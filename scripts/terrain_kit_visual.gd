extends RefCounted
## Sprite composition only. Collision polygons are read, never edited.
const ROOT := "res://assets/environments/valle_ventoso/terrain_kit/"
const SCALE := 1.25
var textures: Dictionary = {}
var blend: ShaderMaterial
var edge_materials: Dictionary = {}

func texture(asset: String) -> Texture2D:
	if not textures.has(asset):
		textures[asset] = load(ROOT + asset + ".png")
	return textures[asset]

func sprite(parent: Node, asset: String, at: Vector2, factor: float = SCALE) -> Sprite2D:
	var result := Sprite2D.new()
	result.name = asset.get_file().to_pascal_case()
	result.texture = texture(asset)
	result.position = at
	result.scale = Vector2.ONE * factor
	result.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	parent.add_child(result)
	return result

func ground(parent: Node2D, end: float) -> void:
	var x: float = -1500.0
	var index: int = 0
	while x < end + 2000.0:
		var asset: String = "terrain_lower/lower_flat_a" if index % 3 == 0 else "terrain_lower/lower_flat_b"
		var part := sprite(parent, asset, Vector2(x, 640.0))
		part.centered = false
		part.flip_h = index % 4 == 2
		x += part.texture.get_width() * SCALE - 5.0
		index += 1

func formation(parent: Node2D, obstacle: FlightObstacle, source: Polygon2D, upper: bool) -> void:
	# This white polygon is a stencil ONLY. All visible colour comes from sprites.
	var mask := Polygon2D.new()
	mask.name = str(obstacle.name) + ("Ceiling" if upper else "Surface")
	mask.position = obstacle.position
	mask.polygon = _organic_outline(source.polygon, obstacle.name == &"RouteDivider")
	mask.set_meta("collision_outline", source.polygon.duplicate())
	mask.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	mask.set_meta("source_obstacle", obstacle.name)
	parent.add_child(mask)
	var bounds := Rect2(mask.polygon[0], Vector2.ZERO)
	for point in mask.polygon:
		bounds = bounds.expand(point)
	_body(mask, bounds, int(obstacle.position.x))
	_rock_clusters(mask, bounds, int(obstacle.position.x), upper)
	var points: PackedVector2Array = source.polygon
	for i in points.size():
		var a: Vector2 = points[i]
		var b: Vector2 = points[(i + 1) % points.size()]
		if b.x > a.x + 1.0:
			_edge(mask, a, b, upper)
		elif obstacle.kind == FlightObstacle.Kind.ISLAND and a.x > b.x + 1.0:
			_edge(mask, b, a, true, true)
	_signature(mask, obstacle, upper)
	source.hide()
	if obstacle.name == &"RouteDivider":
		# Actual flat surface, clear of both boxes and the upper-route flight path.
		_landmark(parent, "props/windmill", obstacle.position + Vector2(-350, obstacle.upper_tip_y), 0.62, Rect2(0, 0, 101, 108))
		_landmark(parent, "props/house", obstacle.position + Vector2(450, obstacle.upper_tip_y), 0.60, Rect2(0, 0, 81, 99))
	if obstacle.name == &"RouteDivider":
		var bridge := sprite(parent, "props/wooden_bridge", obstacle.position + Vector2(145, obstacle.upper_tip_y), 1.35)
		bridge.region_enabled = true
		bridge.region_filter_clip_enabled = true
		bridge.region_rect = Rect2(0, 0, 130, 68)
		bridge.centered = false
		bridge.offset = Vector2(-65, -53)
		bridge.set_meta("surface_anchor", obstacle.position + Vector2(145, obstacle.upper_tip_y))

func _signature(parent: Polygon2D, obstacle: FlightObstacle, upper: bool) -> void:
	if upper:
		var part := sprite(parent, "terrain_upper/upper_point_deep", Vector2(0, obstacle.upper_tip_y), 1.65)
		part.region_enabled = true
		part.region_filter_clip_enabled = true
		part.region_rect = Rect2(4, 22, 112, 67)
		part.centered = false
		part.offset = Vector2(-56, -65)
		part.material = _edge_material("HangingKeystone", part.region_rect, true)
	elif obstacle.kind != FlightObstacle.Kind.ISLAND:
		var part := sprite(parent, "terrain_lower/lower_peak_small", Vector2(0, obstacle.lower_tip_y), 1.35)
		# Exclude the neighbouring sliver at the right of the original extraction.
		part.region_enabled = true
		part.region_filter_clip_enabled = true
		part.region_rect = Rect2(0, 0, 82, 90)
		part.centered = false
		part.offset = Vector2(-57, -1)
		part.material = _edge_material("MountainKeystone", part.region_rect, false)
	elif obstacle.outline.is_empty():
		# Whole island crowns carry their original facets and flower clusters.
		var count: int = maxi(2, ceili(obstacle.width / 190.0))
		for index in count:
			var x: float = lerpf(-obstacle.width * 0.43, obstacle.width * 0.43, float(index) / (count - 1))
			var part := sprite(parent, "islands/island_large", Vector2(x, obstacle.upper_tip_y), 1.55)
			part.centered = false
			part.offset = Vector2(-70, -23)
			part.flip_h = index % 3 == 1
			part.material = _edge_material("IslandCrown", Rect2(Vector2.ZERO, part.texture.get_size()), false)

func _organic_outline(points: PackedVector2Array, bridge_ledge: bool = false) -> PackedVector2Array:
	var result := PackedVector2Array()
	for i in points.size():
		var a: Vector2 = points[i]
		var b: Vector2 = points[(i + 1) % points.size()]
		var edge: Vector2 = b - a
		var inward := Vector2(-edge.y, edge.x).normalized()
		var steps: int = maxi(1, ceili(edge.length() / 24.0))
		for j in steps:
			var point: Vector2 = a.lerp(b, float(j) / steps)
			# Small broken ledges, not a changed gameplay boundary. All offsets
			# go inward, capped at 8 px, so the narrow routes never get covered.
			var notch: float = [0.0, 3.0, 7.0, 2.0, 5.0][(j + i * 3) % 5]
			if j == 0 or (is_equal_approx(a.y, 640.0) and is_equal_approx(b.y, 640.0)) or (is_equal_approx(a.y, 32.0) and is_equal_approx(b.y, 32.0)):
				notch = 0.0
			# A shallow visual recess crossed by the kit's wooden deck. The deck
			# keeps the original solid top at Y=330; no unsupported bridge props.
			if bridge_ledge and is_equal_approx(a.y, 330.0) and is_equal_approx(b.y, 330.0) and point.x > 80.0 and point.x < 210.0:
				notch = 16.0
			result.append(point + inward * notch)
	return result

func _landmark(parent: Node2D, asset: String, at: Vector2, factor: float, region: Rect2) -> void:
	# The extracted props contain transparent padding below their painted base.
	var part := sprite(parent, asset, at + Vector2(0, 8), factor)
	part.region_enabled = true
	part.region_filter_clip_enabled = true
	part.region_rect = region
	part.offset.y = -region.size.y * 0.5
	part.set_meta("surface_anchor", at)

func _rock_clusters(parent: Polygon2D, bounds: Rect2, seed_value: int, upper: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 1049
	var x: float = bounds.position.x + 30.0
	while x < bounds.end.x:
		var asset: String = "terrain_upper/upper_island_a" if rng.randf() > 0.45 else "terrain_upper/upper_point_deep"
		var factor: float = rng.randf_range(1.15, 1.45)
		var at := Vector2(x, bounds.end.y - rng.randf_range(22.0, 60.0))
		if upper: at.y = bounds.position.y + bounds.size.y * rng.randf_range(0.4, 0.75)
		var part := sprite(parent, asset, at, factor)
		part.region_enabled = true
		part.region_filter_clip_enabled = true
		part.region_rect = Rect2(8, 30, part.texture.get_width() - 16, part.texture.get_height() - 30)
		part.flip_h = rng.randf() > 0.5
		part.material = _edge_material(asset + "Cluster", part.region_rect, true)
		x += rng.randf_range(75.0, 110.0)

func _edge_material(key: String, region: Rect2, upper: bool) -> ShaderMaterial:
	if not edge_materials.has(key):
		var material := ShaderMaterial.new()
		material.shader = preload("res://scripts/terrain_edge_blend.gdshader")
		material.set_shader_parameter("source_rect", Vector4(region.position.x, region.position.y, region.size.x, region.size.y))
		material.set_shader_parameter("underside", upper)
		edge_materials[key] = material
	return edge_materials[key]

func _body(parent: Polygon2D, bounds: Rect2, seed_value: int) -> void:
	# Rock sections from the supplied modular flats, at uniform scale. No warping,
	# repeated texture, invented fill, baked decorations or transformed colliders.
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	if blend == null:
		blend = ShaderMaterial.new()
		blend.shader = preload("res://scripts/terrain_module_blend.gdshader")
	var y: float = bounds.position.y - 20.0
	var row: int = 0
	while y < bounds.end.y + 40.0:
		var x: float = bounds.position.x - 100.0 - float(row % 3) * 43.0
		while x < bounds.end.x + 100.0:
			var variant: int = rng.randi_range(0, 1)
			var asset: String = "terrain_lower/lower_flat_a" if variant == 0 else "terrain_lower/lower_flat_b"
			var part := sprite(parent, asset, Vector2(x, y))
			part.region_enabled = true
			part.region_filter_clip_enabled = true
			part.region_rect = Rect2(5, 24, 106, 36)
			part.material = blend
			part.flip_h = rng.randf() > 0.5
			x += rng.randf_range(100.0, 109.0)
		y += rng.randf_range(32.0, 35.0)
		row += 1

func _edge(parent: Polygon2D, a: Vector2, b: Vector2, upper: bool, island_bottom: bool = false) -> void:
	var length: float = a.distance_to(b)
	var angle: float = (b - a).angle()
	var count: int = maxi(1, ceili(length / 100.0))
	for index in count:
		var at: Vector2 = a.lerp(b, (float(index) + 0.5) / count)
		var asset: String
		var anchor: Vector2
		var native_angle: float = 0.0
		var mirrored: bool = angle > 0.0
		if upper:
			if island_bottom:
				asset = "islands/island_large"
				anchor = Vector2(70, 58)
			elif absf(angle) > 0.25:
				asset = "terrain_upper/upper_left_edge" if mirrored else "terrain_upper/upper_right_edge"
				anchor = Vector2(48, 52)
				native_angle = 0.65 if mirrored else -0.65
			else:
				asset = "terrain_upper/upper_point_deep"
				anchor = Vector2(60, 82)
		else:
			if absf(angle) > 0.65:
				asset = "terrain_lower/lower_left_ramp" if not mirrored else "terrain_lower/lower_right_edge"
				anchor = Vector2(43, 18)
				native_angle = 0.55 if mirrored else -0.55
			elif absf(angle) > 0.18:
				asset = "terrain_lower/lower_slope_gentle"
				anchor = Vector2(52, 9)
				native_angle = 0.25 if mirrored else -0.25
			else:
				asset = "terrain_lower/lower_flat_a" if index % 2 == 0 else "terrain_lower/lower_flat_b"
				anchor = Vector2(56, 3)
		var part := sprite(parent, asset, at)
		part.centered = false
		if upper:
			# The kit's hanging pieces include a grassy top. That top cannot appear
			# inside an island/ceiling face; retain only their rock and hanging edge.
			part.region_enabled = true
			part.region_filter_clip_enabled = true
			var crop_top: float = 45.0 if island_bottom else 24.0
			part.region_rect = Rect2(0, crop_top, part.texture.get_width(), part.texture.get_height() - crop_top)
			anchor.y -= crop_top
		part.offset = -anchor
		part.rotation = angle - native_angle
		var key: String = asset + str(upper)
		var region: Rect2 = part.region_rect if part.region_enabled else Rect2(Vector2.ZERO, part.texture.get_size())
		part.material = _edge_material(key, region, upper)
		if not upper and asset.ends_with("gentle"):
			part.flip_h = mirrored
