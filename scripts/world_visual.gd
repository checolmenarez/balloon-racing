extends Node2D

const ROOT: String = "res://assets/worlds/valle_ventoso/"
const TERRAIN_KIT = preload("res://scripts/terrain_kit_visual.gd")
var _terrain_kit = TERRAIN_KIT.new()
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
	_terrain_kit.ground($TerrainVisual, finish_x)


func _dress_obstacles() -> void:
	var obstacles: Node = get_parent().get_node_or_null("Obstacles")
	if obstacles == null:
		return
	for obstacle: FlightObstacle in obstacles.get_children():
		for node_name in ["LowerVisual", "UpperVisual"]:
			var polygon: Polygon2D = obstacle.get_node(node_name)
			if polygon.visible and polygon.polygon.size() >= 3:
				_terrain_kit.formation($TerrainVisual, obstacle, polygon, node_name == "UpperVisual")


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
