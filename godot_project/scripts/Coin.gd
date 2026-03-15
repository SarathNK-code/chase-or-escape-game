extends Area2D
class_name Coin

signal collected(value: int, is_bonus: bool)

@export var is_bonus: bool = false
@export var regular_value: int = 10
@export var bonus_value: int = 25
@export var pulse_speed: float = 0.006
@export var rotation_speed: float = 2.0

var collected: bool = false
var original_scale: Vector2
var pulse_time: float = 0.0
var rotation_angle: float = 0.0

func _ready():
	original_scale = scale
	setup_visuals()
	$AnimationPlayer.animation_finished.connect(_on_animation_finished)

func setup_visuals():
	# Create gradient texture for coin
	var gradient = Gradient.new()
	if is_bonus:
		gradient.set_color(0, Color("#fde047"))
		gradient.set_color(0.5, Color("#f59e0b"))
		gradient.set_color(1, Color("#d97706"))
	else:
		gradient.set_color(0, Color("#fde047"))
		gradient.set_color(0.7, Color("#f59e0b"))
		gradient.set_color(1, Color("#d97706"))
	
	var gradient_texture = GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.width = 16
	gradient_texture.height = 16
	
	$Sprite2D.texture = gradient_texture
	
	if is_bonus:
		$BonusIndicator.visible = true
		$Glow.energy = 0.6
		$Glow.color = Color("#fbbf24")

func _process(delta):
	if collected:
		return
	
	pulse_time += delta
	rotation_angle += rotation_speed * delta
	
	# Pulsing effect for bonus coins
	if is_bonus:
		var pulse = sin(pulse_time * pulse_speed * 100) * 0.3 + 0.7
		scale = original_scale * (1.0 + pulse * 0.3)
		$Glow.energy = 0.3 + pulse * 0.15
	
	# Rotation
	rotation = rotation_angle

func set_bonus(bonus: bool):
	is_bonus = bonus
	setup_visuals()

func collect():
	if collected:
		return
	
	collected = true
	var value = bonus_value if is_bonus else regular_value
	collected.emit(value, is_bonus)
	
	# Play collection animation
	play_collection_animation()

func play_collection_animation():
	if is_bonus:
		play_bonus_explosion()
	else:
		play_regular_collection()

func play_regular_collection():
	# Simple fade and scale animation
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_property(self, "scale", original_scale * 2.0, 0.3)
	tween.tween_callback(queue_free)

func play_bonus_explosion():
	# Explosion effect for bonus coins
	$ExplosionEffect.visible = true
	$Sprite2D.visible = false
	$BonusIndicator.visible = false
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Expand explosion ring
	for i in range(3):
		var ring = $ExplosionEffect.duplicate()
		add_child(ring)
		ring.visible = true
		tween.tween_property(ring, "scale", Vector2(3.0, 3.0), 0.6)
		tween.tween_property(ring, "modulate:a", 0.0, 0.6)
	
	# Fade out main coin
	tween.tween_property(self, "modulate:a", 0.0, 0.6)
	tween.tween_callback(queue_free)

func _on_animation_finished(anim_name):
	if anim_name == "collect":
		queue_free()

func _on_body_entered(body):
	if body is Escaper and not collected:
		collect()

func get_value() -> int:
	return bonus_value if is_bonus else regular_value

func get_collection_data() -> Dictionary:
	return {
		"value": get_value(),
		"is_bonus": is_bonus,
		"position": global_position
	}
