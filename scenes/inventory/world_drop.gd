extends Control

const WORLD_ITEM = preload("uid://j1l4fgu1nq8q")

@onready var player: CharacterBody3D = $"../../Player"


func _can_drop_data(_at_position: Vector2, _data: Variant) -> bool:
	return true

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var node = WORLD_ITEM.instantiate()
	
	node.set_meta("item_data", data.item)
	node.get_node("MeshInstance3D").mesh = data.item.mesh
	
	get_tree().current_scene.add_child(node)
	data.item = null
	if player.camera:
		var mouse_pos = get_viewport().get_mouse_position()
		
		var from = player.camera.project_ray_origin(mouse_pos)
		var to = from + player.camera.project_ray_normal(mouse_pos) * 3.0
		
		# Burada world_3d'yi kameradan alıyoruz
		var space_state = player.camera.get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(from, to)
		var result = space_state.intersect_ray(query)
		
		if result.size() > 0:
			node.global_position = result.position
			node.global_position.y += .5
		else:
			node.global_position = to
