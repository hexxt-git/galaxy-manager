shader_type canvas_item;

// Draws a solid outline around the sprite's alpha silhouette, in texture pixels so it stays pixel-crisp.
// The texture needs at least `width` px of transparent padding or the outline gets clipped.
uniform bool enabled = false;
uniform vec4 outline_color : source_color = vec4(1.0, 0.86, 0.2, 1.0);
uniform int width : hint_range(1, 4) = 2;

#include "res://assets/shaders/room_light.gdshaderinc"

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	COLOR = vec4(room_light(c.rgb), c.a) * modulate;
	if (enabled && c.a < 0.5) {
		float r2 = float(width * width) + 0.5;
		for (int y = -width; y <= width; y++) {
			for (int x = -width; x <= width; x++) {
				if (float(x * x + y * y) > r2) {
					continue;
				}
				if (texture(TEXTURE, UV + vec2(float(x), float(y)) * TEXTURE_PIXEL_SIZE).a >= 0.5) {
					COLOR = outline_color;
				}
			}
		}
	}
}
