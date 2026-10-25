extends SceneTree
## Visual review helper, no gameplay assertions. Run with a rendering window.
func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	root.size = Vector2i(1280,720)
	var deliver: bool = "kit" in OS.get_cmdline_user_args()
	var reduced: bool = "reduced" in OS.get_cmdline_user_args()
	var before: bool = "before" in OS.get_cmdline_user_args()
	# Test-only state: do not overwrite the user's presentation preferences.
	GameFeel._loaded = true
	GameFeel._reduced = reduced
	var output: String = "res://docs/valle-terrain-kit" if deliver else "res://.godot"
	if before: output += "/before"
	DirAccess.make_dir_recursive_absolute(output)
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	if before:
		# Captures the previous renderer against the CURRENT unchanged layout.
		main.get_node("Track01/WorldVisual").set_script(load("res://.godot/world_visual_original.gd"))
	main.get_node("RaceFlow").enabled = false
	main.get_node("ItemCombat").enabled = false
	root.add_child(main)
	for racer in main.competitors:
		racer.set_physics_process(false)
	await physics_frame
	await process_frame
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(Balloon.HALF_WIDTH * 2, Balloon.TOP_EXTENT + Balloon.BOTTOM_EXTENT)
	query.shape = shape
	query.collision_mask = 2
	for i in 6:
		var x: float = [1800,3650,7800,11600,14900,17650][i]
		for index in 4:
			var racer_x: float = x - index * 100
			var desired: float = [180.0, 535.0, 300.0, 460.0][index]
			var best_y: float = 350.0
			var distance: float = INF
			for y in range(100, 580, 5):
				query.transform = Transform2D(0.0, Vector2(racer_x, y + (Balloon.BOTTOM_EXTENT - Balloon.TOP_EXTENT) * 0.5))
				if absf(y - desired) < distance and main.get_world_2d().direct_space_state.intersect_shape(query).is_empty():
					best_y = y
					distance = absf(y - desired)
			main.competitors[index].position = Vector2(racer_x, best_y)
		for frame in 5:
			await process_frame
		await RenderingServer.frame_post_draw
		var suffix: String = "-reduced" if reduced else ""
		root.get_texture().get_image().save_png(output + "/valle-preview-s%d%s.png" % [i+1, suffix])
	main.queue_free()
	await process_frame
	quit()
