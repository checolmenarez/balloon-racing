@tool
class_name FlightObstacle
extends StaticBody2D

enum Kind { LOWER, UPPER, GAP, ISLAND }

@export var kind: Kind = Kind.LOWER:
	set(value):
		kind = value
		_refresh()
@export_range(80.0, 3000.0, 10.0) var width: float = 280.0:
	set(value):
		width = value
		_refresh()
@export var ceiling_y: float = 32.0:
	set(value):
		ceiling_y = value
		_refresh()
@export var ground_y: float = 640.0:
	set(value):
		ground_y = value
		_refresh()
## Lowest point of the hanging formation, in local coordinates.
@export var upper_tip_y: float = 220.0:
	set(value):
		upper_tip_y = value
		_refresh()
## Highest point of the formation rising from the ground.
@export var lower_tip_y: float = 440.0:
	set(value):
		lower_tip_y = value
		_refresh()


func _ready() -> void:
	_refresh()


func get_right_edge() -> float:
	return global_position.x + width * 0.5


func _refresh() -> void:
	if not is_node_ready():
		return
	if kind == Kind.ISLAND:
		# A suspended divider: upper_tip_y and lower_tip_y are its two surfaces.
		var middle: float = (upper_tip_y + lower_tip_y) * 0.5
		var points := PackedVector2Array([
			Vector2(-width * 0.5, middle), Vector2(-width * 0.46, upper_tip_y),
			Vector2(width * 0.46, upper_tip_y), Vector2(width * 0.5, middle),
			Vector2(width * 0.46, lower_tip_y), Vector2(-width * 0.46, lower_tip_y)])
		$LowerVisual.polygon = points
		$LowerVisual.color = Color("718275")
		$LowerVisual.visible = true
		$LowerCollision.polygon = points
		$LowerCollision.disabled = false
		$UpperVisual.visible = false
		$UpperCollision.disabled = true
		return
	_set_formation($LowerVisual, $LowerCollision, false, kind != Kind.UPPER)
	_set_formation($UpperVisual, $UpperCollision, true, kind != Kind.LOWER)


func _set_formation(visual: Polygon2D, shape: CollisionPolygon2D,
		upper: bool, enabled: bool) -> void:
	visual.visible = enabled
	shape.disabled = not enabled
	if not enabled:
		return
	var anchor: float = ceiling_y if upper else ground_y
	var tip: float = upper_tip_y if upper else lower_tip_y
	var shoulder: float = tip + (-35.0 if upper else 35.0)
	var points := PackedVector2Array([
		Vector2(-width * 0.5, anchor), Vector2(-width * 0.22, shoulder),
		Vector2(0.0, tip), Vector2(width * 0.22, shoulder),
		Vector2(width * 0.5, anchor)])
	# The visible polygon and the solid polygon use exactly the same outline.
	visual.polygon = points
	shape.polygon = points
	visual.color = Color("60788e") if upper else Color("8c735b")
