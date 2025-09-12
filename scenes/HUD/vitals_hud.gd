extends CanvasLayer

@export var vitals_path: NodePath
var vitals

@onready var health_bar: ProgressBar = %HealthBar
@onready var hunger_bar: ProgressBar = %HungerBar
@onready var thirst_bar: ProgressBar = %ThirstBar
@onready var fatigue_bar: ProgressBar = %FatigueBar
@onready var oxygen_bar: ProgressBar = %OxygenBar

func _ready():
	if vitals_path != null:
		var player_node = get_node(vitals_path)
		# Player sahnesinin içindeki Vitals node'una erişiyoruz
		vitals = player_node.get_node("Vitals")

func _process(_delta):
	if vitals == null:
		return

	# Değerleri güncelle
	health_bar.value = vitals.get_health()
	hunger_bar.value = vitals.get_hunger()
	thirst_bar.value = vitals.get_thirst()
	fatigue_bar.value = vitals.get_fatigue()
	oxygen_bar.value = vitals.get_oxygen()
