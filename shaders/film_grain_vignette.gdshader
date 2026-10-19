shader_type canvas_item;

// Film Grain and Vignette Shader for Gölge ve Yağmur Noir Aesthetic
// Bound strictly to palette 0b0f1a for deep noir shadows.

uniform bool enable_grain = true;
uniform bool enable_vignette = true;
uniform float grain_amount : hint_range(0.0, 0.2) = 0.045;
uniform float vignette_intensity : hint_range(0.0, 1.5) = 0.55;
uniform vec4 vignette_color : source_color = vec4(0.043, 0.059, 0.102, 1.0); // 0b0f1a

float pseudo_random(vec2 uv, float time) {
	return fract(sin(dot(uv + fract(time * 0.1), vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
	vec4 col = vec4(0.0);
	vec2 uv = UV;

	// Circular Noir Vignette
	if (enable_vignette) {
		vec2 d = uv - vec2(0.5);
		float dist = length(d);
		float vig = smoothstep(0.28, 0.75, dist) * vignette_intensity;
		col = vec4(vignette_color.rgb, vig);
	}

	// 1940s 35mm Film Grain
	if (enable_grain) {
		float n = (pseudo_random(uv, TIME) - 0.5) * grain_amount;
		if (col.a <= 0.001) {
			col = vec4(0.0, 0.0, 0.0, abs(n) * 1.5);
		} else {
			col.rgb += vec3(n);
		}
	}

	COLOR = col;
}
