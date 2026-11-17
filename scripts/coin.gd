class_name SinglePlayerCoin
extends Area2D

signal collected(coin: SinglePlayerCoin)
var consumed: bool = false
var _time: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	rotation = sin(_time * 3.0) * 0.08
	var pulse := 1.0 + sin(_time * 6.0) * 0.06
	scale = Vector2.ONE * pulse
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if consumed or not (body is Balloon) or not body.racing:
		return
	consumed = true
	set_deferred("monitoring", false)
	collected.emit(self)
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "scale", Vector2.ONE * 1.65, 0.12).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "modulate:a", 0.0, 0.12)
	tween.chain().tween_callback(queue_free)


func _draw() -> void:
	draw_circle(Vector2.ZERO, 18.0, Color("fff2a1"))
	draw_circle(Vector2.ZERO, 14.0, Color("f6b82f"))
	draw_arc(Vector2.ZERO, 10.0, 0.0, TAU, 24, Color("fff4a8"), 3.0)
	draw_line(Vector2(-3, -8), Vector2(4, -8), Color("c77917"), 2.0)
	draw_line(Vector2(-3, 8), Vector2(4, 8), Color("c77917"), 2.0)

