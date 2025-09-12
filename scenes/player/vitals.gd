extends Node3D

const PlayerState = preload("res://scenes/player/player_states.gd").PlayerState

# Temel hayatta kalma değerleri
@export var max_health := 100.0
@export var max_hunger := 100.0
@export var max_thirst := 100.0
@export var max_fatigue := 100.0

var health := max_health
var hunger := max_hunger
var thirst := max_thirst
var fatigue := max_fatigue

# Harcama oranları
@export var fatigue_idle_drain := 0.1
@export var fatigue_walk_drain := 0.3
@export var fatigue_run_drain := 1.0
@export var fatigue_jump_drain := 1.3
@export var fatigue_crouch_drain := 0.25

# Değer değişim hızları (her saniye)
@export var hunger_decay_rate := 0.5
@export var thirst_decay_rate := 0.7
@export var fatigue_recovery_rate := 10

# Durum güncellemesi
func _process(delta):
	# Açlık ve susuzluk azalışı
	hunger = max(hunger - hunger_decay_rate * delta, 0)
	thirst = max(thirst - thirst_decay_rate * delta, 0)
	
	# Eğer açlık veya susuzluk sıfırsa sağlığı azalt
	if hunger <= 0 or thirst <= 0:
		health = max(health - 5.0 * delta, 0)

func apply_fatigue_drain(state, delta):
	match state:
		PlayerState.WALKING:
			fatigue = max(fatigue - fatigue_walk_drain * delta, 0)
		PlayerState.RUNNING:
			fatigue = max(fatigue - fatigue_run_drain * delta, 0)
		PlayerState.CROUCHING:
			fatigue = max(fatigue - fatigue_crouch_drain * delta, 0)
		PlayerState.JUMPING:
			fatigue = max(fatigue - fatigue_jump_drain * delta, 0)
		_:
			pass

# Genel değerleri diğer node’lara ya da UI’ya çekmek için getterler
func get_health() -> float:
	return health

func get_hunger() -> float:
	return hunger

func get_thirst() -> float:
	return thirst

func get_fatigue() -> float:
	return fatigue

# Player hareketinden veya olaylardan tetiklenen değişiklikler
func consume_food(amount: float):
	hunger = min(hunger + amount, max_hunger)

func drink(amount: float):
	thirst = min(thirst + amount, max_thirst)

func use_fatigue(amount: float):
	fatigue = max(fatigue - amount, 0)

func _input(event):
	# Fill health
	if event.is_action_pressed("debug_fill_health"):
		health = min(health + 100, max_health)
		print("Debug: Fatigue += 100, current =", health)
	# Fill hunger
	if event.is_action_pressed("debug_fill_hunger"):
		hunger = min(hunger + 100, max_hunger)
		print("Debug: Fatigue += 100, current =", hunger)
	# Fill thirst
	if event.is_action_pressed("debug_fill_thirst"):
		thirst = min(thirst + 100, max_thirst)
		print("Debug: Fatigue += 100, current =", thirst)
	# Fill fatigue
	if event.is_action_pressed("debug_fill_fatigue"):
		fatigue = min(fatigue + 100, max_fatigue)
		print("Debug: Fatigue += 100, current =", fatigue)
