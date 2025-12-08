@icon("icons/PilotedVehicleWheel3D.svg")
class_name PilotedVehicleWheel3D
extends VehicleWheel3D


## If false, the wheel will not steer or apply forces.
@export var active: bool = true

# Steering
## The maximum angle in radians that the wheel can steer.
@export_range(0.0, 90.0, 0.1, "radians")
var max_steering_angle: float = 0.0
## The speed at which the wheel steering angle changes, in radians per second.
@export var steering_radians_per_second: float = 1.0
## The ratio of the maximum steering angle the wheel is targeting to be rotated to.
@export_range(0.0, 1.0, 0.01)
var target_steering_ratio: float = 0.0

# Force
## The maximum force in Newtons (kg⋅m/s²) that the wheel can provide.
@export_custom(PROPERTY_HINT_NONE, "suffix:N (kg\u22C5m/s\u00B2)")
var max_propulsion_force: float = 0.0
## The braking force in Newtons (kg⋅m/s²) that the wheel applies when the vehicle is trying to stop.
## If negative, the wheel uses propulsion force as braking instead.
@export_custom(PROPERTY_HINT_NONE, "suffix:N (kg\u22C5m/s\u00B2)")
var braking_force: float = 0.0
## The speed at which the wheel propulsion force changes, in Newtons per second.
## If negative, the force changes instantly.
@export_custom(PROPERTY_HINT_NONE, "suffix:N/s (kg\u22C5m/s\u00B3)")
var propulsion_force_change_per_second: float = -1.0
## The ratio of the maximum force the wheel is targeting for propulsion.
@export_range(0.0, 1.0, 0.01)
var target_propulsion_force_ratio: float = 0.0

var _negate_steering: bool = false
var _parent_body: RigidBody3D = null


func _enter_tree() -> void:
	_parent_body = _get_parent_body()
	if position.z < 0.0:
		_negate_steering = true


func _physics_process(delta: float) -> void:
	if not active:
		brake = 0.0
		engine_force = 0.0
		return
	# Move the wheel's steering angle towards the target.
	var steer_target: float = target_steering_ratio * max_steering_angle
	if steering_radians_per_second < 0.0:
		steering = steer_target
	else:
		steering = move_toward(steering, steer_target, steering_radians_per_second * delta)
	# Figure out the target force the wheel is moving towards.
	var force_target: float = 0.0
	var should_wheels_brake: bool = false
	if _parent_body != null:
		force_target = target_propulsion_force_ratio * max_propulsion_force
		should_wheels_brake = (_parent_body.angular_dampeners
				and _parent_body.linear_dampeners
				and _parent_body.angular_activation == Vector3.ZERO
				and _parent_body.linear_activation == Vector3.ZERO)
	if should_wheels_brake:
		brake = absf(force_target if braking_force < 0.0 else braking_force)
		force_target = 0.0 # Ramp down the engine force to zero while braking.
	else:
		brake = 0.0
	# Move the wheel's engine force towards the target.
	if propulsion_force_change_per_second < 0.0:
		engine_force = force_target
	else:
		engine_force = move_toward(engine_force, force_target, propulsion_force_change_per_second * delta)


## Sets the wheel's steering and thrust based on vehicle input.
func set_from_vehicle_input(angular_input: Vector3, linear_input: Vector3) -> void:
	# Note: This code only supports wheels where 0 steering means forward.
	# Ideally we should allow for wheels in other rotations but that would be more complicated.
	# Other implementations of OMI_vehicle_wheel can use more complex algorithms if they wish.
	# Set steering, prioritizing linear input when it's stronger, otherwise using angular input.
	var source: float = linear_input.x if (abs(linear_input.x) * 2.0 > abs(angular_input.y)) else angular_input.y
	var steer_ratio: float = source * source
	if (source < 0.0) != _negate_steering:
		steer_ratio = -steer_ratio
	target_steering_ratio = clampf(steer_ratio, -1.0, 1.0)
	# Set thrust from vehicle linear input.
	target_propulsion_force_ratio = clampf(linear_input.z * cos(steering), -1.0, 1.0)


func _get_parent_body() -> RigidBody3D:
	var parent = get_parent()
	while parent != null:
		if parent is RigidBody3D:
			if parent is PilotedVehicleBody3D:
				parent.register_part(self)
			return parent
		parent = parent.get_parent()
	return null
