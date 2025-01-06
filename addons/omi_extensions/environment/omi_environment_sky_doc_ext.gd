@tool
class_name GLTFDocumentExtensionOMIEnvironmentSky
extends GLTFDocumentExtension


@export var export_environment: bool = true


# Import process.
func _import_preflight(state: GLTFState, extensions: PackedStringArray) -> Error:
	if not extensions.has("OMI_environment_sky"):
		return ERR_SKIP
	if not state.json.has("extensions"):
		return ERR_FILE_UNRECOGNIZED
	var doc_extensions: Dictionary = state.json["extensions"]
	if not doc_extensions.has("OMI_environment_sky"):
		return ERR_FILE_UNRECOGNIZED
	var env_sky_ext: Dictionary = doc_extensions["OMI_environment_sky"]
	var gltf_env_skies: Array[GLTFEnvironmentSky] = []
	if env_sky_ext.has("skies"):
		var sky_dicts: Array = env_sky_ext["skies"]
		for i in range(sky_dicts.size()):
			var sky_dict: Dictionary = sky_dicts[i]
			gltf_env_skies.append(GLTFEnvironmentSky.from_dictionary(sky_dict))
		state.set_additional_data(&"GLTFEnvironmentSkies", gltf_env_skies)
	# Get the sky index. Default to 0 but this may be overwritten by the scene.
	state.set_additional_data(&"GLTFEnvironmentSkyIndex", 0)
	if state.json.has("scene") and state.json.has("scenes"):
		var scene_index: int = state.json["scene"]
		var scenes: Array = state.json["scenes"]
		if scene_index < scenes.size():
			var scene: Dictionary = scenes[scene_index]
			if scene.has("extensions"):
				var scene_ext: Dictionary = scene["extensions"]
				if scene_ext.has("OMI_environment_sky"):
					var scene_sky_ext: Dictionary = scene_ext["OMI_environment_sky"]
					if scene_sky_ext.has("sky"):
						var sky_index: int = scene_sky_ext["sky"]
						state.set_additional_data(&"GLTFEnvironmentSkyIndex", sky_index)
	return OK


func _get_supported_extensions() -> PackedStringArray:
	return PackedStringArray(["OMI_environment_sky"])


func _import_post_parse(gltf_state: GLTFState) -> Error:
	var gltf_env_skies: Array[GLTFEnvironmentSky] = gltf_state.get_additional_data(&"GLTFEnvironmentSkies")
	if gltf_env_skies.is_empty():
		return OK
	var images: Array[Texture2D] = gltf_state.get_images()
	var textures: Array[GLTFTexture] = gltf_state.get_textures()
	for gltf_env_sky in gltf_env_skies:
		# Assign equirectangular texture from index.
		if gltf_env_sky.panorama_equirectangular_index != -1:
			if gltf_env_sky.panorama_equirectangular_index >= textures.size():
				return ERR_INVALID_DATA
			var tex: GLTFTexture = textures[gltf_env_sky.panorama_equirectangular_index]
			if tex.src_image != -1:
				if tex.src_image >= images.size():
					return ERR_INVALID_DATA
				gltf_env_sky.panorama_equirectangular_texture = images[tex.src_image]
		# Assign cubemap textures from indices.
		for i in range(gltf_env_sky.panorama_cubemap_indices.size()):
			var tex_index: int = gltf_env_sky.panorama_cubemap_indices[i]
			if tex_index >= textures.size():
				return ERR_INVALID_DATA
			var tex: GLTFTexture = textures[tex_index]
			if tex.src_image != -1:
				if tex.src_image >= images.size():
					return ERR_INVALID_DATA
				gltf_env_sky.panorama_cubemap_textures[i] = images[tex.src_image]
	return OK


func _import_post(gltf_state: GLTFState, root: Node) -> Error:
	var gltf_env_skies: Array[GLTFEnvironmentSky] = gltf_state.get_additional_data(&"GLTFEnvironmentSkies")
	if gltf_env_skies.is_empty():
		return OK
	var sky_index: int = gltf_state.get_additional_data(&"GLTFEnvironmentSkyIndex")
	if sky_index >= gltf_env_skies.size():
		printerr("GLTFEnvironmentSky: Sky at index " + str(sky_index) + " is invalid. Using index 0 as a fallback.")
		sky_index = 0
	var gltf_env_sky: GLTFEnvironmentSky = gltf_env_skies[sky_index]
	var node: Node = gltf_env_sky.to_node()
	root.add_child(node)
	node.owner = root
	for child in node.get_children():
		child.owner = root
	node.set_meta(&"GLTFEnvironmentSkies", gltf_env_skies)
	return OK


# Export process.
func _export_preflight(gltf_state: GLTFState, root: Node) -> Error:
	if export_environment:
		return OK
	return ERR_SKIP


func _convert_scene_node(gltf_state: GLTFState, gltf_node: GLTFNode, scene_node: Node) -> void:
	if scene_node is WorldEnvironment:
		var gltf_env_sky: GLTFEnvironmentSky = GLTFEnvironmentSky.from_node(scene_node)
		var gltf_env_skies: Array[GLTFEnvironmentSky] = [gltf_env_sky]
		gltf_state.set_additional_data(&"GLTFEnvironmentSkies", gltf_env_skies)
		# Exclude this node from export if it's a childless WorldEnvironment.
		if scene_node.get_child_count() == 0:
			gltf_node.parent = -2
			gltf_node.resource_name = &""


func _export_post_convert(gltf_state: GLTFState, root: Node) -> Error:
	var gltf_env_skies: Array[GLTFEnvironmentSky] = gltf_state.get_additional_data(&"GLTFEnvironmentSkies")
	for gltf_env_sky in gltf_env_skies:
		var pan_equirect: Texture2D = gltf_env_sky.panorama_equirectangular_texture
		if pan_equirect != null:
			var gltf_images: Array[Texture2D] = gltf_state.get_images()
			var image_index: int = gltf_images.size()
			gltf_images.append(pan_equirect)
			gltf_state.set_images(gltf_images)
			var pan_equirect_texture := GLTFTexture.new()
			pan_equirect_texture.src_image = image_index
			var gltf_textures: Array[GLTFTexture] = gltf_state.get_textures()
			var texture_index: int = gltf_textures.size()
			gltf_textures.append(pan_equirect_texture)
			gltf_state.set_textures(gltf_textures)
			gltf_env_sky.panorama_equirectangular_index = texture_index
	return OK


func _export_preserialize(gltf_state: GLTFState) -> Error:
	var gltf_env_skies: Array[GLTFEnvironmentSky] = gltf_state.get_additional_data(&"GLTFEnvironmentSkies")
	if not gltf_env_skies.is_empty():
		var engine_version: Dictionary = Engine.get_version_info()
		if engine_version["major"] == 4 and engine_version["minor"] < 4:
			# HACK: This should be run earlier, but Godot 4.3 doesn't have _export_post_convert.
			_export_post_convert(gltf_state, null)
		var sky_dicts: Array = []
		for gltf_env_sky in gltf_env_skies:
			sky_dicts.append(gltf_env_sky.to_dictionary())
		var env_sky_ext: Dictionary = { "skies": sky_dicts }
		var doc_extensions: Dictionary = gltf_state.json.get_or_add("extensions", {})
		doc_extensions["OMI_environment_sky"] = env_sky_ext
		gltf_state.add_used_extension("OMI_environment_sky", false)
	return OK


func _export_post(gltf_state: GLTFState) -> Error:
	var sky_index = gltf_state.get_additional_data(&"GLTFEnvironmentSkyIndex")
	if sky_index is int and sky_index != 0:
		var scenes: Array = gltf_state.json["scenes"]
		var scene_0: Dictionary = scenes[0]
		var scene_ext: Dictionary = scene_0.get_or_add("extensions", {})
		var scene_sky_ext: Dictionary = scene_ext.get_or_add("OMI_environment_sky", {})
		scene_sky_ext["sky"] = sky_index
	return OK
