## General-purpose piloted VehicleBody3D. Can be used for cars, spacecraft, airplanes, boats, and more.
@icon("icons/PilotedVehicleBody3D.svg")
class_name PilotedVehicleBody3D
extends VehicleBody3D


const INERTIA_DAMPENER_RATE_ANGULAR: float = 4.0
const INERTIA_DAMPENER_RATE_LINEAR: float = 1.0


## The input value controlling the ratio of the vehicle's angular forces.
@export var angular_activation := Vector3.ZERO
## The input value controlling the ratio of the vehicle's linear forces.
@export var linear_activation := Vector3.ZERO
## The gyroscope torque intrinsic to the vehicle, excluding torque from parts, measured in Newton-meters per radian (kg⋅m²/s²/rad).
@export_custom(PROPERTY_HINT_NONE, "suffix:kg\u22C5m\u00B2/s\u00B2/rad (N\u22C5m/rad)")
var gyroscope_torque := Vector3.ZERO
## If non-negative, the speed in meters per second at which the vehicle should stop driving acceleration further.
## If throttle is used, activation is a ratio of this speed if positive, or a ratio of thrust power if negative.
@export var max_speed: float = -1.0
## The node to use as the pilot seat / driver seat.
@export var pilot_seat_node: PilotSeat3D = null:
	set(value):
		pilot_seat_node = value
		if pilot_seat_node.piloted_vehicle_node != self:
			pilot_seat_node.piloted_vehicle_node = self
## If true, the vehicle should slow its rotation down when not given angular activation input for a specific rotation.
@export var angular_dampeners: bool = true
## If true, the vehicle should slow itself down when not given linear activation input for a specific direction.
@export var linear_dampeners: bool = true
## If true, the vehicle should use a throttle for linear movement. Pilot seat input "sticks around" when let go.
## If max_speed is non-negative, the throttle should be a ratio of that speed, otherwise it should be a ratio of thrust power.
@export var use_throttle: bool = false

var _hover_thrusters: Array[VehicleHoverThruster3D] = []
var _thrusters: Array[VehicleThruster3D] = []
var _wheels: Array[PilotedVehicleWheel3D] = []


func _ready() -> void:
	if pilot_seat_node:
		pilot_seat_node.piloted_vehicle_node = self


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var actual_angular: Vector3 = angular_activation
	var actual_linear: Vector3 = linear_activation
	var global_to_local_rot: Quaternion = global_transform.basis.get_rotation_quaternion().inverse()
	var local_angular_vel: Vector3 = global_to_local_rot * get_angular_velocity()
	var local_linear_vel: Vector3 = global_to_local_rot * get_linear_velocity()
	var local_up_direction: Vector3 = -_get_local_gravity_direction()
	# Determine the actual linear values to use based on activation, throttle, and dampeners.
	if use_throttle and max_speed >= 0.0:
		# In this case, the throttle should be a ratio of the maximum speed,
		# with the thrust adjusting so that the vehicle meets the target speed.
		var target_velocity: Vector3 = max_speed * linear_activation
		actual_linear = (target_velocity - local_linear_vel) / max_speed
	elif linear_dampeners:
		if is_zero_approx(actual_linear.x):
			actual_linear.x = local_linear_vel.x * -INERTIA_DAMPENER_RATE_LINEAR
		if is_zero_approx(actual_linear.y):
			actual_linear.y = local_linear_vel.y * -INERTIA_DAMPENER_RATE_LINEAR
		if is_zero_approx(actual_linear.z):
			actual_linear.z = local_linear_vel.z * -INERTIA_DAMPENER_RATE_LINEAR
		if not _hover_thrusters.is_empty():
			if linear_activation == Vector3.ZERO:
				actual_linear += local_up_direction * 0.75
			else:
				actual_linear += local_up_direction
	# Vehicle wheels should never rotate due to dampeners, because for wheels,
	# pointing straight is a vehicle's best attempt to stop rotating.
	for wheel in _wheels:
		wheel.set_from_vehicle_input(actual_angular, actual_linear)
	# Determine the actual angular values to use based on activation and dampeners.
	if angular_dampeners:
		if is_zero_approx(angular_activation.x):
			actual_angular.x = local_angular_vel.x * -INERTIA_DAMPENER_RATE_ANGULAR
		if is_zero_approx(angular_activation.y):
			actual_angular.y = local_angular_vel.y * -INERTIA_DAMPENER_RATE_ANGULAR
		if is_zero_approx(angular_activation.z):
			actual_angular.z = local_angular_vel.z * -INERTIA_DAMPENER_RATE_ANGULAR
		# Hovercraft, cars, etc should attempt to keep themselves upright.
		if pilot_seat_node != null and pilot_seat_node.does_pilot_seat_want_to_keep_upright():
			var to_up: Quaternion = _get_rotation_to_upright(local_up_direction)
			var v = Vector3(to_up.x, 0.0, to_up.z).limit_length()
			if is_zero_approx(angular_activation.x):
				actual_angular.x += v.x
			if is_zero_approx(angular_activation.z):
				actual_angular.z += v.z
	# Clamp the actual inputs to the range of -1.0 to 1.0 per each axis (can be longer than 1.0 overall).
	# The individual parts (thrusters etc) may clamp these further as needed (such as to a length of 1.0).
	actual_angular = actual_angular.clampf(-1.0, 1.0)
	actual_linear = actual_linear.clampf(-1.0, 1.0)
	# Now that we've calculated the actual angular/linear inputs including
	# throttle and dampeners, apply them to everything (except wheels).
	apply_torque(basis * (gyroscope_torque * actual_angular))
	for hover_thruster in _hover_thrusters:
		hover_thruster.set_from_vehicle_input(actual_angular, actual_linear)
	for thruster in _thrusters:
		thruster.set_from_vehicle_input(actual_angular, actual_linear)


func has_hover_thrusters() -> bool:
	return not _hover_thrusters.is_empty()


func has_wheels() -> bool:
	return not _wheels.is_empty()


func register_part(part: Node3D) -> void:
	if part is VehicleHoverThruster3D:
		_hover_thrusters.append(part)
	elif part is VehicleThruster3D:
		_thrusters.append(part)
	elif part is PilotedVehicleWheel3D:
		_wheels.append(part)
	else:
		printerr("PilotedVehicleBody3D: Unknown part type: ", part)


func _get_rotation_to_upright(up_direction: Vector3) -> Quaternion:
	var y = up_direction
	if y == Vector3.ZERO:
		return Quaternion.IDENTITY
	var x = y.cross(Vector3.BACK)
	var z = x.cross(y).normalized()
	x = y.cross(z)
	var b = Basis(x, y, z)
	return b.get_rotation_quaternion()


func _get_local_gravity_direction() -> Vector3:
	var global_to_local_rot: Quaternion = global_transform.basis.get_rotation_quaternion().inverse()
	return global_to_local_rot * get_gravity().normalized()
