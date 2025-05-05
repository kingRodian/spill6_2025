extends CharacterBody2D

signal has_died(body)
signal lost_health(new_health)
# TODO
# Doublejump? is something we should add
# Clean up code and add documentation

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var anim_sprite = $"Sprites/AnimatedSprite2D"
@onready var orig_color = anim_sprite.modulate

# Movement vars
const base_accel : float = 250.0
const max_speed : float = 300.0
@export var jump_velocity: float = -300.0
@export var knockback_speed_x : float = - base_accel * 0.4
var jump_y_start : float = 0
var jump_height_max : float = 60

# Flags
var has_double_jumped : bool = false
var has_landed : bool = false
#var animation_locked : bool = false
var in_knockback: bool = false
var hangtime : bool = false

var angle_factor : float = 1
var hearts : int = 3

# Raycast vars
const RAY_LEN = 60

func _ready():
	print("player loaded")

func _physics_process(delta):
	velocity.y += gravity * delta
	velocity.x += base_accel * delta
	velocity.x = minf(velocity.x, max_speed)
	
	
		# Raycasting to detect the angle to the floor
	var space_rid = get_world_2d().space
	var space_state = PhysicsServer2D.space_get_direct_state(space_rid)
	var end = position + Vector2.DOWN * RAY_LEN
	var query = PhysicsRayQueryParameters2D.create(position, end)
	var result = space_state.intersect_ray(query)
	if result:
		var normal = result.get("normal")
		var angle = -normal.angle_to(Vector2.UP)
		#print(str(rad_to_deg(angle)))
		rotation = angle
	
	if is_on_floor():
		if not anim_sprite.is_playing():
			anim_sprite.play("skike")
	else:
		# Jump logic
		if hangtime:
			if position.y < jump_y_start - jump_height_max:
				velocity.y = 0

	has_landed = check_if_landing()
	move_and_slide()


func check_if_landing():
	return (not is_on_floor() and velocity.y > 50)
	
func _on_hit(entity, body):
	if not in_knockback:
		SoundManager.skade_lyd_tromme()
		print('player hit')
		hearts -= 1
		lost_health.emit(hearts)
		$KnockbackTimer.start()
		in_knockback = true
		velocity.x = knockback_speed_x
		# anim_sprite.play("hurt")
		anim_sprite.modulate = Color.RED
		if hearts == 0:
			die(body)

func _on_knockback_timer_timeout() -> void:
	in_knockback = false
	anim_sprite.modulate = orig_color
	
func die(body):
	print('player has died')
	emit_signal('has_died', body)

# Health upgrade?
func _on_health_upgrade_detected(amount):
	print('player received health upgrade')
	hearts += amount

func _on_jump_button_pressed():
	if is_on_floor():
		has_double_jumped = false
		jump_y_start = position.y
		$HangTimer.start()
		hangtime = true
		anim_sprite.play("jump")
		velocity.y = jump_velocity

func _on_hang_timer_timeout() -> void:
	hangtime = false
