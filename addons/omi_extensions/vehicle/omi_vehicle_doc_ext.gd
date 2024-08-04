@tool
class_name GLTFDocumentExtensionOMIVehicle
extends GLTFDocumentExtension


# Import process.
func _import_preflight(state: GLTFState, extensions: PackedStringArray) -> Error:
	if not extensions.has("OMI_vehicle_body") and not extensions.has("OMI_vehicle_hover_thruster") and not extensions.has("OMI_vehicle_thruster") and not extensions.has("OMI_vehicle_wheel"):
		return ERR_SKIP
	var state_json: Dictionary = state.get_json()
	if state_json.has("extensions"):
		var state_extensions: Dictionary = state_json["extensions"]
		if state_extensions.has("OMI_vehicle_hover_thruster"):
			var omi_vehicle_hover_thruster_ext: Dictionary = state_extensions["OMI_vehicle_hover_thruster"]
			if omi_vehicle_hover_thruster_ext.has("hoverThrusters"):
				var state_hover_thruster_dicts: Array = omi_vehicle_hover_thruster_ext["hoverThrusters"]
				if state_hover_thruster_dicts.size() > 0:
					var state_hover_thrusters: Array[GLTFVehicleHoverThruster] = []
					for i in range(state_hover_thruster_dicts.size()):
						state_hover_thrusters.append(GLTFVehicleHoverThruster.from_dictionary(state_hover_thruster_dicts[i]))
					state.set_additional_data(&"GLTFVehicleHoverThrusters", state_hover_thrusters)
		if state_extensions.has("OMI_vehicle_thruster"):
			var omi_vehicle_thruster_ext: Dictionary = state_extensions["OMI_vehicle_thruster"]
			if omi_vehicle_thruster_ext.has("thrusters"):
				var state_thruster_dicts: Array = omi_vehicle_thruster_ext["thrusters"]
				if state_thruster_dicts.size() > 0:
					var state_thrusters: Array[GLTFVehicleThruster] = []
					for i in range(state_thruster_dicts.size()):
						state_thrusters.append(GLTFVehicleThruster.from_dictionary(state_thruster_dicts[i]))
					state.set_additional_data(&"GLTFVehicleThrusters", state_thrusters)
		if state_extensions.has("OMI_vehicle_wheel"):
			var omi_vehicle_wheel_ext: Dictionary = state_extensions["OMI_vehicle_wheel"]
			if omi_vehicle_wheel_ext.has("wheels"):
				var state_wheel_dicts: Array = omi_vehicle_wheel_ext["wheels"]
				if state_wheel_dicts.size() > 0:
					var state_wheels: Array[GLTFVehicleWheel] = []
					for i in range(state_wheel_dicts.size()):
						state_wheels.append(GLTFVehicleWheel.from_dictionary(state_wheel_dicts[i]))
					state.set_additional_data(&"GLTFVehicleWheels", state_wheels)
	return OK


func _get_supported_extensions() -> PackedStringArray:
	return PackedStringArray(["OMI_vehicle_body", "OMI_vehicle_hover_thruster", "OMI_vehicle_thruster", "OMI_vehicle_wheel"])


func _parse_node_extensions(state: GLTFState, gltf_node: GLTFNode, extensions: Dictionary) -> Error:
	if extensions.has("OMI_vehicle_body"):
		gltf_node.set_additional_data(&"GLTFVehicleBody", GLTFVehicleBody.from_dictionary(extensions["OMI_vehicle_body"]))
	if extensions.has("OMI_vehicle_hover_thruster"):
		var node_hover_thruster_ext: Dictionary = extensions["OMI_vehicle_hover_thruster"]
		if node_hover_thruster_ext.has("hoverThruster"):
			# "hoverThruster" is the index of the hover thruster parameters in the state hover thrusters array.
			var node_hover_thruster_index: int = node_hover_thruster_ext["hoverThruster"]
			var state_hover_thrusters: Array[GLTFVehicleHoverThruster] = state.get_additional_data(&"GLTFVehicleHoverThrusters")
			if node_hover_thruster_index < 0 or node_hover_thruster_index >= state_hover_thrusters.size():
				printerr("GLTF Physics: On node " + gltf_node.get_name() + ", the hover thruster index " + str(node_hover_thruster_index) + " is not in the state hover thrusters (size: " + str(state_hover_thrusters.size()) + ").")
				return ERR_FILE_CORRUPT
			gltf_node.set_additional_data(&"GLTFVehicleHoverThruster", state_hover_thrusters[node_hover_thruster_index])
		else:
			gltf_node.set_additional_data(&"GLTFVehicleHoverThruster", GLTFVehicleHoverThruster.from_dictionary(extensions["OMI_vehicle_hover_thruster"]))
	if extensions.has("OMI_vehicle_thruster"):
		var node_thruster_ext: Dictionary = extensions["OMI_vehicle_thruster"]
		if node_thruster_ext.has("thruster"):
			# "thruster" is the index of the thruster parameters in the state thrusters array.
			var node_thruster_index: int = node_thruster_ext["thruster"]
			var state_thrusters: Array[GLTFVehicleThruster] = state.get_additional_data(&"GLTFVehicleThrusters")
			if node_thruster_index < 0 or node_thruster_index >= state_thrusters.size():
				printerr("GLTF Physics: On node " + gltf_node.get_name() + ", the thruster index " + str(node_thruster_index) + " is not in the state thrusters (size: " + str(state_thrusters.size()) + ").")
				return ERR_FILE_CORRUPT
			gltf_node.set_additional_data(&"GLTFVehicleThruster", state_thrusters[node_thruster_index])
		else:
			gltf_node.set_additional_data(&"GLTFVehicleThruster", GLTFVehicleThruster.from_dictionary(extensions["OMI_vehicle_thruster"]))
	if extensions.has("OMI_vehicle_wheel"):
		var node_wheel_ext: Dictionary = extensions["OMI_vehicle_wheel"]
		if node_wheel_ext.has("wheel"):
			# "wheel" is the index of the wheel parameters in the state wheels array.
			var node_wheel_index: int = node_wheel_ext["wheel"]
			var state_wheels: Array[GLTFVehicleWheel] = state.get_additional_data(&"GLTFVehicleWheels")
			if node_wheel_index < 0 or node_wheel_index >= state_wheels.size():
				printerr("GLTF Physics: On node " + gltf_node.get_name() + ", the wheel index " + str(node_wheel_index) + " is not in the state wheels (size: " + str(state_wheels.size()) + ").")
				return ERR_FILE_CORRUPT
			gltf_node.set_additional_data(&"GLTFVehicleWheel", state_wheels[node_wheel_index])
		else:
			gltf_node.set_additional_data(&"GLTFVehicleWheel", GLTFVehicleWheel.from_dictionary(extensions["OMI_vehicle_wheel"]))
	return OK


func _import_post_parse(state: GLTFState) -> Error:
	# If a vehicle is using a seat as a pilot seat, inform that seat that it's a pilot seat.
	# This must be done after parsing node extensions and before generating nodes.
	var gltf_nodes: Array[GLTFNode] = state.get_nodes()
	for gltf_node in gltf_nodes:
		var gltf_vehicle_body = gltf_node.get_additional_data(&"GLTFVehicleBody")
		if gltf_vehicle_body is GLTFVehicleBody:
			if gltf_vehicle_body.pilot_seat_index != -1:
				var seat_node: GLTFNode = gltf_nodes[gltf_vehicle_body.pilot_seat_index]
				if seat_node is GLTFNode:
					seat_node.set_additional_data(&"GLTFPilotedVehicleBody", gltf_nodes.find(gltf_node))
	return OK


func _generate_scene_node(gltf_state: GLTFState, gltf_node: GLTFNode, scene_parent: Node) -> Node3D:
	var gltf_vehicle_body = gltf_node.get_additional_data(&"GLTFVehicleBody")
	if gltf_vehicle_body is GLTFVehicleBody:
		return gltf_vehicle_body.to_node(gltf_state, gltf_node)
	var gltf_vehicle_hover_thruster = gltf_node.get_additional_data(&"GLTFVehicleHoverThruster")
	if gltf_vehicle_hover_thruster is GLTFVehicleHoverThruster:
		return gltf_vehicle_hover_thruster.to_node()
	var gltf_vehicle_thruster = gltf_node.get_additional_data(&"GLTFVehicleThruster")
	if gltf_vehicle_thruster is GLTFVehicleThruster:
		return gltf_vehicle_thruster.to_node()
	var gltf_vehicle_wheel = gltf_node.get_additional_data(&"GLTFVehicleWheel")
	if gltf_vehicle_wheel is GLTFVehicleWheel:
		return gltf_vehicle_wheel.to_node()
	var gltf_seat_dict = gltf_node.get_additional_data(&"OMI_seat")
	if gltf_seat_dict != null:
		var gltf_piloted_body = gltf_node.get_additional_data(&"GLTFPilotedVehicleBody")
		if gltf_piloted_body is int and gltf_piloted_body != -1:
			var seat = PilotSeat3D.from_points(gltf_seat_dict["back"], gltf_seat_dict["foot"], gltf_seat_dict["knee"], gltf_seat_dict.get("angle", TAU * 0.25))
			# If this pilot seat node has a glTF trigger shape, generate that shape too.
			var trigger = gltf_node.get_additional_data(&"GLTFPhysicsTriggerShape")
			if trigger is GLTFPhysicsShape:
				var shape: CollisionShape3D = trigger.to_node(true)
				shape.name = gltf_node.resource_name + "Shape"
				seat.add_child(shape)
			return seat
	return null


func _import_node(gltf_state: GLTFState, gltf_node: GLTFNode, json: Dictionary, node: Node) -> Error:
	if node is PilotedVehicleBody3D:
		var vehicle_node: PilotedVehicleBody3D = node
		var gltf_vehicle_body: GLTFVehicleBody = gltf_node.get_additional_data(&"GLTFVehicleBody")
		if gltf_vehicle_body.pilot_seat_index != -1:
			vehicle_node.pilot_seat_node = gltf_state.get_scene_node(gltf_vehicle_body.pilot_seat_index)
		if vehicle_node.pilot_seat_node != null:
			vehicle_node.pilot_seat_node.piloted_vehicle_node = vehicle_node
	elif node is PilotSeat3D:
		var gltf_piloted_body = gltf_node.get_additional_data(&"GLTFPilotedVehicleBody")
		if gltf_piloted_body is int and gltf_piloted_body != -1:
			node.piloted_vehicle_node = gltf_state.get_scene_node(gltf_piloted_body)
	return OK


# Export process.
func _convert_scene_node(state: GLTFState, gltf_node: GLTFNode, scene_node: Node) -> void:
	if scene_node is VehicleBody3D:
		var gltf_vehicle_body := GLTFVehicleBody.from_node(scene_node)
		gltf_node.set_additional_data(&"GLTFVehicleBody", gltf_vehicle_body)
	elif scene_node is VehicleHoverThruster3D:
		var gltf_vehicle_hover_thruster := GLTFVehicleHoverThruster.from_node(scene_node)
		gltf_node.set_additional_data(&"GLTFVehicleHoverThruster", gltf_vehicle_hover_thruster)
	elif scene_node is VehicleThruster3D:
		var gltf_vehicle_thruster := GLTFVehicleThruster.from_node(scene_node)
		gltf_node.set_additional_data(&"GLTFVehicleThruster", gltf_vehicle_thruster)
	elif scene_node is VehicleWheel3D:
		var gltf_vehicle_wheel := GLTFVehicleWheel.from_node(scene_node)
		gltf_node.set_additional_data(&"GLTFVehicleWheel", gltf_vehicle_wheel)


func _get_or_create_array_in_state(gltf_state: GLTFState, ext_name: String, ext_key: String) -> Array:
	var state_json: Dictionary = gltf_state.get_json()
	var state_extensions: Dictionary = state_json.get_or_add("extensions", {})
	var ext: Dictionary = state_extensions.get_or_add(ext_name, {})
	gltf_state.add_used_extension(ext_name, false)
	var state_ext: Array = ext.get_or_add(ext_key, [])
	return state_ext


func _node_index_from_scene_node(state: GLTFState, scene_node: Node) -> int:
	var index: int = 0
	var node: Node = state.get_scene_node(index)
	while node != null:
		if node == scene_node:
			return index
		index = index + 1
		node = state.get_scene_node(index)
	return -1


func _export_node_item(gltf_state: GLTFState, data_name: StringName, ext_name: String, ext_item_key: String, gltf_node: GLTFNode, node_json: Dictionary) -> void:
	var data_resource: Resource = gltf_node.get_additional_data(data_name)
	if data_resource == null:
		return
	var node_extensions: Dictionary = node_json.get_or_add("extensions", {})
	var state_array: Array = _get_or_create_array_in_state(gltf_state, ext_name, ext_item_key + "s")
	var size: int = state_array.size()
	var node_ext: Dictionary = {}
	node_extensions[ext_name] = node_ext
	var serialized_dict: Dictionary = data_resource.to_dictionary()
	for i in range(size):
		var other: Dictionary = state_array[i]
		if other == serialized_dict:
			# De-duplication: If we already have an identical item,
			# set the item index to the existing one and return.
			node_ext[ext_item_key] = i
			return
	# If we don't have an identical item, add it to the array.
	state_array.append(serialized_dict)
	node_ext[ext_item_key] = size


func _export_node(state: GLTFState, gltf_node: GLTFNode, json: Dictionary, _node: Node) -> Error:
	var gltf_vehicle_body: GLTFVehicleBody = gltf_node.get_additional_data(&"GLTFVehicleBody")
	if gltf_vehicle_body != null:
		gltf_vehicle_body.pilot_seat_index = _node_index_from_scene_node(state, gltf_vehicle_body.pilot_seat_node)
		var node_extensions = json.get_or_add("extensions", {})
		state.add_used_extension("OMI_vehicle_body", false)
		node_extensions["OMI_vehicle_body"] = gltf_vehicle_body.to_dictionary()
	# Use GDScript's dynamic typing to avoid repeating the same code for each type.
	_export_node_item(state, &"GLTFVehicleHoverThruster", "OMI_vehicle_hover_thruster", "hoverThruster", gltf_node, json)
	_export_node_item(state, &"GLTFVehicleThruster", "OMI_vehicle_thruster", "thruster", gltf_node, json)
	_export_node_item(state, &"GLTFVehicleWheel", "OMI_vehicle_wheel", "wheel", gltf_node, json)
	return OK
