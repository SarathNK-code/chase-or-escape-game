extends Node2D

signal level_setup_complete
signal coin_collected(value: int, is_bonus: bool)
signal all_coins_collected

var level_manager
var current_level: int = 1
var map_data: Array = []
var coins: Array = []
var decoys: Array = []
var tile_size: int = 40
var wall_tileset
var total_coins_created: int = 0  # Track actual coins created

func _ready():
	level_manager = preload("res://scripts/LevelManager.gd").new()
	add_child(level_manager)
	level_manager.level_loaded.connect(_on_level_loaded)
	
	# Fix the blue background in level
	hide_blue_background()

func hide_blue_background():
	# Hide or remove the blue background in level
	var background = $Background
	if background:
		background.visible = false
		background.modulate = Color.TRANSPARENT
		# Move it to the very back (no need to move child, just hide it)
		print("Level blue background hidden")

func setup_level(level_number: int):
	current_level = level_number
	level_manager.load_level(level_number)

func is_position_accessible(pos: Vector2) -> bool:
	# Check if position is accessible from spawn points
	var spawn_positions = get_spawn_positions()
	
	# Check accessibility from both escaper and hunter spawns
	for spawn_name in ["escaper", "hunter"]:
		if spawn_positions.has(spawn_name):
			var spawn_pos = spawn_positions[spawn_name]
			# Simple pathfinding check - ensure there's a clear path
			if not has_clear_path(spawn_pos, pos):
				return false
	
	return true

func has_clear_path(from: Vector2, to: Vector2) -> bool:
	# Simple line-of-sight check with some tolerance
	var steps = 10
	var step_size = (to - from) / steps
	
	for i in range(steps + 1):
		var check_pos = from + step_size * i
		var tile_x = int(check_pos.x / tile_size)
		var tile_y = int(check_pos.y / tile_size)
		
		# Check if position is within bounds and not a wall
		if tile_y >= 0 and tile_y < map_data.size() and tile_x >= 0 and tile_x < map_data[0].size():
			if map_data[tile_y][tile_x] == 1:  # Wall
				return false
		else:
			return false  # Out of bounds
	
	return true

func get_expanded_valid_positions(num_needed: int) -> Array:
	# Create accessible positions by ensuring connectivity
	var expanded_positions = []
	var spawn_positions = get_spawn_positions()
	
	# Create a grid of accessible positions around spawn points
	for y in range(map_data.size()):
		for x in range(map_data[y].size()):
			if map_data[y][x] == 0:  # Empty space
				var world_pos = Vector2(x * tile_size + tile_size/2, y * tile_size + tile_size/2)
				
				# Check if position is reasonably accessible
				for spawn_name in ["escaper", "hunter"]:
					if spawn_positions.has(spawn_name):
						var spawn_pos = spawn_positions[spawn_name]
						var distance = world_pos.distance_to(spawn_pos)
						
						# Only include positions within reasonable distance and not too close to walls
						if distance < 400 and is_reasonably_accessible(world_pos):
							expanded_positions.append(world_pos)
							break
	
	return expanded_positions

func is_reasonably_accessible(pos: Vector2) -> bool:
	# Check if position has some clearance around it
	var tile_x = int(pos.x / tile_size)
	var tile_y = int(pos.y / tile_size)
	
	# Check surrounding tiles for walls
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var check_x = tile_x + dx
			var check_y = tile_y + dy
			
			if check_y >= 0 and check_y < map_data.size() and check_x >= 0 and check_x < map_data[0].size():
				if map_data[check_y][check_x] == 1:  # Wall
					# Count walls around position
					return false  # Skip positions too close to walls
	
	return true

func get_level_data() -> Array:
	return map_data

func _on_level_loaded(level_num: int, map: Array):
	map_data = map
	create_walls()
	create_coins()
	setup_navigation()
	level_setup_complete.emit()

func create_walls():
	# Clear existing walls
	for child in $Walls.get_children():
		child.queue_free()
	
	var wall_count = 0
	for y in range(map_data.size()):
		for x in range(map_data[y].size()):
			if map_data[y][x] == 1:  # Wall
				# Create StaticBody2D for collision
				var wall_body = StaticBody2D.new()
				wall_body.name = "WallBody_" + str(x) + "_" + str(y)
				$Walls.add_child(wall_body)
				
				# Add collision shape
				var collision_shape = CollisionShape2D.new()
				var rectangle_shape = RectangleShape2D.new()
				rectangle_shape.size = Vector2(tile_size, tile_size)
				collision_shape.shape = rectangle_shape
				wall_body.add_child(collision_shape)
				
				# Create user-friendly visual rectangle with simple solid color
				var wall_visual = ColorRect.new()
				wall_visual.size = Vector2(tile_size, tile_size)
				wall_visual.position = Vector2(-tile_size/2, -tile_size/2)  # Center on collision
				wall_visual.name = "WallVisual"
				
				# User-friendly colors based on level
				if current_level == 1:
					# Level 1: Soft blue-gray for friendly appearance
					wall_visual.color = Color("#94a3b8")  # Light blue-gray
				elif current_level == 2:
					# Level 2: Medium blue for moderate difficulty
					wall_visual.color = Color("#64748b")  # Medium blue-gray
				else:
					# Level 3+: Darker colors for harder levels
					wall_visual.color = Color("#475569")  # Dark blue-gray
				
				# Add subtle border for better visibility
				var border_style = StyleBoxFlat.new()
				border_style.bg_color = wall_visual.color
				border_style.border_width_left = 1
				border_style.border_width_right = 1
				border_style.border_width_top = 1
				border_style.border_width_bottom = 1
				border_style.border_color = Color("#1e293b")  # Dark border
				border_style.corner_radius_top_left = 3
				border_style.corner_radius_top_right = 3
				border_style.corner_radius_bottom_left = 3
				border_style.corner_radius_bottom_right = 3
				wall_visual.add_theme_stylebox_override("panel", border_style)
				
				wall_body.add_child(wall_visual)
				
				# Position the entire wall body
				wall_body.position = Vector2(x * tile_size + tile_size/2, y * tile_size + tile_size/2)
				
				# Make walls appear immediately - no animation for level 1
				wall_visual.modulate = Color.WHITE
				wall_count += 1

func create_wall_tileset() -> TileSet:
	var tileset = TileSet.new()
	
	# Create source for wall tiles
	var source = TileSetAtlasSource.new()
	source.texture_region_size = Vector2i(40, 40)
	
	# Create wall tile with gradient
	var wall_image = Image.create(40, 40, false, Image.FORMAT_RGBA8)
	
	# Create gradient from top to bottom
	for y in range(40):
		var ratio = float(y) / 40.0
		var color = Color("#475569").lerp(Color("#1e293b"), ratio)
		for x in range(40):
			wall_image.set_pixel(x, y, color)
	
	# Add border
	for x in range(40):
		wall_image.set_pixel(x, 0, Color("#64748b"))
		wall_image.set_pixel(x, 39, Color("#64748b"))
	for y in range(40):
		wall_image.set_pixel(0, y, Color("#64748b"))
		wall_image.set_pixel(39, y, Color("#64748b"))
	
	var wall_texture = ImageTexture.create_from_image(wall_image)
	source.texture = wall_texture
	
	tileset.add_source(source, 0)
	
	return tileset

func create_coins():
	# Clear existing coins
	for coin in coins:
		coin.queue_free()
	coins.clear()
	total_coins_created = 0  # Reset counter
	
	var settings = level_manager.get_level_difficulty_settings(current_level)
	var num_coins = settings.num_coins
	
	print("Creating ", num_coins, " coins for level ", current_level)
	
	# Get intelligent coin positions based on level
	var coin_positions = get_intelligent_coin_positions(num_coins)
	
	for i in range(coin_positions.size()):
		var coin_pos = coin_positions[i]
		
		# Try to load scene, fall back to creating programmatically
		var coin
		var coin_scene = load("res://scenes/Coin.tscn")
		if coin_scene:
			coin = coin_scene.instantiate()
		else:
			coin = create_coin_programmatically()
		
		coin.position = coin_pos
		coin.visible = true  # Ensure coin is visible
		coin.z_index = 5  # Ensure coins render above walls
		
		# Force coin to be visible and properly positioned
		coin.set_process(true)  # Ensure coin processing
		coin.show()  # Force visibility
		
		# Set bonus coin based on intelligent placement
		if i == 0:
			if coin.has_method("set_bonus"):
				coin.set_bonus(true)
		
		if coin.has_signal("collected"):
			coin.collected.connect(_on_coin_collected)
		$CoinContainer.add_child(coin)
		coins.append(coin)
		total_coins_created += 1  # Increment counter
	
	print("Created ", coins.size(), " coins successfully (total created: ", total_coins_created, ")")

func get_intelligent_coin_positions(num_coins: int) -> Array:
	var positions = []
	var spawn_positions = get_spawn_positions()
	
	# Get all valid empty positions
	var valid_positions = []
	for y in range(map_data.size()):
		for x in range(map_data[y].size()):
			if map_data[y][x] == 0:  # Empty space
				var world_pos = Vector2(x * tile_size + tile_size/2, y * tile_size + tile_size/2)
				valid_positions.append(world_pos)
	
	# Filter positions based on level strategy
	var filtered_positions = filter_positions_by_level_strategy(valid_positions, spawn_positions)
	
	# Ensure we have enough positions
	while filtered_positions.size() < num_coins and valid_positions.size() > filtered_positions.size():
		# Add more positions if needed
		for pos in valid_positions:
			if not pos in filtered_positions:
				filtered_positions.append(pos)
				if filtered_positions.size() >= num_coins:
					break
	
	# Select positions intelligently
	positions = select_optimal_coin_positions(filtered_positions, num_coins, spawn_positions)
	
	return positions

func filter_positions_by_level_strategy(valid_positions: Array, spawn_positions: Dictionary) -> Array:
	var filtered = []
	
	for pos in valid_positions:
		var should_include = false
		
		match current_level:
			1:
				# Level 1: Balanced distribution
				should_include = is_position_balanced(pos, spawn_positions)
			2:
				# Level 2: Slightly more challenging positions
				should_include = is_position_challenging(pos, spawn_positions)
			3:
				# Level 3: Mixed difficulty
				should_include = is_position_mixed_difficulty(pos, spawn_positions)
			4:
				# Level 4: Strategic positions requiring planning
				should_include = is_position_strategic(pos, spawn_positions)
			5:
				# Level 5: High difficulty positions
				should_include = is_position_difficult(pos, spawn_positions)
			_:
				# Levels 6+: Adaptive difficulty
				should_include = is_position_adaptive(pos, spawn_positions)
		
		if should_include:
			filtered.append(pos)
	
	return filtered

func is_position_balanced(pos: Vector2, spawn_positions: Dictionary) -> bool:
	# Level 1: Include positions that are reasonably accessible
	var min_distance_from_spawns = tile_size * 3
	var max_distance_from_spawns = tile_size * 8
	
	for spawn_name in spawn_positions:
		var spawn_pos = spawn_positions[spawn_name]
		var distance = pos.distance_to(spawn_pos)
		if distance < min_distance_from_spawns or distance > max_distance_from_spawns:
			return false
	
	return has_clear_path_from_any_spawn(pos, spawn_positions)

func is_position_challenging(pos: Vector2, spawn_positions: Dictionary) -> bool:
	# Level 2: Include positions that require some navigation
	var min_distance_from_spawns = tile_size * 4
	var max_distance_from_spawns = tile_size * 10
	
	var valid_distance = false
	for spawn_name in spawn_positions:
		var spawn_pos = spawn_positions[spawn_name]
		var distance = pos.distance_to(spawn_pos)
		if distance >= min_distance_from_spawns and distance <= max_distance_from_spawns:
			valid_distance = true
			break
	
	return valid_distance and has_clear_path_from_any_spawn(pos, spawn_positions)

func is_position_mixed_difficulty(pos: Vector2, spawn_positions: Dictionary) -> bool:
	# Level 3: Mix of easy and hard positions
	var escaper_pos = spawn_positions.get("escaper", Vector2.ZERO)
	var hunter_pos = spawn_positions.get("hunter", Vector2.ZERO)
	
	var distance_from_escaper = pos.distance_to(escaper_pos)
	var distance_from_hunter = pos.distance_to(hunter_pos)
	
	# Create variety: some closer to escaper, some closer to hunter
	var is_varied = abs(distance_from_escaper - distance_from_hunter) > tile_size * 2
	
	return is_varied and has_clear_path_from_any_spawn(pos, spawn_positions)

func is_position_strategic(pos: Vector2, spawn_positions: Dictionary) -> bool:
	# Level 4: Positions that require strategic planning
	var escaper_pos = spawn_positions.get("escaper", Vector2.ZERO)
	var hunter_pos = spawn_positions.get("hunter", Vector2.ZERO)
	
	var distance_from_escaper = pos.distance_to(escaper_pos)
	var distance_from_hunter = pos.distance_to(hunter_pos)
	
	# Prefer positions that are closer to escaper but require navigation
	var is_strategic = distance_from_escaper < distance_from_hunter and distance_from_escaper > tile_size * 5
	
	return is_strategic and has_clear_path_from_any_spawn(pos, spawn_positions)

func is_position_difficult(pos: Vector2, spawn_positions: Dictionary) -> bool:
	# Level 5: Challenging positions
	var escaper_pos = spawn_positions.get("escaper", Vector2.ZERO)
	var hunter_pos = spawn_positions.get("hunter", Vector2.ZERO)
	
	var distance_from_escaper = pos.distance_to(escaper_pos)
	var distance_from_hunter = pos.distance_to(hunter_pos)
	
	# Positions far from both spawns but accessible
	var is_difficult = distance_from_escaper > tile_size * 6 and distance_from_hunter > tile_size * 6
	
	return is_difficult and has_clear_path_from_any_spawn(pos, spawn_positions)

func is_position_adaptive(pos: Vector2, spawn_positions: Dictionary) -> bool:
	# Levels 6+: Adapt based on level number
	var difficulty_factor = min((current_level - 5) * 0.2, 1.0)
	
	var escaper_pos = spawn_positions.get("escaper", Vector2.ZERO)
	var hunter_pos = spawn_positions.get("hunter", Vector2.ZERO)
	
	var distance_from_escaper = pos.distance_to(escaper_pos)
	var distance_from_hunter = pos.distance_to(hunter_pos)
	
	# Increase difficulty with level number
	var min_distance = tile_size * (4 + difficulty_factor * 4)
	var is_challenging = distance_from_escaper > min_distance and distance_from_hunter > min_distance
	
	return is_challenging and has_clear_path_from_any_spawn(pos, spawn_positions)

func has_clear_path_from_any_spawn(pos: Vector2, spawn_positions: Dictionary) -> bool:
	for spawn_name in spawn_positions:
		var spawn_pos = spawn_positions[spawn_name]
		if has_clear_path(spawn_pos, pos):
			return true
	return false

func select_optimal_coin_positions(filtered_positions: Array, num_coins: int, spawn_positions: Dictionary) -> Array:
	var selected = []
	var positions_copy = filtered_positions.duplicate()
	
	# Sort positions by strategic value
	positions_copy.sort_custom(func(a, b): return calculate_position_value(a, spawn_positions) > calculate_position_value(b, spawn_positions))
	
	# Select positions with good distribution
	for i in range(min(num_coins, positions_copy.size())):
		var pos = positions_copy[i]
		
		# Ensure minimum distance between selected coins
		var too_close = false
		for selected_pos in selected:
			if pos.distance_to(selected_pos) < tile_size * 2:
				too_close = true
				break
		
		if not too_close:
			selected.append(pos)
		else:
			# Find alternative position
			for alt_pos in positions_copy:
				if not alt_pos in selected:
					var valid = true
					for selected_pos in selected:
						if alt_pos.distance_to(selected_pos) < tile_size * 2:
							valid = false
							break
					if valid:
						selected.append(alt_pos)
						break
	
	# If we still need more positions, add them with less strict criteria
	while selected.size() < num_coins and positions_copy.size() > selected.size():
		for pos in positions_copy:
			if not pos in selected:
				selected.append(pos)
				if selected.size() >= num_coins:
					break
	
	return selected

func calculate_position_value(pos: Vector2, spawn_positions: Dictionary) -> float:
	var value = 0.0
	var escaper_pos = spawn_positions.get("escaper", Vector2.ZERO)
	var hunter_pos = spawn_positions.get("hunter", Vector2.ZERO)
	
	# Distance from escaper (closer is slightly better for accessibility)
	var distance_from_escaper = pos.distance_to(escaper_pos)
	value += 100.0 / (distance_from_escaper + 1.0)
	
	# Distance from hunter (farther is better for challenge)
	var distance_from_hunter = pos.distance_to(hunter_pos)
	value += distance_from_hunter * 0.5
	
	# Center preference (balanced positions)
	var center = Vector2(map_data[0].size() * tile_size / 2, map_data.size() * tile_size / 2)
	var distance_from_center = pos.distance_to(center)
	value += 50.0 / (distance_from_center + 1.0)
	
	return value

func create_coin_programmatically():
	# Create a simple coin programmatically
	var coin = Area2D.new()
	coin.collision_layer = 2  # Coin layer
	coin.collision_mask = 1   # Player layer
	
	# Add collision shape
	var collision_shape = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 12.0
	collision_shape.shape = circle_shape
	coin.add_child(collision_shape)
	
	# Add sprite
	var sprite = Sprite2D.new()
	var gradient_texture = GradientTexture2D.new()
	var gradient = Gradient.new()
	gradient.add_point(0, Color("#fbbf24"))
	gradient.add_point(1, Color("#d97706"))
	gradient_texture.gradient = gradient
	gradient_texture.width = 24
	gradient_texture.height = 24
	sprite.texture = gradient_texture
	coin.add_child(sprite)
	
	# Add gentle glow for level 1
	if current_level == 1:
		var glow = PointLight2D.new()
		glow.energy = 0.3
		glow.color = Color("#fbbf24")
		glow.texture_scale = 0.4
		coin.add_child(glow)
	
	# Store properties
	coin.set_meta("is_collected", false)
	coin.set_meta("value", 10)
	
	return coin

func create_decoy_programmatically():
	# Create a simple Area2D decoy without relying on scene files
	var decoy = Area2D.new()
	decoy.collision_layer = 16
	decoy.collision_mask = 0
	
	# Add collision shape
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 10.0
	collision.shape = shape
	decoy.add_child(collision)
	
	# Add sprite
	var sprite = Sprite2D.new()
	# Create simple gradient texture for decoy
	var gradient = Gradient.new()
	gradient.set_color(0, Color("#ef4444"))
	gradient.set_color(1, Color("#dc2626"))
	var gradient_texture = GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.width = 20
	gradient_texture.height = 20
	sprite.texture = gradient_texture
	sprite.scale = Vector2(1.5, 1.5)
	decoy.add_child(sprite)
	
	# Add pulsing light
	var glow = PointLight2D.new()
	glow.energy = 0.5
	glow.color = Color("#ef4444")
	glow.texture_scale = 0.8
	decoy.add_child(glow)
	
	# Add timer for auto-expiry
	var timer = Timer.new()
	timer.wait_time = 5.0  # Decoy lasts 5 seconds
	timer.one_shot = true
	timer.timeout.connect(_on_decoy_timer_timeout.bind(decoy))
	decoy.add_child(timer)
	
	# Add script if available
	if ResourceLoader.exists("res://scripts/Decoy.gd"):
		decoy.set_script(preload("res://scripts/Decoy.gd"))
	
	timer.start()
	return decoy

func _on_decoy_timer_timeout(decoy):
	if decoy in decoys:
		decoys.erase(decoy)
		decoy.queue_free()
		# Emit signal if decoy has one
		if decoy.has_signal("expired"):
			decoy.expired.emit(decoy)

func _rotate_bonus_coin():
	var available_coins = []
	for coin in coins:
		if coin.has_method("get_collected"):
			if not coin.get_collected():
				available_coins.append(coin)
		elif not coin.is_collected:
			available_coins.append(coin)
	
	if available_coins.size() > 0:
		# Remove bonus status from all coins
		for coin in coins:
			if coin.has_method("set_bonus"):
				coin.set_bonus(false)
		
		# Set random coin as bonus
		var random_coin = available_coins[randi() % available_coins.size()]
		if random_coin.has_method("set_bonus"):
			random_coin.set_bonus(true)

func _on_coin_collected(value: int, is_bonus: bool):
	# Remove coin from array and free it
	var coin_to_remove = null
	for coin in coins:
		if not coin.is_inside_tree():  # Coin was removed from scene
			coin_to_remove = coin
			break
		elif coin.has_method("get_collected"):
			if coin.get_collected():
				coin_to_remove = coin
				break
		elif coin.get("is_collected", false):
			coin_to_remove = coin
			break
	
	if coin_to_remove:
		coins.erase(coin_to_remove)
		coin_to_remove.queue_free()
	
	coin_collected.emit(value, is_bonus)
	
	# Check if all coins collected
	if coins.size() == 0:
		all_coins_collected.emit()

func spawn_decoy(position: Vector2):
	var decoy_scene = load("res://scenes/Decoy.tscn")
	var decoy
	if decoy_scene:
		decoy = decoy_scene.instantiate()
	else:
		decoy = create_decoy_programmatically()
	
	decoy.position = position
	if decoy.has_signal("expired"):
		decoy.expired.connect(_on_decoy_expired)
	$DecoyContainer.add_child(decoy)
	decoys.append(decoy)

func _on_decoy_expired(decoy):
	decoys.erase(decoy)
	
	# Notify hunter to remove reference
	var hunter = get_tree().get_first_node_in_group("hunter")
	if hunter and hunter.has_method("remove_decoy_reference"):
		hunter.remove_decoy_reference(decoy)

func get_current_map_data() -> Array:
	return map_data

func get_coins() -> Array:
	return coins

func get_total_coins_created() -> int:
	return total_coins_created

func get_decoys() -> Array:
	return decoys

func setup_navigation():
	# Create navigation mesh for AI pathfinding
	var navigation_mesh = NavigationPolygon.new()
	var outline = PackedVector2Array()
	
	# Create outline around walkable areas
	for y in range(map_data.size()):
		for x in range(map_data[y].size()):
			if map_data[y][x] == 0:  # Walkable tile
				var tile_rect = Rect2(x * tile_size, y * tile_size, tile_size, tile_size)
				add_tile_to_navigation(outline, tile_rect)
	
	if outline.size() > 0:
		navigation_mesh.add_outline(outline)
		navigation_mesh.make_polygons_from_outlines()
		$NavigationRegion2D.navigation_polygon = navigation_mesh

func add_tile_to_navigation(outline: PackedVector2Array, rect: Rect2):
	# Add rectangle corners to navigation outline
	outline.append(rect.position)
	outline.append(Vector2(rect.position.x + rect.size.x, rect.position.y))
	outline.append(rect.position + rect.size)
	outline.append(Vector2(rect.position.x, rect.position.y + rect.size.y))

func cleanup():
	# Clean up all level objects
	for coin in coins:
		coin.queue_free()
	coins.clear()
	
	for decoy in decoys:
		decoy.queue_free()
	decoys.clear()

func get_spawn_positions() -> Dictionary:
	var spawn_positions = {}
	
	if current_level == 1:
		# Level 1: Use the original spawn system
		var escaper_pos = level_manager.get_random_spawn_position(map_data)
		var hunter_pos = level_manager.get_random_spawn_position(map_data, [escaper_pos])
		
		spawn_positions = {
			"escaper": escaper_pos,
			"hunter": hunter_pos
		}
	else:
		# Levels 2+: Use intelligent spawn positioning
		spawn_positions = get_intelligent_spawn_positions()
	
	return spawn_positions

func get_intelligent_spawn_positions() -> Dictionary:
	var spawn_positions = {}
	var valid_positions = []
	
	# Get all valid positions with enhanced clearance
	for y in range(2, map_data.size() - 2):  # Stay away from borders
		for x in range(2, map_data[0].size() - 2):
			if map_data[y][x] == 0:  # Empty space
				var world_pos = Vector2(x * tile_size + tile_size/2, y * tile_size + tile_size/2)
				if has_enough_clearance(world_pos, 4):  # Increased clearance for safety
					if is_position_safe_for_spawn(world_pos):
						valid_positions.append(world_pos)
	
	# Ensure we have valid positions, fallback to safe defaults if needed
	if valid_positions.size() < 2:
		print("Warning: Not enough safe spawn positions, using fallback")
		return get_safe_fallback_spawns()
	
	# Select spawn positions based on level strategy
	var spawn_result = select_spawn_positions_by_level(valid_positions)
	var escaper_pos = spawn_result[0]
	var hunter_pos = spawn_result[1]
	
	# Final validation of selected positions
	if not is_position_safe_for_spawn(escaper_pos):
		escaper_pos = find_closest_safe_position(escaper_pos, valid_positions)
	if not is_position_safe_for_spawn(hunter_pos):
		hunter_pos = find_closest_safe_position(hunter_pos, valid_positions)
	
	spawn_positions = {
		"escaper": escaper_pos,
		"hunter": hunter_pos
	}
	
	print("Spawn positions - Escaper: ", escaper_pos, " Hunter: ", hunter_pos)
	return spawn_positions

func has_enough_clearance(world_pos: Vector2, clearance_tiles: int) -> bool:
	var tile_x = int(world_pos.x / tile_size)
	var tile_y = int(world_pos.y / tile_size)
	
	for dy in range(-clearance_tiles, clearance_tiles + 1):
		for dx in range(-clearance_tiles, clearance_tiles + 1):
			var check_x = tile_x + dx
			var check_y = tile_y + dy
			
			if check_y < 0 or check_y >= map_data.size() or check_x < 0 or check_x >= map_data[0].size():
				return false
			if map_data[check_y][check_x] == 1:  # Wall found
				return false
	
	return true

func is_position_safe_for_spawn(world_pos: Vector2) -> bool:
	var tile_x = int(world_pos.x / tile_size)
	var tile_y = int(world_pos.y / tile_size)
	
	# Check bounds
	if tile_y < 1 or tile_y >= map_data.size() - 1 or tile_x < 1 or tile_x >= map_data[0].size() - 1:
		return false
	
	# Check if position is not a wall
	if map_data[tile_y][tile_x] == 1:
		return false
	
	# Check surrounding tiles for walls (2 tile radius)
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			var check_x = tile_x + dx
			var check_y = tile_y + dy
			
			if check_y >= 0 and check_y < map_data.size() and check_x >= 0 and check_x < map_data[0].size():
				if map_data[check_y][check_x] == 1:
					# Allow diagonal walls but not immediate adjacent walls
					if abs(dx) <= 1 and abs(dy) <= 1:
						return false
	
	return true

func get_safe_fallback_spawns() -> Dictionary:
	# Safe fallback positions that should always work
	var escaper_pos = Vector2(tile_size * 3, tile_size * 3)
	var hunter_pos = Vector2((map_data[0].size() - 3) * tile_size, (map_data.size() - 3) * tile_size)
	
	# Ensure these positions are actually safe
	if not is_position_safe_for_spawn(escaper_pos):
		escaper_pos = Vector2(tile_size * 4, tile_size * 4)
	if not is_position_safe_for_spawn(hunter_pos):
		hunter_pos = Vector2((map_data[0].size() - 4) * tile_size, (map_data.size() - 4) * tile_size)
	
	return {
		"escaper": escaper_pos,
		"hunter": hunter_pos
	}

func find_closest_safe_position(world_pos: Vector2, valid_positions: Array) -> Vector2:
	var closest_pos = world_pos
	var min_distance = INF
	
	for pos in valid_positions:
		if is_position_safe_for_spawn(pos):
			var distance = pos.distance_to(world_pos)
			if distance < min_distance:
				min_distance = distance
				closest_pos = pos
	
	return closest_pos

func has_clearance(world_pos: Vector2, clearance_tiles: int) -> bool:
	var tile_x = int(world_pos.x / tile_size)
	var tile_y = int(world_pos.y / tile_size)
	
	for dy in range(-clearance_tiles, clearance_tiles + 1):
		for dx in range(-clearance_tiles, clearance_tiles + 1):
			var check_x = tile_x + dx
			var check_y = tile_y + dy
			
			if check_y < 0 or check_y >= map_data.size() or check_x < 0 or check_x >= map_data[0].size():
				return false
			if map_data[check_y][check_x] == 1:  # Wall found
				return false
	
	return true

func select_spawn_positions_by_level(valid_positions: Array) -> Array:
	var escaper_pos: Vector2
	var hunter_pos: Vector2
	
	if valid_positions.size() < 2:
		# Fallback to default positions
		escaper_pos = Vector2(tile_size * 2, tile_size * 2)
		hunter_pos = Vector2(map_data[0].size() * tile_size - tile_size * 2, map_data.size() * tile_size - tile_size * 2)
		return [escaper_pos, hunter_pos]
	
	match current_level:
		2:
			# Level 2: Moderate distance spawns
			var result2 = get_moderate_distance_spawns(valid_positions)
			escaper_pos = result2[0]
			hunter_pos = result2[1]
		3:
			# Level 3: Asymmetric spawns
			var result3 = get_asymmetric_spawns(valid_positions)
			escaper_pos = result3[0]
			hunter_pos = result3[1]
		4:
			# Level 4: Strategic spawns
			var result4 = get_strategic_spawns(valid_positions)
			escaper_pos = result4[0]
			hunter_pos = result4[1]
		5:
			# Level 5: Challenging spawns
			var result5 = get_challenging_spawns(valid_positions)
			escaper_pos = result5[0]
			hunter_pos = result5[1]
		_:
			# Levels 6+: Adaptive spawns
			var result6 = get_adaptive_spawns(valid_positions)
			escaper_pos = result6[0]
			hunter_pos = result6[1]
	
	return [escaper_pos, hunter_pos]

func get_moderate_distance_spawns(valid_positions: Array) -> Array:
	var center = Vector2(map_data[0].size() * tile_size / 2, map_data.size() * tile_size / 2)
	var target_distance = min(map_data[0].size(), map_data.size()) * tile_size * 0.3  # 30% of map size
	
	var best_pair = []
	var best_score = -1
	
	for i in range(valid_positions.size()):
		for j in range(i + 1, valid_positions.size()):
			var pos1 = valid_positions[i]
			var pos2 = valid_positions[j]
			var distance = pos1.distance_to(pos2)
			
			# Score based on how close to target distance
			var distance_score = 1.0 - abs(distance - target_distance) / target_distance
			
			# Prefer positions not too close to center
			var center_dist1 = pos1.distance_to(center)
			var center_dist2 = pos2.distance_to(center)
			var center_score = (center_dist1 + center_dist2) / (center.distance * 2)
			
			var total_score = distance_score * 0.7 + center_score * 0.3
			
			if total_score > best_score:
				best_score = total_score
				best_pair = [pos1, pos2]
	
	return best_pair

func get_asymmetric_spawns(valid_positions: Array) -> Array:
	var center = Vector2(map_data[0].size() * tile_size / 2, map_data.size() * tile_size / 2)
	
	# Find position closer to center for escaper
	var escaper_candidates = valid_positions.duplicate()
	escaper_candidates.sort_custom(func(a, b): return a.distance_to(center) < b.distance_to(center))
	var escaper_pos = escaper_candidates[0]
	
	# Find position farther from center for hunter
	var hunter_candidates = valid_positions.duplicate()
	hunter_candidates.sort_custom(func(a, b): return a.distance_to(center) > b.distance_to(center))
	
	# Ensure minimum distance between spawns
	for hunter_pos in hunter_candidates:
		if hunter_pos.distance_to(escaper_pos) > tile_size * 5:
			return [escaper_pos, hunter_pos]
	
	# Fallback to farthest available
	return [escaper_pos, hunter_candidates[0]]

func get_strategic_spawns(valid_positions: Array) -> Array:
	# Level 4: Place spawns in positions that create interesting chase dynamics
	var corners = get_map_corners(valid_positions)
	var edges = get_map_edges(valid_positions)
	
	# Try to place escaper near a corner (defensible position)
	for corner_pos in corners:
		var best_hunter_pos = null
		var max_distance = 0
		
		for hunter_pos in valid_positions:
			if hunter_pos.distance_to(corner_pos) > tile_size * 4:  # Minimum distance
				if hunter_pos.distance_to(corner_pos) > max_distance:
					max_distance = hunter_pos.distance_to(corner_pos)
					best_hunter_pos = hunter_pos
		
		if best_hunter_pos:
			return [corner_pos, best_hunter_pos]
	
	# Fallback to edge positions
	if edges.size() >= 2:
		return [edges[0], edges[edges.size() - 1]]
	
	# Final fallback
	return [valid_positions[0], valid_positions[valid_positions.size() - 1]]

func get_challenging_spawns(valid_positions: Array) -> Array:
	# Level 5: Maximum distance spawns with limited escape routes
	var max_distance_pair = []
	var max_distance = 0
	
	for i in range(valid_positions.size()):
		for j in range(i + 1, valid_positions.size()):
			var pos1 = valid_positions[i]
			var pos2 = valid_positions[j]
			var distance = pos1.distance_to(pos2)
			
			if distance > max_distance:
				max_distance = distance
				max_distance_pair = [pos1, pos2]
	
	# Ensure escaper is in the more challenging position (fewer escape routes)
	var escaper_pos = max_distance_pair[0]
	var hunter_pos = max_distance_pair[1]
	
	# Count escape routes (adjacent empty spaces)
	var escaper_routes = count_adjacent_empty_spaces(escaper_pos)
	var hunter_routes = count_adjacent_empty_spaces(hunter_pos)
	
	if hunter_routes < escaper_routes:
		# Swap to give escaper the more challenging position
		var temp = escaper_pos
		escaper_pos = hunter_pos
		hunter_pos = temp
	
	return [escaper_pos, hunter_pos]

func get_adaptive_spawns(valid_positions: Array) -> Array:
	# Levels 6+: Adapt spawn strategy based on level number
	var difficulty_factor = min((current_level - 5) * 0.2, 1.0)
	
	if difficulty_factor < 0.5:
		return get_strategic_spawns(valid_positions)
	else:
		return get_challenging_spawns(valid_positions)

func get_map_corners(valid_positions: Array) -> Array:
	var corners = []
	var map_width = map_data[0].size() * tile_size
	var map_height = map_data.size() * tile_size
	var corner_threshold = min(map_width, map_height) * 0.15  # Within 15% of corners
	
	var corner_points = [
		Vector2(corner_threshold, corner_threshold),
		Vector2(map_width - corner_threshold, corner_threshold),
		Vector2(corner_threshold, map_height - corner_threshold),
		Vector2(map_width - corner_threshold, map_height - corner_threshold)
	]
	
	for corner_point in corner_points:
		var closest = null
		var min_dist = INF
		
		for pos in valid_positions:
			var dist = pos.distance_to(corner_point)
			if dist < min_dist and dist < corner_threshold * 2:
				min_dist = dist
				closest = pos
		
		if closest:
			corners.append(closest)
	
	return corners

func get_map_edges(valid_positions: Array) -> Array:
	var edges = []
	var map_width = map_data[0].size() * tile_size
	var map_height = map_data.size() * tile_size
	var edge_threshold = min(map_width, map_height) * 0.1  # Within 10% of edges
	
	for pos in valid_positions:
		var is_edge = false
		
		# Check if near any edge
		if pos.x < edge_threshold or pos.x > map_width - edge_threshold:
			is_edge = true
		if pos.y < edge_threshold or pos.y > map_height - edge_threshold:
			is_edge = true
		
		if is_edge:
			edges.append(pos)
	
	return edges

func count_adjacent_empty_spaces(world_pos: Vector2) -> int:
	var tile_x = int(world_pos.x / tile_size)
	var tile_y = int(world_pos.y / tile_size)
	var count = 0
	
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
				
			var check_x = tile_x + dx
			var check_y = tile_y + dy
			
			if check_y >= 0 and check_y < map_data.size() and check_x >= 0 and check_x < map_data[0].size():
				if map_data[check_y][check_x] == 0:
					count += 1
	
	return count
