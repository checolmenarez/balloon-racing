extends Node2D

var target: Balloon
@onready var _cloud: Texture2D = load("res://assets/worlds/valle_ventoso/gameplay/hazards/nube_electrica.png")


func _process(_delta: float) -> void:
	if not is_instance_valid(target) or not target.racing or (target.items.storm_warning_left <= 0.0 and target.items.storm_left <= 0.0):
		queue_free()
		return
	# Offset the cloud slightly so the local TÚ marker remains readable.
	global_position = Vector2(target.global_position.x + 55.0, maxf(target.ceiling_y + 18.0, target.global_position.y - Balloon.TOP_EXTENT - 27.0))
	queue_redraw()


func _draw() -> void:
	if not is_instance_valid(target):
		return
	if _cloud != null:
		draw_texture_rect(_cloud, Rect2(-35, -22, 70, 44), false)
	if target.items.storm_warning_left > 0.0:
		draw_string(ThemeDB.fallback_font, Vector2(-4, 8), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("ffe484"))
	elif target.items.storm_left > target.items.config.storm_duration - 0.22:
		var end: Vector2 = to_local(target.global_position)
		draw_polyline(PackedVector2Array([Vector2(0, 9), end * 0.4 + Vector2(-10, 0), end * 0.5 + Vector2(9, 0), end]), Color("fff18b"), 4.0, true)
