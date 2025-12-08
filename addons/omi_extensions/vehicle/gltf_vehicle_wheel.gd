@tool
class_name GLTFVehicleWheel
extends Resource

# Steering
## The maximum angle in radians that the wheel can steer.
@export_range(0, 90, 0.1, "radians")
var max_steering_angle: float = 0.0
## The speed at which the wheel steering angle changes, in radians per second.
@export var steering_radians_per_second: float = 1.0
## The ratio of the maximum steering angle the wheel is targeting to be rotated to.
@export_range(-1.0, 1.0, 0.01)
var target_steering_ratio: float = 0.0

# Force
## The maximum force in Newtons (kg⋅m/s²) that the wheel can provide.
@export_custom(PROPERTY_HINT_NONE, "suffix:N (kg\u22C5m/s\u00B2)")
var max_propulsion_force: float = 0.0
## The maximum braking force in Newtons (kg⋅m/s²) that the wheel can provide. If negative or not specified, use propulsion force for braking.
@export_custom(PROPERTY_HINT_NONE, "suffix:N (kg\u22C5m/s\u00B2)")
var braking_force: float = -1.0
## The speed at which the wheel propulsion force changes, in Newtons per second. If negative, the force changes instantly.
@export_custom(PROPERTY_HINT_NONE, "suffix:N/s (kg\u22C5m/s\u00B3)")
var propulsion_force_change_per_second: float = -1.0
## The ratio of the maximum force the wheel is targeting for propulsion.
@export_range(-1.0, 1.0, 0.01)
var target_propulsion_force_ratio: float = 0.0

# Physics Material
## The index of the physics material in the top level physicsMaterials array.
## TODO: This is currently unimplemented, pending glTF physics material support.
@export var physics_material_index: int = -1
## Godot only uses friction for wheel physics materials, not restitution.
## Godot allows wheel friction to go above 1.0, but this is unrealistic.
@export var physics_material_friction: float = 1.0
## TODO: This is currently unimplemented, pending glTF physics material support.
@export var physics_material: PhysicsMaterial = null

# Size
## The radius of the wheel in meters. This is the radius of a circle in the local YZ plane.
@export_custom(PROPERTY_HINT_NONE, "suffix:m")
var radius: float = 0.25
## The width of the wheel in meters. This is the width of the wheel in the local X axis.
## Note: Width is not used by Godot VehicleWheel3D but we will still import/export it to/from glTF.
@export_custom(PROPERTY_HINT_NONE, "suffix:m")
var width: float = 0.125

# Suspension
## The damping of the suspension during compression, the resistance to the velocity of the suspension. It is measured in Newton-seconds per meter (N⋅s/m), or kilograms per second (kg/s) in SI base units.
@export_custom(PROPERTY_HINT_NONE, "suffix:N\u22C5s/m (kg/s)")
var suspension_damping_compression: float = 2000.0
## The damping of the suspension during rebound/relaxation, the resistance to the velocity of the suspension. It is measured in Newton-seconds per meter (N⋅s/m), or kilograms per second (kg/s) in SI base units.
@export_custom(PROPERTY_HINT_NONE, "suffix:N\u22C5s/m (kg/s)")
var suspension_damping_rebound: float = 2000.0
## The stiffness of the suspension, the resistance to traveling away from the start point. It is measured in Newtons per meter, or kg/s² in SI base units.
@export_custom(PROPERTY_HINT_NONE, "suffix:N/m (kg/s\u00B2)")
var suspension_stiffness: float = 20000.0
## The maximum distance the suspension can move up or down in meters.
@export_custom(PROPERTY_HINT_NONE, "suffix:m")
var suspension_travel: float = 0.25


static func from_node(wheel_node: VehicleWheel3D) -> GLTFVehicleWheel:
	var ret := GLTFVehicleWheel.new()
	if wheel_node is PilotedVehicleWheel3D:
		# Steering
		ret.max_steering_angle = wheel_node.max_steering_angle
		ret.steering_radians_per_second = wheel_node.steering_radians_per_second
		ret.target_steering_ratio = wheel_node.target_steering_ratio
		# Force
		ret.max_propulsion_force = wheel_node.max_propulsion_force
		ret.braking_force = wheel_node.braking_force
		ret.propulsion_force_change_per_second = wheel_node.propulsion_force_change_per_second
		ret.target_propulsion_force_ratio = wheel_node.target_propulsion_force_ratio
	# Physics Material
	ret.physics_material_friction = wheel_node.wheel_friction_slip
	# Size
	ret.radius = wheel_node.wheel_radius
	# Suspension
	# Note: Godot uses damping values in Mg/s while glTF uses kg/s.
	ret.suspension_damping_compression = wheel_node.damping_compression * 1000.0
	ret.suspension_damping_rebound = wheel_node.damping_relaxation * 1000.0
	# Note: Godot uses stiffness values in Mg/s² (N/mm) while glTF uses kg/s² (N/m).
	ret.suspension_stiffness = wheel_node.suspension_stiffness * 1000.0
	ret.suspension_travel = wheel_node.suspension_travel
	return ret


func to_node() -> PilotedVehicleWheel3D:
	var wheel_node := PilotedVehicleWheel3D.new()
	# Steering
	wheel_node.max_steering_angle = max_steering_angle
	wheel_node.steering_radians_per_second = steering_radians_per_second
	wheel_node.target_steering_ratio = target_steering_ratio
	# Force
	wheel_node.max_propulsion_force = max_propulsion_force
	wheel_node.braking_force = braking_force
	wheel_node.propulsion_force_change_per_second = propulsion_force_change_per_second
	wheel_node.target_propulsion_force_ratio = target_propulsion_force_ratio
	# Physics Material
	wheel_node.wheel_friction_slip = physics_material_friction
	# Size
	wheel_node.wheel_radius = radius
	# Suspension
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
	if dict.has("brakingForce"):
		ret.braking_force = dict["brakingForce"]
	if dict.has("maxPropulsionForce"):
		ret.max_propulsion_force = dict["maxPropulsionForce"]
	if dict.has("maxSteeringAngle"):
		ret.max_steering_angle = dict["maxSteeringAngle"]
	if dict.has("physicsMaterial"):
		ret.physics_material_index = dict["physicsMaterial"]
	if dict.has("propulsionForceChangeRate"):
		ret.propulsion_force_change_per_second = dict["propulsionForceChangeRate"]
	if dict.has("radius"):
		ret.radius = dict["radius"]
	if dict.has("steeringChangeRate"):
		ret.steering_radians_per_second = dict["steeringChangeRate"]
	if dict.has("suspensionDampingCompression"):
		ret.suspension_damping_compression = dict["suspensionDampingCompression"]
	if dict.has("suspensionDampingRebound"):
		ret.suspension_damping_rebound = dict["suspensionDampingRebound"]
	if dict.has("suspensionStiffness"):
		ret.suspension_stiffness = dict["suspensionStiffness"]
	if dict.has("suspensionTravel"):
		ret.suspension_travel = dict["suspensionTravel"]
	if dict.has("targetPropulsionForceRatio"):
		ret.target_propulsion_force_ratio = dict["targetPropulsionForceRatio"]
	if dict.has("targetSteeringRatio"):
		ret.target_steering_ratio = dict["targetSteeringRatio"]
	if dict.has("width"):
		ret.width = dict["width"]
	return ret


func to_dictionary() -> Dictionary:
	var ret: Dictionary = {}
	# Alphabetical order when converting to Dictionary.
	if braking_force != -1.0:
		ret["brakingForce"] = braking_force
	if max_propulsion_force != 0.0:
		ret["maxPropulsionForce"] = max_propulsion_force
	if max_steering_angle != 0.0:
		ret["maxSteeringAngle"] = max_steering_angle
	if physics_material_index != -1:
		ret["physicsMaterial"] = physics_material_index
	if propulsion_force_change_per_second != -1.0:
		ret["propulsionForceChangeRate"] = propulsion_force_change_per_second
	if radius != 0.25:
		ret["radius"] = radius
	if steering_radians_per_second != 1.0:
		ret["steeringChangeRate"] = steering_radians_per_second
	if suspension_damping_compression != 500.0:
		ret["suspensionDampingCompression"] = suspension_damping_compression
	if suspension_damping_rebound != 500.0:
		ret["suspensionDampingRebound"] = suspension_damping_rebound
	if suspension_stiffness != 20000.0:
		ret["suspensionStiffness"] = suspension_stiffness
	if suspension_travel != 0.25:
		ret["suspensionTravel"] = suspension_travel
	if target_propulsion_force_ratio != 0.0:
		ret["targetPropulsionForceRatio"] = target_propulsion_force_ratio
	if target_steering_ratio != 0.0:
		ret["targetSteeringRatio"] = target_steering_ratio
	if width != 0.125:
		ret["width"] = width
	return ret
