@tool
class_name EditorSeat3DGizmoPlugin
extends EditorNode3DGizmoPlugin


const _HANDLE_FOOT: int = 0
const _HANDLE_KNEE: int = 1
const _HANDLE_BACK: int = 2
const _HANDLE_ANGLE: int = 3
const _SNAP_STEP = 0.01
const _SNAP_RADIANS = 0.0017453292519943295769 # 0.1 degrees

var _edited_point_start: Vector3
var _edited_right_start: Vector3


func _init():
	create_material("main", Color.CYAN)
	create_material("cosmetic", Color.YELLOW)
	create_handle_material("handles")


func _begin_handle_action(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool) -> void:
	var node: Seat3D = gizmo.get_node_3d()
	_edited_right_start = node.get_right()
	match handle_id:
		_HANDLE_FOOT:
			_edited_point_start = node.foot
		_HANDLE_KNEE:
			_edited_point_start = node.knee
		_:
			_edited_point_start = node.back


func _get_gizmo_name() -> String:
	return "Seat3DGizmoPlugin"


func _get_handle_name(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool) -> String:
	match handle_id:
		_HANDLE_FOOT:
			return "Foot Control Point"
		_HANDLE_KNEE:
			return "Knee Control Point"
		_HANDLE_BACK:
			return "Back Control Point"
		_HANDLE_ANGLE:
			return "Spine Angle"
	return "Error"


func _get_handle_value(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool) -> Variant:
	var node: Seat3D = gizmo.get_node_3d()
	match handle_id:
		_HANDLE_FOOT:
			return node.foot
		_HANDLE_KNEE:
			return node.knee
		_HANDLE_BACK:
			return node.back
		_HANDLE_ANGLE:
			return node.angle
	return null


func _has_gizmo(node: Node3D) -> bool:
	return node is Seat3D


func _set_handle(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool, camera: Camera3D, screen_pos: Vector2) -> void:
	var node: Seat3D = gizmo.get_node_3d()
	var inverse: Transform3D = node.global_transform.affine_inverse()
	var project_ray_normal: Vector3 = inverse.basis * camera.project_ray_normal(screen_pos)
	var project_ray_origin: Vector3 = inverse * camera.project_ray_origin(screen_pos)
	var plane := Plane(_edited_right_start, _edited_point_start)
	var intersection = plane.intersects_ray(project_ray_origin, project_ray_normal)
	if intersection == null:
		return
	if plane.has_point(intersection.snappedf(_SNAP_STEP)):
		intersection = intersection.snappedf(_SNAP_STEP)
	match handle_id:
		_HANDLE_FOOT:
			node.foot = intersection
			if node.get_right() == Vector3.ZERO:
				# Oops, that was invalid! Revert.
				node.foot = _edited_point_start
		_HANDLE_KNEE:
			node.knee = intersection
			if node.get_right() == Vector3.ZERO:
				node.knee = _edited_point_start
		_HANDLE_BACK:
			node.back = intersection
			if node.get_right() == Vector3.ZERO:
				node.back = _edited_point_start
		_HANDLE_ANGLE:
			var back_to_intersection: Vector3 = intersection - node.back
			if node.get_upper_leg_norm().dot(back_to_intersection) > 0:
				var angle: float = snappedf(node.get_upper_leg_dir().angle_to(back_to_intersection), _SNAP_RADIANS)
				node.angle = clampf(angle, deg_to_rad(10.0), deg_to_rad(180.0))
			else:
				node.angle = deg_to_rad(10.0) if node.get_upper_leg_dir().dot(back_to_intersection) > 0 else PI
	_redraw(gizmo)


func _redraw(gizmo: EditorNode3DGizmo):
	gizmo.clear()
	var node: Seat3D = gizmo.get_node_3d()
	var spine_gizmo_length: float = (node.back - node.knee).length()
	var angle_gizmo_point: Vector3 = node.back + node.get_spine_dir() * spine_gizmo_length
	var main_lines: PackedVector3Array = [
		node.foot, node.knee,
		node.back, node.knee,
		node.back, angle_gizmo_point,
	]
	# Draw cosmetic lines to visually show the seat having a square sitting place.
	var cosmetic_right: Vector3 = node.get_right() * (spine_gizmo_length * 0.5)
	var cosmetic_lines: PackedVector3Array = [
		node.back + cosmetic_right, node.back - cosmetic_right,
		node.knee + cosmetic_right, node.knee - cosmetic_right,
		node.foot + cosmetic_right, node.foot - cosmetic_right,
		node.back + cosmetic_right, node.knee + cosmetic_right,
		node.knee + cosmetic_right, node.foot + cosmetic_right,
		node.back - cosmetic_right, node.knee - cosmetic_right,
		node.knee - cosmetic_right, node.foot - cosmetic_right,
	]
	# Keep these indices consistent with the _HANDLE constants.
	var handles: PackedVector3Array = [node.foot, node.knee, node.back, angle_gizmo_point]
	gizmo.add_lines(main_lines, get_material("main", gizmo), false)
	gizmo.add_lines(cosmetic_lines, get_material("cosmetic", gizmo), false)
	gizmo.add_handles(handles, get_material("handles", gizmo), [])
