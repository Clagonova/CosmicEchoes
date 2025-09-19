class_name InventorySlot extends Control

signal on_item_equipped(slot_id)
signal on_item_dropped(from_slot_id, to_slot_id)

@export var equipped_highlight: Panel
@export var icon_slot: TextureRect
@export var amount_label: Label

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
		tooltip_text = data.item_name
		if amount_label:
			amount_label.text = str(data.amount)
			amount_label.visible = data.max_stack_amount > 1
	else:
		slot_filled = false
		icon_slot.texture = null
		tooltip_text = ""
		if amount_label:
			amount_label.text = ""
			amount_label.visible = false

func _get_drag_data(_at_position: Vector2) -> Variant:
	if slot_filled:
		var drag_amount = slot_data.amount
		var input = Input
		if slot_data.max_stack_amount > 1 and slot_data.amount > 1:
			if input.is_key_pressed(KEY_CTRL):
				drag_amount = 1
			elif input.is_key_pressed(KEY_SHIFT):
				drag_amount = int(slot_data.amount / 2)
				if drag_amount < 1:
					drag_amount = 1

		# Create drag preview with amount label
		var preview = Control.new()
		preview.size = icon_slot.size

		var icon = TextureRect.new()
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.size = icon_slot.size
		icon.pivot_offset = icon_slot.size / 2.0
		icon.rotation = -0.2
		icon.texture = icon_slot.texture
		preview.add_child(icon)

		if drag_amount > 1:
			var drag_amount_label = Label.new()
			drag_amount_label.text = str(drag_amount)
			drag_amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			drag_amount_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			drag_amount_label.add_theme_color_override("font_color", Color(1,1,1))
			drag_amount_label.add_theme_color_override("font_outline_color", Color(0,0,0))
			drag_amount_label.add_theme_constant_override("outline_size", 3)
			var font_file: FontFile = load("res://assets/fonts/Terminal F4.ttf")
			drag_amount_label.add_theme_font_size_override("font_size", 12)
			drag_amount_label.add_theme_font_override("font", font_file)
			drag_amount_label.position = Vector2(icon.size.x - 10, icon.size.y - 14)
			preview.add_child(drag_amount_label)

		set_drag_preview(preview)
		return {"Type": "Item", "ID": inventory_slot_id, "Amount": drag_amount}
	else:
		return false

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data["Type"] == "Item"

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var amount = 1
	if data.has("Amount"):
		amount = data["Amount"]
	on_item_dropped.emit(data["ID"], inventory_slot_id, amount)
