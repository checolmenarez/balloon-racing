extends SceneTree
## Read-only race observer. Run explicitly; never loaded by the game.
## -- 12 measures seeds 1..12; -- visual opens the normal playable race.

func _initialize() -> void:
	_run.call_deferred()


func _geometry(main: Node2D) -> void:
	var data := {"obstacles": [], "boxes": [], "winds": [], "zones": [], "references": {}}
	for obstacle in main.track.get_node("Obstacles").get_children():
		var polygons: Array = []
		for child in obstacle.get_children():
			if child is CollisionPolygon2D and not child.disabled:
				var points: Array = []
				for point in child.polygon:
					var world: Vector2 = child.to_global(point)
					points.append([world.x, world.y])
				polygons.append(points)
		data.obstacles.append({"name": obstacle.name, "x": obstacle.position.x,
			"width": obstacle.width, "kind": obstacle.kind, "top": obstacle.upper_tip_y,
			"bottom": obstacle.lower_tip_y, "polygons": polygons})
	for box in main.track.get_node("ItemBoxes").get_children():
		data.boxes.append({"name": box.name, "x": box.position.x, "y": box.position.y,
			"width": box.get_node("Shape").shape.size.x,
			"height": box.get_node("Shape").shape.size.y})
	for wind in main.track.get_node("WindZones").get_children():
		data.winds.append({"name": wind.name, "x": wind.position.x, "y": wind.position.y,
			"width": wind.size.x, "height": wind.size.y, "multiplier": wind.speed_multiplier})
	for zone in main.track.zones.get_children():
		data.zones.append({"x": zone.position.x, "title": zone.get_meta("title")})
	for marker in main.track.get_node("References").get_children():
		data.references[marker.name] = [marker.position.x, marker.position.y]
	_save("geometry", data)


func _save(label: String, data: Dictionary) -> void:
	var file := FileAccess.open("res://.godot/valle-" + label + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.has("visual"):
		debug_collisions_hint = true
		change_scene_to_file("res://scenes/Main.tscn")
		return
	if args.has("geometry"):
		var main: Node2D = load("res://scenes/Main.tscn").instantiate()
		root.add_child(main)
		_geometry(main)
		quit()
		return
	var count: int = int(args[0]) if not args.is_empty() else 12
	var races: Array = []
	var failures: int = 0
	for seed_value in range(1, count + 1):
		var main: Node2D = load("res://scenes/Main.tscn").instantiate()
		main.race_seed = seed_value
		root.add_child(main)
		await physics_frame
		await process_frame
		if seed_value == 1:
			_geometry(main)
		var rows: Array = []
		for racer in main.competitors:
			var bot := racer.controller as BotController
			rows.append({"name": racer.name, "route": "passive" if bot == null else
				("upper" if bot.profile.preferred_route == BotProfile.Route.UPPER else "lower"),
				"sectors": [], "events": [], "last_counts": [0, 0, 0, 2],
				"last_x": racer.position.x, "stall": 0.0, "max_stall": 0.0,
				"s4_enter": -1.0, "s4_exit": -1.0})
			for sector in 6:
				rows[-1].sectors.append({"seconds": 0.0, "collisions": 0, "collected": 0,
					"used": 0, "turbo": 0, "wind_seconds": 0.0, "boost_seconds": 0.0})
		Input.action_release("burner")
		for frame in 60 * 110:
			await physics_frame
			await process_frame
			for index in main.competitors.size():
				var racer: Balloon = main.competitors[index]
				var row: Dictionary = rows[index]
				var sector: int = main.track.get_zone_index(racer.position.x)
				var bucket: Dictionary = row.sectors[sector]
				var counts: Array = [racer.collision_count, racer.items.collected, racer.items.used, racer.items.turbo_charges]
				for metric in 4:
					var amount: int = counts[metric] - row.last_counts[metric]
					if metric == 3:
						amount = -amount
					if amount > 0:
						var key: String = ["collisions", "collected", "used", "turbo"][metric]
						bucket[key] += amount
						row.events.append({"metric": key, "n": amount, "x": racer.position.x,
							"y": racer.position.y, "sector": sector + 1, "time": main.race_flow.elapsed})
				row.last_counts = counts
				if racer.racing:
					bucket.seconds += 1.0 / 60.0
					if racer.items.wind_multiplier() > 1.0:
						bucket.wind_seconds += 1.0 / 60.0
					if racer.items.boost_left > 0.0:
						bucket.boost_seconds += 1.0 / 60.0
					row.stall = row.stall + 1.0 / 60.0 if racer.position.x - row.last_x < 0.1 else 0.0
					row.max_stall = maxf(row.max_stall, row.stall)
					if racer.position.x >= 9700.0 and row.s4_enter < 0.0:
						row.s4_enter = main.race_flow.elapsed
					if racer.position.x >= 13400.0 and row.s4_exit < 0.0:
						row.s4_exit = main.race_flow.elapsed
				row.last_x = racer.position.x
			if main.race_flow.state == RaceFlow.State.RESULTS:
				break
		for index in rows.size():
			var record: Dictionary = main.race_flow.record_for(main.competitors[index])
			rows[index].finish_time = record.get("time", -1.0)
			if record.is_empty():
				failures += 1
			rows[index].erase("last_counts")
			rows[index].erase("last_x")
			rows[index].erase("stall")
		races.append({"seed": seed_value, "racers": rows})
		print("RECON seed %d: %d finishes" % [seed_value, main.race_flow.records.size()])
		main.queue_free()
		await process_frame
		await physics_frame
	_save("recon", {"baseline": "Passive human; unchanged production bots and combat; 60 Hz",
		"races": races, "missing_finishes": failures, "engine": Engine.get_version_info().string})
	print("RECON: %d missing finishes" % failures)
	quit(0 if failures == 0 else 1)
