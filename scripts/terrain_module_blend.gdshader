shader_type canvas_item;
// Feather only the borders of overlapping, unstretched kit rock sections.
void fragment() {
	vec2 local_uv = (UV / TEXTURE_PIXEL_SIZE - vec2(5.0, 24.0)) / vec2(106.0, 36.0);
	vec2 edge = min(local_uv, vec2(1.0) - local_uv);
	COLOR.a *= smoothstep(0.0, 0.10, edge.x) * smoothstep(0.0, 0.12, edge.y);
}
