extends CharacterBody3D


const INERTIA_DAMPENER_RATE_LINEAR: float = 1.0
const TARGET_SPEED: float = 5.0
const MOUSE_SENSITIVITY: float = 0.1

var _mouse_input := Vector2.ZERO
var _look_rotation := Vector2.ZERO

@onready var pitch: Node3D = $CollisionShape3D/SeatInteractRay
@onready var shape: CollisionShape3D = $CollisionShape3D


func _process(delta: float) -> void:
	var rotation_change := Vector2(
		Input.get_axis(&"rotate_pitch_up", &"rotate_pitch_down"),
		Input.get_axis(&"rotate_yaw_right", &"rotate_yaw_left"),
	)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	rotation_change.x += _mouse_input.y * MOUSE_SENSITIVITY
	rotation_change.y -= _mouse_input.x * MOUSE_SENSITIVITY
	_look_rotation += rotation_change * delta
	shape.basis = Basis.from_euler(Vector3(0.0, _look_rotation.y, 0.0))
	pitch.basis = Basis.from_euler(Vector3(_look_rotation.x, 0.0, 0.0))
	_mouse_input = Vector2.ZERO


func _physics_process(delta: float) -> void:
	var shape_global_basis: Basis = shape.global_basis
	var global_to_local_rot: Basis = shape_global_basis.inverse()
	var linear_input: Vector2 = Input.get_vector(&"move_right", &"move_left", &"move_back", &"move_forward")
	linear_input = linear_input.rotated(-_look_rotation.y)
	velocity = Vector3(linear_input.x, velocity.y, linear_input.y)
	move_and_slide()
	#velocity += get_gravity()
	#linear_input = linear_input.clampf(-1.0, 1.0) * JETPACK_FORCE
	#apply_central_impulse(shape_global_basis * linear_input)


func _unhandled_input(input_event: InputEvent) -> void:
	if input_event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			_mouse_input += input_event.relative


func enter_seat(seat_transform: Transform3D) -> void:
	transform = seat_transform
	shape.basis = Basis.IDENTITY
	process_mode = Node.PROCESS_MODE_DISABLED


func exit_seat(exit_transform: Transform3D, exit_velocity: Vector3) -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	velocity = exit_velocity
	basis = Basis.IDENTITY
	position = exit_transform.origin
	shape.basis = Basis.from_euler(Vector3(0.0, exit_transform.basis.get_euler().y, 0.0))
