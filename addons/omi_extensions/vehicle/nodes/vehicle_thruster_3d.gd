## General-purpose thruster for vehicles. Has a gimbal and emits a force.
## VehicleThruster3D can be used to create rocket engines, jet engines, control thrusters, or any other kind of thruster.
@icon("icons/VehicleThruster3D.svg")
class_name VehicleThruster3D
extends Node3D


## If false, the thruster will not gimbal or apply forces.
@export var enabled: bool = true
## The ratio of the maximum thrust force the thruster is currently using for propulsion.
@export_range(0.0, 1.0, 0.01)
var current_force_ratio: float = 0.0
## The ratio of the maximum gimbal angles the thruster is rotated to. The vector length may not be longer than 1.0. Note: Gimbal must be set before adding the node to the tree.
@export var current_gimbal_ratio := Vector2(0.0, 0.0)
## The maximum thrust force in Newtons (kg⋅m/s²) that the thruster can provide.
@export_custom(PROPERTY_HINT_NONE, "suffix:kg\u22C5m/s\u00B2 (N)")
var max_force: float = 0.0
## The maximum angle the thruster can gimbal or rotate in radians. Note: Gimbal must be set before adding the node to the tree.
@export_custom(PROPERTY_HINT_NONE, "suffix:rad")
var max_gimbal: float = 0.0

var _parent_body: RigidBody3D = null
var _particles_node: GPUParticles3D = null

var _parent_transform_to_body := Transform3D.IDENTITY
var _parent_quaternion_to_body := Quaternion.IDENTITY
var _rest_quaternion := Quaternion.IDENTITY
var _body_to_rest_quaternion := Quaternion.IDENTITY
var _negate_gimbal: bool = true


func _enter_tree() -> void:
	_parent_body = _get_parent_body()
	recalculate_transforms()


func _ready() -> void:
	for child in get_children():
		if child is GPUParticles3D:
			_particles_node = child
			break


func _physics_process(delta: float) -> void:
	if _parent_body == null or not enabled:
		if _particles_node:
			_particles_node.amount_ratio = 0.0
		return
	quaternion = _rest_quaternion * _get_gimbal_rotation_quaternion()
	if _particles_node:
		_particles_node.amount_ratio = current_force_ratio
	if _parent_body == null:
		return
	var force_amount: float = current_force_ratio * max_force
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
	_body_to_rest_quaternion = (_parent_quaternion_to_body * _rest_quaternion).inverse()
	var rest_transform_to_body: Transform3D = _parent_transform_to_body * Transform3D(Basis(_rest_quaternion), position)
	var offset: Vector3 = rest_transform_to_body.origin - _parent_body.center_of_mass
	_negate_gimbal = offset.dot(rest_transform_to_body.basis.z) < 0.0


func set_gimbal_from_vehicle_angular_input(angular_input: Vector3) -> void:
	var rotated: Vector3 = _body_to_rest_quaternion * angular_input
	var gimbal_amount: float = -max_gimbal if _negate_gimbal else max_gimbal
	current_gimbal_ratio = Vector2(rotated.x, rotated.y) / gimbal_amount


func set_thrust_from_vehicle_linear_input(linear_input: Vector3) -> void:
	var thrust_direction: Vector3 = (_parent_quaternion_to_body * quaternion) * Vector3(0.0, 0.0, 1.0)
	current_force_ratio = clampf(linear_input.dot(thrust_direction), 0.0, 1.0)


func _get_gimbal_rotation_quaternion() -> Quaternion:
	if current_gimbal_ratio.is_zero_approx() or is_zero_approx(max_gimbal):
		return Quaternion.IDENTITY
	var rot_angles: Vector2 = current_gimbal_ratio.limit_length() * max_gimbal
	var angle_mag: float = rot_angles.length()
	var sin_norm_angle: float = sin(angle_mag * 0.5) / angle_mag
	var cos_half_angle: float = cos(angle_mag * 0.5)
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
