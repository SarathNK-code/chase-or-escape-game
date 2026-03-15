extends CanvasLayer
class_name HUD

@onready var lives_hearts: Array[Label] = [
	$TopPanel/MarginContainer/HBoxContainer/LeftInfo/LivesContainer/LivesHearts/Heart1,
	$TopPanel/MarginContainer/HBoxContainer/LeftInfo/LivesContainer/LivesHearts/Heart2,
	$TopPanel/MarginContainer/HBoxContainer/LeftInfo/LivesContainer/LivesHearts/Heart3
]

@onready var score_label: Label = $TopPanel/MarginContainer/HBoxContainer/LeftInfo/ScoreLabel
@onready var decoys_label: Label = $TopPanel/MarginContainer/HBoxContainer/LeftInfo/DecoysLabel
@onready var timer_label: Label = $TopPanel/MarginContainer/HBoxContainer/CenterInfo/TimerLabel
@onready var level_label: Label = $TopPanel/MarginContainer/HBoxContainer/CenterInfo/LevelLabel
@onready var coins_label: Label = $TopPanel/MarginContainer/HBoxContainer/RightInfo/CoinsLabel

@onready var respawn_panel: Panel = $RespawnPanel
@onready var respawn_label: Label = $RespawnPanel/RespawnLabel

@onready var level_transition_panel: Panel = $LevelTransitionPanel
@onready var level_complete_label: Label = $LevelTransitionPanel/VBoxContainer/LevelCompleteLabel
@onready var transition_score_label: Label = $LevelTransitionPanel/VBoxContainer/ScoreLabel
@onready var next_level_label: Label = $LevelTransitionPanel/VBoxContainer/NextLevelLabel
@onready var countdown_label: Label = $LevelTransitionPanel/VBoxContainer/CountdownLabel

var respawn_countdown_timer: Timer
var transition_countdown_timer: Timer

func _ready():
	hide_all_panels()

func hide_all_panels():
	respawn_panel.visible = false
	level_transition_panel.visible = false

func update_hud(game_manager: GameManager):
	var state = game_manager.get_game_state()
	
	# Update lives
	update_lives_display(state.lives_remaining)
	
	# Update score
	score_label.text = "SCORE: %d" % (state.cumulative_score + state.score)
	
	# Update decoys
	decoys_label.text = "DECOYS[SPACE]: %d" % state.decoys_remaining
	
	# Update timer
	update_timer_display(state.time_remaining)
	
	# Update level
	level_label.text = "Level %d/%d" % [state.current_level, state.total_levels]
	
	# Update coins
	coins_label.text = "COINS: %d left" % state.coins_left

func update_lives_display(lives: int):
	for i in range(3):
		if i < lives:
			lives_hearts[i].text = "❤️"
		else:
			lives_hearts[i].text = "🤍"

func update_timer_display(time_remaining: float):
	var minutes = int(time_remaining) / 60
	var seconds = int(time_remaining) % 60
	timer_label.text = "%d:%02d" % [minutes, seconds]
	
	# Change color based on time remaining
	if time_remaining <= 10:
		timer_label.modulate = Color.RED
	elif time_remaining <= 30:
		timer_label.modulate = Color.ORANGE
	else:
		timer_label.modulate = Color.GREEN

func show_respawn_timer(duration: float):
	respawn_panel.visible = true
	respawn_label.text = "Respawning in %d..." % int(duration)
	
	# Create countdown timer
	respawn_countdown_timer = Timer.new()
	add_child(respawn_countdown_timer)
	respawn_countdown_timer.wait_time = 1.0
	respawn_countdown_timer.timeout.connect(_on_respawn_countdown_tick)
	respawn_countdown_timer.start()

func hide_respawn_timer():
	respawn_panel.visible = false
	if respawn_countdown_timer:
		respawn_countdown_timer.queue_free()
		respawn_countdown_timer = null

func _on_respawn_countdown_tick():
	var current_text = respawn_label.text
	var current_time = int(current_text.split(" ")[2].rstrip("..."))
	
	if current_time > 1:
		respawn_label.text = "Respawning in %d..." % (current_time - 1)
	else:
		hide_respawn_timer()

func show_level_transition(level: int, total_levels: int, score: int):
	level_transition_panel.visible = true
	
	level_complete_label.text = "Level %d Complete!" % level
	transition_score_label.text = "Score: %d points" % score
	
	if level < total_levels:
		next_level_label.text = "Get ready for Level %d..." % (level + 1)
	else:
		next_level_label.text = "All Levels Completed!"
	
	# Start countdown
	countdown_label.text = "5"
	transition_countdown_timer = Timer.new()
	add_child(transition_countdown_timer)
	transition_countdown_timer.wait_time = 1.0
	transition_countdown_timer.timeout.connect(_on_transition_countdown_tick)
	transition_countdown_timer.start()

func hide_level_transition():
	level_transition_panel.visible = false
	if transition_countdown_timer:
		transition_countdown_timer.queue_free()
		transition_countdown_timer = null

func _on_transition_countdown_tick():
	var current_countdown = int(countdown_label.text)
	
	if current_countdown > 1:
		countdown_label.text = str(current_countdown - 1)
	else:
		hide_level_transition()

func show_game_over(winner: String, final_score: int):
	# Create game over panel
	var game_over_panel = Panel.new()
	add_child(game_over_panel)
	game_over_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_over_panel.color = Color(0.0588235, 0.0901961, 0.164706, 0.95)
	
	var vbox = VBoxContainer.new()
	game_over_panel.add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	
	var title_label = Label.new()
	vbox.add_child(title_label)
	title_label.text = "Game Over!"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 48)
	
	var winner_label = Label.new()
	vbox.add_child(winner_label)
	winner_label.text = "Winner: %s" % winner.capitalize()
	winner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	winner_label.add_theme_font_size_override("font_size", 24)
	
	var score_label = Label.new()
	vbox.add_child(score_label)
	score_label.text = "Final Score: %d" % final_score
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 20)

func show_pause_menu():
	var pause_panel = Panel.new()
	add_child(pause_panel)
	pause_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_panel.color = Color(0.0588235, 0.0901961, 0.164706, 0.85)
	
	var vbox = VBoxContainer.new()
	pause_panel.add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	
	var title_label = Label.new()
	vbox.add_child(title_label)
	title_label.text = "Game Paused"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 36)

func get_hud_elements() -> Dictionary:
	return {
		"lives_hearts": lives_hearts,
		"score_label": score_label,
		"decoys_label": decoys_label,
		"timer_label": timer_label,
		"level_label": level_label,
		"coins_label": coins_label,
		"respawn_panel": respawn_panel,
		"respawn_label": respawn_label,
		"level_transition_panel": level_transition_panel,
		"level_complete_label": level_complete_label,
		"transition_score_label": transition_score_label,
		"next_level_label": next_level_label,
		"countdown_label": countdown_label
	}
