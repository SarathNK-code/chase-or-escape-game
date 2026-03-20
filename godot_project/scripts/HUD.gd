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
	
	# Enable input processing for game over panel
	set_process_input(true)

func _input(event):
	# Handle Enter key press on game over panel
	if event.is_action_pressed("ui_accept"):  # Enter key
		# Check if game over panel is visible
		var game_over_panel = find_child("GameOverPanel", true, false)
		if game_over_panel and game_over_panel.visible:
			print("Enter pressed on game over panel - returning to main menu")
			return_to_main_menu()

func return_to_main_menu():
	# Change scene back to main menu
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

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
	lives_label.name = "LivesLabel"  # Give it a name so it can be found
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
	
	# Get actual total coins created from level
	if game_manager and game_manager.level:
		total_coins = game_manager.level.get_total_coins_created()
		
		# Count remaining coins
		var coins = game_manager.level.get_coins()
		for coin in coins:
			if coin.has_method("get_collected"):
				if not coin.get_collected():
					coins_remaining += 1
			elif not coin.get("is_collected", false):
				coins_remaining += 1
	else:
		# Fallback if level not available
		total_coins = 8  # Default fallback
		coins_remaining = 0
	
	if coins_label:
		var display_text = "Coins: %d/%d" % [coins_remaining, total_coins]
		coins_label.text = display_text
	
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
	level_transition_panel.offset_left = -400.0  # Increased width
	level_transition_panel.offset_top = -200.0  # Increased height
	level_transition_panel.offset_right = 400.0
	level_transition_panel.offset_bottom = 200.0
	
	# Enhanced styling with better visibility
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.0156863, 0.027451, 0.062745, 0.99)  # Much darker background
	panel_style.border_width_left = 4  # Thicker borders
	panel_style.border_width_right = 4
	panel_style.border_width_top = 4
	panel_style.border_width_bottom = 4
	panel_style.border_color = Color("#fbbf24")  # Golden border
	panel_style.corner_radius_top_left = 20  # Larger corners
	panel_style.corner_radius_top_right = 20
	panel_style.corner_radius_bottom_left = 20
	panel_style.corner_radius_bottom_right = 20
	panel_style.shadow_color = Color(0, 0, 0, 0.8)  # Stronger shadow
	panel_style.shadow_offset = Vector2(6, 6)
	panel_style.shadow_size = 12
	level_transition_panel.add_theme_stylebox_override("panel", panel_style)
	level_transition_panel.visible = false
	
	# Create transition vbox
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	level_transition_panel.add_child(vbox)
	vbox.anchors_preset = Control.PRESET_FULL_RECT
	vbox.offset_left = 40.0  # More padding
	vbox.offset_top = 40.0
	vbox.offset_right = -40.0
	vbox.offset_bottom = -40.0
	vbox.add_theme_constant_override("separation", 20)  # More spacing
	
	# Create transition labels with proper sizing
	level_complete_label = Label.new()
	level_complete_label.name = "LevelCompleteLabel"
	level_complete_label.text = "Level Complete!"
	level_complete_label.anchors_preset = Control.PRESET_CENTER
	level_complete_label.offset_left = -180.0  # Proper sizing
	level_complete_label.offset_right = 180.0
	level_complete_label.offset_top = -25.0
	level_complete_label.offset_bottom = 25.0
	level_complete_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_complete_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_complete_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	level_complete_label.add_theme_font_size_override("font_size", 32)  # Slightly smaller for better fit
	level_complete_label.add_theme_color_override("font_color", Color("#fbbf24"))  # Golden color
	level_complete_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))  # Stronger shadow
	level_complete_label.add_theme_constant_override("shadow_offset_x", 3)
	level_complete_label.add_theme_constant_override("shadow_offset_y", 3)
	vbox.add_child(level_complete_label)
	
	transition_score_label = Label.new()
	transition_score_label.name = "ScoreLabel"
	transition_score_label.text = "Score: 100"
	transition_score_label.anchors_preset = Control.PRESET_CENTER
	transition_score_label.offset_left = -150.0
	transition_score_label.offset_right = 150.0
	transition_score_label.offset_top = -20.0
	transition_score_label.offset_bottom = 20.0
	transition_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	transition_score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	transition_score_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	transition_score_label.add_theme_font_size_override("font_size", 24)  # Slightly smaller for better fit
	transition_score_label.add_theme_color_override("font_color", Color("#10b981"))  # Bright green
	transition_score_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	transition_score_label.add_theme_constant_override("shadow_offset_x", 2)
	transition_score_label.add_theme_constant_override("shadow_offset_y", 2)
	vbox.add_child(transition_score_label)
	
	next_level_label = Label.new()
	next_level_label.name = "NextLevelLabel"
	next_level_label.text = "Next Level: 2"
	next_level_label.anchors_preset = Control.PRESET_CENTER
	next_level_label.offset_left = -140.0
	next_level_label.offset_right = 140.0
	next_level_label.offset_top = -18.0
	next_level_label.offset_bottom = 18.0
	next_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	next_level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	next_level_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	next_level_label.add_theme_font_size_override("font_size", 20)  # Slightly smaller for better fit
	next_level_label.add_theme_color_override("font_color", Color("#60a5fa"))  # Bright blue
	next_level_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	next_level_label.add_theme_constant_override("shadow_offset_x", 2)
	next_level_label.add_theme_constant_override("shadow_offset_y", 2)
	vbox.add_child(next_level_label)
	
	countdown_label = Label.new()
	countdown_label.name = "CountdownLabel"
	countdown_label.text = "🕐 5"
	countdown_label.anchors_preset = Control.PRESET_CENTER
	countdown_label.offset_left = -60.0
	countdown_label.offset_right = 60.0
	countdown_label.offset_top = -15.0
	countdown_label.offset_bottom = 15.0
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	countdown_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	countdown_label.add_theme_font_size_override("font_size", 18)  # Slightly smaller for better fit
	countdown_label.add_theme_color_override("font_color", Color("#e2e8f0"))  # Light gray
	countdown_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	countdown_label.add_theme_constant_override("shadow_offset_x", 2)
	countdown_label.add_theme_constant_override("shadow_offset_y", 2)
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
	
	# Simple and clear level completion message
	level_complete_label.text = "Level %d Complete!" % level
	
	# Simple score message
	transition_score_label.text = "Score: %d" % score
	
	# Clear next level information
	if level < total_levels:
		next_level_label.text = "Next: Level %d" % (level + 1)
	else:
		next_level_label.text = "All Levels Complete!"
	
	# Simple countdown
	countdown_label.text = "Starting in 5"
	
	# Simple entrance animation
	level_transition_panel.modulate = Color.TRANSPARENT
	var entrance_tween = create_tween()
	entrance_tween.set_ease(Tween.EASE_OUT)
	entrance_tween.set_trans(Tween.TRANS_BACK)
	entrance_tween.tween_property(level_transition_panel, "modulate", Color.WHITE, 0.5)
	
	# Start countdown
	transition_countdown_timer = Timer.new()
	add_child(transition_countdown_timer)
	transition_countdown_timer.wait_time = 1.0
	transition_countdown_timer.timeout.connect(_on_transition_countdown_tick)
	transition_countdown_timer.start()
	
	# Simple pulse animation for countdown
	var pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.set_ease(Tween.EASE_IN_OUT)
	pulse_tween.tween_property(countdown_label, "scale", Vector2(1.1, 1.1), 0.5)
	pulse_tween.tween_property(countdown_label, "scale", Vector2(1.0, 1.0), 0.5)

func get_score_performance(score: int) -> String:
	if score >= 1000:
		return "Legendary"
	elif score >= 800:
		return "Incredible"
	elif score >= 600:
		return "Amazing"
	elif score >= 400:
		return "Fantastic"
	elif score >= 200:
		return "Great"
	else:
		return "Good"

func get_performance_tier(score: int) -> int:
	if score >= 1000:
		return 4  # Legendary
	elif score >= 800:
		return 3  # Incredible
	elif score >= 600:
		return 2  # Amazing
	elif score >= 400:
		return 1  # Fantastic
	else:
		return 0  # Good/Great

func get_level_hint(level_number: int) -> String:
	var hints = [
		"Balanced Beginnings",
		"Spiral Maze Challenge",
		"Cross Pattern Strategy",
		"Diamond Paths Navigation",
		"Island Battle Tactics",
		"Advanced Spiral",
		"Complex Maze",
		"Strategic Cross",
		"Difficult Diamond",
		"Master Islands",
		"Expert Challenge",
		"Ultimate Test"
	]
	
	var hint_index = (level_number - 1) % hints.size()
	return hints[hint_index]

func hide_level_transition():
	level_transition_panel.visible = false
	if transition_countdown_timer:
		transition_countdown_timer.queue_free()
		transition_countdown_timer = null

func _on_transition_countdown_tick():
	# Extract the number from the countdown text
	var current_text = countdown_label.text
	var current_countdown = 5  # Default fallback
	
	# Try to extract number from text
	var regex = RegEx.new()
	regex.compile(r"\d+")
	var result = regex.search(current_text)
	if result:
		current_countdown = int(result.get_string())
	
	if current_countdown > 1:
		countdown_label.text = "Starting in " + str(current_countdown - 1)
	else:
		hide_level_transition()

func show_game_over(winner: String, final_score: int):
	# Create enhanced game over panel
	var game_over_panel = Panel.new()
	game_over_panel.name = "GameOverPanel"  # Name it so input handler can find it
	add_child(game_over_panel)
	game_over_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Enhanced styling with better visibility
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.0274509, 0.0509804, 0.125490, 0.99)  # Darker blue with higher opacity
	panel_style.border_width_left = 6
	panel_style.border_width_right = 6
	panel_style.border_width_top = 6
	panel_style.border_width_bottom = 6
	panel_style.border_color = Color("#fbbf24") if winner == "Escaper" else Color("#ef4444")  # Gold for win, red for lose
	panel_style.corner_radius_top_left = 25
	panel_style.corner_radius_top_right = 25
	panel_style.corner_radius_bottom_left = 25
	panel_style.corner_radius_bottom_right = 25
	panel_style.shadow_color = Color(0, 0, 0, 0.9)
	panel_style.shadow_offset = Vector2(8, 8)
	panel_style.shadow_size = 16
	game_over_panel.add_theme_stylebox_override("panel", panel_style)
	
	var vbox = VBoxContainer.new()
	game_over_panel.add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.offset_left = -300.0  # Much wider container
	vbox.offset_top = -250.0
	vbox.offset_right = 300.0
	vbox.offset_bottom = 250.0
	vbox.add_theme_constant_override("separation", 30)  # More spacing
	
	# Clear, prominent title with proper sizing
	var title_label = Label.new()
	vbox.add_child(title_label)
	title_label.anchors_preset = Control.PRESET_CENTER
	title_label.offset_left = -200.0
	title_label.offset_right = 200.0
	title_label.offset_top = -40.0
	title_label.offset_bottom = 40.0
	if winner == "Escaper":
		title_label.text = "🎉 VICTORY! 🎉"
	else:
		title_label.text = "🎯 GAME OVER 🎯"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.add_theme_font_size_override("font_size", 48)  # Slightly smaller but still prominent
	title_label.add_theme_color_override("font_color", Color("#fbbf24") if winner == "Escaper" else Color("#ef4444"))
	title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	title_label.add_theme_constant_override("shadow_offset_x", 4)
	title_label.add_theme_constant_override("shadow_offset_y", 4)
	
	# Winner name with clear indication and proper sizing
	var winner_label = Label.new()
	vbox.add_child(winner_label)
	winner_label.anchors_preset = Control.PRESET_CENTER
	winner_label.offset_left = -250.0
	winner_label.offset_right = 250.0
	winner_label.offset_top = -30.0
	winner_label.offset_bottom = 30.0
	if winner == "Escaper":
		winner_label.text = "🏆 Escaper Wins! All Coins Collected! 🏆"
	else:
		winner_label.text = "💀 Hunter Wins! Escaper Caught! 💀"
	winner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	winner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	winner_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	winner_label.add_theme_font_size_override("font_size", 28)  # Slightly smaller for better fit
	winner_label.add_theme_color_override("font_color", Color("#e2e8f0"))
	winner_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	winner_label.add_theme_constant_override("shadow_offset_x", 3)
	winner_label.add_theme_constant_override("shadow_offset_y", 3)
	
	# Final score with emphasis and proper sizing
	var score_label = Label.new()
	vbox.add_child(score_label)
	score_label.anchors_preset = Control.PRESET_CENTER
	score_label.offset_left = -200.0
	score_label.offset_right = 200.0
	score_label.offset_top = -35.0
	score_label.offset_bottom = 35.0
	score_label.text = "💎 FINAL SCORE: %d 💎" % final_score
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	score_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	score_label.add_theme_font_size_override("font_size", 36)  # Slightly smaller
	score_label.add_theme_color_override("font_color", Color("#10b981"))
	score_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	score_label.add_theme_constant_override("shadow_offset_x", 3)
	score_label.add_theme_constant_override("shadow_offset_y", 3)
	
	# Add stats if available with proper sizing
	var stats_label = Label.new()
	vbox.add_child(stats_label)
	stats_label.anchors_preset = Control.PRESET_CENTER
	stats_label.offset_left = -180.0
	stats_label.offset_right = 180.0
	stats_label.offset_top = -20.0
	stats_label.offset_bottom = 20.0
	var stats_text = ""
	if winner == "Escaper":
		stats_text = "🎯 Perfect run! No lives lost!"
	else:
		stats_text = "💪 Better luck next time!"
	stats_label.text = stats_text
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats_label.add_theme_font_size_override("font_size", 18)  # Readable size
	stats_label.add_theme_color_override("font_color", Color("#94a3b8"))
	
	# Restart instruction with proper sizing and enhanced visibility
	var restart_label = Label.new()
	vbox.add_child(restart_label)
	restart_label.anchors_preset = Control.PRESET_CENTER
	restart_label.offset_left = -200.0
	restart_label.offset_right = 200.0
	restart_label.offset_top = -20.0
	restart_label.offset_bottom = 20.0
	restart_label.text = "🎮 Press ENTER to return to main menu 🎮"
	restart_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	restart_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	restart_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	restart_label.add_theme_font_size_override("font_size", 18)  # Larger and more prominent
	restart_label.add_theme_color_override("font_color", Color("#60a5fa"))  # Blue color for visibility
	restart_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	restart_label.add_theme_constant_override("shadow_offset_x", 2)
	restart_label.add_theme_constant_override("shadow_offset_y", 2)
	
	# Add pulse animation to restart label
	var pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.set_ease(Tween.EASE_IN_OUT)
	pulse_tween.tween_property(restart_label, "modulate", Color("#80b8ff"), 1.0)
	pulse_tween.tween_property(restart_label, "modulate", Color("#60a5fa"), 1.0)
	
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
