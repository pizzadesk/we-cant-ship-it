shader_type canvas_item;

uniform float opacity = 0.06;
uniform float speed = 1.5;
uniform float density = 380.0;

void fragment() {
	float line = step(0.55, fract((UV.y + TIME * speed) * density));
	float noise = fract(sin(dot(UV + vec2(TIME * 0.1), vec2(12.9898, 78.233))) * 43758.5453);
	float n = (noise - 0.5) * 0.06;
	COLOR = vec4(vec3(0.03 + n), line * opacity);
}
