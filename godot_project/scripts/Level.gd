extends Node2D
class_name Level

signal level_setup_complete
signal coin_collected(value: int, is_bonus: bool)
signal all_coins_collected

@export var wall_tileset: TileSet
@export var coin_scene: PackedScene
@export var decoy_scene: PackedScene

var level_manager: LevelManager
var current_level: int = 1
var map_data: Array = []
var coins: Array[Coin] = []
var decoys: Array[Decoy] = []
var tile_size: int = 40

func _ready():
	level_manager = LevelManager.new()
	add_child(level_manager)
	level_manager.level_loaded.connect(_on_level_loaded)

func setup_level(level_number: int):
	current_level = level_number
	level_manager.load_level(level_number)

func _on_level_loaded(level_num: int, map: Array):
	map_data = map
	create_walls()
	create_coins()
	setup_navigation()
	level_setup_complete.emit()

func create_walls():
	$Walls.clear()
	
	# Create simple tileset if not provided
	if not wall_tileset:
		wall_tileset = create_wall_tileset()
	
	$Walls.tile_set = wall_tileset
	
	for y in range(map_data.size()):
		for x in range(map_data[y].size()):
			if map_data[y][x] == 1:  # Wall
				$Walls.set_cell(0, Vector2i(x, y), 0, Vector2i(0, 0))

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
	
	var settings = level_manager.get_level_difficulty_settings(current_level)
	var num_coins = settings.num_coins
	
	# Get valid spawn positions
	var exclude_positions = []
	var escaper_pos = level_manager.get_random_spawn_position(map_data)
	var hunter_pos = level_manager.get_random_spawn_position(map_data, [escaper_pos])
	exclude_positions = [escaper_pos, hunter_pos]
	
	var valid_positions = level_manager.get_valid_spawn_positions(map_data, exclude_positions)
	
	# Place coins
	var coins_to_place = min(num_coins, valid_positions.size())
	for i in range(coins_to_place):
		var pos_index = randi() % valid_positions.size()
		var coin_pos = valid_positions[pos_index]
		valid_positions.remove_at(pos_index)
		
		var coin = coin_scene.instantiate() as Coin
		coin.position = coin_pos
		
		# First coin starts as bonus
		if i == 0:
			coin.set_bonus(true)
		
		coin.collected.connect(_on_coin_collected)
		$CoinContainer.add_child(coin)
		coins.append(coin)
	
	# Start bonus coin rotation timer
	start_bonus_coin_rotation()

func start_bonus_coin_rotation():
	var timer = Timer.new()
	timer.wait_time = 8.0  # Change bonus coin every 8 seconds
	timer.timeout.connect(_rotate_bonus_coin)
	add_child(timer)
	timer.start()

func _rotate_bonus_coin():
	var available_coins = coins.filter(func(c): return not c.collected)
	if available_coins.size() > 0:
		# Remove bonus status from all coins
		for coin in coins:
			coin.set_bonus(false)
		
		# Set random coin as bonus
		var random_coin = available_coins[randi() % available_coins.size()]
		random_coin.set_bonus(true)

func _on_coin_collected(value: int, is_bonus: bool):
	coin_collected.emit(value, is_bonus)
	
	# Check if all coins collected
	var remaining_coins = coins.filter(func(c): return not c.collected)
	if remaining_coins.size() == 0:
		all_coins_collected.emit()

func spawn_decoy(position: Vector2):
	var decoy = decoy_scene.instantiate() as Decoy
	decoy.position = position
	decoy.expired.connect(_on_decoy_expired)
	$DecoyContainer.add_child(decoy)
	decoys.append(decoy)
	
	print("Decoy spawned at position: ", position)

func _on_decoy_expired(decoy: Decoy):
	decoys.erase(decoy)
	
	# Notify hunter to remove reference
	var hunter = get_tree().get_first_node_in_group("hunter")
	if hunter and hunter.has_method("remove_decoy_reference"):
		hunter.remove_decoy_reference(decoy)

func get_current_map_data() -> Array:
	return map_data

func get_coins() -> Array[Coin]:
	return coins

func get_decoys() -> Array[Decoy]:
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
