extends SceneTree

func _initialize() -> void:
	_run.call_deferred()


func _capture(label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/m5-%s.png" % label)


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	main.get_node("RaceFlow").enabled = false # Isolate flight/items from lifecycle.
	root.add_child(main)
	main.combat.set_physics_process(false)
	for racer in main.competitors:
		racer.set_physics_process(false)
	main.balloon.position = Vector2(240, 350)
	main.competitors[1].position = Vector2(620, 350)
	main.competitors[2].position = Vector2(760, 450)
	main.competitors[3].position = Vector2(850, 250)
	var box: Area2D = load("res://scenes/ItemBox.tscn").instantiate()
	box.position = Vector2(480, 350)
	box.combat = main.combat
	main.add_child(box)
	main.balloon.items.collect(BalloonItems.Kind.ROCKET)
	await _capture("box-inventory")
	main.balloon.items.use_item()
	await _capture("rocket")
	main.balloon.items.collect(BalloonItems.Kind.BOMB)
	main.balloon.items.use_item()
	var bomb: ItemProjectile = main.combat.get_child(main.combat.get_child_count() - 1)
	bomb.global_position = Vector2(620, 430)
	bomb.age = 0.5
	bomb.explode()
	main.competitors[1]._update_impact(0.0)
	await _capture("bomb")
	main.balloon.items.collect(BalloonItems.Kind.BOOST)
	main.balloon.items.use_item()
	main.balloon.visual.refresh()
	main.get_node("HUD/DebugPanel").visible = true
	await _capture("boost-debug")
	print("ITEMS VISUAL: PASS")
	quit()
