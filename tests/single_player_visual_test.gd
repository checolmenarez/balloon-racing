extends SceneTree


func _initialize() -> void:
	run.call_deferred()


func settle(frames: int = 12) -> void:
	for frame in frames:
		await process_frame


func capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png("res://.godot/single-player-" + label + ".png")
	if error != OK:
		push_error("Could not save Single Player capture")


func capture_pattern(pattern: StringName, label: String, x: float = 1100.0) -> void:
	current_scene.started = false
	current_scene.segments.clear()
	await process_frame
	var segment: Node2D = current_scene.segments.build_pattern_for_test(pattern, 1.0, 350.0)
	var route: PackedVector2Array = segment.get_meta("safe_route")
	current_scene.balloon.position = Vector2(x, current_scene.segments.route_height(route, x))
	current_scene._update_camera()
	await settle(20)
	await capture(label)
	segment.queue_free()


func run() -> void:
	root.size = Vector2i(1280, 720)
	root.get_node("RaceSelection").selected = 0
	var scene: Node2D = load("res://scenes/SinglePlayer.tscn").instantiate()
	scene.run_seed = 82472
	root.add_child(scene)
	current_scene = scene
	await settle()
	await capture("intro")
	current_scene.intro.hide()
	current_scene._start_attempt()
	# Freeze the player while composing deterministic QA captures. Otherwise the
	# live generator repopulates cleared segments and overlays the previews.
	current_scene.started = false
	current_scene.balloon.racing = false
	current_scene.balloon.collision_layer = 0
	current_scene.balloon.collision_mask = 0
	current_scene.balloon.velocity = Vector2.ZERO
	var opening: Node2D = current_scene.segments.active_segments[0]
	var opening_route: PackedVector2Array = opening.get_meta("safe_route")
	current_scene.balloon.position = Vector2(1100, current_scene.segments.route_height(opening_route, 1100.0))
	current_scene._update_camera()
	await settle(20)
	await capture("gameplay")
	await capture_pattern(&"dual_route_island", "dual-route")
	await capture_pattern(&"flappy_encounter", "flappy")
	print("SINGLE PLAYER VISUAL TEST: captures written")
	quit()
