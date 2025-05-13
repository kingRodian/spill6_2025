extends CharacterBody2D
class_name Player

# Raycast vars
const RAY_LEN = 600

signal has_died(body)
signal health_changed(new_health)

@export var start_health := 3
var start_pos := position

@export var speed : float = 300.0
@export var jump_velocity: float = -450.0
@export var scroll_speed : float = 0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var anim_sprite = $"Sprites/AnimatedSprite2D"
@onready var orig_color = anim_sprite.modulate

# Movement vars
const base_accel : float = 250.0
const max_speed : Vector2 = Vector2(400.0, 600)
@export var knockback_reduction = .7
var stored_velocity : Vector2 = Vector2.ZERO
const jumptime = 0.15
const hangtime = 0.1

# Flags
var is_skiking := true
#var animation_locked : bool = false
var in_knockback: bool = false
var is_jumping : bool = false
var is_alive := true

@onready var health : int = start_health


func _ready():
	print("player loaded")
	$HangTimer.wait_time = hangtime
	$JumpTimer.wait_time = jumptime

func _physics_process(delta):
	# Check for player actions
	if is_alive:
		if Input.is_action_just_pressed(&"jump"):
			_on_jump_button_pressed()

	# angle to rotate towards
	var angle := 0.0
	var tangent := Vector2.RIGHT
	var friction = 1.0

	# Raycasting to detect the angle to the floor
	var raycast_result = _raycast()
	if raycast_result:
		var normal : Vector2 = raycast_result.get("normal")
		var collider = raycast_result.get("collider")
		if collider is Terrain:
			friction = collider.friction
		var tangent_3d := Vector3(normal.x, normal.y, 0).cross(Vector3.FORWARD)
		tangent = Vector2(tangent_3d.x, tangent_3d.y)
		angle = -normal.angle_to(Vector2.UP)

	# Apply velocity according to surface tangent if skiking is allowed.
	if is_on_floor() and is_skiking:
		velocity += base_accel * delta * tangent.normalized() * friction
		velocity = velocity.min(max_speed)

	if not is_jumping:
		velocity.y += gravity * delta

	if is_on_floor():
		if not anim_sprite.is_playing():
			anim_sprite.play("skike")
		anim_sprite.rotation = angle

	move_and_slide()

func _raycast() -> Dictionary:
	var space_rid = get_world_2d().space
	var space_state = PhysicsServer2D.space_get_direct_state(space_rid)
	var end := position + Vector2.DOWN * RAY_LEN
	var query = PhysicsRayQueryParameters2D.create(position, end)
	return space_state.intersect_ray(query)

## Stops moving.
func stop():
	is_skiking = false
	is_jumping = false
	in_knockback = false

	$KnockbackTimer.stop()
	$HangTimer.stop()
	$JumpTimer.stop()

func reset():
	print("Resetting")
	position = start_pos
	velocity = Vector2.ZERO
	health = start_health
	health_changed.emit(health)

	anim_sprite.modulate = Color.WHITE

	stop()
	is_skiking = true
	is_alive = true

func die():
	print('player has died')
	is_alive = false
	emit_signal('has_died')

## This function gets called by the object the player hit.
func _on_hit(entity, body):
	match entity.entity_type:
		"enemy", "obstacle":
			if not in_knockback:
				_get_knocked_back() # THis needs to happen first, in the case we die, we can easily stop it.
				_take_damage(entity, body)
		_:
			pass

func _take_damage(entity, body):
	# Different amounts of damage?
	SoundManager.skade_lyd_tromme()
	print("Player hit")
	health -= 1
	health_changed.emit(health)
	if health <= 0:
		die()

func _get_knocked_back():
	$KnockbackTimer.start()
	in_knockback = true
	is_jumping = false
	stored_velocity = Vector2(velocity.x, 0)
	velocity = Vector2.ZERO
	# anim_sprite.play("hurt")
	anim_sprite.modulate = Color.RED

func _on_knockback_timer_timeout() -> void:
	in_knockback = false
	anim_sprite.modulate = orig_color
	# Restore speed but reduced
	velocity = stored_velocity * knockback_reduction

func _on_jump_button_pressed():
	if is_on_floor() and not in_knockback:
		$JumpTimer.start()
		is_jumping = true
		anim_sprite.play("jump")
		velocity.y = jump_velocity

func _on_jump_timer_timeout() -> void:
	velocity.y = 0
	$HangTimer.start()

func _on_hang_timer_timeout() -> void:
	is_jumping = false
