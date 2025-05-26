extends Camera2D

@onready var player : Player = get_parent().get_node("Raskeladden")

## Margins in world coordinates.
@export var margins := Vector2(30, 30)
@export var min_zoom := 0.7
@export var max_zoom := 10.0

var target_position : Vector2
var target_zoom : Vector2
## The time in seconds for the camera to reach is
@export var speed := 1.0
var max_extrapolation := 30.0

func _process(delta: float) -> void:
	if GameManager.is_paused():
		return

	print("Change: ", speed * delta)
	# position = position.lerp(target_position, clampf(speed * delta, 0.0, max_extrapolation))
	# zoom = zoom.lerp(target_zoom, clampf(speed * delta, 0.0, max_extrapolation))
	position = target_position
	zoom = target_zoom
	reset_smoothing()

func _physics_process(delta: float) -> void:
	var positions : Array[Vector2] = [player.global_position, player.global_position + Vector2(200, 0)]
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

	var middle := (minimum + maximum) / 2.0
	var diff := (minimum - maximum)
	# var diff := (minimum - maximum).abs() + margins


	var new_zoom : float
	if diff.x > diff.y:
		new_zoom = float(get_window().size.x) / (diff.abs().x + margins.x)
	else:
		new_zoom = float(get_window().size.y) / (diff.abs().y + margins.y)

	target_zoom = (Vector2(new_zoom, new_zoom)).abs()

	# Make sure zoom is within limits
	if target_zoom.x < min_zoom or target_zoom.y < min_zoom:
		target_zoom = Vector2(min_zoom, min_zoom)
	elif target_zoom.x > max_zoom or target_zoom.y > max_zoom:
		target_zoom = Vector2(max_zoom, max_zoom)

	target_position = middle

func _raycast(start : Vector2, direction : Vector2) -> Dictionary:
	var space_rid = get_world_2d().space
	var space_state = PhysicsServer2D.space_get_direct_state(space_rid)
	var query = PhysicsRayQueryParameters2D.create(start, direction, 1)
	return space_state.intersect_ray(query)
