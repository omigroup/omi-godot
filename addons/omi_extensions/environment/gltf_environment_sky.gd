@tool
class_name GLTFEnvironmentSky
extends Resource


var ambient_color := Color.BLACK
var ambient_sky_contribution: float = 1.0
var type: String

var gradient_bottom_color := Color(0.2, 0.169, 0.133)
var gradient_bottom_curve: float = 0.02
var gradient_horizon_color := Color(0.646, 0.656, 0.671)
var gradient_top_color := Color(0.385, 0.454, 0.55)
var gradient_top_curve: float = 0.15
var gradient_sun_angle_max: float = 0.5
var gradient_sun_curve: float = 0.15

var panorama_cubemap_indices := PackedInt32Array()
var panorama_cubemap_textures: Array[Texture2D] = []
var panorama_equirectangular_index: int = -1
var panorama_equirectangular_texture: Texture2D = null

var physical_ground_color := Color(0.3, 0.2, 0.1)
var physical_mie_color := Color.WHITE
var physical_mie_scale: float = 0.000005
var physical_mie_anisotropy: float = 0.8
var physical_rayleigh_color := Color(0.3, 0.5, 1.0)
var physical_rayleigh_scale: float = 0.00003

var plain_color := Color.BLACK


static func from_dictionary(dict: Dictionary) -> GLTFEnvironmentSky:
	var ret := GLTFEnvironmentSky.new()
	if dict.has("type"):
		ret.type = dict["type"]
	else:
		printerr("GLTFEnvironmentSky: Missing required field 'type'. An empty environment sky will be created.")
	if dict.has("ambientColor"):
		var ambient_color: Array = dict["ambientColor"]
		ret.ambient_color = Color(ambient_color[0], ambient_color[1], ambient_color[2])
	if dict.has("ambientSkyContribution"):
		ret.ambient_sky_contribution = dict["ambientSkyContribution"]
	if dict.has("gradient"):
		var gradient: Dictionary = dict["gradient"]
		if gradient.has("bottomColor"):
			var bottom_color: Array = gradient["bottomColor"]
			ret.gradient_bottom_color = Color(bottom_color[0], bottom_color[1], bottom_color[2])
		if gradient.has("bottomCurve"):
			ret.gradient_bottom_curve = gradient["bottomCurve"]
		if gradient.has("horizonColor"):
			var horizon_color: Array = gradient["horizonColor"]
			ret.gradient_horizon_color = Color(horizon_color[0], horizon_color[1], horizon_color[2])
		if gradient.has("topColor"):
			var top_color: Array = gradient["topColor"]
			ret.gradient_top_color = Color(top_color[0], top_color[1], top_color[2])
		if gradient.has("topCurve"):
			ret.gradient_top_curve = gradient["topCurve"]
		if gradient.has("sunAngleMax"):
			ret.gradient_sun_angle_max = gradient["sunAngleMax"]
		if gradient.has("sunCurve"):
			ret.gradient_sun_curve = gradient["sunCurve"]
	if dict.has("panorama"):
		var panorama: Dictionary = dict["panorama"]
		if panorama.has("cubemap"):
			var cubemap_indices: Array = panorama["cubemap"]
			ret.panorama_cubemap_indices.resize(cubemap_indices.size())
			ret.panorama_cubemap_textures.resize(cubemap_indices.size())
			for i in range(cubemap_indices.size()):
				ret.panorama_cubemap_indices.set(i, cubemap_indices[i])
		if panorama.has("equirectangular"):
			ret.panorama_equirectangular_index = panorama["equirectangular"]
	if dict.has("physical"):
		var physical: Dictionary = dict["physical"]
		if physical.has("groundColor"):
			var ground_color: Array = physical["groundColor"]
			ret.physical_ground_color = Color(ground_color[0], ground_color[1], ground_color[2])
		if physical.has("mieAnisotropy"):
			ret.physical_mie_anisotropy = physical["mieAnisotropy"]
		if physical.has("mieColor"):
			var mie_color: Array = physical["mieColor"]
			ret.physical_mie_color = Color(mie_color[0], mie_color[1], mie_color[2])
		if physical.has("mieScale"):
			ret.physical_mie_scale = physical["mieScale"]
		if physical.has("rayleighColor"):
			var rayleigh_color: Array = physical["rayleighColor"]
			ret.physical_rayleigh_color = Color(rayleigh_color[0], rayleigh_color[1], rayleigh_color[2])
		if physical.has("rayleighScale"):
			ret.physical_rayleigh_scale = physical["rayleighScale"]
	if dict.has("plain"):
		var plain: Dictionary = dict["plain"]
		if plain.has("color"):
			var color: Array = plain["color"]
			ret.plain_color = Color(color[0], color[1], color[2])
	return ret


func to_dictionary() -> Dictionary:
	var ret: Dictionary = {
		"type": type,
	}
	if ambient_color != Color.BLACK:
		ret["ambientColor"] = [ambient_color.r, ambient_color.g, ambient_color.b]
	if ambient_sky_contribution != 1.0:
		ret["ambientSkyContribution"] = ambient_sky_contribution
	match type:
		"gradient":
			var gradient = {
				"bottomColor": [gradient_bottom_color.r, gradient_bottom_color.g, gradient_bottom_color.b],
				"horizonColor": [gradient_horizon_color.r, gradient_horizon_color.g, gradient_horizon_color.b],
				"topColor": [gradient_top_color.r, gradient_top_color.g, gradient_top_color.b],
			}
			if gradient_bottom_curve != 0.02:
				gradient["bottomCurve"] = gradient_bottom_curve
			if gradient_top_curve != 0.15:
				gradient["topCurve"] = gradient_top_curve
			if gradient_sun_angle_max != 0.5:
				gradient["sunAngleMax"] = gradient_sun_angle_max
			if gradient_sun_curve != 0.15:
				gradient["sunCurve"] = gradient_sun_curve
			var engine_version: Dictionary = Engine.get_version_info()
			if not (engine_version["major"] == 4 and engine_version["minor"] < 4):
				# HACK: Godot 4.3 and earlier does not have sort().
				gradient.sort()
			ret["gradient"] = gradient
		"panorama":
			var panorama: Dictionary = {}
			if panorama_cubemap_indices.size() > 0:
				panorama["cubemap"] = panorama_cubemap_indices
			if panorama_equirectangular_index != -1:
				panorama["equirectangular"] = panorama_equirectangular_index
			ret["panorama"] = panorama
		"physical":
			var physical: Dictionary = {}
			if physical_ground_color != Color(0.3, 0.2, 0.1):
				physical["groundColor"] = [physical_ground_color.r, physical_ground_color.g, physical_ground_color.b]
			if physical_mie_anisotropy != 0.8:
				physical["mieAnisotropy"] = physical_mie_anisotropy
			if physical_mie_color != Color.WHITE:
				physical["mieColor"] = [physical_mie_color.r, physical_mie_color.g, physical_mie_color.b]
			if physical_mie_scale != 0.000005:
				physical["mieScale"] = physical_mie_scale
			if physical_rayleigh_color != Color(0.3, 0.5, 1.0):
				physical["rayleighColor"] = [physical_rayleigh_color.r, physical_rayleigh_color.g, physical_rayleigh_color.b]
			if physical_rayleigh_scale != 0.00003:
				physical["rayleighScale"] = physical_rayleigh_scale
			ret["physical"] = physical
		"plain":
			if plain_color != Color.BLACK:
				ret["plain"] = {"color": [plain_color.r, plain_color.g, plain_color.b]}
	return ret


static func from_environment(env: Environment) -> GLTFEnvironmentSky:
	var ret := GLTFEnvironmentSky.new()
	ret.ambient_color = env.ambient_light_color
	ret.ambient_sky_contribution = env.ambient_light_sky_contribution
	var bg_mode: Environment.BGMode = env.background_mode
	match bg_mode:
		Environment.BG_CLEAR_COLOR:
			ret.type = "plain"
			ret.plain_color = ProjectSettings.get_setting("rendering/environment/defaults/default_clear_color", Color())
			return ret
		Environment.BG_COLOR:
			ret.type = "plain"
			ret.plain_color = env.background_color
			return ret
	var sky: Sky = env.sky
	if sky == null:
		return ret
	var sky_material: Material = sky.sky_material
	if sky_material is ProceduralSkyMaterial:
		ret.type = "gradient"
		var procedural_sky: ProceduralSkyMaterial = sky_material
		ret.gradient_bottom_color = procedural_sky.ground_bottom_color
		ret.gradient_bottom_curve = procedural_sky.ground_curve
		ret.gradient_horizon_color = procedural_sky.ground_horizon_color
		ret.gradient_top_color = procedural_sky.sky_top_color
		ret.gradient_top_curve = procedural_sky.sky_curve
		ret.gradient_sun_angle_max = deg_to_rad(procedural_sky.sun_angle_max)
		ret.gradient_sun_curve = procedural_sky.sun_curve
	elif sky_material is PanoramaSkyMaterial:
		ret.type = "panorama"
		var panorama_sky: PanoramaSkyMaterial = sky_material
		if panorama_sky.panorama != null and panorama_sky.panorama.resource_name.is_empty():
			panorama_sky.panorama.resource_name = panorama_sky.panorama.resource_path.get_file().get_basename()
		ret.panorama_equirectangular_texture = panorama_sky.panorama
	elif sky_material is PhysicalSkyMaterial:
		ret.type = "physical"
		var physical_sky: PhysicalSkyMaterial = sky_material
		ret.physical_ground_color = physical_sky.ground_color
		ret.physical_mie_anisotropy = physical_sky.mie_eccentricity
		ret.physical_mie_color = physical_sky.mie_color
		ret.physical_mie_scale = physical_sky.mie_coefficient / 1000
		ret.physical_rayleigh_color = physical_sky.rayleigh_color
		ret.physical_rayleigh_scale = physical_sky.rayleigh_coefficient / 100000
	return ret


func to_environment() -> Environment:
	var ret := Environment.new()
	# Set up the environment with the defaults from the editor environment.
	ret.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	ret.glow_enabled = true
	# Set up the environment with the sky settings from this environment.
	ret.ambient_light_color = ambient_color
	ret.ambient_light_sky_contribution = ambient_sky_contribution
	var sky := Sky.new()
	match type:
		"gradient":
			var procedural_sky := ProceduralSkyMaterial.new()
			procedural_sky.ground_bottom_color = gradient_bottom_color
			procedural_sky.ground_curve = gradient_bottom_curve
			procedural_sky.ground_horizon_color = gradient_horizon_color
			procedural_sky.sky_horizon_color = gradient_horizon_color
			procedural_sky.sky_top_color = gradient_top_color
			procedural_sky.sky_curve = gradient_top_curve
			procedural_sky.sun_angle_max = rad_to_deg(gradient_sun_angle_max)
			procedural_sky.sun_curve = gradient_sun_curve
			sky.sky_material = procedural_sky
		"panorama":
			var panorama_sky := PanoramaSkyMaterial.new()
			panorama_sky.panorama = panorama_equirectangular_texture
			sky.sky_material = panorama_sky
		"physical":
			var physical_sky := PhysicalSkyMaterial.new()
			physical_sky.ground_color = physical_ground_color
			physical_sky.mie_eccentricity = physical_mie_anisotropy
			physical_sky.mie_color = physical_mie_color
			physical_sky.mie_coefficient = physical_mie_scale * 1000
			physical_sky.rayleigh_color = physical_rayleigh_color
			physical_sky.rayleigh_coefficient = physical_rayleigh_scale * 100000
			sky.sky_material = physical_sky
		"plain":
			ret.background_mode = Environment.BG_COLOR
			ret.background_color = plain_color
			return ret
	ret.background_mode = Environment.BG_SKY
	ret.sky = sky
	return ret


static func from_node(node: WorldEnvironment) -> GLTFEnvironmentSky:
	if node != null and node.environment != null:
		return from_environment(node.environment)
	return null


func to_node() -> Node:
	var world_env := WorldEnvironment.new()
	world_env.name = &"WorldEnvironment"
	world_env.environment = to_environment()
	if panorama_cubemap_textures.size() >= 6:
		var cubemap_mi: CubemapSky3D = _make_cubemap_mesh()
		cubemap_mi.set_skybox_textures(panorama_cubemap_textures)
		cubemap_mi.add_child(world_env)
		return cubemap_mi
	return world_env


func _make_cubemap_mesh() -> CubemapSky3D:
	var mesh_instance := CubemapSky3D.new()
	mesh_instance.name = &"CubemapSky3D"
	return mesh_instance
