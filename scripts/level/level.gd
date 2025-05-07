extends Node2D

@onready var player := $Player.get_child(0)
@onready var health := $HUD/LeftContainer/Health
@onready var camera := $Camera2D


func _ready() -> void:
	player.connect("has_died", _on_death)
	player.connect("health_changed", health._on_raskeladden_health_changed)
	
	health.set_max_health(player.start_health)
	health.update_health(player.start_health)

func reset():
	player.reset()

func _on_death(body):
	print("level resetting")
	camera.position = Vector2(0, 0) # does nothing while RemoteTransform2D is active
	player.reset()
	
	# camera.reset()
	
	#SoundManager.taper_lyd()
	##body.queue_free()
	#player.queue_free()
	#GameManager.disconnect_pause_function()
	#get_node("HUD/RightContainer/PauseButton").queue_free()
	#$HUD/CenterContainer/you_died.show()
	#await get_tree().create_timer(2).timeout
	##get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
	##get_tree().reload_current_scene()
	#get_tree().reload_current_scene()
