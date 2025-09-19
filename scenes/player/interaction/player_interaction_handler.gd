# player_interaction_handler.gd

extends Node3D

signal on_item_picked_up(item)

@export var item_types: Array[ItemData] = []

@onready var raycast: RayCast3D = %RayCast3D

var focused_item: InteractableItem = null


func _process(_delta: float) -> void:
	update_focused_item()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		pickup_item_in_front()


func update_focused_item():
	var hit_item: InteractableItem = null

	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider is InteractableItem:
			hit_item = collider

	# Odak değişmişse güncelle
	if hit_item != focused_item:
		if focused_item != null:
			focused_item.lose_focus()
		if hit_item != null:
			hit_item.gain_focus()
		focused_item = hit_item


func pickup_item_in_front():
	if focused_item == null:
		return

	var item_prefab: String = focused_item.scene_file_path
	focused_item.queue_free()

	for i in item_types.size():
		if (item_types[i].item_model_prefab != null 
		and item_types[i].item_model_prefab.resource_path == item_prefab):
			print("Item ID: " + str(i) + " Item Name: " + item_types[i].item_name)
			on_item_picked_up.emit(item_types[i])
			focused_item = null
			return

	printerr("Item not found!")
	focused_item = null
