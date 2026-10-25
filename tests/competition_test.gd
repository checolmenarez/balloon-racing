extends SceneTree

var failures: int = 0
var samples: Array[Dictionary] = []


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func _check_boxes(main: Node2D) -> void:
	# Conservative full balloon bounding rectangle, larger than its actual shapes.
	var shape := RectangleShape2D.new()
	shape.size = Vector2(Balloon.HALF_WIDTH * 2.0, Balloon.TOP_EXTENT + Balloon.BOTTOM_EXTENT)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.collision_mask = 2
	for box in main.track.get_node("ItemBoxes").get_children():
		query.transform = Transform2D(0.0, box.global_position + Vector2(0, (Balloon.BOTTOM_EXTENT - Balloon.TOP_EXTENT) * 0.5))
		check(main.get_world_2d().direct_space_state.intersect_shape(query).is_empty(), "Box has clearance for balloon: %s" % box.name)
		check(box.position.y >= 106.0 and box.position.y <= 579.0, "Box within flight bounds")


func _run() -> void:
	var count: int = 12
	if not OS.get_cmdline_user_args().is_empty():
		count = int(OS.get_cmdline_user_args()[0])
	var wins: Dictionary = {}
	var bot_wins: Dictionary = {}
	for seed_value in range(1, count + 1):
		var main: Node2D = load("res://scenes/Main.tscn").instantiate()
		main.race_seed = seed_value
		root.add_child(main)
		await physics_frame
		await process_frame
		_check_boxes(main)
		# Deliberately passive human baseline; only bot-vs-bot outcomes assess AI.
		Input.action_release("burner")
		for frame in 60 * 110:
			await physics_frame
			await process_frame
			for racer in main.competitors:
				check(racer.physics == main.balloon.physics, "Identical physics resource")
				check(racer.velocity.x <= 297.01, "No permanent/exclusive speed advantage")
			if main.race_flow.state == RaceFlow.State.RESULTS:
				break
		check(main.race_flow.state == RaceFlow.State.RESULTS, "Race reaches results")
		for racer in main.competitors:
			if racer.controller is BotController and racer.position.x < main.track.finish.position.x:
				print("UNFINISHED ", racer.competitor_name, " at ", racer.position, " target=", racer.controller.target_height)
		check(main.race_flow.records.size() == 4, "All competitors finish before timeout")
		var rows: Array[Dictionary] = []
		var fastest_bot: String = ""
		for record in main.race_flow.records:
			var racer: Balloon = record.racer
			var bot := racer.controller as BotController
			rows.append({"name": racer.competitor_name, "time": record.time, "place": record.place,
				"collisions": record.collisions, "items": record.items, "collected": racer.items.collected,
				"route": ("upper" if bot.profile.preferred_route == BotProfile.Route.UPPER else "lower") if bot != null else "passive human"})
			if bot != null and fastest_bot.is_empty():
				fastest_bot = racer.competitor_name
		var winner: String = main.race_flow.records[0].racer.competitor_name
		wins[winner] = wins.get(winner, 0) + 1
		bot_wins[fastest_bot] = bot_wins.get(fastest_bot, 0) + 1
		samples.append({"seed": seed_value, "results": rows})
		print("SEED %d: %s" % [seed_value, JSON.stringify(rows)])
		main.queue_free()
		await process_frame
		await physics_frame
	var file := FileAccess.open("res://.godot/m63-simulations.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"baseline": "Human holds no keys; compare bots only", "wins": wins, "fastest_bot": bot_wins, "races": samples}, "\t"))
	print("BOT FINISH LEADERS: %s" % bot_wins)
	print("COMPETITION TEST: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
