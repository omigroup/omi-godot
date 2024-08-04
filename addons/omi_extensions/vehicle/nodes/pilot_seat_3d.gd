## A Seat3D designed for its occupant to pilot a PilotedVehicleBody3D node.
@tool
@icon("icons/PilotSeat3D.svg")
class_name PilotSeat3D
extends Seat3D


enum ControlScheme {
	## Automatically determine the control scheme based on the vehicle's components.
	AUTO,
	## Uses WS for forward/back movement and AD for steering, like most driving games.
	CAR,
	## Uses WASDRF for linear movement, QE roll, mouse pitch/yaw, or IJKLUO rotation.
	SIX_DOF,
	## Uses WASDQE for rotation, with W as up and S as down, Shift throttle up, Ctrl throttle down.
	NAVBALL,
	## Uses WASDQE for rotation, with W as down and S as up, like Kerbal Space Program.
	NAVBALL_INVERTED,
	## Like SIX_DOF but flattens the horizontal WASD input, good for hovercrafts.
	HORIZONTAL_SIX_DOF,
}

const MOUSE_SENSITIVITY: float = 0.1
const THROTTLE_RATE: float = 0.5

## The control scheme to use. More can be added by editing pilot_seat_3d.gd.
@export var control_scheme := ControlScheme.AUTO

## Will be automatically when player_node is assigned to.
## Can also be overridden for custom use cases.
@export var use_local_controls: bool = false

@export var piloted_vehicle_node: PilotedVehicleBody3D = null:
	set(value):
		piloted_vehicle_node = value
		if piloted_vehicle_node.pilot_seat_node != self:
			piloted_vehicle_node.pilot_seat_node = self

## Should be set at runtime when a player enters the pilot seat.
@export var _player_node: Node3D = null

var _mouse_input := Vector2.ZERO


func _ready() -> void:
	if piloted_vehicle_node == null:
		var parent: Node = get_parent()
		if parent is PilotedVehicleBody3D:
			piloted_vehicle_node = parent
	if piloted_vehicle_node != null:
		piloted_vehicle_node.pilot_seat_node = self
	if Engine.is_editor_hint():
		return


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or not use_local_controls or piloted_vehicle_node == null:
		return
	var actual_control_scheme: ControlScheme = _get_actual_control_scheme()
	var angular_input: Vector3 = _get_angular_input(actual_control_scheme)
	var linear_input: Vector3 = _get_linear_input(actual_control_scheme)
	_mouse_input = Vector2.ZERO
	if Input.is_action_just_pressed(&"toggle_linear_dampeners"):
		piloted_vehicle_node.linear_dampeners = not piloted_vehicle_node.linear_dampeners
	piloted_vehicle_node.angular_activation = angular_input
	if Input.is_action_pressed(&"throttle_zero"):
		piloted_vehicle_node.linear_activation = Vector3.ZERO
	elif piloted_vehicle_node.use_throttle:
		var change: Vector3 = (delta * THROTTLE_RATE) * linear_input
		piloted_vehicle_node.linear_activation = (piloted_vehicle_node.linear_activation + change).clampf(-1.0, 1.0)
	else:
		piloted_vehicle_node.linear_activation = linear_input


func _unhandled_input(input_event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if input_event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			_mouse_input += input_event.relative


func enter_pilot_seat(player: Node3D) -> void:
	assert(player != null)
	_player_node = player
	use_local_controls = player.is_multiplayer_authority()


func exit_pilot_seat() -> void:
	_player_node = null
	use_local_controls = false
	if piloted_vehicle_node:
		piloted_vehicle_node.angular_activation = Vector3.ZERO
		piloted_vehicle_node.linear_activation = Vector3.ZERO


func _get_actual_control_scheme() -> ControlScheme:
	if control_scheme != ControlScheme.AUTO:
		return control_scheme
	if piloted_vehicle_node.use_throttle:
		return ControlScheme.NAVBALL
	if piloted_vehicle_node.has_wheels():
		return ControlScheme.CAR
	if piloted_vehicle_node.has_hover_thrusters():
		return ControlScheme.HORIZONTAL_SIX_DOF
	return ControlScheme.SIX_DOF


func _get_angular_input(actual_control_scheme: ControlScheme) -> Vector3:
	match actual_control_scheme:
		ControlScheme.CAR:
			return Vector3(
				Input.get_axis(&"rotate_pitch_up", &"rotate_pitch_down"),
				Input.get_axis(&"move_right", &"move_left"),
				Input.get_axis(&"rotate_yaw_left", &"rotate_yaw_right")
			)
		ControlScheme.NAVBALL:
			return Vector3(
				Input.get_axis(&"move_forward", &"move_back"),
				Input.get_axis(&"move_right", &"move_left"),
				Input.get_axis(&"rotate_roll_ccw", &"rotate_roll_clockwise"),
			)
		ControlScheme.NAVBALL_INVERTED:
			return Vector3(
				Input.get_axis(&"move_back", &"move_forward"),
				Input.get_axis(&"move_right", &"move_left"),
				Input.get_axis(&"rotate_roll_ccw", &"rotate_roll_clockwise"),
			)
	var angular_input := Vector3(
		Input.get_axis(&"rotate_pitch_up", &"rotate_pitch_down"),
		Input.get_axis(&"rotate_yaw_right", &"rotate_yaw_left"),
		Input.get_axis(&"rotate_roll_ccw", &"rotate_roll_clockwise")
	)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	angular_input.x += _mouse_input.y * MOUSE_SENSITIVITY
	angular_input.y -= _mouse_input.x * MOUSE_SENSITIVITY
	return angular_input


func _get_linear_input(actual_control_scheme: ControlScheme) -> Vector3:
	match actual_control_scheme:
		ControlScheme.CAR:
			return Vector3(
				Input.get_axis(&"rotate_roll_clockwise", &"rotate_roll_ccw"),
				Input.get_axis(&"move_down", &"move_up"),
				Input.get_axis(&"move_back", &"move_forward")
			)
		ControlScheme.NAVBALL:
			return Vector3(
				Input.get_axis(&"rotate_yaw_right", &"rotate_yaw_left"),
				Input.get_axis(&"rotate_pitch_down", &"rotate_pitch_up"),
				Input.get_axis(&"throttle_decrease", &"throttle_increase")
			)
		ControlScheme.NAVBALL_INVERTED:
			return Vector3(
				Input.get_axis(&"rotate_yaw_right", &"rotate_yaw_left"),
				Input.get_axis(&"rotate_pitch_down", &"rotate_pitch_up"),
				Input.get_axis(&"throttle_decrease", &"throttle_increase")
			)
		ControlScheme.HORIZONTAL_SIX_DOF:
			var vehicle_euler: Vector3 = piloted_vehicle_node.basis.get_euler()
			var flatten := Basis.from_euler(Vector3(-vehicle_euler.x, 0.0, -vehicle_euler.z))
			return flatten * Vector3(
				Input.get_axis(&"move_right", &"move_left"),
				Input.get_axis(&"move_down", &"move_up"),
				Input.get_axis(&"move_back", &"move_forward")
			)
	return Vector3(
		Input.get_axis(&"move_right", &"move_left"),
		Input.get_axis(&"move_down", &"move_up"),
		Input.get_axis(&"move_back", &"move_forward")
	)


static func from_points(p_back: Vector3, p_foot: Vector3, p_knee: Vector3, p_angle: float = TAU * 0.25) -> PilotSeat3D:
	var seat = PilotSeat3D.new()
	seat.set_points(p_back, p_foot, p_knee, p_angle)
	return seat
