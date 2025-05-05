extends AnimatableBody2D

signal hit(from, to)

@export var path : PathFollow2D

const speed : float = 20

var target : Vector2 = position
var direction : Vector2 = Vector2.ZERO
const target_delta : float = 5.0

func _ready():
	print("fotgjenger 1 loaded")

func _physics_process(delta):
	if global_position.distance_to(target) > target_delta:
		global_position += direction * speed * delta

	
func _on_area_2d_area_entered(body):
	# Spilleren treffer hinderet
	emit_signal('hit', self, body)
	SoundManager.skade_piano()


func _on_movement_timer_timeout() -> void:
	# Select a random point along the path
	path.set_progress_ratio(randf())
	target = path.global_position
	print("Fotgjenger path set to: " + str(path.progress_ratio))
	print(str(target))
	print("Distance: " + str(global_position.distance_to(target)))
	direction = global_position.direction_to(target).normalized()
	$MovementTimer.start()
