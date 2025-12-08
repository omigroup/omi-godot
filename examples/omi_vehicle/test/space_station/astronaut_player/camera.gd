extends Node3D


func _input(some_input_event: InputEvent) -> void:
	if some_input_event.is_action_pressed(&"ui_cancel"):
		get_tree().quit()


func set_first_person() -> void:
	position = Vector3.ZERO
	rotation = Vector3.ZERO


func set_third_person() -> void:
	position = Vector3(0.0, 2.0, -5.0)
	rotation = Vector3(0.5, 0.0, 0.0)
