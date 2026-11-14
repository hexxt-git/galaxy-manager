shader_type canvas_item;
render_mode blend_mul, unshaded;

// Masks are red = 1 where shadowed. The old mask dithers out over t 0..0.5, the new one dithers in over 0.5..1.
uniform sampler2D mask_old : filter_nearest;
uniform sampler2D mask_new : filter_nearest;
uniform float t = 1.0;
uniform vec4 dim : source_color = vec4(0.7, 0.7, 0.74, 1.0);
// mask pixel position of the texture's top-left in world mask pixels, so the dither pattern stays put in the world
uniform vec2 grid_origin = vec2(0.0);

// 8x8 ordered-dither rank: bit-reversed interleave of (x ^ y) and x
float bayer8(ivec2 p) {
	int x = p.x & 7;
	int xy = x ^ (p.y & 7);
	int v = ((xy & 1) << 5) | ((x & 1) << 4) | ((xy & 2) << 2) | ((x & 2) << 1) | ((xy & 4) >> 1) | ((x & 4) >> 2);
	return (float(v) + 0.5) / 64.0;
}

void fragment() {
	ivec2 p = ivec2(floor(UV * vec2(textureSize(mask_new, 0)) + grid_origin));
	float th = bayer8(p);
	float old_s = texture(mask_old, UV).r * step(2.0 * t, th);
	float new_s = texture(mask_new, UV).r * step(th, 2.0 * t - 1.0);
	COLOR = mix(vec4(1.0), dim, max(old_s, new_s));
}
