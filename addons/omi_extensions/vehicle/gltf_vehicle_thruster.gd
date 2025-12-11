@tool
class_name GLTFVehicleThruster
extends Resource


# Gimbal
## The maximum angle the thruster can gimbal or rotate in radians.
@export_custom(PROPERTY_HINT_NONE, "suffix:rad")
var max_gimbal_radians: float = 0.0
## Optionally, you may also want to allow the gimbal to be adjusted based on linear input.
## For example, if the user wants to go forward, and the thruster points downward,
## we can gimbal the thruster slightly backward to help thrust forward.
@export_range(0.0, 1.0, 0.01)
var linear_gimbal_adjust_ratio: float = 0.0
## The speed at which the gimbal angle changes, in radians per second. If negative, the angle changes instantly.
@export_custom(PROPERTY_HINT_NONE, "suffix:rad/s")
var gimbal_radians_per_second: float = 1.0
## The ratio of the maximum gimbal angles the thruster is targeting to be rotated to. The vector length may not be longer than 1.0.
@export var target_gimbal_ratio := Vector2(0.0, 0.0)

# Thrust Force
## The maximum thrust force in Newtons (kg⋅m/s²) that the thruster can provide.
@export_custom(PROPERTY_HINT_NONE, "suffix:kg\u22C5m/s\u00B2 (N)")
var max_force: float = 0.0
## The speed at which the thruster force changes, in Newtons per second. If negative, the force changes instantly.
@export_custom(PROPERTY_HINT_NONE, "suffix:N/s (kg\u22C5m/s\u00B3)")
var force_change_per_second: float = -1.0
## The ratio of the maximum thrust force the thruster is targeting for propulsion.
@export_range(0.0, 1.0, 0.01)
var target_force_ratio: float = 0.0


static func from_node(thruster_node: VehicleThruster3D) -> GLTFVehicleThruster:
	var ret := GLTFVehicleThruster.new()
	# Gimbal
	ret.max_gimbal_radians = thruster_node.max_gimbal_radians
	ret.linear_gimbal_adjust_ratio = thruster_node.linear_gimbal_adjust_ratio
	ret.gimbal_radians_per_second = thruster_node.gimbal_radians_per_second
	ret.target_gimbal_ratio = thruster_node.target_gimbal_ratio
	# Thrust Force
	ret.max_force = thruster_node.max_force
	ret.force_change_per_second = thruster_node.force_change_per_second
	ret.target_force_ratio = thruster_node.target_force_ratio
	return ret


func to_node() -> VehicleThruster3D:
	var thruster_node := VehicleThruster3D.new()
	# Gimbal
	thruster_node.max_gimbal_radians = max_gimbal_radians
	thruster_node.linear_gimbal_adjust_ratio = linear_gimbal_adjust_ratio
	thruster_node.gimbal_radians_per_second = gimbal_radians_per_second
	thruster_node.target_gimbal_ratio = target_gimbal_ratio
	# Thrust Force
	thruster_node.max_force = max_force
	thruster_node.force_change_per_second = force_change_per_second
	thruster_node.target_force_ratio = target_force_ratio
	return thruster_node


static func from_dictionary(dict: Dictionary) -> GLTFVehicleThruster:
	var ret := GLTFVehicleThruster.new()
	# Gimbal
	if dict.has("maxGimbal"):
		ret.max_gimbal_radians = dict["maxGimbal"]
	if dict.has("linearGimbalAdjustRatio"):
		ret.linear_gimbal_adjust_ratio = dict["linearGimbalAdjustRatio"]
	if dict.has("gimbalChangeRate"):
		ret.gimbal_radians_per_second = dict["gimbalChangeRate"]
	if dict.has("targetGimbalRatio"):
		ret.target_gimbal_ratio = dict["targetGimbalRatio"]
	# Thrust Force
	if dict.has("maxForce"):
		ret.max_force = dict["maxForce"]
	if dict.has("forceChangeRate"):
		ret.force_change_per_second = dict["forceChangeRate"]
	if dict.has("targetForceRatio"):
		ret.target_force_ratio = dict["targetForceRatio"]
	return ret


func to_dictionary() -> Dictionary:
	var ret: Dictionary = {}
	# Alphabetical order when converting to Dictionary.
	if force_change_per_second != -1.0:
		ret["forceChangeRate"] = force_change_per_second
	if gimbal_radians_per_second != 1.0:
		ret["gimbalChangeRate"] = gimbal_radians_per_second
	if linear_gimbal_adjust_ratio != 0.0:
		ret["linearGimbalAdjustRatio"] = linear_gimbal_adjust_ratio
	# Always include maxForce since it is a required property for thrusters.
	ret["maxForce"] = max_force
	if max_gimbal_radians != 0.0:
		ret["maxGimbal"] = max_gimbal_radians
	if target_force_ratio != 0.0:
		ret["targetForceRatio"] = target_force_ratio
	if target_gimbal_ratio != Vector2.ZERO:
		ret["targetGimbalRatio"] = target_gimbal_ratio
	return ret
