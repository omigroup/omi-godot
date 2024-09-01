@tool
class_name GLTFPhysicsJointSettings
extends Resource


## The limits get serialized to an array of dictionaries in glTF,
## but for runtime convenience, we store them as separate variables.
var limit_linear_x: GLTFPhysicsJointLimit = null
var limit_linear_y: GLTFPhysicsJointLimit = null
var limit_linear_z: GLTFPhysicsJointLimit = null
var limit_angular_x: GLTFPhysicsJointLimit = null
var limit_angular_y: GLTFPhysicsJointLimit = null
var limit_angular_z: GLTFPhysicsJointLimit = null

## Drives/motors are the same, they get serialized to an array in glTF,
## but for for runtime convenience, we store them as separate variables.
var drive_linear_x: GLTFPhysicsJointDrive = null
var drive_linear_y: GLTFPhysicsJointDrive = null
var drive_linear_z: GLTFPhysicsJointDrive = null
var drive_angular_x: GLTFPhysicsJointDrive = null
var drive_angular_y: GLTFPhysicsJointDrive = null
var drive_angular_z: GLTFPhysicsJointDrive = null


func to_dictionary() -> Dictionary:
	var ret: Dictionary = {}
	var limits: Array[GLTFPhysicsJointLimit] = get_limits()
	if limits.size() > 0:
		var limit_dicts: Array = []
		for limit in limits:
			limit_dicts.append(limit.to_dictionary())
		ret["limits"] = limit_dicts
	var drives: Array[GLTFPhysicsJointDrive] = get_drives()
	if drives.size() > 0:
		var drive_dicts: Array = []
		for drive in drives:
			drive_dicts.append(drive.to_dictionary())
		ret["drives"] = drive_dicts
	return ret


func to_node() -> Joint3D:
	if limit_linear_x != null and limit_linear_x.is_fixed_at_zero() \
			and limit_linear_y != null and limit_linear_y.is_fixed_at_zero() \
			and limit_linear_z != null and limit_linear_z.is_fixed_at_zero() \
			and drive_linear_x == null and drive_linear_y == null and drive_linear_z == null \
			and drive_angular_x == null and drive_angular_y == null:
		# Linearly fixed at zero, and no drives except maybe angular Z, so it could be a pin or hinge.
		if limit_angular_x == null and limit_angular_y == null and limit_angular_z == null and drive_angular_z == null:
			# No angular constraint or drive, so this is a pin joint.
			var pin = PinJoint3D.new()
			# Calculate values that will not cause Godot's physics engine to explode.
			var bias = (limit_linear_x.stiffness + limit_linear_y.stiffness + limit_linear_z.stiffness) / 6.0
			pin.set_param(PinJoint3D.PARAM_BIAS, clamp(bias, 0.01, 0.99))
			var damping: float = (limit_linear_x.damping + limit_linear_y.damping + limit_linear_z.damping) / 3.0
			pin.set_param(PinJoint3D.PARAM_DAMPING, clamp(damping, bias * 0.51, 2.0))
			return pin
		if limit_angular_x != null and limit_angular_x.is_fixed_at_zero() \
				and limit_angular_y != null and limit_angular_y.is_fixed_at_zero() \
				and limit_angular_x.limits_equal_to(limit_angular_y) \
				and (limit_angular_z == null or not limit_angular_z.is_fixed_at_zero()):
			# Angular X and Y are equally fixed at zero, Z is not, so this is a hinge joint.
			var hinge = HingeJoint3D.new()
			if limit_angular_z != null:
				hinge.set_flag(HingeJoint3D.FLAG_USE_LIMIT, true)
				hinge.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, limit_angular_z.min)
				hinge.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, limit_angular_z.max)
				hinge.set_param(HingeJoint3D.PARAM_LIMIT_SOFTNESS, limit_angular_z.stiffness)
				hinge.set_param(HingeJoint3D.PARAM_LIMIT_RELAXATION, 1.0 / limit_angular_z.damping)
			if drive_angular_z != null:
				hinge.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)
				hinge.set_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE, drive_angular_z.max_force)
				hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, drive_angular_z.velocity_target)
			return hinge
	if limit_linear_y != null and limit_linear_y.is_fixed_at_zero() \
			and limit_linear_z != null and limit_linear_z.is_fixed_at_zero() \
			and limit_linear_y.limits_equal_to(limit_linear_z) \
			and limit_angular_y != null and limit_angular_y.is_fixed_at_zero() \
			and limit_angular_z != null and limit_angular_z.is_fixed_at_zero() \
			and limit_angular_y.limits_equal_to(limit_angular_z) \
			and (limit_angular_x == null or not limit_angular_x.is_fixed_at_zero() \
				or limit_linear_x == null or not limit_linear_x.is_fixed_at_zero()) \
			and drive_linear_x == null and drive_angular_x == null \
			and drive_linear_y == null and drive_angular_y == null \
			and drive_linear_z == null and drive_angular_z == null:
		# The only free axes are the linear and/or angular X, and there are no drives, so this looks like a Slider.
		var slider = SliderJoint3D.new()
		if limit_linear_x == null:
			# In Godot's Slider joint, the lower limit being higher than the upper limit means unconstrained.
			slider.set_param(SliderJoint3D.PARAM_LINEAR_LIMIT_LOWER, 1.0)
			slider.set_param(SliderJoint3D.PARAM_LINEAR_LIMIT_UPPER, -1.0)
		else:
			slider.set_param(SliderJoint3D.PARAM_LINEAR_LIMIT_LOWER, limit_linear_x.min)
			slider.set_param(SliderJoint3D.PARAM_LINEAR_LIMIT_UPPER, limit_linear_x.max)
			slider.set_param(SliderJoint3D.PARAM_LINEAR_LIMIT_SOFTNESS, limit_linear_x.stiffness)
			slider.set_param(SliderJoint3D.PARAM_LINEAR_LIMIT_DAMPING, limit_linear_x.damping)
		slider.set_param(SliderJoint3D.PARAM_LINEAR_ORTHOGONAL_SOFTNESS, limit_linear_y.stiffness)
		slider.set_param(SliderJoint3D.PARAM_LINEAR_ORTHOGONAL_DAMPING, limit_linear_y.damping)
		if limit_angular_x == null:
			# In Godot's Slider joint, the lower limit being higher than the upper limit means unconstrained.
			slider.set_param(SliderJoint3D.PARAM_ANGULAR_LIMIT_LOWER, 1.0)
			slider.set_param(SliderJoint3D.PARAM_ANGULAR_LIMIT_UPPER, -1.0)
		else:
			slider.set_param(SliderJoint3D.PARAM_ANGULAR_LIMIT_LOWER, limit_angular_x.min)
			slider.set_param(SliderJoint3D.PARAM_ANGULAR_LIMIT_UPPER, limit_angular_x.max)
			slider.set_param(SliderJoint3D.PARAM_ANGULAR_LIMIT_SOFTNESS, limit_angular_x.stiffness)
			slider.set_param(SliderJoint3D.PARAM_ANGULAR_LIMIT_DAMPING, limit_angular_x.damping)
		slider.set_param(SliderJoint3D.PARAM_ANGULAR_ORTHOGONAL_SOFTNESS, limit_angular_y.stiffness)
		slider.set_param(SliderJoint3D.PARAM_ANGULAR_ORTHOGONAL_DAMPING, limit_angular_y.damping)
		return slider
	# If none of the special-purpose joints apply, use the generic one.
	return to_generic_joint_node()


func get_drives() -> Array[GLTFPhysicsJointDrive]:
	var ret: Array[GLTFPhysicsJointDrive] = []
	if drive_linear_x != null:
		ret.append(drive_linear_x)
	if drive_linear_y != null and not drive_linear_y in ret:
		ret.append(drive_linear_y)
	if drive_linear_z != null and not drive_linear_z in ret:
		ret.append(drive_linear_z)
	if drive_angular_x != null and not drive_angular_x in ret:
		ret.append(drive_angular_x)
	if drive_angular_y != null and not drive_angular_y in ret:
		ret.append(drive_angular_y)
	if drive_angular_z != null and not drive_angular_z in ret:
		ret.append(drive_angular_z)
	return ret


func get_limits() -> Array[GLTFPhysicsJointLimit]:
	var ret: Array[GLTFPhysicsJointLimit] = []
	if limit_linear_x != null:
		ret.append(limit_linear_x)
	if limit_linear_y != null and not limit_linear_y in ret:
		ret.append(limit_linear_y)
	if limit_linear_z != null and not limit_linear_z in ret:
		ret.append(limit_linear_z)
	if limit_angular_x != null and not limit_angular_x in ret:
		ret.append(limit_angular_x)
	if limit_angular_y != null and not limit_angular_y in ret:
		ret.append(limit_angular_y)
	if limit_angular_z != null and not limit_angular_z in ret:
		ret.append(limit_angular_z)
	return ret


static func from_dictionary(joint_settings_dict: Dictionary) -> GLTFPhysicsJointSettings:
	var ret := GLTFPhysicsJointSettings.new()
	if joint_settings_dict.has("limits"):
		var limit_dicts: Array = joint_settings_dict["limits"]
		for limit_dict in limit_dicts:
			var limit := GLTFPhysicsJointLimit.from_dictionary(limit_dict)
			for axis in limit.linear_axes:
				if axis == 0:
					ret.limit_linear_x = limit
				elif axis == 1:
					ret.limit_linear_y = limit
				elif axis == 2:
					ret.limit_linear_z = limit
			for axis in limit.angular_axes:
				if axis == 0:
					ret.limit_angular_x = limit
				elif axis == 1:
					ret.limit_angular_y = limit
				elif axis == 2:
					ret.limit_angular_z = limit
	if joint_settings_dict.has("drives"):
		var drive_dicts: Array = joint_settings_dict["drives"]
		for drive_dict in drive_dicts:
			var drive := GLTFPhysicsJointDrive.from_dictionary(drive_dict)
			if drive.type == "linear":
				if drive.axis == 0:
					ret.drive_linear_x = drive
				elif drive.axis == 1:
					ret.drive_linear_y = drive
				elif drive.axis == 2:
					ret.drive_linear_z = drive
			elif drive.type == "angular":
				if drive.axis == 0:
					ret.drive_angular_x = drive
				elif drive.axis == 1:
					ret.drive_angular_y = drive
				elif drive.axis == 2:
					ret.drive_angular_z = drive
	return ret


static func from_node(godot_joint: Joint3D) -> GLTFPhysicsJointSettings:
	# We need different code for each type of Godot joint we want to convert.
	if godot_joint is Generic6DOFJoint3D:
		return _from_generic_joint_node(godot_joint)
	elif godot_joint is PinJoint3D:
		return _from_pin_joint_node(godot_joint)
	elif godot_joint is HingeJoint3D:
		return _from_hinge_joint_node(godot_joint)
	elif godot_joint is SliderJoint3D:
		return _from_slider_joint_node(godot_joint)
	elif godot_joint is ConeTwistJoint3D:
		return _from_cone_twist_joint_node(godot_joint)
	printerr("glTF Physics Joint: Unable to convert '" + str(godot_joint) + "'. Returning a default pin joint as fallback.")
	var ret := GLTFPhysicsJointSettings.new()
	var limit := GLTFPhysicsJointLimit.new()
	limit.linear_axes = [0, 1, 2]
	limit.min = 0.0
	limit.max = 0.0
	ret.limit_linear_x = limit
	ret.limit_linear_y = limit
	ret.limit_linear_z = limit
	return ret


static func _from_pin_joint_node(godot_joint: PinJoint3D) -> GLTFPhysicsJointSettings:
	var ret := GLTFPhysicsJointSettings.new()
	var limit := GLTFPhysicsJointLimit.new()
	limit.linear_axes = [0, 1, 2]
	limit.min = 0.0
	limit.max = 0.0
	limit.stiffness = godot_joint.get_param(PinJoint3D.PARAM_BIAS)
	limit.damping = godot_joint.get_param(PinJoint3D.PARAM_DAMPING)
	ret.limit_linear_x = limit
	ret.limit_linear_y = limit
	ret.limit_linear_z = limit
	return ret


static func _from_hinge_joint_node(godot_joint: HingeJoint3D) -> GLTFPhysicsJointSettings:
	var ret := GLTFPhysicsJointSettings.new()
	var linear_limit := GLTFPhysicsJointLimit.new()
	linear_limit.linear_axes = [0, 1, 2]
	linear_limit.min = 0.0
	linear_limit.max = 0.0
	linear_limit.stiffness = godot_joint.get_param(HingeJoint3D.PARAM_BIAS)
	ret.limit_linear_x = linear_limit
	ret.limit_linear_y = linear_limit
	ret.limit_linear_z = linear_limit
	var fixed_angular_limit := GLTFPhysicsJointLimit.new()
	fixed_angular_limit.angular_axes = [0, 1]
	fixed_angular_limit.min = 0.0
	fixed_angular_limit.max = 0.0
	fixed_angular_limit.stiffness = godot_joint.get_param(HingeJoint3D.PARAM_LIMIT_BIAS)
	fixed_angular_limit.damping = 1.0 / godot_joint.get_param(HingeJoint3D.PARAM_LIMIT_RELAXATION)
	ret.limit_angular_x = fixed_angular_limit
	ret.limit_angular_y = fixed_angular_limit
	# Godot's Hinge joint rotates around the local Z axis (in the XY plane).
	if godot_joint.get_flag(HingeJoint3D.FLAG_USE_LIMIT):
		var loose_angular_limit := GLTFPhysicsJointLimit.new()
		loose_angular_limit.angular_axes = [2]
		loose_angular_limit.min = godot_joint.get_param(HingeJoint3D.PARAM_LIMIT_LOWER)
		loose_angular_limit.max = godot_joint.get_param(HingeJoint3D.PARAM_LIMIT_UPPER)
		loose_angular_limit.stiffness = godot_joint.get_param(HingeJoint3D.PARAM_LIMIT_SOFTNESS)
		loose_angular_limit.damping = 1.0 / godot_joint.get_param(HingeJoint3D.PARAM_LIMIT_RELAXATION)
		ret.limit_angular_z = loose_angular_limit
	if godot_joint.get_flag(HingeJoint3D.FLAG_ENABLE_MOTOR):
		var drive := GLTFPhysicsJointDrive.new()
		drive.axis = 2 # Z
		drive.max_force = godot_joint.get_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE)
		drive.velocity_target = godot_joint.get_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY)
		ret.drive_angular_z = drive
	return ret


static func _from_slider_joint_node(godot_joint: SliderJoint3D) -> GLTFPhysicsJointSettings:
	var ret := GLTFPhysicsJointSettings.new()
	# Godot's Slider joint slides on the local X axis (fixed in the YZ plane).
	var loose_linear_limit := GLTFPhysicsJointLimit.new()
	loose_linear_limit.linear_axes = [0]
	loose_linear_limit.min = godot_joint.get_param(SliderJoint3D.PARAM_LINEAR_LIMIT_LOWER)
	loose_linear_limit.max = godot_joint.get_param(SliderJoint3D.PARAM_LINEAR_LIMIT_UPPER)
	loose_linear_limit.stiffness = godot_joint.get_param(SliderJoint3D.PARAM_LINEAR_LIMIT_SOFTNESS)
	loose_linear_limit.damping = godot_joint.get_param(SliderJoint3D.PARAM_LINEAR_LIMIT_DAMPING)
	if loose_linear_limit.min <= loose_linear_limit.max:
		# In Godot's Slider joint, the lower limit being higher than the upper limit means unconstrained.
		# Therefore, the limit only contains if min is less than or equal to max.
		ret.limit_linear_x = loose_linear_limit
	var fixed_linear_limit := GLTFPhysicsJointLimit.new()
	fixed_linear_limit.linear_axes = [1, 2]
	fixed_linear_limit.min = 0.0
	fixed_linear_limit.max = 0.0
	fixed_linear_limit.damping = godot_joint.get_param(SliderJoint3D.PARAM_LINEAR_ORTHOGONAL_DAMPING)
	fixed_linear_limit.stiffness = godot_joint.get_param(SliderJoint3D.PARAM_LINEAR_ORTHOGONAL_SOFTNESS)
	ret.limit_linear_y = fixed_linear_limit
	ret.limit_linear_z = fixed_linear_limit
	# Godot's Slider joint rotates around the local X axis (in the YZ plane).
	var loose_angular_limit := GLTFPhysicsJointLimit.new()
	loose_angular_limit.angular_axes = [0]
	loose_angular_limit.min = godot_joint.get_param(SliderJoint3D.PARAM_ANGULAR_LIMIT_LOWER)
	loose_angular_limit.max = godot_joint.get_param(SliderJoint3D.PARAM_ANGULAR_LIMIT_UPPER)
	loose_angular_limit.stiffness = godot_joint.get_param(SliderJoint3D.PARAM_ANGULAR_LIMIT_SOFTNESS)
	loose_angular_limit.damping = godot_joint.get_param(SliderJoint3D.PARAM_ANGULAR_LIMIT_DAMPING)
	if loose_angular_limit.min <= loose_angular_limit.max:
		# In Godot's Slider joint, the lower limit being higher than the upper limit means unconstrained.
		# Therefore, the limit only contains if min is less than or equal to max.
		ret.limit_angular_x = loose_angular_limit
	var fixed_angular_limit := GLTFPhysicsJointLimit.new()
	fixed_angular_limit.angular_axes = [1, 2]
	fixed_angular_limit.min = 0.0
	fixed_angular_limit.max = 0.0
	fixed_angular_limit.damping = godot_joint.get_param(SliderJoint3D.PARAM_ANGULAR_ORTHOGONAL_DAMPING)
	fixed_angular_limit.stiffness = godot_joint.get_param(SliderJoint3D.PARAM_ANGULAR_ORTHOGONAL_SOFTNESS)
	ret.limit_angular_y = fixed_angular_limit
	ret.limit_angular_z = fixed_angular_limit
	return ret


static func _from_cone_twist_joint_node(godot_joint: ConeTwistJoint3D) -> GLTFPhysicsJointSettings:
	# It doesn't seem possible to fully represent ConeTwistJoint3D, so use an approximation.
	push_warning("glTF Physics Joint: Converting a ConeTwistJoint3D which cannot be properly represented as a glTF joint, so it will only be approximated.")
	var ret := GLTFPhysicsJointSettings.new()
	var linear_limit := GLTFPhysicsJointLimit.new()
	linear_limit.linear_axes = [0, 1, 2]
	linear_limit.min = 0.0
	linear_limit.max = 0.0
	ret.limit_linear_x = linear_limit
	ret.limit_linear_y = linear_limit
	ret.limit_linear_z = linear_limit
	var angular_limit := GLTFPhysicsJointLimit.new()
	angular_limit.angular_axes = [0, 1, 2]
	angular_limit.min = -godot_joint.get_param(ConeTwistJoint3D.PARAM_SWING_SPAN)
	angular_limit.max = godot_joint.get_param(ConeTwistJoint3D.PARAM_SWING_SPAN)
	angular_limit.stiffness = godot_joint.get_param(ConeTwistJoint3D.PARAM_SOFTNESS)
	angular_limit.damping = 1.0 / godot_joint.get_param(ConeTwistJoint3D.PARAM_RELAXATION)
	ret.limit_angular_x = angular_limit
	ret.limit_angular_y = angular_limit
	ret.limit_angular_z = angular_limit
	return ret


static func _from_generic_joint_node(godot_joint: Generic6DOFJoint3D) -> GLTFPhysicsJointSettings:
	var ret := GLTFPhysicsJointSettings.new()
	if godot_joint.get_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT):
		var limit := GLTFPhysicsJointLimit.new()
		limit.min = godot_joint.get_param_x(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT)
		limit.max = godot_joint.get_param_x(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT)
		limit.stiffness = godot_joint.get_param_x(Generic6DOFJoint3D.PARAM_LINEAR_LIMIT_SOFTNESS)
		limit.damping = godot_joint.get_param_x(Generic6DOFJoint3D.PARAM_LINEAR_DAMPING)
		limit.linear_axes = [0] # X
		ret.limit_linear_x = limit
	if godot_joint.get_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT):
		var limit := GLTFPhysicsJointLimit.new()
		limit.min = godot_joint.get_param_y(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT)
		limit.max = godot_joint.get_param_y(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT)
		limit.stiffness = godot_joint.get_param_y(Generic6DOFJoint3D.PARAM_LINEAR_LIMIT_SOFTNESS)
		limit.damping = godot_joint.get_param_y(Generic6DOFJoint3D.PARAM_LINEAR_DAMPING)
		if ret.limit_linear_x != null and limit.limits_equal_to(ret.limit_linear_x):
			ret.limit_linear_x.linear_axes.append(1) # Y
			ret.limit_linear_y = ret.limit_linear_x
		else:
			limit.linear_axes = [1] # Y
			ret.limit_linear_y = limit
	if godot_joint.get_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT):
		var limit := GLTFPhysicsJointLimit.new()
		limit.min = godot_joint.get_param_z(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT)
		limit.max = godot_joint.get_param_z(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT)
		limit.stiffness = godot_joint.get_param_z(Generic6DOFJoint3D.PARAM_LINEAR_LIMIT_SOFTNESS)
		limit.damping = godot_joint.get_param_z(Generic6DOFJoint3D.PARAM_LINEAR_DAMPING)
		if ret.limit_linear_x != null and limit.limits_equal_to(ret.limit_linear_x):
			ret.limit_linear_x.linear_axes.append(2) # Z
			ret.limit_linear_z = ret.limit_linear_x
		elif ret.limit_linear_y != null and limit.limits_equal_to(ret.limit_linear_y):
			ret.limit_linear_y.linear_axes.append(2) # Z
			ret.limit_linear_z = ret.limit_linear_y
		else:
			limit.linear_axes = [2] # Z
			ret.limit_linear_z = limit
	if godot_joint.get_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT):
		var limit := GLTFPhysicsJointLimit.new()
		limit.min = godot_joint.get_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT)
		limit.max = godot_joint.get_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT)
		limit.stiffness = godot_joint.get_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_LIMIT_SOFTNESS)
		limit.damping = godot_joint.get_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_DAMPING)
		limit.angular_axes = [0] # X
		ret.limit_angular_x = limit
	if godot_joint.get_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT):
		var limit := GLTFPhysicsJointLimit.new()
		limit.min = godot_joint.get_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT)
		limit.max = godot_joint.get_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT)
		limit.stiffness = godot_joint.get_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_LIMIT_SOFTNESS)
		limit.damping = godot_joint.get_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_DAMPING)
		if ret.limit_angular_x != null and limit.limits_equal_to(ret.limit_angular_x):
			ret.limit_angular_x.angular_axes.append(1) # Y
			ret.limit_angular_y = ret.limit_angular_x
		else:
			limit.angular_axes = [1] # Y
			ret.limit_angular_y = limit
	if godot_joint.get_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT):
		var limit := GLTFPhysicsJointLimit.new()
		limit.min = godot_joint.get_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT)
		limit.max = godot_joint.get_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT)
		limit.stiffness = godot_joint.get_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_LIMIT_SOFTNESS)
		limit.damping = godot_joint.get_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_DAMPING)
		if ret.limit_angular_x != null and limit.limits_equal_to(ret.limit_angular_x):
			ret.limit_angular_x.angular_axes.append(2) # Z
			ret.limit_angular_z = ret.limit_angular_x
		elif ret.limit_angular_y != null and limit.limits_equal_to(ret.limit_angular_y):
			ret.limit_angular_y.angular_axes.append(2) # Z
			ret.limit_angular_z = ret.limit_angular_y
		else:
			limit.angular_axes = [2] # Z
			ret.limit_angular_z = limit
	# glTF Joint Drives are a combination of Godot Generic6DOFJoint3D Motors and Springs.
	if godot_joint.get_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_MOTOR) or godot_joint.get_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_SPRING):
		var drive := GLTFPhysicsJointDrive.new()
		drive.axis = 0 # X
		if godot_joint.get_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_MOTOR):
			drive.max_force = godot_joint.get_param_x(Generic6DOFJoint3D.PARAM_LINEAR_MOTOR_FORCE_LIMIT)
			drive.velocity_target = godot_joint.get_param_x(Generic6DOFJoint3D.PARAM_LINEAR_MOTOR_TARGET_VELOCITY)
		if godot_joint.get_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_SPRING):
			drive.damping = godot_joint.get_param_x(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_DAMPING)
			drive.position_target = godot_joint.get_param_x(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_EQUILIBRIUM_POINT)
			drive.stiffness = godot_joint.get_param_x(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_STIFFNESS)
		ret.drive_linear_x = drive
	if godot_joint.get_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_MOTOR) or godot_joint.get_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_SPRING):
		var drive := GLTFPhysicsJointDrive.new()
		drive.axis = 1 # Y
		if godot_joint.get_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_MOTOR):
			drive.max_force = godot_joint.get_param_y(Generic6DOFJoint3D.PARAM_LINEAR_MOTOR_FORCE_LIMIT)
			drive.velocity_target = godot_joint.get_param_y(Generic6DOFJoint3D.PARAM_LINEAR_MOTOR_TARGET_VELOCITY)
		if godot_joint.get_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_SPRING):
			drive.damping = godot_joint.get_param_y(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_DAMPING)
			drive.position_target = godot_joint.get_param_y(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_EQUILIBRIUM_POINT)
			drive.stiffness = godot_joint.get_param_y(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_STIFFNESS)
		ret.drive_linear_y = drive
	if godot_joint.get_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_MOTOR) or godot_joint.get_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_SPRING):
		var drive := GLTFPhysicsJointDrive.new()
		drive.axis = 2 # Z
		if godot_joint.get_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_MOTOR):
			drive.max_force = godot_joint.get_param_z(Generic6DOFJoint3D.PARAM_LINEAR_MOTOR_FORCE_LIMIT)
			drive.velocity_target = godot_joint.get_param_z(Generic6DOFJoint3D.PARAM_LINEAR_MOTOR_TARGET_VELOCITY)
		if godot_joint.get_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_SPRING):
			drive.damping = godot_joint.get_param_z(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_DAMPING)
			drive.position_target = godot_joint.get_param_z(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_EQUILIBRIUM_POINT)
			drive.stiffness = godot_joint.get_param_z(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_STIFFNESS)
		ret.drive_linear_z = drive
	if godot_joint.get_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_MOTOR) or godot_joint.get_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING):
		var drive := GLTFPhysicsJointDrive.new()
		drive.axis = 0 # X
		if godot_joint.get_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_MOTOR):
			drive.max_force = godot_joint.get_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_MOTOR_FORCE_LIMIT)
			drive.velocity_target = godot_joint.get_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_MOTOR_TARGET_VELOCITY)
		if godot_joint.get_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING):
			drive.damping = godot_joint.get_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_SPRING_DAMPING)
			drive.position_target = godot_joint.get_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_SPRING_EQUILIBRIUM_POINT)
			drive.stiffness = godot_joint.get_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_SPRING_STIFFNESS)
		ret.drive_angular_x = drive
	if godot_joint.get_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_MOTOR) or godot_joint.get_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING):
		var drive := GLTFPhysicsJointDrive.new()
		drive.axis = 1 # Y
		if godot_joint.get_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_MOTOR):
			drive.max_force = godot_joint.get_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_MOTOR_FORCE_LIMIT)
			drive.velocity_target = godot_joint.get_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_MOTOR_TARGET_VELOCITY)
		if godot_joint.get_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING):
			drive.damping = godot_joint.get_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_SPRING_DAMPING)
			drive.position_target = godot_joint.get_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_SPRING_EQUILIBRIUM_POINT)
			drive.stiffness = godot_joint.get_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_SPRING_STIFFNESS)
		ret.drive_angular_y = drive
	if godot_joint.get_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_MOTOR) or godot_joint.get_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING):
		var drive := GLTFPhysicsJointDrive.new()
		drive.axis = 2 # Z
		if godot_joint.get_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_MOTOR):
			drive.max_force = godot_joint.get_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_MOTOR_FORCE_LIMIT)
			drive.velocity_target = godot_joint.get_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_MOTOR_TARGET_VELOCITY)
		if godot_joint.get_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING):
			drive.damping = godot_joint.get_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_SPRING_DAMPING)
			drive.position_target = godot_joint.get_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_SPRING_EQUILIBRIUM_POINT)
			drive.stiffness = godot_joint.get_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_SPRING_STIFFNESS)
		ret.drive_angular_z = drive
	return ret


func to_generic_joint_node() -> Generic6DOFJoint3D:
	var ret := Generic6DOFJoint3D.new()
	if limit_linear_x == null:
		ret.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, false)
	else:
		ret.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, limit_linear_x.min)
		ret.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, limit_linear_x.max)
		# Calculate values that will not cause Godot's physics engine to explode.
		# These magic numbers can be changed if Godot's physics engine improves.
		var stiffness: float = clampf(limit_linear_x.stiffness, 0.01, 2.0)
		var minimum_damping: float = 0.01
		if stiffness > 0.5:
			minimum_damping = 0.25 * sqrt(stiffness - 0.498)
		ret.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_LIMIT_SOFTNESS, stiffness)
		ret.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_DAMPING, clampf(limit_linear_x.damping, minimum_damping, 16.0))
	if limit_linear_y == null:
		ret.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, false)
	else:
		ret.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, limit_linear_y.min)
		ret.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, limit_linear_y.max)
		var stiffness: float = clampf(limit_linear_y.stiffness, 0.01, 2.0)
		var minimum_damping: float = 0.01
		if stiffness > 0.5:
			minimum_damping = 0.25 * sqrt(stiffness - 0.498)
		ret.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_LIMIT_SOFTNESS, stiffness)
		ret.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_DAMPING, clampf(limit_linear_y.damping, minimum_damping, 16.0))
	if limit_linear_z == null:
		ret.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, false)
	else:
		ret.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, limit_linear_z.min)
		ret.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, limit_linear_z.max)
		var stiffness: float = clampf(limit_linear_z.stiffness, 0.01, 2.0)
		var minimum_damping: float = 0.01
		if stiffness > 0.5:
			minimum_damping = 0.25 * sqrt(stiffness - 0.498)
		ret.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_LIMIT_SOFTNESS, stiffness)
		ret.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_DAMPING, clampf(limit_linear_z.damping, minimum_damping, 16.0))
	if limit_angular_x == null:
		ret.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, false)
	else:
		ret.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, limit_angular_x.min)
		ret.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, limit_angular_x.max)
		var stiffness: float = clampf(limit_angular_x.stiffness, 0.01, 2.0)
		var minimum_damping: float = 0.01
		if stiffness > 0.5:
			minimum_damping = 0.25 * sqrt(stiffness - 0.498)
		ret.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_LIMIT_SOFTNESS, stiffness)
		ret.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_DAMPING, clampf(limit_angular_x.damping, minimum_damping, 16.0))
	if limit_angular_y == null:
		ret.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, false)
	else:
		ret.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, limit_angular_y.min)
		ret.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, limit_angular_y.max)
		var stiffness: float = clampf(limit_angular_y.stiffness, 0.01, 2.0)
		var minimum_damping: float = 0.01
		if stiffness > 0.5:
			minimum_damping = 0.25 * sqrt(stiffness - 0.498)
		ret.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_LIMIT_SOFTNESS, stiffness)
		ret.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_DAMPING, clampf(limit_angular_y.damping, minimum_damping, 16.0))
	if limit_angular_z == null:
		ret.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, false)
	else:
		ret.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, limit_angular_z.min)
		ret.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, limit_angular_z.max)
		var stiffness: float = clampf(limit_angular_z.stiffness, 0.01, 2.0)
		var minimum_damping: float = 0.01
		if stiffness > 0.5:
			minimum_damping = 0.25 * sqrt(stiffness - 0.498)
		ret.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_LIMIT_SOFTNESS, stiffness)
		ret.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_DAMPING, clampf(limit_angular_z.damping, minimum_damping, 16.0))
	# glTF Joint Drives are a combination of Godot Generic6DOFJoint3D Motors and Springs.
	if drive_linear_x != null:
		if not is_nan(drive_linear_x.velocity_target):
			ret.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_MOTOR, true)
			ret.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_MOTOR_FORCE_LIMIT, drive_linear_x.max_force)
			ret.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_MOTOR_TARGET_VELOCITY, drive_linear_x.velocity_target)
		if not is_nan(drive_linear_x.position_target):
			ret.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_SPRING, true)
			ret.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_DAMPING, drive_linear_x.damping)
			ret.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_EQUILIBRIUM_POINT, drive_linear_x.position_target)
			ret.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_STIFFNESS, drive_linear_x.stiffness)
	if drive_linear_y != null:
		if not is_nan(drive_linear_y.velocity_target):
			ret.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_MOTOR, true)
			ret.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_MOTOR_FORCE_LIMIT, drive_linear_y.max_force)
			ret.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_MOTOR_TARGET_VELOCITY, drive_linear_y.velocity_target)
		if not is_nan(drive_linear_y.position_target):
			ret.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_SPRING, true)
			ret.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_DAMPING, drive_linear_y.damping)
			ret.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_EQUILIBRIUM_POINT, drive_linear_y.position_target)
			ret.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_STIFFNESS, drive_linear_y.stiffness)
	if drive_linear_z != null:
		if not is_nan(drive_linear_z.velocity_target):
			ret.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_MOTOR, true)
			ret.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_MOTOR_FORCE_LIMIT, drive_linear_z.max_force)
			ret.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_MOTOR_TARGET_VELOCITY, drive_linear_z.velocity_target)
		if not is_nan(drive_linear_z.position_target):
			ret.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_SPRING, true)
			ret.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_DAMPING, drive_linear_z.damping)
			ret.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_EQUILIBRIUM_POINT, drive_linear_z.position_target)
			ret.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_STIFFNESS, drive_linear_z.stiffness)
	if drive_angular_x != null:
		if not is_nan(drive_angular_x.velocity_target):
			ret.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_MOTOR, true)
			ret.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_MOTOR_FORCE_LIMIT, drive_angular_x.max_force)
			ret.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_MOTOR_TARGET_VELOCITY, drive_angular_x.velocity_target)
		if not is_nan(drive_angular_x.position_target):
			ret.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING, true)
			ret.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_SPRING_DAMPING, drive_angular_x.damping)
			ret.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_SPRING_EQUILIBRIUM_POINT, drive_angular_x.position_target)
			ret.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_SPRING_STIFFNESS, drive_angular_x.stiffness)
	if drive_angular_y != null:
		if not is_nan(drive_angular_y.velocity_target):
			ret.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_MOTOR, true)
			ret.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_MOTOR_FORCE_LIMIT, drive_angular_y.max_force)
			ret.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_MOTOR_TARGET_VELOCITY, drive_angular_y.velocity_target)
		if not is_nan(drive_angular_y.position_target):
			ret.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING, true)
			ret.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_SPRING_DAMPING, drive_angular_y.damping)
			ret.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_SPRING_EQUILIBRIUM_POINT, drive_angular_y.position_target)
			ret.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_SPRING_STIFFNESS, drive_angular_y.stiffness)
	if drive_angular_z != null:
		if not is_nan(drive_angular_z.velocity_target):
			ret.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_MOTOR, true)
			ret.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_MOTOR_FORCE_LIMIT, drive_angular_z.max_force)
			ret.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_MOTOR_TARGET_VELOCITY, drive_angular_z.velocity_target)
		if not is_nan(drive_angular_z.position_target):
			ret.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING, true)
			ret.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_SPRING_DAMPING, drive_angular_z.damping)
			ret.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_SPRING_EQUILIBRIUM_POINT, drive_angular_z.position_target)
			ret.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_SPRING_STIFFNESS, drive_angular_z.stiffness)
	return ret
