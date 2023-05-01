shader_type spatial;

void vertex() {
	UV += TIME * 0.01;
}

void fragment() {
	ALBEDO = vec3(abs(cos(TIME * 2.0)));
}
