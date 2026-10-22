extends SceneTree

var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func _run() -> void:
	var gallery := Node2D.new()
	root.add_child(gallery)
	for row in CharacterCatalog.IDS.size():
		var id: String = CharacterCatalog.IDS[row]
		for column in CharacterCatalog.STATES.size():
			var state: String = CharacterCatalog.STATES[column]
			var path: String = "res://assets/characters/%s/%s_%s.png" % [id, id, state]
			check(ResourceLoader.exists(path), "Required PNG exists: " + path)
			var texture: Texture2D = CharacterCatalog.texture_for(id, state)
			check(texture != null and texture.get_size() == Vector2(384, 512), "RGBA pose dimensions")
			check(texture.get_image().detect_alpha() != Image.ALPHA_NONE, "Pose has transparency")
			var racer: Balloon = load("res://scenes/Balloon.tscn").instantiate()
			racer.character_id = id
			racer.position = Vector2(160 + column * 220, 115 + row * 165)
			gallery.add_child(racer)
			racer.set_physics_process(false)
			racer.visual.set_local_outline(column == 0)
			racer.burner_active = state == "burner"
			racer.items.boost_left = 2.0 if state == "turbo" else 0.0
			racer.impact_time_left = 0.4 if state == "hit" else 0.0
			racer.visual.victory = state == "victory"
			racer.visual.refresh()
			check(racer.visual.current_state == state, "Gameplay selects " + state)
			var sprite: Sprite2D = racer.get_node("Visual/CharacterSprite")
			var shown: String = "idle" if state == "burner" else state
			check(sprite.texture == CharacterCatalog.texture_for(id, shown) and sprite.visible and not racer.get_node("Visual/Artwork").visible, "Only official sprite rendered, with stable normal-flight silhouette")
			var basket := CharacterCatalog.basket_anchor(id, shown)
			var anchor: Vector2 = sprite.transform * (basket - texture.get_size() * 0.5)
			check(anchor.is_equal_approx(Vector2(0, 61)), "Basket anchor remains stable")
			check(racer.get_node("CollisionShape2D").shape.size == Vector2(77.44, 118.8), "Collision shape unchanged")
			check(racer.physics.horizontal_speed == 220 and racer.physics.gravity == 350 and racer.physics.burner_force == 650 and racer.physics.max_vertical_speed == 250, "Physics unchanged")
			var label := Label.new()
			label.text = id + " / " + state
			label.position = racer.position + Vector2(-65, 60)
			label.modulate = Color("243c52")
			gallery.add_child(label)
	await process_frame
	await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/characters-poses.png")
	var fallback: Balloon = load("res://scenes/Balloon.tscn").instantiate()
	fallback.character_id = "invalid"
	fallback.racing = false
	root.add_child(fallback)
	fallback.visual.refresh()
	check(fallback.get_node("Visual/Artwork").visible and not fallback.get_node("Visual/CharacterSprite").visible, "Invalid ID uses geometry without duplicate art")
	check(CharacterCatalog.texture_for("calaca", "missing_state") == CharacterCatalog.texture_for("calaca", "idle"), "Missing pose falls back to idle")
	fallback.queue_free()
	gallery.queue_free()
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	for racer in main.competitors:
		racer.set_physics_process(false)
	main.race_flow.set_physics_process(false)
	main.race_flow._physics_process(3.1)
	main.competitors[1].position.x = main.track.finish.position.x + 1.0
	main.race_flow._physics_process(0.016)
	check(main.competitors[1].visual.current_state == "victory", "Actual first finisher celebrates")
	main.balloon.position.x = main.track.finish.position.x + 1.0
	main.race_flow._physics_process(0.016)
	check(not main.balloon.visual.victory and main.balloon.visual.current_state == "idle", "Other finishers do not celebrate a win")
	main.queue_free()
	await process_frame
	print("CHARACTERS TEST: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
