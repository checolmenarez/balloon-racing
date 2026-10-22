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
		await process_frame
		await physics_frame


func _run() -> void:
	var reduced: bool = GameFeel.reduced_motion
	GameFeel._reduced = false
	var gallery := Node2D.new()
	root.add_child(gallery)
	var racers: Array[Balloon] = []
	for index in 4:
		var racer: Balloon = load("res://scenes/Balloon.tscn").instantiate()
		racer.character_id = CharacterCatalog.IDS[index]
		racer.position = Vector2(180 + 300 * index, 360)
		racer.scale = Vector2.ONE * 2.0
		gallery.add_child(racer)
		racer.set_physics_process(false)
		racer.visual.set_local_outline(index == 0)
		racers.append(racer)
	await frames(2)
	for racer in racers:
		var visual: BalloonVisual = racer.visual
		visual.set_process(false)
		var body: Transform2D = racer.transform
		var shape: Transform2D = racer.get_node("CollisionShape2D").transform
		var texture: Texture2D = visual.get_node("CharacterSprite").texture
		visual._process(0.05)
		var motion: Vector3 = visual._living_motion
		visual._process(0.2)
		check(visual._living_motion != motion and visual.get_node("CharacterSprite").texture == texture, "Continuous internal animation without changing PNG: " + racer.character_id)
		racer.burner_active = true
		visual.refresh()
		check(visual.get_node("CharacterSprite").texture == texture, "Burner animates the same drawing instead of swapping proportions")
		racer.items.boost_left = 2.0
		visual.refresh()
		check(visual._pose_blend == 0, "New pose begins at previous image")
		visual._process(visual.pose_transition_seconds * 0.25)
		var progress: float = visual._pose_blend
		racer.burner_active = false
		racer.items.boost_left = 0.0
		visual.refresh()
		check(is_equal_approx(visual._pose_blend, 1.0 - progress), "Rapid input reverses blend without restarting")
		visual._process(0.3)
		check(visual._pose_blend == 1.0, "Pose blend settles")
		check(racer.transform == body and racer.get_node("CollisionShape2D").transform == shape, "Animation leaves body and collider unchanged")
		# A fixed target converges equally at 30/60/120 Hz, including large deltas.
		visual.sway_degrees = 0
		racer.velocity.y = 100
		var results: Array[float] = []
		for hz in [15, 30, 60, 120]:
			visual.rotation = 0
			visual._angular_velocity = 0
			visual._anticipation = 0
			for step in hz:
				visual._process(1.0 / hz)
			results.append(visual.rotation)
		for angle in results:
			check(absf(angle - results[0]) < 0.00001, "Spring is independent of FPS")
		visual.sway_degrees = 0.7
		racer.velocity = Vector2.ZERO
		visual.set_process(true)
	await frames(20)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var first: Image = root.get_texture().get_image()
		first.save_png("res://.godot/natural-motion-idle.png")
		await frames(24)
		await RenderingServer.frame_post_draw
		var second: Image = root.get_texture().get_image()
		check(first.get_data() != second.get_data(), "Renderer animates an unchanged idle pose")
		second.save_png("res://.godot/natural-motion-follow.png")
		for racer in racers:
			racer.visual.set_process(false)
			racer.burner_active = true
			racer.visual.refresh()
			racer.visual._process(racer.visual.pose_transition_seconds * 0.5)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/natural-motion-transition.png")
		for racer in racers:
			racer.visual.set_process(true)
	paused = true
	var frozen: Vector3 = racers[0].visual._living_motion
	var frozen_arms: Vector2 = racers[0].visual._arms
	var frozen_blink: float = racers[0].visual._blink
	await frames(4)
	check(frozen == racers[0].visual._living_motion, "Pause freezes shader-driven motion")
	check(frozen_arms == racers[0].visual._arms and frozen_blink == racers[0].visual._blink, "Pause also freezes arms and eyelids")
	paused = false
	GameFeel._reduced = true
	await frames(20)
	check(absf(racers[0].visual._living_motion.x) <= racers[0].visual.breathing_amount * 0.2 + 0.00001, "Reduced motion limits internal breathing")
	GameFeel._reduced = reduced
	gallery.queue_free()
	await process_frame
	print("NATURAL MOTION TEST: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
