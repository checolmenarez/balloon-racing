extends Node2D

const ROOT: String = "res://assets/worlds/valle_ventoso/"
const LAYER_SCRIPT = preload("res://scripts/world_parallax_layer.gd")
@export_range(0.0, 2.0, 0.1) var ambient_sway_degrees: float = 0.65
@export_range(0.0, 1.0, 0.05) var background_opacity: float = 0.22
var _animated_decor: Array[Sprite2D] = []
var _ambient_time: float = 0.0


func _process(delta: float) -> void:
	_ambient_time += delta
	for sprite in _animated_decor:
		var wave: float = sin(_ambient_time * 1.6 + sprite.position.x * 0.01)
		sprite.skew = 0.0 if GameFeel.reduced_motion else deg_to_rad(ambient_sway_degrees) * wave
	queue_redraw()


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
	var names: Array[String] = ["01_sky", "02_far_clouds", "03_distant_islands", "06_front_clouds"]
	var speeds: Array[float] = [0.025, 0.08, 0.16, 0.55]
	var heights: Array[float] = [760, 210, 270, 100]
	var positions_y: Array[float] = [-20, 100, 325, 650]
	var opacity: Array[float] = [1.0, background_opacity, background_opacity, 0.28]
	for index in names.size():
		var layer := Node2D.new()
		layer.set_script(LAYER_SCRIPT)
		layer.name = names[index].substr(3).to_pascal_case()
		layer.texture = load(ROOT + "parallax/layer_" + names[index] + ".png")
		layer.scroll_factor = speeds[index]
		layer.drift_speed = 6.0 if index == 1 else (14.0 if index == 3 else 0.0)
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
		if asset == "arbol_redondo":
			_animated_decor.append(decor)
		_animated_decor.append(_sprite($DecorVisual, "props/decor/flores_arbustos", Vector2(x + 130, 660), Vector2(95, 55), true))
	for x in [700, 6100, 13400, 18700]:
		var flag: Sprite2D = _sprite($DecorVisual, "props/decor/bandera_ondeante", Vector2(x + 200, 650), Vector2(55, 75), true)
		flag.modulate.a = 0.65
		_animated_decor.append(flag)
	_sprite($DecorVisual, "props/decor/casita_torre", Vector2(500, 650), Vector2(140, 150), true)


func _dress_obstacles() -> void:
	var obstacles: Node = get_parent().get_node_or_null("Obstacles")
	if obstacles == null:
		return
	var rock: Texture2D = load(ROOT + "terrain/base/valle_reference_atlas.png")
	var rock_material := ShaderMaterial.new()
	rock_material.shader = preload("res://scripts/valle_rock.gdshader")
	var dimensions: Vector2 = rock.get_size()
	rock_material.set_shader_parameter("region", Vector4(405.0 / dimensions.x, 208.0 / dimensions.y, 70.0 / dimensions.x, 58.0 / dimensions.y))
	for obstacle in obstacles.get_children():
		for node_name in ["LowerVisual", "UpperVisual"]:
			var polygon: Polygon2D = obstacle.get_node(node_name)
			if not polygon.visible or polygon.polygon.size() < 4:
				continue
			# Dress the exact existing polygon; never alter its collision counterpart.
			polygon.texture = rock
			polygon.material = rock_material
			polygon.color = Color.WHITE if node_name == "LowerVisual" else Color("c0cbd5")
			var rim := Line2D.new()
			rim.points = polygon.polygon
			rim.closed = true
			rim.width = 3.0
			rim.default_color = Color("60494d")
			polygon.add_child(rim)
			if node_name == "LowerVisual":
				var grass := Line2D.new()
				grass.points = PackedVector2Array([polygon.polygon[1], polygon.polygon[2], polygon.polygon[3]])
				if not obstacle.outline.is_empty():
					grass.points = obstacle.outline.slice(0, obstacle.outline.size() - 2)
				grass.width = 6.0
				grass.default_color = Color("82ad44")
				polygon.add_child(grass)
				_dress_surface(polygon, obstacle)
			else:
				_face_image(polygon, "terrain/vertical/vegetacion_colgante", Rect2(-40, obstacle.upper_tip_y - 105, 75, 100))


func _surface_y(points: PackedVector2Array, x: float) -> float:
	var result: float = INF
	for i in points.size():
		var a: Vector2 = points[i]
		var b: Vector2 = points[(i + 1) % points.size()]
		if absf(a.x - b.x) < 0.001 or x < minf(a.x,b.x) or x > maxf(a.x,b.x):
			continue
		result = minf(result, lerpf(a.y,b.y,(x-a.x)/(b.x-a.x)))
	return result


func _face_image(polygon: Polygon2D, asset: String, rect: Rect2) -> void:
	# Bake decoration into the face, with exact polygon clipping and no extra
	# collision bodies or offscreen canvas groups. Water never hides an air gap.
	var corners := PackedVector2Array([rect.position, Vector2(rect.end.x,rect.position.y), rect.end, Vector2(rect.position.x,rect.end.y)])
	var texture: Texture2D = load(ROOT + asset + ".png")
	var source := Rect2(Vector2.ZERO,texture.get_size())
	if asset == "terrain/vertical/cascada_ancha":
		texture = load(ROOT + "terrain/base/valle_reference_atlas.png")
		source = Rect2(916,140,50,115)
	for points in Geometry2D.intersect_polygons(polygon.polygon, corners):
		var detail := Polygon2D.new()
		detail.name = "FaceDetail"
		detail.texture = texture
		detail.polygon = points
		var uv := PackedVector2Array()
		for point in points:
			uv.append(source.position+(point-rect.position)/rect.size*source.size)
		detail.uv = uv
		polygon.add_child(detail)


func _dress_surface(polygon: Polygon2D, obstacle: FlightObstacle) -> void:
	# Leaves follow the existing surface, rather than covering it with a new island silhouette.
	for x in range(int(-obstacle.width*0.40),int(obstacle.width*0.40)+1,140):
		var y: float = _surface_y(polygon.polygon,x)
		_face_image(polygon,"terrain/vertical/vegetacion_colgante",Rect2(x-22,y-3,48,55))
	if obstacle.kind == FlightObstacle.Kind.ISLAND:
		var left: float = -obstacle.width*0.28
		var right: float = obstacle.width*0.28
		var y: float = _surface_y(polygon.polygon,left)
		_face_image(polygon,"terrain/vertical/cascada_ancha",Rect2(left-32,y+8,64,obstacle.lower_tip_y-y-10))
		var mill_y: float = _surface_y(polygon.polygon,left+120)+8
		var mill_height: float = minf(90.0, obstacle.lower_tip_y-mill_y-5)
		_face_image(polygon,"props/decor/molino_viento",Rect2(left+85,mill_y,mill_height*0.88,mill_height))
		_face_image(polygon,"terrain/connectors/puente_colgante_mediano",Rect2(right-95,_surface_y(polygon.polygon,right)+18,150,48))
		_face_image(polygon,"props/decor/flores_arbustos",Rect2(right-65,_surface_y(polygon.polygon,right)+2,85,35))
	else:
		_face_image(polygon,"props/decor/flores_arbustos",Rect2(-35,obstacle.lower_tip_y+5,70,35))


func _build_signs() -> void:
	var refs: Node = get_parent().get_node("References")
	_sprite($SignageVisual, "terrain/connectors/plataforma_inicio", Vector2(refs.get_node("Start").position.x, 650), Vector2(180, 125), true)
	_sprite($SignageVisual, "gameplay/signage/checkpoint_visual", Vector2(refs.get_node("Merge").position.x, 640), Vector2(70, 90), true)
	_sprite($SignageVisual, "gameplay/signage/meta_visual", Vector2(refs.get_node("Finish").position.x, 650), Vector2(240, 150), true)
	for x in [1300, 2700, 6000, 9250, 13400, 16900]:
		_sprite($SignageVisual, "gameplay/signage/indicador_direccion", Vector2(x, 635), Vector2(58, 75), true)
	queue_redraw()


func _draw() -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera != null and not GameFeel.reduced_motion:
		# Six faint motes in the decorative ground band, below the racing focus.
		for index in 6:
			var phase: float = fposmod(_ambient_time * 0.12 + index * 0.618, 1.0)
			var at := Vector2(camera.position.x - 700.0 + phase * 1400.0, 605.0 + sin(phase * TAU + index) * 20.0)
			draw_circle(at, 1.5, Color(0.8, 0.95, 1, sin(phase * PI) * 0.18))
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
