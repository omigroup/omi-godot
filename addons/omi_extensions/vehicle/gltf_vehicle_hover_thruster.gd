@tool
class_name GLTFVehicleHoverThruster
extends Resource


# Gimbal
## The maximum angle the hover thruster can gimbal or rotate in radians.
@export_custom(PROPERTY_HINT_NONE, "suffix:rad")
var max_gimbal_radians: float = 0.0
## Optionally, you may also want to allow the gimbal to be adjusted based on linear input.
## For example, if the user wants to go forward, and the thruster points downward,
## we can gimbal the thruster slightly backward to help thrust forward.
@export_range(0.0, 1.0, 0.01)
var linear_gimbal_adjust_ratio: float = 0.5
## The speed at which the gimbal angle changes, in radians per second. If negative, the angle changes instantly.
@export_custom(PROPERTY_HINT_NONE, "suffix:rad/s")
var gimbal_radians_per_second: float = 1.0
## The ratio of the maximum gimbal angles the hover thruster is targeting to be rotated to. The vector length may not be longer than 1.0.
@export var target_gimbal_ratio := Vector2(0.0, 0.0)

# Hover Thrust
## The maximum hover energy in Newton-meters (N⋅m or kg⋅m²/s²) that the hover thruster can provide.
@export_custom(PROPERTY_HINT_NONE, "suffix:kg\u22C5m\u00B2/s\u00B2 (N\u22C5m)")
var max_hover_energy: float = 0.0
## The speed at which the hover energy changes, in Newtons-meters per second. If negative, the force changes instantly.
@export_custom(PROPERTY_HINT_NONE, "suffix:N\u22C5m/s (kg\u22C5m\u00B2/s\u00B3)")
var hover_energy_change_per_second: float = -1.0
## The ratio of the maximum hover energy the hover thruster is targeting for propulsion.
@export_range(0.0, 1.0, 0.01)
var target_hover_ratio: float = 0.0


static func from_node(thruster_node: VehicleHoverThruster3D) -> GLTFVehicleHoverThruster:
	var ret := GLTFVehicleHoverThruster.new()
	# Gimbal
	ret.max_gimbal_radians = thruster_node.max_gimbal_radians
	ret.linear_gimbal_adjust_ratio = thruster_node.linear_gimbal_adjust_ratio
	ret.gimbal_radians_per_second = thruster_node.gimbal_radians_per_second
	ret.target_gimbal_ratio = thruster_node.target_gimbal_ratio
	# Hover Thrust
	ret.max_hover_energy = thruster_node.max_hover_energy
	ret.hover_energy_change_per_second = thruster_node.hover_energy_change_per_second
	ret.target_hover_ratio = thruster_node.target_hover_ratio
	return ret


func to_node() -> VehicleHoverThruster3D:
	var thruster_node := VehicleHoverThruster3D.new()
	# Gimbal
	thruster_node.max_gimbal_radians = max_gimbal_radians
	thruster_node.linear_gimbal_adjust_ratio = linear_gimbal_adjust_ratio
	thruster_node.gimbal_radians_per_second = gimbal_radians_per_second
	thruster_node.target_gimbal_ratio = target_gimbal_ratio
	# Hover Thrust
	thruster_node.max_hover_energy = max_hover_energy
	thruster_node.hover_energy_change_per_second = hover_energy_change_per_second
	thruster_node.target_hover_ratio = target_hover_ratio
	return thruster_node


static func from_dictionary(dict: Dictionary) -> GLTFVehicleHoverThruster:
	var ret := GLTFVehicleHoverThruster.new()
	# Gimbal
	if dict.has("maxGimbal"):
		ret.max_gimbal_radians = dict["maxGimbal"]
	if dict.has("linearGimbalAdjustRatio"):
		ret.linear_gimbal_adjust_ratio = dict["linearGimbalAdjustRatio"]
	if dict.has("gimbalChangeRate"):
		ret.gimbal_radians_per_second = dict["gimbalChangeRate"]
	if dict.has("targetGimbalRatio"):
		ret.target_gimbal_ratio = dict["targetGimbalRatio"]
	# Hover Thrust
	if dict.has("maxHoverEnergy"):
		ret.max_hover_energy = dict["maxHoverEnergy"]
	if dict.has("hoverEnergyChangeRate"):
		ret.hover_energy_change_per_second = dict["hoverEnergyChangeRate"]
	if dict.has("targetHoverRatio"):
		ret.target_hover_ratio = dict["targetHoverRatio"]
	return ret


func to_dictionary() -> Dictionary:
	var ret: Dictionary = {}
	# Alphabetical order when converting to Dictionary.
	if gimbal_radians_per_second != 1.0:
		ret["gimbalChangeRate"] = gimbal_radians_per_second
	if hover_energy_change_per_second != -1.0:
		ret["hoverEnergyChangeRate"] = hover_energy_change_per_second
	if linear_gimbal_adjust_ratio != 0.5:
		ret["linearGimbalAdjustRatio"] = linear_gimbal_adjust_ratio
	if max_gimbal_radians != 0.0:
		ret["maxGimbal"] = max_gimbal_radians
	# Always include maxHoverEnergy since it is a required property for hover thrusters.
	ret["maxHoverEnergy"] = max_hover_energy
	if target_gimbal_ratio != Vector2.ZERO:
		ret["targetGimbalRatio"] = target_gimbal_ratio
	if target_hover_ratio != 0.0:
		ret["targetHoverRatio"] = target_hover_ratio
	return ret
