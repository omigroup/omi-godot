// Cubemap sky shader for glTF panorama skies with cubemap textures.
// Each face is a separate 2D texture, so the material can directly reference
// the glTF's textures instead of needing a generated Cubemap resource.
//
// glTF cubemap faces follow KTX 2.0: the order is +X, -X, +Y, -Y, +Z, -Z in
// KTX's left-handed cubemap space, which maps to glTF/Godot by negating X.
// So the "+X" face is seen when looking toward -X, and vice versa. Face images
// are not mirrored when viewed from inside the sky, so text is readable.
shader_type sky;

uniform sampler2D face_pos_x : source_color, filter_linear, repeat_disable, hint_default_black;
uniform sampler2D face_neg_x : source_color, filter_linear, repeat_disable, hint_default_black;
uniform sampler2D face_pos_y : source_color, filter_linear, repeat_disable, hint_default_black;
uniform sampler2D face_neg_y : source_color, filter_linear, repeat_disable, hint_default_black;
uniform sampler2D face_pos_z : source_color, filter_linear, repeat_disable, hint_default_black;
uniform sampler2D face_neg_z : source_color, filter_linear, repeat_disable, hint_default_black;

void sky() {
	vec3 dir = EYEDIR;
	vec3 abs_dir = abs(dir);
	vec3 color;
	// Use textureLod since UV derivatives are discontinuous at face edges.
	if (abs_dir.x >= abs_dir.y && abs_dir.x >= abs_dir.z) {
		// The KTX X axis points toward -X, so the X faces are swapped.
		if (dir.x > 0.0) {
			color = textureLod(face_neg_x, vec2(dir.z, -dir.y) / abs_dir.x * 0.5 + 0.5, 0.0).rgb;
		} else {
			color = textureLod(face_pos_x, vec2(-dir.z, -dir.y) / abs_dir.x * 0.5 + 0.5, 0.0).rgb;
		}
	} else if (abs_dir.y >= abs_dir.z) {
		if (dir.y > 0.0) {
			color = textureLod(face_pos_y, vec2(-dir.x, dir.z) / abs_dir.y * 0.5 + 0.5, 0.0).rgb;
		} else {
			color = textureLod(face_neg_y, vec2(-dir.x, -dir.z) / abs_dir.y * 0.5 + 0.5, 0.0).rgb;
		}
	} else {
		if (dir.z > 0.0) {
			color = textureLod(face_pos_z, vec2(-dir.x, -dir.y) / abs_dir.z * 0.5 + 0.5, 0.0).rgb;
		} else {
			color = textureLod(face_neg_z, vec2(dir.x, -dir.y) / abs_dir.z * 0.5 + 0.5, 0.0).rgb;
		}
	}
	COLOR = color;
}
