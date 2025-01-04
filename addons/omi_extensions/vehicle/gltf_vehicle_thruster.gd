@tool
class_name GLTFVehicleThruster
extends Resource


## The ratio of the maximum thrust force the thruster is currently using for propulsion.
@export_range(0.0, 1.0, 0.01)
var current_force_ratio: float = 0.0
## The ratio of the maximum gimbal angles the thruster is rotated to. The vector length may not be longer than 1.0.
@export var current_gimbal_ratio := Vector2(0.0, 0.0)
## The maximum thrust force in Newtons (kg⋅m/s²) that the thruster can provide.
@export_custom(PROPERTY_HINT_NONE, "suffix:kg\u22C5m/s\u00B2 (N)")
var max_force: float = 0.0
## The maximum angle the thruster can gimbal or rotate in radians.
@export_custom(PROPERTY_HINT_NONE, "suffix:rad")
var max_gimbal: float = 0.0


static func from_node(thruster_node: VehicleThruster3D) -> GLTFVehicleThruster:
	var ret := GLTFVehicleThruster.new()
	ret.current_force_ratio = thruster_node.current_force_ratio
	ret.current_gimbal_ratio = thruster_node.current_gimbal_ratio
	ret.max_force = thruster_node.max_force
	ret.max_gimbal = thruster_node.max_gimbal
	return ret


func to_node() -> VehicleThruster3D:
	var thruster_node := VehicleThruster3D.new()
	thruster_node.current_force_ratio = current_force_ratio
	thruster_node.current_gimbal_ratio = current_gimbal_ratio
	thruster_node.max_force = max_force
	thruster_node.max_gimbal = max_gimbal
	return thruster_node


static func from_dictionary(dict: Dictionary) -> GLTFVehicleThruster:
	var ret := GLTFVehicleThruster.new()
	if dict.has("currentForceRatio"):
		ret.current_force_ratio = dict["currentForceRatio"]
	if dict.has("currentGimbalRatio"):
		ret.current_gimbal_ratio = dict["currentGimbalRatio"]
	if dict.has("maxForce"):
		ret.max_force = dict["maxForce"]
	if dict.has("maxGimbal"):
		ret.max_gimbal = dict["maxGimbal"]
	return ret


func to_dictionary() -> Dictionary:
	var ret: Dictionary = {}
	ret["maxForce"] = max_force
	if current_force_ratio != 0.0:
		ret["currentForceRatio"] = current_force_ratio
	if current_gimbal_ratio != Vector2.ZERO:
		ret["currentGimbalRatio"] = current_gimbal_ratio
	if max_gimbal != 0.0:
		ret["maxGimbal"] = max_gimbal
	return ret
