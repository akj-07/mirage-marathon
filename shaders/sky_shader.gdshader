shader_type sky;

uniform vec3 new_color:source_color = vec3(0.2,0.5,0.9);

void sky() {
	// Called for every visible pixel in the sky background, as well as all pixels
	// in the radiance cubemap.
	COLOR = new_color;
}
