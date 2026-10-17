@tool
extends Node2D

## Visual-only attachment for an existing obstacle/effect. Adds no collision or damage.
@export_enum("roca_flotante", "barril_explosivo", "mina_aerea", "turbina", "nube_electrica") var appearance: String = "roca_flotante":
	set(value):
		appearance = value
		queue_redraw()
@export var display_size: Vector2 = Vector2(64, 64)


func _draw() -> void:
	var texture := load("res://assets/worlds/valle_ventoso/gameplay/hazards/%s.png" % appearance) as Texture2D
	var size: Vector2 = texture.get_size()
	size *= minf(display_size.x / size.x, display_size.y / size.y)
	draw_texture_rect(texture, Rect2(-size * 0.5, size), false)
