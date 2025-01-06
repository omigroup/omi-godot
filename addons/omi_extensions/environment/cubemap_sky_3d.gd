@tool
class_name CubemapSky3D
extends MeshInstance3D


const S = 10 # Size of the skybox mesh.

static var quad_uv := PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(0, 1), Vector2(1, 0), Vector2(1, 1)])


func _init() -> void:
	var array_mesh := ArrayMesh.new()
	var surface_array: Array = [
		PackedVector3Array([Vector3(S, S, -S), Vector3(S, S, S), Vector3(S, -S, -S), Vector3(S, -S, -S), Vector3(S, S, S), Vector3(S, -S, S)]),
		null, # ARRAY_NORMAL
		null, # ARRAY_TANGENT
		null, # ARRAY_COLOR
		quad_uv, # ARRAY_TEX_UV
		null, # ARRAY_TEX_UV2
		null, # ARRAY_CUSTOM0
		null, # ARRAY_CUSTOM1
		null, # ARRAY_CUSTOM2
		null, # ARRAY_CUSTOM3
		null, # ARRAY_BONES
		null, # ARRAY_WEIGHTS
		null, # ARRAY_INDEX
	]
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	surface_array[0] = PackedVector3Array([Vector3(-S, S, S), Vector3(-S, S, -S), Vector3(-S, -S, S), Vector3(-S, -S, S), Vector3(-S, S, -S), Vector3(-S, -S, -S)])
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	surface_array[0] = PackedVector3Array([Vector3(S, S, -S), Vector3(-S, S, -S), Vector3(S, S, S), Vector3(S, S, S), Vector3(-S, S, -S), Vector3(-S, S, S)])
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	surface_array[0] = PackedVector3Array([Vector3(S, -S, S), Vector3(-S, -S, S), Vector3(S, -S, -S), Vector3(S, -S, -S), Vector3(-S, -S, S), Vector3(-S, -S, -S)])
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	surface_array[0] = PackedVector3Array([Vector3(S, S, S), Vector3(-S, S, S), Vector3(S, -S, S), Vector3(S, -S, S), Vector3(-S, S, S), Vector3(-S, -S, S)])
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	surface_array[0] = PackedVector3Array([Vector3(-S, S, -S), Vector3(S, S, -S), Vector3(-S, -S, -S), Vector3(-S, -S, -S), Vector3(S, S, -S), Vector3(S, -S, -S)])
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	# Set up the materials.
	var unlit := StandardMaterial3D.new()
	unlit.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	array_mesh.surface_set_material(0, unlit.duplicate())
	array_mesh.surface_set_material(1, unlit.duplicate())
	array_mesh.surface_set_material(2, unlit.duplicate())
	array_mesh.surface_set_material(3, unlit.duplicate())
	array_mesh.surface_set_material(4, unlit.duplicate())
	array_mesh.surface_set_material(5, unlit.duplicate())
	# Set the surface names.
	array_mesh.surface_set_name(0, "+X")
	array_mesh.surface_set_name(1, "-X")
	array_mesh.surface_set_name(2, "+Y")
	array_mesh.surface_set_name(3, "-Y")
	array_mesh.surface_set_name(4, "+Z")
	array_mesh.surface_set_name(5, "-Z")
	mesh = array_mesh
	sorting_offset = -1000000000000000.0


func _process(_delta: float) -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	#print(camera)
	if camera:
		global_position = camera.global_position


func set_skybox_textures(textures: Array[Texture2D]) -> void:
	for i in range(textures.size()):
		var mat: StandardMaterial3D = mesh.surface_get_material(i)
		if mat:
			mat.albedo_texture = textures[i].duplicate(true)
			mesh.surface_set_material(i, mat)
