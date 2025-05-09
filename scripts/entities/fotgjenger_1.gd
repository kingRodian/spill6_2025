extends Node2D

signal hit(from, to)

const entity_type := "enemy"

@export var follower : PathFollow2D
const base_speed : float = 0.2
var speed = base_speed
var target : float = 1.0

func _ready():
	print("fotgjenger 1 loaded")
	#follower.progress_ratio = 0.0
	$MovementTimer.start()

func _physics_process(delta):
	if not is_equal_approx(follower.progress_ratio, target):
		follower.progress_ratio += speed * delta
		position = follower.position


func _on_movement_timer_timeout() -> void:
	$MovementTimer.start()
	target = abs(target - 1)
	speed = -speed


func _on_area_2d_body_entered(body: Node2D) -> void:
		# Spilleren treffer hinderet
	if body is Player:
		emit_signal('hit', self, body)
		SoundManager.skade_piano()
