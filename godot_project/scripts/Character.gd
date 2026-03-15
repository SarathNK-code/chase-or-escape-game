extends CharacterBody2D
class_name Character

signal coin_collected(value: int, is_bonus: bool)
signal life_lost()

@export var speed: float = 160.0
@export var character_type: String = "escaper"  # "escaper" or "hunter"
@export var color_primary: Color = Color.BLUE
@export var color_secondary: Color = Color.CYAN
@export var glow_color: Color = Color.CYAN

var current_direction: Vector2 = Vector2.RIGHT
var is_controlled_by_player: bool = false
var can_be_caught: bool = true
var grace_timer: float = 0.0

func _ready():
	setup_visuals()
	if character_type == "hunter":
		$Glow.color = Color.RED
		$Glow.energy = 0.8

func setup_visuals():
	# Create gradient texture for the character
	var gradient = Gradient.new()
	if character_type == "escaper":
		gradient.set_color(0, Color("#60a5fa"))
		gradient.set_color(1, Color("#2563eb"))
	else:
		gradient.set_color(0, Color("#dc2626"))
		gradient.set_color(1, Color("#991b1b"))
	
	var gradient_texture = GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.width = 32
	gradient_texture.height = 32
	
	$Sprite2D.texture = gradient_texture
	
	# Setup direction indicator
	$DirectionIndicator.points = [Vector2.ZERO, current_direction * 12]

func _physics_process(delta):
	if grace_timer > 0:
		grace_timer -= delta
		can_be_caught = grace_timer <= 0
	
	if is_controlled_by_player:
		handle_player_input(delta)
	
	# Update direction indicator
	if velocity.length() > 0:
		current_direction = velocity.normalized()
		$DirectionIndicator.points = [Vector2.ZERO, current_direction * 12]
	
	move_and_slide()

func handle_player_input(delta):
	var input_dir = Vector2.ZERO
	
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	if Input.is_action_pressed("move_up"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_down"):
		input_dir.y += 1
	
	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()
		velocity = input_dir * speed
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed * delta)

func set_player_control(controlled: bool):
	is_controlled_by_player = controlled

func start_grace_period(duration: float):
	grace_timer = duration
	can_be_caught = false
	# Visual feedback for grace period
	modulate = Color.GREEN

func _on_grace_period_ended():
	can_be_caught = true
	modulate = Color.WHITE
