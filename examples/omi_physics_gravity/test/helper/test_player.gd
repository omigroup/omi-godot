extends CharacterBody3D


const FOOT_OFFSET = Vector3(0.0, 0.75, 0.0)

@export var movement_speed: float = 5.0
@export var jump_velocity: float = 4.5

var horizontal_velocity := Vector3.ZERO
var gravity_last_frame := Vector3.ZERO

@onready var initial_position: Vector3 = position
@onready var ray_cast: RayCast3D = $RayCast3D


func _ready() -> void:
	var spring_arm: SpringArm3D = $TestPlayerHead
	spring_arm.add_excluded_object(get_rid())


func _physics_process(delta: float) -> void:
	if Input.is_action_pressed(&"reset"):
		position = initial_position
		velocity = Vector3.ZERO
		return
	var gravity: Vector3 = (get_gravity() + gravity_last_frame) * 0.5
	_rotate_to_gravity(gravity)
	if ray_cast.is_colliding():
		if Input.is_action_pressed(&"jump"):
			velocity = velocity.slide(basis.y)
			velocity += jump_velocity * basis.y
		else:
			position = ray_cast.get_collision_point() + basis * FOOT_OFFSET
			velocity = Vector3.ZERO
			_ground_movement()
	else:
		# Add the gravity.
		velocity += gravity * delta
	move_and_slide()
	gravity_last_frame = gravity


func _rotate_to_gravity(gravity: Vector3) -> void:
	if gravity.is_zero_approx():
		return
	var b: Basis = basis
	b.y = -gravity.normalized()
	b.z = b.x.cross(b.y).normalized()
	b.x = b.y.cross(b.z).normalized()
	basis = b


func _ground_movement() -> void:
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = Vector3(input_dir.x, 0, input_dir.y)
	if direction:
		horizontal_velocity.x = direction.x * movement_speed
		horizontal_velocity.z = direction.z * movement_speed
	else:
		horizontal_velocity.x = move_toward(horizontal_velocity.x, 0, movement_speed)
		horizontal_velocity.z = move_toward(horizontal_velocity.z, 0, movement_speed)
	velocity += basis * horizontal_velocity
