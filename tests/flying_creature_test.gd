extends SceneTree

class HoldHeight extends FlightController:
	var target: float = 340.0
	func wants_burner(body: CharacterBody2D, _delta: float) -> bool:
		return body.position.y + body.velocity.y * 0.2 > target

var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func frames(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame


func _run() -> void:
	var saved: bool = GameFeel.reduced_motion
	GameFeel._reduced = false
	var arena := Node2D.new()
	root.add_child(arena)
	var creature: FlyingCreatureObstacle = load("res://scenes/FlyingCreatureObstacle.tscn").instantiate()
	creature.position = Vector2(360, 340)
	arena.add_child(creature)
	creature.set_physics_process(false)
	for hz in [30, 60, 120]:
		creature.elapsed = 0
		for step in hz * 3:
			creature._physics_process(1.0 / hz)
			check(absf(creature.position.x - 360.0) < 0.001, "Horizontal position remains fixed")
			check(absf(creature.position.y - 340.0) <= 45.001, "Oscillation remains bounded")
		check(creature.position.distance_to(Vector2(360, 340)) < 0.001, "Same cycle at 30/60/120 Hz")
		creature._physics_process(0.75)
		check(absf(creature.position.y - 385) < 0.001, "Quarter-cycle reaches amplitude")
	var normal: Vector2 = creature.position
	GameFeel._reduced = true
	creature.elapsed = 3
	creature._physics_process(0.75)
	check(creature.position.is_equal_approx(normal), "Reduced effects never alter gameplay movement")
	GameFeel._reduced = false
	creature.set_physics_process(true)
	await frames(2)
	var query := PhysicsPointQueryParameters2D.new()
	query.position = creature.shape.global_position
	query.collision_mask = 2
	var hits: Array[Dictionary] = creature.get_world_2d().direct_space_state.intersect_point(query)
	check(not hits.is_empty() and hits[0].collider == creature, "Physics shape follows moving body")
	for height in [340.0, 150.0, 530.0]:
		creature.elapsed = 0
		creature._physics_process(0)
		var racer: Balloon = load("res://scenes/Balloon.tscn").instantiate()
		var pilot := HoldHeight.new()
		pilot.target = height
		racer.controller = pilot
		racer.add_child(pilot)
		racer.position = Vector2(150, height)
		arena.add_child(racer)
		var saw_penalty: bool = false
		var saw_reaction: bool = false
		for frame in 240:
			await frames(1)
			if racer.is_impact_penalized():
				saw_penalty = true
				check(racer._forward_speed() < racer.physics.horizontal_speed, "Standard impact slows racer")
			if creature.reaction_left > 0:
				saw_reaction = true
				check(creature.sprite.texture == creature.impact_texture, "Contact uses supplied punch pose")
		check(racer.position.x > 700, "Racer continues after encounter")
		if height == 340.0:
			check(racer.collision_count == 1 and saw_penalty and saw_reaction, "Contact applies exactly one standard impact")
		else:
			check(racer.collision_count == 0, "Clear route above/below creature")
		check(racer.get_collision_exceptions().is_empty(), "Exception removed after horizontal clearance")
		racer.queue_free()
		await frames(2)
	check(creature.sprite.texture == creature.normal_texture, "Creature survives and recovers normal pose")
	creature.set_process(false)
	creature._visual_time = 0.09
	creature._process(0)
	check(float(creature.sprite.material.get_shader_parameter("blink")) > 0.99, "Eyelids close")
	var wing: float = creature.sprite.material.get_shader_parameter("wing")
	GameFeel._reduced = true
	creature._process(0)
	check(is_equal_approx(float(creature.sprite.material.get_shader_parameter("wing")), wing * 0.2), "Reduced mode attenuates wing motion")
	creature.set_process(true)
	paused = true
	var frozen: Vector2 = creature.position
	var clock: float = creature._visual_time
	await frames(5)
	check(creature.position == frozen and creature._visual_time == clock, "Pause freezes physics and visuals")
	paused = false
	arena.queue_free()
	await frames(2)
	GameFeel._reduced = saved
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	main.get_node("RaceFlow").enabled = false
	root.add_child(main)
	main.combat.set_physics_process(false)
	for racer in main.competitors:
		racer.set_physics_process(false)
	var creatures: Node = main.track.get_node("FlyingObstacles")
	check(creatures.get_child_count() == 3, "Three reused creatures in Valle Ventoso")
	for index in 3:
		var flappy: FlyingCreatureObstacle = creatures.get_child(index)
		check(main.track.get_zone_index(flappy.global_position.x) == [1, 4, 5][index], "Encounter is in S2/S5/S6")
		var bounds: Rect2 = flappy.get_swept_bounds()
		check(bounds.position.y - main.balloon.ceiling_y > Balloon.TOP_EXTENT + Balloon.BOTTOM_EXTENT, "Full balloon fits above entire sweep")
		check(main.balloon.ground_y - bounds.end.y > Balloon.TOP_EXTENT + Balloon.BOTTOM_EXTENT, "Full balloon fits below entire sweep")
		for obstacle in main.track.get_node("Obstacles").get_children():
			check(bounds.end.x < obstacle.position.x - obstacle.width * 0.5 or bounds.position.x > obstacle.get_right_edge(), "Creature sweep does not intersect existing formations")
		main.balloon.position = Vector2(flappy.position.x - 350, 420)
		await frames(5)
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://.godot/flappy-sector-%d.png" % [2, 5, 6][index])
			flappy.react_to_impact()
			await frames(2)
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://.godot/flappy-sector-%d-impact.png" % [2, 5, 6][index])
	main.queue_free()
	await frames(2)
	print("FLYING CREATURE TEST: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
