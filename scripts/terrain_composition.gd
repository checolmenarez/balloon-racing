extends Node2D
## Immutable drawing commands: one CanvasItem per formation, no per-frame assembly.
var pieces: Array[Dictionary] = []

func piece(texture: Texture2D, region: Rect2, at: Vector2, factor: float,
		angle: float = 0.0, tint: Color = Color.WHITE, flip: bool = false, feather: bool = false) -> void:
	pieces.append({"texture": texture, "region": region, "at": at,
		"factor": factor, "angle": angle, "tint": tint, "flip": flip, "feather": feather})

func _draw() -> void:
	for part in pieces:
		draw_set_transform(part.at, part.angle, Vector2(-part.factor if part.flip else part.factor, part.factor))
		if part.feather:
			_feathered(part)
		else:
			draw_texture_rect_region(part.texture, Rect2(-part.region.size * 0.5, part.region.size), part.region, part.tint)
	draw_set_transform(Vector2.ZERO)

func _feathered(part: Dictionary) -> void:
	# Vertex alpha joins adjacent crops without a fragment shader or texture warp.
	var region: Rect2 = part.region
	var xs: Array = [0.0, 14.0, region.size.x - 14.0, region.size.x]
	var ys: Array = [0.0, 12.0, region.size.y - 12.0, region.size.y]
	for y in 3:
		for x in 3:
			var positions := PackedVector2Array()
			var uvs := PackedVector2Array()
			var colors := PackedColorArray()
			for corner in [Vector2i(x,y), Vector2i(x+1,y), Vector2i(x+1,y+1), Vector2i(x,y+1)]:
				var at := Vector2(xs[corner.x], ys[corner.y])
				positions.append(at - region.size * 0.5)
				uvs.append((region.position + at) / part.texture.get_size())
				var color: Color = part.tint
				if corner.x in [0,3] or corner.y in [0,3]: color.a = 0.0
				colors.append(color)
			draw_polygon(positions, colors, uvs, part.texture)
