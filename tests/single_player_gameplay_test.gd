extends SceneTree

var failures: int = 0
var config: SinglePlayerConfig = load("res://resources/default_single_player.tres")


func check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)


func _initialize() -> void:
	run.call_deferred()


func run() -> void:
	await _check_pattern_geometry()
	await _check_real_flight()
	await _check_sequence_rules()
	await _check_actual_speed_curve()
	print("SINGLE PLAYER GAMEPLAY TEST: failures=", failures)
	quit(failures)


func _check_pattern_geometry() -> void:
	var manager := SinglePlayerSegmentManager.new()
	manager.config = config
	root.add_child(manager)
	var body_shape := RectangleShape2D.new()
	body_shape.size = Vector2(Balloon.HALF_WIDTH * 2.0 + 12.0, Balloon.TOP_EXTENT + Balloon.BOTTOM_EXTENT + 12.0)
	var original_star_chance := config.star_spawn_chance
	config.star_spawn_chance = 1.0
	for pattern in SinglePlayerSegmentManager.PATTERNS:
		manager._last_star_index = -100
		var segment := manager.build_pattern_for_test(pattern, 1.0, 350.0)
		await physics_frame
		var route: PackedVector2Array = segment.get_meta("safe_route")
		check(route[0].x == 0.0 and route[-1].x == config.segment_length, "%s has explicit safe entry and exit" % pattern)
		check(is_equal_approx(route[0].y, 350.0) and is_equal_approx(route[-1].y, float(segment.get_meta("safe_end_y"))), "%s route metadata is continuous" % pattern)
		var clear := true
		var first_blocked_x := -1
		for x in range(30, roundi(config.segment_length), 20):
			var query := PhysicsShapeQueryParameters2D.new()
			query.shape = body_shape
			var y := manager.route_height(route, float(x))
			query.transform = Transform2D(0.0, segment.to_global(Vector2(x, y + (Balloon.BOTTOM_EXTENT - Balloon.TOP_EXTENT) * 0.5)))
			query.collision_mask = 2
			if not root.world_2d.direct_space_state.intersect_shape(query, 1).is_empty():
				clear = false
				first_blocked_x = x
				break
		check(clear, "%s safe route clears real colliders (blocked x=%d)" % [pattern, first_blocked_x])
		for obstacle: FlightObstacle in segment.get_node("Obstacles").get_children():
			check(obstacle.has_meta("track_source"), "%s obstacle references Track01 source" % pattern)
			for side in [&"Lower", &"Upper"]:
				var collision := obstacle.get_node(str(side) + "Collision") as CollisionPolygon2D
				var source_visual := obstacle.get_node(str(side) + "Visual") as Polygon2D
				if not collision.disabled:
					check(collision.polygon == source_visual.polygon, "%s collider matches source silhouette" % pattern)
		for star: MagicStar in segment.find_children("*", "MagicStar", true, false):
			var star_query := PhysicsShapeQueryParameters2D.new()
			star_query.shape = body_shape
			star_query.transform = Transform2D(0.0, star.global_position + Vector2(0.0, (Balloon.BOTTOM_EXTENT - Balloon.TOP_EXTENT) * 0.5))
			star_query.collision_mask = 2
			check(root.world_2d.direct_space_state.intersect_shape(star_query, 1).is_empty(), "%s star is reachable by the full balloon body" % pattern)
		check(segment.find_children("*", "SinglePlayerGate", true, false).is_empty(), "%s uses no generic rectangular gate" % pattern)
		segment.queue_free()
		await process_frame
	config.star_spawn_chance = original_star_chance
	manager.queue_free()
	await process_frame


func _check_real_flight() -> void:
	for pattern in SinglePlayerSegmentManager.PATTERNS:
		var manager := SinglePlayerSegmentManager.new()
		manager.config = config
		root.add_child(manager)
		var segment := manager.build_pattern_for_test(pattern, 1.0, 350.0)
		var route: PackedVector2Array = segment.get_meta("safe_route")
		var balloon := load("res://scenes/Balloon.tscn").instantiate() as Balloon
		balloon.physics = balloon.physics.duplicate(true)
		balloon.physics.horizontal_speed = config.target_speed(config.advanced_distance)
		balloon.physics.impact_protection_time = 1.0
		balloon.position = Vector2(0, 350)
		root.add_child(balloon)
		balloon.set_vertical_bounds(32.0, 640.0)
		var frames := 0
		while balloon.position.x < config.segment_length and frames < 60 * 14:
			var target := manager.route_height(route, balloon.position.x + 90.0)
			if balloon.position.y + balloon.velocity.y * 0.42 > target:
				Input.action_press("burner")
			else:
				Input.action_release("burner")
			await physics_frame
			frames += 1
		Input.action_release("burner")
		check(balloon.position.x >= config.segment_length, "%s completes at advanced speed" % pattern)
		check(balloon.collision_count == 0, "%s is traversable with shared balloon physics" % pattern)
		balloon.queue_free()
		manager.queue_free()
		await process_frame


func _check_sequence_rules() -> void:
	for seed in [17, 82472, 991337]:
		var manager := SinglePlayerSegmentManager.new()
		root.add_child(manager)
		manager.setup(config, seed)
		for segment_index in 40:
			manager.ensure_segments(segment_index * config.segment_length)
			await process_frame
		var seen: Dictionary = {}
		var previous: StringName = &""
		var repeats_immediately := false
		for pattern in manager.generated_patterns:
			seen[pattern] = true
			if pattern == previous:
				repeats_immediately = true
			previous = pattern
		check(not repeats_immediately, "Seed %d avoids immediate pattern repetition" % seed)
		for pattern in SinglePlayerSegmentManager.PATTERNS:
			check(seen.has(pattern), "Seed %d reaches pattern %s" % [seed, pattern])
		var stars_are_spaced := true
		for star_index in range(1, manager.generated_star_indices.size()):
			if manager.generated_star_indices[star_index] - manager.generated_star_indices[star_index - 1] < config.star_minimum_segments:
				stars_are_spaced = false
		check(stars_are_spaced, "Seed %d spaces strategic stars by the configured minimum" % seed)
		check(manager.active_segments.size() <= config.segments_ahead + config.segments_behind + 1, "Seed %d keeps bounded active resources" % seed)
		manager.queue_free()
		await process_frame


func _check_actual_speed_curve() -> void:
	root.get_node("RaceSelection").selected = 0
	var scene: Node2D = load("res://scenes/SinglePlayer.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.intro.hide()
	scene._start_attempt()
	# This check measures the applied CharacterBody2D velocity, independently of
	# slide collisions already covered by the pattern traversal checks above.
	scene.balloon.collision_mask = 0
	var samples: Array[float] = []
	for milestone in [0.0, 3600.0, 9000.0]:
		scene.distance = milestone
		for frame in 90:
			await physics_frame
		samples.append(scene.balloon.velocity.x)
		var expected: float = config.target_speed(scene.distance)
		check(absf(scene.balloon.velocity.x - expected) < 2.0, "Actual body speed matches target at %.0f px" % milestone)
	check(samples[1] > samples[0] * 1.18 and samples[2] > samples[0] * 1.45, "Actual speed curve is perceptible: %s" % [samples])
	check(samples[2] <= config.initial_speed * config.maximum_speed_multiplier + 0.1, "Actual speed remains capped")
	print("SINGLE PLAYER ACTUAL SPEEDS: start=%.1f intermediate=%.1f advanced=%.1f px/s" % samples)
	scene.queue_free()
	await process_frame
