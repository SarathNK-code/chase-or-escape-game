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
	
	print("Creating enhanced walls for level ", current_level, " with map data size: ", map_data.size())
	
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
	
	print("Created ", wall_count, " user-friendly wall bodies with collision")

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
	
	# Get valid positions with enhanced filtering for accessibility
	var valid_positions = []
	for y in range(map_data.size()):
		for x in range(map_data[y].size()):
			if map_data[y][x] == 0:  # Empty space
				var world_pos = Vector2(x * tile_size + tile_size/2, y * tile_size + tile_size/2)
				
				# First add all empty spaces, then filter for accessibility
				valid_positions.append(world_pos)
	
	print("Found ", valid_positions.size(), " total empty spaces")
	
	# If we have accessibility checking, try to filter, but ensure we don't lose all positions
	var accessible_positions = []
	for pos in valid_positions:
		if is_position_accessible(pos):
			accessible_positions.append(pos)
	
	print("Found ", accessible_positions.size(), " accessible positions")
	
	# Use accessible positions if we have enough, otherwise fall back to all empty spaces
	var final_positions = accessible_positions
	if accessible_positions.size() < num_coins / 2:  # If less than half are accessible
		print("Not enough accessible positions, using all empty spaces")
		final_positions = valid_positions
	
	var coins_to_place = min(num_coins, final_positions.size())
	print("Placing ", coins_to_place, " coins in ", final_positions.size(), " available positions")
	
	# Sort positions to ensure good distribution
	final_positions.sort_custom(func(a, b): return a.length() < b.length())
	
	for i in range(coins_to_place):
		# Use systematic placement instead of random for better distribution
		var pos_index = (i * 7) % final_positions.size()  # Distribute coins
		var coin_pos = final_positions[pos_index]
		final_positions.remove_at(pos_index)
		
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
		
		# First coin starts as bonus
		if i == 0:
			if coin.has_method("set_bonus"):
				coin.set_bonus(true)
		
		if coin.has_signal("collected"):
			coin.collected.connect(_on_coin_collected)
		$CoinContainer.add_child(coin)
		coins.append(coin)
		total_coins_created += 1  # Increment counter
	
	print("Created ", coins.size(), " coins successfully (total created: ", total_coins_created, ")")

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
	
	print("Coin collected! Value: ", value, ", Bonus: ", is_bonus, ", Remaining coins: ", coins.size())
	
	# Check if all coins collected
	if coins.size() == 0:
		print("All coins collected!")
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
	
	print("Decoy spawned at position: ", position)

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
	var escaper_pos = level_manager.get_random_spawn_position(map_data)
	var hunter_pos = level_manager.get_random_spawn_position(map_data, [escaper_pos])
	
	return {
		"escaper": escaper_pos,
		"hunter": hunter_pos
	}
