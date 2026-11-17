class_name SinglePlayerGate
extends FlightObstacle


func _ready() -> void:
	_refresh()


func _refresh() -> void:
	if not is_node_ready():
		return
	var upper_height := maxf(1.0, upper_tip_y - ceiling_y)
	var lower_height := maxf(1.0, ground_y - lower_tip_y)
	var upper_shape := RectangleShape2D.new()
	upper_shape.size = Vector2(width, upper_height)
	$UpperShape.shape = upper_shape
	$UpperShape.position = Vector2(0.0, ceiling_y + upper_height * 0.5)
	var lower_shape := RectangleShape2D.new()
	lower_shape.size = Vector2(width, lower_height)
	$LowerShape.shape = lower_shape
	$LowerShape.position = Vector2(0.0, lower_tip_y + lower_height * 0.5)
	queue_redraw()


func _draw() -> void:
	var half := width * 0.5
	var upper := PackedVector2Array([
		Vector2(-half, ceiling_y), Vector2(half, ceiling_y),
		Vector2(half, upper_tip_y - 24.0), Vector2(half * 0.55, upper_tip_y),
		Vector2(-half * 0.55, upper_tip_y), Vector2(-half, upper_tip_y - 24.0)])
	var lower := PackedVector2Array([
		Vector2(-half, lower_tip_y + 24.0), Vector2(-half * 0.55, lower_tip_y),
		Vector2(half * 0.55, lower_tip_y), Vector2(half, lower_tip_y + 24.0),
		Vector2(half, ground_y), Vector2(-half, ground_y)])
	draw_colored_polygon(upper, Color("536d78"))
	draw_polyline(upper + PackedVector2Array([upper[0]]), Color("8eb4b7"), 3.0)
	draw_colored_polygon(lower, Color("806c53"))
	draw_polyline(lower + PackedVector2Array([lower[0]]), Color("a9a069"), 3.0)

