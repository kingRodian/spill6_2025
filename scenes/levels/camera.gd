extends Camera2D

@onready var player : Player = get_parent().get_node("Raskeladden")

## Margins in world coordinates.
@export var margins := Vector2(300, 300)
@export var min_zoom := 0.7
@export var max_zoom := 10.0
## The zoom value to scale around.
@export var baseline_zoom = 2.0

var target_position : Vector2
var target_zoom : Vector2

@export_group("Interpolation")
## The speed at which the camera will zoom in. Usually a value between 1.0 and 10.0.
@export var zoom_in_speed := 1.0
## The speed at which the camera will zoom out. Usually a value between 1.0 and 10.0.
@export var zoom_out_speed := 1.0
## The speed at which the camera will change its x coordinate. Usually a value between 1.0 and 10.0.
@export var x_speed := 6.0
## The speed at which the camera will change its x coordinate. Usually a value between 1.0 and 10.0.
@export var y_speed := 1.0
## A max clamp on how fast all interpolation happens. A value below 1.0 will lower decrease the time to reach rest.
## A value over 1.0 will allow the camera to go past the target direction.
@export var max_interpolation := 1.0

var HEIGHT_TO_IGNORE := 20.0

func _process(delta: float) -> void:
	# Position
	position.x = lerp(position.x, target_position.x, clampf(x_speed * delta, 0.0, max_interpolation))
	if position.y - HEIGHT_TO_IGNORE > target_position.y or true:
		position.y = lerp(position.y, target_position.y, clampf(y_speed * delta, 0.0, max_interpolation))

	# Zoom
	var zoom_speed := zoom_out_speed
	if zoom.x < target_zoom.x:
		zoom_speed = zoom_in_speed

	zoom = zoom.lerp(target_zoom, clampf(zoom_speed * delta, 0.0, max_interpolation))

func _physics_process(delta: float) -> void:
	var positions : Array[Vector2] = [player.global_position, player.global_position + Vector2(200, -100)]
	var origin := player.global_position

	var add_point := func (start, end):
		var ray := _raycast(start, end)
		if ray:
			# If collision is with floor
			if abs(Vector2.UP.angle_to(ray["normal"])) < PI / 4:
				positions.append(ray["position"])

	add_point.call(origin, player.global_position + Vector2(1,1) * 600)
	add_point.call(origin, player.global_position + Vector2(1,0) * 600)
	add_point.call(origin, player.global_position + Vector2(2,1) * 600)

	fit_to_points(positions)

func fit_to_points(points : Array[Vector2]):
	var minimum := Vector2(points[0])
	var maximum := Vector2(points[-1])
	for point in points:
		minimum = minimum.min(point)
		maximum = maximum.max(point)

	# print(minimum, ", ", maximum)

	var middle := (minimum + maximum) / 2.0
	var diff := (minimum - maximum)
	var diff_x := absf(diff.x)
	var diff_y := absf(diff.y)
	# var diff := (minimum - maximum).abs() + margins

	var new_zoom : float
	var ratio := float(get_window().size.x ) / float(get_window().size.y)
	if diff_x > diff_y * ratio:
		new_zoom = (float(get_window().size.x) / (diff_x + margins.x)) / baseline_zoom
	else:
		new_zoom = (float(get_window().size.y) / (diff_y + margins.y)) / baseline_zoom

	if new_zoom < min_zoom:
		new_zoom = min_zoom
	elif new_zoom > max_zoom:
		new_zoom = max_zoom

	target_zoom = Vector2(new_zoom, new_zoom).abs()
	target_position = middle

func _raycast(start : Vector2, direction : Vector2) -> Dictionary:
	var space_rid = get_world_2d().space
	var space_state = PhysicsServer2D.space_get_direct_state(space_rid)
	var query = PhysicsRayQueryParameters2D.create(start, direction, 1)
	return space_state.intersect_ray(query)
