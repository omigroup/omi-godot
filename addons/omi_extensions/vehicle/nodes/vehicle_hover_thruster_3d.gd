## Hover thruster for vehicles, used for hovercraft thrust. This is not realistic, it is sci-fi.
## For the "enabled" property supplied by RayCast3D: If false, the hover thruster will not gimbal or apply forces.
@icon("icons/VehicleHoverThruster3D.svg")
class_name VehicleHoverThruster3D
extends RayCast3D


# Controls how much the vehicle's angular input should affect the hover ratio.
# 0 = none, 1 or more = too much stabilization (overcorrection/bounciness).
const TORQUE_STABILIZATION = 0.5

## The ratio of the maximum hover energy the hover thruster is using for propulsion.
@export_range(0.0, 1.0, 0.01)
var current_hover_ratio: float = 0.0
## The ratio of the maximum gimbal angles the hover thruster is rotated to. The vector length may not be longer than 1.0. Note: Gimbal must be set before adding the node to the tree.
@export var current_gimbal_ratio := Vector2(0.0, 0.0)
## The maximum gimbal energy in Newton-meters (N⋅m or kg⋅m²/s²) that the hover thruster can provide.
@export_custom(PROPERTY_HINT_NONE, "suffix:kg\u22C5m\u00B2/s\u00B2 (N\u22C5m)")
var max_hover_energy: float = 0.0
## The maximum angle the hover thruster can gimbal or rotate in radians. Note: Gimbal must be set before adding the node to the tree.
@export_custom(PROPERTY_HINT_NONE, "suffix:rad")
var max_gimbal: float = 0.0

var _parent_body: RigidBody3D = null
var _particles_node: GPUParticles3D = null

var _parent_transform_to_body := Transform3D.IDENTITY
var _parent_quaternion_to_body := Quaternion.IDENTITY
var _rest_quaternion := Quaternion.IDENTITY
var _rest_quaternion_to_body := Quaternion.IDENTITY
var _maximum_linear_gimbal_adjust: float = 0.0
var _negate_gimbal: bool = true


func _init() -> void:
	target_position = Vector3(0.0, 0.0, -1000.0)


func _enter_tree() -> void:
	_parent_body = _get_parent_body()
	recalculate_transforms()


func _ready() -> void:
	for child in get_children():
		if child is GPUParticles3D:
			_particles_node = child
			break


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		# This isn't a tool script so I have no clue why it's running in the editor but it does?
		return
	if _parent_body == null or not enabled:
		if _particles_node:
			_particles_node.amount_ratio = 0.0
		return
	# First, find the actual hover ratio we need. Hover thrusters should naturally provide
	var actual_hover: float = clampf(current_hover_ratio, 0.0, 1.0)
	quaternion = _rest_quaternion * _get_gimbal_rotation_quaternion()
	if _particles_node:
		_particles_node.amount_ratio = current_hover_ratio
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
		printerr("Error: VehicleThruster3D must be a descendant of a RigidBody3D node (preferably PilotedVehicleBody3D).")
		return
	_parent_transform_to_body = Transform3D.IDENTITY
	var parent: Node = get_parent()
	while parent != _parent_body:
		_parent_transform_to_body = parent.transform * _parent_transform_to_body
		parent = parent.get_parent()
	_rest_quaternion = quaternion * _get_gimbal_rotation_quaternion().inverse()
	_parent_quaternion_to_body = _parent_transform_to_body.basis.get_rotation_quaternion()
	_rest_quaternion_to_body = _parent_quaternion_to_body * _rest_quaternion
	var rest_transform_to_body: Transform3D = _parent_transform_to_body * Transform3D(Basis(_rest_quaternion), position)
	var offset: Vector3 = rest_transform_to_body.origin - _parent_body.center_of_mass
	_maximum_linear_gimbal_adjust = maxf(asin(rest_transform_to_body.basis.z.y) - TAU / 12.0, 0.0)
	_negate_gimbal = offset.dot(rest_transform_to_body.basis.z) < 0.0


func set_from_vehicle_input(angular_input: Vector3, linear_input: Vector3) -> void:
	# Set the gimbal based on angular input.
	if max_gimbal != 0.0:
		var rotated: Vector3 = _rest_quaternion_to_body.inverse() * angular_input
		var gimbal_amount: float = -max_gimbal if _negate_gimbal else max_gimbal
		current_gimbal_ratio = (Vector2(rotated.x, rotated.y) / gimbal_amount).limit_length()
	# Adjust the gimbal based on linear input (optional but significantly improves handling).
	var rot: Quaternion = _rest_quaternion_to_body * _get_gimbal_rotation_quaternion()
	var local_input: Vector3 = rot.inverse() * linear_input
	var max_linear_gimbal_adjust: float = _maximum_linear_gimbal_adjust / max_gimbal
	var linear_gimbal_adjust: Vector2 = Vector2(-local_input.y, local_input.x).limit_length() * max_linear_gimbal_adjust
	current_gimbal_ratio = (current_gimbal_ratio + linear_gimbal_adjust).limit_length()
	# Set the hover ratio based on linear input and angular torque.
	rot = _rest_quaternion_to_body * _get_gimbal_rotation_quaternion()
	var thrust_direction: Vector3 = rot * Vector3(0, 0, 1)
	var thrust_hover: float = maxf(linear_input.dot(thrust_direction), 0.0)
	var torque: Vector3 = position.cross(thrust_direction)
	var torque_hover: float = maxf(angular_input.dot(torque) * TORQUE_STABILIZATION, 0.0)
	current_hover_ratio = clampf(thrust_hover + torque_hover, 0.0, 1.0)


func _get_gimbal_rotation_quaternion() -> Quaternion:
	if current_gimbal_ratio.is_zero_approx() or is_zero_approx(max_gimbal):
		return Quaternion.IDENTITY
	var rot_angles: Vector2 = current_gimbal_ratio.limit_length() * max_gimbal
	var angle_mag: float = rot_angles.length()
	var sin_norm_angle: float = sin(angle_mag / 2.0) / angle_mag
	var cos_half_angle: float = cos(angle_mag / 2.0)
	return Quaternion(rot_angles.x * sin_norm_angle, rot_angles.y * sin_norm_angle, 0.0, cos_half_angle)


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
	var box := BoxMesh.new()
	box.size = Vector3(0.1, 0.1, 4.0)
	mi.mesh = box
	add_child(mi)
