// Shared by sprites lit per room. Defines vertex(): fragment()'s COLOR already includes the texture,
// so the plain modulate is taken here and multiplied back in by the includer.
uniform float light = 1.0;

varying vec4 modulate;

void vertex() {
	modulate = COLOR;
}

vec3 room_light(vec3 c) {
	return c * light;
}
