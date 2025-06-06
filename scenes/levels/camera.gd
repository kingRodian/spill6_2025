class_name Camera
extends Camera2D


## Whether to drawn terrain collision points. Will never draw debug in release mode.
## The purple circle is where all rays are drawn from.
## The red circles are intersections with raycasts.
## The blue circle is the target_position of the camera.
## The green circle is the current position of the camera.
@export var DRAW_DEBUG := true

## How many units down should be checked for ground.
const GROUND_CHECK_LENGTH := 200.0
## THE height above the ground terrain rays will be cast from.
const GROUND_RAYS_HEIGHT := 70.0
## How many units long the terrain rays are.
const RAY_LENGTH := 500.0
## The maximum slope that is still considered floor, in radians
const MAX_FLOOR_ANGLE := PI / 4
## The margin given to include player
const PLAYER_MARGIN := 50.0

@onready var player : Player = get_parent().get_node("Raskeladden")

## Margins in world coordinates.
@export var margins := Vector2(30, 10)
@export var min_zoom := 0.7
@export var max_zoom := 3.5
## The zoom value to scale around. Also default zoom on start and on reset. Manually changing zoom should be avoided.
@export var baseline_zoom := 2.5
## The minimum difference between zoom and target_zoom to immidietaly start to interpolate.
## Otherwise, a delay given by zoom_deadzone_frames will occur, zoom interpolation fully starts.
@export var zoom_deadzone := 1.2
## The number of frames waited before camera zooms normally on zoom direction changed.
@export var zoom_deadzone_frames := 50

@export_group("Interpolation")
## The speed at which the camera will zoom in. Usually a value between 1.0 and 10.0.
@export var zoom_in_speed := 0.6
## The speed at which the camera will zoom out. Usually a value between 1.0 and 10.0.
@export var zoom_out_speed := 0.8
## The speed at which the camera will change its x coordinate. Usually a value between 1.0 and 10.0.
@export var x_speed := 2.75
## The speed at which the camera will change its x coordinate. Usually a value between 1.0 and 10.0.
@export var y_speed := 2.75

## Specifies the direction the camera is zooming. In is positive, out is negative.
var _zoom_direction := 1.0
## A zoom factor used to slow down zooming during rapid canges between zoom in and out.
var _zoom_slowdown := 1.0
var _zoom_frame_count := 0.0

var target_position : Vector2
var target_zoom : Vector2

var _last_ground : Vector2
var _points : Array[Vector2]


func _ready() -> void:
	zoom = Vector2(baseline_zoom, baseline_zoom)

	# Only change if default is not set
	if drag_horizontal_offset == 0.0:
		drag_horizontal_offset = 1.0

	if drag_left_margin == 0.2:
		drag_left_margin = 0.28

	if drag_vertical_offset == 0.0:
		drag_vertical_offset = -0.36

func _process(delta: float) -> void:
	# Position
	position.x = lerp(position.x, target_position.x, clampf(x_speed * delta, 0.0, 1.0))
	position.y = lerp(position.y, target_position.y, clampf(y_speed * delta, 0.0, 1.0))

	# Zoom
	# If directiion of zoom changed, e.g zoom in to zoom out
	if signf(zoom.x - target_zoom.x) == _zoom_direction:
		_zoom_direction *= -1
		_zoom_slowdown = 0.0
		_zoom_frame_count = 0.0

	# Ignore slowdown if zoom is large enough
	if absf(zoom.x - target_zoom.x) > zoom_deadzone:
		_zoom_slowdown = 1.0
		# print("Deadzone hit!")

	# Exponential easing function. _zoom_slowdown is small for all _zoom_frame_counts except the few last ones.
	if _zoom_slowdown != 1.0:
		# Last parameter of pow can be increased for steeper curve, or lower for shallower curve.
		_zoom_slowdown = clampf(exp(0.7 * pow(_zoom_frame_count / zoom_deadzone_frames, 7.0)) - 1.0, 0.0, 1.0)
		# print("Zoom slowdown: ", _zoom_slowdown)

	_zoom_frame_count += 1

	var zoom_speed := zoom_out_speed
	if zoom.x < target_zoom.x:
		zoom_speed = zoom_in_speed

	zoom = zoom.lerp(target_zoom, clampf(_zoom_slowdown * zoom_speed * delta, 0.0, 1.0))

func _draw() -> void:
	if OS.is_debug_build() and DRAW_DEBUG:
		draw_set_transform_matrix(global_transform.affine_inverse())

		if _points:
			for point in _points:
				draw_circle((point), 10, "red")
			draw_circle(_points[0], 10, "purple")
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

	origin = ground + Vector2.UP * GROUND_RAYS_HEIGHT

	var add_point := func (start, end):
		var ray := _raycast(start, end)
		if ray:
			# If collision is with floor
			if abs(Vector2.UP.angle_to(ray["normal"])) < MAX_FLOOR_ANGLE:
				positions.append(ray["position"])

	# Ordered from most flat to steep. Uses magic numbers for length ratios and angle.
	add_point.call(origin, origin + Vector2(12, 1).normalized() * RAY_LENGTH )
	add_point.call(origin, origin + Vector2(1.8, 1).normalized() * RAY_LENGTH * 2.5)
	add_point.call(origin, origin + Vector2(0.8, 1).normalized() * RAY_LENGTH)
	add_point.call(origin, origin + Vector2(0, 1).normalized() * RAY_LENGTH)

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
	# We stop the target from going backwards, to not cause any stuttering.
	target_position = middle.max(Vector2(target_position.x, middle.y))

## Zoom and pan to the player. Called by level on player death.
func death_zoom():
	target_zoom = Vector2(max_zoom, max_zoom)
	target_position = player.global_position
	x_speed = 1.0
	y_speed = 1.0
	drag_horizontal_offset = 0.0
	drag_vertical_offset = 0.0

	# disable zoom deadzone
	if signf(zoom.x - target_zoom.x) == _zoom_direction:
		_zoom_direction *= -1
	_zoom_slowdown = 1.0

	set_physics_process(false)

func reset():
	position = Vector2.ZERO
	target_position = Vector2.ZERO
	target_zoom = Vector2(baseline_zoom, baseline_zoom)
	zoom = Vector2(baseline_zoom, baseline_zoom)
	_last_ground = Vector2.ZERO
	_points = []

## Only raycasts with ground layer
func _raycast(start : Vector2, direction : Vector2) -> Dictionary:
	var space_rid = get_world_2d().space
	var space_state = PhysicsServer2D.space_get_direct_state(space_rid)
	var query = PhysicsRayQueryParameters2D.create(start, direction, 1)
	return space_state.intersect_ray(query)
