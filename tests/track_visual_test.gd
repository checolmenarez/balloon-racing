extends SceneTree


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Visual capture requires the graphical renderer")
		quit(1)
		return
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	main.get_node("ItemCombat").enabled = false # Isolate pre-M5 regression.
	main.get_node("RaceFlow").enabled = false # Isolate flight/items from lifecycle.
	root.add_child(main)
	var balloon: Balloon = main.get_node("Balloon")
	balloon.set_physics_process(false)
	var positions: Array[Vector2] = [Vector2(10000, 350), Vector2(11400, 180), Vector2(18400, 350), Vector2(240, 420)]
	for index in positions.size():
		balloon.position = positions[index]
		main.get_node("HUD/DebugPanel").visible = index == 1
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var error: Error = root.get_texture().get_image().save_png("res://.godot/track-preview-%d.png" % index)
		if error != OK:
			push_error("Could not save track preview")
			quit(1)
			return
	print("TRACK VISUAL CAPTURE: PASS")
	quit()
