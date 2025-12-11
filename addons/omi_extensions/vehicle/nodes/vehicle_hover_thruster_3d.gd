## Hover thruster for vehicles, used for hovercraft thrust. This is not realistic, it is sci-fi.
## For the "enabled" property supplied by RayCast3D: If false, the hover thruster will not gimbal or apply forces.
@icon("icons/VehicleHoverThruster3D.svg")
class_name VehicleHoverThruster3D
extends RayCast3D


# Controls how much the vehicle's angular input should affect the hover ratio.
# 0 = none, 1 or more = too much stabilization (overcorrection/bounciness).
const TORQUE_STABILIZATION = 0.5

# Gimbal
## The maximum angle the hover thruster can gimbal or rotate in radians.
## Note: The initial gimbal must be set before adding the node to the tree.
@export_custom(PROPERTY_HINT_NONE, "suffix:rad")
var max_gimbal_radians: float = 0.0
## Optionally, you may also want to allow the gimbal to be adjusted based on linear input.
## For example, if the user wants to go forward, and the thruster points downward,
## we can gimbal the thruster slightly backward to help thrust forward.
## The default is 0.0 for thrusters and 0.5 for hover thrusters.
@export_range(0.0, 1.0, 0.01)
var linear_gimbal_adjust_ratio: float = 0.5
## The speed at which the gimbal angle changes, in radians per second. If negative, the angle changes instantly.
@export_custom(PROPERTY_HINT_NONE, "suffix:rad/s")
var gimbal_radians_per_second: float = 1.0
## The ratio of the maximum gimbal angles the hover thruster is targeting to be rotated to. The vector length may not be longer than 1.0.
## Note: The initial gimbal must be set before adding the node to the tree.
@export var target_gimbal_ratio := Vector2(0.0, 0.0)
## The current gimbal angles in radians, tending towards target_gimbal_ratio * max_gimbal_radians.
## If gimbal_radians_per_second is negative, this will equal the target value.
var _current_gimbal_radians := Vector2(0.0, 0.0)

# Hover Thrust
## The maximum hover energy in Newton-meters (N⋅m or kg⋅m²/s²) that the hover thruster can provide.
@export_custom(PROPERTY_HINT_NONE, "suffix:N\u22C5m (kg\u22C5m\u00B2/s\u00B2)")
var max_hover_energy: float = 0.0
## The speed at which the hover energy changes, in Newtons-meters per second. If negative, the force changes instantly.
@export_custom(PROPERTY_HINT_NONE, "suffix:N\u22C5m/s")
var hover_energy_change_per_second: float = -1.0
## The ratio of the maximum hover energy the hover thruster is targeting for propulsion.
@export_range(0.0, 1.0, 0.01)
var target_hover_ratio: float = 0.0
var _current_hover_energy: float = 0.0

var _parent_body: RigidBody3D = null
var _particles_node: GPUParticles3D = null

var _parent_transform_to_body := Transform3D.IDENTITY
var _parent_quaternion_to_body := Quaternion.IDENTITY
var _rest_quaternion := Quaternion.IDENTITY
var _rest_quaternion_to_body := Quaternion.IDENTITY
var _body_to_rest_quaternion := Quaternion.IDENTITY
var _negate_gimbal: bool = true


func _init() -> void:
	target_position = Vector3(0.0, 0.0, -1000.0)


func _enter_tree() -> void:
	_parent_body = _get_parent_body()
	recalculate_transforms()


func _ready() -> void:
	_make_debug_mesh()
	for child in get_children():
		if child is GPUParticles3D:
			_particles_node = child
			break


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		# This isn't a tool script so I have no clue why it's running in the editor but it does?
		return
	# Move the current gimbal radians towards the target value.
	var target_gimbal_radians: Vector2 = target_gimbal_ratio.limit_length() * max_gimbal_radians
	if gimbal_radians_per_second < 0.0:
		_current_gimbal_radians = target_gimbal_radians
	else:
		var gimbal_change: float = gimbal_radians_per_second * delta
		_current_gimbal_radians = _current_gimbal_radians.move_toward(target_gimbal_radians, gimbal_change)
	quaternion = _rest_quaternion * _get_gimbal_rotation_quaternion()
	# Set force and particles to zero if inactive.
	if _parent_body == null or not enabled:
		if _particles_node:
			_particles_node.amount_ratio = 0.0
		return
	# First, find the actual hover ratio we need. Hover thrusters should naturally provide
	var actual_hover: float = clampf(target_hover_ratio, 0.0, 1.0)
	if _particles_node:
		_particles_node.amount_ratio = target_hover_ratio
	if _parent_body == null:
		return
	var hit_distance: float = maxf(get_collision_point().distance_to(global_position), 0.1)
	var max_hover_force: float = max_hover_energy / hit_distance # Nm / m == N
	var force_amount: float = actual_hover * max_hover_force
	var force_dir: Vector3 = _parent_body.basis * _parent_transform_to_body.basis * basis.z
	var force_pos: Vector3 = Transform3D(_parent_body.basis) * _parent_transform_to_body * position
	_parent_body.apply_force(force_dir * force_amount, force_pos)


func recalculate_transforms() -> void:
	if _parent_body == null:
		printerr("Error: VehicleHoverThruster3D must be a descendant of a RigidBody3D node (preferably PilotedVehicleBody3D).")
		return
	# Get the transform from the parent to the body.
	_parent_transform_to_body = Transform3D.IDENTITY
	var parent: Node = get_parent()
	while parent != _parent_body and parent is Node3D:
		_parent_transform_to_body = parent.transform * _parent_transform_to_body
		parent = parent.get_parent()
	# Get the rotation of the rest orientation of the part's gimbal.
	_rest_quaternion = quaternion * _get_gimbal_rotation_quaternion().inverse()
	# Use both of those to determine the rest quaternion to body and its inverse.
	_parent_quaternion_to_body = _parent_transform_to_body.basis.get_rotation_quaternion()
	_rest_quaternion_to_body = _parent_quaternion_to_body * _rest_quaternion
	_body_to_rest_quaternion = _rest_quaternion_to_body.inverse()
	# Where is this part relative to the center of mass? We may need to negate the gimbal.
	var rest_transform_to_body: Transform3D = _parent_transform_to_body * Transform3D(Basis(_rest_quaternion), position)
	var offset: Vector3 = rest_transform_to_body.origin - _parent_body.center_of_mass
	_negate_gimbal = offset.dot(rest_transform_to_body.basis.z) < 0.0


func set_from_vehicle_input(angular_input: Vector3, linear_input: Vector3) -> void:
	if max_gimbal_radians == 0.0:
		target_gimbal_ratio = Vector2.ZERO
		return
	# Set the gimbal based on the local angular input.
	var local_angular_input: Vector3 = _body_to_rest_quaternion * angular_input
	target_gimbal_ratio = Vector2(-local_angular_input.x, -local_angular_input.y).limit_length()
	# Adjust the gimbal based on linear input (optional but significantly improves handling).
	if linear_input == Vector3.ZERO or linear_gimbal_adjust_ratio == 0.0:
		return
	var current_rot: Quaternion = _rest_quaternion_to_body * _get_gimbal_rotation_quaternion()
	var local_linear_input: Vector3 = current_rot.inverse() * linear_input
	var linear_gimbal_adjust: Vector2 = Vector2(-local_linear_input.y, local_linear_input.x).limit_length() * linear_gimbal_adjust_ratio
	target_gimbal_ratio = (target_gimbal_ratio + linear_gimbal_adjust).limit_length()
	# Set the hover ratio based on angular torque and linear input.
	var thrust_direction: Vector3 = current_rot * Vector3(0, 0, 1)
	var thrust_hover: float = maxf(linear_input.dot(thrust_direction), 0.0)
	var torque: Vector3 = (_parent_transform_to_body * position).cross(thrust_direction)
	var torque_hover: float = maxf(angular_input.dot(torque) * TORQUE_STABILIZATION, 0.0)
	target_hover_ratio = clampf(thrust_hover + torque_hover, 0.0, 1.0)


func _get_gimbal_rotation_quaternion() -> Quaternion:
	if _current_gimbal_radians.is_zero_approx():
		return Quaternion.IDENTITY
	var angle_mag: float = _current_gimbal_radians.length()
	var sin_norm: float = sin(angle_mag / 2.0) / angle_mag
	var cos_half: float = cos(angle_mag / 2.0)
	return Quaternion(_current_gimbal_radians.x * sin_norm, _current_gimbal_radians.y * sin_norm, 0.0, cos_half)


func _get_parent_body() -> RigidBody3D:
	var parent = get_parent()
	while parent != null:
		if parent is RigidBody3D:
			if parent is PilotedVehicleBody3D:
				parent.register_part(self)
			return parent
		parent = parent.get_parent()
	return null


func _make_debug_mesh() -> void:
	var mi := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.05
	mi.basis = Basis(Vector3.RIGHT, Vector3.FORWARD, Vector3.UP)
	mi.position = Vector3(0.0, 0.0, -1.0)
	mi.mesh = capsule
	add_child(mi)
