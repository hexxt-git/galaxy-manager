// Shared by sprites lit per room. Defines vertex(): fragment()'s COLOR already includes the texture,
// so the plain modulate is taken here and multiplied back in by the includer.
uniform float light = 1.0;
uniform float contrast = 1.0;  // colour exponent: above 1 darkens and saturates, most in the midtones

varying vec4 modulate;

void vertex() {
	modulate = COLOR;
}

vec3 room_light(vec3 c) {
	return pow(c, vec3(contrast)) * light;
}
