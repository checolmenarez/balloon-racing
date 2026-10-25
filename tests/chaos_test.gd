extends SceneTree

var failures: int = 0
var main: Node2D


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func step(seconds: float = 0.1) -> void:
	for frame in ceili(seconds * 60.0):
		await physics_frame
		await process_frame


func setup() -> void:
	main = load("res://scenes/Main.tscn").instantiate()
	main.get_node("RaceFlow").enabled = false
	root.add_child(main)
	main.combat.set_physics_process(false)
	main.combat.config = main.combat.config.duplicate()
	for index in 4:
		var racer: Balloon = main.competitors[index]
		racer.set_physics_process(false)
		racer.position = Vector2(-1000 - index * 200, 350)
		racer.items.config = main.combat.config


func cleanup() -> void:
	main.queue_free()
	await step()


func boxes_and_size() -> void:
	setup()
	await step()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(Balloon.HALF_WIDTH * 2.0, Balloon.TOP_EXTENT + Balloon.BOTTOM_EXTENT)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.collision_mask = 2
	var heights: Dictionary = {}
	check(main.track.get_node("ItemBoxes").get_child_count() == 24, "24 evenly distributed boxes")
	for box in main.track.get_node("ItemBoxes").get_children():
		heights[box.position.y] = true
		query.transform = Transform2D(0.0, box.global_position + Vector2(0, (Balloon.BOTTOM_EXTENT - Balloon.TOP_EXTENT) * 0.5))
		check(main.get_world_2d().direct_space_state.intersect_shape(query).is_empty(), "Balloon fits at box " + box.name)
	check(heights.size() >= 8, "Boxes distributed vertically")
	for racer in main.competitors:
		check(racer.visual.scale.is_equal_approx(Vector2(0.88, 0.88)), "Uniform 12 percent visual reduction")
		check(racer.get_node("CollisionShape2D").shape.size.is_equal_approx(shape.size), "Hitbox matches visual size")
	main.combat.config.box_respawn_time = 0.2
	var box: Area2D = main.track.get_node("ItemBoxes/Box0")
	var racer: Balloon = main.balloon
	racer.position = box.global_position
	await step(0.1)
	check(box.consumed and racer.items.collected == 1, "Real box pickup")
	racer.items.equipped = BalloonItems.Kind.NONE
	await step(0.3)
	check(not box.consumed and box.visible and racer.items.collected == 1, "Respawn does not immediately regrant to same body")
	main.competitors[1].position = racer.position
	await step()
	check(main.competitors[1].items.collected == 1, "Respawn available to trailing rival")
	racer.position.x += 200
	main.competitors[1].position.x += 200
	await step(0.3)
	racer.items.equipped = BalloonItems.Kind.ROCKET
	racer.position.x -= 200
	await step()
	check(not box.consumed and racer.items.equipped == BalloonItems.Kind.ROCKET, "Full inventory preserves available box")
	await cleanup()


func storms() -> void:
	setup()
	for index in 4:
		main.competitors[index].position = Vector2(1000 - index * 100, 350)
	var leader: Balloon = main.balloon
	var source: Balloon = main.competitors[3]
	for index in 4:
		check(is_equal_approx(main.combat.storm_probability(main.competitors[index]), [0.0, 0.05, 0.15, 0.25][index]), "Storm odds follow real place")
	main.combat.config.storm_probability_by_place = Vector4(0, 1, 1, 1)
	check(main.combat.choose_item(source) == BalloonItems.Kind.STORM, "Weighted draw can grant storm to trailing racer")
	for sample in 20:
		check(main.combat.choose_item(leader) != BalloonItems.Kind.STORM, "Leader receives no storm")
	leader.items.collect(BalloonItems.Kind.STORM)
	check(not leader.items.use_item() and leader.items.equipped == BalloonItems.Kind.STORM, "Leader retains invalid storm")
	source.items.collect(BalloonItems.Kind.STORM)
	check(source.items.use_item() and source.items.equipped == BalloonItems.Kind.NONE, "Trailing racer can use storm")
	check(leader.items.storm_warning_left > 0.0 and source.items.storm_warning_left == 0.0, "Warning targets active leader only")
	await step()
	check(main.get_node("HUD/StormWarning").visible, "Human sees warning")
	leader.items.tick(0.4)
	check(is_equal_approx(leader._forward_speed(), 220.0), "Warning does not apply penalty early")
	main.competitors[2].items.collect(BalloonItems.Kind.STORM)
	check(not main.competitors[2].items.use_item(), "Pending storm cannot stack")
	leader.velocity.y = -70.0
	leader.items.tick(0.41)
	check(leader.items.storms_received == 1 and is_equal_approx(leader._forward_speed(), 143.0), "Lightning applies bounded penalty and count")
	check(leader.velocity.y == -70.0, "Storm preserves vertical control")
	leader.items.tick(1.6)
	check(is_equal_approx(leader._forward_speed(), 220.0), "Storm penalty expires")
	check(not main.competitors[2].items.use_item(), "Cooldown outlasts active penalty")
	leader.items.tick(2.0)
	check(main.competitors[2].items.use_item(), "Protection eventually expires")
	leader.stop_racing()
	check(main.combat.storm_target(source) == main.competitors[1], "Finished leader excluded from future targeting")
	check(leader.items.storm_warning_left == 0.0, "Finishing cancels pending personal effect")
	source.items.collect(BalloonItems.Kind.STORM)
	main.combat.set_physics_process(true)
	await step(0.4)
	check(source.items.used == 2 and main.competitors[1].items.storm_warning_left > 0.0, "Bot autonomously targets the new active leader")
	await cleanup()


func winds() -> void:
	setup()
	var zone: Area2D = main.track.get_node("WindZones/LowerCurrent")
	for racer in main.competitors:
		racer.position = zone.position
	await step()
	for racer in main.competitors:
		check(is_equal_approx(racer.items.wind_multiplier(), 1.2), "Wind affects every competitor equally")
		check(is_equal_approx(racer._forward_speed(), 264.0), "Wind gives temporary 20 percent speed")
	var racer: Balloon = main.balloon
	racer.set_physics_process(true)
	await step(0.1)
	check(is_equal_approx(racer.velocity.x, 264.0), "Wind changes actual moving velocity")
	racer.set_physics_process(false)
	var overlap: Area2D = load("res://scenes/WindZone.tscn").instantiate()
	overlap.position = zone.position
	main.add_child(overlap)
	await step()
	check(is_equal_approx(racer._forward_speed(), 264.0), "Overlapping winds do not multiply")
	racer.items.collect(BalloonItems.Kind.BOOST)
	racer.items.use_item()
	check(is_equal_approx(racer._forward_speed(), 297.0), "Turbo replaces rather than multiplies wind bonus")
	racer.items.storm_left = 1.5
	racer.items.hit_left = 1.0
	check(is_equal_approx(racer._forward_speed(), 178.2), "Only strongest penalty combines with strongest bonus")
	racer.items.tick(3.0)
	check(is_equal_approx(racer._forward_speed(), 264.0), "Expiring effects leaves wind only")
	for body in main.competitors:
		body.position = Vector2(1000, 350)
	await step()
	for body in main.competitors:
		check(is_equal_approx(body._forward_speed(), 220.0) and body.items.wind_zones.is_empty(), "Exit removes all wind sources")
	await cleanup()


func _run() -> void:
	await boxes_and_size()
	await storms()
	await winds()
	print("CHAOS TEST: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
