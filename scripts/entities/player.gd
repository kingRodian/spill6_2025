extends CharacterBody2D
class_name Player

signal has_died(body)
signal health_changed(new_health)
# TODO
# Doublejump? is something we should add
# Clean up code and add documentation

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
var has_double_jumped : bool = false
var has_landed : bool = false
#var animation_locked : bool = false
var in_knockback: bool = false
var jumping : bool = false


var health : int = start_health

# Raycast vars
const RAY_LEN = 600

func _ready():
	print("player loaded")
	$HangTimer.wait_time = hangtime
	$JumpTimer.wait_time = jumptime

func _physics_process(delta):
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

	if is_on_floor():
		# Apply velocity according to surface tangent.
		velocity += base_accel * delta * tangent.normalized() * friction
		velocity = velocity.min(max_speed)
	if not jumping:
		velocity.y += gravity * delta
	if is_on_floor():
		if not anim_sprite.is_playing():
			anim_sprite.play("skike")
		anim_sprite.rotation = angle

	has_landed = check_if_landing()
	move_and_slide()

func _raycast() -> Dictionary:
	var space_rid = get_world_2d().space
	var space_state = PhysicsServer2D.space_get_direct_state(space_rid)
	var end := position + Vector2.DOWN * RAY_LEN
	var query = PhysicsRayQueryParameters2D.create(position, end)
	return space_state.intersect_ray(query)



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
	match entity.entity_type:
		"enemy", "obstacle":
			if not in_knockback:
				_take_damage(entity, body)
				_get_knocked_back()
		"launch":
			_get_launched(entity)
		_:
			pass

func _take_damage(entity, body):
	# Different amounts of damage?
	SoundManager.skade_lyd_tromme()
	print("Player hit")
	health -= 1
	health_changed.emit(health)
	if health <= 0:
		die(body)

func _get_knocked_back():
	$KnockbackTimer.start()
	in_knockback = true
	jumping = false
	stored_velocity = Vector2(velocity.x, 0)
	velocity = Vector2.ZERO
	# anim_sprite.play("hurt")
	anim_sprite.modulate = Color.RED

func _get_launched(entity):
	jumping = true
	$HangTimer.start()
	velocity += entity.launch_vector

func _on_knockback_timer_timeout() -> void:
	in_knockback = false
	anim_sprite.modulate = orig_color
	# Restore speed but reduced
	velocity = stored_velocity * knockback_reduction

# Health upgrade?
# Old relic code
func _on_health_upgrade_detected(amount):
	print('player received health upgrade')
	health += amount

func _on_jump_button_pressed():
	if is_on_floor() and not in_knockback:
		has_double_jumped = false
		$JumpTimer.start()
		jumping = true
		anim_sprite.play("jump")
		velocity.y = jump_velocity

func _on_jump_timer_timeout() -> void:
	velocity.y = 0
	$HangTimer.start()

func _on_hang_timer_timeout() -> void:
	jumping = false
