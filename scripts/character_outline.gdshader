shader_type canvas_item;
uniform bool local_outline = false;
uniform vec4 outline_color : source_color = vec4(0.14, 0.24, 0.32, 1.0);
// Updated by BalloonVisual, so animation respects pause and reduced motion.
uniform vec3 living_motion = vec3(0.0); // envelope breath, basket lag, pilot nod
uniform sampler2D current_pose : source_color, filter_linear, repeat_disable;
uniform sampler2D previous_pose : source_color, filter_linear, repeat_disable;
uniform float pose_blend = 1.0;
uniform vec2 previous_scale = vec2(1.0);
uniform vec2 previous_offset = vec2(0.0);
uniform vec4 left_eye = vec4(0.0);
uniform vec4 right_eye = vec4(0.0);
uniform vec4 left_arm = vec4(0.0);
uniform vec4 right_arm = vec4(0.0);
uniform vec2 arm_motion = vec2(0.0);
uniform float blink = 0.0;
uniform vec4 eyelid_color : source_color = vec4(1.0, 0.85, 0.65, 1.0);
varying vec4 vertex_tint;

void vertex() {
	vertex_tint = COLOR;
}

vec2 living_uv(vec2 uv) {
	float envelope = 1.0 - smoothstep(0.48, 0.68, uv.y);
	uv.x = 0.5 + (uv.x - 0.5) / (1.0 + living_motion.x * envelope);
	// Continuous warp keeps ropes attached; the lower section follows as one piece.
	uv.x -= living_motion.y * smoothstep(0.46, 0.87, uv.y);
	float pilot = smoothstep(0.62, 0.73, uv.y) * (1.0 - smoothstep(0.84, 0.94, uv.y));
	uv.y -= living_motion.z * pilot;
	if (left_arm.z > 0.0) {
		float left = 1.0 - smoothstep(0.15, 1.0, length((uv - left_arm.xy) / left_arm.zw));
		float right = 1.0 - smoothstep(0.15, 1.0, length((uv - right_arm.xy) / right_arm.zw));
		uv.y -= arm_motion.x * left + arm_motion.y * right;
	}
	return uv;
}


vec4 pose_pixel(vec2 uv) {
	vec2 animated_uv = living_uv(uv);
	vec4 pixel = texture(current_pose, animated_uv);
	if (pose_blend < 1.0) {
		vec2 old_uv = (uv - 0.5) * previous_scale + 0.5 + previous_offset;
		vec4 old = texture(previous_pose, living_uv(old_uv));
		// Premultiplied interpolation avoids dark fringes around transparent pixels.
		float alpha = mix(old.a, pixel.a, pose_blend);
		pixel = vec4(mix(old.rgb * old.a, pixel.rgb * pixel.a, pose_blend) / max(alpha, 0.0001), alpha);
	}
	return pixel;
}

void fragment() {
	vec4 tint = vertex_tint;
	vec4 pixel = pose_pixel(UV);
	vec2 animated_uv = living_uv(UV);
	if (blink > 0.001) {
		for (int i = 0; i < 2; i++) {
			vec4 region = i == 0 ? left_eye : right_eye;
			if (region.z > 0.0) {
				vec2 p = (animated_uv - region.xy) / region.zw;
				float mask = 1.0 - smoothstep(0.8, 1.0, length(p));
				if (mask > 0.0) {
					float opening = max(0.045, 1.0 - blink);
					vec2 eye_uv = vec2(animated_uv.x, region.y + clamp(p.y / opening, -1.0, 1.0) * region.w);
					vec4 eye = texture(TEXTURE, eye_uv);
					vec4 lid = vec4(eyelid_color.rgb, pixel.a);
					float cover = smoothstep(opening, opening + 0.15, abs(p.y));
					eye = mix(eye, lid, cover);
					float crease = (1.0 - smoothstep(0.06, 0.18, abs(p.y - 0.12 * p.x * p.x))) * smoothstep(0.8, 1.0, blink);
					eye.rgb = mix(eye.rgb, vec3(0.15, 0.10, 0.09), crease);
					pixel = mix(pixel, eye, mask);
				}
			}
		}
	}
	if (local_outline) {
		vec2 step_uv = TEXTURE_PIXEL_SIZE * 4.0;
		float edge = 0.0;
		for (int x = -1; x <= 1; x++) {
			for (int y = -1; y <= 1; y++) {
				edge = max(edge, pose_pixel(UV + vec2(float(x), float(y)) * step_uv).a);
			}
		}
		pixel.rgb = mix(outline_color.rgb, pixel.rgb, pixel.a);
		pixel.a = max(pixel.a, edge);
	}
	COLOR = pixel * tint;
}
