extends SceneTree

var failures: int = 0
var main: Node2D


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func step(frames: int = 1) -> void:
	for frame in frames:
		await physics_frame
		await process_frame


func send_key(code: Key, pressed: bool, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	event.echo = echo
	Input.parse_input_event(event)


func tap(code: Key) -> void:
	send_key(code, true)
	await step()
	send_key(code, false)
	await step()


func snapshot() -> Array:
	var values: Array = [main.race_flow.elapsed, main.race_flow.countdown_left, main.camera.position]
	for racer in main.competitors:
		values.append([racer.position, racer.velocity, racer.items.boost_left,
			racer.items.storm_warning_left, racer.items.storm_left, racer.items.turbo_wait_left,
			racer.impact_time_left, racer.items.protection_left])
		if racer.controller is BotController:
			values.append(racer.controller._reaction_left)
	for projectile in main.combat.get_children():
		values.append(projectile.position)
		if projectile is ItemProjectile:
			values.append(projectile.age)
	values.append(main.track.get_node("ItemBoxes/Box0")._respawn_left)
	return values


func _run() -> void:
	var bindings: Dictionary = {"burner": KEY_UP, "use_item": KEY_A, "use_turbo": KEY_D, "pause": KEY_SPACE, "toggle_debug": KEY_F2}
	for action in bindings:
		var events: Array[InputEvent] = InputMap.action_get_events(action)
		check(events.size() == 1 and events[0].physical_keycode == bindings[action], "Only intended binding for " + action)
	main = load("res://scenes/Main.tscn").instantiate()
	main.race_seed = 1
	root.add_child(main)
	current_scene = main
	await step()
	await tap(KEY_SPACE)
	check(paused and main.get_node("HUD/RaceOverlay/PausePanel").visible, "SPACE pauses countdown and shows panel")
	var frozen: Array = snapshot()
	await step(30)
	check(snapshot() == frozen, "Countdown and bodies stay frozen")
	send_key(KEY_SPACE, true, true)
	await step()
	check(paused, "Key repeat cannot unpause")
	# SPACE must resume, not click the focused Restart button through ui_accept.
	main.get_node("HUD/RaceOverlay/PausePanel/Rows/Restart").grab_focus()
	var identity: int = main.get_instance_id()
	await tap(KEY_SPACE)
	check(not paused and current_scene.get_instance_id() == identity, "SPACE resumes despite Restart focus")
	while main.race_flow.state == RaceFlow.State.COUNTDOWN:
		await step()
	main.combat.set_physics_process(false)
	main.balloon.position = Vector2(600, 350)
	send_key(KEY_UP, true)
	await step(2)
	check(main.balloon.burner_active, "UP activates burner")
	send_key(KEY_UP, false)
	await step(2)
	check(not main.balloon.burner_active, "Releasing UP stops burner")
	main.balloon.items.turbo_wait_left = 0.0
	main.balloon.items.collect(BalloonItems.Kind.ROCKET)
	await tap(KEY_D)
	check(main.balloon.items.turbo_charges == 1 and main.balloon.items.boost_left > 0.0, "D consumes exactly one personal charge")
	await tap(KEY_A)
	check(main.balloon.items.used == 1 and main.balloon.items.equipped == BalloonItems.Kind.NONE, "A launches equipped rocket")
	check(main.combat.get_child_count() == 1, "Actual projectile exists")
	main.competitors[3].items.collect(BalloonItems.Kind.STORM)
	main.competitors[3].items.use_item()
	var box: Area2D = main.track.get_node("ItemBoxes/Box0")
	box.consumed = true
	box._respawn_left = 3.0
	box.hide()
	await step()
	await tap(KEY_SPACE)
	check(paused and not main.balloon.burner_active and not Input.is_action_pressed("burner"), "SPACE pauses without activating burner")
	frozen = snapshot()
	await step(90)
	check(snapshot() == frozen, "Bots, projectiles, storm, boosts, box timer and race clock freeze")
	await tap(KEY_A)
	await tap(KEY_D)
	check(snapshot() == frozen and main.balloon.items.turbo_charges == 1, "Gameplay input cannot consume objects/charges during pause")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/pause-preview.png")
	main.get_node("HUD/RaceOverlay/PausePanel/Rows/Continue").pressed.emit()
	await step(2)
	check(not paused and snapshot() != frozen, "Continue button resumes simulation")
	await tap(KEY_SPACE)
	await tap(KEY_ENTER)
	check(not paused, "Enter activates focused Continue button")
	await tap(KEY_SPACE)
	main.get_node("HUD/RaceOverlay/PausePanel/Rows/Restart").pressed.emit()
	await step(3)
	main = current_scene
	check(not paused and main.get_instance_id() != identity, "Restart unpauses and reloads scene")
	check(main.race_flow.state == RaceFlow.State.COUNTDOWN and main.race_flow.elapsed == 0.0, "Restart restores countdown and clock")
	for racer in main.competitors:
		check(racer.items.turbo_charges == 2 and racer.items.boost_left == 0.0 and racer.items.storm_warning_left == 0.0, "Restart clears effects and restores charges")
	check(main.combat.get_child_count() == 0 and not main.track.get_node("ItemBoxes/Box0").consumed, "Restart restores projectiles and boxes")
	# A short real finish exercises podium with the pause UI present.
	main.track.finish.position.x = 260.0
	for frame in 240:
		await step()
		if main.race_flow.state == RaceFlow.State.RESULTS:
			break
	await step(2)
	check(main.race_flow.records.size() == 4 and main.get_node("HUD/RaceOverlay/Results").visible, "Race can finish and display podium")
	identity = main.get_instance_id()
	await tap(KEY_SPACE)
	check(not paused and current_scene.get_instance_id() == identity and not main.get_node("HUD/RaceOverlay/PausePanel").visible, "Results ignore pause without accidental restart")
	print("PAUSE TEST: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
