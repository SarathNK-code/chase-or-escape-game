extends Node

@export var max_lives: int = 3
@export var game_time: int = 120  # seconds

var escaper: Node2D
var hunter: Node2D
var level: Node
var hud: CanvasLayer  # Changed from Control to CanvasLayer
var score: int = 0
var lives_remaining: int = 3
var cumulative_score: int = 0
var current_level: int = 1
var time_left: float = 120.0
var decoys_remaining: int = 5
var game_running: bool = false
var original_spawn_positions: Dictionary = {}  # Store original spawn positions

signal game_started
signal game_ended
signal level_completed
signal life_lost
signal score_updated(new_score)
signal time_updated(new_time)

func _ready():
	print("DEBUG: GameManager _ready() called - Scene should be loading now")
	
	# Get references to game nodes
	hud = get_tree().get_first_node_in_group("hud")
	level = get_tree().get_first_node_in_group("level")
	escaper = get_tree().get_first_node_in_group("escaper")
	hunter = get_tree().get_first_node_in_group("hunter")
	
	print("DEBUG: Node references - HUD: ", hud != null, " Level: ", level != null, " Escaper: ", escaper != null, " Hunter: ", hunter != null)
	
	# Check if we're in the main game scene
	var current_scene = get_tree().current_scene
	print("DEBUG: Current scene: ", current_scene.name if current_scene else "NULL")
	print("DEBUG: Scene file path: ", current_scene.scene_file_path if current_scene else "NULL")
	
	if not hud:
		print("WARNING: HUD node not found - checking for alternative...")
		# Try to find HUD by name
		hud = get_node_or_null("HUD")
		if hud:
			print("DEBUG: Found HUD by name: HUD")
		else:
			print("ERROR: HUD not found at all!")
	
	if not level:
		print("WARNING: Level node not found - checking for alternative...")
		# Try to find Level by name
		level = get_node_or_null("Level")
		if level:
			print("DEBUG: Found Level by name: Level")
		else:
			print("ERROR: Level not found at all!")
	
	if not escaper:
		print("WARNING: Escaper node not found - checking for alternative...")
		# Try to find Escaper by name
		escaper = get_node_or_null("Escaper")
		if escaper:
			print("DEBUG: Found Escaper by name: Escaper")
		else:
			print("ERROR: Escaper not found at all!")
	
	if not hunter:
		print("WARNING: Hunter node not found - checking for alternative...")
		# Try to find Hunter by name
		hunter = get_node_or_null("Hunter")
		if hunter:
			print("DEBUG: Found Hunter by name: Hunter")
		else:
			print("ERROR: Hunter not found at all!")
	
	# Create respawn timer if it doesn't exist
	var respawn_timer = get_node_or_null("RespawnTimer")
	if not respawn_timer:
		respawn_timer = Timer.new()
		respawn_timer.name = "RespawnTimer"
		respawn_timer.wait_time = 0.1  # 0.1 second for instant respawn
		respawn_timer.one_shot = true
		add_child(respawn_timer)
		print("Created RespawnTimer with 0.1s delay")
	else:
		# Update existing timer to use instant respawn
		respawn_timer.wait_time = 0.1
		print("Updated RespawnTimer to 0.1s delay")
	
	# Setup collision detection timer
	var collision_timer = Timer.new()
	collision_timer.wait_time = 0.1  # Check 10 times per second
	collision_timer.timeout.connect(_check_collisions)
	add_child(collision_timer)
	collision_timer.start()
	print("DEBUG: Collision timer started")

	# Connect signals only if level exists
	if level:
		if level.has_signal("coin_collected"):
			level.coin_collected.connect(_on_coin_collected)
		if level.has_signal("all_coins_collected"):
			level.all_coins_collected.connect(_on_all_coins_collected)
	
	# Setup timers
	var game_timer = get_node_or_null("GameTimer")
	if game_timer:
		game_timer.timeout.connect(_on_game_timer_timeout)
	
	# Connect respawn timer
	respawn_timer.timeout.connect(_on_respawn_timer_timeout)
	print("Connected RespawnTimer signal")
	
	var transition_timer = get_node_or_null("LevelTransitionTimer")
	if transition_timer:
		transition_timer.timeout.connect(_on_level_transition_timeout)
	
	# Setup camera
	var camera = get_node_or_null("Camera2D")
	if camera:
		camera.enabled = true
		camera.position = Vector2(400, 300)
		print("DEBUG: Camera enabled and positioned")
	else:
		print("DEBUG: Camera not found!")
	
	# Force start the game if not already running
	if not game_running:
		print("DEBUG: Game not running, forcing start...")
		start_game()
	else:
		print("DEBUG: Game already running, skipping start")

func start_game():
	print("DEBUG: start_game() called!")
	game_running = true
	print("DEBUG: game_running set to: ", game_running)
	score = 0
	time_left = 90
	lives_remaining = 3
	decoys_remaining = 5
	current_level = 1
	
	print("DEBUG: Game initialized - lives: ", lives_remaining, " time: ", time_left)
	
	# Setup the level
	if level:
		print("DEBUG: Setting up level ", current_level)
		level.setup_level(current_level)
		
		# Store original spawn positions and position characters
		if escaper and hunter:
			var spawn_positions = level.get_spawn_positions()
			original_spawn_positions = spawn_positions
			escaper.global_position = spawn_positions.escaper
			hunter.global_position = spawn_positions.hunter
			print("DEBUG: Positioned characters - Escaper: ", escaper.global_position, " Hunter: ", hunter.global_position)
			# Give Hunter the level data
			if hunter.has_method("set_level_data"):
				var level_data = level.get_level_data()
				hunter.set_level_data(current_level, level_data)
			
			# Start escaper grace period
			if escaper.has_method("start_grace_period"):
				escaper.start_grace_period(5.0)
		else:
			print("ERROR: Escaper or Hunter not found for positioning!")
	
	# Start game timer
	var game_timer = get_node_or_null("GameTimer")
	if game_timer:
		game_timer.wait_time = game_time
		game_timer.start()
	
	# Update HUD
	if hud:
		hud.update_hud(self)
	
	game_started.emit()

func end_game():
	game_running = false
	var game_timer = get_node_or_null("GameTimer")
	if game_timer:
		game_timer.stop()
	
	if hud:
		hud.show_game_over("Hunter", cumulative_score + score)
	
	game_ended.emit()

func next_level():
	current_level += 1
	decoys_remaining = 5
	
	print("Starting level ", current_level)
	
	# Temporarily pause the game during transition
	game_running = false
	
	# Show level transition
	if hud:
		var level_manager = get_node_or_null("/root/LevelManager")
		var total_levels = 5  # Default or get from LevelManager
		if level_manager and level_manager.has_method("get_total_levels"):
			total_levels = level_manager.get_total_levels()
		
		hud.show_level_transition(current_level, total_levels, score)
	
	# Start transition timer (3 seconds instead of 5 for faster progression)
	var transition_timer = get_node_or_null("LevelTransitionTimer")
	if transition_timer:
		transition_timer.wait_time = 3.0  # 3 second transition
		transition_timer.start()
		print("Level transition timer started (3 seconds)")
	else:
		print("ERROR: LevelTransitionTimer not found!")
	
	level_completed.emit()

func _on_game_timer_timeout():
	end_game()

func _on_respawn_timer_timeout():
	print("DEBUG: RESPAWN TIMER TRIGGERED!")
	# Respawn escaper at safe position
	if escaper and level:
		print("DEBUG: Escaper found: ", escaper.name)
		print("DEBUG: Hunter position: ", hunter.global_position)
		
		# Get safe respawn position away from hunter
		var respawn_position: Vector2
		if not original_spawn_positions.is_empty():
			respawn_position = get_safe_respawn_position(original_spawn_positions.escaper)
			print("DEBUG: Final respawn position: ", respawn_position)
		else:
			# If no original positions stored, get them now
			var spawn_positions = level.get_spawn_positions()
			original_spawn_positions = spawn_positions
			respawn_position = get_safe_respawn_position(spawn_positions.escaper)
			print("DEBUG: Final respawn position (new): ", respawn_position)
		
		# Check if escaper has respawn method using different approaches
		if escaper.has_method("respawn"):
			print("DEBUG: Calling escaper.respawn() at position: ", respawn_position)
			escaper.respawn(respawn_position)
			# Force position update immediately after respawn
			escaper.global_position = respawn_position
			print("DEBUG: Forced position update to: ", escaper.global_position)
		elif escaper.get_script() and escaper.get_script().get_source_code().contains("func respawn"):
			print("DEBUG: Found respawn method in script, calling directly...")
			escaper.call("respawn", respawn_position)
			# Force position update immediately after respawn
			escaper.global_position = respawn_position
			print("DEBUG: Forced position update to: ", escaper.global_position)
		else:
			print("DEBUG: ERROR: Escaper doesn't have respawn method!")
			print("DEBUG: Available methods: ", escaper.get_method_list())
			# Fallback: just reposition escaper
			escaper.global_position = respawn_position
			print("DEBUG: Repositioned escaper to: ", respawn_position)
			# Start grace period manually
			if escaper.has_method("start_grace_period"):
				escaper.start_grace_period(8.0)
		
		# Verify final position
		print("DEBUG: Final verification - Escaper at: ", escaper.global_position, " Hunter at: ", hunter.global_position)
		var final_distance = escaper.global_position.distance_to(hunter.global_position)
		print("DEBUG: Final distance between characters: ", final_distance)
	else:
		print("DEBUG: ERROR: Escaper or level not found for respawn!")
		if not escaper:
			print("DEBUG: Escaper is null")
		if not level:
			print("DEBUG: Level is null")

func _on_level_transition_timeout():
	print("Level transition timeout - loading level ", current_level)
	# Load next level
	if level:
		if level.has_method("setup_level"):
			level.setup_level(current_level)
			print("Level ", current_level, " setup complete")
		else:
			print("ERROR: Level doesn't have setup_level method!")
		
		# Reset positions using original spawn positions or get new ones
		if escaper and hunter and level:
			if original_spawn_positions.is_empty():
				# Store original spawn positions on first level
				var spawn_positions = level.get_spawn_positions()
				original_spawn_positions = spawn_positions
				print("Stored original spawn positions: ", original_spawn_positions)
			else:
				print("Using existing original spawn positions: ", original_spawn_positions)
			
			# Use original positions for respawn
			escaper.global_position = original_spawn_positions.escaper
			hunter.global_position = original_spawn_positions.hunter
			print("Reset to original positions - Escaper: ", original_spawn_positions.escaper, " Hunter: ", original_spawn_positions.hunter)
			print("Actual Escaper position after reset: ", escaper.global_position)
			print("Actual Hunter position after reset: ", hunter.global_position)
			
			# Give Hunter the level data again
			if hunter.has_method("set_level_data"):
				var level_data = level.get_level_data()
				hunter.set_level_data(current_level, level_data)
				print("Hunter level data updated for level ", current_level)
			else:
				print("ERROR: Hunter doesn't have set_level_data method!")
		else:
			print("ERROR: Missing characters for level transition!")
	else:
		print("ERROR: Level node not found for transition!")
	
	# Resume game
	game_running = true
	print("Game resumed for level ", current_level)
	
	# Start game timer again
	var game_timer = get_node_or_null("GameTimer")
	if game_timer:
		game_timer.start()
		print("Game timer restarted for level ", current_level)
	else:
		print("ERROR: GameTimer not found!")
	
	# Update HUD
	if hud:
		hud.update_hud(self)
		print("HUD updated for level ", current_level)
	else:
		print("ERROR: HUD not found!")

func _on_coin_collected(value: int, is_bonus: bool):
	var points = value
	if is_bonus:
		points *= 2
	
	score += points
	cumulative_score += points
	
	if hud:
		hud.update_hud(self)
	
	score_updated.emit(score)

func _on_all_coins_collected():
	# Level completed - move to next level
	print("Level completed! All coins collected!")
	print("Current score: ", score, " Time bonus: ", int(time_left * 10))
	
	# Add time bonus to score
	var time_bonus = int(time_left * 10)  # 10 points per second remaining
	score += time_bonus
	cumulative_score += score
	
	# Check if this was the last level (let's say max 5 levels for now)
	if current_level >= 5:
		# Game completed - player wins all levels
		game_running = false
		var game_timer = get_node_or_null("GameTimer")
		if game_timer:
			game_timer.stop()
		
		print("Game Completed! All levels finished! Final score: ", cumulative_score + score)
		
		if hud:
			hud.show_game_over("Escaper", cumulative_score + score)
		
		game_ended.emit()
	else:
		# Move to next level
		next_level()

func get_safe_respawn_position(original_pos: Vector2) -> Vector2:
	var min_distance = 200.0  # Minimum distance from hunter
	var max_attempts = 50  # Maximum attempts to find safe position
	var hunter_pos = hunter.global_position
	
	print("DEBUG: Finding safe respawn position")
	print("DEBUG: Hunter at: ", hunter_pos)
	print("DEBUG: Original escaper pos: ", original_pos)
	
	# First check if original position is safe enough
	var original_distance = original_pos.distance_to(hunter_pos)
	print("DEBUG: Original distance from hunter: ", original_distance)
	
	if original_distance >= min_distance:
		print("DEBUG: Original position is safe: ", original_distance, " >= ", min_distance)
		return original_pos
	else:
		print("DEBUG: Original position is UNSAFE: ", original_distance, " < ", min_distance)
	
	# If original position is too close, find a safe alternative
	print("DEBUG: Searching for safe position in circle pattern...")
	for attempt in range(max_attempts):
		# Try positions in a circle around the original position
		var angle = (float(attempt) / max_attempts) * 2 * PI
		var radius = min_distance + (attempt * 20)  # Increase radius with attempts
		var candidate_pos = original_pos + Vector2(cos(angle), sin(angle)) * radius
		
		# Calculate distance from hunter
		var distance = candidate_pos.distance_to(hunter_pos)
		print("DEBUG: Attempt ", attempt + 1, ": pos ", candidate_pos, " distance: ", distance)
		
		# Check if position is safe and within reasonable bounds
		if distance >= min_distance:
			print("DEBUG: Found safe position at distance: ", distance)
			return candidate_pos
	
	# If no safe position found, use a fallback position far from hunter
	print("DEBUG: No safe position found after ", max_attempts, " attempts, using fallback")
	var fallback_pos = hunter_pos + Vector2(min_distance * 1.5, 0)
	print("DEBUG: Using fallback position: ", fallback_pos)
	return fallback_pos

func lose_life():
	lives_remaining -= 1
	
	print("Life lost! Lives remaining: ", lives_remaining)
	
	if hud:
		hud.update_hud(self)
	
	life_lost.emit()
	
	if lives_remaining <= 0:
		end_game()
	else:
		# Start respawn timer immediately
		var respawn_timer = get_node_or_null("RespawnTimer")
		if respawn_timer:
			print("Starting respawn timer...")
			respawn_timer.start()
		else:
			print("ERROR: RespawnTimer not found!")
			# Try to create it again
			respawn_timer = Timer.new()
			respawn_timer.name = "RespawnTimer"
			respawn_timer.wait_time = 2.0  # 2 second respawn delay
			respawn_timer.one_shot = true
			add_child(respawn_timer)
			respawn_timer.timeout.connect(_on_respawn_timer_timeout)
			respawn_timer.start()
			print("Created and started new RespawnTimer")

func _check_collisions():
	print("DEBUG: _check_collisions called - game_running: ", game_running)
	if not game_running:
		print("Game not running, skipping collision check")
		return
	
	if not escaper:
		print("Escaper not found, skipping collision check")
		return
	
	if not hunter:
		print("Hunter not found, skipping collision check")
		return
	
	var distance = escaper.global_position.distance_to(hunter.global_position)
	print("Collision check - Distance: ", distance, " Threshold: 25.0")
	
	if distance < 25.0:  # Collision threshold - increased for better detection
		print("COLLISION DETECTED! Distance: ", distance)
		
		# Check if escaper is in grace period
		var in_grace_period = false
		if escaper.has_method("is_in_grace_period"):
			in_grace_period = escaper.is_in_grace_period()
			print("Escaper grace period status: ", in_grace_period)
		else:
			print("Escaper doesn't have is_in_grace_period method")
		
		if in_grace_period:
			print("Hunter close to Escaper but Escaper is in grace period! Distance: ", distance)
			return  # Don't count as catch during grace period
		
		print("Hunter caught Escaper! Distance: ", distance)
		
		# Immediate visual feedback - make escaper flash
		if escaper.has_method("flash"):
			escaper.flash()
		else:
			# Simple color change as feedback
			var sprite = escaper.get_node_or_null("Sprite2D")
			if sprite:
				sprite.modulate = Color.RED
				await get_tree().create_timer(0.2).timeout
				sprite.modulate = Color.WHITE
		
		# Call lose_life on both GameManager and Escaper to sync lives
		print("Calling lose_life functions...")
		lose_life()
		if escaper and escaper.has_method("lose_life"):
			escaper.lose_life()
		else:
			print("Escaper doesn't have lose_life method")
		
		# Check if game should end or respawn
		print("Current lives: ", lives_remaining)
		if lives_remaining <= 0:
			print("Game Over - No lives remaining")
			end_game()
		else:
			print("Respawning - Lives remaining: ", lives_remaining)
			# Start respawn timer immediately
			var respawn_timer = get_node_or_null("RespawnTimer")
			if respawn_timer:
				print("Starting respawn timer...")
				respawn_timer.start()
			else:
				print("ERROR: RespawnTimer not found! Creating emergency timer...")
				# Emergency timer creation
				respawn_timer = Timer.new()
				respawn_timer.name = "RespawnTimer"
				respawn_timer.wait_time = 0.1
				respawn_timer.one_shot = true
				add_child(respawn_timer)
				respawn_timer.timeout.connect(_on_respawn_timer_timeout)
				respawn_timer.start()
				print("Created emergency RespawnTimer")
	else:
		print("No collision - Distance too high: ", distance)

func use_decoy():
	if decoys_remaining > 0:
		decoys_remaining -= 1
		
		# Spawn decoy at escaper position
		if escaper and level:
			if level.has_method("spawn_decoy"):
				level.spawn_decoy(escaper.global_position)
		
		if hud:
			hud.update_hud(self)
		
		return true
	return false

func get_game_state():
	return {
		"score": score,
		"cumulative_score": cumulative_score,
		"time_left": time_left,
		"lives_remaining": lives_remaining,
		"decoys_remaining": decoys_remaining,
		"current_level": current_level,
		"game_running": game_running
	}

func _process(delta):
	if game_running:
		time_left -= delta
		
		if hud:
			hud.update_hud(self)
		
		time_updated.emit(time_left)
		
		if time_left <= 0:
			end_game()
