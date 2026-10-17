extends SceneTree


func _initialize() -> void:
	_run.call_deferred()


func capture(label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/m6-" + label + ".png")


func _run() -> void:
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	main.race_seed = 1
	root.add_child(main)
	await capture("countdown")
	while main.race_flow.state == RaceFlow.State.COUNTDOWN:
		await physics_frame
		await process_frame
	await capture("go")
	main.race_flow.set_physics_process(false)
	for racer in main.competitors:
		racer.set_physics_process(false)
		racer.position = Vector2(500, 350)
	for frame in 20:
		await process_frame
	await capture("overlap")
	for racer in main.competitors:
		racer.position.x = 19000.0
	main.race_flow._physics_process(1.0 / 60.0)
	await capture("results")
	print("M6 VISUAL: screenshots saved")
	quit()
