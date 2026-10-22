extends Node2D


func _draw() -> void:
	# Keep CanvasGroup's automatic compositing rectangle intact.
	get_parent().draw_effects(self)
