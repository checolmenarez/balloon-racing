extends SceneTree
## Controlled S3 traversal: identical inputs with/without the new current,
## plus a lower lane that bypasses it. No production controller is changed.

var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func traverse(current_enabled: bool, target_y: float, from_corridor: bool = false) -> float:
	Input.action_release("burner")
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	main.get_node("RaceFlow").enabled = false
	main.get_node("ItemCombat").enabled = false
	main.get_node("Track01/WindZones/RecoveryCurrent").enabled = current_enabled
	root.add_child(main)
	for rival in main.competitors:
		rival.set_physics_process(false)
	var racer: Balloon = main.balloon
	racer.position = Vector2(8500, 400) if from_corridor else Vector2(8860, target_y)
	racer.velocity = Vector2.ZERO
	await physics_frame
	await process_frame
	racer.set_physics_process(true)
	var elapsed: float = 0.0
	var saw_wind: bool = false
	var peak_speed: float = 0.0
	for frame in 60 * 8:
		var desired: float = 400.0 if from_corridor and racer.position.x < 8680.0 else target_y
		if racer.position.y + racer.velocity.y * 0.35 > desired:
			Input.action_press("burner")
		else:
			Input.action_release("burner")
		await physics_frame
		await process_frame
		elapsed = float(frame + 1) / 60.0
		saw_wind = saw_wind or racer.items.wind_multiplier() > 1.0
		peak_speed = maxf(peak_speed, racer.velocity.x)
		check(racer.items.boost_left == 0.0, "S3 measurement must not use turbo")
		if racer.position.x >= 9400.0:
			check(is_equal_approx(racer.velocity.x, 220.0), "Base speed restored before Fork")
		if racer.position.x >= main.track.fork.position.x:
			break
	check(racer.position.x >= main.track.fork.position.x, "Reached Fork")
	check(racer.collision_count == 0, "S3 traversal has no impacts")
	check(saw_wind == (current_enabled and target_y < 400.0), "Current is optional by altitude")
	check(is_equal_approx(peak_speed, 264.0 if saw_wind else 220.0), "Actual wind speed without turbo")
	check(main.track.get_node("Obstacles").get_child_count() == 17, "No added obstacles")
	check(main.track.get_node("ItemBoxes").get_child_count() == 32, "No added boxes")
	var last: FlightObstacle = main.track.get_node("Obstacles/FinalLower")
	var finish_x: float = main.track.finish.position.x
	check(finish_x == 18400.0 and finish_x - last.get_right_edge() >= 650.0, "Longer sprint, unchanged finish")
	for box_name in ["Box19", "Box20"]:
		var box: Node2D = main.track.get_node("ItemBoxes/" + box_name)
		var seconds: float = (finish_x - box.position.x) / 297.0
		check(seconds > 2.0, "Final pickup leaves time even at maximum turbo speed")
	print("S3 current=%s target_y=%.0f from_corridor=%s: %.3f s, peak %.0f px/s, impacts=%d" %
		[current_enabled, target_y, from_corridor, elapsed, peak_speed, racer.collision_count])
	Input.action_release("burner")
	main.queue_free()
	await process_frame
	await physics_frame
	return elapsed


func _run() -> void:
	var baseline: float = await traverse(false, 335.0)
	var assisted: float = await traverse(true, 335.0)
	var bypass: float = await traverse(true, 520.0)
	check(baseline - assisted > 0.25, "New current saves measurable time with identical inputs")
	check(absf(bypass - baseline) <= 1.0 / 60.0, "Lower lane remains unassisted")
	await traverse(true, 520.0, true)
	print("S3 saving without turbo: %.3f s" % (baseline - assisted))
	print("VALLE INCREMENTAL TEST: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
