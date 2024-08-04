@tool
class_name GLTFVehicleWheel
extends Resource


## The ratio of the maximum force the wheel is using for propulsion.
@export_range(0.0, 1.0, 0.01)
var current_force_ratio: float = 0.0
## The ratio of the maximum steering angle the wheel is rotated to.
@export_range(0.0, 1.0, 0.01)
var current_steering_ratio: float = 0.0
## The maximum force in Newtons (kg⋅m/s²) that the wheel can provide.
@export_custom(PROPERTY_HINT_NONE, "suffix:kg\u22C5m/s\u00B2 (N)")
var max_force: float = 0.0
## The maximum angle in radians that the wheel can steer.
@export_range(0, 90, 0.1, "radians")
var max_steering_angle: float = 0.0
## The index of the physics material in the top level physicsMaterials array.
## TODO: This is currently unimplemented, pending glTF physics material support.
@export var physics_material_index: int = -1
## Godot only uses friction for wheel physics materials, not restitution.
## Godot allows wheel friction to go above 1.0, but this is unrealistic.
@export var physics_material_friction: float = 1.0
## TODO: This is currently unimplemented, pending glTF physics material support.
@export var physics_material: PhysicsMaterial = null
## The radius of the wheel in meters. This is the radius of a circle in the local YZ plane.
@export_custom(PROPERTY_HINT_NONE, "suffix:m")
var radius: float = 0.25
## The damping of the suspension during compression, the resistance to the velocity of the suspension. It is measured in Newton-seconds per meter (N⋅s/m), or kilograms per second (kg/s) in SI base units.
@export_custom(PROPERTY_HINT_NONE, "suffix:kg/s (N\u22C5s/m)")
var suspension_damping_compression: float = 2000.0
## The damping of the suspension during rebound/relaxation, the resistance to the velocity of the suspension. It is measured in Newton-seconds per meter (N⋅s/m), or kilograms per second (kg/s) in SI base units.
@export_custom(PROPERTY_HINT_NONE, "suffix:kg/s (N\u22C5s/m)")
var suspension_damping_rebound: float = 2000.0
## The stiffness of the suspension, the resistance to traveling away from the start point. It is measured in Newtons per meter, or kg/s² in SI base units.
@export_custom(PROPERTY_HINT_NONE, "suffix:kg/s\u00B2 (N/m)")
var suspension_stiffness: float = 20000.0
## The maximum distance the suspension can move up or down in meters.
@export_custom(PROPERTY_HINT_NONE, "suffix:m")
var suspension_travel: float = 0.25
## The width of the wheel in meters. This is the width of the wheel in the local X axis.
## Note: Width is not used by Godot VehicleWheel3D but we will still import/export it to/from glTF.
@export_custom(PROPERTY_HINT_NONE, "suffix:m")
var width: float = 0.125


static func from_node(wheel_node: VehicleWheel3D) -> GLTFVehicleWheel:
	var ret := GLTFVehicleWheel.new()
	ret.current_force_ratio = wheel_node.current_force_ratio
	ret.current_steering_ratio = wheel_node.current_steering_ratio
	ret.max_force = wheel_node.max_force
	ret.max_steering_angle = wheel_node.max_steering_angle
	ret.physics_material_friction = wheel_node.wheel_friction_slip
	ret.radius = wheel_node.wheel_radius
	# Note: Godot uses damping values in Mg/s while glTF uses kg/s.
	ret.suspension_damping_compression = wheel_node.damping_compression * 1000.0
	ret.suspension_damping_rebound = wheel_node.damping_relaxation * 1000.0
	# Note: Godot uses stiffness values in Mg/s² (N/mm) while glTF uses kg/s² (N/m).
	ret.suspension_stiffness = wheel_node.suspension_stiffness * 1000.0
	ret.suspension_travel = wheel_node.suspension_travel
	return ret


func to_node() -> VehicleWheel3D:
	var wheel_node := PilotedVehicleWheel3D.new()
	wheel_node.current_force_ratio = current_force_ratio
	wheel_node.current_steering_ratio = current_steering_ratio
	wheel_node.max_force = max_force
	wheel_node.max_steering_angle = max_steering_angle
	wheel_node.wheel_friction_slip = physics_material_friction
	wheel_node.wheel_radius = radius
	# Note: Godot uses damping values in Mg/s while glTF uses kg/s.
	wheel_node.damping_compression = suspension_damping_compression / 1000.0
	wheel_node.damping_relaxation = suspension_damping_rebound / 1000.0
	# Note: Godot uses stiffness values in Mg/s² (N/mm) while glTF uses kg/s² (N/m).
	wheel_node.suspension_stiffness = suspension_stiffness / 1000.0
	wheel_node.suspension_travel = suspension_travel
	wheel_node.wheel_rest_length = suspension_travel
	return wheel_node


static func from_dictionary(dict: Dictionary) -> GLTFVehicleWheel:
	var ret := GLTFVehicleWheel.new()
	if dict.has("currentForceRatio"):
		ret.current_force_ratio = dict["currentForceRatio"]
	if dict.has("currentSteeringRatio"):
		ret.current_steering_ratio = dict["currentSteeringRatio"]
	if dict.has("maxForce"):
		ret.max_force = dict["maxForce"]
	if dict.has("maxSteeringAngle"):
		ret.max_steering_angle = dict["maxSteeringAngle"]
	if dict.has("physicsMaterial"):
		ret.physics_material_index = dict["physicsMaterial"]
	if dict.has("radius"):
		ret.radius = dict["radius"]
	if dict.has("suspensionDampingCompression"):
		ret.suspension_damping_compression = dict["suspensionDampingCompression"]
	if dict.has("suspensionDampingRebound"):
		ret.suspension_damping_rebound = dict["suspensionDampingRebound"]
	if dict.has("suspensionStiffness"):
		ret.suspension_stiffness = dict["suspensionStiffness"]
	if dict.has("suspensionTravel"):
		ret.suspension_travel = dict["suspensionTravel"]
	if dict.has("width"):
		ret.width = dict["width"]
	return ret


func to_dictionary() -> Dictionary:
	var ret: Dictionary = {}
	if current_force_ratio != 0.0:
		ret["currentForceRatio"] = current_force_ratio
	if current_steering_ratio != 0.0:
		ret["currentSteeringRatio"] = current_steering_ratio
	if max_force != 0.0:
		ret["maxForce"] = max_force
	if max_steering_angle != 0.0:
		ret["maxSteeringAngle"] = max_steering_angle
	if physics_material_index != -1:
		ret["physicsMaterial"] = physics_material_index
	if radius != 0.25:
		ret["radius"] = radius
	if suspension_damping_compression != 500.0:
		ret["suspensionDampingCompression"] = suspension_damping_compression
	if suspension_damping_rebound != 500.0:
		ret["suspensionDampingRebound"] = suspension_damping_rebound
	if suspension_stiffness != 20000.0:
		ret["suspensionStiffness"] = suspension_stiffness
	if suspension_travel != 0.25:
		ret["suspensionTravel"] = suspension_travel
	if width != 0.125:
		ret["width"] = width
	return ret
