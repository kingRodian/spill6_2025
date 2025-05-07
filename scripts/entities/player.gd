extends CharacterBody2D

signal has_died(body)
signal health_changed(new_health)
# TODO
# Legg til relevant bevegelse
# Ask if doublejump is something we should add
# Clean up code and add documentation

@export var start_health := 3
@export var start_pos := position

@export var speed : float = 300.0
@export var jump_velocity: float = -450.0
@export var scroll_speed : float = 0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var has_double_jumped : bool = false
var has_landed : bool = false
var animation_locked : bool = false

var health : int = start_health

@onready var anim_sprite = $"Sprites/AnimatedSprite2D"


func _ready():
	print("player loaded")

func _physics_process(delta):
	position.x += scroll_speed * delta
	if not is_on_floor():
		velocity.y += gravity * delta
	if not anim_sprite.is_playing() and is_on_floor():
		anim_sprite.play("skike")

	has_landed = check_if_landing()
	move_and_slide()

func check_if_landing():
	return (not is_on_floor() and velocity.y > 50)

func reset():
	print("Resetting")
	position = start_pos
	health = start_health
	health_changed.emit(health)

func die(body):
	print('player has died')
	emit_signal('has_died', body)

func _on_hit(entity, body):
	print('player hit')
	health -= 1
	health_changed.emit(health)
	# play hit animation
	# push character back a bit?
	# invincibility, flashing sprite?
	if health <= 0:
		die(body)

# Health upgrade?
# Old relic code
func _on_health_upgrade_detected(amount):
	print('player received health upgrade')
	health += amount

func _on_jump_button_pressed():
	if is_on_floor():
		has_double_jumped = false
		anim_sprite.play("jump")
		velocity.y = jump_velocity

	
