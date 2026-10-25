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


func _inventory_and_strategy() -> void:
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	main.get_node("RaceFlow").enabled = false
	root.add_child(main)
	main.combat.set_physics_process(false)
	for body in main.competitors:
		body.set_physics_process(false)
	var racer: Balloon = main.competitors[1]
	racer.position = Vector2(1000, 350)
	racer.controller.target_height = 350.0
	racer.items.initialize_turbo(3, 0.0)
	check(main.combat.bot_should_turbo(racer), "Open stable flight permits charge")
	racer.position.x = 1650.0
	check(not main.combat.bot_should_turbo(racer), "Approaching rock blocks charge")
	racer.position.x = 18250.0
	check(not main.combat.bot_should_turbo(racer), "Do not waste boost across finish")
	racer.position = Vector2(240, 110)
	check(not main.combat.bot_should_turbo(racer), "Precision/vertical margin blocks charge")
	# State/API also work on a human competitor, with no new input binding.
	racer = main.balloon
	racer.items.initialize_turbo(3, 0.0)
	check(racer.items.collect(BalloonItems.Kind.ROCKET), "Item inventory remains available")
	check(racer.items.use_turbo_charge() and racer.items.turbo_charges == 2, "Charge starts boost and decrements once")
	check(racer.items.equipped == BalloonItems.Kind.ROCKET and racer.items.used == 0, "Charge does not occupy/consume inventory or item statistics")
	check(not racer.items.use_turbo_charge(), "No repeated charge while boosted")
	racer.items.tick(0.5)
	check(racer.items.use_item(), "Rocket usable during charge boost")
	check(racer.items.collect(BalloonItems.Kind.BOOST), "Can collect item during boost")
	var remaining: float = racer.items.boost_left
	check(not racer.items.use_item() and racer.items.equipped == BalloonItems.Kind.BOOST, "Active boost preserves equipped boost")
	check(racer.items.boost_left == remaining, "Rejected boost cannot extend duration")
	racer.items.tick(2.0)
	check(not racer.items.use_turbo_charge(), "Minimum charge interval enforced after boost ends")
	check(racer.items.use_item(), "Item boost still works during charge cooldown")
	racer.items.turbo_wait_left = 0.0
	check(not racer.items.use_turbo_charge() and racer.items.turbo_charges == 2, "Item boost also prevents charge stacking")
	racer.items.tick(3.0)
	check(racer.items.use_turbo_charge(), "Second charge available after both restrictions")
	racer.position = Vector2(20000, 350)
	racer.set_physics_process(true)
	await step()
	await step()
	check(is_equal_approx(racer.velocity.x, 297.0), "Actual horizontal movement uses existing boost")
	racer.items.receive_hit(main.competitors[1], Vector2.ZERO)
	await step()
	check(is_equal_approx(racer.velocity.x, 178.2), "Penalty composes with charge boost")
	racer.set_physics_process(false)
	racer.items.tick(12.0)
	check(is_equal_approx(racer._forward_speed(), 220.0), "Modifiers expire without changing base speed")
	check(racer.items.use_turbo_charge() and racer.items.turbo_charges == 0, "Third charge exhausts supply")
	racer.items.tick(30.0)
	for attempt in 5:
		check(not racer.items.use_turbo_charge() and racer.items.turbo_charges == 0, "Counter cannot become negative or regenerate")
	racer.items.initialize_turbo(1, 0.0)
	racer.stop_racing()
	check(not racer.items.use_turbo_charge() and racer.items.turbo_charges == 1, "Finished competitor cannot consume charges")
	main.queue_free()
	await step()


func _real_race() -> void:
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	main.race_seed = 1
	root.add_child(main)
	current_scene = main
	check(main.balloon.items.turbo_charges == 2, "Human starts with two")
	var previous: Array[int] = [2, 2, 2, 2]
	var last_use: Array[float] = [-100, -100, -100, -100]
	var uses: Array[int] = [0, 0, 0, 0]
	for index in range(1, 4):
		check(main.competitors[index].items.turbo_charges == 2, "Every bot starts with exactly two")
		check(not main.competitors[index].items.use_turbo_charge(), "Countdown prevents charge use")
	for frame in 60 * 110:
		await step()
		if main.balloon.racing and main.balloon.items.turbo_charges == 2 and main.balloon.items.turbo_wait_left <= 0.0:
			main.balloon.items.collect(BalloonItems.Kind.ROCKET)
			var equipped_before: BalloonItems.Kind = main.balloon.items.equipped
			var key := InputEventKey.new()
			key.physical_keycode = KEY_SPACE
			key.pressed = true
			Input.parse_input_event(key)
			await step()
			check(main.balloon.items.turbo_charges == 1 and main.balloon.items.boost_left > 0.0, "D activates human turbo")
			check(main.balloon.items.equipped == equipped_before, "D leaves equipped object intact")
		for index in range(1, 4):
			var racer: Balloon = main.competitors[index]
			var charges: int = racer.items.turbo_charges
			check(charges >= 0 and charges <= previous[index], "Charges only decrease during race")
			if charges < previous[index]:
				var time: float = main.race_flow.elapsed
				check(time >= 5.0 - 0.02, "No charge immediately after GO")
				check(time - last_use[index] >= 12.0 - 0.02, "Autonomous uses are spaced")
				check(charges == previous[index] - 1, "One charge per activation")
				uses[index] += 1
				last_use[index] = time
				print("TURBO %s at %.2f s: %d remaining" % [racer.competitor_name, time, charges])
			previous[index] = charges
		if main.race_flow.state == RaceFlow.State.RESULTS:
			break
	check(main.race_flow.records.size() == 4, "Four recorded arrivals with turbos")
	check(uses[1] + uses[2] + uses[3] > 0, "Bots exploit a safe opening on the denser track")
	for index in range(1, 4):
		check(not main.competitors[index].items.use_turbo_charge(), "Results block turbo use")
	for index in main.race_flow.records.size():
		var record: Dictionary = main.race_flow.records[index]
		check(record.place == index + 1 and main.standings.get_place(record.racer) == index + 1, "Standings preserve real finish order")
		check(record.time > 0.0, "Finish records have positive race time")
		if index > 0:
			check(record.time >= main.race_flow.records[index - 1].time, "Finish times are ordered")
	main.debug_panel.show()
	await step()
	check(main.debug_label.text.count("Turbos") == 4, "F2 includes all competitors' charge counters")
	main.get_node("HUD/RaceOverlay/Results/Rows/Restart").pressed.emit()
	await step()
	await step()
	main = current_scene
	for index in 4:
		check(main.competitors[index].items.turbo_charges == 2, "Another race resets allocation")
	check(main.race_flow.elapsed == 0.0, "Restart resets clock")
	main.queue_free()
	await step()


func _run() -> void:
	await _inventory_and_strategy()
	await _real_race()
	print("TURBO TEST: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
