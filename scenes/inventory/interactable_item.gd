class_name InteractableItem extends Node3D

@export var ItemHighlightMesh: MeshInstance3D

func gain_focus():
	ItemHighlightMesh.visible = true

func lose_focus():
	ItemHighlightMesh.visible = false
