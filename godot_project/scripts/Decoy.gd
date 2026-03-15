extends Area2D
class_name Decoy

signal expired(decoy: Decoy)

@export var lifespan: float = 5.0  # 5 seconds
@export var distract_distance: float = 200.0
@export var pulse_speed: float = 0.004

var created_time: float = 0.0
var current_time: float = 0.0
var original_scale: Vector2
var pulse_time: float = 0.0

func _ready():
	original_scale = scale
	created_time = Time.get_time_dict_from_system().get("second", 0.0)
	setup_visuals()
	setup_timer_ring()

func setup_visuals():
	# Create gradient texture for decoy
	var gradient = Gradient.new()
	gradient.set_color(0, Color("#06b6d4"))
	gradient.set_color(0.65, Color("#06b6d4"))
	gradient.set_color(1, Color("#0891b2"))
	
	var gradient_texture = GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.width = 20
	gradient_texture.height = 20
	
	$Sprite2D.texture = gradient_texture

func setup_timer_ring():
	# Create circular timer ring
	var points = []
	var segments = 64
	for i in range(segments + 1):
		var angle = (float(i) / segments) * TAU
		var radius = 16.0  # DECOY_RADIUS + 6
		points.append(Vector2(cos(angle) * radius, sin(angle) * radius))
	
	$TimerRing.points = points

func _process(delta):
	current_time += delta
	pulse_time += delta
	
	# Calculate life ratio
	var life_ratio = get_life_ratio()
	
	if life_ratio <= 0:
		expire()
		return
	
	# Pulsing effect
	var pulse = sin(pulse_time * pulse_speed * 100) * 0.2 + 0.8
	var alpha = 0.65 * life_ratio
	
	# Update visual properties
	modulate.a = alpha
	scale = original_scale * pulse
	$Glow.energy = 0.2 * life_ratio
	$Glow.color = Color("#06b6d4")
	
	# Update timer ring
	update_timer_ring(life_ratio)

func update_timer_ring(life_ratio: float):
	var segments = 64
	var active_segments = int(segments * life_ratio)
	var points = []
	
	for i in range(active_segments + 1):
		var angle = (float(i) / segments) * TAU - PI / 2
		var radius = 16.0
		points.append(Vector2(cos(angle) * radius, sin(angle) * radius))
	
	$TimerRing.points = points
	$TimerRing.default_color.a = 0.8 * life_ratio

func get_life_ratio() -> float:
	var elapsed = current_time
	return max(0.0, 1.0 - (elapsed / lifespan))

func expire():
	expired.emit(self)
	
	# Fade out animation
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_property(self, "scale", original_scale * 0.5, 0.3)
	tween.tween_callback(queue_free)

func get_distract_score() -> float:
	var life_ratio = get_life_ratio()
	return 60.0 * life_ratio  # Priority score for AI targeting

func is_hunter_in_range(hunter_position: Vector2) -> bool:
	var distance = global_position.distance_to(hunter_position)
	return distance <= distract_distance

func _on_body_entered(body):
	if body is Hunter:
		# Hunter touched decoy - apply distraction effect
		var hunter = body as Hunter
		if hunter.has_method("apply_distraction"):
			hunter.apply_distraction(self)

func get_decoy_data() -> Dictionary:
	return {
		"position": global_position,
		"life_ratio": get_life_ratio(),
		"time_remaining": lifespan * get_life_ratio(),
		"is_active": get_life_ratio() > 0
	}
