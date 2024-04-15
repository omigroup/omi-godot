@tool
extends EditorPlugin


func _enter_tree() -> void:
	# NOTE: Be sure to also instance and register these at runtime if you want
	# the extensions at runtime. This editor plugin script won't run in games.
	var ext = GLTFDocumentExtensionKHR_XMP.new()
	GLTFDocument.register_gltf_document_extension(ext)
