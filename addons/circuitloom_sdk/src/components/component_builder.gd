class_name ComponentBuilder
extends RefCounted

## Shared helpers for assembling placeholder ("low-poly") 3D components out of
## Godot's built-in primitive meshes only — no external mesh/texture assets,
## so instantiating a component can never hit a missing resource reference.


static func add_box(
	parent: Node3D, size: Vector3, position: Vector3, color: Color, part_name: String
) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _add(parent, mesh, position, color, part_name)


static func add_cylinder(
	parent: Node3D,
	radius: float,
	height: float,
	position: Vector3,
	color: Color,
	part_name: String,
	top_radius: float = -1.0
) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = radius
	mesh.top_radius = radius if top_radius < 0.0 else top_radius
	mesh.height = height
	return _add(parent, mesh, position, color, part_name)


static func add_sphere(
	parent: Node3D, radius: float, position: Vector3, color: Color, part_name: String
) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	return _add(parent, mesh, position, color, part_name)


static func _add(
	parent: Node3D, mesh: Mesh, position: Vector3, color: Color, part_name: String
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = part_name
	instance.mesh = mesh
	instance.position = position

	var material := StandardMaterial3D.new()
	material.albedo_color = color
	instance.material_override = material

	parent.add_child(instance)
	return instance
