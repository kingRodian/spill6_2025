extends CharacterBody2D
class_name Player

# Raycast vars
const RAY_LEN = 600

# Jump buffer
## The number of frames after leaving a ledge where jumping is still allowed.
const COYOTE_FRAMES := 3
## The number of frames early a jump input will still trigger a jump when landing.
const LANDING_FRAMES := 4
## The number of consecutive frames the character has been falling for.
## Is always 0 when on the ground.
var falling_frames : int
## How many frames ago we got our newest jump input. Is -1 when no jump has been inputted.
var jump_frame := -1


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
## Whether the player has jumped in the current coyote frames.
var has_jumped : bool = false
var is_alive := true

@onready var health : int = start_health


func _ready():
	print("player loaded")
	$HangTimer.wait_time = hangtime
	$JumpTimer.wait_time = jumptime

func _physics_process(delta):
	# Check for player actions
	if is_alive:
		if Input.is_action_just_pressed("jump"):
			jump_frame = 0

	jump_check()

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
	if entity is Enemy or entity is Obstacle:
		if not in_knockback:
			get_knocked_back()
			take_damage()
	if entity is Launcher:
		get_launched(entity)
	else:
		pass

func take_damage(damage := 1):
	SoundManager.skade_lyd_tromme()
	print("Player hit")
	health -= damage
	health_changed.emit(health)
	if health <= 0:
		die()

func get_knocked_back():
	$KnockbackTimer.start()
	in_knockback = true
	is_jumping = false
	stored_velocity = Vector2(velocity.x, 0)
	velocity = Vector2.ZERO
	# anim_sprite.play("hurt")
	anim_sprite.modulate = Color.RED

func get_launched(entity):
	is_jumping = true
	$HangTimer.start()
	velocity += entity.launch_vector

func _on_knockback_timer_timeout() -> void:
	in_knockback = false
	anim_sprite.modulate = orig_color
	# Restore speed but reduced
	velocity = stored_velocity * knockback_reduction

## Checks if a jump should trigger, if so it triggers a jump.
func jump_check():
	# Count the frames we have been in air.
	if not is_on_floor():
		falling_frames += 1
	else:
		falling_frames = 0

	var is_jump_buffer = jump_frame <= LANDING_FRAMES and is_on_floor()
	var is_coyote_frames = falling_frames <= COYOTE_FRAMES and not is_on_floor()

	if jump_frame != -1 and (is_jump_buffer or is_coyote_frames) and not has_jumped:
		if is_jump_buffer and jump_frame != 0:
			print("You jumped %s frames to early" % [jump_frame])
		if is_coyote_frames:
			print("You jumped %s frames to late" % [falling_frames])

		jump()
		jump_frame = -1

	if jump_frame != -1:
		jump_frame += 1

	# Reset jump after known safe delay
	if falling_frames > COYOTE_FRAMES and has_jumped:
		has_jumped = false
		jump_frame = -1

func jump():
	$JumpTimer.start()
	is_jumping = true
	has_jumped = true
	anim_sprite.play("jump")
	velocity.y = jump_velocity

func _on_jump_timer_timeout() -> void:
	velocity.y = 0
	$HangTimer.start()

func _on_hang_timer_timeout() -> void:
	is_jumping = false
