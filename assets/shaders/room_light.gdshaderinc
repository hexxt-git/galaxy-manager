uniform float light = 1.0;
uniform float contrast = 1.0;  // colour exponent: above 1 darkens and saturates, most in the midtones

vec3 room_light(vec3 c) {
	return pow(c, vec3(contrast)) * light;
}
