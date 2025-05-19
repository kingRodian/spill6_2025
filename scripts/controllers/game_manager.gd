extends Node

signal toggle_game_paused(is_paused : bool)

var game_paused : bool = false:
	get:
		return game_paused
	set(value):
		game_paused = value

		# Vis/Skjul pauseknappen når man pauser
		var pause_button = get_node("/root/THE-MAP/HUD/RightContainer/PauseButton")
		if pause_button != null:
			if game_paused == true:
				pause_button.visible = false
			else:
				pause_button.visible = true

		print("Game paused: ",game_paused)
		get_tree().paused = game_paused
		toggle_game_paused.emit(game_paused)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if get_node("../CutsceneW1m1") != null or get_node("../Menu") != null:
			return
		if $PauseMenu/Settings.visible:
			$PauseMenu/Settings.hide()
		else:
			game_paused = !game_paused
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
			game_paused = !game_paused

## Will attempt to retry the current level if it exists
func try_retry():
	# Search if a Level node is the currently active scene.
	var siblings := get_parent().get_children()
	var level_index := siblings.find_custom(func(node): return node is Level)
	if level_index != -1:
		# Is reconnected when Level is done resetting.
		disconnect_pause_function()

		# TODO When trying to reset after dying, the level will call reset() twice
		var level : Level = siblings[level_index]
		level.reset()
		game_paused = false


func _on_pause_menu_resume():
	assert(game_paused == true, "Game should be paused when trying to resume.")
	game_paused = false

func _on_pause_menu_retry():
	try_retry()

func disconnect_pause_function():
	if game_paused:
		game_paused = false
	disconnect("toggle_game_paused",$PauseMenu._on_game_manager_toggle_game_paused)

func connect_pause_function():
	connect("toggle_game_paused",$PauseMenu._on_game_manager_toggle_game_paused)
