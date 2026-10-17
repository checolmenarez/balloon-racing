extends SceneTree


func _initialize() -> void:
	_run.call_deferred()


func capture(label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/m63-" + label + ".png")


func _run() -> void:
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	main.get_node("RaceFlow").enabled = false
	root.add_child(main)
	main.combat.set_physics_process(false)
	for index in 4:
		var racer: Balloon = main.competitors[index]
		racer.set_physics_process(false)
		racer.position = Vector2(10800 - index * 130, 178 if index == 0 else 485)
		racer.items.initialize_turbo(2, 0.0)
	main.debug_panel.show()
	for frame in 3:
		await physics_frame
		await process_frame
	await capture("wind-debug")
	main.debug_panel.hide()
	main.competitors[3].items.collect(BalloonItems.Kind.STORM)
	main.competitors[3].items.use_item()
	await capture("storm-warning")
	main.balloon.items.tick(0.81)
	main.balloon._update_impact(0.0)
	await capture("lightning")
	main.balloon.items.tick(5.0)
	for racer in main.competitors:
		racer.position = Vector2(1200, 350)
	for frame in 20:
		await process_frame
	await capture("overlap-boxes")
	print("M6.3 VISUAL: captures saved")
	quit()
