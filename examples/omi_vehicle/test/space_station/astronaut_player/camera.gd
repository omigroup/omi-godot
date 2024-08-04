extends Node3D


func set_first_person() -> void:
	position = Vector3.ZERO
	rotation = Vector3.ZERO


func set_third_person() -> void:
	position = Vector3(0.0, 2.0, -5.0)
	rotation = Vector3(0.5, 0.0, 0.0)
