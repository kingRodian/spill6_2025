extends Node2D

# We use on_exited because player should be past the goal post to win.
func _on_area_2d_body_exited(body):
	# Simple win trigger
	if body is Player:
		var level = find_level_root(self)
		if level is Level:
			level.win()

## Gets the first Level ancestor or null
func find_level_root(node : Node):
	if node.get_parent() is Level or node.get_parent() == null:
		return node.get_parent()
	return find_level_root(node.get_parent())
