@tool
extends Area3D

signal entered_gravity_zone(player)
signal exited_gravity_zone(player)

@export var collision_size: Vector3 = Vector3.ONE:
	set(value):
		collision_size = value
		_update_collision_shape()

@export var sphere_radius := 0.1:
	set(value):
		sphere_radius = value
		_update_spheres()

@onready var collision_shape = $CollisionShape3D
@onready var sphere_in = $SphereIn
@onready var sphere_out = $SphereOut

func _ready():
	if not Engine.is_editor_hint():
		connect("body_entered", Callable(self, "_on_body_entered"))
	_update_spheres()

func _on_body_entered(body: Node):
	if not body.is_in_group("player"):
		return

	var forward = global_transform.basis.z.normalized()
	var to_player = (body.global_transform.origin - global_transform.origin).normalized()
	var dot = forward.dot(to_player)

	if dot > 0:
		emit_signal("exited_gravity_zone", body)  # içeriden çıkış
	else:
		emit_signal("entered_gravity_zone", body) # dışarıdan giriş

func _update_collision_shape():
	if not collision_shape:
		return
	if collision_shape.shape is BoxShape3D:
		collision_shape.shape.size = collision_size
	elif collision_shape.shape is CapsuleShape3D:
		collision_shape.shape.radius = collision_size.x * 0.5
		collision_shape.shape.height = collision_size.y
	elif collision_shape.shape is SphereShape3D:
		collision_shape.shape.radius = collision_size.x * 0.5

func _update_spheres():
	if not is_inside_tree():
		return
	
	# Materyal ayarı
	var mat_in = StandardMaterial3D.new()
	mat_in.albedo_color = Color(0, 1, 0, 0.3) # yeşil, %30 opak
	mat_in.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_in.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var mat_out = StandardMaterial3D.new()
	mat_out.albedo_color = Color(1, 0, 0, 0.3) # kırmızı, %30 opak
	mat_out.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_out.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	# SphereIn
	if sphere_in and sphere_in is MeshInstance3D:
		var mesh = SphereMesh.new()
		mesh.radius = sphere_radius
		mesh.height = sphere_radius * 2.0
		mesh.radial_segments = 16
		mesh.rings = 8
		sphere_in.mesh = mesh
		sphere_in.material_override = mat_in
		sphere_in.transform = Transform3D(Basis(), Vector3(0, 0, sphere_radius * 3.5))

	# SphereOut
	if sphere_out and sphere_out is MeshInstance3D:
		var mesh = SphereMesh.new()
		mesh.radius = sphere_radius
		mesh.height = sphere_radius * 2.0
		mesh.radial_segments = 16
		mesh.rings = 8
		sphere_out.mesh = mesh
		sphere_out.material_override = mat_out
		sphere_out.transform = Transform3D(Basis(), Vector3(0, 0, -sphere_radius * 3.5))
