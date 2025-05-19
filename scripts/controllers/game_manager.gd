extends Node


signal toggle_game_paused(is_paused : bool)

var is_pause_enabled := false
var is_game_retry_enabled := false

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

var _game_paused := false

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if get_node("../CutsceneW1m1") != null or get_node("../Menu") != null:
			return
		if $PauseMenu/Settings.visible:
			$PauseMenu/Settings.hide()
		else:
			toggle_pause()
	elif event.is_action_pressed("retry"):
		try_retry()

func _notification(what):
	# pause og fortsett spill med android back button
	# TODO wouldn't this mean the game unpauses when you press the home button.
	if what in [
		NOTIFICATION_APPLICATION_PAUSED, # home button
		NOTIFICATION_WM_GO_BACK_REQUEST]: # back button
		if get_node("../CutsceneW1m1") != null or get_node("../Menu") != null:
			return
		if $PauseMenu/Settings.visible:
			$PauseMenu/Settings.hide()
		else:
			toggle_pause()

## Will attempt to retry the current level if it exists
func try_retry():
	# Search if a Level node is the currently active scene.
	var siblings := get_parent().get_children()
	var level_index := siblings.find_custom(func(node): return node is Level)
	if level_index != -1:
		# TODO When trying to reset after dying, the level will call reset() twice
		var level : Level = siblings[level_index]
		level.reset()
		unpause()

func _on_pause_menu_resume():
	assert(is_paused(), "Game should be paused when trying to resume.")
	unpause()

func _on_pause_menu_retry():
	try_retry()

func disconnect_pause_function():
	disconnect("toggle_game_paused",$PauseMenu._on_game_manager_toggle_game_paused)

func connect_pause_function():
	connect("toggle_game_paused",$PauseMenu._on_game_manager_toggle_game_paused)

## Tries to pause the current level if is_pause_enabled.
func pause():
	if _game_paused or not is_pause_enabled:
		return

	_game_paused = true
	toggle_pause_button()
	print("Game paused!")
	get_tree().paused = true
	toggle_game_paused.emit(true)

## Unpauses the current level regardless of is_pause_enabled
func unpause():
	if not _game_paused:
		return

	_game_paused = false
	toggle_pause_button()
	print("Game unpaused!")
	get_tree().paused = false
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
