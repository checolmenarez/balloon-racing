extends SceneTree
## Visual review helper, no gameplay assertions. Run with a rendering window.
func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	root.size = Vector2i(1280,720)
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	main.get_node("RaceFlow").enabled = false
	main.get_node("ItemCombat").enabled = false
	root.add_child(main)
	for racer in main.competitors:
		racer.set_physics_process(false)
	for i in 6:
		var x: float = [1800,3650,7800,10200,14900,17400][i]
		for index in 4:
			main.competitors[index].position = Vector2(x - index * 95, 180 + index * 110)
		for frame in 5:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/valle-preview-s%d.png" % (i+1))
	main.queue_free()
	await process_frame
	quit()
