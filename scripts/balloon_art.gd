extends Node2D

@onready var balloon: Balloon = get_parent().get_parent()


func _draw() -> void:
	# All artwork is geometry, with no external textures.
	draw_set_transform(Vector2(0, -25), 0.0, Vector2(1.0, 1.1))
	if balloon.visual.local_outline_visible:
		draw_arc(Vector2.ZERO, 45.0, 0.0, TAU, 64, Color("243c52"), 1.5, true)
	draw_circle(Vector2.ZERO, 44.0, balloon.envelope_color.darkened(0.3))
	draw_circle(Vector2.ZERO, 41.0, balloon.envelope_color)
	draw_set_transform(Vector2(0, -25), 0.0, Vector2(0.52, 1.05))
	draw_circle(Vector2.ZERO, 41.0, balloon.envelope_color.lightened(0.3))
	draw_set_transform(Vector2.ZERO)
	draw_colored_polygon(PackedVector2Array([Vector2(-28, 9), Vector2(28, 9), Vector2(12, 30), Vector2(-12, 30)]), balloon.envelope_color.darkened(0.1))
	for side in [-1.0, 1.0]:
		draw_line(Vector2(side * 15, 24), Vector2(side * 18, 43), Color("654937"), 3.0, true)
	if balloon.items.boost_left > 0.0:
		draw_line(Vector2(-40, -25), Vector2(-85, -25), Color("ffd34e"), 7.0)
		draw_colored_polygon(PackedVector2Array([Vector2(-10, 41), Vector2(0, 8), Vector2(10, 41)]), Color("ffe371"))
	if balloon.burner_active:
		draw_colored_polygon(PackedVector2Array([Vector2(-7, 41), Vector2(0, 17), Vector2(7, 41)]), Color("ffb52e"))
		draw_colored_polygon(PackedVector2Array([Vector2(-3, 41), Vector2(0, 27), Vector2(3, 41)]), Color("fff1a1"))
	draw_rect(Rect2(-21, 42, 42, 19), Color("805032"))
	draw_rect(Rect2(-18, 46, 36, 12), Color("bc8750"))
	for x in [-10.0, 0.0, 10.0]:
		draw_line(Vector2(x, 46), Vector2(x, 58), Color("94643d"), 2.0)
