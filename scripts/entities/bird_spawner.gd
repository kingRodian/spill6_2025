extends Node2D
@export var spawns : int = 1
const mobres_str : String = "res://scenes/game/obstacles/bird.tscn"
var mobres : Resource = preload(mobres_str)

func _on_area_2d_body_entered(body):
	if body is Player and spawns > 0:
		print("Spawning bird.")
		var mob = mobres.instantiate()
		mob.initialize(body)
		add_child(mob)
		spawns -= 1
