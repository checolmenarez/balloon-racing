extends SceneTree

var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _test_race(swap_routes: bool) -> void:
	Input.action_release("burner")
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	main.get_node("ItemCombat").enabled = false # Isolate pre-M5 regression.
	main.get_node("RaceFlow").enabled = false # Isolate flight/items from lifecycle.
	for zone in main.get_node("Track01/WindZones").get_children():
		zone.enabled = false
	root.add_child(main)
	var racers: Array[Balloon] = main.competitors
	var track: BalloonTrack = main.get_node("Track01")
	var standings: RaceStandings = main.get_node("Standings")
	var found: int = 0
	for child in main.get_children():
		if child is Balloon:
			found += 1
	_check(found == 4 and racers.size() == 4, "Exactly four Balloon instances")
	for index in racers.size():
		var racer: Balloon = racers[index]
		_check(racer.physics == racers[0].physics, "Shared physics resource")
		_check(racer.collision_mask == racers[0].collision_mask, "Same collision rules")
		for other in range(index + 1, racers.size()):
			var difference: Vector2 = (racer.position - racers[other].position).abs()
			_check(difference.x >= 88.0 or difference.y >= 135.0, "No overlapping starting bodies")
		if index > 0 and swap_routes:
			var bot := racer.controller as BotController
			bot.profile = bot.profile.duplicate()
			bot.profile.preferred_route = BotProfile.Route.UPPER if bot.profile.preferred_route == BotProfile.Route.LOWER else BotProfile.Route.LOWER
	var previous_x: Array[float] = []
	var reached: Array[bool] = [false, false, false, false]
	var saw_penalty: Array[bool] = [false, false, false, false]
	var recovered: Array[bool] = [false, false, false, false]
	var branch_seen: Array[bool] = [false, false, false, false]
	var burner_seen: Array[bool] = [false, false, false, false]
	# A scene may be added during a physics_frame signal; settle that tick first.
	await process_frame
	for racer in racers:
		previous_x.append(racer.position.x)
	var places: Array[int] = []
	var previous_tick: int = Engine.get_physics_frames()
	for frame in Engine.physics_ticks_per_second * 100:
		# The human deliberately flies low. Bots must be independent of UP.
		await physics_frame
		await process_frame
		var ticks: int = Engine.get_physics_frames() - previous_tick
		previous_tick = Engine.get_physics_frames()
		for index in racers.size():
			var racer: Balloon = racers[index]
			burner_seen[index] = burner_seen[index] or racer.burner_active
			_check(racer.position.y >= 32.0 + Balloon.TOP_EXTENT - 0.001 and racer.position.y <= 640.0 - Balloon.BOTTOM_EXTENT + 0.001, "All racers respect bounds")
			# Sliding may project some vertical motion into X; use total speed bound.
			var maximum_displacement: float = Vector2(220.0, 250.0).length() * ticks / Engine.physics_ticks_per_second + 0.2
			_check(absf(racer.position.x - previous_x[index]) <= maximum_displacement, "No teleport: %s frame=%d ticks=%d dx=%.3f" % [racer.competitor_name, frame, ticks, racer.position.x - previous_x[index]])
			_check(racer.velocity.x <= 220.01, "No extra horizontal speed")
			previous_x[index] = racer.position.x
			if racer.is_impact_penalized():
				saw_penalty[index] = true
				_check(racer.velocity.x < 220.01, "Impact penalty remains effective")
			elif saw_penalty[index] and is_equal_approx(racer.velocity.x, 220.0):
				recovered[index] = true
			if racer.position.x > 11600.0 and racer.position.x < 11700.0 and index > 0:
				var bot := racer.controller as BotController
				branch_seen[index] = racer.position.y < 260.0 if bot.profile.preferred_route == BotProfile.Route.UPPER else racer.position.y > 340.0
			if racer.position.x >= track.finish.global_position.x and not reached[index]:
				reached[index] = true
				print("%s route_swap=%s: %.2f s, hits=%d" % [racer.competitor_name, swap_routes,
					float(frame + 1) / Engine.physics_ticks_per_second, racer.collision_count])
		var place: int = standings.get_place(racers[0])
		if place not in places:
			places.append(place)
		if not reached.has(false):
			break
	_check(not reached.has(false), "Every competitor reaches finish")
	_check(places.size() > 1, "Live race changes player position")
	_check(not burner_seen[0], "Human input remains independent of bot burners")
	for index in range(1, racers.size()):
		_check(burner_seen[index], "Bot uses burner without UP")
		_check(branch_seen[index], "Bot navigates its selected branch")
		if saw_penalty[index]:
			_check(recovered[index], "Bot recovers after actual collisions")
	# Exact ranking and stable near-tie checks, isolated from motion.
	for index in racers.size():
		racers[index].set_physics_process(false)
		racers[index].position.x = 1000.0 + index * 100.0
	standings.update_positions()
	_check(standings.get_place(racers[0]) == 4, "Real X determines last place")
	racers[0].position.x = 1400.0
	standings.update_positions()
	_check(standings.get_place(racers[0]) == 1, "Overtake takes first place")
	racers[3].position.x = 1401.0
	standings.update_positions()
	_check(standings.get_place(racers[0]) == 1, "Near tie preserves ordering")
	racers[3].position.x = 1404.0
	standings.update_positions()
	_check(standings.get_place(racers[3]) == 1, "Clear overtake resolves tie")
	await process_frame
	await process_frame
	_check(is_equal_approx(main.get_node("Camera2D").position.x, racers[0].position.x + 280.0), "Camera follows only human")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_F2
	key.pressed = true
	Input.parse_input_event(key)
	await process_frame
	await process_frame
	_check(main.get_node("HUD/DebugPanel").visible, "F2 opens race debug")
	var debug: String = main.get_node("HUD/DebugPanel/Margin/DebugLabel").text
	for index in range(1, racers.size()):
		var bot := racers[index].controller as BotController
		_check(debug.contains(bot.profile.profile_name), "Debug identifies every bot profile")
	_check(debug.contains(racers[0].competitor_name + ":") and debug.contains("Y objetivo"), "Debug contains all progress and target heights")
	main.queue_free()
	await process_frame
	await physics_frame


func _test_equal_impacts() -> void:
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	main.get_node("ItemCombat").enabled = false # Isolate pre-M5 regression.
	main.get_node("RaceFlow").enabled = false # Isolate flight/items from lifecycle.
	for zone in main.get_node("Track01/WindZones").get_children():
		zone.enabled = false
	root.add_child(main)
	# Same geometry, position and input for each controller identity.
	# Place each at the first mountain, and suppress burner decisions temporarily.
	for racer in main.competitors:
		racer.controller = null
		racer.position = Vector2(1700.0, 579.0)
	var hit: bool = false
	for frame in 180:
		await physics_frame
		await process_frame
		for racer in main.competitors:
			_check(racer.velocity.is_equal_approx(main.balloon.velocity), "Identical movement and impact response")
			_check(racer.collision_count == main.balloon.collision_count, "Identical impact counts")
		hit = hit or main.balloon.collision_count > 0
	_check(hit and not main.balloon.is_impact_penalized(), "All four collide and recover")
	main.queue_free()
	await process_frame
	await physics_frame


func _run() -> void:
	if not OS.get_cmdline_user_args().is_empty():
		Engine.physics_ticks_per_second = int(OS.get_cmdline_user_args()[0])
	await _test_race(false)
	await _test_race(true)
	await _test_equal_impacts()
	print("RACE TEST at %d Hz: %s (%d failures)" % [Engine.physics_ticks_per_second,
		"PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
