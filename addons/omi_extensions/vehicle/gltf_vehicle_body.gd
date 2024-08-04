@tool
class_name GLTFVehicleBody
extends Resource


## The input value controlling the ratio of the vehicle's angular forces.
@export var angular_activation := Vector3.ZERO
## The input value controlling the ratio of the vehicle's linear forces.
@export var linear_activation := Vector3.ZERO
## The gyroscope torque intrinsic to the vehicle, excluding torque from parts, measured in Newton-meters per radian (kg⋅m²/s²/rad).
@export_custom(PROPERTY_HINT_NONE, "suffix:kg\u22C5m\u00B2/s\u00B2/rad (N\u22C5m/rad)")
var gyroscope_torque := Vector3.ZERO
## If non-negative, the speed in meters per second at which the vehicle should stop driving acceleration further.
@export var max_speed: float = -1.0
## The index of the `OMI_seat` glTF node to use as the pilot / driver seat.
@export var pilot_seat_index: int = -1
## The Godot node to use as the pilot seat / driver seat.
var pilot_seat_node: Node3D = null
## If true, the vehicle should slow its rotation down when not given angular activation input for a specific rotation.
@export var angular_dampeners: bool = true
## If true, the vehicle should slow itself down when not given linear activation input for a specific direction.
@export var linear_dampeners: bool = false
## If true, the vehicle should use a throttle for linear movement. If max_speed is non-negative, the throttle should be a ratio of that speed, otherwise it should be a ratio of thrust power.
@export var use_throttle: bool = false


static func from_node(vehicle_node: VehicleBody3D) -> GLTFVehicleBody:
	var ret := GLTFVehicleBody.new()
	if vehicle_node is PilotedVehicleBody3D:
		ret.angular_activation = vehicle_node.angular_activation
		ret.linear_activation = vehicle_node.linear_activation
		ret.gyroscope_torque = vehicle_node.gyroscope_torque
		ret.max_speed = vehicle_node.max_speed
		ret.pilot_seat_node = vehicle_node.pilot_seat_node
		ret.angular_dampeners = vehicle_node.angular_dampeners
		ret.linear_dampeners = vehicle_node.linear_dampeners
		ret.use_throttle = vehicle_node.use_throttle
	return ret


func to_node(gltf_state: GLTFState, gltf_node: GLTFNode) -> PilotedVehicleBody3D:
	# Set up the body node.
	var vehicle_node := PilotedVehicleBody3D.new()
	var gltf_physics_body: GLTFPhysicsBody = gltf_node.get_additional_data(&"GLTFPhysicsBody")
	if gltf_physics_body == null:
		printerr("GLTF vehicle body: Expected the vehicle body to also be a physics body. Continuing anyway.")
	else:
		vehicle_node.mass = gltf_physics_body.mass
		vehicle_node.linear_velocity = gltf_physics_body.linear_velocity
		vehicle_node.angular_velocity = gltf_physics_body.angular_velocity
		vehicle_node.inertia = gltf_physics_body.inertia_diagonal
		vehicle_node.center_of_mass = gltf_physics_body.center_of_mass
	vehicle_node.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	# If there is a collider shape, set it up.
	var gltf_collider_shape: GLTFPhysicsShape = gltf_node.get_additional_data(&"GLTFPhysicsColliderShape")
	if gltf_collider_shape != null:
		_setup_shape_mesh_resource_from_index_if_needed(gltf_state, gltf_collider_shape)
		var col_shape: CollisionShape3D = gltf_collider_shape.to_node(true)
		col_shape.name = gltf_node.resource_name + "Collider"
		vehicle_node.add_child(col_shape)
	# Set up the vehicle properties.
	vehicle_node.angular_activation = angular_activation
	vehicle_node.linear_activation = linear_activation
	vehicle_node.gyroscope_torque = gyroscope_torque
	vehicle_node.max_speed = max_speed
	vehicle_node.angular_dampeners = angular_dampeners
	vehicle_node.linear_dampeners = linear_dampeners
	vehicle_node.use_throttle = use_throttle
	return vehicle_node


static func from_dictionary(dict: Dictionary) -> GLTFVehicleBody:
	var ret := GLTFVehicleBody.new()
	if dict.has("angularActivation"):
		var ang_arr: Array = dict["angularActivation"]
		ret.angular_activation = Vector3(ang_arr[0], ang_arr[1], ang_arr[2])
	if dict.has("linearActivation"):
		var lin_arr: Array = dict["linearActivation"]
		ret.linear_activation = Vector3(lin_arr[0], lin_arr[1], lin_arr[2])
	if dict.has("gyroTorque"):
		var gyro_arr: Array = dict["gyroTorque"]
		ret.gyroscope_torque = Vector3(gyro_arr[0], gyro_arr[1], gyro_arr[2])
	if dict.has("maxSpeed"):
		ret.max_speed = dict["maxSpeed"]
	if dict.has("pilotSeat"):
		ret.pilot_seat_index = dict["pilotSeat"]
	if dict.has("angularDampeners"):
		ret.angular_dampeners = dict["angularDampeners"]
	if dict.has("linearDampeners"):
		ret.linear_dampeners = dict["linearDampeners"]
	if dict.has("useThrottle"):
		ret.use_throttle = dict["useThrottle"]
	return ret


func to_dictionary() -> Dictionary:
	var ret: Dictionary = {}
	if angular_activation != Vector3.ZERO:
		ret["angularActivation"] = [angular_activation.x, angular_activation.y, angular_activation.z]
	if linear_activation != Vector3.ZERO:
		ret["linearActivation"] = [linear_activation.x, linear_activation.y, linear_activation.z]
	if gyroscope_torque != Vector3.ZERO:
		ret["gyroTorque"] = [gyroscope_torque.x, gyroscope_torque.y, gyroscope_torque.z]
	if max_speed != -1.0:
		ret["maxSpeed"] = max_speed
	if pilot_seat_index != -1:
		ret["pilotSeat"] = pilot_seat_index
	if not angular_dampeners: # Default is true.
		ret["angularDampeners"] = angular_dampeners
	if linear_dampeners:
		ret["linearDampeners"] = linear_dampeners
	if use_throttle:
		ret["useThrottle"] = use_throttle
	return ret


func _setup_shape_mesh_resource_from_index_if_needed(gltf_state: GLTFState, gltf_shape: GLTFPhysicsShape) -> void:
	var shape_mesh_index: int = gltf_shape.mesh_index
	if shape_mesh_index == -1:
		return # No mesh for this shape.
	var importer_mesh: ImporterMesh = gltf_shape.importer_mesh
	if importer_mesh != null:
		return # The mesh resource is already set up.
	var state_meshes: Array[GLTFMesh] = gltf_state.meshes
	var gltf_mesh: GLTFMesh = state_meshes[shape_mesh_index]
	importer_mesh = gltf_mesh.mesh
	gltf_shape.importer_mesh = importer_mesh
