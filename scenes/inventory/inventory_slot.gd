class_name InventorySlot extends Control

signal on_item_equipped(slot_id)
signal on_item_dropped(from_slot_id, to_slot_id)

@export var equipped_highlight: Panel
@export var icon_slot: TextureRect

var inventory_slot_id: int = -1
var slot_filled: bool = false

var slot_data: ItemData


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if (event.button_index == MOUSE_BUTTON_LEFT and event.double_click):
			on_item_equipped.emit(inventory_slot_id)

func fill_slot(data: ItemData, equipped: bool):
	slot_data = data
	equipped_highlight.visible = equipped
	if (slot_data != null):
		slot_filled = true
		icon_slot.texture = data.icon
		# amount_slot = data.amount
	else:
		slot_filled = false
		icon_slot.texture = null

func _get_drag_data(_at_position: Vector2) -> Variant:
	if (slot_filled):
		var preview: TextureRect = TextureRect.new()
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.size = icon_slot.size
		preview.pivot_offset = icon_slot.size / 2.0
		preview.rotation = -0.2
		preview.texture = icon_slot.texture
		set_drag_preview(preview)
		
		return {"Type": "Item", "ID": inventory_slot_id}
	else:
		return false

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data["Type"] == "Item"

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	on_item_dropped.emit(data["ID"], inventory_slot_id)
