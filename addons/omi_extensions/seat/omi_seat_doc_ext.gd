@tool
class_name GLTFDocumentExtensionOMISeat
extends GLTFDocumentExtension


# Import process.
func _import_preflight(_state: GLTFState, extensions: PackedStringArray) -> Error:
	if extensions.has("OMI_seat"):
		return OK
	return ERR_SKIP


func _get_supported_extensions() -> PackedStringArray:
	return PackedStringArray(["OMI_seat"])


func _parse_node_extensions(state: GLTFState, gltf_node: GLTFNode, extensions: Dictionary) -> Error:
	if not extensions.has("OMI_seat"):
		return OK
	var seat_dict = extensions["OMI_seat"]
	if not seat_dict is Dictionary:
		printerr("Error: OMI_seat extension should be a Dictionary.")
		return ERR_FILE_CORRUPT
	if not _convert_seat_dict(seat_dict):
		return ERR_FILE_CORRUPT
	gltf_node.set_additional_data(&"OMI_seat", seat_dict)
	return OK


func _generate_scene_node(state: GLTFState, gltf_node: GLTFNode, scene_parent: Node) -> Node3D:
	var seat_dict = gltf_node.get_additional_data(&"OMI_seat")
	if seat_dict == null:
		return null
	# If this node is both a seat and a glTF trigger, generate the Area3D-derived Seat3D node.
	# Else, if this is not any kind of trigger, don't generate a Seat3D/Area3D, just set node metadata later.
	var trigger = gltf_node.get_additional_data(&"GLTFPhysicsTrigger")
	if trigger == null:
		trigger = gltf_node.get_additional_data(&"GLTFPhysicsCompoundTriggerNodes")
		if trigger == null:
			trigger = gltf_node.get_additional_data(&"GLTFPhysicsBody")
			if trigger == null:
				return null
			if trigger.body_type != "trigger":
				return null
	return Seat3D.from_points(seat_dict["back"], seat_dict["foot"], seat_dict["knee"], seat_dict.get("angle", TAU * 0.25))


func _import_node(_state: GLTFState, gltf_node: GLTFNode, json: Dictionary, node: Node) -> Error:
	var seat_dict = gltf_node.get_additional_data(&"OMI_seat")
	if seat_dict != null:
		node.set_meta(&"OMI_seat", seat_dict)
	return OK


static func _convert_seat_dict(seat_dict: Dictionary) -> bool:
	# The JSON data has Vector3s represented as arrays, let's convert them to Vector3.
	if not _convert_seat_vector(seat_dict, "foot"):
		return false
	if not _convert_seat_vector(seat_dict, "knee"):
		return false
	if not _convert_seat_vector(seat_dict, "back"):
		return false
	if not seat_dict.has("angle") or not seat_dict["angle"] is float:
		seat_dict["angle"] = TAU * 0.25
	_calculate_helper_vectors(seat_dict)
	return true


static func _convert_seat_vector(seat_dict: Dictionary, vector_name: String) -> bool:
	if not seat_dict.has(vector_name):
		printerr("Error: OMI_seat extension is missing required field '" + vector_name + "', contents: '" + str(seat_dict) + "'.")
		return false
	var vector_array = seat_dict[vector_name]
	if not vector_array is Array or vector_array.size() != 3 or not vector_array[0] is float \
			or not vector_array[1] is float or not vector_array[2] is float:
		printerr("Error: OMI_seat extension field '" + vector_name + "' is invalid, expected an array of 3 numbers but was '" + str(vector_array) + "'.")
		return false
	seat_dict[vector_name] = Vector3(vector_array[0], vector_array[1], vector_array[2])
	return true


static func _calculate_helper_vectors(seat_dict: Dictionary) -> void:
	var back: Vector3 = seat_dict["back"]
	var foot: Vector3 = seat_dict["foot"]
	var knee: Vector3 = seat_dict["knee"]
	var upper_leg_dir: Vector3 = back.direction_to(knee)
	var lower_leg_dir: Vector3 = knee.direction_to(foot)
	var right: Vector3 = lower_leg_dir.cross(upper_leg_dir).normalized()
	var spine_dir: Vector3 = upper_leg_dir.rotated(right, seat_dict["angle"])
	var spine_norm: Vector3 = spine_dir.cross(right)
	var upper_leg_norm: Vector3 = right.cross(upper_leg_dir)
	var lower_leg_norm: Vector3 = right.cross(lower_leg_dir)
	# Write to the dictionary.
	seat_dict["upper_leg_dir"] = upper_leg_dir
	seat_dict["lower_leg_dir"] = lower_leg_dir
	seat_dict["right"] = right
	seat_dict["spine_dir"] = spine_dir
	seat_dict["spine_norm"] = spine_norm
	seat_dict["upper_leg_norm"] = upper_leg_norm
	seat_dict["lower_leg_norm"] = lower_leg_norm


# Export process.
func _export_node(state: GLTFState, _gltf_node: GLTFNode, json: Dictionary, node: Node) -> Error:
	var omi_seat_ext: Dictionary = _export_omi_seat_from_node(node)
	if omi_seat_ext.is_empty():
		return OK
	# Write to the GLTF node JSON.
	var extensions: Dictionary
	if "extensions" in json:
		extensions = json["extensions"]
	else:
		extensions = {}
		json["extensions"] = extensions
	extensions["OMI_seat"] = omi_seat_ext
	state.add_used_extension("OMI_seat", false)
	return OK


func _export_omi_seat_from_node(node: Node) -> Dictionary:
	var omi_seat_ext: Dictionary = {}
	var back: Vector3
	var foot: Vector3
	var knee: Vector3
	var angle: float
	if node is Seat3D:
		back = node.back
		foot = node.foot
		knee = node.knee
		angle = node.angle
	elif node.has_meta(&"OMI_seat"):
		var omi_seat_meta = node.get_meta(&"OMI_seat")
		back = omi_seat_meta["back"]
		foot = omi_seat_meta["foot"]
		knee = omi_seat_meta["knee"]
		angle = omi_seat_meta["angle"]
	else:
		return omi_seat_ext
	omi_seat_ext["back"] = [back.x, back.y, back.z]
	omi_seat_ext["foot"] = [foot.x, foot.y, foot.z]
	omi_seat_ext["knee"] = [knee.x, knee.y, knee.z]
	if not is_equal_approx(angle, TAU * 0.25):
		omi_seat_ext["angle"] = angle
	return omi_seat_ext
