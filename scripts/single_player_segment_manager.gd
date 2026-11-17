class_name SinglePlayerSegmentManager
extends Node2D

signal coin_collected(coin: SinglePlayerCoin)
signal star_collected(star: MagicStar)

const OBSTACLE := preload("res://scenes/Obstacle.tscn")
const TRACK := preload("res://scenes/Track01.tscn")
const TERRAIN_KIT := preload("res://scripts/terrain_kit_visual.gd")
const FLAPPY := preload("res://scenes/FlyingCreatureObstacle.tscn")
const WIND := preload("res://scenes/WindZone.tscn")
const COIN := preload("res://scenes/Coin.tscn")
const STAR := preload("res://scenes/MagicStar.tscn")

const PATTERNS: Array[StringName] = [
	&"progressive_ascent", &"anticipated_descent", &"high_low_alternation",
	&"narrow_passage", &"dual_route_island", &"wind_shift",
	&"flappy_encounter", &"recovery"]
const TRACK_OBSTACLES: Array[StringName] = [
	&"GentleMountain", &"RisingMountain", &"AlternatingLower",
	&"AlternatingLowerB", &"IntroUpper", &"DeepHangingRock",
	&"FirstCorridor", &"AlternatingUpperA", &"EntryFunnel",
	&"RouteDivider", &"TechnicalIslandS3", &"PrecisionB", &"PrecisionC"]

var config: SinglePlayerConfig
var rng := RandomNumberGenerator.new()
var seed_value: int = 0
var generation_enabled: bool = true
var active_segments: Dictionary = {}
var generated_signatures: Array[String] = []
var generated_patterns: Array[StringName] = []
var generated_star_indices: Array[int] = []
var _templates: Dictionary = {}
var _terrain_kit = TERRAIN_KIT.new()
var _next_index: int = 0
var _last_pattern: StringName = &""
var _safe_y: float = 350.0
var _last_star_index: int = -100


func setup(new_config: SinglePlayerConfig, seed: int) -> void:
	clear()
	config = new_config
	seed_value = seed if seed != 0 else new_config.default_seed
	rng.seed = seed_value
	generation_enabled = true
	_next_index = 0
	_last_pattern = &""
	_safe_y = 350.0
	_last_star_index = -100
	if _templates.is_empty():
		_load_track_templates()
	ensure_segments(0.0)


func ensure_segments(player_x: float) -> void:
	if not generation_enabled or config == null:
		return
	var current_index := maxi(0, floori(player_x / config.segment_length))
	while _next_index <= current_index + config.segments_ahead:
		_generate_segment(_next_index)
		_next_index += 1
	var minimum_index := current_index - config.segments_behind
	for index in active_segments.keys():
		if int(index) < minimum_index:
			var segment: Node2D = active_segments[index]
			active_segments.erase(index)
			segment.queue_free()


func clear() -> void:
	for segment in active_segments.values():
		if is_instance_valid(segment):
			segment.queue_free()
	active_segments.clear()
	generated_signatures.clear()
	generated_patterns.clear()
	generated_star_indices.clear()
	_next_index = 0


func active_collectible_count() -> int:
	var count := 0
	for segment: Node2D in active_segments.values():
		count += segment.find_children("*", "Area2D", true, false).size()
	return count


func build_pattern_for_test(pattern: StringName, difficulty: float, start_y: float) -> Node2D:
	if _templates.is_empty():
		_load_track_templates()
	var segment := _new_segment(-1, 0.0)
	_build_pattern(segment, pattern, clampf(difficulty, 0.0, 1.0), start_y, 99)
	_dress_obstacles(segment)
	return segment


func _generate_segment(index: int) -> void:
	var world_x := index * config.segment_length
	var difficulty := config.difficulty(world_x)
	var pattern := _choose_pattern(index, config.difficulty_tier(world_x))
	var segment := _new_segment(index, world_x)
	active_segments[index] = segment
	var result := _build_pattern(segment, pattern, difficulty, _safe_y, index)
	_safe_y = float(result.end_y)
	if not segment.find_children("*", "MagicStar", true, false).is_empty():
		generated_star_indices.append(index)
		if generated_star_indices.size() > 64:
			generated_star_indices.pop_front()
	_dress_obstacles(segment)
	var signature := "%d:%s:%d:%d" % [index, pattern, roundi(_safe_y), roundi(difficulty * 100.0)]
	segment.set_meta("signature", signature)
	generated_signatures.append(signature)
	generated_patterns.append(pattern)
	if generated_signatures.size() > 64:
		generated_signatures.pop_front()
		generated_patterns.pop_front()


func _new_segment(index: int, world_x: float) -> Node2D:
	var segment := Node2D.new()
	segment.name = "Segment%04d" % index if index >= 0 else "PatternPreview"
	segment.position.x = world_x
	segment.set_meta("segment_index", index)
	var art := Node2D.new()
	art.name = "TerrainArt"
	art.z_index = -2
	segment.add_child(art)
	var obstacles := Node2D.new()
	obstacles.name = "Obstacles"
	segment.add_child(obstacles)
	var gameplay := Node2D.new()
	gameplay.name = "Gameplay"
	segment.add_child(gameplay)
	add_child(segment)
	return segment


func _choose_pattern(index: int, tier: int) -> StringName:
	if index == 0:
		_last_pattern = &"progressive_ascent"
		return &"progressive_ascent"
	if config.relief_interval_segments > 0 and index % config.relief_interval_segments == 0:
		_last_pattern = &"recovery"
		return &"recovery"
	var allowed: Array[StringName]
	if tier == 0:
		allowed = [&"progressive_ascent", &"anticipated_descent", &"narrow_passage"]
	elif tier == 1:
		allowed = [&"progressive_ascent", &"anticipated_descent", &"high_low_alternation", &"narrow_passage", &"dual_route_island", &"wind_shift", &"flappy_encounter"]
	else:
		allowed = [&"progressive_ascent", &"anticipated_descent", &"high_low_alternation", &"narrow_passage", &"dual_route_island", &"wind_shift", &"flappy_encounter"]
	var pattern := allowed[rng.randi_range(0, allowed.size() - 1)]
	if pattern == _last_pattern and allowed.size() > 1:
		pattern = allowed[(allowed.find(pattern) + 1 + rng.randi_range(0, allowed.size() - 2)) % allowed.size()]
	_last_pattern = pattern
	return pattern


func _build_pattern(segment: Node2D, pattern: StringName, difficulty: float, start_y: float, index: int) -> Dictionary:
	var result: Dictionary
	match pattern:
		&"progressive_ascent": result = _pattern_progressive_ascent(segment, difficulty, start_y)
		&"anticipated_descent": result = _pattern_anticipated_descent(segment, difficulty, start_y)
		&"high_low_alternation": result = _pattern_high_low_alternation(segment, difficulty, start_y)
		&"narrow_passage": result = _pattern_narrow_passage(segment, difficulty, start_y, index)
		&"dual_route_island": result = _pattern_dual_route_island(segment, difficulty, start_y, index)
		&"wind_shift": result = _pattern_wind_shift(segment, difficulty, start_y, index)
		&"flappy_encounter": result = _pattern_flappy_encounter(segment, difficulty, start_y, index)
		_: result = _pattern_recovery(segment, difficulty, start_y, index)
	var route: PackedVector2Array = result.route
	segment.set_meta("pattern", pattern)
	segment.set_meta("difficulty", difficulty)
	segment.set_meta("safe_start_y", start_y)
	segment.set_meta("safe_end_y", result.end_y)
	segment.set_meta("safe_route", route)
	segment.set_meta("minimum_gap", result.get("minimum_gap", config.beginner_gap))
	return result


func _pattern_progressive_ascent(segment: Node2D, difficulty: float, start_y: float) -> Dictionary:
	var end_y := clampf(start_y - lerpf(145.0, 210.0, difficulty), 165.0, 360.0)
	var entry_x := config.minimum_reaction_distance + 60.0
	var route := PackedVector2Array([Vector2(0, start_y), Vector2(entry_x, lerpf(start_y, end_y, 0.35)), Vector2(1250, lerpf(start_y, end_y, 0.72)), Vector2(1780, end_y), Vector2(config.segment_length, end_y)])
	for entry in [[&"GentleMountain", entry_x, route[1].y], [&"RisingMountain", 1250.0, route[2].y], [&"AlternatingLowerB", 1780.0, end_y]]:
		_add_forcing_obstacle(segment, entry[0], entry[1], entry[2], true, 24.0)
	_add_coin_line(segment, Vector2(380, lerpf(start_y, end_y, 0.12)), Vector2(1740, end_y - 4.0), 6)
	return {"end_y": end_y, "route": route, "minimum_gap": 225.0}


func _pattern_anticipated_descent(segment: Node2D, difficulty: float, start_y: float) -> Dictionary:
	var end_y := clampf(start_y + lerpf(150.0, 220.0, difficulty), 340.0, 525.0)
	var entry_x := config.minimum_reaction_distance + 60.0
	var route := PackedVector2Array([Vector2(0, start_y), Vector2(entry_x, lerpf(start_y, end_y, 0.32)), Vector2(1250, lerpf(start_y, end_y, 0.68)), Vector2(1780, end_y), Vector2(config.segment_length, end_y)])
	for entry in [[&"IntroUpper", entry_x, route[1].y], [&"DeepHangingRock", 1250.0, route[2].y], [&"FirstCorridor", 1780.0, end_y]]:
		_add_forcing_obstacle(segment, entry[0], entry[1], entry[2], false, 24.0)
	_add_coin_line(segment, Vector2(400, lerpf(start_y, end_y, 0.12)), Vector2(1740, end_y + 5.0), 6)
	return {"end_y": end_y, "route": route, "minimum_gap": 225.0}


func _pattern_high_low_alternation(segment: Node2D, difficulty: float, start_y: float) -> Dictionary:
	var high := lerpf(235.0, 205.0, difficulty)
	var low := lerpf(455.0, 490.0, difficulty)
	var end_y := 285.0
	var entry_x := config.minimum_reaction_distance + 60.0
	var route := PackedVector2Array([Vector2(0, start_y), Vector2(500, high), Vector2(900, high), Vector2(1260, low), Vector2(1600, low), Vector2(1920, end_y), Vector2(2220, end_y), Vector2(config.segment_length, end_y)])
	_add_forcing_obstacle(segment, &"AlternatingLower", entry_x, high, true, 22.0)
	_add_forcing_obstacle(segment, &"AlternatingUpperA", 1450.0, low, false, 22.0)
	_add_forcing_obstacle(segment, &"AlternatingLowerB", 2100.0, end_y, true, 22.0)
	_add_coin_arc(segment, Vector2(500, high), Vector2(900, high), -38.0, 4)
	_add_coin_arc(segment, Vector2(1260, low), Vector2(1600, low), 36.0, 4)
	_add_coin_line(segment, Vector2(1920, end_y), Vector2(2200, end_y), 3)
	return {"end_y": end_y, "route": route, "minimum_gap": 205.0}


func _pattern_narrow_passage(segment: Node2D, difficulty: float, start_y: float, index: int) -> Dictionary:
	var center := clampf(start_y + rng.randf_range(-70.0, 70.0), 255.0, 455.0)
	var gap := lerpf(config.beginner_gap, config.advanced_gap, difficulty)
	var end_y := clampf(center + rng.randf_range(-65.0, 65.0), 220.0, 485.0)
	var route := PackedVector2Array([Vector2(0, start_y), Vector2(650, center), Vector2(980, center), Vector2(1450, end_y), Vector2(config.segment_length, end_y)])
	_add_obstacle(segment, &"EntryFunnel", 820.0, {"kind": FlightObstacle.Kind.GAP, "upper_tip_y": center - gap * 0.5, "lower_tip_y": center + gap * 0.5, "width": 420.0})
	if difficulty > 0.55:
		_add_forcing_obstacle(segment, &"PrecisionC", 1450.0, end_y, end_y < center, 24.0)
	_add_coin_line(segment, Vector2(610, center), Vector2(1030, center), 4)
	_maybe_add_star(segment, index, Vector2(850, center + (gap * 0.14 if center < 350.0 else -gap * 0.14)), difficulty)
	return {"end_y": end_y, "route": route, "minimum_gap": gap}


func _pattern_dual_route_island(segment: Node2D, difficulty: float, start_y: float, index: int) -> Dictionary:
	var upper_route := lerpf(165.0, 145.0, difficulty)
	var lower_route := lerpf(525.0, 545.0, difficulty)
	var safe_upper := start_y < 350.0
	var safe_y := upper_route if safe_upper else lower_route
	var risk_y := lower_route if safe_upper else upper_route
	var end_y := 350.0
	var route := PackedVector2Array([Vector2(0, start_y), Vector2(500, safe_y), Vector2(1780, safe_y), Vector2(2200, end_y), Vector2(config.segment_length, end_y)])
	var source: StringName = &"TechnicalIslandS3" if index % 2 == 0 else &"PrecisionB"
	_add_obstacle(segment, source, 1120.0, {"outline_scale_x": 0.66})
	_add_coin_line(segment, Vector2(500, safe_y), Vector2(1680, safe_y), 5)
	_add_coin_arc(segment, Vector2(480, risk_y), Vector2(1720, risk_y), -30.0 if risk_y < 350.0 else 30.0, 8)
	_maybe_add_star(segment, index, Vector2(1120, risk_y), difficulty, 0.15)
	return {"end_y": end_y, "route": route, "minimum_gap": 205.0}


func _pattern_wind_shift(segment: Node2D, difficulty: float, start_y: float, index: int) -> Dictionary:
	var first_y := 220.0 if start_y >= 350.0 else 470.0
	var second_y := 465.0 if first_y < 350.0 else 225.0
	var end_y := second_y
	var route := PackedVector2Array([Vector2(0, start_y), Vector2(350, first_y), Vector2(930, first_y), Vector2(1550, second_y), Vector2(1970, second_y), Vector2(config.segment_length, end_y)])
	_add_forcing_obstacle(segment, &"AlternatingLower", config.minimum_reaction_distance + 60.0, first_y, first_y < 350.0, 26.0)
	_add_wind(segment, 760.0, first_y, lerpf(1.17, 1.22, difficulty))
	_add_forcing_obstacle(segment, &"AlternatingUpperA", 1760.0, second_y, second_y < 350.0, 24.0)
	_add_wind(segment, 2080.0, second_y, lerpf(1.17, 1.22, difficulty))
	_add_coin_line(segment, Vector2(560, first_y), Vector2(900, first_y), 3)
	_add_coin_line(segment, Vector2(1580, second_y), Vector2(2130, second_y), 4)
	_maybe_add_star(segment, index, Vector2(1260, lerpf(first_y, second_y, 0.5)), difficulty, 0.1)
	return {"end_y": end_y, "route": route, "minimum_gap": 205.0}


func _pattern_flappy_encounter(segment: Node2D, difficulty: float, start_y: float, index: int) -> Dictionary:
	var safe_y := 215.0 if start_y < 360.0 else 485.0
	var flappy_y := 455.0 if safe_y < 350.0 else 185.0
	var end_y := lerpf(safe_y, 350.0, 0.55)
	var route := PackedVector2Array([Vector2(0, start_y), Vector2(390, safe_y), Vector2(1480, safe_y), Vector2(2080, end_y), Vector2(config.segment_length, end_y)])
	_add_forcing_obstacle(segment, &"AlternatingLower", config.minimum_reaction_distance + 60.0, safe_y, safe_y < 350.0, 24.0)
	_add_flappy(segment, 1080.0, flappy_y, index, difficulty)
	_add_coin_arc(segment, Vector2(700, safe_y), Vector2(1420, safe_y), -42.0 if safe_y < 350.0 else 42.0, 5)
	_maybe_add_star(segment, index, Vector2(1080, safe_y + (-55.0 if safe_y < 350.0 else 55.0)), difficulty, 0.12)
	return {"end_y": end_y, "route": route, "minimum_gap": 205.0}


func _pattern_recovery(segment: Node2D, _difficulty: float, start_y: float, index: int) -> Dictionary:
	var end_y := lerpf(start_y, 350.0, 0.7)
	var route := PackedVector2Array([Vector2(0, start_y), Vector2(900, end_y), Vector2(config.segment_length, end_y)])
	if index % 2 != 0:
		_add_coin_arc(segment, Vector2(700, end_y), Vector2(1450, end_y), -35.0, 4)
	return {"end_y": end_y, "route": route, "minimum_gap": 300.0}


func _load_track_templates() -> void:
	var track: Node = TRACK.instantiate()
	var obstacles: Node = track.get_node("Obstacles")
	for obstacle_name in TRACK_OBSTACLES:
		var source := obstacles.get_node(str(obstacle_name)) as FlightObstacle
		_templates[obstacle_name] = {"kind": source.kind, "width": source.width,
			"ceiling_y": source.ceiling_y, "ground_y": source.ground_y,
			"upper_tip_y": source.upper_tip_y, "lower_tip_y": source.lower_tip_y,
			"outline": source.outline.duplicate()}
	track.free()


func _add_obstacle(segment: Node2D, source_name: StringName, x: float, overrides: Dictionary = {}) -> FlightObstacle:
	var template: Dictionary = _templates[source_name]
	var obstacle := OBSTACLE.instantiate() as FlightObstacle
	obstacle.name = str(source_name)
	obstacle.position.x = x
	obstacle.kind = overrides.get("kind", template.kind)
	obstacle.width = overrides.get("width", template.width)
	obstacle.ceiling_y = template.ceiling_y
	obstacle.ground_y = template.ground_y
	obstacle.upper_tip_y = overrides.get("upper_tip_y", template.upper_tip_y)
	obstacle.lower_tip_y = overrides.get("lower_tip_y", template.lower_tip_y)
	var outline: PackedVector2Array = template.outline.duplicate()
	if not outline.is_empty() and overrides.has("outline_scale_x"):
		var scale_x := float(overrides.outline_scale_x)
		for point_index in outline.size():
			outline[point_index].x *= scale_x
		obstacle.width *= scale_x
	obstacle.outline = outline
	obstacle.set_meta("track_source", source_name)
	segment.get_node("Obstacles").add_child(obstacle)
	return obstacle


func _add_forcing_obstacle(segment: Node2D, source_name: StringName, x: float, route_y: float, pass_above: bool, margin: float) -> void:
	if pass_above:
		_add_obstacle(segment, source_name, x, {"kind": FlightObstacle.Kind.LOWER, "lower_tip_y": route_y + Balloon.BOTTOM_EXTENT + margin})
	else:
		_add_obstacle(segment, source_name, x, {"kind": FlightObstacle.Kind.UPPER, "upper_tip_y": route_y - Balloon.TOP_EXTENT - margin})


func _dress_obstacles(segment: Node2D) -> void:
	var art: Node2D = segment.get_node("TerrainArt")
	for obstacle: FlightObstacle in segment.get_node("Obstacles").get_children():
		for node_name in [&"LowerVisual", &"UpperVisual"]:
			var polygon := obstacle.get_node(str(node_name)) as Polygon2D
			if polygon.visible and polygon.polygon.size() >= 3:
				_terrain_kit.formation(art, obstacle, polygon, node_name == &"UpperVisual")


func _add_wind(segment: Node2D, x: float, y: float, multiplier: float) -> void:
	var wind := WIND.instantiate() as Area2D
	wind.name = "WindCurrent"
	wind.position = Vector2(x, y)
	wind.size = Vector2(300.0, 72.0)
	wind.speed_multiplier = multiplier
	segment.get_node("Gameplay").add_child(wind)


func _add_flappy(segment: Node2D, x: float, y: float, index: int, difficulty: float) -> void:
	var flappy := FLAPPY.instantiate() as FlyingCreatureObstacle
	flappy.name = "Flappy"
	flappy.position = Vector2(x, y)
	flappy.amplitude = lerpf(44.0, 70.0, difficulty)
	flappy.period = lerpf(3.25, 2.65, difficulty)
	flappy.initial_phase_degrees = float((index * 73) % 360)
	segment.get_node("Gameplay").add_child(flappy)


func _add_coin_line(segment: Node2D, from: Vector2, to: Vector2, count: int) -> void:
	for coin_index in count:
		var progress := float(coin_index) / maxf(count - 1, 1)
		_add_coin(segment, from.lerp(to, progress))


func _add_coin_arc(segment: Node2D, from: Vector2, to: Vector2, arc_height: float, count: int) -> void:
	for coin_index in count:
		var progress := float(coin_index) / maxf(count - 1, 1)
		var position := from.lerp(to, progress)
		position.y += sin(progress * PI) * arc_height
		_add_coin(segment, position)


func _add_coin(segment: Node2D, position: Vector2) -> void:
	var coin := COIN.instantiate() as SinglePlayerCoin
	coin.position = position
	coin.collected.connect(_on_coin_collected)
	segment.get_node("Gameplay").add_child(coin)


func _maybe_add_star(segment: Node2D, index: int, position: Vector2, difficulty: float, bonus: float = 0.0) -> bool:
	if index - _last_star_index < config.star_minimum_segments:
		return false
	if rng.randf() > clampf(config.star_spawn_chance + difficulty * 0.1 + bonus, 0.0, 1.0):
		return false
	var star := STAR.instantiate() as MagicStar
	star.position = position
	star.collected.connect(_on_star_collected)
	segment.get_node("Gameplay").add_child(star)
	_last_star_index = index
	return true


func route_height(route: PackedVector2Array, x: float) -> float:
	if route.is_empty():
		return 350.0
	if x <= route[0].x:
		return route[0].y
	for point_index in range(1, route.size()):
		if x <= route[point_index].x:
			var previous := route[point_index - 1]
			var current := route[point_index]
			return lerpf(previous.y, current.y, inverse_lerp(previous.x, current.x, x))
	return route[-1].y


func _on_coin_collected(coin: SinglePlayerCoin) -> void:
	coin_collected.emit(coin)


func _on_star_collected(star: MagicStar) -> void:
	star_collected.emit(star)
