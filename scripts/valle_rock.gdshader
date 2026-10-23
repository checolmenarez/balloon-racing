shader_type canvas_item;
render_mode unshaded;

// Sample the supplied illustrated cliff, mirrored to avoid hard tile seams.
uniform vec4 region = vec4(0.0);
uniform vec2 tile_size = vec2(280.0, 360.0);
varying vec2 local_position;
varying vec4 tint;
void vertex() {
	local_position = VERTEX;
	tint = COLOR;
}
void fragment() {
	vec2 rock_position = vec2(local_position.x + local_position.y * 0.28, local_position.y);
	vec2 tile = abs(fract(rock_position / tile_size) * 2.0 - 1.0);
	vec3 rock = texture(TEXTURE, region.xy + tile * region.zw).rgb;
	COLOR = vec4(rock * tint.rgb, tint.a);
}
