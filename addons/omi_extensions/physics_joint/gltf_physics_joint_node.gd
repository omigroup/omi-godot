@tool
class_name GLTFPhysicsJointNode
extends Resource


## The index of the node to which this is connected.
@export var connected_node_index: int = -1
## The index of the joint settings in the top level physicsJoints array.
@export var joint_settings_index: int = -1
## The joint settings data, loaded from the top level physicsJoints array on import, and saved there on export.
@export var joint_settings_data: GLTFPhysicsJointSettings = null
## If true, allow the connected objects to collide. Connected objects do not collide by default.
@export var enable_collision: bool = false


func to_dictionary() -> Dictionary:
	var ret: Dictionary = {}
	if connected_node_index != -1:
		ret["connectedNode"] = connected_node_index
	if joint_settings_index != -1:
		ret["joint"] = joint_settings_index
	if enable_collision:
		ret["enableCollision"] = enable_collision
	return ret


func to_node() -> Joint3D:
	var godot_joint_node: Joint3D = joint_settings_data.to_node()
	godot_joint_node.exclude_nodes_from_collision = not enable_collision
	godot_joint_node.node_a = ^".."
	return godot_joint_node


static func from_dictionary(node_dict: Dictionary) -> GLTFPhysicsJointNode:
	var ret = GLTFPhysicsJointNode.new()
	if node_dict.has("connectedNode"):
		ret.connected_node_index = node_dict["connectedNode"]
	if node_dict.has("joint"):
		ret.joint_settings_index = node_dict["joint"]
	if node_dict.has("enableCollision"):
		ret.enable_collision = node_dict["enableCollision"]
	return ret


static func from_node(godot_joint_node: Joint3D) -> GLTFPhysicsJointNode:
	var ret = GLTFPhysicsJointNode.new()
	ret.joint_settings_data = GLTFPhysicsJointSettings.from_node(godot_joint_node)
	ret.enable_collision = not godot_joint_node.exclude_nodes_from_collision
	return ret
