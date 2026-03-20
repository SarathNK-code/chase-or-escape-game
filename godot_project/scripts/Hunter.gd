extends CharacterBody2D

signal target_reached(escaper_position: Vector2)

@export var base_speed: float = 125.0
@export var detection_radius: float = 200.0
@export var catch_distance: float = 24.0
@export var ai_reaction_time: float = 0.9  # seconds
@export var block_detection_distance: float = 40.0
@export var pathfinding_update_interval: float = 0.5  # Update pathfinding every 0.5 seconds

var target_position: Vector2
var ai_timer: float = 0.0
var distraction_timer: float = 0.0
var current_target: Node2D
var level_number: int = 1
var current_map: Array = []
var decoys: Array = []
var current_direction: Vector2 = Vector2.RIGHT
var is_controlled_by_player: bool = false
var speed: float = base_speed

# Enhanced AI variables
var current_path: Array = []
var path_index: int = 0
var last_target_position: Vector2
var stuck_timer: float = 0.0
var last_position: Vector2
var reroute_attempts: int = 0
var max_reroute_attempts: int = 3

func _ready():
	setup_visuals()
	setup_eyes()
	add_to_group("hunter")
	
	# Check if this Hunter should be AI-controlled
	check_ai_control_status()

func setup_visuals():
	# Create all visual elements since scene has no children
	
	# Create sprite
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	add_child(sprite)
	
	# Create gradient texture for hunter
	var gradient = Gradient.new()
	gradient.set_color(0, Color("#dc2626"))
	gradient.set_color(1, Color("#991b1b"))
	
	var gradient_texture = GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.width = 32
	gradient_texture.height = 32
	
	sprite.texture = gradient_texture
	
	# Create collision shape
	var collision = CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape = CircleShape2D.new()
	shape.radius = 8.0
	collision.shape = shape
	add_child(collision)
	
	# Create eyes container
	var eyes = Node2D.new()
	eyes.name = "Eyes"
	add_child(eyes)
	
	# Create eyes
	var eye_color = Color("#fecaca")
	var eye_texture = create_eye_texture(eye_color)
	
	var left_eye = Sprite2D.new()
	left_eye.name = "LeftEye"
	left_eye.position = Vector2(-3.5, 3.5)
	left_eye.texture = eye_texture
	eyes.add_child(left_eye)
	
	var right_eye = Sprite2D.new()
	right_eye.name = "RightEye"
	right_eye.position = Vector2(3.5, 3.5)
	right_eye.texture = eye_texture
	eyes.add_child(right_eye)

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
	var eyes = get_node_or_null("Eyes")
	if eyes:
		eyes.rotation = current_direction.angle()

func _process(delta):
	# Update AI behavior
	ai_timer += delta
	
	# Check if stuck and need rerouting
	if is_stuck():
		stuck_timer += delta
		if stuck_timer > 1.0:  # Stuck for 1 second
			force_reroute()
			stuck_timer = 0.0
	else:
		stuck_timer = 0.0
	
	# Update AI target periodically or when needed
	if ai_timer >= ai_reaction_time or needs_path_update():
		ai_timer = 0.0
		update_ai_target()
	
	# Update distraction timer
	if distraction_timer > 0:
		distraction_timer -= delta
	
	# Update eyes rotation
	if velocity.length() > 0:
		$Eyes.rotation = velocity.angle()

func is_stuck() -> bool:
	# Check if hunter hasn't moved significantly
	if last_position.distance_to(global_position) < 5.0:
		return true
	return false

func needs_path_update() -> bool:
	# Check if we need to update our path
	if current_target and last_target_position.distance_to(current_target.global_position) > 50.0:
		return true
	if current_path.size() == 0 or path_index >= current_path.size():
		return true
	return false

func update_ai_target():
	if distraction_timer > 0:
		# Hunter is distracted by decoy
		return
	
	# Find best target (escaper or decoy)
	var best_target = find_best_target()
	if best_target:
		current_target = best_target
		last_target_position = best_target.global_position
		calculate_path_to_target(best_target.global_position)

func calculate_path_to_target(target_pos: Vector2):
	# Calculate intelligent path using A* pathfinding
	current_path = find_path_astar(global_position, target_pos)
	path_index = 0
	reroute_attempts = 0
	
	if current_path.size() > 0:
		target_position = current_path[0]
	else:
		# Fallback to direct movement if no path found
		target_position = target_pos

func find_path_astar(start: Vector2, end: Vector2) -> Array:
	# Enhanced A* pathfinding implementation
	var start_tile = world_to_tile(start)
	var end_tile = world_to_tile(end)
	
	# Simple pathfinding using BFS with heuristic
	var open_set = [start_tile]
	var closed_set = {}
	var came_from = {}
	var g_score = {start_tile: 0}
	var f_score = {start_tile: heuristic(start_tile, end_tile)}
	
	while open_set.size() > 0:
		# Find node with lowest f_score
		var current = open_set[0]
		var current_index = 0
		for i in range(open_set.size()):
			if f_score.get(open_set[i], INF) < f_score.get(current, INF):
				current = open_set[i]
				current_index = i
		
		if current == end_tile:
			# Reconstruct path
			var path = []
			var temp = current
			while came_from.has(temp):
				path.append(tile_to_world(temp))
				temp = came_from[temp]
			path.append(tile_to_world(start_tile))
			path.reverse()
			return path
		
		open_set.remove_at(current_index)
		closed_set[current] = true
		
		# Check neighbors
		var neighbors = get_walkable_neighbors(current)
		for neighbor in neighbors:
			if closed_set.has(neighbor):
				continue
			
			var tentative_g = g_score.get(current, INF) + 1
			
			if not open_set.has(neighbor):
				open_set.append(neighbor)
			elif tentative_g >= g_score.get(neighbor, INF):
				continue
			
			came_from[neighbor] = current
			g_score[neighbor] = tentative_g
			f_score[neighbor] = tentative_g + heuristic(neighbor, end_tile)
	
	return []  # No path found

func heuristic(a: Vector2, b: Vector2) -> float:
	# Manhattan distance heuristic
	return abs(a.x - b.x) + abs(a.y - b.y)

func world_to_tile(world_pos: Vector2) -> Vector2:
	return Vector2(int(world_pos.x / 40.0), int(world_pos.y / 40.0))

func tile_to_world(tile_pos: Vector2) -> Vector2:
	return Vector2(tile_pos.x * 40.0 + 20.0, tile_pos.y * 40.0 + 20.0)

func get_walkable_neighbors(tile: Vector2) -> Array:
	var neighbors = []
	var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	
	for direction in directions:
		var neighbor = tile + direction
		if is_walkable_tile(neighbor):
			neighbors.append(neighbor)
	
	return neighbors

func is_walkable_tile(tile: Vector2) -> bool:
	# Check if current_map is valid and not empty
	if current_map.is_empty():
		print("DEBUG: Hunter - current_map is empty!")
		return false
	
	# Check if map has at least one row
	if current_map.size() == 0:
		print("DEBUG: Hunter - current_map has no rows!")
		return false
	
	# Check if first row has columns
	if current_map[0].is_empty():
		print("DEBUG: Hunter - current_map first row is empty!")
		return false
	
	# Check bounds with proper validation
	if tile.x < 0 or tile.x >= current_map[0].size():
		return false
	if tile.y < 0 or tile.y >= current_map.size():
		return false
	
	# Safely access the map data
	return current_map[tile.y][tile.x] == 0

func force_reroute():
	# Force a reroute when stuck
	reroute_attempts += 1
	if reroute_attempts <= max_reroute_attempts:
		# Try to find alternative path
		if current_target:
			calculate_path_to_target(current_target.global_position)
			print("Hunter rerouting (attempt %d/%d)" % [reroute_attempts, max_reroute_attempts])
	else:
		# Reset and try direct approach
		reroute_attempts = 0
		if current_target:
			target_position = current_target.global_position
			print("Hunter using direct approach after failed rerouting")

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
	# Check if map data is valid
	if current_map.is_empty() or current_map.size() == 0:
		return false
	
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

func _physics_process(delta):
	if is_controlled_by_player:
		# Player-controlled movement when user selects Hunter
		handle_player_input(delta)
	else:
		# Enhanced AI movement along calculated path
		handle_ai_movement(delta)
	
	# Actually move the character
	move_and_slide()

func handle_player_input(delta):
	# Handle movement input for player-controlled Hunter
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	if Input.is_action_pressed("move_up"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_down"):
		input_dir.y += 1
	
	# Normalize diagonal movement
	if input_dir.length() > 0:
		input_dir = input_dir.normalized()
	
	# Set velocity and move
	velocity = input_dir * speed
	print("Hunter: Player input direction: ", input_dir)

func handle_ai_movement(delta):
	# Enhanced AI movement along calculated path
	if current_path.size() > 0 and path_index < current_path.size():
		# Move along path
		target_position = current_path[path_index]
		var direction = (target_position - global_position).normalized()
		velocity = direction * speed
		
		# Check if reached current waypoint
		if global_position.distance_to(target_position) < 10.0:
			path_index += 1
			if path_index >= current_path.size():
				# Reached end of path, recalculate
				if current_target:
					calculate_path_to_target(current_target.global_position)
	elif current_target:
		# No path or path completed, move directly to target
		var direction = (current_target.global_position - global_position).normalized()
		velocity = direction * speed
	else:
		# No target, slow down
		velocity = velocity.move_toward(Vector2.ZERO, speed * delta)
	
	# Store last position for stuck detection
	last_position = global_position
	
	
func set_target(target: Node2D):
	current_target = target
	target_position = target.global_position

func set_level_data(level: int, map_data: Array):
	print("DEBUG: Hunter set_level_data called - level: ", level, " map_data size: ", map_data.size())
	level_number = level
	current_map = map_data
	
	# Validate map data
	if current_map.is_empty():
		print("DEBUG: Hunter - Received empty map data!")
	elif current_map.size() == 0:
		print("DEBUG: Hunter - Map data has no rows!")
	else:
		print("DEBUG: Hunter - Map data loaded successfully: ", current_map.size(), " rows, ", current_map[0].size(), " columns")
	
	# Increase speed with level
	speed = base_speed + (level - 1) * 10
	# Decrease reaction time with level
	ai_reaction_time = max(0.3, 0.9 - (level - 1) * 0.1)
	print("DEBUG: Hunter speed set to: ", speed, " reaction time: ", ai_reaction_time)

func add_decoy_reference(decoy: Node2D):
	decoys.append(decoy)

func remove_decoy_reference(decoy: Node2D):
	decoys.erase(decoy)

func check_ai_control_status():
	# Check if user selected Escaper (this Hunter should be AI-controlled)
	var game_settings = get_node_or_null("/root/GameSettings")
	if game_settings:
		var player_character = game_settings.get("player_character")
		if player_character == null:
			player_character = "escaper"  # Default fallback
		is_controlled_by_player = (player_character == "hunter")
		print("Hunter AI control status: ", not is_controlled_by_player, " (player chose: ", player_character, ")")
	else:
		# Fallback: use AI control by default
		is_controlled_by_player = false
		print("Hunter AI: GameSettings not found, using AI control")
