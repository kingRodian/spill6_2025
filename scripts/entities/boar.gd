extends Obstacle

func _on_area_2d_body_entered(body):
	if body is Player:
		# Spilleren treffer hinderet
		body._on_hit(self, body)
