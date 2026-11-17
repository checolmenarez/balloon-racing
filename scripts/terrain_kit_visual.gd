extends RefCounted
## Art-only construction. Physical outlines are read and retained as metadata.
const ROOT := "res://assets/environments/valle_ventoso/terrain_kit/"
const WORLD := "res://assets/worlds/valle_ventoso/"
const ATLAS := preload("res://assets/environments/valle_ventoso/art_pass_v1/rock_compositions.png")
const COMPOSITION := preload("res://scripts/terrain_composition.gd")
const CACHE := "res://assets/environments/valle_ventoso/art_pass_v1/baked/"
const CACHE_REVISION := 1
const ROCKS := [Rect2(18, 65, 510, 478), Rect2(570, 48, 420, 512), Rect2(1030, 70, 490, 475)]
const FACES := [Rect2(125, 168, 260, 260), Rect2(660, 160, 240, 270), Rect2(1120, 165, 260, 260)]
const CROWNS := [Rect2(18, 565, 510, 390), Rect2(542, 587, 555, 318)]
const ROOTS := Rect2(1120, 565, 400, 395)
var textures: Dictionary = {}

func texture(asset: String) -> Texture2D:
	if not textures.has(asset): textures[asset] = load(asset)
	return textures[asset]

func _layer(parent: Node) -> Node2D:
	var layer := Node2D.new()
	layer.set_script(COMPOSITION)
	layer.name = "RockComposition"
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	parent.add_child(layer)
	return layer

func ground(parent: Node2D, end: float) -> void:
	for chunk in range(-2, ceili(end / 960.0) + 3):
		var layer := _layer(parent)
		layer.name = "Ground%d" % (chunk + 2)
		layer.position = Vector2(chunk * 960.0, 0)
		for i in 5:
			var region: Rect2 = CROWNS[(i + absi(chunk)) % 2]
			layer.piece(ATLAS, region, Vector2(i * 220 - 30, 728), 0.55, 0.0, Color.WHITE, (chunk + i) % 3 == 0)
		layer.queue_redraw()

func formation(parent: Node2D, obstacle: FlightObstacle, source: Polygon2D, upper: bool) -> void:
	var variant: int = (int(obstacle.position.x) / 100) % 3
	if obstacle.name == &"TechnicalIslandS3": variant = 0
	if obstacle.name == &"PrecisionB": variant = 1
	if obstacle.name == &"RouteDivider": variant = 2
	var mask := Polygon2D.new()
	mask.name = str(obstacle.name) + ("Ceiling" if upper else "Surface")
	mask.position = obstacle.position
	mask.polygon = _contour(source.polygon, variant, obstacle.name == &"RouteDivider")
	mask.set_meta("collision_outline", source.polygon.duplicate())
	mask.set_meta("source_obstacle", obstacle.name)
	mask.set_meta("rock_variant", variant)
	mask.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	mask.antialiased = true
	parent.add_child(mask)
	var bounds := Rect2(source.polygon[0], Vector2.ZERO)
	for point in source.polygon: bounds = bounds.expand(point)
	var cached: bool = false
	var image_path: String = CACHE + str(mask.name) + ".png"
	var info_path: String = CACHE + str(mask.name) + ".json"
	if not "bake-terrain" in OS.get_cmdline_user_args() and FileAccess.file_exists(info_path) and ResourceLoader.exists(image_path):
		var info: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(info_path))
		if info.revision == CACHE_REVISION and info.outline_hash == str(source.polygon).sha256_text() and info.get("visual_hash", "") == str(mask.polygon).sha256_text():
			var part := Sprite2D.new()
			part.name = "BakedComposition"
			part.texture = load(image_path)
			part.centered = false
			part.position = Vector2(info.x, info.y)
			part.scale = Vector2.ONE / info.density
			part.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			mask.add_child(part)
			mask.clip_children = CanvasItem.CLIP_CHILDREN_DISABLED
			mask.self_modulate.a = 0.0
			cached = true
	if not cached:
		var layer := _layer(mask)
		_body(layer, bounds, variant, int(obstacle.position.x), upper)
		_edges(layer, source.polygon, upper, obstacle.kind == FlightObstacle.Kind.ISLAND, variant)
		layer.queue_redraw()
	source.hide()
	if obstacle.name == &"ChoiceIsland":
		_waterfall(parent, obstacle.position + Vector2(190, _heights(mask.polygon, 190).x + 4), 0.14)
	if obstacle.name == &"TechnicalIslandS3":
		_waterfall(parent, obstacle.position + Vector2(-240, _heights(mask.polygon, -240).x + 4), 0.15)
	if obstacle.name == &"PrecisionB":
		_waterfall(parent, obstacle.position + Vector2(630, _heights(mask.polygon, 630).x + 4), 0.15)
	if obstacle.name == &"RouteDivider":
		_landmark(parent, "props/windmill", obstacle.position + Vector2(-350, _heights(mask.polygon, -350).x + 5), 0.68, Rect2(0, 0, 101, 108))
		_landmark(parent, "props/house", obstacle.position + Vector2(450, _heights(mask.polygon, 450).x + 5), 0.7, Rect2(0, 0, 81, 99))
		_landmark(parent, "props/wooden_bridge", obstacle.position + Vector2(145, 350), 0.95, Rect2(0, 0, 130, 68))
		_waterfall(parent, obstacle.position + Vector2(260, _heights(mask.polygon, 260).x + 4), 0.15)

func _contour(points: PackedVector2Array, variant: int, divider: bool) -> PackedVector2Array:
	# These track formations are x-monotone. Paired profiles avoid crossing
	# at narrow connectors and keep all artwork within the physical envelope.
	var left: float = INF
	var right: float = -INF
	var xs: Array[float] = []
	for point in points:
		left = minf(left, point.x)
		right = maxf(right, point.x)
		if not xs.has(point.x): xs.append(point.x)
	var x: float = left + 14.0
	while x < right:
		xs.append(x)
		x += 14.0
	xs.sort()
	var top_line := PackedVector2Array()
	var bottom_line := PackedVector2Array()
	for sample in xs:
		var heights := _heights(points, sample)
		var thickness: float = heights.y - heights.x
		var phase: float = sample * 0.028 + variant * 1.7
		var rhythm: float = (sin(phase) + sin(phase * 2.37) * 0.32 + 1.32) / 2.64
		var depth: float = rhythm * 22.0
		if divider:
			depth = _hollow(sample, -830, 55, 20) + _hollow(sample, -300, 72, 24) + _hollow(sample, 145, 55, 26) + _hollow(sample, 680, 84, 17)
		var under: float = (0.5 + 0.5 * sin(sample / 27.0 + variant)) * 22.0
		if divider:
			under = _hollow(sample, -750, 80, 33) + _hollow(sample, -215, 50, 36) + _hollow(sample, 220, 110, 29) + _hollow(sample, 690, 60, 36)
		depth = minf(depth, thickness * (0.30 if divider else 0.22))
		under = minf(under, thickness * (0.30 if divider else 0.22))
		if divider and sample > 60.0 and sample < 230.0:
			depth = 4.0 + 22.0 * sin(clampf((sample - 80.0) / 130.0, 0.0, 1.0) * PI)
		if is_equal_approx(heights.x, 32.0):
			depth = 0.0
			under *= clampf(absf(sample) / 30.0, 0.0, 1.0)
		if is_equal_approx(heights.y, 640.0): under = 0.0
		# Extend into the non-flyable ceiling band so hanging rocks enter from
		# outside the camera instead of exposing a horizontal atlas-like cut.
		top_line.append(Vector2(sample, -96.0 if is_equal_approx(heights.x, 32.0) else heights.x + depth))
		bottom_line.append(Vector2(sample, heights.y - under))
	bottom_line.reverse()
	top_line.append_array(bottom_line)
	return top_line

func _hollow(x: float, center: float, width: float, depth: float) -> float:
	return exp(-pow((x - center) / width, 2.0)) * depth

func _heights(points: PackedVector2Array, x: float) -> Vector2:
	var low: float = INF
	var high: float = -INF
	for i in points.size():
		var a: Vector2 = points[i]
		var b: Vector2 = points[(i + 1) % points.size()]
		if x < minf(a.x, b.x) - 0.01 or x > maxf(a.x, b.x) + 0.01: continue
		if is_equal_approx(a.x, b.x):
			low = minf(low, minf(a.y, b.y))
			high = maxf(high, maxf(a.y, b.y))
		else:
			var y: float = lerpf(a.y, b.y, (x - a.x) / (b.x - a.x))
			low = minf(low, y)
			high = maxf(high, y)
	return Vector2(low, high)

func _body(layer: Node2D, bounds: Rect2, variant: int, seed_value: int, upper: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var shade := Color(0.87, 0.91, 1.0) if variant == 1 else Color.WHITE
	if upper: shade = shade * Color(0.83, 0.88, 0.96)
	var y: float = bounds.position.y - 70.0
	while y < bounds.end.y + 120:
		var x: float = bounds.position.x - 70.0
		while x < bounds.end.x + 120:
			layer.piece(ATLAS, FACES[variant], Vector2(x, y), 0.66, 0.0, shade, false, true)
			x += 150.0
		y += 160.0
	var x: float = bounds.position.x + 35.0
	while x < bounds.end.x + 120:
		var family: int = (variant + rng.randi_range(0, 1)) % 3
		var factor: float = rng.randf_range(0.48, 0.68)
		var at := Vector2(x, bounds.get_center().y + rng.randf_range(-18.0, 30.0))
		layer.piece(ATLAS, ROCKS[family], at, factor, rng.randf_range(-0.08, 0.08), shade, rng.randf() > 0.75)
		x += rng.randf_range(145.0, 205.0)

func _edges(layer: Node2D, points: PackedVector2Array, upper: bool, island: bool, variant: int) -> void:
	var serial: int = 0
	if island:
		var low: float = -INF
		var left: float = INF
		var right: float = -INF
		for point in points:
			low = maxf(low, point.y)
			left = minf(left, point.x)
			right = maxf(right, point.x)
		var x: float = left + 110.0
		while x < right:
			var region: Rect2 = ROOTS if serial % 3 == 0 else ROCKS[(serial + variant) % 3]
			layer.piece(ATLAS, region, Vector2(x, low - region.size.y * 0.2), 0.40, 0, Color(0.87,0.88,0.98))
			x += 180.0 + (serial % 3) * 36.0
			serial += 1

	for i in points.size() - 1:
		var a: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		var edge: Vector2 = b - a
		if edge.x <= 0.0: continue
		var count: int = maxi(1, ceili(edge.length() / (120.0 if upper else 38.0)))
		for j in count:
			var at: Vector2 = a.lerp(b, (float(j) + 0.5) / count)
			if upper:
				var factor: float = 0.29 + (serial % 3) * 0.04
				var region: Rect2 = ROOTS if serial % 3 == 0 else ROCKS[(serial + variant) % 3]
				layer.piece(ATLAS, region, at + Vector2(0, -region.size.y * factor * 0.40), factor, 0, Color(0.85,0.91,1))
			else:
				var crown: Rect2 = CROWNS[(serial / 5 + variant) % 2]
				var region := Rect2(crown.position + Vector2(55 + (serial % 4) * 65, 48), Vector2(140, 80))
				layer.piece(ATLAS, region, at + Vector2(-edge.y, edge.x).normalized() * 18.0, 0.54, edge.angle(), Color.WHITE, false, true)
			serial += 1

func _landmark(parent: Node2D, asset: String, at: Vector2, factor: float, region: Rect2) -> void:
	var part := Sprite2D.new()
	part.texture = texture(ROOT + asset + ".png")
	part.region_enabled = true
	part.region_filter_clip_enabled = true
	part.region_rect = region
	part.position = at
	part.scale = Vector2.ONE * factor
	part.offset.y = -region.size.y * 0.5
	part.set_meta("surface_anchor", at)
	parent.add_child(part)

func _waterfall(parent: Node2D, lip: Vector2, factor: float) -> void:
	var part := Sprite2D.new()
	part.name = "Waterfall"
	part.texture = texture("res://assets/environments/valle_ventoso/art_pass_v1/waterfall.png")
	part.centered = false
	part.offset = Vector2(-512, -110)
	part.position = lip
	part.scale = Vector2.ONE * factor
	# Behind racers/items/current markers, readable as non-solid ambient water.
	part.z_index = 0
	part.modulate = Color(0.85, 0.94, 1.0, 0.68)
	part.set_meta("rock_lip", lip)
	parent.add_child(part)
