class_name BalloonVisual
extends CanvasGroup

@export var local_outline_enabled: bool = true
var local_outline_visible: bool = false
var victory: bool = false
var current_state: String = "idle"
var _pose_key: String = ""


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
		if balloon.impact_time_left > 0.0 or balloon.items.hit_left > 0.0:
			current_state = "hit"
		elif balloon.items.boost_left > 0.0:
			current_state = "turbo"
		elif balloon.burner_active:
			current_state = "burner"
	var key: String = balloon.character_id + ":" + current_state
	var sprite: Sprite2D = $CharacterSprite
	if key != _pose_key:
		_pose_key = key
		sprite.texture = CharacterCatalog.texture_for(balloon.character_id, current_state)
		sprite.visible = sprite.texture != null
		$Artwork.visible = not sprite.visible
		if sprite.visible:
			# Uniform scaling preserves illustration proportions. Basket base stays at
			# local Y=61 and envelope top at -74 across the five individual poses.
			var basket: float = CharacterCatalog.basket_y(balloon.character_id, current_state)
			var factor: float = 135.0 / (basket - 28.0)
			sprite.scale = Vector2.ONE * factor
			sprite.position = Vector2(0.0, 61.0 - (basket - 256.0) * factor)
	if sprite.material != null:
		sprite.material.set_shader_parameter("local_outline", local_outline_visible)
	$Artwork.queue_redraw()
