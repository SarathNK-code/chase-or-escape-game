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
var collision_cooldown: float = 0.0  # Prevent multiple life losses from same collision

signal game_started
signal game_ended
signal level_completed
signal life_lost
signal score_updated(new_score)
signal time_updated(new_time)

func _ready():
	# Get references to game nodes
	hud = get_tree().get_first_node_in_group("hud")
	level = get_tree().get_first_node_in_group("level")
	escaper = get_tree().get_first_node_in_group("escaper")
	hunter = get_tree().get_first_node_in_group("hunter")
	
	# Check if we're in the main game scene
	var current_scene = get_tree().current_scene
	
	if not hud:
		# Try to find HUD by name
		hud = get_node_or_null("HUD")
	
	if not level:
		# Try to find Level by name
		level = get_node_or_null("Level")
	
	if not escaper:
		# Try to find Escaper by name
		escaper = get_node_or_null("Escaper")
	
	if not hunter:
		# Try to find Hunter by name
		hunter = get_node_or_null("Hunter")
	
	# Create respawn timer if it doesn't exist
	var respawn_timer = get_node_or_null("RespawnTimer")
	if not respawn_timer:
		respawn_timer = Timer.new()
		respawn_timer.name = "RespawnTimer"
		respawn_timer.wait_time = 0.1  # 0.1 second for instant respawn
		respawn_timer.one_shot = true
		add_child(respawn_timer)
	else:
		# Update existing timer to use instant respawn
		respawn_timer.wait_time = 0.1
	
	# Setup collision detection timer
	var collision_timer = Timer.new()
	collision_timer.wait_time = 0.1  # Check 10 times per second
	collision_timer.timeout.connect(_check_collisions)
	add_child(collision_timer)
	collision_timer.start()

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
	
	var transition_timer = get_node_or_null("LevelTransitionTimer")
	if transition_timer:
		transition_timer.timeout.connect(_on_level_transition_timeout)
	
	# Setup camera
	var camera = get_node_or_null("Camera2D")
	if camera:
		camera.enabled = true
		camera.position = Vector2(400, 300)
	
	# Force start the game if not already running
	if not game_running:
		start_game()

func start_game():
	game_running = true
	score = 0
	time_left = 90
	lives_remaining = 3
	decoys_remaining = 5
	current_level = 1
	
	# Hide all panels when starting new game
	if hud:
		hud.hide_all_panels()
	
	# Setup the level
	if level:
		level.setup_level(current_level)
		
		# Store original spawn positions and position characters
		if escaper and hunter:
			var spawn_positions = level.get_spawn_positions()
			original_spawn_positions = spawn_positions
			escaper.global_position = spawn_positions.escaper
			hunter.global_position = spawn_positions.hunter
			
			# Give Hunter the level data
			if hunter.has_method("set_level_data"):
				var level_data = level.get_level_data()
				hunter.set_level_data(current_level, level_data)
			
			# Start escaper grace period
			if escaper.has_method("start_grace_period"):
				escaper.start_grace_period(5.0)
	
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
	
	# Stop hunter movement
	if hunter:
		hunter.velocity = Vector2.ZERO
		if hunter.has_method("stop_movement"):
			hunter.stop_movement()
	
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
	# Don't respawn if game is already over
	if not game_running or lives_remaining <= 0:
		print("Respawn timer ignored - game over or not running")
		return
		
	print("Respawn timer triggered - processing respawn")
	# Respawn escaper at safe position
	if escaper and level:
		# Get safe respawn position away from hunter
		var respawn_position: Vector2
		if not original_spawn_positions.is_empty():
			respawn_position = get_safe_respawn_position(original_spawn_positions.escaper)
		else:
			# If no original positions stored, get them now
			var spawn_positions = level.get_spawn_positions()
			original_spawn_positions = spawn_positions
			respawn_position = get_safe_respawn_position(spawn_positions.escaper)
		
		print("Respawning escaper to position: ", respawn_position)
		
		# Check if escaper has respawn method using different approaches
		if escaper.has_method("respawn"):
			escaper.respawn(respawn_position)
			# Force position update immediately after respawn
			escaper.global_position = respawn_position
			print("Escaper respawned successfully using respawn method")
		elif escaper.get_script() and escaper.get_script().get_source_code().contains("func respawn"):
			escaper.call("respawn", respawn_position)
			# Force position update immediately after respawn
			escaper.global_position = respawn_position
			print("Escaper respawned successfully using call method")
		else:
			# Fallback: just reposition escaper
			escaper.global_position = respawn_position
			# Start grace period manually
			if escaper.has_method("start_grace_period"):
				escaper.start_grace_period(8.0)
			print("Escaper respawned using fallback reposition method")
		
		# Reset escaper velocity to ensure movement works
		if "velocity" in escaper:
			escaper.velocity = Vector2.ZERO
			print("Escaper velocity reset for respawn")
	else:
		print("ERROR: Cannot respawn - escaper or level not found")

func _on_level_transition_timeout():
	print("Level transition timeout - loading level ", current_level)
	
	# Hide level transition panel before starting new level
	if hud:
		hud.hide_level_transition()
	
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
	
	# Stop game immediately when all coins are collected
	game_running = false
	var game_timer = get_node_or_null("GameTimer")
	if game_timer:
		game_timer.stop()
	
	# Stop hunter movement immediately when all coins are collected
	if hunter:
		hunter.velocity = Vector2.ZERO
		if hunter.has_method("stop_movement"):
			hunter.stop_movement()
	
	# Add time bonus to score
	var time_bonus = int(time_left * 10)  # 10 points per second remaining
	score += time_bonus
	cumulative_score += score
	
	# Check if this was the last level (let's say max 5 levels for now)
	if current_level >= 5:
		# Game completed - player wins all levels
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
	
	# First check if original position is safe enough
	var original_distance = original_pos.distance_to(hunter_pos)
	
	if original_distance >= min_distance:
		return original_pos
	
	# If original position is too close, find a safe alternative
	for attempt in range(max_attempts):
		# Try positions in a circle around the original position
		var angle = (float(attempt) / max_attempts) * 2 * PI
		var radius = min_distance + (attempt * 20)  # Increase radius with attempts
		var candidate_pos = original_pos + Vector2(cos(angle), sin(angle)) * radius
		
		# Calculate distance from hunter
		var distance = candidate_pos.distance_to(hunter_pos)
		
		# Check if position is safe and within reasonable bounds
		if distance >= min_distance:
			return candidate_pos
	
	# If no safe position found, use a fallback position far from hunter
	var fallback_pos = hunter_pos + Vector2(min_distance * 1.5, 0)
	return fallback_pos

func lose_life():
	lives_remaining -= 1
	
	print("Life lost! Lives remaining: ", lives_remaining)
	
	# Update HUD immediately after life loss
	if hud:
		hud.update_hud(self)
	
	life_lost.emit()
	
	if lives_remaining <= 0:
		print("Game Over - No lives remaining")
		end_game()
	else:
		# Only start respawn timer if game is still running
		if game_running:
			print("Starting instant respawn for life: ", lives_remaining)
			# Start respawn timer immediately (0.1 seconds for instant respawn)
			var respawn_timer = get_node_or_null("RespawnTimer")
			if respawn_timer:
				respawn_timer.wait_time = 0.1  # Instant respawn
				respawn_timer.start()
			else:
				print("ERROR: RespawnTimer not found!")
				# Try to create it again
				respawn_timer = Timer.new()
				respawn_timer.name = "RespawnTimer"
				respawn_timer.wait_time = 0.1  # Instant respawn
				respawn_timer.one_shot = true
				add_child(respawn_timer)
				respawn_timer.timeout.connect(_on_respawn_timer_timeout)
				respawn_timer.start()
				print("Created and started instant RespawnTimer")

func _check_collisions():
	if not game_running:
		return
	
	if not escaper or not hunter:
		return
	
	# Don't check collisions if game is over or lives <= 0
	if lives_remaining <= 0:
		return
	
	# Check collision cooldown to prevent multiple life losses
	if collision_cooldown > 0:
		return
	
	var distance = escaper.global_position.distance_to(hunter.global_position)
	
	if distance < 25.0:  # Collision threshold - increased for better detection
		# Check if escaper is in grace period
		var in_grace_period = false
		if escaper.has_method("is_in_grace_period"):
			in_grace_period = escaper.is_in_grace_period()
		
		if in_grace_period:
			return  # Don't count as catch during grace period
		
		print("Collision detected! Distance: ", distance)
		
		# Start collision cooldown immediately to prevent multiple hits
		collision_cooldown = 2.0  # 2 second cooldown after collision
		
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
		lose_life()
		if escaper and escaper.has_method("lose_life"):
			escaper.lose_life()
		
		# Check if game should end or respawn
		if lives_remaining <= 0:
			end_game()
		else:
			# Start respawn timer immediately
			var respawn_timer = get_node_or_null("RespawnTimer")
			if respawn_timer:
				respawn_timer.start()
			else:
				# Emergency timer creation
				respawn_timer = Timer.new()
				respawn_timer.name = "RespawnTimer"
				respawn_timer.wait_time = 0.1
				respawn_timer.one_shot = true
				add_child(respawn_timer)
				respawn_timer.timeout.connect(_on_respawn_timer_timeout)
				respawn_timer.start()

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
		
		# Update collision cooldown
		if collision_cooldown > 0:
			collision_cooldown -= delta
		
		if hud:
			hud.update_hud(self)
		
		time_updated.emit(time_left)
		
		if time_left <= 0:
			end_game()
