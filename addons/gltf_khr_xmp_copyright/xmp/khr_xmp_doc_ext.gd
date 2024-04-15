@tool
class_name GLTFDocumentExtensionKHR_XMP
extends GLTFDocumentExtension


## Applies to the whole document when exporting.
@export var dcmi_license_metadata := DCMILicenseMetadata.new()


# Import process.
func _import_preflight(gltf_state: GLTFState, extensions_used: PackedStringArray) -> Error:
	if not extensions_used.has("KHR_xmp_json_ld"):
		return ERR_SKIP
	var state_json: Dictionary = gltf_state.json
	if not state_json.has("extensions"):
		return ERR_INVALID_DATA
	var doc_extensions: Dictionary = state_json["extensions"]
	if not doc_extensions.has("KHR_xmp_json_ld"):
		return ERR_INVALID_DATA
	var khr_xmp_ext: Dictionary = doc_extensions["KHR_xmp_json_ld"]
	if not khr_xmp_ext.has("packets"):
		return ERR_INVALID_DATA
	var khr_xmp_packets: Array = khr_xmp_ext["packets"]
	var parsed_khr_xmp_data: Array = []
	for xmp_packet in khr_xmp_packets:
		var xmp: XMPMetadataBase = _parse_xmp_packet(gltf_state, xmp_packet)
		if xmp == null:
			return ERR_INVALID_DATA
		parsed_khr_xmp_data.append(xmp)
	gltf_state.set_additional_data(&"KHR_xmp_json_ld", parsed_khr_xmp_data)
	return OK


func _parse_xmp_packet(gltf_state: GLTFState, xmp_packet: Dictionary) -> XMPMetadataBase:
	if not xmp_packet.has("@context"):
		return null
	var xmp_context: Dictionary = xmp_packet["@context"]
	var xmp_metadata: XMPMetadataBase = null
	for context_prefix in xmp_context:
		if context_prefix == "dc":
			xmp_metadata = DCMILicenseMetadata.from_dictionary(xmp_packet)
		elif context_prefix == "rdf":
			# RDF allows specifying language alternatives, it combines together
			# with another context, we don't need to do anything special here.
			pass
		else:
			# XMP is an open-ended standard, any data structure can be stored
			# in it. Show a warning when we encounter something unrecognized,
			# but the JSON data will still be available in an XMPMetadataBase.
			push_warning("GLTF KHR XMP: Unrecognized context prefix '" + context_prefix + "'.")
	if xmp_metadata == null:
		# No specific class wants to handle this, so just return the base class.
		xmp_metadata = XMPMetadataBase.from_dictionary(xmp_packet)
	return xmp_metadata


func _get_supported_extensions() -> PackedStringArray:
	return PackedStringArray(["KHR_xmp_json_ld"])


func _import_post(gltf_state: GLTFState, root: Node) -> Error:
	var asset_json: Dictionary = gltf_state.json["asset"]
	if asset_json.has("extensions"):
		var asset_extensions: Dictionary = asset_json["extensions"]
		if asset_extensions.has("KHR_xmp_json_ld"):
			var asset_xmp: Dictionary = asset_extensions["KHR_xmp_json_ld"]
			if asset_xmp.has("packet"):
				var packet: int = int(asset_xmp["packet"])
				var xmp_array: Array = gltf_state.get_additional_data("KHR_xmp_json_ld")
				root.set_meta("KHR_xmp_json_ld", xmp_array[packet])
	return OK


# Export process.
func _export_preflight(gltf_state: GLTFState, root: Node) -> Error:
	var dcmi_dict: Dictionary = dcmi_license_metadata.to_dictionary()
	if dcmi_dict.is_empty():
		return OK
	dcmi_dict["dc:format"] = "model/gltf"
	# Add the DCMI XMP JSON dictionary to the document extensions.
	var state_packets: Array = _get_or_create_state_packets_in_state(gltf_state)
	state_packets.append(dcmi_dict)
	return OK


func _export_preserialize(gltf_state: GLTFState) -> Error:
	var state_packets = _get_state_packets_in_state_if_present(gltf_state)
	if state_packets == null or state_packets.is_empty():
		return OK
	var first_packet: Dictionary = state_packets[0]
	if first_packet.has("dc:format"):
		if gltf_state.filename.ends_with(".gltf"):
			first_packet["dc:format"] = "model/gltf+json"
		else: # If .glb, it's binary. If empty, it's a buffer, also binary.
			first_packet["dc:format"] = "model/gltf-binary"
	return OK


func _export_node(gltf_state: GLTFState, gltf_node: GLTFNode, node_json: Dictionary, node: Node) -> Error:
	if not node.has_meta(&"dcmi_license_metadata"):
		return OK
	var dcmi_data: DCMILicenseMetadata = node.get_meta(&"dcmi_license_metadata")
	var dcmi_dict = dcmi_data.to_dictionary()
	if dcmi_dict.is_empty():
		return OK
	# Insert the DCMI dictionary in the state packets and reference it on the node.
	var state_packets: Array = _get_or_create_state_packets_in_state(gltf_state)
	var node_extensions: Dictionary
	# TODO: = node_json.get_or_set_default("extensions", {})
	if node_json.has("extensions"):
		node_extensions = node_json["extensions"]
	else:
		node_extensions = {}
		node_json["extensions"] = node_extensions
	node_extensions["KHR_xmp_json_ld"] = {
		"packet": state_packets.size()
	}
	state_packets.append(dcmi_dict)
	return OK


func _export_post(gltf_state: GLTFState) -> Error:
	var state_json: Dictionary = gltf_state.json
	var state_packets = _get_state_packets_in_state_if_present(gltf_state)
	if state_packets == null or state_packets.is_empty():
		return OK
	if not state_packets[0].has("dc:format"):
		return OK
	# Reference the DCMI XMP JSON dictionary in the asset.
	var asset: Dictionary = state_json["asset"]
	var asset_extensions: Dictionary
	# TODO: = asset.get_or_set_default("extensions", {})
	if asset.has("extensions"):
		asset_extensions = asset["extensions"]
	else:
		asset_extensions = {}
		asset["extensions"] = asset_extensions
	asset_extensions["KHR_xmp_json_ld"] = {
		"packet": 0
	}
	return OK


func _get_state_packets_in_state_if_present(gltf_state: GLTFState): # -> Array?
	var state_json: Dictionary = gltf_state.json
	if not state_json.has("extensions"):
		return null
	var state_extensions: Dictionary = state_json["extensions"]
	if not state_extensions.has("KHR_xmp_json_ld"):
		return null
	var khr_xmp_ext: Dictionary = state_extensions["KHR_xmp_json_ld"]
	return khr_xmp_ext["packets"]


func _get_or_create_state_packets_in_state(gltf_state: GLTFState) -> Array:
	var state_json = gltf_state.get_json()
	var state_extensions: Dictionary
	if state_json.has("extensions"):
		state_extensions = state_json["extensions"]
	else:
		state_extensions = {}
		state_json["extensions"] = state_extensions
	var omi_physics_joint_doc_ext: Dictionary
	if state_extensions.has("KHR_xmp_json_ld"):
		omi_physics_joint_doc_ext = state_extensions["KHR_xmp_json_ld"]
	else:
		omi_physics_joint_doc_ext = {}
		state_extensions["KHR_xmp_json_ld"] = omi_physics_joint_doc_ext
		gltf_state.add_used_extension("KHR_xmp_json_ld", false)
	var state_packets: Array
	if omi_physics_joint_doc_ext.has("packets"):
		state_packets = omi_physics_joint_doc_ext["packets"]
	else:
		state_packets = []
		omi_physics_joint_doc_ext["packets"] = state_packets
	return state_packets
