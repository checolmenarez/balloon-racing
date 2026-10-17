extends SceneTree

var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func step() -> void:
	await physics_frame
	await process_frame


func _run() -> void:
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	var flow: RaceFlow = main.race_flow
	var origins: Array[Vector2] = []
	for racer in main.competitors:
		origins.append(racer.position)
	Input.action_press("burner")
	main.balloon.items.equipped = BalloonItems.Kind.BOOST
	check(not main.balloon.items.use_item(), "Countdown prevents item use")
	for frame in 175:
		await step()
		for index in 4:
			check(main.competitors[index].position == origins[index], "Countdown freezes every body")
		check(flow.elapsed == 0.0, "Clock starts at GO")
		check(main.camera.position.x == 520.0, "Countdown camera stable")
	while flow.state == RaceFlow.State.COUNTDOWN:
		await step()
	check(flow.elapsed == 0.0, "GO begins without artificial elapsed time")
	await step()
	for racer in main.competitors:
		check(racer.position.x > 240.0, "All racers start in the same physics tick")
	check(main.balloon.burner_active, "UP still controls the human")
	Input.action_release("burner")
	# Same-tick crossings in reverse registration order; interpolate real segment.
	flow.set_physics_process(false)
	main.track.finish.position.x = 200.0
	for index in 4:
		var racer: Balloon = main.competitors[index]
		racer.set_physics_process(false)
		flow._previous_x[racer] = 100.0
		racer.position.x = 210.0 + index * 10.0
		racer.collision_count = index
	flow._physics_process(1.0 / 60.0)
	check(flow.state == RaceFlow.State.RESULTS, "All finishes open results")
	check(flow.records.size() == 4, "Exactly one record per racer")
	for index in 4:
		check(flow.records[index].racer == main.competitors[3 - index], "Order uses crossing time, not body order")
		check(flow.records[index].collisions == 3 - index, "Statistics captured at finish")
		check(not main.competitors[index].racing, "Finishers no longer compete")
	check(not main.balloon.items.use_item() and not main.balloon.items.receive_hit(main.competitors[1], Vector2.ZERO), "Finishers cannot use objects or be attacked")
	await step()
	check(main.get_node("HUD/RaceOverlay/Results").visible, "Results visible")
	check(main.get_node("HUD/RaceOverlay/Results/Rows/Podium").get_child_count() == 4, "Four podium places")
	check(main.get_node("HUD/RaceOverlay/Results/Rows/Classification").text.contains("4.º  " + main.balloon.competitor_name + " · TÚ"), "Fourth-place human included")
	main.get_node("HUD/RaceOverlay/Results/Rows/Restart").pressed.emit()
	await step()
	await step()
	main = current_scene
	check(main.race_flow.state == RaceFlow.State.COUNTDOWN and main.balloon.items.used == 0, "Button reloads a clean race")
	for racer in main.competitors:
		check(racer.items.turbo_charges == 2 and racer.items.storm_left == 0.0 and racer.items.storm_warning_left == 0.0 and racer.items.wind_zones.is_empty(), "Restart resets charges, storm and wind state")
	for box in main.track.get_node("ItemBoxes").get_children():
		check(not box.consumed and box.visible, "Restart restores every box")
	flow = main.race_flow
	flow.set_physics_process(false)
	flow.state = RaceFlow.State.RUNNING
	main.track.finish.position.x = 300.0
	for racer in main.competitors:
		racer.set_physics_process(false)
		racer.racing = true
	main.balloon.position.x = 301.0
	flow._physics_process(0.1)
	check(flow.state == RaceFlow.State.WAITING, "Human finish waits for remaining racers")
	flow._physics_process(flow.finish_timeout + 0.1)
	check(flow.state == RaceFlow.State.RESULTS and flow.records.size() == 1, "Timeout does not fabricate finishes")
	await step()
	check(main.get_node("HUD/RaceOverlay/Results/Rows/Classification").text.count("Sin terminar") == 3, "DNF shown without invented times")
	print("RACE FLOW TEST: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
