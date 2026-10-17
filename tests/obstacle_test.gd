extends SceneTree

var failures: int = 0
var main: Node2D
var balloon: Balloon


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _start_scene() -> void:
	Input.action_release("burner")
	main = load("res://scenes/Main.tscn").instantiate()
	main.get_node("Track01/Obstacles").free()
	var fixture: Node2D = load("res://tests/fixtures/M2Obstacles.tscn").instantiate()
	main.get_node("Track01").add_child(fixture)
	main.get_node("ItemCombat").enabled = false # Isolate pre-M5 regression.
	main.get_node("RaceFlow").enabled = false # Isolate flight/items from lifecycle.
	root.add_child(main)
	balloon = main.get_node("Balloon")


func _finish_scene() -> void:
	Input.action_release("burner")
	main.queue_free()
	await process_frame
	await physics_frame


func _step() -> void:
	await physics_frame
	await process_frame
	_check(balloon.position.y >= 32.0 + Balloon.TOP_EXTENT - 0.001 and balloon.position.y <= 640.0 - Balloon.BOTTOM_EXTENT + 0.001, "Vertical bounds remain intact")
	_check(absf(balloon.velocity.y) <= 250.01, "Vertical speed cap remains intact")


func _test_impact(kind: FlightObstacle.Kind) -> void:
	_start_scene()
	main.get_node("Track01/Obstacles").free()
	var obstacle: FlightObstacle = load("res://scenes/Obstacle.tscn").instantiate()
	obstacle.kind = kind
	obstacle.position.x = 850.0
	obstacle.width = 600.0
	main.add_child(obstacle)
	if kind != FlightObstacle.Kind.LOWER:
		Input.action_press("burner")
	var hit_frame: int = -1
	var hit_position: float = 0.0
	var previous_speed: float = 0.0
	var checked_recovery: bool = false
	var checked_protection: bool = false
	for frame in Engine.physics_ticks_per_second * 9:
		await _step()
		if balloon.collision_count == 0:
			continue
		if hit_frame == -1:
			hit_frame = frame
			hit_position = balloon.position.x
			_check(balloon.is_impact_penalized(), "Impact activates penalty")
			_check(balloon.velocity.x <= 220.0 * 0.6 + 0.01, "Impact applies speed multiplier")
			_check(balloon.velocity.x < 220.0 * 0.6 - 1.0, "Collision normal produces horizontal recoil")
			_check(balloon.protection_time_left > 0.0, "Impact activates protection")
			_check(balloon.get_collision_exceptions().has(obstacle), "Struck formation temporarily passable")
			previous_speed = balloon.velocity.x
		elif balloon.is_impact_penalized():
			_check(balloon.velocity.x < 220.0, "Base movement does not overwrite penalty")
			_check(balloon.velocity.x >= previous_speed - 0.01, "Speed recovers gradually")
			_check(balloon.impact_tint != Color.WHITE, "Impact has visual feedback")
			previous_speed = balloon.velocity.x
		var elapsed: float = float(frame - hit_frame) / Engine.physics_ticks_per_second
		if elapsed >= 0.4 and not checked_protection:
			checked_protection = true
			_check(balloon.position.x - hit_position < 220.0 * elapsed * 0.9, "Actual displacement is reduced")
			_check(balloon.collision_count == 1, "Cooldown prevents repeated impacts")
		if elapsed >= 0.9 and not checked_recovery:
			checked_recovery = true
			_check(not balloon.is_impact_penalized(), "Penalty expires")
			_check(is_equal_approx(balloon.velocity.x, 220.0), "Normal speed restored")
	_check(hit_frame >= 0 and checked_recovery and checked_protection, "Real collision detected for kind %d" % kind)
	_check(balloon.collision_count == 1, "Wide formation counts one hit even after cooldown")
	_check(balloon.position.x - Balloon.HALF_WIDTH > obstacle.get_right_edge(), "Balloon escapes wide formation")
	_check(balloon.get_collision_exceptions().is_empty(), "Collision exceptions cleaned after clearance")
	_check(balloon.impact_tint == Color.WHITE, "Normal appearance restored")
	print("Impact configuration %d completed" % kind)
	await _finish_scene()


func _test_course(mode: int) -> void:
	_start_scene()
	# Test-only input sequence; no automatic control is installed in the game.
	for frame in Engine.physics_ticks_per_second * 48:
		if mode == 0:
			var target_y: float = 280.0
			var x: float = balloon.position.x
			if x >= 2000.0 and x < 3350.0:
				target_y = 450.0
			elif x >= 3350.0 and x < 4500.0:
				target_y = 250.0
			elif x >= 4500.0 and x < 5650.0:
				target_y = 460.0
			elif x >= 5650.0:
				target_y = 350.0
			if balloon.position.y + balloon.velocity.y * 0.5 > target_y:
				Input.action_press("burner")
			else:
				Input.action_release("burner")
		elif mode == 1:
			Input.action_release("burner")
		else:
			Input.action_press("burner")
		await _step()
		if balloon.position.x >= 9040.0:
			break
	_check(balloon.position.x >= 9040.0, "Full course remains traversable, mode %d" % mode)
	if mode == 0:
		_check(balloon.collision_count == 0, "Course is traversable without collisions")
	else:
		_check(balloon.collision_count == 4, "Unattended flight hits four formations without becoming trapped")
	balloon.set_physics_process(false)
	await process_frame
	await process_frame
	_check(is_equal_approx(main.get_node("Camera2D").position.x, balloon.position.x + 280.0), "Camera follows through course")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_F2
	key.pressed = true
	Input.parse_input_event(key)
	await process_frame
	await process_frame
	var debug_label: Label = main.get_node("HUD/DebugPanel/Margin/DebugLabel")
	_check(main.get_node("HUD/DebugPanel").visible, "F2 works in obstacle course")
	_check(debug_label.text.contains("Colisiones: %d" % balloon.collision_count), "Existing HUD reports collisions")
	_check(debug_label.text.contains("Penalización: NO"), "HUD reports recovered penalty")
	print("Course mode %d: x=%.1f, collisions=%d" % [mode, balloon.position.x, balloon.collision_count])
	await _finish_scene()


func _run() -> void:
	if not OS.get_cmdline_user_args().is_empty():
		Engine.physics_ticks_per_second = int(OS.get_cmdline_user_args()[0])
	for kind in [FlightObstacle.Kind.LOWER, FlightObstacle.Kind.UPPER, FlightObstacle.Kind.GAP]:
		await _test_impact(kind)
	for mode in 3:
		await _test_course(mode)
	print("OBSTACLE TEST at %d Hz: %s (%d failures)" % [Engine.physics_ticks_per_second,
		"PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
