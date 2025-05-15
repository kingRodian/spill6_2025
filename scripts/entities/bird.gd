extends Enemy
class_name Bird
## Bird enemy
## Swoops in over the player, hovers around in a circle and then attacks
## Spawned by birdspawner

var player : Node2D

enum State {
	swooping,
	hovering,
	warning,
	attacking
}

var _state := State.swooping
var sprite : AnimatedSprite2D

var hovertime_min : float = 2
var hovertime_max : float = 4

var hover_offset := Vector2(20, -160)
var hovercycle_radius : float = 20
# How far around the hover cycle we are as a vector
var hovercycle := Vector2(hovercycle_radius, 0)
# We want a 180 degree hover in .5 seconds, so in 30 frames PI, so PI/30 per frame
var hovercycle_speed : float = PI / 30

var warning_timer : Timer
var warning_time : float = 0.3

var swoop_offset := Vector2(200, -250)
var swoop_speed : float = 8.0
var swoop_delta : float = 10.0

var attack_speed : float = swoop_speed
var attack_offset := Vector2(0, -125)
var attack_direction : Vector2

# Current offset relative to the player, basically the offset we want to be at currently
var relative_position : Vector2

var hover_timer : Timer

func initialize(_player : Node2D):
	player = _player
	relative_position = swoop_offset

func _ready():
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

	position = player.position + relative_position
	sprite = $Sprite2D

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

# Swoop in at spawn until we get to where we want to hover
func _swoop(delta):
	var distance = relative_position.distance_to(hover_offset)
	# Move our relative position towards the target relative position, which is to hover
	if distance > swoop_delta:
		relative_position = relative_position.move_toward(hover_offset, swoop_speed)
		position = player.position + relative_position
	else:
		_state = State.hovering
		sprite.play("flap")
		hover_timer.start()

	# Fly around in a circle
func _hover(delta):
	hovercycle = hovercycle.rotated(hovercycle_speed)
	position = player.position + hover_offset + hovercycle

func _warn(delta):
	position = player.position + relative_position

func _attack(delta):
	# Uncouple movement from player at this point and move blindly in the attack dir
	position = position + attack_direction * attack_speed

func _on_hover_timer_timeout() -> void:
	_state = State.warning
	relative_position = position - player.position
	warning_timer.start()
	sprite.play("warn")
	SoundManager.bird_warn()

func _on_warning_timer_timeout() -> void:
	_state = State.attacking
	# We want to attack the head of the guy
	attack_direction = relative_position.direction_to(attack_offset)
	print("Relative pos: " + str(relative_position))
	print("Attack dir: " + str(attack_direction))
	sprite.play("attack")

func _on_area_2d_body_entered(body):
	if body is Player:
		# Spilleren treffer hinderet
		body._on_hit(self, body)

# Delete bird when it exits screen
func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	print("Delete bird")
	queue_free()
