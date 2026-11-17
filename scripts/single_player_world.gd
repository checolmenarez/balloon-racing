extends Node2D

const ROOT := "res://assets/worlds/valle_ventoso/"
const LAYER_SCRIPT := preload("res://scripts/world_parallax_layer.gd")
var _camera_x: float = 0.0


func _ready() -> void:
	var names: Array[String] = ["01_sky", "02_far_clouds", "03_distant_islands", "06_front_clouds"]
	var speeds: Array[float] = [0.025, 0.08, 0.16, 0.55]
	var heights: Array[float] = [760.0, 210.0, 270.0, 100.0]
	var positions_y: Array[float] = [-20.0, 100.0, 325.0, 650.0]
	var opacity: Array[float] = [1.0, 0.24, 0.24, 0.28]
	for index in names.size():
		var layer := Node2D.new()
		layer.set_script(LAYER_SCRIPT)
		layer.name = names[index].substr(3).to_pascal_case()
		layer.texture = load(ROOT + "parallax/layer_" + names[index] + ".png")
		layer.scroll_factor = speeds[index]
		layer.strip_y = positions_y[index]
		layer.strip_height = heights[index]
		layer.drift_speed = 6.0 if index == 1 else (14.0 if index == 3 else 0.0)
		layer.modulate = Color(1, 1, 1, opacity[index])
		layer.z_index = -30 + index
		add_child(layer)


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	if camera != null:
		_camera_x = camera.position.x
	queue_redraw()


func _draw() -> void:
	var left := _camera_x - 1000.0
	var right := _camera_x + 1000.0
	draw_rect(Rect2(left, 640.0, right - left, 100.0), Color("9a7047"))
	draw_rect(Rect2(left, 635.0, right - left, 12.0), Color("72aa50"))
	for index in range(floori(left / 90.0), ceili(right / 90.0) + 1):
		var x := index * 90.0
		draw_line(Vector2(x, 640), Vector2(x + 10, 630), Color("4f873c"), 3.0)
