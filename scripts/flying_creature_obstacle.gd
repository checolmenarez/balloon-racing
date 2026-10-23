class_name FlyingCreatureObstacle
extends AnimatableBody2D

@export_range(0.0, 200.0, 1.0) var amplitude: float = 45.0
@export_range(0.2, 20.0, 0.1) var period: float = 3.0
@export_range(0.0, 360.0, 1.0) var initial_phase_degrees: float = 0.0
@export var normal_texture: Texture2D
@export var impact_texture: Texture2D
@export_range(40.0, 300.0, 1.0) var visual_width: float = 142.0
@export_range(0.1, 1.0, 0.05) var reaction_duration: float = 0.4
@export_range(0.0, 12.0, 0.5) var reaction_tilt_degrees: float = 7.0
@export_range(0.0, 0.1, 0.005) var wing_amount: float = 0.045
@export_range(0.5, 5.0, 0.1) var wing_frequency: float = 2.2
@export_range(1.0, 6.0, 0.1) var blink_interval: float = 2.3
var elapsed: float = 0.0
var reaction_left: float = 0.0
var _center := Vector2.ZERO
var _visual_time: float = 0.0
@onready var sprite: Sprite2D = $Visual
@onready var shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	# Movement is updated explicitly before racers, in the physics callback.
	sync_to_physics = false
	process_physics_priority = -10
	_center = position
	position = position_at_time(0.0)
	sprite.material = sprite.material.duplicate()
	_update_texture()
	reset_physics_interpolation()


func position_at_time(seconds: float) -> Vector2:
	return _center + Vector2(0, sin(seconds * TAU / maxf(period, 0.2) + deg_to_rad(initial_phase_degrees)) * amplitude)


func _physics_process(delta: float) -> void:
	elapsed += delta
	position = position_at_time(elapsed)


func get_body_bounds() -> Rect2:
	return shape.global_transform * shape.shape.get_rect()


func get_right_edge() -> float:
	return get_body_bounds().end.x


func get_swept_bounds() -> Rect2:
	var bounds: Rect2 = get_body_bounds()
	var center_offset: Vector2 = get_parent().to_global(_center) - global_position
	bounds.position += center_offset - Vector2(0, amplitude)
	bounds.size.y += amplitude * 2.0
	return bounds


func react_to_impact() -> void:
	reaction_left = reaction_duration
	_update_texture()


func _update_texture() -> void:
	sprite.texture = impact_texture if reaction_left > 0 and impact_texture != null else normal_texture
	if sprite.texture != null:
		sprite.scale = Vector2.ONE * visual_width / sprite.texture.get_width()


func _process(delta: float) -> void:
	_visual_time += delta
	var was_hit: bool = reaction_left > 0.0
	reaction_left = maxf(0.0, reaction_left - delta)
	if was_hit and reaction_left == 0.0:
		_update_texture()
	var intensity: float = 0.2 if GameFeel.reduced_motion else 1.0
	var envelope: float = reaction_left / reaction_duration
	sprite.rotation = sin((1.0 - envelope) * TAU) * envelope * deg_to_rad(reaction_tilt_degrees) * intensity
	var clock: float = fposmod(_visual_time + deg_to_rad(initial_phase_degrees), blink_interval)
	var blink: float = pow(sin(clock / 0.18 * PI), 2.0) if clock < 0.18 and reaction_left == 0.0 else 0.0
	sprite.material.set_shader_parameter("blink", blink)
	sprite.material.set_shader_parameter("wing", sin(_visual_time * TAU * wing_frequency) * wing_amount * intensity)
