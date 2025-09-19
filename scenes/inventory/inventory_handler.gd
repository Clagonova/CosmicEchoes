class_name InventoryHandler extends Node

@export var player: CharacterBody3D
@export_flags_3d_physics var collision_mask: int

@export var item_slots_count: int = 40

@export var inventory_grid: GridContainer
@export var inventory_slot_prefab: PackedScene = preload("uid://c152xf4ysp1y")

var inventory_slots: Array[InventorySlot] = []

var equipped_slot: int = -1


func _ready() -> void:
	for i in item_slots_count:
		var slot = inventory_slot_prefab.instantiate() as InventorySlot
		inventory_grid.add_child(slot)
		slot.inventory_slot_id = i
		slot.on_item_dropped.connect(item_dropped_on_slot.bind())
		slot.on_item_equipped.connect(item_equipped.bind())
		inventory_slots.append(slot)


func pickup_item(item: ItemData):
	var found_slot: bool = false
	for slot in inventory_slots:
		if (!slot.slot_filled):
			slot.fill_slot(item, false)
			found_slot = true
			break
	
	if (!found_slot):
		var new_item = item.item_model_prefab.instantiate() as Node3D
		
		player.get_parent().add_child(new_item)
		new_item.global_position = get_world_mouse_position()


func item_equipped(slot_id: int):
	if (equipped_slot != -1):
		inventory_slots[equipped_slot].fill_slot(inventory_slots[equipped_slot].slot_data, false)
	
	if (slot_id != equipped_slot and inventory_slots[slot_id].slot_data != null):
		inventory_slots[slot_id].fill_slot(inventory_slots[slot_id].slot_data, true)
		equipped_slot = slot_id
	else:
		equipped_slot = -1


func item_dropped_on_slot(from_slot_id: int, to_slot_id: int):
	if equipped_slot != -1:
		if equipped_slot == from_slot_id:
			equipped_slot = to_slot_id
		elif equipped_slot == to_slot_id:
			equipped_slot = from_slot_id
	
	var to_slot_item = inventory_slots[to_slot_id].slot_data
	var from_slot_item = inventory_slots[from_slot_id].slot_data
	
	inventory_slots[to_slot_id].fill_slot(from_slot_item, equipped_slot == to_slot_id)
	inventory_slots[from_slot_id].fill_slot(to_slot_item, equipped_slot == from_slot_id)


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data["Type"] == "Item"


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if (equipped_slot == data["ID"]):
		equipped_slot = -1
	
	var new_item = inventory_slots[data["ID"]].slot_data.item_model_prefab.instantiate() as Node3D
	inventory_slots[data["ID"]].fill_slot(null, false)
	
	player.get_parent().add_child(new_item)
	new_item.global_position = get_world_mouse_position()


func get_world_mouse_position() -> Vector3:
	var mouse_pos = get_viewport().get_mouse_position()
	var cam = get_viewport().get_camera_3d()
	var ray_start = cam.project_ray_origin(mouse_pos)
	var ray_dir = cam.project_ray_normal(mouse_pos)
	var ray_length = cam.global_position.distance_to(player.global_position) * 2.0
	var ray_end = ray_start + ray_dir * ray_length
	
	var world3d: World3D = player.get_world_3d()
	var space_state = world3d.direct_space_state
	
	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end, collision_mask)
	var results = space_state.intersect_ray(query)
	
	var floor_height = 0.2
	var wall_offset = 0.2
	
	if results:
		var pos = results["position"] as Vector3
		
		if results.has("normal"):
			var normal = results["normal"] as Vector3
			pos += normal * wall_offset
		
		pos.y += floor_height
		return pos
	else:
		return ray_start.lerp(ray_end, 0.5) + Vector3(0.0, floor_height, 0.0)
