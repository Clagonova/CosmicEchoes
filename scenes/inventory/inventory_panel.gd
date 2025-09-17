extends Panel

@onready var inventory_hud: CanvasLayer = $".."


# Hides the forbidden version of the mouse cursor
func _process(_delta: float) -> void:
	if Input.get_current_cursor_shape() == CURSOR_FORBIDDEN:
		DisplayServer.cursor_set_shape(DisplayServer.CURSOR_ARROW)

var data_bk
func _notification(what: int) -> void:
	if what == Node.NOTIFICATION_DRAG_BEGIN:
		data_bk = get_viewport().gui_get_drag_data()
	
	if what == Node.NOTIFICATION_DRAG_END:
		if not is_drag_successful():
			if data_bk:
				data_bk.icon.show()
				data_bk = null

func _input(event):
	if event.is_action_pressed("inventory"):
		toggle_inventory_hud()

func toggle_inventory_hud() -> void:
	inventory_hud.visible = not inventory_hud.visible
	
	if inventory_hud.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
