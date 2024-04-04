class_name GlobalGravitySetter
extends Node


@export var gravity: float = 9.80665
@export var direction: Vector3 = Vector3.DOWN


func _ready() -> void:
	var world_space_rid: RID = get_viewport().find_world_3d().space
	PhysicsServer3D.area_set_param(world_space_rid, PhysicsServer3D.AREA_PARAM_GRAVITY, gravity)
	PhysicsServer3D.area_set_param(world_space_rid, PhysicsServer3D.AREA_PARAM_GRAVITY_VECTOR, direction)
	queue_free()
