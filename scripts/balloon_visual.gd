class_name BalloonVisual
extends CanvasGroup

@export var local_outline_enabled: bool = true
var local_outline_visible: bool = false
var victory: bool = false
var current_state: String = "idle"
var displayed_pose: String = "idle"
var _pose_key: String = ""
@export_range(0.0, 8.0, 0.5) var shake_pixels: float = 4.0
@export_range(0.1, 0.5, 0.05) var shake_duration: float = 0.28
@export_range(0.0, 5.0, 0.25) var tilt_degrees: float = 2.0
@export_range(0.0, 2.0, 0.1) var sway_degrees: float = 0.7
@export_range(0.0, 1.0, 0.05) var effects_intensity: float = 1.0
@export_range(0.0, 0.15, 0.01) var impact_squash: float = 0.09
var speed_glow: float = 0.0
var _time: float = 0.0
var _phase: float = 0.0
var _base_scale: Vector2
var _burning: bool = false
var _boosting: bool = false
var _wind: bool = false
var _anticipation: float = 0.0
var _turbo_pulse: float = 0.0
var _turbo_age: float = 0.0
var _turbo_color: float = 0.0
var _trail_points := PackedVector2Array()
var _trail_colors := PackedColorArray()
@export_range(0.03, 0.12, 0.01) var turbo_anticipation_seconds: float = 0.06
var _wind_pulse: float = 0.0
var _impact_point := Vector2(35, -20)
var _shake_left: float = 0.0
var _impact_count: int = 0
var _entry_offset: float = 0.0
var _entry_tween: Tween
@export_range(0.0, 0.25, 0.01) var pose_transition_seconds: float = 0.07
@export_range(0.0, 0.03, 0.001) var breathing_amount: float = 0.014
@export_range(0.0, 0.04, 0.001) var basket_follow_amount: float = 0.02
@export_range(0.0, 0.01, 0.001) var pilot_nod_amount: float = 0.004
var _pose_blend: float = 1.0
var _previous_pose_texture: Texture2D
var _basket_follow: float = 0.0
var _angular_velocity: float = 0.0
var _living_motion := Vector3.ZERO
var _burner_glow: float = 0.0
@export_range(1.0, 7.0, 0.25) var blink_interval: float = 1.75
@export_range(0.1, 0.3, 0.01) var blink_duration: float = 0.18
@export_range(0.0, 0.012, 0.001) var arm_motion_amount: float = 0.008
var _blink: float = 0.0
var _arms := Vector2.ZERO
@export_range(2.0, 6.0, 0.25) var arm_gesture_interval: float = 2.75


func present(duration: float) -> void:
	if _entry_tween != null:
		_entry_tween.kill()
	if GameFeel.reduced_motion:
		_entry_offset = 0.0
		return
	_entry_offset = -65.0
	_entry_tween = create_tween()
	_entry_tween.tween_property(self, "_entry_offset", 0.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	var balloon := get_parent() as Balloon
	_time += delta
	var intensity: float = effects_intensity * (0.2 if GameFeel.reduced_motion else 1.0)
	var burning: bool = balloon.racing and balloon.burner_active
	var boosting: bool = balloon.racing and balloon.items.boost_left > 0.0
	var wind: bool = balloon.racing and balloon.items.wind_multiplier() > 1.0
	if burning != _burning:
		_anticipation = 1.0 if burning else -0.5
	if boosting and not _boosting:
		_turbo_age = 0.0
	if boosting:
		var previous_age: float = _turbo_age
		_turbo_age += delta
		if previous_age < turbo_anticipation_seconds and _turbo_age >= turbo_anticipation_seconds:
			_turbo_pulse = 1.0
	_turbo_color = lerpf(_turbo_color, 1.0 if boosting else 0.0, 1.0 - exp(-delta * 5.0))
	if wind != _wind:
		_wind_pulse = 1.0
	_burning = burning
	_burner_glow = lerpf(_burner_glow, 1.0 if burning else 0.0, 1.0 - exp(-delta * 14.0))
	_boosting = boosting
	_wind = wind
	_anticipation *= exp(-delta * 9.0)
	_turbo_pulse = maxf(0.0, _turbo_pulse - delta * 3.5)
	_wind_pulse = maxf(0.0, _wind_pulse - delta * 2.5)
	var speed_target: float = 1.0 if boosting else clampf((balloon.items.wind_multiplier() - 1.0) / 0.35, 0.0, 1.0)
	if not balloon.racing:
		speed_target = 0.0
	speed_glow = lerpf(speed_glow, speed_target, 1.0 - exp(-delta * 7.0))
	var count: int = balloon.collision_count + balloon.items.hits_received
	if count > _impact_count:
		_shake_left = shake_duration # Restart one envelope; never stack shakes.
		_impact_point = Vector2(35, -20)
		if balloon.get_slide_collision_count() > 0:
			_impact_point = to_local(balloon.get_slide_collision(0).get_position())
	_impact_count = count
	_shake_left = maxf(0.0, _shake_left - delta)
	var envelope: float = _shake_left / shake_duration
	var shake: float = sin((shake_duration - _shake_left) * 28.0) * shake_pixels * envelope * intensity
	position = Vector2(_entry_offset + shake, 0.0)
	var target: float = clampf(balloon.velocity.y / balloon.physics.max_vertical_speed, -1.0, 1.0) * deg_to_rad(tilt_degrees)
	if balloon.racing:
		target += deg_to_rad(sway_degrees) * sin(_time * 1.8 + _phase) * (1.0 + speed_glow)
	target += deg_to_rad(_anticipation * 1.8 - speed_glow * tilt_degrees + shake * 0.4)
	target *= intensity
	# Exact damped spring for a held target: stable even at low rendering FPS.
	var displacement: float = rotation - target
	var damping: float = 7.0
	var stiffness: float = 100.0
	var frequency: float = sqrt(stiffness - damping * damping)
	var decay: float = exp(-damping * delta)
	var cosine: float = cos(frequency * delta)
	var sine: float = sin(frequency * delta)
	rotation = target + decay * (displacement * cosine + (_angular_velocity + damping * displacement) / frequency * sine)
	_angular_velocity = decay * (_angular_velocity * cosine - (damping * _angular_velocity + stiffness * displacement) / frequency * sine)
	var squash: float = sin((1.0 - envelope) * PI * 2.0) * envelope * impact_squash
	var stretch: float = (_turbo_pulse * 0.045 - _anticipation * 0.025 - squash) * intensity
	if boosting and _turbo_age < turbo_anticipation_seconds:
		stretch -= sin(PI * _turbo_age / turbo_anticipation_seconds) * 0.035 * intensity
	scale = _base_scale * Vector2(1.0 + stretch, 1.0 - stretch)
	var follow_target: float = sin(_time * 1.8 + _phase - 0.7) * 0.45 - clampf(_angular_velocity * 8.0, -1.0, 1.0)
	_basket_follow = lerpf(_basket_follow, follow_target, 1.0 - exp(-delta * 5.0))
	_living_motion = Vector3(
		sin(_time * 2.1 + _phase) * breathing_amount,
		_basket_follow * basket_follow_amount,
		sin(_time * 2.7 + _phase + 0.8) * pilot_nod_amount) * intensity
	var material: ShaderMaterial = $CharacterSprite.material
	material.set_shader_parameter("living_motion", _living_motion)
	_pose_blend = minf(1.0, _pose_blend + delta / maxf(0.001, pose_transition_seconds))
	material.set_shader_parameter("pose_blend", smoothstep(0.0, 1.0, _pose_blend))
	var expression_active: bool = displayed_pose == "idle" and _pose_blend >= 1.0
	var blink_clock: float = fposmod(_time + _phase, blink_interval + fposmod(_phase, 0.9))
	_blink = pow(sin(PI * blink_clock / blink_duration), 2.0) if expression_active and blink_clock < blink_duration else 0.0
	var gesture: float = sin(_time * 2.4 + _phase)
	var gesture_clock: float = fposmod(_time + _phase, arm_gesture_interval)
	var gesture_envelope: float = pow(sin(PI * gesture_clock / 1.2), 2.0) if gesture_clock < 1.2 else 0.0
	_arms = Vector2(gesture, sin(_time * 2.1 + _phase + 1.3)) * arm_motion_amount * intensity * gesture_envelope if expression_active else Vector2.ZERO
	material.set_shader_parameter("blink", _blink)
	material.set_shader_parameter("arm_motion", _arms)
	$FlightEffects.queue_redraw()


func draw_effects(canvas: Node2D) -> void:
	var intensity: float = effects_intensity * (0.2 if GameFeel.reduced_motion else 1.0)
	# Reuse the fallback burner's geometry; normal flight keeps one coherent drawing.
	if _burner_glow > 0.01 and current_state in ["idle", "burner"]:
		var flame: float = _burner_glow * (1.0 + sin(_time * 13.0 + _phase) * 0.1 * intensity)
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(-5, 31), Vector2(0, 31 - flame * 19), Vector2(5, 31)]), Color(1, 0.65, 0.18, _burner_glow * 0.85))
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(-2, 31), Vector2(0, 31 - flame * 12), Vector2(2, 31)]), Color(1, 0.94, 0.65, _burner_glow))
	# One batched command for trails and motes; individual antialiased lines
	# force costly draw breaks on the target ANGLE driver.
	for index in (7 if speed_glow > 0.005 else 0):
		var travel: float = fposmod(_time * (1.7 + index * 0.07) + index * 0.37, 1.0)
		var at := Vector2(-43.0 - travel * 90.0, -63.0 + index * 18.0)
		var tint := Color(0.35, 0.85, 1.0).lerp(Color(1.0, 0.8, 0.35), _turbo_color)
		tint.a = sin(travel * PI) * speed_glow * 0.7 * intensity
		_trail_points[index * 4] = at
		_trail_points[index * 4 + 1] = at + Vector2(16.0 + speed_glow * 34.0, 0)
		_trail_points[index * 4 + 2] = at - Vector2(9, 0)
		_trail_points[index * 4 + 3] = at - Vector2(6, 0)
		_trail_colors[index * 2] = tint
		_trail_colors[index * 2 + 1] = tint
	if speed_glow > 0.005:
		canvas.draw_multiline_colors(_trail_points, _trail_colors, 1.5, false)
	if _turbo_pulse > 0:
		canvas.draw_arc(Vector2(0, -18), 48.0 + (1.0 - _turbo_pulse) * 22.0, PI * 0.55, PI * 1.45, 20, Color(1, 0.8, 0.3, _turbo_pulse * 0.55 * intensity), 2.0, true)
	if _wind_pulse > 0:
		canvas.draw_arc(Vector2(0, -18), 50.0 + (1.0 - _wind_pulse) * 15.0, PI * 0.6, PI * 1.4, 16, Color(0.3, 0.85, 1, _wind_pulse * 0.5 * intensity), 1.5, true)
	if _shake_left > 0:
		var life: float = 1.0 - _shake_left / shake_duration
		for index in 6:
			var direction := Vector2.from_angle(index * TAU / 6.0 + _phase)
			var at: Vector2 = _impact_point + direction * (5.0 + life * 22.0)
			canvas.draw_line(at, at + direction * 5.0, Color(1, 0.88, 0.55, (1.0 - life) * intensity), 2.0, true)


func _ready() -> void:
	_trail_points.resize(28)
	_trail_colors.resize(14)
	_base_scale = scale
	# Stable per-racer phase; never consumes the competitive random sequence.
	_phase = float(get_parent().get_index()) * 2.399
	var outline := ShaderMaterial.new()
	outline.shader = preload("res://scripts/character_outline.gdshader")
	$CharacterSprite.material = outline
	refresh.call_deferred() # Parent onready references must be initialized first.


func get_visual_bounds() -> Rect2:
	if $CharacterSprite.visible and $CharacterSprite.texture != null:
		return $CharacterSprite.transform * $CharacterSprite.get_rect()
	return Rect2(-44.0, -74.0, 88.0, 135.0)


func set_local_outline(is_local: bool) -> void:
	var enabled: bool = is_local and local_outline_enabled
	if enabled != local_outline_visible:
		local_outline_visible = enabled
		refresh()


func refresh() -> void:
	var balloon := get_parent() as Balloon
	if balloon.items == null:
		return
	current_state = "idle"
	if victory:
		current_state = "victory"
	elif balloon.racing:
		if balloon.impact_time_left > 0.0 or balloon.items.hit_left > 0.0 or balloon.items.storm_left > 0.0:
			current_state = "hit"
		elif balloon.items.boost_left > 0.0:
			current_state = "turbo"
		elif balloon.burner_active:
			current_state = "burner"
	var key: String = balloon.character_id + ":" + current_state
	# Burner PNGs change proportions, not just expression. Animate idle instead.
	displayed_pose = "idle" if current_state == "burner" else current_state
	var sprite: Sprite2D = $CharacterSprite
	if key != _pose_key:
		var first_pose: bool = _pose_key.is_empty()
		var old_texture: Texture2D = sprite.texture
		var old_scale: Vector2 = sprite.scale
		var old_position: Vector2 = sprite.position
		var previous_blend: float = _pose_blend
		var same_character: bool = _pose_key.get_slice(":", 0) == balloon.character_id
		_pose_key = key
		var regions: Array = CharacterCatalog.gesture_regions(balloon.character_id)
		sprite.material.set_shader_parameter("eyelid_color", CharacterCatalog.EYELIDS.get(balloon.character_id, Color.WHITE))
		for index in 4:
			var region: Vector4 = regions[index] / Vector4(384, 512, 384, 512) if regions.size() == 4 else Vector4.ZERO
			sprite.material.set_shader_parameter(["left_eye", "right_eye", "left_arm", "right_arm"][index], region)
		sprite.material.set_shader_parameter("blink", 0.0)
		sprite.material.set_shader_parameter("arm_motion", Vector2.ZERO)
		sprite.texture = CharacterCatalog.texture_for(balloon.character_id, displayed_pose)
		sprite.material.set_shader_parameter("current_pose", sprite.texture)
		sprite.visible = sprite.texture != null
		$Artwork.visible = not sprite.visible
		if sprite.visible:
			# Uniform scaling preserves illustration proportions. Basket base stays at
			# local Y=61 and envelope top at -74 across the five individual poses.
			var basket: Vector2 = CharacterCatalog.basket_anchor(balloon.character_id, displayed_pose)
			var factor: float = 135.0 / (basket.y - 28.0)
			var target_scale := Vector2.ONE * factor
			var target_position := Vector2(0, 61) - (basket - sprite.texture.get_size() * 0.5) * factor
			# Register both poses before blending; never show a new PNG at the old anchor.
			sprite.scale = target_scale
			sprite.position = target_position
			_pose_blend = 1.0
			if not first_pose and same_character and old_texture != null and old_texture != sprite.texture and pose_transition_seconds > 0:
				var material: ShaderMaterial = sprite.material
				material.set_shader_parameter("previous_pose", old_texture)
				material.set_shader_parameter("previous_scale", target_scale * sprite.texture.get_size() / (old_scale * old_texture.get_size()))
				material.set_shader_parameter("previous_offset", (target_position - old_position) / (old_scale * old_texture.get_size()))
				# Returning to the previous pose midway reverses the blend continuously.
				_pose_blend = 1.0 - previous_blend if sprite.texture == _previous_pose_texture and previous_blend < 1.0 else 0.0
				_previous_pose_texture = old_texture
			sprite.material.set_shader_parameter("pose_blend", smoothstep(0.0, 1.0, _pose_blend))
	if sprite.material != null:
		sprite.material.set_shader_parameter("local_outline", local_outline_visible)
	$Artwork.queue_redraw()
