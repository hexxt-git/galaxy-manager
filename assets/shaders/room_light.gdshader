shader_type canvas_item;

#include "res://assets/shaders/room_light.gdshaderinc"

// Prop ground shadows are exported at exactly alpha 56/255 (GROUND_RGBA in art-src/props/prop.js); nothing else is.
const float SHADOW_KEY = 56.0 / 255.0;
uniform float shadow = 0.2196;  // SHADOW_KEY
const vec3 SHADOW_RGB = vec3(0.09);  // neutral; the exported key colour is bluish

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (abs(c.a - SHADOW_KEY) < 2.0 / 255.0) {
		COLOR = vec4(SHADOW_RGB * light, shadow) * modulate;
	} else {
		COLOR = vec4(room_light(c.rgb), c.a) * modulate;
	}
}
