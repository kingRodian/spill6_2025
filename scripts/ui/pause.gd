extends CanvasLayer

signal resume
signal retry

func _ready():
	hide()

func _on_resume_button_pressed():
	resume.emit()
	# TODO Why is the pause *menu* in charge of background sound shouldn't this be GameManager or Level?
	SoundManager.play_bird_chirp_loop(false)
	$".".hide() # Should be in GameManager

func _on_retry_button_pressed():
	retry.emit()

func _on_settings_button_pressed():
	$Settings.show()

func _on_quit_button_pressed():
	resume.emit()
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn") # TODO This should also be in GameManager

func _on_game_manager_toggle_game_paused(is_paused):
	visible = is_paused
	if visible:
		SoundManager.play_bird_chirp_loop(false)
		update_percent()

func update_percent():
	var label = get_node("Percent/Label")
	var goal = get_node("/root/THE-MAP/MAP-TRIGGERS/goal")
	var player = get_node("/root/THE-MAP/PLAYER/Raskeladden")
	if player:
		var percent = round((player.position.x / goal.position.x) * 100)
		label.text = str(percent) + "% Ferdig"
