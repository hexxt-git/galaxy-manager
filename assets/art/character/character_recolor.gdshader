shader_type canvas_item;

// character.png keys the body as pure red (lit) and pure blue (shadow); everything else passes through.
uniform vec4 body_color : source_color = vec4(0.773, 0.067, 0.067, 1.0);
uniform vec4 shadow_color : source_color = vec4(0.478, 0.031, 0.220, 1.0);

#include "res://assets/shaders/room_light.gdshaderinc"

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (c.g < 0.1) {
		if (c.r > 0.9 && c.b < 0.1) {
			c.rgb = body_color.rgb;
		} else if (c.b > 0.9 && c.r < 0.1) {
			c.rgb = shadow_color.rgb;
		}
	}
	COLOR = vec4(room_light(c.rgb), c.a) * modulate;
}
