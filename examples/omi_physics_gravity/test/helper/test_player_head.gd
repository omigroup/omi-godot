extends Node3D


const SENSITIVITY = 0.002

@export var player_body: CharacterBody3D

var pitch: float = 0.0
var yaw: float = 0.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _input(input_event: InputEvent) -> void:
	if input_event is InputEventMouseMotion:
		pitch = clampf(pitch - input_event.relative.y * SENSITIVITY, -1.57, 1.57)
		yaw -= input_event.relative.x * SENSITIVITY
	elif input_event.is_action_pressed(&"ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _physics_process(_delta: float) -> void:
	rotation = Vector3(pitch, 0.0, 0.0)
	player_body.rotate_object_local(Vector3.UP, yaw)
	yaw = 0.0
