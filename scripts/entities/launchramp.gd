extends Launcher

const launch_speed : float = 600
@onready var launch_vector:= (Vector2(1, -.75) * launch_speed).rotated(global_rotation)


func _on_2d_area_body_entered(body: Node2D) -> void:
	if body is Player:
	# Spilleren treffer hinderet
		body._on_hit(self, body)
