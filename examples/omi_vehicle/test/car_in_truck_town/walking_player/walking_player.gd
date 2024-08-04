extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY: float = 0.1

var _mouse_input := Vector2.ZERO
var _look_rotation := Vector2.ZERO

@onready var view_node: Node3D = $CollisionShape3D/SeatInteractRay


func _process(delta: float) -> void:
	var rotation_change := Vector2(
		Input.get_axis(&"rotate_pitch_up", &"rotate_pitch_down"),
		Input.get_axis(&"rotate_yaw_right", &"rotate_yaw_left"),
	)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	rotation_change.x += _mouse_input.y * MOUSE_SENSITIVITY
	rotation_change.y -= _mouse_input.x * MOUSE_SENSITIVITY
	_look_rotation += rotation_change * delta
	view_node.basis = Basis.from_euler(Vector3(_look_rotation.x, _look_rotation.y, 0.0))
	_mouse_input = Vector2.ZERO


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir: Vector2 = Input.get_vector(&"move_right", &"move_left", &"move_back", &"move_forward")
	input_dir = input_dir.rotated(-_look_rotation.y)
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()


func _unhandled_input(mouse_input_event: InputEvent) -> void:
	if mouse_input_event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			_mouse_input += mouse_input_event.relative


func enter_seat(seat_transform: Transform3D) -> Transform3D:
	var prev_transform := Transform3D(view_node.basis, position)
	transform = seat_transform
	view_node.basis = Basis.IDENTITY
	process_mode = Node.PROCESS_MODE_DISABLED
	return prev_transform


func exit_seat(exit_transform: Transform3D, exit_velocity: Vector3) -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	velocity = exit_velocity
	position = exit_transform.origin
	basis = Basis.IDENTITY
	_look_rotation.y = exit_transform.basis.get_euler().y
	view_node.basis = Basis.from_euler(Vector3(_look_rotation.x, _look_rotation.y, 0.0))
