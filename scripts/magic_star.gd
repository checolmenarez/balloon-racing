class_name MagicStar
extends Area2D

signal collected(star: MagicStar)
var consumed: bool = false
var _time: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	rotation = sin(_time * 2.2) * 0.12
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if consumed or not (body is Balloon) or not body.racing:
		return
	consumed = true
	set_deferred("monitoring", false)
	collected.emit(self)
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "scale", Vector2.ONE * 1.8, 0.18).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "modulate:a", 0.0, 0.18)
	tween.chain().tween_callback(queue_free)


func _draw() -> void:
	var points := PackedVector2Array()
	for index in 10:
		var radius := 22.0 if index % 2 == 0 else 9.0
		var angle := -PI * 0.5 + index * PI / 5.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	draw_circle(Vector2.ZERO, 30.0 + sin(_time * 5.0) * 2.0, Color(0.35, 1.0, 0.75, 0.16))
	draw_colored_polygon(points, Color("70f2bd"))
	draw_polyline(points + PackedVector2Array([points[0]]), Color("eaffd8"), 2.0)

