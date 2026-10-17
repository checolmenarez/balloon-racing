extends StaticBody2D

var hit: bool = false:
	set(value):
		hit = value
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-20, -245, 40, 490), Color("73d793") if hit else Color("f4ca62"))
	for y in [-180, -60, 60, 180]:
		draw_circle(Vector2(0, y), 30, Color("f4eee1"))
		draw_circle(Vector2(0, y), 19, Color("be5448"))
		draw_circle(Vector2(0, y), 7, Color("f4eee1"))
