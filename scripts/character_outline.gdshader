shader_type canvas_item;
uniform bool local_outline = false;
uniform vec4 outline_color : source_color = vec4(0.14, 0.24, 0.32, 1.0);
varying vec4 vertex_tint;

void vertex() {
	vertex_tint = COLOR;
}

void fragment() {
	vec4 tint = vertex_tint;
	vec4 pixel = texture(TEXTURE, UV);
	if (local_outline) {
		vec2 step_uv = TEXTURE_PIXEL_SIZE * 4.0;
		float edge = 0.0;
		for (int x = -1; x <= 1; x++) {
			for (int y = -1; y <= 1; y++) {
				edge = max(edge, texture(TEXTURE, UV + vec2(float(x), float(y)) * step_uv).a);
			}
		}
		pixel.rgb = mix(outline_color.rgb, pixel.rgb, pixel.a);
		pixel.a = max(pixel.a, edge);
	}
	COLOR = pixel * tint;
}
