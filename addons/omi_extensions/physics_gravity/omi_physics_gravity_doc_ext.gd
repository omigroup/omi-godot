@tool
class_name GLTFDocumentExtensionOMIPhysicsGravity
extends GLTFDocumentExtension


## Writes the project's global gravity into the document-level glTF extension.
@export var write_global_gravity: bool = false:
	set(value):
		write_global_gravity = value
		notify_property_list_changed()

var global_gravity_direction := Vector3.DOWN
var global_gravity_amount: float = 9.80665


# Import process.
func _import_preflight(gltf_state: GLTFState, extensions: PackedStringArray) -> Error:
	if not extensions.has("OMI_physics_gravity"):
		return ERR_SKIP
	var state_json = gltf_state.get_json()
	if not state_json.has("extensions"):
		return OK
	var state_extensions: Dictionary = state_json["extensions"]
	if not state_extensions.has("OMI_physics_gravity"):
		return OK
	# If this point is reached, the gravity extension is defined on
	# the document-level, which means the GLTF defines global gravity.
	var omi_physics_gravity_doc_ext: Dictionary = state_extensions["OMI_physics_gravity"]
	gltf_state.set_additional_data("GLTFPhysicsGlobalGravity", omi_physics_gravity_doc_ext)
	return OK


func _get_supported_extensions() -> PackedStringArray:
	return PackedStringArray(["OMI_physics_gravity"])


func _parse_node_extensions(gltf_state: GLTFState, gltf_node: GLTFNode, extensions: Dictionary) -> Error:
	if extensions.has("OMI_physics_gravity"):
		var omi_gravity_ext = extensions["OMI_physics_gravity"]
		gltf_node.set_additional_data("GLTFPhysicsGravity", omi_gravity_ext)
	return OK


func _generate_scene_node(gltf_state: GLTFState, gltf_node: GLTFNode, scene_parent: Node) -> Node3D:
	var gravity_dict = gltf_node.get_additional_data("GLTFPhysicsGravity")
	if gravity_dict is Dictionary and not gravity_dict.is_empty():
		var custom_grav := CustomGravityArea3D.from_dictionary(gravity_dict, gltf_state)
		if custom_grav != null:
			var trigger_shape = gltf_node.get_additional_data("GLTFPhysicsTriggerShape")
			if trigger_shape is GLTFPhysicsShape:
				var shape_node: CollisionShape3D = trigger_shape.to_node(true)
				shape_node.name = gltf_node.get_name() + "Shape"
				custom_grav.add_child(shape_node)
		return custom_grav
	return null


func _import_post(gltf_state: GLTFState, root: Node) -> Error:
	var global_gravity_dict = gltf_state.get_additional_data("GLTFPhysicsGlobalGravity")
	if global_gravity_dict is Dictionary:
		var setter_node := GlobalGravitySetter.new()
		var direction = global_gravity_dict.get("direction")
		if direction is Array:
			setter_node.direction = Vector3(direction[0], direction[1], direction[2])
		var gravity = global_gravity_dict.get("gravity")
		if gravity is float:
			setter_node.gravity = gravity
		setter_node.name = &"GlobalGravitySetter"
		root.add_child(setter_node)
		setter_node.owner = root
	return OK


# Export process.
func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []
	if write_global_gravity:
		properties.append({
			"name": "global_gravity_direction",
			"type": TYPE_VECTOR3,
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_SCRIPT_VARIABLE,
		})
		properties.append({
			"name": "global_gravity_amount",
			"type": TYPE_FLOAT,
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_SCRIPT_VARIABLE,
		})
	return properties


func _export_preflight(gltf_state: GLTFState, root: Node) -> Error:
	if not write_global_gravity:
		return OK
	var extensions: Dictionary = gltf_state.json.get_or_add("extensions", {})
	var world_space_rid: RID = root.get_viewport().find_world_3d().space
	var omi_gravity_doc_ext: Dictionary = {}
	if not global_gravity_direction.is_equal_approx(Vector3.DOWN):
		omi_gravity_doc_ext["direction"] = [global_gravity_direction.x, global_gravity_direction.y, global_gravity_direction.z]
	omi_gravity_doc_ext["gravity"] = global_gravity_amount
	extensions["OMI_physics_gravity"] = omi_gravity_doc_ext
	gltf_state.add_used_extension("OMI_physics_gravity", false)
	return OK


func _convert_scene_node(gltf_state: GLTFState, gltf_node: GLTFNode, scene_node: Node) -> void:
	if scene_node is CustomGravityArea3D:
		var dict: Dictionary = scene_node.to_dictionary(gltf_state)
		if not dict.is_empty():
			gltf_node.set_additional_data("GLTFPhysicsGravity", dict)
	elif scene_node is Area3D and scene_node.gravity_space_override != Area3D.SPACE_OVERRIDE_DISABLED:
		var dict: Dictionary = CustomGravityArea3D.area_gravity_to_dictionary(scene_node)
		if not dict.is_empty():
			gltf_node.set_additional_data("GLTFPhysicsGravity", dict)


func _export_node(gltf_state: GLTFState, gltf_node: GLTFNode, json: Dictionary, node: Node) -> Error:
	var gravity_dict = gltf_node.get_additional_data("GLTFPhysicsGravity")
	if gravity_dict is Dictionary:
		var ext: Dictionary = json.get_or_add("extensions", {})
		ext["OMI_physics_gravity"] = gravity_dict
		gltf_state.add_used_extension("OMI_physics_gravity", false)
	return OK
