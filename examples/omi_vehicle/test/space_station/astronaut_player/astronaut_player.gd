extends RigidBody3D


const INERTIA_DAMPENER_RATE_LINEAR: float = 1.0
const JETPACK_FORCE: float = 500.0
const MOUSE_SENSITIVITY: float = 0.1

var _mouse_input := Vector2.ZERO

@onready var shape: CollisionShape3D = $CollisionShape3D


func _process(delta: float) -> void:
	var angular_input := Vector3(
		Input.get_axis(&"rotate_pitch_up", &"rotate_pitch_down"),
		Input.get_axis(&"rotate_yaw_right", &"rotate_yaw_left"),
		Input.get_axis(&"rotate_roll_ccw", &"rotate_roll_clockwise")
	)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	angular_input.x += _mouse_input.y * MOUSE_SENSITIVITY
	angular_input.y -= _mouse_input.x * MOUSE_SENSITIVITY
	shape.basis *= Basis.from_euler(angular_input * delta)
	_mouse_input = Vector2.ZERO


func _physics_process(delta: float) -> void:
	var shape_global_basis: Basis = shape.global_basis
	var global_to_local_rot: Basis = shape_global_basis.inverse()
	var local_linear: Vector3 = global_to_local_rot * get_linear_velocity()
	var linear_input := Vector3(
		Input.get_axis(&"move_right", &"move_left"),
		Input.get_axis(&"move_down", &"move_up"),
		Input.get_axis(&"move_back", &"move_forward")
	).limit_length(1.0)
	if is_zero_approx(linear_input.x):
		linear_input.x = local_linear.x * -INERTIA_DAMPENER_RATE_LINEAR
	if is_zero_approx(linear_input.y):
		linear_input.y = local_linear.y * -INERTIA_DAMPENER_RATE_LINEAR
	if is_zero_approx(linear_input.z):
		linear_input.z = local_linear.z * -INERTIA_DAMPENER_RATE_LINEAR
	linear_input = linear_input.clampf(-1.0, 1.0) * JETPACK_FORCE
	apply_central_force(shape_global_basis * linear_input)


func _unhandled_input(input_event: InputEvent) -> void:
	if input_event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			_mouse_input += input_event.relative


func enter_seat(seat_transform: Transform3D) -> Transform3D:
	var prev_transform := Transform3D(shape.basis, position)
	transform = seat_transform
	shape.basis = Basis.IDENTITY
	process_mode = Node.PROCESS_MODE_DISABLED
	return prev_transform


func exit_seat(exit_transform: Transform3D, exit_velocity: Vector3) -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	linear_velocity = exit_velocity
	position = exit_transform.origin
	basis = Basis.IDENTITY
	shape.basis = exit_transform.basis
