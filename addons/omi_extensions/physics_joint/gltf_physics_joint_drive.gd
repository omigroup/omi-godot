@tool
class_name GLTFPhysicsJointDrive
extends Resource


## Determines the degree of freedom which this drive controls.
@export_enum("linear", "angular") var type: String = "linear"
## Specifies the force calculation mode.
@export_enum("force", "acceleration") var mode: String = "force"
## The index of the axis which this drive applies forces on.
@export_enum("X:0", "Y:1", "Z:2") var axis: int = 0
## The maximum force (or torque, for angular drives) the drive can apply. If not provided, this drive is not force-limited.
@export var max_force: float = INF
## The target translation/angle along the axis that this drive attempts to achieve. If NaN, the drive should not target a position.
@export var position_target: float = NAN
## The target velocity along/about the axis that this drive attempts to achieve. If NaN, the drive should not target a velocity.
@export var velocity_target: float = NAN
## The stiffness of the drive, scaling the force based on the position target.
@export var stiffness: float = 0.0
## The damping of the drive, scaling the force based on the velocity target.
@export var damping: float = 0.0


func to_dictionary() -> Dictionary:
	var ret: Dictionary = {}
	ret["type"] = type
	ret["mode"] = mode
	ret["axis"] = axis
	if max_force != 0.0:
		ret["maxForce"] = max_force
	if not is_nan(position_target):
		ret["positionTarget"] = position_target
	if not is_nan(velocity_target):
		ret["velocityTarget"] = velocity_target
	if stiffness != 0.0:
		ret["stiffness"] = stiffness
	if damping != 0.0:
		ret["damping"] = damping
	return ret


static func from_dictionary(joint_drive_dict: Dictionary) -> GLTFPhysicsJointDrive:
	var ret = GLTFPhysicsJointDrive.new()
	if joint_drive_dict.has("type"):
		ret.type = joint_drive_dict["type"]
	if joint_drive_dict.has("mode"):
		ret.mode = joint_drive_dict["mode"]
	if joint_drive_dict.has("axis"):
		ret.axis = joint_drive_dict["axis"]
	if joint_drive_dict.has("maxForce"):
		ret.max_force = joint_drive_dict["maxForce"]
		if ret.max_force < 0.0:
			ret.max_force = INF
	if joint_drive_dict.has("positionTarget"):
		ret.position_target = joint_drive_dict["positionTarget"]
	if joint_drive_dict.has("velocityTarget"):
		ret.velocity_target = joint_drive_dict["velocityTarget"]
	if joint_drive_dict.has("stiffness"):
		ret.stiffness = joint_drive_dict["stiffness"]
		if ret.stiffness < 0.0:
			ret.stiffness = INF
	if joint_drive_dict.has("damping"):
		ret.damping = joint_drive_dict["damping"]
	if ret.mode != "force":
		push_warning("glTF Physics Joint: Godot's joint motors only support force mode. The mode '" + ret.mode + "' will be ignored.")
	return ret


func is_equal_to(other: GLTFPhysicsJointDrive) -> bool:
	return type == other.type \
			and mode == other.mode \
			and axis == other.axis \
			and is_equal_approx(max_force, other.max_force) \
			and ((is_nan(position_target) and is_nan(other.position_target)) or is_equal_approx(position_target, other.position_target)) \
			and ((is_nan(velocity_target) and is_nan(other.velocity_target)) or is_equal_approx(velocity_target, other.velocity_target)) \
			and is_equal_approx(stiffness, other.stiffness) \
			and is_equal_approx(damping, other.damping)
