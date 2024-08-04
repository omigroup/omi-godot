@icon("icons/PilotedVehicleWheel3D.svg")
class_name PilotedVehicleWheel3D
extends VehicleWheel3D


## The ratio of the maximum force the wheel is using for propulsion.
@export_range(0.0, 1.0, 0.01)
var current_force_ratio: float = 0.0
## The ratio of the maximum steering angle the wheel is rotated to.
@export_range(0.0, 1.0, 0.01)
var current_steering_ratio: float = 0.0
## The maximum force in Newtons (kg⋅m/s²) that the wheel can provide.
@export_custom(PROPERTY_HINT_NONE, "suffix:kg\u22C5m/s\u00B2 (N)")
var max_force: float = 0.0
## The maximum angle in radians that the wheel can steer.
@export_range(0, 90, 0.1, "radians")
var max_steering_angle: float = 0.0

var _negate_steering: bool = false
var _parent_body: RigidBody3D = null


func _enter_tree() -> void:
	_parent_body = _get_parent_body()
	if position.z < 0.0:
		_negate_steering = true


func _physics_process(delta: float) -> void:
	steering = move_toward(steering, current_steering_ratio * max_steering_angle, delta)


func set_steering_from_vehicle_angular_input(angular_input: Vector3) -> void:
	# Note: This code only supports wheels where 0 steering means forward.
	# Ideally we should allow for wheels in other rotations but that would be more complicated.
	# Other implementations of OMI_vehicle_wheel can use more complex algorithms if they wish.
	var steer_ratio: float = angular_input.y * angular_input.y
	if (angular_input.y < 0) != _negate_steering:
		steer_ratio = -steer_ratio
	current_steering_ratio = clampf(steer_ratio, -1.0, 1.0)


func set_thrust_from_vehicle_linear_input(linear_input: Vector3) -> void:
	# Note: This code only supports wheels where 0 steering means forward.
	# Ideally we should allow for wheels in other rotations but that would be more complicated.
	# Other implementations of OMI_vehicle_wheel can use more complex algorithms if they wish.
	current_force_ratio = linear_input.z * cos(steering)
	engine_force = current_force_ratio * max_force


func _get_parent_body() -> RigidBody3D:
	var parent = get_parent()
	while parent != null:
		if parent is RigidBody3D:
			if parent is PilotedVehicleBody3D:
				parent.register_part(self)
			return parent
		parent = parent.get_parent()
	return null
