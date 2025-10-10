shader_type spatial;

// from https://www.youtube.com/watch?v=KKR1UhOboUE&t=47s
uniform sampler2D noise_texture;
uniform sampler2D color;
uniform float smoothness: hint_range(0.0, 1.0, 0.05) = 0.05;
uniform float displacement_strength: hint_range(0.0, 0.01, 0.0001) = 0.01;
uniform float fresnel_power: hint_range(0.0, 5.0, 0.1) = 1.0;

varying vec3 world_position;

void vertex()
{
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float height = texture(noise_texture, VERTEX.xz * smoothness + vec2(TIME * 0.1)).r;
	VERTEX += NORMAL * height * displacement_strength;
}

float fresnel(vec3 normal, mat4 camera_matrix, float power)
{
	vec3 view_direction_world = (camera_matrix * vec4(0.0, 0.0, 1.0, 0.0)).xyz;
	vec3 normal_world = (camera_matrix * vec4(normal, 0.0)).xyz;

	float fresnel = dot(view_direction_world, normal_world);
	fresnel = pow(1.0 - abs(fresnel), power);
	return fresnel;
}

void fragment()
{
	float fresnel = fresnel(NORMAL, INV_VIEW_MATRIX, fresnel_power);

	ALBEDO = texture(color, world_position.xz + vec2(TIME * 0.5)).rgb;
	ROUGHNESS = 0.0f;
	METALLIC = 0.0f;
	ALPHA = fresnel;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
