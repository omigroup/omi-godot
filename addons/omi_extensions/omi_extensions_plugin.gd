@tool
extends EditorPlugin


var seat_gizmo_plugin = EditorSeat3DGizmoPlugin.new()


func _enter_tree() -> void:
	# NOTE: Be sure to also instance and register these at runtime if you want
	# the extensions at runtime. This editor plugin script won't run in games.
	var ext: GLTFDocumentExtension
	ext = GLTFDocumentExtensionOMISeat.new()
	GLTFDocument.register_gltf_document_extension(ext, true)
	ext = GLTFDocumentExtensionOMISpawnPoint.new()
	GLTFDocument.register_gltf_document_extension(ext)
	ext = GLTFDocumentExtensionOMIPhysicsJoint.new()
	GLTFDocument.register_gltf_document_extension(ext)
	add_node_3d_gizmo_plugin(seat_gizmo_plugin)


func _exit_tree():
	remove_node_3d_gizmo_plugin(seat_gizmo_plugin)
