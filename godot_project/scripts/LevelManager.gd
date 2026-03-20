extends Node

signal level_loaded(level_number: int, map_data: Array)
signal all_levels_completed()

@export var tile_size: int = 40
@export var map_width: int = 20
@export var map_height: int = 15

var current_level: int = 1
var total_levels: int = 5
var current_map_data: Array = []

# Map layouts (1 = wall, 0 = empty) - All levels designed for proper accessibility
var LEVEL_MAPS: Array = [
	# Level 1 - Original balanced map
	[
		[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
		[1,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,1],
		[1,0,1,1,0,0,0,0,1,0,0,1,0,0,0,0,1,1,0,1],
		[1,0,1,0,0,1,0,0,0,0,0,0,0,0,0,1,0,0,1,0,1],
		[1,0,0,0,1,0,0,1,0,1,1,0,1,0,0,1,0,0,0,1],
		[1,0,1,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0,0,1,1],
		[1,0,1,1,0,1,0,0,1,0,0,1,0,0,1,0,1,1,0,1],
		[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
		[1,0,1,1,0,1,0,0,1,0,0,1,0,0,1,0,1,1,0,1],
		[1,0,1,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0,0,1,1],
		[1,0,0,0,1,0,0,1,0,1,1,0,1,0,0,1,0,0,0,1],
		[1,0,1,0,0,1,0,0,0,0,0,0,0,0,0,1,0,0,1,0,1],
		[1,0,1,1,0,0,0,0,1,0,0,1,0,0,0,0,1,1,0,1],
		[1,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,1],
		[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
	],
	# Level 2 - Modified maze with better accessibility
	[
		[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
		[1,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,0,1],
		[1,0,1,1,1,1,1,0,1,0,1,0,1,1,1,0,1,1,0,1],
		[1,0,1,0,0,0,1,0,1,0,0,0,1,0,0,1,0,1,0,1],
		[1,0,1,0,1,0,1,0,1,0,0,0,0,1,0,1,0,1,0,1],
		[1,0,1,0,1,0,1,0,1,0,0,0,0,0,1,0,1,0,0,1],
		[1,0,1,0,1,0,1,0,0,0,0,0,0,0,0,0,1,0,0,1],
		[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
		[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
		[1,0,1,0,1,0,1,0,0,0,0,0,0,0,0,0,1,0,0,1],
		[1,0,1,0,1,0,1,0,0,0,0,0,0,0,0,0,1,0,0,1],
		[1,0,1,0,1,0,1,0,0,0,0,0,0,0,0,0,1,0,0,1],
		[1,0,1,0,0,0,1,0,0,0,0,0,0,0,0,1,0,0,0,1],
		[1,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,1],
		[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
	],
	# Level 3 - Modified cross pattern with better paths
	[
		[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
		[1,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1],
		[1,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1],
		[1,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1],
		[1,1,1,1,1,1,0,0,0,1,0,0,0,1,0,0,0,0,1,1],
		[1,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,1,1],
		[1,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,1,1],
		[1,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,1,1],
		[1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,1,1],
		[1,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,1,1],
		[1,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,1,1],
		[1,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,1,1],
		[1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,1,1],
		[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1],
		[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
	],
	# Level 4 - Modified diamond pattern with clear paths
	[
		[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
		[1,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,1],
		[1,0,0,0,1,1,0,0,0,0,0,1,1,0,0,0,0,1,1],
		[1,0,0,1,1,1,0,0,0,0,0,1,1,0,0,0,1,1,1],
		[1,0,1,1,1,1,1,0,0,0,1,1,1,0,0,1,1,1,1],
		[1,0,1,1,1,1,1,0,0,0,1,1,1,0,0,1,1,1,1],
		[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
		[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
		[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
		[1,0,1,1,1,1,1,0,0,0,1,1,1,0,0,1,1,1,1],
		[1,0,1,1,1,1,1,0,0,0,1,1,1,0,0,1,1,1,1],
		[1,0,0,1,1,1,0,0,0,0,0,1,1,0,0,0,1,1,1],
		[1,0,0,0,1,1,0,0,0,0,0,1,1,0,0,0,0,1,1],
		[1,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,0,1],
		[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
	],
	# Level 5 - Modified islands with better connectivity
	[
		[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
		[1,0,0,0,1,1,1,1,0,0,0,1,1,1,0,0,0,0,0,1],
		[1,0,0,0,1,1,1,1,0,0,0,1,1,1,0,0,0,0,0,1],
		[1,0,0,0,1,1,1,1,0,0,0,1,1,1,0,0,0,0,0,1],
		[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
		[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
		[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
		[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
		[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
		[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
		[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
		[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
		[1,0,0,0,1,1,1,1,0,0,0,1,1,1,0,0,0,0,0,1],
		[1,0,0,0,1,1,1,1,0,0,0,1,1,1,0,0,0,0,0,1],
		[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
	]
]

func _ready():
	print("Level Manager initialized with ", total_levels, " levels")

func load_level(level_number: int):
	if level_number < 1 or level_number > total_levels:
		print("Invalid level number: ", level_number)
		return
	
	current_level = level_number
	
	if level_number == 1:
		# Keep Level 1 as is (original balanced map)
		var map_index = (level_number - 1) % LEVEL_MAPS.size()
		current_map_data = LEVEL_MAPS[map_index].duplicate(true)
		print("Loading level ", level_number, " (original map)")
	else:
		# Generate intelligent layout for levels 2+
		current_map_data = generate_intelligent_level_layout(level_number)
		print("Loading level ", level_number, " (intelligent generation)")
	
	level_loaded.emit(level_number, current_map_data)

func get_current_map() -> Array:
	return current_map_data

func get_level_difficulty_settings(level: int) -> Dictionary:
	var base_settings = {
		"num_coins": 15,
		"game_duration": 90,
		"ai_speed": 125,
		"max_decoys": 3,
		"ai_reaction_time": 0.9
	}
	
	# Calculate coins with guaranteed minimum 15 and maximum 25
	var coins_for_level = base_settings.num_coins + (level - 1) * 2
	var final_coins = clamp(coins_for_level, 15, 25)  # Explicit min/max enforcement
	
	# Level-specific adjustments
	var level_multiplier = 1.0 + (level - 1) * 0.2
	
	return {
		"num_coins": final_coins,
		"game_duration": max(base_settings.game_duration - (level - 1) * 10, 60),
		"ai_speed": min(base_settings.ai_speed + (level - 1) * 10, 180),
		"max_decoys": max(base_settings.max_decoys - floor((level - 1) * 0.5), 1),
		"ai_reaction_time": max(base_settings.ai_reaction_time - (level - 1) * 0.1, 0.3)
	}

func get_valid_spawn_positions(map_data: Array, exclude_positions: Array = []) -> Array:
	var valid_positions = []
	
	# Use actual map dimensions instead of fixed values
	var actual_height = map_data.size()
	var actual_width = 0
	if actual_height > 0:
		actual_width = map_data[0].size()
	
	print("Map dimensions: ", actual_width, "x", actual_height)
	
	for y in range(actual_height):
		for x in range(actual_width):
			# Ensure we don't go out of bounds
			if y >= map_data.size() or x >= map_data[y].size():
				continue
				
			if map_data[y][x] == 0:  # Empty tile
				var world_pos = Vector2(x * tile_size + tile_size / 2, y * tile_size + tile_size / 2)
				
				# Check if position is far enough from excluded positions
				var valid = true
				for exclude_pos in exclude_positions:
					if world_pos.distance_to(exclude_pos) < tile_size * 2.5:
						valid = false
						break
				
				if valid:
					valid_positions.append(world_pos)
	
	return valid_positions

func get_random_spawn_position(map_data: Array, exclude_positions: Array = []) -> Vector2:
	var valid_positions = get_valid_spawn_positions(map_data, exclude_positions)
	
	if valid_positions.size() > 0:
		return valid_positions[randi() % valid_positions.size()]
	
	# Fallback to center if no valid positions found
	return Vector2(map_width * tile_size / 2, map_height * tile_size / 2)

func is_wall_at_position(world_pos: Vector2) -> bool:
	var tile_x = int(world_pos.x / tile_size)
	var tile_y = int(world_pos.y / tile_size)
	
	# Use actual map dimensions
	var actual_height = current_map_data.size()
	var actual_width = 0
	if actual_height > 0:
		actual_width = current_map_data[0].size()
	
	# Check bounds using actual dimensions
	if tile_x < 0 or tile_x >= actual_width or tile_y < 0 or tile_y >= actual_height:
		return true
	
	# Additional bounds check to prevent index errors
	if tile_y >= current_map_data.size() or tile_x >= current_map_data[tile_y].size():
		return true
	
	return current_map_data[tile_y][tile_x] == 1

func get_level_name(level: int) -> String:
	var level_names = [
		"Balanced Beginnings",
		"Spiral Maze",
		"Cross Pattern",
		"Diamond Paths", 
		"Island Battle"
	]
	
	var index = (level - 1) % level_names.size()
	return level_names[index]

func advance_to_next_level():
	if current_level < total_levels:
		load_level(current_level + 1)
	else:
		all_levels_completed.emit()

func reset_to_level_one():
	current_level = 1
	load_level(1)

func generate_intelligent_level_layout(level_number: int) -> Array:
	# Create dynamic map dimensions based on level
	var width = map_width
	var height = map_height
	
	# Adjust complexity based on level
	var complexity_factor = min(0.3 + (level_number - 2) * 0.1, 0.7)  # 30% to 70% wall density
	var openness_factor = max(0.6 - (level_number - 2) * 0.05, 0.3)  # Less open space for higher levels
	
	# Initialize map with walls
	var map_data = []
	for y in range(height):
		var row = []
		for x in range(width):
			row.append(1)  # Start with all walls
		map_data.append(row)
	
	# Generate layout based on level pattern
	var pattern_type = (level_number - 2) % 4  # 4 different patterns
	
	match pattern_type:
		0:
			# Spiral pattern
			_generate_spiral_layout(map_data, complexity_factor, openness_factor)
		1:
			# Maze pattern
			_generate_maze_layout(map_data, complexity_factor, openness_factor)
		2:
			# Islands pattern
			_generate_islands_layout(map_data, complexity_factor, openness_factor)
		3:
			# Cross pattern
			_generate_cross_layout(map_data, complexity_factor, openness_factor)
	
	# Ensure borders are walls
	_apply_wall_borders(map_data)
	
	# Create guaranteed paths between spawn areas
	_ensure_connectivity(map_data, level_number)
	
	return map_data

func _generate_spiral_layout(map_data: Array, complexity: float, openness: float):
	var center_x = map_data[0].size() / 2
	var center_y = map_data.size() / 2
	
	# Create spiral paths
	var spiral_paths = []
	var radius = min(center_x, center_y) - 2
	
	for angle in range(0, 360 * 3, 15):  # 3 full rotations
		var rad = deg_to_rad(angle)
		var r = radius * (angle / (360 * 3.0))  # Expanding spiral
		
		var x = int(center_x + r * cos(rad))
		var y = int(center_y + r * sin(rad))
		
		if y > 0 and y < map_data.size() - 1 and x > 0 and x < map_data[0].size() - 1:
			map_data[y][x] = 0  # Create path
			# Add some width to the path
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var nx = x + dx
					var ny = y + dy
					if ny > 0 and ny < map_data.size() - 1 and nx > 0 and nx < map_data[0].size() - 1:
						if randf() < openness:
							map_data[ny][nx] = 0

func _generate_maze_layout(map_data: Array, complexity: float, openness: float):
	# Create maze-like structure with corridors
	var corridor_width = max(1, int(3 - complexity * 2))
	
	# Horizontal corridors
	for y in range(2, map_data.size() - 2, 3):
		for x in range(1, map_data[0].size() - 1):
			map_data[y][x] = 0
			if corridor_width > 1:
				for dy in range(1, corridor_width):
					if y + dy < map_data.size() - 1:
						map_data[y + dy][x] = 0
	
	# Vertical corridors
	for x in range(2, map_data[0].size() - 2, 3):
		for y in range(1, map_data.size() - 1):
			map_data[y][x] = 0
			if corridor_width > 1:
				for dx in range(1, corridor_width):
					if x + dx < map_data[0].size() - 1:
						map_data[y][x + dx] = 0
	
	# Add some random openings
	for y in range(1, map_data.size() - 1):
		for x in range(1, map_data[0].size() - 1):
			if randf() < openness * 0.3:
				map_data[y][x] = 0

func _generate_islands_layout(map_data: Array, complexity: float, openness: float):
	var num_islands = 3 + int(complexity * 4)
	var island_radius = max(2, int(5 - complexity * 3))
	
	for i in range(num_islands):
		var center_x = randi_range(island_radius + 1, map_data[0].size() - island_radius - 2)
		var center_y = randi_range(island_radius + 1, map_data.size() - island_radius - 2)
		
		# Create circular island
		for y in range(-island_radius, island_radius + 1):
			for x in range(-island_radius, island_radius + 1):
				var distance = sqrt(x * x + y * y)
				if distance <= island_radius:
					var nx = center_x + x
					var ny = center_y + y
					if ny > 0 and ny < map_data.size() - 1 and nx > 0 and nx < map_data[0].size() - 1:
						map_data[ny][nx] = 0
	
	# Connect islands with bridges
	for i in range(num_islands - 1):
		_create_bridge_between_points(map_data, 
			Vector2(randi_range(2, map_data[0].size() - 3), randi_range(2, map_data.size() - 3)),
			Vector2(randi_range(2, map_data[0].size() - 3), randi_range(2, map_data.size() - 3))
		)

func _generate_cross_layout(map_data: Array, complexity: float, openness: float):
	var center_x = map_data[0].size() / 2
	var center_y = map_data.size() / 2
	var cross_width = max(2, int(5 - complexity * 2))
	
	# Main horizontal corridor
	for x in range(1, map_data[0].size() - 1):
		for dy in range(-cross_width/2, cross_width/2 + 1):
			var y = center_y + dy
			if y > 0 and y < map_data.size() - 1:
				map_data[y][x] = 0
	
	# Main vertical corridor
	for y in range(1, map_data.size() - 1):
		for dx in range(-cross_width/2, cross_width/2 + 1):
			var x = center_x + dx
			if x > 0 and x < map_data[0].size() - 1:
				map_data[y][x] = 0
	
	# Add diagonal corridors for higher complexity
	if complexity > 0.5:
		for i in range(1, min(map_data.size(), map_data[0].size()) - 1):
			# Main diagonal
			if i < map_data.size() and i < map_data[0].size():
				map_data[i][i] = 0
			# Anti-diagonal
			if i < map_data.size() and map_data[0].size() - 1 - i >= 0:
				map_data[i][map_data[0].size() - 1 - i] = 0
	
	# Add random openings
	for y in range(1, map_data.size() - 1):
		for x in range(1, map_data[0].size() - 1):
			if randf() < openness * 0.2:
				map_data[y][x] = 0

func _create_bridge_between_points(map_data: Array, start: Vector2, end: Vector2):
	var current = start
	while current.distance_to(end) > 1:
		var next_step = current + (end - current).normalized()
		current = next_step.round()
		
		var x = int(current.x)
		var y = int(current.y)
		
		if y > 0 and y < map_data.size() - 1 and x > 0 and x < map_data[0].size() - 1:
			map_data[y][x] = 0
			# Make bridge slightly wider
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var nx = x + dx
					var ny = y + dy
					if ny > 0 and ny < map_data.size() - 1 and nx > 0 and nx < map_data[0].size() - 1:
						if randf() < 0.3:
							map_data[ny][nx] = 0

func _apply_wall_borders(map_data: Array):
	# Ensure top and bottom borders are walls
	for x in range(map_data[0].size()):
		map_data[0][x] = 1
		map_data[map_data.size() - 1][x] = 1
	
	# Ensure left and right borders are walls
	for y in range(map_data.size()):
		map_data[y][0] = 1
		map_data[y][map_data[0].size() - 1] = 1

func _ensure_connectivity(map_data: Array, level_number: int):
	# Find valid spawn positions for escaper and hunter
	var spawn_positions = _find_optimal_spawn_positions(map_data)
	
	# Ensure there's a clear path between spawn positions
	if spawn_positions.size() >= 2:
		var escaper_spawn = spawn_positions[0]
		var hunter_spawn = spawn_positions[1]
		_create_clear_path(map_data, escaper_spawn, hunter_spawn)
	
	# Add some guaranteed open areas around spawn positions
	for spawn_pos in spawn_positions:
		_create_spawn_area(map_data, spawn_pos)

func _find_optimal_spawn_positions(map_data: Array) -> Array:
	var valid_positions = []
	
	for y in range(1, map_data.size() - 1):
		for x in range(1, map_data[0].size() - 1):
			if map_data[y][x] == 0:  # Empty space
				var world_pos = Vector2(x, y)
				# Check if position has some clearance
				if _has_clearance(map_data, world_pos, 2):
					valid_positions.append(world_pos)
	
	# Sort positions by distance from center to get good spread
	var center = Vector2(map_data[0].size() / 2, map_data.size() / 2)
	valid_positions.sort_custom(func(a, b): return a.distance_to(center) > b.distance_to(center))
	
	# Return best positions (far from center for good gameplay)
	return valid_positions.slice(0, min(4, valid_positions.size()))

func _has_clearance(map_data: Array, pos: Vector2, radius: int) -> bool:
	for y in range(max(0, pos.y - radius), min(map_data.size(), pos.y + radius + 1)):
		for x in range(max(0, pos.x - radius), min(map_data[0].size(), pos.x + radius + 1)):
			if map_data[y][x] == 1:  # Wall found
				return false
	return true

func _create_clear_path(map_data: Array, start: Vector2, end: Vector2):
	var current = start
	while current.distance_to(end) > 1:
		var next_step = current + (end - current).normalized()
		current = next_step.round()
		
		var x = int(current.x)
		var y = int(current.y)
		
		if y > 0 and y < map_data.size() - 1 and x > 0 and x < map_data[0].size() - 1:
			map_data[y][x] = 0

func _create_spawn_area(map_data: Array, spawn_pos: Vector2):
	# Create a small clear area around spawn position
	var radius = 2
	for y in range(max(1, spawn_pos.y - radius), min(map_data.size() - 1, spawn_pos.y + radius + 1)):
		for x in range(max(1, spawn_pos.x - radius), min(map_data[0].size() - 1, spawn_pos.x + radius + 1)):
			map_data[y][x] = 0
