class_name BalloonVisual
extends CanvasGroup

@export var local_outline_enabled: bool = true
var local_outline_visible: bool = false
var victory: bool = false
var current_state: String = "idle"
var _pose_key: String = ""
@export_range(0.0, 8.0, 0.5) var shake_pixels: float = 4.0
@export_range(0.1, 0.5, 0.05) var shake_duration: float = 0.28
@export_range(0.0, 5.0, 0.25) var tilt_degrees: float = 2.0
var _shake_left: float = 0.0
var _impact_count: int = 0
var _entry_offset: float = 0.0
var _entry_tween: Tween
@export_range(0.0, 0.25, 0.01) var pose_transition_seconds: float = 0.12
var _pose_tween: Tween


func present(duration: float) -> void:
	if _entry_tween != null:
		_entry_tween.kill()
	_entry_offset = -65.0
	_entry_tween = create_tween()
	_entry_tween.tween_property(self, "_entry_offset", 0.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	var balloon := get_parent() as Balloon
	var count: int = balloon.collision_count + balloon.items.hits_received
	if count > _impact_count:
		_shake_left = shake_duration # Restart one envelope; never stack shakes.
	_impact_count = count
	_shake_left = maxf(0.0, _shake_left - delta)
	var shake: float = sin((shake_duration - _shake_left) * 85.0) * shake_pixels * _shake_left / shake_duration
	position = Vector2(_entry_offset + shake, 0.0)
	var target: float = clampf(balloon.velocity.y / balloon.physics.max_vertical_speed, -1.0, 1.0) * deg_to_rad(tilt_degrees)
	if balloon.items.boost_left > 0:
		target -= deg_to_rad(tilt_degrees)
	rotation = lerp_angle(rotation, target, 1.0 - exp(-delta * 10.0))


func _ready() -> void:
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
	var sprite: Sprite2D = $CharacterSprite
	if key != _pose_key:
		var first_pose: bool = _pose_key.is_empty()
		_pose_key = key
		sprite.texture = CharacterCatalog.texture_for(balloon.character_id, current_state)
		sprite.visible = sprite.texture != null
		$Artwork.visible = not sprite.visible
		if sprite.visible:
			# Uniform scaling preserves illustration proportions. Basket base stays at
			# local Y=61 and envelope top at -74 across the five individual poses.
			var basket: Vector2 = CharacterCatalog.basket_anchor(balloon.character_id, current_state)
			var factor: float = 135.0 / (basket.y - 28.0)
			var target_scale := Vector2.ONE * factor
			var target_position := Vector2(0, 61) - (basket - sprite.texture.get_size() * 0.5) * factor
			if _pose_tween != null:
				_pose_tween.kill()
			if first_pose or pose_transition_seconds <= 0:
				sprite.scale = target_scale
				sprite.position = target_position
			else:
				_pose_tween = create_tween().set_parallel(true)
				_pose_tween.tween_property(sprite, "scale", target_scale, pose_transition_seconds).set_trans(Tween.TRANS_SINE)
				_pose_tween.tween_property(sprite, "position", target_position, pose_transition_seconds).set_trans(Tween.TRANS_SINE)
	if sprite.material != null:
		sprite.material.set_shader_parameter("local_outline", local_outline_visible)
	$Artwork.queue_redraw()
