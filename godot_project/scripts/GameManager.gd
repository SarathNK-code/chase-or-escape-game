extends Node
class_name GameManager

signal game_over(winner: String, final_score: int)
signal level_completed(level: int, score: int)
signal all_levels_completed(final_score: int)

enum GamePhase {
	MENU,
	PLAYING,
	LEVEL_TRANSITION,
	GAME_OVER,
	RESPAWNING
}

@export var escaper_scene: PackedScene
@export var hunter_scene: PackedScene
@export var level_scene: PackedScene

var current_phase: GamePhase = GamePhase.MENU
var current_level: int = 1
var total_levels: int = 5
var player_role: String = "escaper"  # "escaper" or "hunter"
var score: int = 0
var cumulative_score: int = 0
var time_remaining: float = 90.0
var lives_remaining: int = 3

var escaper: Escaper
var hunter: Hunter
var level: Level
var hud: HUD

func _ready():
	setup_game()
	connect_signals()

func setup_game():
	# Get references to existing nodes
	escaper = $Escaper
	hunter = $Hunter
	level = $Level
	hud = $HUD
	
	# Setup initial game state
	start_new_game()

func connect_signals():
	# Character signals
	escaper.coin_collected.connect(_on_coin_collected)
	escaper.life_lost.connect(_on_life_lost)
	escaper.decoy_dropped.connect(_on_decoy_dropped)
	
	# Level signals
	level.level_setup_complete.connect(_on_level_setup_complete)
	level.coin_collected.connect(_on_coin_collected)
	level.all_coins_collected.connect(_on_all_coins_collected)
	
	# Timer signals
	$GameTimer.timeout.connect(_on_game_timer_timeout)
	$RespawnTimer.timeout.connect(_on_respawn_timer_timeout)
	$LevelTransitionTimer.timeout.connect(_on_level_transition_timeout)

func start_new_game():
	current_level = 1
	cumulative_score = 0
	lives_remaining = 3
	score = 0
	current_phase = GamePhase.PLAYING
	
	setup_level(current_level)
	hud.update_hud(self)

func setup_level(level_number: int):
	current_level = level_number
	level.setup_level(level_number)
	
	# Wait for level setup to complete before spawning characters
	await level.level_setup_complete
	
	spawn_characters()
	setup_game_timer()
	
	# Update AI with level data
	var map_data = level.get_current_map_data()
	hunter.set_level_data(level_number, map_data)
	
	print("Level ", level_number, " setup complete")

func spawn_characters():
	var spawn_positions = level.get_spawn_positions()
	
	# Position characters
	escaper.position = spawn_positions.escaper
	hunter.position = spawn_positions.hunter
	
	# Reset character states
	escaper.reset_for_new_level()
	escaper.set_player_control(player_role == "escaper")
	
	hunter.set_player_control(player_role == "hunter")
	
	# Clear any existing decoys
	for decoy in level.get_decoys():
		decoy.queue_free()

func setup_game_timer():
	var settings = level.level_manager.get_level_difficulty_settings(current_level)
	time_remaining = settings.game_duration
	
	$GameTimer.wait_time = time_remaining
	$GameTimer.start()

func _process(delta):
	if current_phase == GamePhase.PLAYING:
		update_game_logic(delta)
		hud.update_hud(self)

func update_game_logic(delta):
	# Check for catch condition
	if escaper.can_be_caught:
		var distance = escaper.global_position.distance_to(hunter.global_position)
		if distance < 24.0:  # CATCH_DISTANCE
			handle_catch()

func handle_catch():
	if player_role == "escaper":
		# Escaper loses a life
		escaper.lose_life()
		
		if lives_remaining > 0:
			start_respawn_sequence()
		else:
			end_game("hunter")
	else:
		# Hunter wins immediately
		end_game("hunter")

func start_respawn_sequence():
	current_phase = GamePhase.RESPAWNING
	$RespawnTimer.start()
	hud.show_respawn_timer(5.0)

func _on_respawn_timer_timeout():
	# Find new spawn position for escaper
	var map_data = level.get_current_map_data()
	var new_position = level.level_manager.get_random_spawn_position(map_data, [hunter.global_position])
	
	escaper.respawn(new_position)
	current_phase = GamePhase.PLAYING
	hud.hide_respawn_timer()

func _on_coin_collected(value: int, is_bonus: bool):
	score += value
	hud.update_hud(self)
	
	print("Coin collected! Value: ", value, ", Bonus: ", is_bonus)

func _on_all_coins_collected():
	# Level complete!
	var level_score = score + int(time_remaining * 5)
	cumulative_score += level_score
	
	level_completed.emit(current_level, level_score)
	
	if current_level >= total_levels:
		end_game("escaper")
	else:
		start_level_transition()

func start_level_transition():
	current_phase = GamePhase.LEVEL_TRANSITION
	$LevelTransitionTimer.start()
	hud.show_level_transition(current_level, total_levels, score)

func _on_level_transition_timeout():
	current_level += 1
	setup_level(current_level)
	current_phase = GamePhase.PLAYING
	hud.hide_level_transition()

func _on_decoy_dropped(position: Vector2):
	level.spawn_decoy(position)
	
	# Add decoy reference to hunter
	var decoys = level.get_decoys()
	if decoys.size() > 0:
		hunter.add_decoy_reference(decoys[-1])

func _on_life_lost():
	lives_remaining = escaper.lives
	hud.update_hud(self)

func _on_game_timer_timeout():
	end_game("escaper")

func end_game(winner: String):
	current_phase = GamePhase.GAME_OVER
	
	var final_score = cumulative_score + score
	game_over.emit(winner, final_score)
	
	print("Game Over! Winner: ", winner, ", Final Score: ", final_score)

func _on_level_setup_complete():
	print("Level setup completed for level ", current_level)

func get_game_state() -> Dictionary:
	return {
		"current_level": current_level,
		"total_levels": total_levels,
		"score": score,
		"cumulative_score": cumulative_score,
		"time_remaining": time_remaining,
		"lives_remaining": lives_remaining,
		"player_role": player_role,
		"phase": current_phase,
		"coins_left": level.get_coins().filter(func(c): return not c.collected).size(),
		"decoys_remaining": escaper.decoys_remaining
	}

func set_player_role(role: String):
	player_role = role
	if escaper:
		escaper.set_player_control(role == "escaper")
	if hunter:
		hunter.set_player_control(role == "hunter")

func restart_game():
	# Reset everything
	current_level = 1
	cumulative_score = 0
	lives_remaining = 3
	score = 0
	current_phase = GamePhase.PLAYING
	
	# Clear level
	level.cleanup()
	
	# Start new game
	start_new_game()

func pause_game():
	current_phase = GamePhase.MENU
	$GameTimer.paused = true

func resume_game():
	if current_phase == GamePhase.MENU:
		current_phase = GamePhase.PLAYING
		$GameTimer.paused = false
