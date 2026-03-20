extends CanvasLayer

var lives_hearts: Array = []
var score_label: Label
var decoys_label: Label
var timer_label: Label
var level_label: Label
var coins_label: Label
var respawn_panel: Panel
var respawn_label: Label
var level_transition_panel: Panel
var level_complete_label: Label
var transition_score_label: Label
var next_level_label: Label
var countdown_label: Label

var respawn_countdown_timer: Timer
var transition_countdown_timer: Timer

func _ready():
	setup_hud_nodes()
	hide_all_panels()

func setup_hud_nodes():
	# Create compact top panel
	var top_panel = Panel.new()
	top_panel.name = "TopPanel"
	add_child(top_panel)
	
	# Setup panel anchors and styling
	top_panel.anchors_preset = Control.PRESET_TOP_WIDE
	top_panel.anchor_right = 1.0
	top_panel.offset_bottom = 60.0  # Compact height
	
	# Create stylebox for panel background
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.0588235, 0.0901961, 0.164706, 0.9)
	top_panel.add_theme_stylebox_override("panel", panel_style)
	
	# Create margin container
	var margin_container = MarginContainer.new()
	margin_container.name = "MarginContainer"
	top_panel.add_child(margin_container)
	margin_container.anchors_preset = Control.PRESET_FULL_RECT
	margin_container.offset_left = 10.0
	margin_container.offset_top = 5.0
	margin_container.offset_right = -10.0
	margin_container.offset_bottom = -5.0
	
	# Create main HBox container for compact layout
	var hbox = HBoxContainer.new()
	hbox.name = "HBoxContainer"
	margin_container.add_child(hbox)
	hbox.add_theme_constant_override("separation", 15)
	
	# Level info
	level_label = Label.new()
	level_label.text = "Level 1"
	level_label.add_theme_font_size_override("font_size", 16)
	level_label.add_theme_color_override("font_color", Color("#fbbf24"))
	hbox.add_child(level_label)
	
	# Separator
	var separator1 = VSeparator.new()
	hbox.add_child(separator1)
	
	# Score info
	score_label = Label.new()
	score_label.text = "Score: 0"
	score_label.add_theme_font_size_override("font_size", 16)
	score_label.add_theme_color_override("font_color", Color("#e2e8f0"))
	hbox.add_child(score_label)
	
	# Separator
	var separator2 = VSeparator.new()
	hbox.add_child(separator2)
	
	# Coins info
	coins_label = Label.new()
	coins_label.text = "Coins: 0/0"
	coins_label.add_theme_font_size_override("font_size", 16)
	coins_label.add_theme_color_override("font_color", Color("#fbbf24"))
	hbox.add_child(coins_label)
	
	# Spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)
	
	# Timer info
	timer_label = Label.new()
	timer_label.text = "⏱️ 60"
	timer_label.add_theme_font_size_override("font_size", 16)
	timer_label.add_theme_color_override("font_color", Color("#60a5fa"))
	hbox.add_child(timer_label)
	
	# Separator
	var separator3 = VSeparator.new()
	hbox.add_child(separator3)
	
	# Lives info
	var lives_label = Label.new()
	lives_label.text = "Lives: 3"
	lives_label.add_theme_font_size_override("font_size", 16)
	lives_label.add_theme_color_override("font_color", Color("#ef4444"))
	hbox.add_child(lives_label)
	
	# Separator
	var separator4 = VSeparator.new()
	hbox.add_child(separator4)
	
	# Decoys info
	decoys_label = Label.new()
	decoys_label.text = "Decoys: 5"
	decoys_label.add_theme_font_size_override("font_size", 16)
	decoys_label.add_theme_color_override("font_color", Color("#a78bfa"))
	hbox.add_child(decoys_label)

func update_hud(game_manager):
	if not game_manager:
		return
	
	# Update level
	if level_label:
		level_label.text = "Level %d" % game_manager.current_level
	
	# Update score
	if score_label:
		score_label.text = "Score: %d" % game_manager.score
	
	# Update coins - get remaining coins from level
	var coins_remaining = 0
	var total_coins = 0
	
	# Get total coins from game manager instead of level manager
	if game_manager:
		var level_manager = get_node_or_null("/root/LevelManager")
		if level_manager and level_manager.has_method("get_level_difficulty_settings"):
			var settings = level_manager.get_level_difficulty_settings(game_manager.current_level)
			total_coins = settings.num_coins
			print("DEBUG: Got total_coins from LevelManager settings: ", total_coins)
		else:
			# Use game manager's stored total or fallback
			if game_manager.has_method("get_total_coins_for_level"):
				total_coins = game_manager.get_total_coins_for_level(game_manager.current_level)
				print("DEBUG: Got total_coins from GameManager: ", total_coins)
			else:
				# Last fallback: use a reasonable default based on level
				total_coins = 8 + (game_manager.current_level - 1) * 2  # 8, 10, 12, etc.
				print("DEBUG: Using calculated total_coins: ", total_coins)
		
		# Count remaining coins
		var coins = game_manager.level.get_coins()
		print("DEBUG: Current coins array size: ", coins.size())
		for coin in coins:
			if coin.has_method("get_collected"):
				if not coin.get_collected():
					coins_remaining += 1
			elif not coin.get("is_collected", false):
				coins_remaining += 1
		
		print("DEBUG: coins_remaining: ", coins_remaining, " total_coins: ", total_coins)
	
	if coins_label:
		var display_text = "Coins: %d/%d" % [coins_remaining, total_coins]
		coins_label.text = display_text
		print("DEBUG: Setting coins_label to: ", display_text)
	
	# Update timer
	if timer_label:
		var minutes = int(game_manager.time_left) / 60
		var seconds = int(game_manager.time_left) % 60
		timer_label.text = "⏱️ %d:%02d" % [minutes, seconds]
		
		# Change color based on time remaining
		if game_manager.time_left < 10:
			timer_label.add_theme_color_override("font_color", Color("#ef4444"))  # Red
		elif game_manager.time_left < 30:
			timer_label.add_theme_color_override("font_color", Color("#f59e0b"))  # Orange
		else:
			timer_label.add_theme_color_override("font_color", Color("#60a5fa"))  # Blue
	
	# Update lives
	var lives_text = "Lives: %d" % game_manager.lives_remaining
	if game_manager.lives_remaining <= 1:
		lives_text += " ⚠️"
	
	# Find and update lives label
	var lives_label = find_child("LivesLabel", true, false)
	if lives_label:
		lives_label.text = lives_text
		if game_manager.lives_remaining <= 1:
			lives_label.add_theme_color_override("font_color", Color("#ef4444"))
		else:
			lives_label.add_theme_color_override("font_color", Color("#ef4444"))
	
	# Update decoys
	if decoys_label:
		decoys_label.text = "Decoys: %d" % game_manager.decoys_remaining

	# Create respawn panel
	respawn_panel = Panel.new()
	respawn_panel.name = "RespawnPanel"
	add_child(respawn_panel)
	respawn_panel.anchors_preset = Control.PRESET_CENTER
	respawn_panel.offset_left = -150.0
	respawn_panel.offset_top = -50.0
	respawn_panel.offset_right = 150.0
	respawn_panel.offset_bottom = 50.0
	respawn_panel.modulate = Color(0.1, 0.1, 0.1, 0.9)
	respawn_panel.visible = false
	
	# Create respawn label
	respawn_label = Label.new()
	respawn_label.name = "RespawnLabel"
	respawn_panel.add_child(respawn_label)
	respawn_label.anchors_preset = Control.PRESET_CENTER
	respawn_label.offset_left = -75.0
	respawn_label.offset_top = -11.5
	respawn_label.offset_right = 75.0
	respawn_label.offset_bottom = 11.5
	respawn_label.text = "Respawning in 3..."
	respawn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Create level transition panel
	level_transition_panel = Panel.new()
	level_transition_panel.name = "LevelTransitionPanel"
	add_child(level_transition_panel)
	level_transition_panel.anchors_preset = Control.PRESET_CENTER
	level_transition_panel.offset_left = -200.0
	level_transition_panel.offset_top = -100.0
	level_transition_panel.offset_right = 200.0
	level_transition_panel.offset_bottom = 100.0
	level_transition_panel.modulate = Color(0.1, 0.1, 0.1, 0.9)
	level_transition_panel.visible = false
	
	# Create transition vbox
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	level_transition_panel.add_child(vbox)
	vbox.anchors_preset = Control.PRESET_FULL_RECT
	vbox.offset_left = 20.0
	vbox.offset_top = 20.0
	vbox.offset_right = -20.0
	vbox.offset_bottom = -20.0
	
	# Create transition labels
	level_complete_label = Label.new()
	level_complete_label.name = "LevelCompleteLabel"
	level_complete_label.text = "Level Complete!"
	level_complete_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(level_complete_label)
	
	transition_score_label = Label.new()
	transition_score_label.name = "ScoreLabel"
	transition_score_label.text = "Score: 100"
	transition_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(transition_score_label)
	
	next_level_label = Label.new()
	next_level_label.name = "NextLevelLabel"
	next_level_label.text = "Next Level: 2"
	next_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(next_level_label)
	
	countdown_label = Label.new()
	countdown_label.name = "CountdownLabel"
	countdown_label.text = "Starting in 3..."
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(countdown_label)

func hide_all_panels():
	if respawn_panel:
		respawn_panel.visible = false
	if level_transition_panel:
		level_transition_panel.visible = false

func update_lives_display(lives: int):
	for i in range(min(3, lives_hearts.size())):
		if i < lives:
			lives_hearts[i].text = "❤️"
		else:
			lives_hearts[i].text = "🤍"

func update_timer_display(time_remaining: float):
	if timer_label:
		var minutes = int(time_remaining) / 60
		var seconds = int(time_remaining) % 60
		timer_label.text = "⏱️ %d:%02d" % [minutes, seconds]
		
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
	
	# Enhanced user-friendly messages with emojis and excitement
	var messages = [
		"🎉 Level %d Complete! Amazing Work!" % level,
		"⭐ Level %d Cleared! You're on Fire!" % level,
		"🏆 Level %d Mastered! Outstanding!" % level,
		"💫 Level %d Conquered! Fantastic!" % level
	]
	level_complete_label.text = messages[level % messages.size()]
	
	# Enhanced score message with encouragement
	var score_messages = [
		"🎯 Score: %d points - Great Job!" % score,
		"⚡ Score: %d points - Keep Going!" % score,
		"🚀 Score: %d points - Incredible!" % score,
		"💎 Score: %d points - Brilliant!" % score
	]
	transition_score_label.text = score_messages[min(score / 100, score_messages.size() - 1)]
	
	if level < total_levels:
		var next_messages = [
			"🎮 Get Ready for Level %d - New Challenges Await!" % (level + 1),
			"🌟 Level %d Coming Up - You Got This!" % (level + 1),
			"🔥 Level %d Loading - Time to Shine!" % (level + 1),
			"⚡ Level %d Approaching - Stay Focused!" % (level + 1)
		]
		next_level_label.text = next_messages[level % next_messages.size()]
	else:
		next_level_label.text = "🏆 All Levels Completed! You're a Champion! 🎊"
	
	# Start countdown with enhanced visual
	countdown_label.text = "🕐 5"
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
	# Create enhanced game over panel
	var game_over_panel = Panel.new()
	add_child(game_over_panel)
	game_over_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_over_panel.modulate = Color(0.0588235, 0.0901961, 0.164706, 0.95)
	
	var vbox = VBoxContainer.new()
	game_over_panel.add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.add_theme_constant_override("separation", 20)
	
	# Winner icon and title
	var winner_container = HBoxContainer.new()
	vbox.add_child(winner_container)
	winner_container.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var winner_icon = Label.new()
	winner_icon.text = "🏆" if winner == "Escaper" else "🎯"
	winner_icon.add_theme_font_size_override("font_size", 48)
	winner_container.add_child(winner_icon)
	
	var title_label = Label.new()
	vbox.add_child(title_label)
	if winner == "Escaper":
		title_label.text = "Victory! All Coins Collected!"
	else:
		title_label.text = "Game Over!"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 36)
	title_label.add_theme_color_override("font_color", Color("#fbbf24"))
	
	# Winner name
	var winner_label = Label.new()
	vbox.add_child(winner_label)
	winner_label.text = "Winner: %s" % winner.capitalize()
	winner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	winner_label.add_theme_font_size_override("font_size", 24)
	winner_label.add_theme_color_override("font_color", Color("#e2e8f0"))
	
	# Final score with breakdown
	var score_container = VBoxContainer.new()
	vbox.add_child(score_container)
	score_container.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var score_title = Label.new()
	score_title.text = "Final Score Breakdown:"
	score_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_title.add_theme_font_size_override("font_size", 18)
	score_title.add_theme_color_override("font_color", Color("#a78bfa"))
	score_container.add_child(score_title)
	
	var score_label = Label.new()
	vbox.add_child(score_label)
	score_label.text = "Total Score: %d" % final_score
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 28)
	score_label.add_theme_color_override("font_color", Color("#10b981"))
	
	# Add stats if available
	var stats_label = Label.new()
	vbox.add_child(stats_label)
	var stats_text = ""
	if winner == "Escaper":
		stats_text = "🎯 Perfect run! No lives lost!"
	else:
		stats_text = "💪 Better luck next time!"
	stats_label.text = stats_text
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.add_theme_font_size_override("font_size", 16)
	stats_label.add_theme_color_override("font_color", Color("#94a3b8"))
	
	# Restart instruction
	var restart_label = Label.new()
	vbox.add_child(restart_label)
	restart_label.text = "Press ENTER to return to main menu"
	restart_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	restart_label.add_theme_font_size_override("font_size", 14)
	restart_label.add_theme_color_override("font_color", Color("#64748b"))
	
	# Add animation
	game_over_panel.modulate = Color.TRANSPARENT
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(game_over_panel, "modulate", Color.WHITE, 0.5)

func show_pause_menu():
	var pause_panel = Panel.new()
	add_child(pause_panel)
	pause_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_panel.modulate = Color(0.0588235, 0.0901961, 0.164706, 0.85)
	
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
