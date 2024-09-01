@tool
class_name GLTFDocumentExtensionOMIPhysicsJoint
extends GLTFDocumentExtension


# Import process.
func _import_preflight(state: GLTFState, extensions: PackedStringArray) -> Error:
	if not extensions.has("OMI_physics_joint"):
		return ERR_SKIP
	var state_json = state.get_json()
	if not state_json.has("extensions"):
		return ERR_FILE_CORRUPT
	var state_extensions: Dictionary = state_json["extensions"]
	if not state_extensions.has("OMI_physics_joint"):
		return ERR_FILE_CORRUPT
	var omi_physics_joint_doc_ext: Dictionary = state_extensions["OMI_physics_joint"]
	if omi_physics_joint_doc_ext.has("physicsJoints"):
		var state_joint_settings_dicts: Array = omi_physics_joint_doc_ext["physicsJoints"]
		var state_joint_settings: Array[GLTFPhysicsJointSettings] = []
		for joint_settings_dict in state_joint_settings_dicts:
			state_joint_settings.append(GLTFPhysicsJointSettings.from_dictionary(joint_settings_dict))
		state.set_additional_data("GLTFPhysicsJointSettings", state_joint_settings)
	elif omi_physics_joint_doc_ext.has("constraints"):
		var state_constraint_dicts: Array = omi_physics_joint_doc_ext["constraints"]
		var state_constraints: Array[GLTFPhysicsJointConstraint] = []
		for constraint_dict in state_constraint_dicts:
			state_constraints.append(GLTFPhysicsJointConstraint.from_dictionary(constraint_dict))
		state.set_additional_data("GLTFPhysicsJointConstraints", state_constraints)
	else:
		return ERR_FILE_CORRUPT
	return OK


func _get_supported_extensions() -> PackedStringArray:
	return PackedStringArray(["OMI_physics_joint"])


func _parse_node_extensions(state: GLTFState, gltf_node: GLTFNode, extensions: Dictionary) -> Error:
	if not extensions.has("OMI_physics_joint"):
		return OK
	var joint_node_dict = extensions.get("OMI_physics_joint")
	if not joint_node_dict is Dictionary:
		printerr("Error: OMI_physics_joint extension should be a Dictionary.")
		return ERR_FILE_CORRUPT
	if joint_node_dict.has("constraints"):
		# Old code in this if statement.
		var constraints = joint_node_dict.get("constraints")
		if not constraints is Array or constraints.is_empty():
			printerr("Error: OMI_physics_joint extension should have at least one constraint.")
			return ERR_FILE_CORRUPT
		var state_constraints: Array = state.get_additional_data("GLTFPhysicsJointConstraints")
		var joint := GLTFPhysicsJointOld.new()
		for constraint in constraints:
			var joint_constraint: GLTFPhysicsJointConstraint
			if constraint is float: # Remember, JSON only stores "number".
				joint_constraint = state_constraints[int(constraint)]
			else:
				joint_constraint = GLTFPhysicsJointConstraint.from_dictionary(constraint)
			joint.apply_constraint(joint_constraint)
		gltf_node.set_additional_data("GLTFPhysicsJointOld", joint)
		return OK
	var joint_node := GLTFPhysicsJointNode.from_dictionary(joint_node_dict)
	if joint_node.joint_settings_index == -1:
		printerr("Error: OMI_physics_joint node does not have any joint settings.")
	else:
		var state_joint_settings: Array[GLTFPhysicsJointSettings] = state.get_additional_data("GLTFPhysicsJointSettings")
		joint_node.joint_settings_data = state_joint_settings[joint_node.joint_settings_index]
	gltf_node.set_additional_data("GLTFPhysicsJointNode", joint_node)
	return OK


func _generate_scene_node(state: GLTFState, gltf_node: GLTFNode, scene_parent: Node) -> Node3D:
	var joint_node: GLTFPhysicsJointNode = gltf_node.get_additional_data("GLTFPhysicsJointNode")
	if joint_node != null:
		var godot_node: Joint3D = joint_node.to_node()
		if not scene_parent is PhysicsBody3D:
			while scene_parent is Node3D and not scene_parent is PhysicsBody3D:
				scene_parent = scene_parent.get_parent()
			if scene_parent is PhysicsBody3D:
				godot_node.node_a = godot_node.get_path_to(scene_parent)
			else:
				printerr("Error: OMI_physics_joint node should be a descendant of a non-trigger physics body node (Godot PhysicsBody3D node).")
		return godot_node
	var joint_old: GLTFPhysicsJointOld = gltf_node.get_additional_data("GLTFPhysicsJointOld")
	if joint_old != null:
		return joint_old.to_node()
	return null


func _import_node(state: GLTFState, gltf_node: GLTFNode, json: Dictionary, node: Node) -> Error:
	var joint_node: GLTFPhysicsJointNode = gltf_node.get_additional_data("GLTFPhysicsJointNode")
	if joint_node != null:
		if not node is Joint3D:
			printerr("Error: OMI_physics_joint node should be a Joint3D.")
			return ERR_FILE_CORRUPT
		if joint_node.connected_node_index != -1:
			var connected_node: Node = state.get_scene_node(joint_node.connected_node_index)
			while connected_node is Node3D and not connected_node is PhysicsBody3D:
				connected_node = connected_node.get_parent()
			if not connected_node is PhysicsBody3D:
				printerr("Error: OMI_physics_joint node does not have a physics body ancestor. Godot only supports joints between physics bodies.")
				return ERR_FILE_CORRUPT
			node.node_b = node.get_path_to(connected_node)
		return OK
	# Old code below.
	if not json.has("extensions"):
		return OK
	var extensions = json.get("extensions")
	if not extensions.has("OMI_physics_joint"):
		return OK
	var joint_dict = extensions.get("OMI_physics_joint")
	if not joint_dict is Dictionary:
		printerr("Error: OMI_physics_joint extension should be a Dictionary.")
		return ERR_FILE_CORRUPT
	if not joint_dict.has("nodeA") or not joint_dict.has("nodeB"):
		printerr("Error: OMI_physics_joint extension should have nodeA and nodeB.")
		return ERR_FILE_CORRUPT
	var godot_joint_node: Joint3D = node as Joint3D
	var node_a_index: int = int(joint_dict["nodeA"])
	if node_a_index != -1:
		var node_a: Node = state.get_scene_node(node_a_index)
		if not node_a is PhysicsBody3D:
			printerr("Error: OMI_physics_joint nodeA should be a physics body (non-trigger).")
			return ERR_FILE_CORRUPT
		godot_joint_node.node_a = godot_joint_node.get_path_to(node_a)
	var node_b_index: int = int(joint_dict["nodeB"])
	if node_b_index != -1:
		var node_b: Node = state.get_scene_node(node_b_index)
		if not node_b is PhysicsBody3D:
			printerr("Error: OMI_physics_joint nodeB should be a physics body (non-trigger).")
			return ERR_FILE_CORRUPT
		godot_joint_node.node_b = godot_joint_node.get_path_to(node_b)
	return OK


# Export process.
func _get_or_create_state_joint_settings_in_state(state: GLTFState) -> Array:
	var state_json = state.get_json()
	var state_extensions: Dictionary
	if state_json.has("extensions"):
		state_extensions = state_json["extensions"]
	else:
		state_extensions = {}
		state_json["extensions"] = state_extensions
	var omi_physics_joint_doc_ext: Dictionary
	if state_extensions.has("OMI_physics_joint"):
		omi_physics_joint_doc_ext = state_extensions["OMI_physics_joint"]
	else:
		omi_physics_joint_doc_ext = {}
		state_extensions["OMI_physics_joint"] = omi_physics_joint_doc_ext
		state.add_used_extension("OMI_physics_joint", false)
	var state_joint_settings_dicts: Array
	if omi_physics_joint_doc_ext.has("physicsJoints"):
		state_joint_settings_dicts = omi_physics_joint_doc_ext["physicsJoints"]
	else:
		state_joint_settings_dicts = []
		omi_physics_joint_doc_ext["physicsJoints"] = state_joint_settings_dicts
	return state_joint_settings_dicts


func _get_or_insert_joint_settings_in_state(state: GLTFState, joint_settings: GLTFPhysicsJointSettings) -> int:
	var state_joint_settings: Array = _get_or_create_state_joint_settings_in_state(state)
	var size: int = state_joint_settings.size()
	var joint_settings_dict: Dictionary = joint_settings.to_dictionary()
	for i in range(size):
		var other: Dictionary = state_joint_settings[i]
		if other == joint_settings_dict:
			# De-duplication: If we already have identical joint settings,
			# return the index of the existing joint settings.
			return i
	# If we don't have identical joint settings, add it to the array.
	state_joint_settings.push_back(joint_settings_dict)
	return size


func _get_ancestor_physics_body(node: Node) -> PhysicsBody3D:
	while node is Node3D:
		if node is PhysicsBody3D:
			return node
		node = node.get_parent()
	return null


func _get_connected_node_if_any(node: Node, target_global_transform: Transform3D) -> Node:
	if node is Node3D and node.global_transform.is_equal_approx(target_global_transform):
		return node
	for child in node.get_children():
		var found = _get_connected_node_if_any(child, target_global_transform)
		if found:
			return found
	return null


func _convert_scene_node(state: GLTFState, gltf_node: GLTFNode, scene_node: Node) -> void:
	if not scene_node is Joint3D:
		return
	var joint_node := GLTFPhysicsJointNode.from_node(scene_node)
	joint_node.joint_settings_index = _get_or_insert_joint_settings_in_state(state, joint_node.joint_settings_data)
	# The joint needs to be a descendant of one of the physics bodies. Is it? If not, we need to make a new glTF node.
	var ancestor_body: PhysicsBody3D = _get_ancestor_physics_body(scene_node)
	var node_at_a: Node = scene_node.get_node(scene_node.node_a)
	var node_at_b: Node = scene_node.get_node(scene_node.node_b)
	if node_at_a == null:
		if node_at_b == null:
			printerr("glTF Physics Joint: Cannot export a joint that is not connected to anything.")
			return
		node_at_a = node_at_b
	if node_at_b == ancestor_body:
		# Uncommon case, B is the ancestor and A is the attached node.
		# Just swap them so that A is the ancestor in the below code.
		node_at_b = node_at_a
		node_at_a = ancestor_body
	elif node_at_a != ancestor_body:
		# The joint isn't a descendant of either A or B, so we need to make it a child of A.
		gltf_node.xform = node_at_a.global_transform.affine_inverse() * scene_node.global_transform
		var parent_index_a: int = state.get_node_index(node_at_a)
		if parent_index_a == -1:
			# In this case, the GLTFNode hasn't been created yet, so we need to set the parent later.
			gltf_node.set_additional_data(&"GLTFPhysicsJointSetNodeParent", node_at_a)
			# Set this to a positive number so Godot doesn't try to add it as a parent to the wrong node.
			parent_index_a = 2147483647
		state.append_gltf_node(gltf_node, scene_node, parent_index_a)
	if node_at_b != null:
		# Set up a connection from gltf_node to node B.
		var connected_node: Node = _get_connected_node_if_any(node_at_b, scene_node.global_transform)
		if connected_node is Node3D:
			joint_node.connected_node_index = state.get_node_index(connected_node)
		else:
			var connected_gltf_node := GLTFNode.new()
			connected_gltf_node.resource_name = node_at_b.name + "JointAttachment"
			connected_gltf_node.xform = node_at_b.global_transform.affine_inverse() * scene_node.global_transform
			var parent_index_b: int = state.get_node_index(node_at_b)
			if parent_index_b == -1:
				# In this case, the GLTFNode hasn't been created yet, so we need to set the parent later.
				connected_gltf_node.set_additional_data(&"GLTFPhysicsJointSetNodeParent", node_at_b)
				# Set this to a positive number so Godot doesn't try to add it as a parent to the wrong node.
				parent_index_b = 2147483647
			joint_node.connected_node_index = state.append_gltf_node(connected_gltf_node, scene_node, parent_index_b)
	gltf_node.set_additional_data("GLTFPhysicsJointNode", joint_node)


func _export_post_convert(state: GLTFState, root: Node) -> Error:
	var all_gltf_nodes: Array[GLTFNode] = state.get_nodes()
	for i in range(all_gltf_nodes.size()):
		var gltf_node: GLTFNode = all_gltf_nodes[i]
		var set_node_parent = gltf_node.get_additional_data("GLTFPhysicsJointSetNodeParent")
		if set_node_parent is Node:
			var parent_index: int = state.get_node_index(set_node_parent)
			if parent_index == -1:
				printerr("glTF Physics Joint: Could not find parent node for joint.")
				return ERR_INVALID_DATA
			gltf_node.parent = parent_index
			all_gltf_nodes[parent_index].append_child_index(i)
	return OK


func _export_node(state: GLTFState, gltf_node: GLTFNode, json: Dictionary, joint_maybe: Node) -> Error:
	var gltf_physics_joint_node: GLTFPhysicsJointNode = gltf_node.get_additional_data("GLTFPhysicsJointNode")
	if gltf_physics_joint_node == null:
		return OK
	var node_extensions = json.get("extensions")
	if not node_extensions is Dictionary:
		node_extensions = {}
		json["extensions"] = node_extensions
	var omi_physics_joint_node_ext: Dictionary = gltf_physics_joint_node.to_dictionary()
	node_extensions["OMI_physics_joint"] = omi_physics_joint_node_ext
	return OK
