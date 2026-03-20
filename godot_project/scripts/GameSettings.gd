extends Node

signal settings_loaded

var player_name: String = "Player"
var player_character: String = "escaper"

func _ready():
	load_settings()

func load_settings():
	# Load settings from file or use defaults
	pass

func save_settings():
	# Save settings to file
	pass
