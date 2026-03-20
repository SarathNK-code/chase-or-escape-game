extends Control

@onready var player_name_input: LineEdit = $VBoxContainer/PlayerNameInput
@onready var character_choice: OptionButton = $VBoxContainer/CharacterChoice
@onready var start_button: Button = $VBoxContainer/StartButton
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $VBoxContainer/SubtitleLabel
var background_node: Control
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var selected_character: String = "escaper"
var player_name: String = ""
var particle_system: CPUParticles2D

func _ready():
	setup_ui()
	create_animated_background()
	setup_animations()
	play_intro_animations()
	setup_keyboard_navigation()
	setup_sound_effects()

func setup_ui():
	# Create animated gradient background
	create_animated_background()
	
	# Setup title with enhanced styling and animation
	title_label.text = "🏃 Chase or Escape"
	title_label.add_theme_font_size_override("font_size", 42)
	title_label.add_theme_color_override("font_color", Color("#fbbf24"))
	title_label.add_theme_color_override("font_shadow_color", Color("#f59e0b"))
	title_label.add_theme_constant_override("shadow_offset_x", 2)
	title_label.add_theme_constant_override("shadow_offset_y", 2)
	
	# Setup subtitle with typing effect
	subtitle_label.text = "🎯 The Ultimate Chase Adventure!"
	subtitle_label.add_theme_font_size_override("font_size", 20)
	subtitle_label.add_theme_color_override("font_color", Color("#e2e8f0"))
	subtitle_label.add_theme_color_override("font_shadow_color", Color("#64748b"))
	subtitle_label.add_theme_constant_override("shadow_offset_x", 1)
	subtitle_label.add_theme_constant_override("shadow_offset_y", 1)
	
	# Setup character choice with cards instead of dropdown
	setup_character_cards()
	
	# Setup enhanced start button with animations
	start_button.text = "🎮 START PLAYING"
	start_button.add_theme_font_size_override("font_size", 24)
	start_button.custom_minimum_size = Vector2(350, 70)
	start_button.pressed.connect(_on_start_pressed)
	start_button.mouse_entered.connect(_on_button_hover)
	start_button.mouse_exited.connect(_on_button_exit)
	setup_button_style()
	
	# Setup enhanced input field with animations
	player_name_input.placeholder_text = "🦸 Enter your hero name..."
	player_name_input.add_theme_font_size_override("font_size", 20)
	player_name_input.custom_minimum_size = Vector2(350, 60)
	player_name_input.text_changed.connect(_on_name_changed)
	setup_input_field_style()
	
	# Hide the original dropdown since we're using cards
	character_choice.visible = false

func _on_name_changed(new_text: String):
	player_name = new_text.strip_edges()

func _on_start_pressed():
	player_name = player_name_input.text.strip_edges()
	
	if player_name.is_empty():
		player_name = "Hero"
	
	print("Starting adventure with name: ", player_name, " as ", selected_character)
	
	# Add enhanced haptic feedback for mobile
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(200)
	
	# Play start animation
	play_start_animation()
	
	# Store game settings
	GameSettings.player_name = player_name
	GameSettings.player_character = selected_character
	
	# Load main game scene after animation
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/GameManager.tscn")

func setup_character_cards():
	# Create a container for character cards
	var cards_container = HBoxContainer.new()
	cards_container.name = "CharacterCardsContainer"
	cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_container.add_theme_constant_override("separation", 20)
	
	# Find the subtitle label and insert cards after it
	var subtitle = $VBoxContainer/SubtitleLabel
	if subtitle:
		var subtitle_index = subtitle.get_index()
		$VBoxContainer.add_child(cards_container)
		$VBoxContainer.move_child(cards_container, subtitle_index + 1)
		print("Cards container inserted after subtitle at index: ", subtitle_index + 1)
	else:
		# Fallback: add at end if subtitle not found
		$VBoxContainer.add_child(cards_container)
		print("Cards container added at end (subtitle not found)")
	
	# Create Escaper card with enhanced colors
	var escaper_card = create_character_card("escaper", "🏃‍♀️", "Escaper", "Outsmart the Hunter!", Color("#3b82f6"), Color("#2563eb"))
	cards_container.add_child(escaper_card)
	
	# Create Hunter card with enhanced colors
	var hunter_card = create_character_card("hunter", "🎯", "Hunter", "Catch the Escaper!", Color("#dc2626"), Color("#b91c1c"))
	cards_container.add_child(hunter_card)
	
	# Select escaper by default (but allow immediate reselection)
	select_character_card(escaper_card)
	print("Initial selection: Escaper")

func create_character_card(character_type: String, icon: String, title: String, description: String, color: Color, hover_color: Color) -> Panel:
	var card = Panel.new()
	card.name = character_type.capitalize() + "Card"
	card.custom_minimum_size = Vector2(200, 140)
	card.mouse_filter = Control.MOUSE_FILTER_PASS  # Ensure card accepts mouse input
	
	# Create card style using the helper function
	var card_style = create_card_style(color, hover_color)
	card.add_theme_stylebox_override("normal", card_style)
	
	# Create hover style
	var hover_style = create_card_style(hover_color, hover_color)
	card.add_theme_stylebox_override("hover", hover_style)
	
	# Create card content
	var vbox = VBoxContainer.new()
	vbox.name = "Content"
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	card.add_child(vbox)
	
	# Add a selection indicator (initially hidden)
	var selection_indicator = ColorRect.new()
	selection_indicator.name = "SelectionIndicator"
	selection_indicator.color = Color.TRANSPARENT
	selection_indicator.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	selection_indicator.z_index = 5  # Draw below content but above background
	selection_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Allow clicks to pass through
	card.add_child(selection_indicator)
	
	# Icon label with enhanced styling
	var icon_label = Label.new()
	icon_label.name = "Icon"
	icon_label.text = icon
	icon_label.add_theme_font_size_override("font_size", 48)
	icon_label.add_theme_color_override("font_color", Color.WHITE)
	icon_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	icon_label.add_theme_constant_override("shadow_offset_x", 2)
	icon_label.add_theme_constant_override("shadow_offset_y", 2)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(icon_label)
	
	# Title label with enhanced styling
	var title_label = Label.new()
	title_label.name = "Title"
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	title_label.add_theme_constant_override("shadow_offset_x", 1)
	title_label.add_theme_constant_override("shadow_offset_y", 1)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)
	
	# Description label with better readability
	var desc_label = Label.new()
	desc_label.name = "Description"
	desc_label.text = description
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color.WHITE)
	desc_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	desc_label.add_theme_constant_override("shadow_offset_x", 1)
	desc_label.add_theme_constant_override("shadow_offset_y", 1)
	desc_label.modulate = Color(1, 1, 1, 0.9)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)
	
	# Connect signals
	card.mouse_entered.connect(_on_character_card_hovered.bind(card, hover_style))
	card.mouse_exited.connect(_on_character_card_exited.bind(card, card_style))
	card.gui_input.connect(_on_character_card_clicked.bind(card, character_type))
	
	# Store character type
	card.set_meta("character_type", character_type)
	
	return card

func create_card_style(base_color: Color, hover_color: Color) -> StyleBoxFlat:
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = base_color
	card_style.corner_radius_top_left = 20
	card_style.corner_radius_top_right = 20
	card_style.corner_radius_bottom_left = 20
	card_style.corner_radius_bottom_right = 20
	card_style.border_width_left = 4
	card_style.border_width_right = 4
	card_style.border_width_top = 4
	card_style.border_width_bottom = 4
	card_style.border_color = Color.WHITE
	card_style.shadow_color = Color(0, 0, 0, 0.3)
	card_style.shadow_size = 8
	card_style.shadow_offset = Vector2(4, 4)
	return card_style

func create_selected_card_style() -> StyleBoxFlat:
	var selected_style = StyleBoxFlat.new()
	selected_style.bg_color = Color("#fbbf24")  # Golden background for selected
	selected_style.corner_radius_top_left = 20
	selected_style.corner_radius_top_right = 20
	selected_style.corner_radius_bottom_left = 20
	selected_style.corner_radius_bottom_right = 20
	selected_style.border_width_left = 8  # Thicker border for visibility
	selected_style.border_width_right = 8
	selected_style.border_width_top = 8
	selected_style.border_width_bottom = 8
	selected_style.border_color = Color("#f59e0b")  # Darker gold border
	selected_style.shadow_color = Color(0, 0, 0, 0.7)  # Stronger shadow
	selected_style.shadow_size = 15  # Bigger shadow
	selected_style.shadow_offset = Vector2(8, 8)  # More offset
	return selected_style

func _on_character_card_hovered(card: Panel, hover_style: StyleBox):
	print("Hovered over: ", card.name, " Selected: ", card.get_meta("selected", false))
	# Don't override style if card is selected
	if not card.get_meta("selected", false):
		card.add_theme_stylebox_override("normal", hover_style)
		card.add_theme_stylebox_override("hover", hover_style)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(card, "scale", Vector2(1.05, 1.05), 0.2)

func _on_character_card_exited(card: Panel, normal_style: StyleBox):
	print("Exited from: ", card.name, " Selected: ", card.get_meta("selected", false))
	# Don't change style if selected, but still reset scale
	if card.get_meta("selected", false):
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.2)
		return
	card.add_theme_stylebox_override("normal", normal_style)
	card.add_theme_stylebox_override("hover", normal_style)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.2)

func _on_character_card_clicked(event: InputEvent, card: Panel, character_type: String):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Card clicked: ", card.name, " Type: ", character_type)
		# Always allow selection, even if already selected
		select_character_card(card)
		selected_character = character_type
		play_character_switch_animation()

func select_character_card(selected_card: Panel):
	print("Selecting character card: ", selected_card.name)
	# Deselect all cards first
	var cards_container = $VBoxContainer/CharacterCardsContainer
	for card in cards_container.get_children():
		card.set_meta("selected", false)
		# Reset to original style by recreating it
		var character_type = card.get_meta("character_type", "")
		if character_type == "escaper":
			var escaper_style = create_card_style(Color("#3b82f6"), Color("#2563eb"))
			card.add_theme_stylebox_override("normal", escaper_style)
			card.add_theme_stylebox_override("hover", escaper_style)
		elif character_type == "hunter":
			var hunter_style = create_card_style(Color("#dc2626"), Color("#b91c1c"))
			card.add_theme_stylebox_override("normal", hunter_style)
			card.add_theme_stylebox_override("hover", hunter_style)
		# Reset scale and modulate
		card.scale = Vector2(1.0, 1.0)
		card.modulate = Color.WHITE
		# Hide selection indicator
		var indicator = card.get_node_or_null("SelectionIndicator")
		if indicator:
			indicator.color = Color.TRANSPARENT
	
	# Select the new card with enhanced styling
	selected_card.set_meta("selected", true)
	var selected_style = create_selected_card_style()
	selected_card.add_theme_stylebox_override("normal", selected_style)
	selected_card.add_theme_stylebox_override("hover", selected_style)  # Also override hover
	print("Applied selected style to card: ", selected_card.name)
	print("Selected style border color: ", selected_style.border_color)
	print("Selected style bg color: ", selected_style.bg_color)
	
	# Show selection indicator with golden glow
	var selected_indicator = selected_card.get_node_or_null("SelectionIndicator")
	if selected_indicator:
		selected_indicator.color = Color(1.0, 0.8, 0.0, 0.3)  # Golden transparent overlay
		print("Selection indicator shown")
	
	# Force immediate visual update
	selected_card.queue_redraw()
	
	# Add a more dramatic glow effect
	var glow_tween = create_tween()
	glow_tween.set_loops()
	glow_tween.set_ease(Tween.EASE_IN_OUT)
	glow_tween.tween_property(selected_card, "modulate", Color(1.3, 1.3, 0.8, 1.0), 0.8)
	glow_tween.tween_property(selected_card, "modulate", Color.WHITE, 0.8)
	
	# Also add a scale pulse
	var scale_tween = create_tween()
	scale_tween.set_loops()
	scale_tween.set_ease(Tween.EASE_IN_OUT)
	scale_tween.tween_property(selected_card, "scale", Vector2(1.1, 1.1), 0.6)
	scale_tween.tween_property(selected_card, "scale", Vector2(1.0, 1.0), 0.6)

func _on_button_hover():
	# Animate button on hover
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(start_button, "scale", Vector2(1.05, 1.05), 0.2)
	tween.parallel().tween_property(start_button, "rotation", deg_to_rad(2), 0.1)
	tween.tween_property(start_button, "rotation", 0, 0.1)

func _on_button_exit():
	# Reset button animation
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(start_button, "scale", Vector2(1.0, 1.0), 0.2)

func create_animated_background():
	# Completely remove and destroy the original blue background
	var original_background = $Background
	if original_background:
		original_background.visible = false
		original_background.modulate = Color.TRANSPARENT
		original_background.queue_free()  # Completely remove the blue background
		print("Original blue background completely removed")
	
	# Store current children to re-add them in correct order
	var children_to_readd = []
	for child in get_children():
		if child.name != "Background":  # Skip the background we're removing
			children_to_readd.append(child)
			remove_child(child)
	
	# Create animated gradient background using ColorRect (better coverage)
	var gradient_rect = ColorRect.new()
	gradient_rect.name = "GradientBackground"
	gradient_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gradient_rect.color = Color("#1e293b")  # Dark slate background
	add_child(gradient_rect)  # This will be index 0 (behind everything)
	print("Gradient background created and positioned")
	
	# Create animated gradient overlay
	var gradient_overlay = TextureRect.new()
	gradient_overlay.name = "GradientOverlay"
	gradient_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gradient_overlay.modulate = Color(1, 1, 1, 0.7)  # Semi-transparent overlay
	add_child(gradient_overlay)  # This will be index 1 (behind UI but above background)
	print("Gradient overlay created and positioned")
	
	# Re-add all original children (they'll be on top)
	for child in children_to_readd:
		add_child(child)
	print("Re-added ", children_to_readd.size(), " UI elements on top")
	
	# Create particle system for magical effects
	particle_system = CPUParticles2D.new()
	particle_system.name = "BackgroundParticles"
	add_child(particle_system)
	particle_system.position = get_viewport().size / 2
	particle_system.emitting = true
	particle_system.amount = 50
	particle_system.lifetime = 3.0
	particle_system.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particle_system.emission_rect_extents = Vector2(get_viewport().size.x / 2, get_viewport().size.y / 2)
	particle_system.direction = Vector2(0, -1)
	particle_system.spread = 30.0
	particle_system.initial_velocity_min = 20.0
	particle_system.initial_velocity_max = 50.0
	particle_system.angular_velocity_min = -45.0
	particle_system.angular_velocity_max = 45.0
	particle_system.scale_amount_min = 0.1
	particle_system.scale_amount_max = 0.3
	particle_system.color = Color("#fbbf24")
	particle_system.modulate = Color(1, 1, 1, 0.6)

func setup_character_dropdown_style():
	# Style the character dropdown
	var dropdown_style = StyleBoxFlat.new()
	dropdown_style.bg_color = Color("#1e293b")
	dropdown_style.border_width_left = 2
	dropdown_style.border_width_right = 2
	dropdown_style.border_width_top = 2
	dropdown_style.border_width_bottom = 2
	dropdown_style.border_color = Color("#60a5fa")
	dropdown_style.corner_radius_top_left = 8
	dropdown_style.corner_radius_top_right = 8
	dropdown_style.corner_radius_bottom_left = 8
	dropdown_style.corner_radius_bottom_right = 8
	character_choice.add_theme_stylebox_override("normal", dropdown_style)

func setup_button_style():
	# Create enhanced button style with gradient
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color("#10b981")
	normal_style.corner_radius_top_left = 15
	normal_style.corner_radius_top_right = 15
	normal_style.corner_radius_bottom_left = 15
	normal_style.corner_radius_bottom_right = 15
	normal_style.border_width_left = 3
	normal_style.border_width_right = 3
	normal_style.border_width_top = 3
	normal_style.border_width_bottom = 3
	normal_style.border_color = Color("#34d399")
	
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color("#059669")
	hover_style.corner_radius_top_left = 15
	hover_style.corner_radius_top_right = 15
	hover_style.corner_radius_bottom_left = 15
	hover_style.corner_radius_bottom_right = 15
	hover_style.border_width_left = 3
	hover_style.border_width_right = 3
	hover_style.border_width_top = 3
	hover_style.border_width_bottom = 3
	hover_style.border_color = Color("#10b981")
	
	start_button.add_theme_stylebox_override("normal", normal_style)
	start_button.add_theme_stylebox_override("hover", hover_style)

func setup_input_field_style():
	# Style the input field
	var input_style = StyleBoxFlat.new()
	input_style.bg_color = Color("#1e293b")
	input_style.border_width_left = 2
	input_style.border_width_right = 2
	input_style.border_width_top = 2
	input_style.border_width_bottom = 2
	input_style.border_color = Color("#60a5fa")
	input_style.corner_radius_top_left = 10
	input_style.corner_radius_top_right = 10
	input_style.corner_radius_bottom_left = 10
	input_style.corner_radius_bottom_right = 10
	player_name_input.add_theme_stylebox_override("normal", input_style)

func create_character_preview():
	# Skip creating character preview to avoid UI conflicts
	# The existing UI elements should be sufficient
	pass

func update_character_preview():
	# Skip character preview updates to avoid UI conflicts
	pass

func play_character_switch_animation():
	# Add haptic feedback when switching character
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(50)

func play_intro_animations():
	# Animate title entrance
	title_label.modulate = Color.TRANSPARENT
	var title_tween = create_tween()
	title_tween.set_ease(Tween.EASE_OUT)
	title_tween.set_trans(Tween.TRANS_BACK)
	title_tween.tween_property(title_label, "modulate", Color.WHITE, 0.8)
	title_tween.parallel().tween_property(title_label, "scale", Vector2(1.1, 1.1), 0.5)
	title_tween.tween_property(title_label, "scale", Vector2(1.0, 1.0), 0.3)
	
	# Animate subtitle entrance
	subtitle_label.modulate = Color.TRANSPARENT
	await get_tree().create_timer(0.3).timeout
	var subtitle_tween = create_tween()
	subtitle_tween.set_ease(Tween.EASE_OUT)
	subtitle_tween.tween_property(subtitle_label, "modulate", Color.WHITE, 0.6)

func play_start_animation():
	# Play a fun start animation
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(start_button, "scale", Vector2(1.2, 1.2), 0.2)
	tween.parallel().tween_property(start_button, "rotation", deg_to_rad(360), 0.4)
	tween.tween_property(start_button, "scale", Vector2(0.1, 0.1), 0.3)

func setup_animations():
	# Create animation player if it doesn't exist
	if not animation_player:
		animation_player = AnimationPlayer.new()
		add_child(animation_player)

func setup_keyboard_navigation():
	# Allow keyboard navigation for accessibility
	set_process_input(true)

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ENTER:
				_on_start_pressed()
			KEY_LEFT, KEY_RIGHT:
				# Toggle character selection with cards
				var cards_container = $VBoxContainer/CharacterCardsContainer
				if cards_container:
					var cards = cards_container.get_children()
					var current_selected = -1
					
					# Find currently selected card
					for i in range(cards.size()):
						if cards[i].get_meta("selected", false):
							current_selected = i
							break
					
					# Select next card
					var next_index = (current_selected + 1) % cards.size()
					select_character_card(cards[next_index])
					selected_character = cards[next_index].get_meta("character_type")
					play_character_switch_animation()

func setup_sound_effects():
	# Create audio player for menu sounds
	var audio_player = AudioStreamPlayer.new()
	audio_player.name = "MenuAudioPlayer"
	add_child(audio_player)

func play_menu_sound(sound_name: String):
	var audio_player = $MenuAudioPlayer
	if audio_player:
		# You can add different sound files here
		pass

func _on_character_choice_item_selected(index: int):
	# This function is no longer needed since we're using cards instead of dropdown
	pass
