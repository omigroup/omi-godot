@tool
class_name GLTFDocumentExtensionOMIMaterialsBlend
extends GLTFDocumentExtension


func _import_preflight(_state: GLTFState, extensions: PackedStringArray) -> Error:
	if extensions.has("OMI_materials_blend"):
		return OK
	return ERR_SKIP


func _get_supported_extensions() -> PackedStringArray:
	return PackedStringArray(["OMI_materials_blend"])


func _apply_alpha_mode(alpha_mode: String, godot_mat: BaseMaterial3D) -> void:
	match alpha_mode:
		"BLEND": godot_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
		"HASH": godot_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_HASH
		"PREMULT": godot_mat.blend_mode = BaseMaterial3D.BLEND_MODE_PREMULT_ALPHA
		"MULTIPLY": godot_mat.blend_mode = BaseMaterial3D.BLEND_MODE_MUL
		"ADD": godot_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		"SUBTRACT": godot_mat.blend_mode = BaseMaterial3D.BLEND_MODE_SUB
		"REV_SUBTRACT": push_warning("REV_SUBTRACT alpha blend mode is not supported by Godot.")
		"MAX": push_warning("MAX alpha blend mode is not supported by Godot.")
		"MIN": push_warning("MIN alpha blend mode is not supported by Godot.")


func _read_apply_material_blend_extension(mat_blend_ext: Dictionary, godot_mat: BaseMaterial3D) -> void:
	if mat_blend_ext.has("alwaysUseCutoff"):
		if mat_blend_ext["alwaysUseCutoff"]:
			godot_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	if mat_blend_ext.has("alphaMode"):
		_apply_alpha_mode(mat_blend_ext["alphaMode"], godot_mat)


func _import_post_parse(gltf_state: GLTFState) -> Error:
	var materials: Array[Material] = gltf_state.get_materials()
	var json_materials: Array = gltf_state.json.get("materials", [])
	assert(materials.size() == json_materials.size())
	for i in range(materials.size()):
		var mat_3d: BaseMaterial3D = materials[i] as BaseMaterial3D
		var mat_dict: Dictionary = json_materials[i]
		if mat_dict.has("alphaMode"):
			_apply_alpha_mode(mat_dict["alphaMode"], mat_3d)
		if mat_dict.has("extensions") and materials[i] is BaseMaterial3D:
			var mat_extensions: Dictionary = mat_dict["extensions"]
			if mat_extensions.has("OMI_materials_blend"):
				var mat_blend_ext: Dictionary = mat_extensions["OMI_materials_blend"]
				_read_apply_material_blend_extension(mat_blend_ext, mat_3d)
	gltf_state.set_materials(materials)
	return OK


func _write_material_blend_extension_if_needed(godot_mat: BaseMaterial3D, mat_dict: Dictionary) -> bool:
	if godot_mat.blend_mode == BaseMaterial3D.BLEND_MODE_MIX:
		if godot_mat.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_HASH:
			var mat_blend_ext: Dictionary = mat_dict.get_or_add("extensions", {}).get_or_add("OMI_materials_blend", {})
			mat_blend_ext["alphaMode"] = "HASH"
			return true
		return false
	var mat_blend_ext: Dictionary = mat_dict.get_or_add("extensions", {}).get_or_add("OMI_materials_blend", {})
	match godot_mat.blend_mode:
		BaseMaterial3D.BLEND_MODE_ADD:
			mat_blend_ext["alphaMode"] = "ADD"
		BaseMaterial3D.BLEND_MODE_SUB:
			mat_blend_ext["alphaMode"] = "SUBTRACT"
		BaseMaterial3D.BLEND_MODE_MUL:
			mat_blend_ext["alphaMode"] = "MULTIPLY"
		BaseMaterial3D.BLEND_MODE_PREMULT_ALPHA:
			mat_blend_ext["alphaMode"] = "PREMULT"
	if godot_mat.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR:
		mat_blend_ext["alwaysUseCutoff"] = true
		mat_dict["alphaCutoff"] = godot_mat.alpha_scissor_threshold
	return true


func _export_post(gltf_state: GLTFState) -> Error:
	var materials: Array[Material] = gltf_state.get_materials()
	var json_materials: Array = gltf_state.json.get("materials", [])
	assert(materials.size() == json_materials.size())
	var use_material_blend_extension: bool = false
	for i in range(materials.size()):
		var mat_dict: Dictionary = json_materials[i]
		var written: bool = _write_material_blend_extension_if_needed(materials[i] as BaseMaterial3D, mat_dict)
		use_material_blend_extension = use_material_blend_extension or written
	if use_material_blend_extension:
		gltf_state.add_used_extension("OMI_materials_blend", false)
		var extensions_used: Array = gltf_state.json.get_or_add("extensionsUsed", [])
		extensions_used.append("OMI_materials_blend")
		gltf_state.json["extensionsUsed"] = extensions_used
	return OK
