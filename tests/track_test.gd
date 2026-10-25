extends SceneTree

var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _target_height(x: float, upper_route: bool) -> float:
	return preload("res://tests/valle_routes.gd").height(x, upper_route)


func _test_course(mode: int) -> void:
	Input.action_release("burner")
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	main.get_node("ItemCombat").enabled = false # Isolate pre-M5 regression.
	main.get_node("RaceFlow").enabled = false # Isolate flight/items from lifecycle.
	root.add_child(main)
	var balloon: Balloon = main.get_node("Balloon")
	var track: BalloonTrack = main.get_node("Track01")
	var visited: Array[int] = []
	var previous_progress: float = 0.0
	var elapsed: float = 0.0
	var s4_enter: float = -1.0
	var s4_exit: float = -1.0
	var crossed_divider: bool = false
	var s4_wind_frames: int = 0
	var previous_collisions: int = 0
	_check(track.get_progress(track.start.global_position.x - 500.0) == 0.0, "Progress clamps before start")
	_check(track.get_progress(track.finish.global_position.x + 500.0) == 1.0, "Progress clamps after finish")
	_check(track.start.global_position.x < track.fork.global_position.x and
		track.fork.global_position.x < track.merge.global_position.x and
		track.merge.global_position.x < track.finish.global_position.x, "Ordered reference markers")
	var estimate: float = (track.finish.global_position.x - track.start.global_position.x) / balloon.physics.horizontal_speed
	_check(estimate >= 75.0 and estimate <= 90.0, "Track duration estimate")
	for frame in Engine.physics_ticks_per_second * 100:
		var x: float = balloon.global_position.x
		var target_y: float = _target_height(x, mode == 0) if mode < 2 else 350.0
		if mode == 3 or (mode != 2 and balloon.position.y + balloon.velocity.y * 0.5 > target_y):
			Input.action_press("burner")
		else:
			Input.action_release("burner")
		await physics_frame
		await process_frame
		if mode < 2 and balloon.collision_count > previous_collisions:
			print("Controlled route contact: ", balloon.position, " obstacles=", balloon._ignored_obstacles)
		previous_collisions = balloon.collision_count
		elapsed = float(frame + 1) / Engine.physics_ticks_per_second
		if balloon.position.x >= track.fork.position.x and s4_enter < 0.0:
			s4_enter = elapsed
		if balloon.position.x >= track.zones.get_child(4).position.x and s4_exit < 0.0:
			s4_exit = elapsed
		var progress: float = track.get_progress(balloon.global_position.x)
		# Solid slopes can push a deliberately crashing balloon slightly backward.
		if mode < 2:
			_check(progress >= previous_progress, "Clean route progresses monotonically")
		previous_progress = progress
		_check(balloon.position.y >= 32.0 + Balloon.TOP_EXTENT - 0.001 and balloon.position.y <= 640.0 - Balloon.BOTTOM_EXTENT + 0.001, "Vertical limits")
		_check(absf(balloon.velocity.y) <= 250.01, "Vertical speed limit")
		var zone: int = track.get_zone_index(balloon.global_position.x)
		if zone not in visited:
			visited.append(zone)
		if balloon.position.x > 10600.0 and balloon.position.x < 12700.0 and mode < 2:
			if balloon.items.wind_multiplier() > 1.0:
				s4_wind_frames += 1
			_check(balloon.position.y + Balloon.BOTTOM_EXTENT < track.get_node("Obstacles/RouteDivider").upper_tip_y if mode == 0
				else balloon.position.y - Balloon.TOP_EXTENT > track.get_node("Obstacles/RouteDivider").lower_tip_y, "Chosen route stays on its side of divider")
		if balloon.get_collision_exceptions().has(track.get_node("Obstacles/RouteDivider")):
			crossed_divider = true
		if progress >= 1.0:
			break
	_check(previous_progress == 1.0, "Reached finish, mode %d" % mode)
	_check(visited == [0, 1, 2, 3, 4, 5], "Traversed all six zones in order")
	if mode < 2:
		_check(s4_wind_frames == 0 if mode == 0 else s4_wind_frames > 0,
			"S4 current rewards only the lower route")
		_check(balloon.collision_count == 0, "Route %d traversable without collisions" % mode)
		_check(elapsed >= 75.0 and elapsed <= estimate + 0.1, "Wind-assisted route remains within target duration")
	else:
		_check(balloon.collision_count > 0, "Crash flight still reaches finish")
	_check(not crossed_divider, "Horizontal divider never becomes passable")
	balloon.set_physics_process(false)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_F2
	key.pressed = true
	Input.parse_input_event(key)
	await process_frame
	await process_frame
	_check(main.get_node("HUD/TrackProgress").value == 100.0, "HUD reaches 100 percent")
	_check(main.get_node("HUD/DebugPanel").visible, "F2 remains functional")
	var debug: String = main.get_node("HUD/DebugPanel/Margin/DebugLabel").text
	_check(debug.contains("Progreso: 100.0%") and debug.contains("Zona: 6/6"), "Debug progress and final zone")
	_check(is_equal_approx(main.get_node("Camera2D").position.x, balloon.position.x + 280.0), "Camera reaches finish")
	print("Track mode %d: %.2f s, %d collisions, zones=%s" % [mode, elapsed, balloon.collision_count, visited])
	if mode < 2:
		print("Controlled S4 %s: %.3f s" % ["upper" if mode == 0 else "lower", s4_exit - s4_enter])
	Input.action_release("burner")
	main.queue_free()
	await process_frame
	await physics_frame


func _run() -> void:
	if not OS.get_cmdline_user_args().is_empty():
		Engine.physics_ticks_per_second = int(OS.get_cmdline_user_args()[0])
	for mode in 4:
		await _test_course(mode)
	print("TRACK TEST at %d Hz: %s (%d failures)" % [Engine.physics_ticks_per_second,
		"PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
