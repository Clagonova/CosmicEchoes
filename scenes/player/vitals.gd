extends Node3D

const PlayerState = preload("res://scenes/player/player_states.gd").PlayerState

@onready var player: CharacterBody3D = $".."

signal oxygen_depleted
signal oxygen_low(new_value: float)

# --- Temel hayatta kalma değerleri
@export var max_health := 100.0
@export var max_hunger := 100.0
@export var max_fatigue := 100.0
@export var max_oxygen := 100.0

var health := max_health
var hunger := max_hunger
var fatigue := max_fatigue
var oxygen := max_oxygen

# Harcama oranları
@export var fatigue_idle_drain := 0.05
@export var fatigue_crouch_drain := 0.1
@export var fatigue_walk_drain := 0.15
@export var fatigue_run_drain := 0.5
@export var fatigue_jump_drain := 0.75
@export var oxygen_vacuum_drain := 0.1

# Decay/recovery
@export var hunger_decay_rate := 0.05
@export var fatigue_recovery_rate := 10.0
@export var oxygen_recovery_rate := 15.0

# Çalışma flagleri
var in_habitat := false  # gemi içi/planetary, oksijen değerleri olan alan
var oxygen_low_threshold := 0.15  # %15 altına düşerse "low" sinyali


func _process(delta):
	# Açlık
	hunger = max(hunger - hunger_decay_rate * delta, 0.0)

	# Sağlık düşürme (açlık veya susuzluk kritikse)
	if hunger <= 0.0:
		health = max(health - 5.0 * delta, 0.0)

	if player.state != PlayerState.ZEROG: #/if in_habitat:
		if oxygen < max_oxygen:
			oxygen = min(oxygen + oxygen_recovery_rate * delta, max_oxygen)
	else:
		if oxygen_vacuum_drain > 0.0:
			oxygen = max(oxygen - oxygen_vacuum_drain * delta, 0.0)

	# Oksijen bittiğinde sağlık azalabilir (isteğe göre ayarla)
	if oxygen <= 0.0:
		health = max(health - 10.0 * delta, 0.0)  # oksijen bittiğinde zarar

	# Basit fatigue recovery (örnek: durunca geri dolar)
	#if fatigue < max_fatigue:
	#	fatigue = min(fatigue + fatigue_recovery_rate * delta, max_fatigue)


# --- Fatigue / stamina API (senin mevcut fonksiyonları korudum)
func apply_fatigue_drain(state, delta):
	match state:
		PlayerState.WALKING:
			fatigue = max(fatigue - fatigue_walk_drain * delta, 0.0)
		PlayerState.RUNNING:
			fatigue = max(fatigue - fatigue_run_drain * delta, 0.0)
		PlayerState.CROUCHING:
			fatigue = max(fatigue - fatigue_crouch_drain * delta, 0.0)
		PlayerState.JUMPING:
			fatigue = max(fatigue - fatigue_jump_drain * delta, 0.0)
		_:
			pass

func get_health() -> float:
	return health
func get_hunger() -> float:
	return hunger
func get_fatigue() -> float:
	return fatigue
func get_oxygen() -> float:
	return oxygen

func damage_health(amount: float, delta):
	health = max(health - amount * delta, 0.0)

func consume_food(amount: float):
	hunger = min(hunger + amount, max_hunger)

func use_fatigue(amount: float):
	fatigue = max(fatigue - amount, 0.0)

# --- Oksijen API ---
# amount: miktar (ör. thruster_oxygen_rate * delta)
# döndürür: gerçekte kullanılan miktar (böylece Player kalan miktarı biliyor)
func use_oxygen(amount: float) -> float:
	if amount <= 0.0:
		return 0.0
	var used = min(amount, oxygen)
	oxygen -= used
	# sinyaller
	if oxygen <= 0.0:
		oxygen = 0.0
		emit_signal("oxygen_depleted")
	elif oxygen / max_oxygen <= oxygen_low_threshold:
		emit_signal("oxygen_low", oxygen)
	return used

func can_consume_oxygen(amount: float) -> bool:
	return oxygen >= amount

func refill_oxygen(amount: float):
	oxygen = min(oxygen + amount, max_oxygen)

func set_in_habitat(enabled: bool):
	in_habitat = enabled


func _input(event):
	# Fill health
	if event.is_action_pressed("debug_fill_health"):
		health = min(health + 100, max_health)
		print("Cheat: Health Filled.")
	# Fill hunger
	if event.is_action_pressed("debug_fill_hunger"):
		hunger = min(hunger + 100, max_hunger)
		print("Cheat: Hunger Filled.")
	# Fill fatigue
	if event.is_action_pressed("debug_fill_fatigue"):
		fatigue = min(fatigue + 100, max_fatigue)
		print("Cheat: Fatigue Filled.")
	# Fill oxygen
	if event.is_action_pressed("debug_fill_oxygen"):
		oxygen = min(oxygen + 100, max_oxygen)
		print("Cheat: Oxygen Filled.")
