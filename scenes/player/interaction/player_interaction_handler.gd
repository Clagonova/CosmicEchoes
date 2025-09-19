extends Area3D

signal on_item_picked_up(item)

@export var item_types: Array[ItemData] = []

var nearby_bodies: Array[InteractableItem]


func _input(event: InputEvent) -> void:
	if (event.is_action_pressed("interact")):
		pickup_nearest_item()

func pickup_nearest_item():
	var nearest_item: InteractableItem = null
	var nearest_item_distance: float = INF
	for item in nearby_bodies:
		if (item.global_position.distance_to(global_position) < nearest_item_distance):
			nearest_item_distance = item.global_position.distance_to(global_position)
			nearest_item = item
	
	if (nearest_item != null):
		nearest_item.queue_free()
		nearby_bodies.remove_at(nearby_bodies.find(nearest_item))
		var item_prefab: String = nearest_item.scene_file_path
		for i in item_types.size():
			if (item_types[i].item_model_prefab != null and item_types[i].item_model_prefab.resource_path == item_prefab):
				print("Item ID: " + str(i) + " Item Name: " + item_types[i].item_name)
				on_item_picked_up.emit(item_types[i])
				return
		
		printerr("Item not found!")

func on_object_entered_area(body: Node3D):
	if (body is InteractableItem):
		body.gain_focus()
		nearby_bodies.append(body) 

func on_object_exited_area(body: Node3D):
	if (body is InteractableItem and nearby_bodies.has(body)):
		body.lose_focus()
		nearby_bodies.remove_at(nearby_bodies.find(body))
