extends SceneTree

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
	# Only the in-memory preference is overridden; never alter the user's setting.
	var reduced: bool = GameFeel.reduced_motion
	GameFeel._reduced = false
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	main.get_node("RaceFlow").enabled = false
	root.add_child(main)
	main.combat.set_physics_process(false)
	for index in 4:
		var racer: Balloon = main.competitors[index]
		racer.set_physics_process(false)
		racer.racing = true
		racer.position = Vector2(1000 - index * 95, 190 + index * 100)
		racer.items.initialize_turbo(2, 0.0)
	await frames(2)
	var player: Balloon = main.balloon
	var visual: BalloonVisual = player.visual
	var body: Transform2D = player.transform
	var collider: Transform2D = player.get_node("CollisionShape2D").transform
	var rng_state: int = main.combat.rng.state
	check(visual._phase != main.competitors[1].visual._phase, "Racers sway with distinct phases")
	player.velocity.y = -250
	player.burner_active = true
	await frames(30)
	check(visual.rotation < 0, "Ascending tilts smoothly")
	player.velocity.y = 250
	player.burner_active = false
	await frames(40)
	check(visual.rotation > 0, "Descending reverses tilt")
	player.velocity = Vector2.ZERO
	check(player.items.use_turbo_charge(), "Real accepted turbo starts")
	visual.refresh()
	await frames(5)
	check(visual.speed_glow > 0.2 and visual._turbo_pulse > 0, "Turbo activation and trails are visible")
	await frames(30)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/game-feel-turbo.png")
	player.items.tick(player.items.config.boost_duration)
	player.items.wind_zones.clear()
	await frames(90)
	check(visual.speed_glow < 0.001, "Turbo tail fades to zero")
	var zone: Area2D = main.track.get_node("WindZones").get_child(0)
	zone._enter(player)
	await frames(10)
	check(visual.speed_glow > 0 and visual._wind_pulse > 0, "Actual wind entry triggers feedback")
	zone._leave(player)
	await frames(1)
	check(visual._wind_pulse > 0.9, "Wind exit triggers brief feedback")
	player._apply_impact(Vector2.LEFT)
	visual.refresh()
	await frames(4)
	check(visual._shake_left > 0 and not visual.scale.is_equal_approx(Vector2.ONE * Balloon.SIZE_SCALE), "Accepted collision squashes visual")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/game-feel-impact.png")
	paused = true
	var frozen: Transform2D = visual.transform
	var wind_time: float = zone._visual_time
	await frames(10)
	check(visual.transform == frozen and zone._visual_time == wind_time, "Pause freezes motion and wind")
	paused = false
	await frames(50)
	check(visual._shake_left == 0 and visual.position.is_zero_approx(), "Impact recovers without drift")
	check(player.transform == body and player.get_node("CollisionShape2D").transform == collider, "Presentation preserves body and collider")
	check(main.combat.rng.state == rng_state, "Presentation does not consume gameplay RNG")
	GameFeel._reduced = true
	visual.present(1.0)
	check(visual._entry_offset == 0, "Reduced motion skips entry travel")
	player.items.boost_left = 2.0
	await frames(60)
	check(absf(visual.rotation) < deg_to_rad(1.5), "Reduced motion limits tilt")
	GameFeel._reduced = false
	for racer in main.competitors:
		racer.items.boost_left = 2.0
		racer.visual.refresh()
	await frames(30)
	# Wall-clock samples are diagnostic only, not a 60 FPS acceptance benchmark.
	var start: int = Time.get_ticks_usec()
	await frames(180)
	print("GAME FEEL: 180 rendered/process frames in %.1f ms (%s)" % [(Time.get_ticks_usec() - start) / 1000.0, DisplayServer.get_name()])
	GameFeel._reduced = reduced
	main.queue_free()
	await process_frame
	var home: Control = load("res://scenes/StartMenu.tscn").instantiate()
	root.add_child(home)
	home._open_panel(home.get_node("Options"), home.get_node("Layout/Rows/Buttons/Options"))
	await frames(3)
	var option: CheckButton = home.get_node("Options/Panel/Rows/ReducedMotion")
	check(home.get_viewport_rect().encloses(option.get_global_rect()), "Reduced motion option fits on screen")
	check(option.button_pressed == reduced, "Options reflect saved motion preference")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/game-feel-options.png")
	home.queue_free()
	await process_frame
	print("GAME FEEL TEST: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
