extends Node
class_name LevelManager

signal level_loaded(level_number: int, map_data: Array)
signal all_levels_completed()

@export var tile_size: int = 40
@export var map_width: int = 20
@export var map_height: int = 15

var current_level: int = 1
var total_levels: int = 5
var current_map_data: Array = []

# Map layouts (1 = wall, 0 = empty)
var LEVEL_MAPS: Array[Array] = [
	# Level 1 - Original balanced map
	[
		[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
		[1,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,1],
		[1,0,1,1,0,0,0,0,1,0,0,1,0,0,0,0,1,1,0,1],
		[1,0,1,0,0,1,0,0,0,0,0,0,0,0,1,0,0,1,0,1],
		[1,0,0,0,1,0,0,1,0,1,1,0,1,0,0,1,0,0,0,1],
		[1,0,1,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,1,1],
		[1,0,1,1,0,1,0,0,1,0,0,1,0,0,1,0,1,1,0,1],
		[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
		[1,0,1,1,0,1,0,0,1,0,0,1,0,0,1,0,1,1,0,1],
		[1,0,1,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,1,1],
		[1,0,0,0,1,0,0,1,0,1,1,0,1,0,0,1,0,0,0,1],
		[1,0,1,0,0,1,0,0,0,0,0,0,0,0,1,0,0,1,0,1],
		[1,0,1,1,0,0,0,0,1,0,0,1,0,0,0,0,1,1,0,1],
		[1,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,1],
		[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
	],
	# Level 2 - Spiral maze with center arena
	[
		[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
		[1,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,0,1],
		[1,0,1,1,1,1,1,0,1,0,1,1,1,1,1,0,1,1,0,1],
		[1,0,1,0,0,0,1,0,1,0,0,0,1,0,0,1,0,1,0,1],
		[1,0,1,0,1,0,1,0,1,0,0,0,0,1,0,1,0,1,0,1],
		[1,0,1,0,1,0,1,0,1,0,0,0,0,0,1,0,1,0,1,1],
		[1,0,1,0,1,0,1,0,1,0,0,0,0,0,1,0,1,0,1,1],
		[1,0,1,0,1,0,1,0,0,0,0,0,0,0,0,0,0,0,1,1],
		[1,0,1,0,1,0,1,0,0,0,0,0,0,0,0,0,0,0,1,1],
		[1,0,1,0,1,0,1,0,0,0,0,0,0,0,0,0,0,0,1,1],
		[1,0,1,0,1,0,1,0,0,0,0,0,0,0,0,0,0,0,1,1],
		[1,0,1,0,1,0,1,0,0,0,0,0,0,0,0,0,0,0,1,1],
		[1,0,1,0,1,0,1,0,0,0,0,0,0,0,0,0,0,0,1,1],
		[1,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,0,1],
		[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
	],
	# Level 3 - Cross pattern with quadrants
	[
		[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
		[1,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1],
		[1,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1],
		[1,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1],
		[1,1,1,1,1,1,0,0,0,1,0,0,0,1,0,0,0,0,1,1],
		[1,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,1,1],
		[1,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,1,1],
		[1,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,1,1],
		[1,1,1,1,1,1,0,0,0,1,0,0,0,1,0,0,0,0,1,1],
		[1,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,1,1],
		[1,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,1,1],
		[1,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,1,1],
		[1,1,1,1,1,1,0,0,0,1,0,0,0,1,0,0,0,0,1,1],
		[1,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,1,1],
		[1,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,1,1],
		[1,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,1,1],
		[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
	],
	# Level 4 - Diamond pattern with diagonal paths
	[
		[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
		[1,0,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0,0,0,1],
		[1,0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0,0,1,1],
		[1,0,0,1,1,1,0,0,0,0,0,0,1,1,0,0,0,1,1,1],
		[1,0,1,1,1,1,1,0,0,0,0,1,1,1,0,0,1,1,1,1],
		[1,0,1,1,1,1,1,0,0,0,0,1,1,1,0,0,1,1,1,1],
		[1,0,1,1,1,1,1,0,0,0,0,1,1,1,0,0,1,1,1,1],
		[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
		[1,0,1,1,1,1,1,0,0,0,0,1,1,1,0,0,1,1,1,1],
		[1,0,1,1,1,1,1,0,0,0,0,1,1,1,0,0,1,1,1,1],
		[1,0,1,1,1,1,1,0,0,0,0,1,1,1,0,0,1,1,1,1],
		[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
		[1,0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0,0,1,1],
		[1,0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0,0,1,1],
		[1,0,0,0,1,0,0,0,0,0,0,0,1,1,0,0,0,0,1,1],
		[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
	],
	# Level 5 - Islands pattern with bridges
	[
		[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
		[1,0,0,0,1,1,1,1,0,0,0,1,1,1,0,0,0,0,0,1],
		[1,0,0,0,1,1,1,1,0,0,0,1,1,1,0,0,0,0,0,1],
		[1,0,0,0,1,1,1,1,0,0,0,1,1,1,0,0,0,0,0,1],
		[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
		[1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1],
		[1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1],
		[1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1],
		[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
		[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
		[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
		[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
		[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
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
	var map_index = (level_number - 1) % LEVEL_MAPS.size()
	current_map_data = LEVEL_MAPS[map_index].duplicate(true)
	
	print("Loading level ", level_number, " with map index ", map_index)
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
	
	# Level-specific adjustments
	var level_multiplier = 1.0 + (level - 1) * 0.2
	
	return {
		"num_coins": min(base_settings.num_coins + (level - 1) * 2, 25),
		"game_duration": max(base_settings.game_duration - (level - 1) * 10, 60),
		"ai_speed": min(base_settings.ai_speed + (level - 1) * 10, 180),
		"max_decoys": max(base_settings.max_decoys - floor((level - 1) * 0.5), 1),
		"ai_reaction_time": max(base_settings.ai_reaction_time - (level - 1) * 0.1, 0.3)
	}

func get_valid_spawn_positions(map_data: Array, exclude_positions: Array = []) -> Array:
	var valid_positions = []
	
	for y in range(map_height):
		for x in range(map_width):
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
	
	if tile_x < 0 or tile_x >= map_width or tile_y < 0 or tile_y >= map_height:
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
