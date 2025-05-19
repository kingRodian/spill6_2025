@tool
class_name Level
extends Node2D


## To initialize a level in the editor, first press the "First Time Setup" button in the property list and then save.

var SaveManager = preload("res://scenes/save_manager.tscn")

@onready var player : Player = $Raskeladden
@onready var health := $HUD/LeftContainer/Health
@onready var camera : Camera2D = $Camera

var level_timer : Timer

@export_tool_button("First Time Setup") var first_time_setup_button = _first_time_setup

## The amount of time to beat the level in seconds.
@export var level_time : int = 90

@export_storage var has_setup := false

var can_win := true
var can_lose := true


func _enter_tree() -> void:
	# Don't run this in editor as tool.
	if Engine.is_editor_hint():
		return

	# This can always be instantiated at runtime
	var save_manager = SaveManager.instantiate()
	save_manager.name = "SaveManager"
	add_child(save_manager)

	assert(has_setup, "You forgot to run first time setup.")

func _ready() -> void:
	# Don't run this in editor as tool.
	if Engine.is_editor_hint():
		return

	player.connect("has_died", lose)
	player.connect("health_changed", health._on_raskeladden_health_changed)

	health.set_max_health(player.start_health)
	health.update_health(player.start_health)

	$HUD/JumpButton.connect("button_down", func(): Input.action_press("jump"))
	$HUD/JumpButton.connect("button_up", func(): Input.action_release("jump"))

	level_timer = $HUD/GameTimer.timer
	level_timer.connect("timeout", lose)
	# We add one second so the label shows the time we eant
	level_timer.start(level_time + 1)

	GameManager.current_level = self

func reset():
	player.reset()
	camera.position = Vector2(0, 0)
	camera.reset_smoothing()

	# We add one second so the label shows the time we eant
	level_timer.start(level_time + 1)

	can_win = true
	can_lose = true

	GameManager.is_pause_enabled = true
	GameManager.is_game_retry_enabled = true

func _first_time_setup():
	print("Running first time level setup.\n")
	has_setup = true

	if find_child("Camera", false) == null:
		print("Ingen Camera funnet.")
		print("Generer ny Camera.")
		_add_node(Camera2D.new(), "Camera")
		camera = $Camera

		# Copy of camera from level 1
		camera.zoom = Vector2(3, 3)
		camera.limit_left = -45
		camera.limit_right = 10600
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 7.0
		camera.drag_vertical_enabled = true
		camera.drag_horizontal_offset = 1.0
		camera.drag_vertical_offset = -0.36

	if find_child("Raskeladden", false) == null:
		print("Ingen Raskeladden funnet.")
		print("Generer ny Raskeladden.")
		var rask : Player = load("res://scenes/game/characters/raskeladden.tscn").instantiate()
		_add_node(rask, "Raskeladden")

		# Make remote transform
		var remote := RemoteTransform2D.new()
		remote.name = "RemoteTransform2D"
		rask.add_child(remote)
		remote.owner = self
		remote.scale = Vector2(0.6, 0.6)
		remote.remote_path = remote.get_path_to(camera)

	if find_child("HUD", false) == null:
		print("Ingen HUD funnet.")
		print("Generer ny HUD.")
		_add_node(load("res://scenes/HUD/hud.tscn").instantiate(),"HUD")

## Instantly wins the level. Called by goal.gd collision trigger.
func win():
	if can_win:
		can_lose = false
		can_win = false
		_on_win()
	else:
		push_warning(false, "Redundant win() call was made.")

func _on_win():
	$"HUD/RightContainer/PauseButton".hide() #Hide the pause button from player on win
	player.set_physics_process(false) # Stops player movement

	# TODO We could eventually add a celebration animation
	#player.anim_sprite.play('idle')
	GameManager.is_pause_enabled = false
	GameManager.is_game_retry_enabled = false

	SoundManager.vinn_bane()
	$"HUD/CenterContainer/you_win".show()
	level_timer.stop()

	await get_tree().create_timer(2).timeout
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")

## Immediately lose the level. Called on level_timer timeout.
func lose():
	if can_lose:
		can_lose = false
		can_win = false
		_on_lose()
	else:
		push_warning("Redundant lose() call was made.")

func _on_lose():
	# TODO temporary, add retry button

	# Stop level
	SoundManager.taper_lyd()
	GameManager.is_pause_enabled = false # TODO TEMPORARY add functions
	GameManager.is_game_retry_enabled = false
	player.stop()
	level_timer.stop()

	# TODO fix bug when pausing at the same time as dying.
	# 	Game should automatically unpause when dying.
	# TODO We could add death/stop/idle animation here

	$HUD/CenterContainer/you_died.show()
	await get_tree().create_timer(2).timeout

	# Restart level
	# TODO We could use a transition screen here.
	print("level resetting")
	reset()
	$HUD/CenterContainer/you_died.hide()

## Used by PauseMenu to show progress towards completing the level.
func calculate_progress() -> int:
	# TODO Add better goal node retrieval
	var goal = get_node("MAP-TRIGGERS/goal")

	return round((player.position.x / goal.position.x) * 100)


## Permanentaly add a node to this node
func _add_node(node : Node, node_name := ""):
	if node_name:
		node.name = node_name
	add_child(node)
	node.owner = self
