extends Enemy
class_name Bird
## Bird enemy
## Swoops in over the player, hovers around in a circle and then attacks
## Spawned by birdspawner

var player : Player

enum State {
	swooping,
	hovering,
	warning,
	attacking
}

var _state := State.swooping
@onready var sprite : AnimatedSprite2D = $Sprite2D
@onready var warning_sprite : Sprite2D = $WarningSprite



var swoop_offset := Vector2(400, -150)
var swoop_speed : float = 400
var swoop_delta : float = 5

var hovertime_min : float = 2
var hovertime_max : float = 4

var hover_offset := Vector2(200, -80)
var hovercycle_radius : float = 20
# How far around the hover cycle we are as a vector
var hovercycle := Vector2(hovercycle_radius, 0)
# We want a 180 degree hover in .5 seconds, so in 30 frames PI, so PI/30 per frame
var hovercycle_speed : float = PI

var warning_timer : Timer
var warning_time : float = 0.3

var attack_coeff : float
var attack_speed : float = 600
var attack_offset := Vector2(-10, -20)

# Current offset relative to the player, basically the offset we want to be at currently
var relative_position := swoop_offset

@onready var hitbox : Area2D = $Hitbox

var hover_timer : Timer

func initialize(_player : Node2D):
	if _player:
		player = _player
	global_position = player.global_position + relative_position

func _ready():
	velocity = Vector2.ZERO
	hover_timer = Timer.new()
	hover_timer.wait_time = randf_range(hovertime_min, hovertime_max)
	hover_timer.one_shot = true
	hover_timer.timeout.connect(_on_hover_timer_timeout)
	add_child(hover_timer)

	warning_timer = Timer.new()
	warning_timer.wait_time = warning_time
	warning_timer.one_shot = true
	warning_timer.timeout.connect(_on_warning_timer_timeout)
	add_child(warning_timer)

func _physics_process(delta):
	match _state:
		State.swooping:
			_swoop(delta)
		State.hovering:
			_hover(delta)
		State.warning:
			_warn(delta)
		State.attacking:
			_attack(delta)
	global_position = player.global_position + relative_position


# State transitions
func _transition_state():
	match _state:
		State.swooping:
			_state = State.hovering
			hover_offset = relative_position
			sprite.play("flap")
			hover_timer.start()
		State.hovering:
			_state = State.warning
			warning_timer.start()
			sprite.play("warn")
			warning_sprite.visible = true
			SoundManager.bird_warn()
		State.warning:
			_state = State.attacking
			hitbox.set_collision_mask_value(player.COLLISION_LAYER_PLAYER, true)
			# Calculate "a" of the parabola we attack through
			attack_coeff = (relative_position.y - attack_offset.y) / pow(relative_position.x - attack_offset.x, 2)
			sprite.play("attack")

# Swoop in at spawn until we get to where we want to hover
func _swoop(delta):
	var distance = relative_position.distance_to(hover_offset)
	# Swoop until we get close to the hover_offset
	if distance > swoop_delta:
		relative_position = relative_position.move_toward(hover_offset, swoop_speed * delta)
	else:
		_transition_state()

	# Fly around in a circle
func _hover(delta):
	hovercycle = hovercycle.rotated(hovercycle_speed * delta)
	relative_position = hover_offset + hovercycle

func _warn(delta):
	pass

func _attack(delta):
	# Attack the player by swooping down through him
	# The shape of the attack is a parabola with the player + attack_offset as the vertex
	relative_position.x -= attack_speed * delta
	# Calculate y of the point on the parabola
	relative_position.y = attack_coeff * pow(relative_position.x - attack_offset.x, 2) + attack_offset.y

func _on_hover_timer_timeout() -> void:
	_transition_state()

func _on_warning_timer_timeout() -> void:
	_transition_state()

func _on_area_2d_body_entered(body):
	if body is Player:
		# Spilleren treffer hinderet
		body._on_hit(self, body)
		hitbox.set_collision_mask_value(player.COLLISION_LAYER_PLAYER, false)

# Delete bird when it exits screen
func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	print("Delete bird")
	queue_free()
