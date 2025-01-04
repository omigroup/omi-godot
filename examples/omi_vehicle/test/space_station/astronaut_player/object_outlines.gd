extends Node


const _CURVE_PRECISION = 32
const _RING_PRECISION = _CURVE_PRECISION * 2
const _OUTLINE_MATERIAL = preload("outline_material.mat.tres")

@onready var _wireframe_box: ArrayMesh = _create_wireframe_box()


func _process(_delta: float) -> void:
	for child in get_children():
		child.queue_free()


func draw_wireframe_box(col_shape_node: CollisionShape3D, color: Color) -> void:
	var box_size: Vector3 = col_shape_node.shape.size
	var mesh_instance: MeshInstance3D = _create_mesh_instance_for_mesh(_wireframe_box, color)
	mesh_instance.transform = col_shape_node.global_transform.translated_local(box_size * -0.5).scaled_local(box_size)


func _create_mesh_instance_for_mesh(mesh: Mesh, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _OUTLINE_MATERIAL
	mesh_instance.set_instance_shader_parameter("albedo", color)
	mesh_instance.set_instance_shader_parameter("albedo_depth", Color.from_hsv(color.h + 0.25, color.s - 0.1, color.v - 0.5))
	add_child(mesh_instance)
	return mesh_instance


func _create_wireframe_box() -> ArrayMesh:
	var positions := PackedVector3Array([
		Vector3(0, 0, 0),
		Vector3(1, 0, 0),
		Vector3(1, 0, 1),
		Vector3(0, 0, 1),
		Vector3(0, 1, 0),
		Vector3(1, 1, 0),
		Vector3(1, 1, 1),
		Vector3(0, 1, 1)
	])
	var indices := PackedInt32Array([
		0, 1, 1, 2, 2, 3, 3, 0,
		4, 5, 5, 6, 6, 7, 7, 4,
		0, 4, 1, 5, 2, 6, 3, 7
	])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = positions
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	return mesh
