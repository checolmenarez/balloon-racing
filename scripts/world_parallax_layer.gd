extends Node2D

@export var texture: Texture2D
@export_range(0.0, 1.0, 0.01) var scroll_factor: float = 0.2
@export var strip_y: float = 200.0
@export var strip_height: float = 180.0
@export var tile_width: float = 1800.0
var _camera_x: float = 0.0
var _half_width: float = 1000.0


func _process(_delta: float) -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera != null:
		_camera_x = camera.global_position.x
		_half_width = get_viewport_rect().size.x / camera.zoom.x * 0.5 + tile_width
		position.x = _camera_x * (1.0 - scroll_factor)
	queue_redraw()


func _draw() -> void:
	if texture == null:
		return
	var center: float = _camera_x - position.x
	for index in range(floori((center - _half_width) / tile_width), ceili((center + _half_width) / tile_width) + 1):
		# Alternating mirror tiles meet at identical edge pixels; no hard repeat seam.
		if posmod(index, 2) == 1:
			draw_set_transform(Vector2((index + 1) * tile_width, 0), 0.0, Vector2(-1, 1))
		else:
			draw_set_transform(Vector2(index * tile_width, 0))
		draw_texture_rect(texture, Rect2(0, strip_y, tile_width, strip_height), false)
	draw_set_transform(Vector2.ZERO)
