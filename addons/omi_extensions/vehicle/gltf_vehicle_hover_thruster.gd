@tool
class_name GLTFVehicleHoverThruster
extends Resource


## The ratio of the maximum hover energy the hover thruster is currently using for propulsion.
@export_range(0.0, 1.0, 0.01)
var current_hover_ratio: float = 0.0
## The ratio of the maximum gimbal angles the hover thruster is rotated to. The vector length may not be longer than 1.0.
@export var current_gimbal_ratio := Vector2(0.0, 0.0)
## The maximum hover energy in Newton-meters (N⋅m or kg⋅m²/s²) that the hover thruster can provide.
@export_custom(PROPERTY_HINT_NONE, "suffix:kg\u22C5m\u00B2/s\u00B2 (N\u22C5m)")
var max_hover_energy: float = 0.0
## The maximum angle the hover thruster can gimbal or rotate in radians.
@export_custom(PROPERTY_HINT_NONE, "suffix:rad")
var max_gimbal: float = 0.0


static func from_node(thruster_node: VehicleHoverThruster3D) -> GLTFVehicleHoverThruster:
	var ret := GLTFVehicleHoverThruster.new()
	ret.current_hover_ratio = thruster_node.current_hover_ratio
	ret.current_gimbal_ratio = thruster_node.current_gimbal_ratio
	ret.max_hover_energy = thruster_node.max_hover_energy
	ret.max_gimbal = thruster_node.max_gimbal
	return ret


func to_node() -> VehicleHoverThruster3D:
	var thruster_node := VehicleHoverThruster3D.new()
	thruster_node.current_hover_ratio = current_hover_ratio
	thruster_node.current_gimbal_ratio = current_gimbal_ratio
	thruster_node.max_hover_energy = max_hover_energy
	thruster_node.max_gimbal = max_gimbal
	return thruster_node


static func from_dictionary(dict: Dictionary) -> GLTFVehicleHoverThruster:
	var ret := GLTFVehicleHoverThruster.new()
	if dict.has("currentHoverRatio"):
		ret.current_force_ratio = dict["currentHoverRatio"]
	if dict.has("currentGimbalRatio"):
		ret.current_gimbal_ratio = dict["currentGimbalRatio"]
	if dict.has("maxHoverEnergy"):
		ret.max_hover_energy = dict["maxHoverEnergy"]
	if dict.has("maxGimbal"):
		ret.max_gimbal = dict["maxGimbal"]
	return ret


func to_dictionary() -> Dictionary:
	var ret: Dictionary = {}
	ret["maxHoverEnergy"] = max_hover_energy
	if current_hover_ratio != 0.0:
		ret["currentHoverRatio"] = current_hover_ratio
	if current_gimbal_ratio != Vector2.ZERO:
		ret["currentGimbalRatio"] = current_gimbal_ratio
	if max_gimbal != 0.0:
		ret["maxGimbal"] = max_gimbal
	return ret
