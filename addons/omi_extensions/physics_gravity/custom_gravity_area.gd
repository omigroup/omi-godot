@tool
class_name CustomGravityArea3D
extends Area3D


enum CustomGravityType {
	DIRECTIONAL, ## Gravity in a direction in local space.
	POINT, ## Gravity towards the local origin point.
	DISC, ## Gravity towards a filled circle on the local XZ plane.
	TORUS, ## Gravity towards a hollow circle on the local XZ plane.
	LINE, ## Gravity towards a line defined by points in local space.
	SHAPED, ## Gravity towards a shape in local space.
}

@export var custom_gravity_type: CustomGravityType:
	set(value):
		custom_gravity_type = value
		notify_property_list_changed()

var direction := Vector3.DOWN
var radius: float = 1.0
var line_points: PackedVector3Array
var shape: Shape3D


func _ready() -> void:
	if gravity_space_override == SPACE_OVERRIDE_DISABLED:
		push_warning("CustomGravityArea3D has its Area3D gravity override disabled, this node will not have gravity.")
	if gravity_type != GRAVITY_TYPE_TARGET:
		push_warning("CustomGravityArea3D has its Area3D gravity type not set to target. The CustomGravityArea3D gravity logic will not be used.")


func _calculate_gravity_target(local_position: Vector3) -> Vector3:
	match custom_gravity_type:
		CustomGravityType.DIRECTIONAL:
			return local_position + direction
		CustomGravityType.POINT:
			return Vector3.ZERO
		CustomGravityType.DISC:
			var flat_position = Vector3(local_position.x, 0.0, local_position.z)
			return flat_position.limit_length(radius)
		CustomGravityType.TORUS:
			var flat_position = Vector3(local_position.x, 0.0, local_position.z)
			return flat_position.normalized() * radius
		CustomGravityType.LINE:
			var closest_point := Vector3.ZERO
			var closest_distance_sq: float = INF
			for i in range(line_points.size() - 1):
				var a: Vector3 = line_points[i]
				var b: Vector3 = line_points[i + 1]
				var closest: Vector3 = Geometry3D.get_closest_point_to_segment(local_position, a, b)
				var distance_sq: float = local_position.distance_squared_to(closest)
				if distance_sq < closest_distance_sq:
					closest_point = closest
					closest_distance_sq = distance_sq
			return closest_point
		CustomGravityType.SHAPED:
			return _get_closest_point_on_shape(shape, local_position)
	return Vector3()


static func _project_point_onto_triangle(point: Vector3, a: Vector3, b: Vector3, c: Vector3) -> Vector3:
	var plane: Plane = Plane(a, b, c)
	var projected: Vector3 = plane.project(point)
	var bary: Vector3 = Geometry3D.get_triangle_barycentric_coords(projected, a, b, c)
	if 0.0 < bary.x and bary.x < 1.0 and 0.0 < bary.y and bary.y < 1.0 and 0.0 < bary.z and bary.z < 1.0:
		return projected # If all barycentric coordinates are between 0 and 1, this is on the triangle.
	# Else, find which two barycentric coordinates are the greatest, and project onto that line segment.
	if bary.x < bary.y and bary.x < bary.z:
		return Geometry3D.get_closest_point_to_segment(projected, b, c)
	if bary.y < bary.x and bary.y < bary.z:
		return Geometry3D.get_closest_point_to_segment(projected, a, c)
	return Geometry3D.get_closest_point_to_segment(projected, a, b)


static func _get_closest_point_on_shape(shape: Shape3D, point: Vector3) -> Vector3:
	if shape is BoxShape3D:
		var extents = shape.size * 0.5
		return point.clamp(-extents, extents)
	if shape is SphereShape3D:
		return point.limit_length(shape.radius)
	if shape is CapsuleShape3D:
		var mid_extent: float = (shape.height - shape.radius * 2.0) * 0.5
		var projected: Vector3 = Geometry3D.get_closest_point_to_segment(point, Vector3(0.0, -mid_extent, 0.0), Vector3(0.0, mid_extent, 0.0))
		var difference: Vector3 = (point - projected).limit_length(shape.radius)
		return projected + difference
	if shape is CylinderShape3D:
		var extent: float = shape.height * 0.5
		var projected: Vector3 = Geometry3D.get_closest_point_to_segment(point, Vector3(0.0, -extent, 0.0), Vector3(0.0, extent, 0.0))
		var flat_location = Vector3(point.x, 0.0, point.z)
		return projected + flat_location.limit_length(shape.radius)
	if shape is ConcavePolygonShape3D:
		var closest_point := Vector3.ZERO
		var closest_distance_sq: float = INF
		var faces: PackedVector3Array = shape.get_faces()
		for i in range(0, faces.size(), 3):
			var on_triangle: Vector3 = _project_point_onto_triangle(point, faces[i], faces[i + 1], faces[i + 2])
			var distance_sq: float = point.distance_squared_to(on_triangle)
			if distance_sq < closest_distance_sq:
				closest_point = on_triangle
				closest_distance_sq = distance_sq
		return closest_point
	printerr("Unsupported shape: ", shape)
	return point


func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []
	match custom_gravity_type:
		CustomGravityType.DIRECTIONAL:
			properties.append({
				"name": "direction",
				"type": TYPE_VECTOR3,
				"usage": PROPERTY_USAGE_DEFAULT,
			})
		CustomGravityType.DISC, CustomGravityType.TORUS:
			properties.append({
				"name": "radius",
				"type": TYPE_FLOAT,
				"usage": PROPERTY_USAGE_DEFAULT,
			})
		CustomGravityType.LINE:
			properties.append({
				"name": "line_points",
				"type": TYPE_PACKED_VECTOR3_ARRAY,
				"usage": PROPERTY_USAGE_DEFAULT,
			})
		CustomGravityType.SHAPED:
			properties.append({
				"name": "shape",
				"type": TYPE_OBJECT,
				"usage": PROPERTY_USAGE_DEFAULT,
				"hint": PROPERTY_HINT_RESOURCE_TYPE,
				"hint_string": "Shape3D"
			})
	return properties


# Everything below this point is for GLTF serialization.
func _get_or_create_state_shapes_in_state(gltf_state: GLTFState) -> Array:
	var state_extensions: Dictionary = gltf_state.json.get_or_add("extensions", {})
	if not state_extensions.has("OMI_physics_shape"):
		state_extensions["OMI_physics_shape"] = {}
		gltf_state.add_used_extension("OMI_physics_shape", false)
	var omi_physics_shape_ext: Dictionary = state_extensions["OMI_physics_shape"]
	var state_shapes: Array = omi_physics_shape_ext.get_or_add("shapes", [])
	return state_shapes


func to_dictionary(gltf_state: GLTFState) -> Dictionary:
	var ret: Dictionary = area_gravity_to_dictionary(self)
	if gravity_type != Area3D.GravityType.GRAVITY_TYPE_TARGET:
		return ret
	var type_string: String = _gravity_type_enum_to_string(custom_gravity_type)
	ret["type"] = type_string
	var sub_dict: Dictionary = {}
	if custom_gravity_type == CustomGravityType.DIRECTIONAL:
		if not direction.is_equal_approx(Vector3.DOWN):
			sub_dict = { "direction": [direction.x, direction.y, direction.z] }
	else:
		if gravity_point_unit_distance != 0.0:
			sub_dict = { "unitDistance": gravity_point_unit_distance }
		match custom_gravity_type:
			CustomGravityType.DISC, CustomGravityType.TORUS:
				if radius != 1.0:
					sub_dict["radius"] = radius
			CustomGravityType.LINE:
				var point_numbers: Array = []
				for line_point in line_points:
					point_numbers.append(line_point.x)
					point_numbers.append(line_point.y)
					point_numbers.append(line_point.z)
				sub_dict["points"] = point_numbers
			CustomGravityType.SHAPED:
				var state_shapes: Array = _get_or_create_state_shapes_in_state(gltf_state)
				var gltf_shape := GLTFPhysicsShape.from_resource(shape)
				sub_dict["shape"] = state_shapes.size()
				state_shapes.append(gltf_shape.to_dictionary())
	if not sub_dict.is_empty():
		ret[type_string] = sub_dict
	return ret


## Functionality common to all Godot Area3D nodes including non-CustomGravityArea3D nodes.
static func area_gravity_to_dictionary(area: Area3D) -> Dictionary:
	var ret: Dictionary = {}
	var space_override: Area3D.SpaceOverride = area.gravity_space_override
	if space_override == Area3D.SpaceOverride.SPACE_OVERRIDE_DISABLED:
		return ret
	ret["gravity"] = area.gravity
	if area.priority != 0:
		ret["priority"] = area.priority
	if space_override == Area3D.SpaceOverride.SPACE_OVERRIDE_REPLACE:
		ret["replace"] = true
		ret["stop"] = true
	elif space_override == Area3D.SpaceOverride.SPACE_OVERRIDE_COMBINE_REPLACE:
		ret["stop"] = true
	elif space_override == Area3D.SpaceOverride.SPACE_OVERRIDE_REPLACE_COMBINE:
		ret["replace"] = true
	if area.gravity_type == Area3D.GravityType.GRAVITY_TYPE_DIRECTIONAL:
		var dir: Vector3 = area.gravity_direction * area.global_basis.orthonormalized()
		if not dir.is_equal_approx(Vector3.DOWN):
			ret["directional"] = { "direction": [dir.x, dir.y, dir.z] }
		ret["type"] = "directional"
	elif area.gravity_type == Area3D.GravityType.GRAVITY_TYPE_POINT:
		var unit_dist: float = area.gravity_point_unit_distance
		if unit_dist != 0.0:
			ret["point"] = { "unitDistance": unit_dist }
		ret["type"] = "point"
	return ret


static func from_dictionary(dict: Dictionary, gltf_state: GLTFState) -> CustomGravityArea3D:
	if "type" not in dict:
		printerr('GLTF gravity import: Missing required field "type", expected "directional", "point", "disc", "torus", "line", or "shaped".')
		return null
	if "gravity" not in dict:
		printerr('GLTF gravity import: Missing required field "gravity", expected a number in meters per second squared.')
		return null
	var type_string = dict.get("type")
	if type_string not in ["directional", "point", "disc", "torus", "line", "shaped"]:
		printerr("GLTF gravity import: Invalid gravity type, found: ", dict.get("type"), ' but expected "directional", "point", "disc", "torus", "line", or "shaped".')
		return null
	var gravity_amount = dict.get("gravity")
	if not gravity_amount is float: # All JSON numbers are floats.
		printerr("GLTF gravity import: Invalid gravity, found: ", dict.get("gravity"), ' but expected a number.')
		return null
	var ret: CustomGravityArea3D = CustomGravityArea3D.new()
	ret.gravity_type = Area3D.GRAVITY_TYPE_TARGET
	ret.custom_gravity_type = _gravity_type_string_to_enum(type_string)
	ret.gravity = gravity_amount
	var priority = dict.get("priority")
	if priority is float: # All JSON numbers are floats.
		ret.priority = priority
	var replace: bool = dict.get("replace", false)
	var stop: bool = dict.get("stop", false)
	if replace and stop:
		ret.gravity_space_override = Area3D.SpaceOverride.SPACE_OVERRIDE_REPLACE
	elif stop:
		ret.gravity_space_override = Area3D.SpaceOverride.SPACE_OVERRIDE_COMBINE_REPLACE
	elif replace:
		ret.gravity_space_override = Area3D.SpaceOverride.SPACE_OVERRIDE_REPLACE_COMBINE
	else:
		ret.gravity_space_override = Area3D.SpaceOverride.SPACE_OVERRIDE_COMBINE
	var sub_dict = dict.get(type_string)
	if not sub_dict is Dictionary:
		return ret
	var direction = sub_dict.get("direction")
	if direction is Array:
		ret.direction = Vector3(direction[0], direction[1], direction[2])
	var unit_distance = sub_dict.get("unitDistance")
	if unit_distance is float:
		ret.gravity_point_unit_distance = unit_distance
	var radius = sub_dict.get("radius")
	if radius is float:
		ret.radius = radius
	var points = sub_dict.get("points")
	if points is Array:
		var packed_points := PackedVector3Array()
		for i in range(0, points.size(), 3):
			packed_points.append(Vector3(points[i], points[i + 1], points[i + 2]))
		ret.line_points = packed_points
	var shape = sub_dict.get("shape")
	if shape is float: # Integer but all JSON numbers are floats.
		var shape_index: int = shape
		if shape_index < 0:
			printerr("GLTF gravity import: Invalid shape index, found: ", shape, " but expected a non-negative integer.")
			return ret
		var state_shapes: Array = gltf_state.get_additional_data(&"GLTFPhysicsShapes")
		if shape_index >= state_shapes.size():
			printerr("GLTF gravity import: Shape index ", shape_index, " is out of bounds (size=", state_shapes.size(), ").")
			return ret
		var gltf_shape: GLTFPhysicsShape = state_shapes[shape_index]
		ret.shape = gltf_shape.to_resource(true)
	return ret


static func _gravity_type_enum_to_string(type: CustomGravityType) -> String:
	# The type value may be set to `"directional"`, `"point"`, `"disc"`, `"torus"`, `"line"`, or `"shaped"`.
	match type:
		CustomGravityType.DIRECTIONAL:
			return "directional"
		CustomGravityType.POINT:
			return "point"
		CustomGravityType.DISC:
			return "disc"
		CustomGravityType.TORUS:
			return "torus"
		CustomGravityType.LINE:
			return "line"
		CustomGravityType.SHAPED:
			return "shaped"
	assert(false, "GLTF gravity export: Invalid gravity type.")
	return ""


static func _gravity_type_string_to_enum(type: String) -> CustomGravityType:
	match type:
		"directional":
			return CustomGravityType.DIRECTIONAL
		"point":
			return CustomGravityType.POINT
		"disc":
			return CustomGravityType.DISC
		"torus":
			return CustomGravityType.TORUS
		"line":
			return CustomGravityType.LINE
		"shaped":
			return CustomGravityType.SHAPED
	printerr("GLTF gravity import: Unknown gravity type: ", type)
	return CustomGravityType.DIRECTIONAL
