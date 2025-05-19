extends CanvasLayer

signal resume
signal retry

func _ready():
	connect("visibility_changed", _on_visibility_changed)
	hide()

func update_percent():
	if GameManager.current_level:
		var label = get_node("Percent/Label")
		label.text = str(GameManager.current_level.calculate_progress()) + "% Ferdig"

func _on_resume_button_pressed():
	resume.emit()

func _on_retry_button_pressed():
	retry.emit()

func _on_settings_button_pressed():
	$Settings.show()

func _on_quit_button_pressed():
	resume.emit()
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn") # TODO This should also be in GameManager

func _on_visibility_changed() -> void:
	if visible:
		update_percent()
