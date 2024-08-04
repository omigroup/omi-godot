extends RayCast3D


@export var player_body: CollisionObject3D

var _disembark_transform := Transform3D.IDENTITY
var _current_seat: Seat3D = null

@onready var _camera_holder = $CameraHolder


func _ready() -> void:
	assert(player_body != null)
	assert(player_body.has_method(&"enter_seat"))
	assert(player_body.has_method(&"exit_seat"))


func _process(_delta: float) -> void:
	if _current_seat != null:
		player_body.transform = _current_seat.global_transform
		if Input.is_action_just_pressed(&"interact"):
			_exit_seat()
		return
	if is_colliding():
		var area: Area3D = get_collider()
		var area_shape = area.get_child(0)
		if area_shape is CollisionShape3D and area_shape.shape is BoxShape3D:
			ObjectOutlines.draw_wireframe_box(area_shape, Color.CYAN)
		if area is Seat3D and Input.is_action_just_pressed(&"interact"):
			_enter_seat(area)
			return


func _enter_seat(seat: Seat3D) -> void:
	_current_seat = seat
	_camera_holder.set_third_person()
	var seat_transform: Transform3D = seat.global_transform
	var prev_transform: Transform3D = player_body.enter_seat(seat_transform)
	_disembark_transform = seat_transform.inverse() * prev_transform
	if seat is PilotSeat3D:
		seat.enter_pilot_seat(player_body)


func _exit_seat() -> void:
	if _current_seat is PilotSeat3D:
		_current_seat.exit_pilot_seat()
	var seat_transform: Transform3D = _current_seat.global_transform
	var exit_transform = seat_transform * _disembark_transform
	var exit_velocity := Vector3.ZERO
	if _current_seat is PilotSeat3D:
		var vehicle: RigidBody3D = _current_seat.piloted_vehicle_node
		if vehicle != null:
			exit_velocity = vehicle.linear_velocity
	player_body.exit_seat(exit_transform, exit_velocity)
	_camera_holder.set_first_person()
	_current_seat = null
