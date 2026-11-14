shader_type canvas_item;
render_mode blend_mul, unshaded;

// Corner darkening over a room's visible floor, in two hard bands.
// sqrt(dx * dy) gives hyperbolic contours that hug both walls and run off along them; the (dx + dy) term ends those tails.
uniform vec2 rect_pos;     // world px
uniform vec2 rect_size;    // world px
uniform float radius = 100.0;  // world px, how far the bands reach out of the corner
uniform float reach = 380.0;   // world px, how far they run along the walls
uniform float strength = 0.3;  // inner band; the outer one gets half
uniform float outer = 0.1;
uniform float inner = 0.35;
uniform float pixel = 4.0;     // world px, matches the sight shadow grid
uniform float wobble = 0.18;   // band edge wander, as a fraction of radius
uniform float wobble_scale = 90.0;  // world px per noise cell

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
	vec2 cell = (floor(world / pixel) + 0.5) * pixel;
	vec2 d = min(cell - rect_pos, rect_pos + rect_size - cell);
	vec2 n = cell / wobble_scale;
	d = max(d + (vec2(vnoise(n), vnoise(n + vec2(17.3, 5.1))) - 0.5) * 2.0 * wobble * radius, 0.0);
	float ao = max(0.0, 1.0 - sqrt(d.x * d.y) / radius) * max(0.0, 1.0 - (d.x + d.y) / reach);
	float band = 0.5 * step(outer, ao) + 0.5 * step(inner, ao);
	COLOR = vec4(vec3(1.0 - strength * band), 1.0);
}
