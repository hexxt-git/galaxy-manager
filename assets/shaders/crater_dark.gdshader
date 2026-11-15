shader_type canvas_item;
render_mode blend_mul, unshaded;

// Darkness over the crater, lit around the player, in hard bands with wobbly edges like the floor AO.
uniform vec2 rect_pos;  // world px
uniform vec2 rect_size;  // world px
uniform vec2 light_pos;  // world px
uniform float radius = 360.0;  // fully lit inside this
uniform float soft = 260.0;  // then fades to dark over this
uniform float fade = 160.0;  // darkness ramps in over this much from the top edge
uniform vec4 dark : source_color = vec4(0.3, 0.34, 0.48, 1.0);
uniform float pixel = 4.0;
uniform float levels = 3.0;
uniform float wobble = 70.0;  // world px the band edges wander
uniform float wobble_scale = 140.0;
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0)), u.x), u.y);
}



void fragment() {
	vec2 world = rect_pos + UV * rect_size;
	vec2 cell = floor(world / pixel);
	vec2 c = (cell + 0.5) * pixel;
	float depth = clamp((c.y - rect_pos.y) / fade, 0.0, 1.0);
	float w = (vnoise(c / wobble_scale) - 0.5) * wobble;
	depth = clamp((c.y - rect_pos.y + w) / fade, 0.0, 1.0);
	float lit = 1.0 - clamp((distance(c, light_pos) - radius + w) / soft, 0.0, 1.0);
	float level = depth * (1.0 - lit) * levels;
	float band = floor(level);
	COLOR = mix(vec4(1.0), dark, band / levels);
}
