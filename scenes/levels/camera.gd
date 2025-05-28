extends Camera2D


## Whether to drawn terrain collision points.
## The red circles on the ground are intersections with raycasts, and the red circle around the player is where they are cast from.
## The blue circle is the target_position of the camera.
## The green circle is the current position of the camera.
const DRAW_DEBUG := true

## How many units down should be checked for ground.
const GROUND_CHECK_LENGTH := 200.0
## THE height above the ground terrain rays will be cast from.
const GROUND_RAYS_HEIGHT := 70.0
## How many units long the terrain rays are.
const RAY_LENGTH := 600.0
## The maximum slope that is still considered floor, in radians
const MAX_FLOOR_ANGLE := PI / 4
## The margin given to include player
const PLAYER_MARGIN := 50.0

@onready var player : Player = get_parent().get_node("Raskeladden")

## Margins in world coordinates.
@export var margins := Vector2(300, 300)
@export var min_zoom := 0.7
@export var max_zoom := 5.0
## The zoom value to scale around.
@export var baseline_zoom = 2.0

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

var target_position : Vector2
var target_zoom : Vector2

var _last_ground : Vector2
var _points : Array[Vector2]


func _process(delta: float) -> void:
	# Position
	position.x = lerp(position.x, target_position.x, clampf(x_speed * delta, 0.0, max_interpolation))
	position.y = lerp(position.y, target_position.y, clampf(y_speed * delta, 0.0, max_interpolation))

	# Zoom
	var zoom_speed := zoom_out_speed
	if zoom.x < target_zoom.x:
		zoom_speed = zoom_in_speed

	zoom = zoom.lerp(target_zoom, clampf(zoom_speed * delta, 0.0, max_interpolation))

func _draw() -> void:
	if OS.is_debug_build() and DRAW_DEBUG:
		draw_set_transform_matrix(global_transform.affine_inverse())

		if _points:
			for point in _points:
				draw_circle((point), 10, "red")
		draw_circle(target_position, 10, "blue")
		draw_circle(position, 10, "green")

func _physics_process(_delta: float) -> void:
	var positions : Array[Vector2] = []
	var origin := player.global_position
	var ground := origin

	var ground_res := _raycast(origin, origin + Vector2.DOWN * GROUND_CHECK_LENGTH)
	if ground_res and abs(Vector2.UP.angle_to(ground_res["normal"])) < MAX_FLOOR_ANGLE:
		ground = ground_res["position"]
		_last_ground = ground
		positions.append(ground + Vector2.UP * PLAYER_MARGIN)
	else:
		ground = Vector2(origin.x, _last_ground.y)
		positions.append(player.global_position)
		print("Ground NOT detected!")

	origin = ground + Vector2.UP * GROUND_RAYS_HEIGHT

	var add_point := func (start, end):
		var ray := _raycast(start, end)
		if ray:
			# If collision is with floor
			if abs(Vector2.UP.angle_to(ray["normal"])) < MAX_FLOOR_ANGLE:
				positions.append(ray["position"])

	add_point.call(origin, origin + Vector2(1,1) * RAY_LENGTH)
	add_point.call(origin, origin + Vector2(1,0) * RAY_LENGTH)
	add_point.call(origin, origin + Vector2(2,1) * RAY_LENGTH)

	if not positions:
		push_error("No raycasts was hit!")
		positions = [player.global_position]
	fit_to_points(positions)

func fit_to_points(points : Array[Vector2]):
	var minimum := Vector2(points[0])
	var maximum := Vector2(points[-1])
	for point in points:
		minimum = minimum.min(point)
		maximum = maximum.max(point)

	_points = points.duplicate()
	if OS.is_debug_build() and DRAW_DEBUG:
		queue_redraw()

	var middle := (minimum + maximum) / 2.0
	var diff := (minimum - maximum)
	var diff_x := absf(diff.x)
	var diff_y := absf(diff.y)

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

## Only raycasts with ground layer
func _raycast(start : Vector2, direction : Vector2) -> Dictionary:
	var space_rid = get_world_2d().space
	var space_state = PhysicsServer2D.space_get_direct_state(space_rid)
	var query = PhysicsRayQueryParameters2D.create(start, direction, 1)
	return space_state.intersect_ray(query)
