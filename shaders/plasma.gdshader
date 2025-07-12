shader_type canvas_item;

#define C(x) sin(x) * 0.8 + 0.5

uniform vec2 resolution = vec2(1152.0, 648.0);
uniform float speed: hint_range(0.1, 4.0, 0.1) = 1.0;

void fragment() {
	float time = TIME * speed;
	vec2 uv = UV - 0.5;
	uv.x *= resolution.x / resolution.y;
	float r = C(uv.x + time);
	float g = C(uv.y - time);
	float b = C((uv.x * uv.y) + C(time * 0.5));
	vec3 color = vec3(r, g, b);
	COLOR = vec4(color, 0.2);
}
