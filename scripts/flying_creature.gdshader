shader_type canvas_item;

uniform float wing = 0.0;
uniform float blink = 0.0;
uniform vec4 left_eye = vec4(0.369, 0.342, 0.075, 0.09);
uniform vec4 right_eye = vec4(0.636, 0.342, 0.075, 0.09);
uniform vec4 eyelid_color : source_color = vec4(0.95, 0.67, 0.32, 1.0);
varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec2 uv = UV;
	// Only the outer wing tips flex; the solid body and wing roots stay attached.
	float tips = smoothstep(0.24, 0.43, abs(uv.x - 0.5));
	uv.y -= wing * tips * (1.0 - smoothstep(0.58, 0.72, uv.y));
	vec4 pixel = texture(TEXTURE, uv);
	if (blink > 0.001) {
		for (int i = 0; i < 2; i++) {
			vec4 eye = i == 0 ? left_eye : right_eye;
			vec2 p = (uv - eye.xy) / eye.zw;
			float mask = 1.0 - smoothstep(0.8, 1.0, length(p));
			float cover = smoothstep(1.0 - blink, 1.15 - blink, abs(p.y));
			pixel.rgb = mix(pixel.rgb, eyelid_color.rgb, mask * cover);
			float crease = (1.0 - smoothstep(0.04, 0.13, abs(p.y))) * smoothstep(0.8, 1.0, blink);
			pixel.rgb = mix(pixel.rgb, vec3(0.18, 0.08, 0.025), crease * mask);
		}
	}
	COLOR = tint * pixel;
}
