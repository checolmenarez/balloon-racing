@tool
extends Area2D

@export var enabled: bool = true
@export var size: Vector2 = Vector2(1000, 110):
	set(value):
		size = value
		if is_node_ready():
			_update_shape()
@export_range(1.0, 1.35, 0.05) var speed_multiplier: float = 1.20
var _wind_texture: Texture2D
var _visual_time: float = 0.0
var _flow_points := PackedVector2Array()
var _flow_colors := PackedColorArray()


func _ready() -> void:
	_wind_texture = load("res://assets/worlds/valle_ventoso/gameplay/wind/lateral.png")
	_update_shape()
	if not Engine.is_editor_hint():
		body_entered.connect(_enter)
		body_exited.connect(_leave)


func _update_shape() -> void:
	var shape := RectangleShape2D.new()
	shape.size = size
	$CollisionShape2D.shape = shape
	queue_redraw()


func _enter(body: Node2D) -> void:
	if enabled and body is Balloon and body.racing:
		body.items.wind_zones[self] = speed_multiplier


func _leave(body: Node2D) -> void:
	if body is Balloon:
		body.items.wind_zones.erase(self)


func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return
	for body in get_overlapping_bodies():
		_leave(body)


func _process(delta: float) -> void:
	_visual_time += delta * (0.2 if GameFeel.reduced_motion else 1.0)
	queue_redraw()


func _draw() -> void:
	if not enabled:
		return
	var rect := Rect2(-size * 0.5, size)
	var strength: float = clampf((speed_multiplier - 1.0) / 0.35, 0.0, 1.0)
	draw_rect(rect, Color(0.3, 0.85, 0.95, 0.12))
	draw_line(rect.position, Vector2(rect.end.x, rect.position.y), Color(0.2, 0.65, 0.8, 0.5), 1.0)
	draw_line(Vector2(rect.position.x, rect.end.y), rect.end, Color(0.2, 0.65, 0.8, 0.5), 1.0)
	var count: int = mini(48, maxi(6, int(size.x / 30.0)))
	_flow_points.resize(count * 2)
	_flow_colors.resize(count)
	for index in count:
		var travel: float = fposmod(index * 0.618 + _visual_time * (85.0 + strength * 90.0) / size.x, 1.0)
		var at := Vector2(rect.position.x + travel * size.x, rect.position.y + 8.0 + fposmod(index * 0.381, 1.0) * (size.y - 16.0))
		var alpha: float = sin(travel * PI) * (0.12 + strength * 0.22)
		_flow_points[index * 2] = at
		_flow_points[index * 2 + 1] = at + Vector2(minf(24.0 + strength * 16.0, rect.end.x - at.x), 0)
		_flow_colors[index] = Color(0.25, 0.85, 1, alpha)
	draw_multiline_colors(_flow_points, _flow_colors, 1.5, false)
	for x in range(int(-size.x * 0.5) + 35, int(size.x * 0.5) - 20, 100):
		if _wind_texture != null:
			var height: float = minf(size.y - 12.0, 48.0)
			draw_texture_rect(_wind_texture, Rect2(x - 25 + sin(_visual_time * 2.0) * 5.0, -height * 0.5, 65, height), false, Color(1, 1, 1, 0.65))
			continue
		draw_line(Vector2(x - 20, 0), Vector2(x + 16, 0), Color(0.12, 0.5, 0.7, 0.65), 2.0)
		draw_polyline(PackedVector2Array([Vector2(x + 5, -8), Vector2(x + 16, 0), Vector2(x + 5, 8)]), Color(0.12, 0.5, 0.7, 0.65), 2.0)
