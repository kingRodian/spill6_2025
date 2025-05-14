extends CanvasLayer

#TODO for GameTimer
	# Set Timer-font
	# Set Background frame for timer
	# Set good font-size for timer
	# Decide final placement on screen for timer
	# Save time_left as part of score.
	# decide color for timer

@onready var timer = $CenterContainer/Label/Timer
@onready var label = $CenterContainer/Label

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if timer.time_left==0:
		return
	# Set the label text to the current time left on timer
	label.text = get_time()

func get_time():
	# Divide the given time left into minutes, seconds and miliseconds
	var current_time : int = timer.time_left
	var minutes : int = current_time / 60
	var seconds : int = fmod(current_time, 60.0)

	# Convert the integers into string format
	var mins = str(minutes)
	var secs = str(seconds)

	# Format the string to a better visiual reprensentation
	if minutes < 10:
		mins = "0" + str(minutes)
	if seconds < 10:
		secs = "0" + str(seconds)

	# Return the converted and formated time in a 00:00:00 format
	return str(mins) + ":" + str(secs)
