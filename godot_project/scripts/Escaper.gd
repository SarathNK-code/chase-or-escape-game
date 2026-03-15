extends Character
class_name Escaper

signal decoy_dropped(position: Vector2)
signal all_coins_collected()

@export var max_decoys: int = 3
@export var decoys_remaining: int = 3
@export var lives: int = 3

var footprints: Array[Dictionary] = []
var footprint_timer: float = 0.0
var footprint_interval: float = 0.125  # 8 frames at 60fps

func _ready():
	super._ready()
	character_type = "escaper"
	speed = 160.0
	setup_visuals()

func _process(delta):
	# Handle footprint generation
	footprint_timer += delta
	if footprint_timer >= footprint_interval and velocity.length() > 0:
		footprint_timer = 0.0
		add_footprint()
	
	# Clean up old footprints
	var current_time = Time.get_time_dict_from_system()
	footprints = footprints.filter(func(fp): return current_time.get("second") - fp.get("timestamp", 0) < 3.0)
	
	# Handle decoy dropping
	if Input.is_action_just_pressed("drop_decoy") and decoys_remaining > 0:
		drop_decoy()

func drop_decoy():
	if decoys_remaining > 0:
		decoys_remaining -= 1
		decoy_dropped.emit(global_position)
		print("Decoy dropped at position: ", global_position)

func add_footprint():
	var footprint = {
		"position": global_position,
		"timestamp": Time.get_time_dict_from_system().get("second", 0)
	}
	footprints.append(footprint)
	if footprints.size() > 50:  # Limit footprint count
		footprints.pop_front()

func collect_coin(value: int, is_bonus: bool):
	coin_collected.emit(value, is_bonus)

func lose_life():
	lives -= 1
	life_lost.emit()
	if lives <= 0:
		print("Game Over - No lives remaining")
	else:
		print("Life lost. Lives remaining: ", lives)

func respawn(new_position: Vector2):
	global_position = new_position
	velocity = Vector2.ZERO
	start_grace_period(2.0)  # 2 second grace period after respawn

func reset_for_new_level():
	decoys_remaining = max_decoys
	footprints.clear()
	velocity = Vector2.ZERO

func get_footprint_data() -> Array[Dictionary]:
	return footprints

func add_decoy():
	decoys_remaining += 1
	decoys_remaining = min(decoys_remaining, max_decoys)
