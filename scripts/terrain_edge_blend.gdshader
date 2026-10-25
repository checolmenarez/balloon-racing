shader_type canvas_item;
uniform vec4 source_rect;
uniform bool underside = false;
void fragment() {
	vec2 uv = (UV / TEXTURE_PIXEL_SIZE - source_rect.xy) / source_rect.zw;
	float sides = smoothstep(0.0, 0.12, min(uv.x, 1.0 - uv.x));
	float interior = smoothstep(0.0, 0.22, underside ? uv.y : (1.0 - uv.y));
	COLOR.a *= sides * interior;
}
