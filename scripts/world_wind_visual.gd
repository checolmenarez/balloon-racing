@tool
extends Node2D

## Preview/hook only. Gameplay forces belong to WindZone, never to this node.
@export_enum("ascendente", "lateral", "descendente", "remolino", "nube_tormentosa") var appearance: String = "lateral":
	set(value):
		appearance = value
		queue_redraw()
@export var display_size: Vector2 = Vector2(90, 60)


func _draw() -> void:
	var folder: String = "hazards" if appearance == "nube_tormentosa" else "wind"
	var texture := load("res://assets/worlds/valle_ventoso/gameplay/%s/%s.png" % [folder, appearance]) as Texture2D
	draw_texture_rect(texture, Rect2(-display_size * 0.5, display_size), false)
