class_name BalloonTrack
extends Node2D

@export var track_name: String = "Valle Ventoso"

@onready var start: Marker2D = $References/Start
@onready var fork: Marker2D = $References/Fork
@onready var merge: Marker2D = $References/Merge
@onready var finish: Marker2D = $References/Finish
@onready var zones: Node2D = $Zones


func get_progress(world_x: float) -> float:
	return clampf(inverse_lerp(start.global_position.x, finish.global_position.x, world_x), 0.0, 1.0)


func get_upcoming_obstacles(world_x: float, distance: float) -> Array[FlightObstacle]:
	var result: Array[FlightObstacle] = []
	var container: Node = get_node_or_null("Obstacles")
	if container == null:
		return result
	for child in container.get_children():
		var obstacle := child as FlightObstacle
		if obstacle != null and obstacle.get_right_edge() >= world_x - Balloon.HALF_WIDTH - 4.0 and obstacle.global_position.x - obstacle.width * 0.5 <= world_x + distance:
			result.append(obstacle)
	result.sort_custom(func(a: FlightObstacle, b: FlightObstacle) -> bool:
		if (a.kind == FlightObstacle.Kind.ISLAND) != (b.kind == FlightObstacle.Kind.ISLAND):
			return a.kind == FlightObstacle.Kind.ISLAND
		return a.global_position.x - a.width * 0.5 < b.global_position.x - b.width * 0.5)
	return result


func get_zone_index(world_x: float) -> int:
	var result: int = 0
	for index in zones.get_child_count():
		var marker := zones.get_child(index) as Marker2D
		if world_x >= marker.global_position.x:
			result = index
	return result


func get_zone_title(world_x: float) -> String:
	var index: int = get_zone_index(world_x)
	return "%d/6 · %s" % [index + 1, zones.get_child(index).get_meta("title")]


func _draw() -> void:
	if has_node("WorldVisual"):
		return
	# World marker shared by rendering and RaceFlow; no physical barrier.
	var finish_marker := get_node("References/Finish") as Marker2D
	var x: float = finish_marker.position.x
	draw_line(Vector2(x, 110.0), Vector2(x, 640.0), Color("344452"), 6.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(x, 110.0), Vector2(x + 90.0, 110.0),
		Vector2(x + 70.0, 132.0), Vector2(x + 90.0, 154.0), Vector2(x, 154.0)]), Color("fff0b0"))
