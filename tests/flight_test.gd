extends SceneTree

var failures: int = 0
var balloon: Balloon


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _step(count: int) -> void:
	for frame in ceili(count * Engine.physics_ticks_per_second / 60.0):
		await physics_frame
		await process_frame
		_check(balloon.position.y >= 32.0 + Balloon.TOP_EXTENT - 0.001 and balloon.position.y <= 640.0 - Balloon.BOTTOM_EXTENT + 0.001, "Vertical bounds")
		_check(absf(balloon.velocity.y) <= 250.01, "Vertical speed cap")
		_check(is_equal_approx(balloon.velocity.x, 220.0), "Automatic forward speed")


func _run() -> void:
	if not OS.get_cmdline_user_args().is_empty():
		Engine.physics_ticks_per_second = int(OS.get_cmdline_user_args()[0])
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	# Isolate the M1 regression from the M2 obstacle course.
	main.get_node("Track01/Obstacles").free()
	main.get_node("ItemCombat").enabled = false # Isolate pre-M5 regression.
	main.get_node("RaceFlow").enabled = false # Isolate flight/items from lifecycle.
	root.add_child(main)
	balloon = main.get_node("Balloon")
	await _step(20)
	_check(balloon.velocity.y > 0.0, "Gravity pulls down")
	Input.action_press("burner")
	await _step(1)
	_check(balloon.burner_active and balloon.velocity.y > 0.0, "Burner preserves downward inertia")
	await _step(40)
	_check(balloon.velocity.y < 0.0, "Burner reverses descent gradually")
	Input.action_release("burner")
	await _step(1)
	_check(not balloon.burner_active and balloon.velocity.y < 0.0, "Release preserves upward inertia")
	await _step(300)
	_check(is_equal_approx(balloon.position.y, 640.0 - Balloon.BOTTOM_EXTENT), "Basket stops at ground")
	Input.action_press("burner")
	await _step(300)
	_check(is_equal_approx(balloon.position.y, 32.0 + Balloon.TOP_EXTENT), "Envelope stops at ceiling")
	_check(is_zero_approx(balloon.velocity.y), "No outward speed at ceiling")
	Input.action_release("burner")
	await _step(300)
	_check(is_equal_approx(balloon.position.y, 640.0 - Balloon.BOTTOM_EXTENT), "Can descend after ceiling contact")
	_check(balloon.position.x > 3000.0, "Continuous horizontal travel")
	balloon.set_physics_process(false)
	await process_frame
	await process_frame
	_check(is_equal_approx(main.get_node("Camera2D").position.x, balloon.position.x + 280.0), "Camera follows horizontal position")
	var panel: PanelContainer = main.get_node("HUD/DebugPanel")
	_check(not panel.visible, "Debug initially hidden")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_F2
	key.pressed = true
	_check(key.is_action_pressed("toggle_debug"), "F2 mapping")
	Input.parse_input_event(key)
	await process_frame
	_check(panel.visible, "F2 opens debug")
	key = key.duplicate()
	key.echo = true
	Input.parse_input_event(key)
	await process_frame
	_check(panel.visible, "Key repeat does not toggle debug")
	key = key.duplicate()
	key.echo = false
	Input.parse_input_event(key)
	await process_frame
	_check(not panel.visible, "F2 closes debug")
	print("FLIGHT TEST at %d Hz: %s (%d failures)" % [Engine.physics_ticks_per_second, "PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
