extends Enemy

const BASE_SPEED : float = 30
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var start_pos : Vector2

# Whether the npc is activated and moves, visibleonscreen turns this on when we can see the pedestrian
var active := false
@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	print("fotgjenger 1 loaded")
	start_pos = position
	# Select a random pedestrian sprite to use
	var pedestrian_sprites = Array(sprite.sprite_frames.get_animation_names())
	sprite.animation = pedestrian_sprites.pick_random()
	sprite.play()

func _physics_process(delta):
	if active:
		velocity += Vector2.LEFT * BASE_SPEED * delta
		velocity.y += gravity * delta
		move_and_slide()

func _on_area_2d_body_entered(body: Node2D) -> void:
		# Spilleren treffer hinderet
	print("hit player")
	if body is Player:
		body._on_hit(self, body)

func _on_visible_on_screen_enabler_2d_screen_entered() -> void:
	active = true
