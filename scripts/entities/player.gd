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

@onready var collision := $CollisionShape2D
@onready var original_hitbox_pos = collision.position
@onready var ducking_hitbox_pos :Vector2 = original_hitbox_pos + Vector2(0, 5)
@onready var normal_hitbox : Shape2D = load("res://scenes/game/characters/raskeladden_hitbox.tres")
@onready var ducking_hitbox : Shape2D = load("res://scenes/game/characters/raskeladden_hitbox_ducking.tres")

# Movement vars
const base_accel : float = 250.0
const max_speed : Vector2 = Vector2(400.0, 600)
@export var knockback_reduction = .7
var stored_velocity : Vector2 = Vector2.ZERO

# Timers
const jump_time := 0.15
const hang_time := 0.1
const knockback_time := 0.4
const duck_time := 0.6

var jump_timer : Timer
var hang_timer : Timer
var knockback_timer : Timer
var duck_timer : Timer

# Flags
var is_skiking := true
#var animation_locked : bool = false
var in_knockback := false
var is_jumping := false
var is_alive := true
var is_ducking := false

@onready var health : int = start_health


func _ready():
	print("player loaded")
	jump_timer = Timer.new()
	jump_timer.wait_time = jump_time
	jump_timer.one_shot = true
	jump_timer.timeout.connect(_on_jump_timer_timeout)
	add_child(jump_timer)

	hang_timer = Timer.new()
	hang_timer.wait_time = hang_time
	hang_timer.one_shot = true
	hang_timer.timeout.connect(_on_hang_timer_timeout)
	add_child(hang_timer)

	knockback_timer = Timer.new()
	knockback_timer.wait_time = knockback_time
	knockback_timer.one_shot = true
	knockback_timer.timeout.connect(_on_knockback_timer_timeout)
	add_child(knockback_timer)

	duck_timer = Timer.new()
	duck_timer.wait_time = duck_time
	duck_timer.one_shot = true
	duck_timer.timeout.connect(_on_duck_timer_timeout)
	add_child(duck_timer)


func _physics_process(delta):
	# Check for player actions
	if is_alive:
		if Input.is_action_just_pressed(&"jump"):
			_on_jump_button_pressed()
		elif Input.is_action_just_pressed(&"duck"):
			_on_duck_button_pressed()

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
		if not anim_sprite.is_playing() and is_alive:
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
	velocity = Vector2.ZERO

	knockback_timer.stop()
	hang_timer.stop()
	jump_timer.stop()

func reset():
	print("Resetting")
	position = start_pos

	health = start_health
	health_changed.emit(health)

	anim_sprite.modulate = Color.WHITE

	stop()
	is_skiking = true
	is_alive = true

func die():
	print('player has died')
	is_alive = false
	anim_sprite.stop()
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
	knockback_timer.start()
	in_knockback = true
	is_jumping = false
	stored_velocity = Vector2(velocity.x, 0)
	velocity = Vector2.ZERO
	# anim_sprite.play("hurt")
	anim_sprite.modulate = Color.RED

func get_launched(entity):
	is_jumping = true
	hang_timer.start()
	velocity += entity.launch_vector

func _on_knockback_timer_timeout() -> void:
	in_knockback = false
	anim_sprite.modulate = orig_color
	# Restore speed but reduced
	velocity = stored_velocity * knockback_reduction

func _on_jump_button_pressed():
	if is_on_floor() and not in_knockback:
		jump_timer.start()
		is_jumping = true
		anim_sprite.play("jump")
		velocity.y = jump_velocity
		if is_ducking:
			# Reset hitbox
			_on_duck_timer_timeout()

func _on_duck_button_pressed():
	if not is_jumping and not is_ducking:
		is_ducking = true
		collision.shape = ducking_hitbox
		collision.position = ducking_hitbox_pos
		anim_sprite.play("duck")
		duck_timer.start()


func _on_jump_timer_timeout() -> void:
	velocity.y = 0
	hang_timer.start()

func _on_hang_timer_timeout() -> void:
	is_jumping = false

func _on_duck_timer_timeout() -> void:
	is_ducking = false
	collision.shape = normal_hitbox
	collision.position = original_hitbox_pos
