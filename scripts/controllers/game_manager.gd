extends Node


signal toggle_game_paused(is_paused : bool)

@onready var pause_menu = get_node("PauseMenu")
@onready var pause_menu_settings = get_node("PauseMenu/Settings")

var is_pause_enabled := false
var is_game_retry_enabled := false

var player : Player
var camera : Camera2D

var is_debug_mode := false
var debug_faster := false
var debug_base_speed : float = 500
var debug_faster_speed : float = 2000
var debug_keymap := {"debug_up" : false, "debug_down" : false,
 "debug_left" : false, "debug_right" : false}
var debug_dir_vecs := {"debug_up" : Vector2.UP, "debug_down" : Vector2.DOWN,
 "debug_left" : Vector2.LEFT, "debug_right" : Vector2.RIGHT}

## The current level being played. Only changed when a new level is loaded.
var current_level : Level:
	get:
		return current_level
	set(value):

		# If we go to a new level
		if value != null:
			is_pause_enabled = true
			is_game_retry_enabled = true
		else:
			is_pause_enabled = false
			is_game_retry_enabled = false

		current_level = value
		player = current_level.find_child("Raskeladden", true)
		camera = current_level.find_child("Camera", true)

var _game_paused := false

# Debug movement
func _physics_process(delta):
	if is_debug_mode and player != null:
		var debug_vec := Vector2.ZERO
		for key in debug_keymap:
			# If key is being held, add its vector
			if debug_keymap[key]:
				debug_vec += debug_dir_vecs[key]
		debug_vec = debug_vec.normalized()

		var movement : Vector2
		if debug_faster:
			movement = debug_vec * debug_faster_speed * delta
		else:
			movement = debug_vec * debug_base_speed * delta
		player.position += movement

func _input(event : InputEvent):
	if OS.is_debug_build():
		if event.is_action_pressed("debug_mode") and not _game_paused:
			toggle_debug_mode()
		else:
			if is_debug_mode:
				debug_mode_input(event)
				return
	if event.is_action_pressed("ui_cancel"):
		if current_level == null:
			return
		if pause_menu_settings.visible:
			pause_menu_settings.hide()
		else:
			toggle_pause()
	elif event.is_action_pressed("retry"):
		try_retry()

# Take input in debug mode for movement
# To allow for holding a key down, we need to keep track of what keys are held or not
# So we have a keymap of bools and their states
# We then add these directions up, normalize them and add them to the player position
# NOTE: All of this is basically to avoid having a huge if-chain
func debug_mode_input(event : InputEvent):
	if not event.is_action_type():
		return
	if event.is_action_pressed("debug_faster"):
		debug_faster = true
	elif event.is_action_released("debug_faster"):
		debug_faster = false
	elif event.is_action_pressed("debug_refill_health"):
		player.health = player.start_health
		player.health_changed.emit(player.health)

	# Update state of key on events
	for action in debug_keymap.keys():
		if event.is_action(action):
			if event.is_pressed():
				debug_keymap[action] = true
			else:
				debug_keymap[action] = false

func _notification(what):
	# pause og fortsett spill med android back button
	# TODO wouldn't this mean the game unpauses when you press the home button.
	if what in [
		NOTIFICATION_APPLICATION_PAUSED, # home button
		NOTIFICATION_WM_GO_BACK_REQUEST, # back button
	]:

		if current_level == null:
			return
		if pause_menu_settings.visible:
			pause_menu_settings.hide()
		else:
			toggle_pause()

## Will attempt to retry the current level if it exists
func try_retry():
	# Search if a Level node is the currently active scene.
	var siblings := get_parent().get_children()
	var level_index := siblings.find_custom(func(node): return node is Level)
	if level_index != -1:
		var level : Level = siblings[level_index]
		level.reset()
		unpause()

## Tries to pause the current level if is_pause_enabled.
func pause():
	if _game_paused or not is_pause_enabled:
		return

	_game_paused = true
	pause_menu.show()
	toggle_pause_button()
	get_tree().paused = true

	print("Game paused!")
	toggle_game_paused.emit(true)

## Unpauses the current level regardless of is_pause_enabled
func unpause():
	if not _game_paused:
		return

	_game_paused = false
	pause_menu.hide()
	toggle_pause_button()
	get_tree().paused = false

	print("Game unpaused!")
	toggle_game_paused.emit(false)

func toggle_pause():
	if is_paused():
		unpause()
	else:
		pause()

func is_paused():
	return _game_paused

## Hides or shows the touch button used to pause the level dependig on the pause state
func toggle_pause_button():
	if current_level:
		# HUD should always have a PauseButton otherwise we get an error.
		current_level.get_node("HUD/RightContainer/PauseButton").visible = !is_paused()

func _on_pause_menu_resume():
	assert(is_paused(), "Game should be paused when trying to resume.")
	unpause()

func _on_pause_menu_retry():
	try_retry()


func _on_pause_menu_quit() -> void:
	unpause()

	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")

func toggle_debug_mode():
	if current_level == null:
		return
	if not is_debug_mode:
		if player != null:
			print("debug_mode on")
			is_debug_mode = true
			player.set_physics_process(false)
			get_tree().paused = true
			toggle_debug_label()
			camera.position_smoothing_enabled = false
	else:
		print("debug_mode off")
		# We cant enter debug mode in the first place without a player, so no check here
		is_debug_mode = false
		player.set_physics_process(true)
		get_tree().paused = false
		toggle_debug_label()
		camera.position_smoothing_enabled = true

func toggle_debug_label():
	var debug_label : Label = current_level.find_child("debug_label", true)
	if debug_label != null:
		debug_label.visible = !debug_label.visible
