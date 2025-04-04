@tool
class_name GLTFPhysicsJointLimit
extends Resource


## The indices of the linear axes which are limited, constraining the linear motion in 1, 2 or 3 dimensions. 1D keeps an object some distance from an infinite plane. 2D keeps an object some distance from an infinite line. 3D keeps an object some distance from a point. Can only contain 0 (X), 1 (Y), or 2 (Z), so [0, 1, 2] constrains all three axes.
@export_enum("X:0", "Y:1", "Z:2") var linear_axes: PackedInt32Array = []
## The indices of the angular axes which are limited, constraining the angular motion in 1, 2 or 3 dimensions. 1D limits rotation about one axis (e.g. a universal joint). 2D limits rotation about two axes (e.g. a cone). 3D limits rotation about all three axes. Can only contain 0 (X), 1 (Y), or 2 (Z), so [0, 1, 2] constrains all three axes.
@export_enum("X:0", "Y:1", "Z:2") var angular_axes: PackedInt32Array = []
## The minimum of the allowed range of relative distance in meters, or angle in radians.
@export var min: float = -INF
## The maximum of the allowed range of relative distance in meters, or angle in radians.
@export var max: float = INF
## The stiffness strength used to calculate a restorative force when the joint is extended beyond the limit.
@export var stiffness: float = INF
## Damping applied to the velocity when the joint is extended beyond the limit.
@export var damping: float = 0.0


func to_dictionary() -> Dictionary:
	var ret: Dictionary = {}
	if not linear_axes.is_empty():
		ret["linearAxes"] = linear_axes
	if not angular_axes.is_empty():
		ret["angularAxes"] = angular_axes
	if min != -INF:
		ret["min"] = min
	if max != INF:
		ret["max"] = max
	if stiffness != INF:
		ret["stiffness"] = stiffness
	if damping != 0.0:
		ret["damping"] = damping
	return ret


static func from_dictionary(joint_limit_dict: Dictionary) -> GLTFPhysicsJointLimit:
	var ret = GLTFPhysicsJointLimit.new()
	if joint_limit_dict.has("linearAxes"):
		var dict_axes: Array = joint_limit_dict["linearAxes"]
		for dict_axis in dict_axes:
			ret.linear_axes.append(int(dict_axis))
	if joint_limit_dict.has("angularAxes"):
		var dict_axes: Array = joint_limit_dict["angularAxes"]
		for dict_axis in dict_axes:
			ret.angular_axes.append(int(dict_axis))
	ret.min = joint_limit_dict.get("min", -INF)
	ret.max = joint_limit_dict.get("max", INF)
	if joint_limit_dict.has("stiffness"):
		ret.stiffness = joint_limit_dict["stiffness"]
		if ret.stiffness < 0.0:
			ret.stiffness = INF
	if joint_limit_dict.has("damping"):
		ret.damping = joint_limit_dict["damping"]
	return ret


func is_fixed_at_zero() -> bool:
	return is_zero_approx(min) and is_zero_approx(max)


func limits_equal_to(other: GLTFPhysicsJointLimit) -> bool:
	return ((is_nan(min) and is_nan(other.min)) or is_equal_approx(min, other.min)) \
			and ((is_nan(max) and is_nan(other.max)) or is_equal_approx(max, other.max)) \
			and is_equal_approx(stiffness, other.stiffness) \
			and is_equal_approx(damping, other.damping)


func is_equal_to(other: GLTFPhysicsJointLimit) -> bool:
	# Godot PackedInt32Array compares by value for the == operator.
	return limits_equal_to(other) \
			and linear_axes == other.linear_axes \
			and angular_axes == other.angular_axes
