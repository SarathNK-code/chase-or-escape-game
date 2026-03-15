extends Character
class_name Hunter

signal target_reached(escaper_position: Vector2)

@export var base_speed: float = 125.0
@export var detection_radius: float = 200.0
@export var catch_distance: float = 24.0
@export var ai_reaction_time: float = 0.9  # seconds
@export var block_detection_distance: float = 40.0

var target_position: Vector2
var ai_timer: float = 0.0
var distraction_timer: float = 0.0
var current_target: Node2D
var level_number: int = 1
var current_map: Array = []
var decoys: Array[Node2D] = []

func _ready():
	super._ready()
	character_type = "hunter"
	speed = base_speed
	setup_visuals()
	setup_eyes()

func setup_visuals():
	# Create gradient texture for hunter
	var gradient = Gradient.new()
	gradient.set_color(0, Color("#dc2626"))
	gradient.set_color(1, Color("#991b1b"))
	
	var gradient_texture = GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.width = 32
	gradient_texture.height = 32
	
	$Sprite2D.texture = gradient_texture
	
	# Setup eyes
	var eye_color = Color("#fecaca")
	var eye_texture = create_eye_texture(eye_color)
	$Eyes/LeftEye.texture = eye_texture
	$Eyes/RightEye.texture = eye_texture

func create_eye_texture(color: Color) -> Texture2D:
	var image = Image.create(5, 5, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Draw circle for eye
	for x in range(5):
		for y in range(5):
			var dist = Vector2(x - 2, y - 2).length()
			if dist <= 2.5:
				image.set_pixel(x, y, color)
	
	return ImageTexture.create_from_image(image)

func setup_eyes():
	$Eyes.rotation = current_direction.angle()

func _process(delta):
	# Update AI behavior
	ai_timer += delta
	
	if ai_timer >= ai_reaction_time:
		ai_timer = 0.0
		update_ai_target()
	
	# Update distraction timer
	if distraction_timer > 0:
		distraction_timer -= delta
	
	# Update eyes rotation
	if velocity.length() > 0:
		$Eyes.rotation = velocity.angle()

func update_ai_target():
	if distraction_timer > 0:
		# Hunter is distracted by decoy
		return
	
	# Find best target (escaper or decoy)
	var best_target = find_best_target()
	if best_target:
		current_target = best_target
		target_position = best_target.global_position

func find_best_target() -> Node2D:
	var escaper = get_tree().get_first_node_in_group("escaper")
	if not escaper:
		return null
	
	# Check if blocked by walls
	if is_blocked_by_walls():
		# If blocked, immediately target escaper with aggressive pursuit
		return escaper
	
	# Consider decoys as targets
	var targets = [escaper]
	for decoy in decoys:
		if decoy and is_instance_valid(decoy):
			targets.append(decoy)
	
	# Score each target
	var best_target = escaper
	var best_score = -INF
	
	for target in targets:
		var score = calculate_target_score(target, escaper)
		if score > best_score:
			best_score = score
			best_target = target
	
	# Set distraction timer if targeting decoy
	if best_target != escaper:
		distraction_timer = max(2.0, 4.0 - (level_number - 1) * 0.2)
	
	return best_target

func calculate_target_score(target: Node2D, escaper: Node2D) -> float:
	var path_distance = calculate_path_distance(global_position, target.global_position)
	var direct_distance = global_position.distance_to(target.global_position)
	
	# Score based on path efficiency and priority
	var path_efficiency = direct_distance / max(path_distance, 1.0)
	var priority = 100.0 if target == escaper else 60.0
	
	return (priority * path_efficiency) - (path_distance * 0.5)

func is_blocked_by_walls() -> bool:
	# Check if hunter is blocked by walls in any direction
	var check_distance = block_detection_distance
	var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	
	for direction in directions:
		var check_pos = global_position + direction * check_distance
		if is_wall_at(check_pos):
			return true
	
	return false

func is_wall_at(position: Vector2) -> bool:
	var tile_pos = Vector2(
		int(position.x / 40.0),
		int(position.y / 40.0)
	)
	
	if tile_pos.x < 0 or tile_pos.x >= current_map[0].size():
		return true
	if tile_pos.y < 0 or tile_pos.y >= current_map.size():
		return true
	
	return current_map[tile_pos.y][tile_pos.x] == 1

func calculate_path_distance(start: Vector2, end: Vector2) -> float:
	# Simple pathfinding using BFS
	var start_tile = Vector2(int(start.x / 40.0), int(start.y / 40.0))
	var end_tile = Vector2(int(end.x / 40.0), int(end.y / 40.0))
	
	var queue = [start_tile]
	var visited = {start_tile: true}
	var distance = {start_tile: 0.0}
	
	while queue.size() > 0:
		var current = queue.pop_front()
		
		if current == end_tile:
			return distance[current]
		
		var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
		for direction in directions:
			var next = current + direction
			
			if not visited.has(next) and is_walkable_tile(next):
				visited[next] = true
				distance[next] = distance[current] + 1.0
				queue.append(next)
	
	# Fallback to direct distance if no path found
	return start.distance_to(end)

func is_walkable_tile(tile_pos: Vector2) -> bool:
	if tile_pos.x < 0 or tile_pos.x >= current_map[0].size():
		return false
	if tile_pos.y < 0 or tile_pos.y >= current_map.size():
		return false
	
	return current_map[tile_pos.y][tile_pos.x] == 0

func _physics_process(delta):
	if not is_controlled_by_player:
		# AI movement towards target
		if current_target:
			var direction = (target_position - global_position).normalized()
			velocity = direction * speed
		else:
			velocity = velocity.move_toward(Vector2.ZERO, speed * delta)
	
	super._physics_process(delta)

func set_level_data(level: int, map_data: Array):
	level_number = level
	current_map = map_data
	# Increase speed with level
	speed = base_speed + (level - 1) * 10
	# Decrease reaction time with level
	ai_reaction_time = max(0.3, 0.9 - (level - 1) * 0.1)

func add_decoy_reference(decoy: Node2D):
	decoys.append(decoy)

func remove_decoy_reference(decoy: Node2D):
	decoys.erase(decoy)
