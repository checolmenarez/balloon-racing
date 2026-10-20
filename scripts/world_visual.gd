extends Node2D

const ROOT: String = "res://assets/worlds/valle_ventoso/"
const LAYER_SCRIPT = preload("res://scripts/world_parallax_layer.gd")


func _ready() -> void:
	_build_background()
	_build_terrain()
	_dress_obstacles.call_deferred() # Fixtures may append obstacles after WorldVisual.
	_build_signs()
	# Reference-only anchors for future artwork, not new gameplay zones.
	for kind in ["ascendente", "descendente", "remolino"]:
		var hook := Marker2D.new()
		hook.name = kind
		hook.set_meta("visual_scene", "res://scenes/WorldWindVisual.tscn")
		$WindVisual.add_child(hook)


func _build_background() -> void:
	var names: Array[String] = ["01_sky", "02_far_clouds", "03_distant_islands", "04_mid_islands", "05_playable_backdrop", "06_front_clouds"]
	var speeds: Array[float] = [0.025, 0.08, 0.16, 0.27, 0.40, 0.55]
	var heights: Array[float] = [760, 210, 230, 210, 200, 125]
	var positions_y: Array[float] = [-20, 100, 225, 370, 495, 610]
	var opacity: Array[float] = [1.0, 0.35, 0.32, 0.30, 0.26, 0.45]
	for index in names.size():
		var layer := Node2D.new()
		layer.set_script(LAYER_SCRIPT)
		layer.name = names[index].substr(3).to_pascal_case()
		layer.texture = load(ROOT + "parallax/layer_" + names[index] + ".png")
		layer.scroll_factor = speeds[index]
		layer.strip_y = positions_y[index]
		layer.strip_height = heights[index]
		layer.modulate = Color(1, 1, 1, opacity[index])
		layer.z_index = -30 + index
		$ParallaxBackground.add_child(layer)


func _sprite(parent: Node, asset: String, at: Vector2, size: Vector2, bottom: bool = false) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load(ROOT + asset + ".png")
	sprite.position = at
	var dimensions: Vector2 = sprite.texture.get_size()
	sprite.scale = Vector2.ONE * minf(size.x / dimensions.x, size.y / dimensions.y)
	if bottom:
		sprite.offset.y = -dimensions.y * 0.5
	parent.add_child(sprite)
	return sprite


func _build_terrain() -> void:
	var finish_x: float = get_parent().get_node("References/Finish").position.x
	for x in range(-1500, int(finish_x) + 2000, 220):
		var tile: Sprite2D = _sprite($TerrainVisual, "terrain/base/plataforma_recta", Vector2(x, 640), Vector2(232, 110))
		tile.offset.y = tile.texture.get_height() * 0.5
	for x in [700, 2500, 4300, 6100, 8100, 9400, 13400, 16700, 18700]:
		var asset: String = "molino_viento" if x % 3 == 1 else "arbol_redondo"
		var decor: Sprite2D = _sprite($DecorVisual, "props/decor/" + asset, Vector2(x, 650), Vector2(140, 145), true)
		decor.modulate = Color(0.90, 0.96, 1.0, 0.65)
		_sprite($DecorVisual, "props/decor/flores_arbustos", Vector2(x + 130, 660), Vector2(95, 55), true)
	_sprite($DecorVisual, "props/decor/casita_torre", Vector2(500, 650), Vector2(140, 150), true)


func _dress_obstacles() -> void:
	var obstacles: Node = get_parent().get_node_or_null("Obstacles")
	if obstacles == null:
		return
	var rock: Texture2D = load(ROOT + "terrain/base/rock_fill.png")
	for obstacle in obstacles.get_children():
		for node_name in ["LowerVisual", "UpperVisual"]:
			var polygon: Polygon2D = obstacle.get_node(node_name)
			if not polygon.visible or polygon.polygon.size() < 4:
				continue
			# Dress the exact existing polygon; never alter its collision counterpart.
			polygon.texture = rock
			polygon.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			var uv := PackedVector2Array()
			for point in polygon.polygon:
				uv.append(point * 0.45)
			polygon.uv = uv
			polygon.color = Color("c9b897") if node_name == "LowerVisual" else Color("a2b5c2")
			var rim := Line2D.new()
			rim.points = polygon.polygon
			rim.closed = true
			rim.width = 3.0
			rim.default_color = Color("465b65")
			polygon.add_child(rim)
			if node_name == "LowerVisual":
				var grass := Line2D.new()
				grass.points = PackedVector2Array([polygon.polygon[1], polygon.polygon[2], polygon.polygon[3]])
				grass.width = 6.0
				grass.default_color = Color("82ad44")
				polygon.add_child(grass)
		if obstacle.kind == FlightObstacle.Kind.UPPER and obstacle.upper_tip_y > 180:
			var hazard: Node2D = load("res://scenes/WorldHazardVisual.tscn").instantiate()
			hazard.position = Vector2(obstacle.position.x, 110)
			$HazardVisual.add_child(hazard)


func _build_signs() -> void:
	var refs: Node = get_parent().get_node("References")
	_sprite($SignageVisual, "terrain/connectors/plataforma_inicio", Vector2(refs.get_node("Start").position.x, 650), Vector2(180, 125), true)
	_sprite($SignageVisual, "gameplay/signage/checkpoint_visual", Vector2(refs.get_node("Merge").position.x, 640), Vector2(70, 90), true)
	_sprite($SignageVisual, "gameplay/signage/meta_visual", Vector2(refs.get_node("Finish").position.x, 650), Vector2(240, 150), true)
	for x in [1300, 2700, 6000, 9250, 13400, 16900]:
		_sprite($SignageVisual, "gameplay/signage/indicador_direccion", Vector2(x, 635), Vector2(58, 75), true)
	queue_redraw()


func _draw() -> void:
	var start_x: float = get_parent().get_node("References/Start").position.x
	# Decorative tape shares the start reference and has no collision node.
	for y in range(70, 640, 20):
		draw_rect(Rect2(start_x - 6, y, 12, 20), Color(1, 0.88, 0.45, 0.65) if y % 40 == 10 else Color(0.16, 0.27, 0.32, 0.55))
	# The line remains the exact racing reference, even though the arch is decorative.
	var marker := get_parent().get_node("References/Finish") as Marker2D
	if marker == null:
		return
	for y in range(90, 640, 24):
		draw_line(Vector2(marker.position.x, y), Vector2(marker.position.x, y + 12), Color(1, 1, 1, 0.65), 3)
