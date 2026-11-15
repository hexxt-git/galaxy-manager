shader_type canvas_item;
render_mode unshaded;

// Night past the map's walkable edge: dithered bands that thicken with distance out to the clear colour.
uniform vec2 rect_pos;  // world px
uniform vec2 rect_size;  // world px
uniform vec2 inner_pos;  // walkable area, world px
uniform vec2 inner_size;
uniform float start = 0.0;  // darkness begins this far past the walkable edge
uniform float fade = 380.0;  // and is solid this much further out
uniform vec4 dark : source_color = vec4(0.07, 0.08, 0.11, 1.0);
uniform float pixel = 4.0;
uniform float levels = 4.0;
uniform float wander = 220.0;  // world px the dark edge wanders in and out, so it never runs straight
uniform float wander_scale = 520.0;  // world px per noise cell

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
	vec2 past = max(max(inner_pos - c, c - inner_pos - inner_size), 0.0);
	float n = vnoise(c / wander_scale) * 0.65 + vnoise(c / wander_scale * 2.3 + 7.1) * 0.35;
	float level = clamp((length(past) - start + (n - 0.5) * wander) / fade, 0.0, 1.0) * levels;
	float band = floor(level);
	COLOR = vec4(dark.rgb, band / levels);
}
