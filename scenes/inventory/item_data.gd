class_name ItemData extends Resource

#@export var item_id: String
@export var item_name: String
@export var icon: Texture2D
#@export_multiline var item_desc: String

@export var item_model_prefab: PackedScene

# Stack özellikleri
@export var max_stack_amount: int = 1 # Default: stacklenemez
var amount: int = 1 # O anki miktar
