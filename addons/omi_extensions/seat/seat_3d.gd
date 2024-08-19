## Defines a seat using a set of control points. Characters can sit on this seat by interacting with it.
@tool
@icon("Seat3D.svg")
class_name Seat3D
extends Area3D


## The character occupying the seat, if any. This is expected to be assigned at runtime.
## Change the type if your characters do not inherit CharacterBody3D.
var occupant: CharacterBody3D

var _back := Vector3(0.0, 0.0, -0.25)
## The seat position control point corresponding to the character's back position.
@export_custom(PROPERTY_HINT_NONE, "suffix:m")
var back := Vector3(0.0, 0.0, -0.25):
	get:
		return _back
	set(value):
		_back = value
		_recalculate_helper_vectors()

var _foot := Vector3(0.0, -0.5, 0.25)
## The seat position control point corresponding to the character's foot position.
@export_custom(PROPERTY_HINT_NONE, "suffix:m")
var foot := Vector3(0.0, -0.5, 0.25):
	get:
		return _foot
	set(value):
		_foot = value
		_recalculate_helper_vectors()

var _knee := Vector3(0.0, 0.0, 0.25)
## The seat position control point corresponding to the character's knee position.
@export_custom(PROPERTY_HINT_NONE, "suffix:m")
var knee := Vector3(0.0, 0.0, 0.25):
	get:
		return _knee
	set(value):
		_knee = value
		_recalculate_helper_vectors()

var _angle: float = TAU * 0.25
## The seat angle between the spine and the back-knee line. Recommended values are close to 90 degrees, and going over is better than going under.
@export_range(10.0, 180.0, 0.1, "radians_as_degrees")
var angle: float = TAU * 0.25:
	get:
		return _angle
	set(value):
		_angle = value
		_recalculate_helper_vectors()

var _right := Vector3.ZERO
var _spine_dir := Vector3.ZERO
var _spine_norm := Vector3.ZERO
var _upper_leg_dir := Vector3.ZERO
var _upper_leg_norm := Vector3.ZERO
var _lower_leg_dir := Vector3.ZERO
var _lower_leg_norm := Vector3.ZERO


func _init() -> void:
	_recalculate_helper_vectors()


func get_right() -> Vector3:
	return _right


func get_spine_dir() -> Vector3:
	return _spine_dir


func get_spine_norm() -> Vector3:
	return _spine_norm


func get_upper_leg_dir() -> Vector3:
	return _upper_leg_dir


func get_upper_leg_norm() -> Vector3:
	return _upper_leg_norm


func get_lower_leg_dir() -> Vector3:
	return _lower_leg_dir


func get_lower_leg_norm() -> Vector3:
	return _lower_leg_norm


func set_points(p_back: Vector3, p_foot: Vector3, p_knee: Vector3, p_angle: float = TAU * 0.25) -> void:
	_back = p_back
	_foot = p_foot
	_knee = p_knee
	_angle = p_angle
	_recalculate_helper_vectors()


func _recalculate_helper_vectors() -> void:
	_upper_leg_dir = back.direction_to(knee)
	_lower_leg_dir = knee.direction_to(foot)
	_right = _lower_leg_dir.cross(_upper_leg_dir).normalized()
	if _right == Vector3.ZERO:
		return
	_spine_dir = _upper_leg_dir.rotated(_right, angle)
	_spine_norm = _spine_dir.cross(_right)
	_upper_leg_norm = _right.cross(_upper_leg_dir)
	_lower_leg_norm = _right.cross(_lower_leg_dir)


static func from_points(p_back: Vector3, p_foot: Vector3, p_knee: Vector3, p_angle: float = TAU * 0.25) -> Seat3D:
	var seat = Seat3D.new()
	seat.set_points(p_back, p_foot, p_knee, p_angle)
	return seat
