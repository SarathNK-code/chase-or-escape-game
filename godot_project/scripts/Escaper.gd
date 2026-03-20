extends CharacterBody2D

signal decoy_dropped(position: Vector2)
signal all_coins_collected()
signal coin_collected(value: int, is_bonus: bool)
signal life_lost()

@export var max_decoys: int = 3
@export var decoys_remaining: int = 3
@export var lives: int = 3

var footprints: Array = []
var footprint_timer: float = 0.0
var footprint_interval: float = 0.125  # 8 frames at 60fps
var grace_period_timer: float = 0.0
var in_grace_period: bool = false

# AI variables for when user controls Hunter
var is_ai_controlled: bool = false
var hunter_target: Node2D = null
var coin_targets: Array = []
var current_coin_target: Node2D = null
var ai_speed: float = 125.0  # Same as Hunter base speed
var escape_direction: Vector2 = Vector2.ZERO
var last_hunter_position: Vector2 = Vector2.ZERO
var danger_threshold: float = 150.0  # Distance to consider hunter dangerous

# Pathfinding variables (similar to Hunter)
var current_map: Array = []
var current_path: Array = []
var path_index: int = 0
var last_target_position: Vector2
var stuck_timer: float = 0.0
var last_position: Vector2
var reroute_attempts: int = 0
var max_reroute_attempts: int = 3

# Respawn state to prevent AI interference
var is_respawning: bool = false
var respawn_timer: float = 0.0

func _ready():
	setup_visuals()
	add_to_group("escaper")
	
	# Check if this Escaper should be AI-controlled
	check_ai_control_status()
	
	# Find hunter reference if AI-controlled
	if is_ai_controlled:
		find_hunter_reference()
		find_coin_targets()  # Initial coin detection
	else:
		find_coin_targets()

func setup_visuals():
	# Create all visual elements since scene has no children
	
	# Create sprite
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	add_child(sprite)
	
	# Create simple gradient texture for escaper
	var gradient = Gradient.new()
	gradient.set_color(0, Color("#60a5fa"))
	gradient.set_color(1, Color("#3b82f6"))
	var gradient_texture = GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.width = 20
	gradient_texture.height = 20
	sprite.texture = gradient_texture
	
	# Create collision shape
	var collision = CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape = CircleShape2D.new()
	shape.radius = 8.0
	collision.shape = shape
	add_child(collision)
	
	# Remove glow effect to eliminate blue background square
	# var glow = PointLight2D.new()
	# glow.name = "Glow"
	# glow.energy = 0.4
	# glow.color = Color("#60a5fa")
	# glow.texture_scale = 0.6
	# add_child(glow)

func _physics_process(delta):
	# Handle grace period timer countdown (for invulnerability)
	if in_grace_period:
		grace_period_timer -= delta
		if grace_period_timer <= 0:
			in_grace_period = false
			print("Escaper grace period ended - now vulnerable")
			# Reset visual feedback
			var sprite = get_node_or_null("Sprite2D")
			if sprite:
				sprite.modulate = Color.WHITE
	
	# Movement logic (executed immediately after respawn)
	if is_ai_controlled:
		# AI mode with intelligent coin collection
		update_intelligent_ai_behavior(delta)
	else:
		# Player-controlled behavior when user controls Escaper
		handle_player_input(delta)
	
	move_and_slide()  # Make sure to actually move!

func handle_player_input(delta):
	# Handle movement input with collision prevention
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
	
	# Calculate desired velocity
	var desired_velocity = input_dir * 125.0  # Same as AI speed
	
	# Check for wall collisions before applying movement
	if input_dir != Vector2.ZERO:
		var test_pos = global_position + desired_velocity * delta
		if is_position_safe_from_walls(test_pos):
			velocity = desired_velocity
		else:
			# Try to find safe alternative movement
			velocity = find_safe_alternative_velocity(input_dir, 125.0)
			print("Escaper: Player movement blocked, finding alternative")
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()

func update_intelligent_ai_behavior(delta):
	# Don't run AI while respawning
	if is_respawning:
		respawn_timer -= delta
		if respawn_timer <= 0:
			is_respawning = false
		return
	
	# Intelligent Escaper AI when user controls Hunter
	if not hunter_target:
		find_hunter_reference()
		if not hunter_target:
			return
	
	# Update coin targets more frequently and validate them
	find_coin_targets()  # Update every frame to ensure fresh targets
	
	# Calculate hunter threat
	var hunter_distance = global_position.distance_to(hunter_target.global_position)
	var hunter_direction = (hunter_target.global_position - global_position).normalized()
	
	# Find best target (coin or escape position)
	var target_position: Vector2
	var best_coin = find_best_coin_target()
	
	if best_coin:
		var coin_direction = (best_coin.global_position - global_position).normalized()
		var coin_distance = global_position.distance_to(best_coin.global_position)
		
		# AI decision making
		if hunter_distance < danger_threshold:
			# Hunter is close - prioritize escape
			target_position = global_position - hunter_direction * 200  # Escape direction
		else:
			# Hunter is far - prioritize coin collection
			if coin_distance < 100:
				target_position = best_coin.global_position
			else:
				# Balance between coin collection and hunter avoidance
				var escape_weight = 1.0 - (hunter_distance / danger_threshold)
				var coin_weight = 1.0 - (coin_distance / 300.0)
				
				if escape_weight > coin_weight:
					target_position = global_position - hunter_direction * 150
				else:
					target_position = best_coin.global_position
	else:
		# No coins available - move in circle to find coins
		var time = Time.get_ticks_msec() / 1000.0
		var angle = time * 0.5
		target_position = global_position + Vector2(cos(angle), sin(angle)) * 150
	
	# Move toward target with smooth movement
	move_toward_target(target_position, delta)

func move_toward_target(target_pos: Vector2, delta: float):
	var direction = (target_pos - global_position).normalized()
	var desired_velocity = direction * ai_speed
	
	# Enhanced collision detection before moving
	var test_pos = global_position + desired_velocity * delta
	if is_position_safe_from_walls(test_pos):
		velocity = desired_velocity
	else:
		# Hit wall, try to find alternative direction
		velocity = find_safe_alternative_velocity(direction, ai_speed)
		print("Escaper: Wall detected, finding alternative path")

func is_position_safe_from_walls(test_pos: Vector2) -> bool:
	# Enhanced wall detection with better boundaries
	var margin = 10.0  # Margin for safety
	
	# Check map boundaries
	if test_pos.x < margin or test_pos.x > 800 - margin:
		return false
	if test_pos.y < margin or test_pos.y > 600 - margin:
		return false
	
	# Check wall collisions using multiple sample points
	var sample_points = [
		test_pos,
		test_pos + Vector2(margin, 0),
		test_pos + Vector2(-margin, 0),
		test_pos + Vector2(0, margin),
		test_pos + Vector2(0, -margin)
	]
	
	for point in sample_points:
		if is_wall_at_position(point):
			return false
	
	return true

func is_wall_at_position(position: Vector2) -> bool:
	# Check if position is in a wall
	var level = get_tree().get_first_node_in_group("level")
	if level and level.has_method("get_level_data"):
		var map_data = level.get_level_data()
		if not map_data.is_empty():
			var tile_x = int(position.x / 40.0)
			var tile_y = int(position.y / 40.0)
			
			# Check bounds
			if tile_x >= 0 and tile_x < map_data[0].size() and tile_y >= 0 and tile_y < map_data.size():
				return map_data[tile_y][tile_x] == 1
	
	return false

func find_safe_alternative_velocity(desired_direction: Vector2, speed: float) -> Vector2:
	# Try multiple alternative directions to find safe movement
	var alternatives = []
	
	# Try perpendicular directions first
	alternatives.append(Vector2(-desired_direction.y, desired_direction.x).normalized() * speed * 0.8)
	alternatives.append(Vector2(desired_direction.y, -desired_direction.x).normalized() * speed * 0.8)
	
	# Try diagonal alternatives
	alternatives.append(Vector2(desired_direction.x + desired_direction.y, desired_direction.y - desired_direction.x).normalized() * speed * 0.7)
	alternatives.append(Vector2(desired_direction.x - desired_direction.y, desired_direction.y + desired_direction.x).normalized() * speed * 0.7)
	
	# Try reverse direction as last resort
	alternatives.append(-desired_direction.normalized() * speed * 0.5)
	
	# Test each alternative
	for alt_vel in alternatives:
		var test_pos = global_position + alt_vel * get_physics_process_delta_time()
		if is_position_safe_from_walls(test_pos):
			return alt_vel
	
	# If no safe alternative found, stop
	print("Escaper: No safe movement direction found, stopping")
	return Vector2.ZERO

func move_along_path(delta):
	print("Escaper: move_along_path called - path size: ", current_path.size(), " path_index: ", path_index)
	
	if current_path.size() > 0 and path_index < current_path.size():
		# Move along path
		var target_pos = current_path[path_index] * 40.0 + Vector2(20, 20)  # Convert tile to world position
		var direction = (target_pos - global_position).normalized()
		velocity = direction * ai_speed
		print("Escaper: Following path to ", target_pos, " direction: ", direction)
		
		# Check if reached current waypoint
		if global_position.distance_to(target_pos) < 10.0:
			path_index += 1
			print("Escaper: Reached waypoint, new path_index: ", path_index)
			if path_index >= current_path.size():
				# Reached end of path, recalculate
				if last_target_position != Vector2.ZERO:
					calculate_path_to_target(last_target_position)
	else:
		# No path, move directly to target
		if last_target_position != Vector2.ZERO:
			var direction = (last_target_position - global_position).normalized()
			velocity = direction * ai_speed
			print("Escaper: Moving directly to target - direction: ", direction, " target: ", last_target_position)
		else:
			# No target, just move randomly to test
			var random_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
			velocity = random_direction * ai_speed * 0.5  # Slower random movement
			print("Escaper: No target, moving randomly - direction: ", random_direction)
			# Try to find coins again
			find_coin_targets()

func check_if_stuck(delta):
	# Check if Escaper is stuck
	var distance_moved = global_position.distance_to(last_position)
	if distance_moved < 5.0:  # Moved less than 5 pixels
		stuck_timer += delta
		if stuck_timer > 1.0:  # Stuck for 1 second
			force_reroute()
			stuck_timer = 0.0
	else:
		stuck_timer = 0.0
	
	last_position = global_position

func force_reroute():
	# Force a reroute when stuck
	reroute_attempts += 1
	if reroute_attempts <= max_reroute_attempts:
		# Try to find alternative path
		if last_target_position != Vector2.ZERO:
			calculate_path_to_target(last_target_position)
			print("Escaper AI rerouting (attempt %d/%d)" % [reroute_attempts, max_reroute_attempts])
	else:
		# Reset attempts if too many reroutes
		reroute_attempts = 0
		current_path.clear()
		path_index = 0

func _process(delta):
	# Handle grace period timer
	if in_grace_period:
		grace_period_timer -= delta
		if grace_period_timer <= 0:
			in_grace_period = false
			# Visual feedback that grace period ended
			var sprite = get_node_or_null("Sprite2D")
			if sprite:
				sprite.modulate = Color.WHITE
	
	# Handle footprint generation for both AI and player
	footprint_timer += delta
	if footprint_timer >= footprint_interval and velocity.length() > 0:
		footprint_timer = 0.0
		add_footprint()
	
	# Clean up old footprints
	var current_time = Time.get_time_dict_from_system()
	footprints = footprints.filter(func(fp): 
		var fp_timestamp = fp.get("timestamp", 0)
		var current_second = current_time.get("second", 0)
		return current_second - fp_timestamp < 3.0
	)
	
	# Handle decoy dropping (only for player-controlled Escaper)
	if not is_ai_controlled and Input.is_action_just_pressed("drop_decoy") and decoys_remaining > 0:
		drop_decoy()

func check_ai_control_status():
	# Check if user selected Hunter (this Escaper should be AI-controlled)
	var game_settings = get_node_or_null("/root/GameSettings")
	
	if game_settings:
		var player_character = game_settings.get("player_character")
		if player_character == null:
			player_character = "escaper"  # Default fallback
		is_ai_controlled = (player_character == "hunter")
	else:
		# Fallback: check global or use default
		is_ai_controlled = false

func find_hunter_reference():
	# Find the Hunter node
	var hunters = get_tree().get_nodes_in_group("hunter")
	if hunters.size() > 0:
		hunter_target = hunters[0]

func find_coin_targets():
	# Find all coins in the scene and filter out collected ones
	coin_targets.clear()
	var coins = get_tree().get_nodes_in_group("coins")
	for coin in coins:
		if coin and coin.is_inside_tree() and is_coin_valid(coin):
			coin_targets.append(coin)

func is_coin_valid(coin: Node2D) -> bool:
	# Check if coin is still valid (not collected and visible)
	if not coin or not coin.is_inside_tree():
		return false
	
	# Check if coin has a method to determine if it's collected
	if coin.has_method("is_collected"):
		return not coin.is_collected()
	
	# Check if coin is visible (collected coins are usually hidden)
	if coin.has_method("is_visible_in_tree"):
		return coin.is_visible_in_tree()
	
	# Fallback: check if coin position is valid (not at origin or invalid position)
	var pos = coin.global_position
	return pos.x > 0 and pos.y > 0 and pos.x < 2000 and pos.y < 2000

func find_best_coin_target() -> Node2D:
	if coin_targets.is_empty():
		return null
	
	var best_coin = null
	var best_score = -999999
	
	for coin in coin_targets:
		if not is_coin_valid(coin):
			continue  # Skip invalid coins
		
		var coin_distance = global_position.distance_to(coin.global_position)
		var hunter_distance: float
		if hunter_target:
			hunter_distance = global_position.distance_to(hunter_target.global_position)
		else:
			hunter_distance = 999999
		
		# Score coins based on distance to us and danger from hunter
		var coin_score = 1000 - coin_distance * 2
		
		# Prefer coins that are safer from hunter
		if hunter_distance < danger_threshold:
			coin_score -= 500  # Penalize coins near hunter
		
		# Prefer bonus coins
		if coin.has_method("is_bonus") and coin.is_bonus():
			coin_score += 300
		
		if coin_score > best_score:
			best_score = coin_score
			best_coin = coin
	
	return best_coin

# Pathfinding functions (similar to Hunter)
func calculate_path_to_target(target_pos: Vector2):
	# Get level data for pathfinding
	var level = get_tree().get_first_node_in_group("level")
	if level and level.has_method("get_level_data"):
		current_map = level.get_level_data()
	else:
		print("Escaper AI: Cannot get level data for pathfinding")
		return
	
	# Calculate path using BFS
	var start_tile = Vector2(int(global_position.x / 40.0), int(global_position.y / 40.0))
	var end_tile = Vector2(int(target_pos.x / 40.0), int(target_pos.y / 40.0))
	
	current_path = find_path_bfs(start_tile, end_tile)
	path_index = 0
	
	print("Escaper AI: Path calculated with ", current_path.size(), " waypoints")

func find_path_bfs(start: Vector2, end: Vector2) -> Array:
	var queue = [start]
	var visited = {start: true}
	var came_from = {}
	
	while queue.size() > 0:
		var current = queue.pop_front()
		
		if current == end:
			# Reconstruct path
			var path = []
			var node = end
			while node != start:
				path.append(node)
				node = came_from[node]
			path.reverse()
			return path
		
		var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
		for direction in directions:
			var next = current + direction
			
			if not visited.has(next) and is_walkable_tile(next):
				visited[next] = true
				came_from[next] = current
				queue.append(next)
	
	return []  # No path found

func is_walkable_tile(tile: Vector2) -> bool:
	if current_map.is_empty():
		return false
	if tile.x < 0 or tile.x >= current_map[0].size():
		return false
	if tile.y < 0 or tile.y >= current_map.size():
		return false
	return current_map[tile.y][tile.x] == 0

func is_position_safe_for_movement(test_pos: Vector2) -> bool:
	# Check if position is not in a wall
	var level = get_tree().get_first_node_in_group("level")
	if level and level.has_method("is_wall_at_position"):
		return not level.is_wall_at_position(test_pos)
	
	# Simple boundary check
	var screen_size = get_viewport().get_visible_rect().size
	var margin = 20  # Keep away from edges
	return test_pos.x > margin and test_pos.x < screen_size.x - margin and \
		   test_pos.y > margin and test_pos.y < screen_size.y - margin

func find_safe_velocity(desired_velocity: Vector2, delta: float) -> Vector2:
	# Try different velocities to find safe one
	var test_velocities = [
		desired_velocity,
		Vector2(desired_velocity.x, 0),  # Only X movement
		Vector2(0, desired_velocity.y),  # Only Y movement
		Vector2(-desired_velocity.x, desired_velocity.y),  # Reverse X
		Vector2(desired_velocity.x, -desired_velocity.y),  # Reverse Y
		Vector2(-desired_velocity.x, -desired_velocity.y),  # Reverse both
		Vector2(desired_velocity.y, desired_velocity.x),  # Swap X/Y
		Vector2(-desired_velocity.y, desired_velocity.x),  # Swap with reverse X
	]
	
	for test_vel in test_velocities:
		var test_pos = global_position + test_vel * delta
		if is_position_safe_for_movement(test_pos):
			print("Escaper: Found safe velocity: ", test_vel)
			return test_vel
	
	# If no safe velocity found, stop
	print("Escaper: No safe velocity found, stopping")
	return Vector2.ZERO

func find_alternative_direction():
	# Try different directions to find safe path
	var directions = [
		Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT,
		Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)
	]
	
	for direction in directions:
		var test_pos = global_position + direction.normalized() * 50
		if is_position_safe_for_movement(test_pos):
			escape_direction = direction.normalized()
			print("Escaper AI: Found safe direction: ", direction)
			return
	
	# If no safe direction found, stop
	escape_direction = Vector2.ZERO
	print("Escaper AI: No safe direction found, stopping")

func drop_decoy():
	if decoys_remaining > 0:
		decoys_remaining -= 1
		decoy_dropped.emit(global_position)
		print("Decoy dropped at position: ", global_position)

func add_footprint():
	var footprint = {
		"position": global_position,
		"timestamp": Time.get_time_dict_from_system().get("second", 0)
	}
	footprints.append(footprint)
	if footprints.size() > 50:  # Limit footprint count
		footprints.pop_front()

func collect_coin(value: int, is_bonus: bool):
	coin_collected.emit(value, is_bonus)

func lose_life():
	lives -= 1
	life_lost.emit()
	if lives <= 0:
		print("Game Over - No lives remaining")
	else:
		print("Life lost. Lives remaining: ", lives)

func respawn(new_position: Vector2):
	print("Escaper respawn function called at: ", new_position)
	
	# Instant respawn - no protection delay, just immediate grace period
	is_respawning = false  # Don't block movement
	respawn_timer = 0.0  # No protection timer
	
	# Force position update immediately
	global_position = new_position
	print("Escaper position set to: ", global_position)
	
	velocity = Vector2.ZERO
	print("Escaper velocity reset to zero")
	
	# Clear AI state to prevent interference
	current_path.clear()
	path_index = 0
	escape_direction = Vector2.ZERO
	last_target_position = Vector2.ZERO
	
	# Reset any stuck detection
	stuck_timer = 0.0
	reroute_attempts = 0
	
	# Start grace period AFTER position is set - this is the protection
	start_grace_period(8.0)  # 8 second grace period for instant protection
	print("Escaper grace period started (8 seconds) - NOW PROTECTED")

func start_grace_period(duration: float):
	grace_period_timer = duration
	in_grace_period = true
	# Visual feedback for grace period
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		sprite.modulate = Color(1, 1, 0.5, 1)  # Yellow tint during grace period

func is_in_grace_period() -> bool:
	return in_grace_period

func reset_for_new_level():
	decoys_remaining = max_decoys
	footprints.clear()
	velocity = Vector2.ZERO

func get_footprint_data() -> Array[Dictionary]:
	return footprints

func add_decoy():
	decoys_remaining += 1
	decoys_remaining = min(decoys_remaining, max_decoys)
