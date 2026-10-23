extends SceneTree


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Benchmark requires a rendering window")
		quit(1)
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	root.size = Vector2i(1280, 720)
	GameFeel._loaded = true
	GameFeel._reduced = false
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var label: String = args[0] if args.size() > 0 else "sample"
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	var sample_x: float = 4000.0 if "s2" in args else 1000.0
	for arg in args:
		if arg.begins_with("x="):
			sample_x = float(arg.trim_prefix("x="))
		if arg.begins_with("track="):
			main.get_node("Track01").free()
			var course: Node = load(arg.trim_prefix("track=")).instantiate()
			course.name = "Track01"
			main.add_child(course)
	main.race_seed = 21
	main.get_node("RaceFlow").enabled = false
	root.add_child(main)
	main.combat.set_physics_process(false)
	if "no_flappy" in args:
		main.track.get_node("FlyingObstacles").free()
	for index in 4:
		var racer: Balloon = main.competitors[index]
		racer.set_physics_process(false)
		racer.racing = true
		racer.position = Vector2(sample_x - index * 95, 190 + index * 100)
		racer.items.boost_left = 2.0
		racer.visual.refresh()
	if "no_world" in args:
		main.track.get_node("WorldVisual").hide()
	if "no_racers" in args:
		for racer in main.competitors:
			racer.visual.hide()
	if "no_hud" in args:
		main.get_node("HUD").hide()
	for racer in main.competitors:
		if "no_effects" in args:
			racer.visual.get_node("FlightEffects").hide()
		if "no_groups" in args:
			RenderingServer.canvas_item_set_canvas_group_mode(racer.visual.get_canvas_item(), RenderingServer.CANVAS_GROUP_MODE_DISABLED)
		if "no_shader" in args:
			racer.visual.set_process(false)
			racer.visual.get_node("CharacterSprite").material = null
	var results: Array[Dictionary] = []
	for reduced in [false, true]:
		if reduced and args.size() > 1:
			break
		GameFeel._reduced = reduced or "reduced" in args
		for frame in 60:
			await RenderingServer.frame_post_draw
		for sample in (1 if args.size() > 1 else 3):
			var times: Array[float] = []
			var last: int = Time.get_ticks_usec()
			for frame in 90:
				await RenderingServer.frame_post_draw
				var now: int = Time.get_ticks_usec()
				times.append((now - last) / 1000.0)
				last = now
			var mean: float = 0.0
			for ms in times:
				mean += ms / times.size()
			times.sort()
			var row: Dictionary = {"reduced": GameFeel.reduced_motion, "sample": sample, "fps": 1000.0 / mean, "mean_ms": mean, "p95_ms": times[85], "draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), "process_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0}
			results.append(row)
			print("BENCH ", label, " ", JSON.stringify(row))
	var file := FileAccess.open("res://.godot/feel-bench-" + label + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"label": label, "renderer": RenderingServer.get_video_adapter_name(), "size": "1280x720", "samples": results}, "\t"))
	main.queue_free()
	await process_frame
	quit()
