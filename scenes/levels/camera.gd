extends Camera2D

@onready var player : Player = get_parent().get_node("Raskeladden")

## Margins in world coordinates.
@export var margins := Vector2(30, 30)
@export var min_zoom := 0.7
@export var max_zoom := 10

func _process(delta: float) -> void:
	# position = player.position




	var positions : Array[Vector2] = [player.global_position, player.global_position + Vector2(60, 60)]

	var ray1 := _raycast(player.global_position, player.global_position + Vector2(1,1) * 600)
	if ray1:
		# If collision is with floor
		if abs(Vector2.UP.angle_to(ray1["normal"])) < PI / 4:
			# print("Found position: ", ray1["position"])
			positions.append(ray1["position"])

	var ray2 := _raycast(player.global_position, player.global_position + Vector2(1,0) * 600)
	if ray2:
		# If collision is with floor
		if abs(Vector2.UP.angle_to(ray2["normal"])) < PI / 4:
			# print("Found position: ", ray2["position"])
			positions.append(ray2["position"])


	var ray3 := _raycast(player.global_position, player.global_position + Vector2(2,1) * 600)
	if ray3:
		# If collision is with floor
		if abs(Vector2.UP.angle_to(ray3["normal"])) < PI / 4:
			# print("Found position: ", ray3["position"])
			positions.append(ray3["position"])

	fit_to_points(positions)


func fit_to_points(points : Array[Vector2]):
	var minimum := Vector2(points[0])
	var maximum := Vector2(points[-1])
	for point in points:
		minimum = minimum.min(point)
		maximum = maximum.max(point)

	var middle := (minimum + maximum) / 2.0
	# var diff := (minimum - maximum)
	var diff := (minimum - maximum).abs() + margins

	print("Minimum: ", minimum)
	print("Maximum: ", maximum)

	if diff.x > diff.y:
		# var x_zoom := float(get_window().size.x) / (diff.abs().x + margins.x)
		var x_zoom := float(get_window().size.x) / (diff.x)
		zoom = (Vector2(x_zoom, x_zoom)).abs()
	else:
		var y_zoom := float(get_window().size.y) / (diff.y)
		# var y_zoom := float(get_window().size.y) / (diff.abs().y + margins.y)
		zoom = (Vector2(y_zoom, y_zoom)).abs()
	# zoom = abs(Vector2(get_window().size) / diff).min(max_zoom)

	if zoom.x < min_zoom or zoom.y < min_zoom:
		zoom = Vector2(min_zoom, min_zoom)
	elif zoom.x > max_zoom or zoom.y > max_zoom:
		zoom = Vector2(max_zoom, max_zoom)

	print(zoom)

	position = middle
	reset_smoothing()

func _raycast(start : Vector2, direction : Vector2) -> Dictionary:
	var space_rid = get_world_2d().space
	var space_state = PhysicsServer2D.space_get_direct_state(space_rid)
	var query = PhysicsRayQueryParameters2D.create(start, direction, 1)
	return space_state.intersect_ray(query)
