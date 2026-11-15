// Plain color sky shader for glTF plain skies.
// Godot's "Custom Color" background mode ignores the ambient light sky
// contribution, so plain skies use a sky shader instead. This makes the
// sky color contribute to ambient light and reflections like any other sky.
shader_type sky;

uniform vec3 sky_color : source_color = vec3(0.0);

void sky() {
	COLOR = sky_color;
}
