extends Node

@export var save_data : SaveData

# Called when the node enters the scene tree for the first time.
func _ready():
	if save_data == null:
		load_save()

func save():
	if save_data == null:
		push_error("Cannot save missing save_data.")
		return

	print("Saving the game.")
	ResourceSaver.save(save_data, "user://save_data.res")


## Will load a SaveData resource from the user data. Optionally a SaveData object can be given to load instead:
func load_save(data : SaveData = null):
	if data != null:
		print("Loading custom save.")
		save_data = data

	if not FileAccess.file_exists("user://save_data.res"):
		# Check for first time setup
		if save_data == null:
			print("Creating first save file!")
			save_data = SaveData.new()
			save()
			return

		push_error("Cannot load missing save_data file.")
		return

	print("Loading save file from disk.")
	save_data = ResourceLoader.load("user://save_data.res")
