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
		await physics_frame
		await process_frame


func _run() -> void:
	TranslationServer.set_locale("es")
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	var player: Balloon = main.balloon
	var hud: Label = main.item_label
	var overlay: Control = main.get_node("HUD/RaceOverlay")
	main.combat.set_physics_process(false)
	main.race_flow.set_physics_process(false)
	for racer in main.competitors:
		racer.set_physics_process(false)
	var initial: Vector2 = player.position
	await frames(50)
	check(player.position == initial and player.visual.position.is_zero_approx(), "Entry returns visual to origin without moving body")
	check(main.standings.get_place(player) == 1 and main.race_flow.elapsed == 0, "Presentation preserves starting order and timer")
	main.race_flow._physics_process(2.9)
	check(not player.racing, "Presentation never starts race early")
	main.race_flow._physics_process(0.1)
	check(player.racing and main.race_flow.elapsed == 0, "GO uses original countdown boundary")
	check(overlay.get_node("PausePanel/Rows/Home").visible, "Race pause exposes existing Home button")
	var state: int = main.combat.rng.state
	player.items.collect(BalloonItems.Kind.BOMB)
	await frames(1)
	check(hud.roulette_left > 0 and "Bomba" in hud.text, "Roulette starts while real item name is already visible")
	paused = true
	var roulette: float = hud.roulette_left
	var countdown_alpha: float = overlay.countdown.modulate.a
	var visual_position: Vector2 = player.visual.position
	await frames(10)
	check(hud.roulette_left == roulette, "Pause freezes roulette")
	check(overlay.countdown.modulate.a == countdown_alpha and player.visual.position == visual_position, "Pause freezes countdown tween and visual motion")
	paused = false
	check(player.items.use_item(), "Item usable before roulette ends")
	await frames(1)
	check(hud.roulette_left == 0 and hud.displayed_kind == BalloonItems.Kind.NONE and "Vacío" in hud.text, "Early use cancels roulette without stale inventory")
	player.items.collect(BalloonItems.Kind.ROCKET)
	await frames(40)
	check(hud.displayed_kind == BalloonItems.Kind.ROCKET and hud.roulette_left == 0, "Roulette settles on actual assigned item")
	check(main.combat.rng.state == state, "Presentation consumes no gameplay RNG")
	player.items.initialize_turbo(2, 0)
	check(player.items.use_turbo_charge(), "Personal turbo still works")
	await frames(1)
	check("Turbo: 1" in hud.text, "HUD reflects consumed charge")
	var shape: Shape2D = player.get_node("CollisionShape2D").shape
	var transform_before: Transform2D = player.get_node("CollisionShape2D").transform
	player.items.receive_hit(main.competitors[1], Vector2.ZERO)
	await frames(3)
	check(player.visual._shake_left > 0, "Accepted impact starts bounded visual reaction")
	await frames(25)
	check(player.visual.position.is_zero_approx(), "Reaction settles without drift")
	check(player.get_node("CollisionShape2D").shape == shape and player.get_node("CollisionShape2D").transform == transform_before, "Visual reactions never modify collider")
	player.items.storm_protection_left = 0
	player.items.tick(player.items.config.boost_duration)
	check(player.items.warn_storm(main.competitors[1]), "Storm warning accepted")
	player.items.tick(player.items.config.storm_warning)
	player.visual.refresh()
	check(player.visual.current_state == "hit" and player.items.storm_left == player.items.config.storm_duration, "Storm impact selects reaction with original duration")
	check(player.items.speed_multiplier() == player.items.config.storm_multiplier, "Storm power unchanged")
	main.combat.launch(player, BalloonItems.Kind.BOMB)
	var bomb: ItemProjectile = main.combat.get_child(main.combat.get_child_count() - 1)
	if not bomb.exploded:
		bomb.explode()
	check(bomb.collision_mask == 0 and bomb.collision_layer == 0, "Explosion tail has no collision")
	var hits: int = player.items.hits_received
	bomb.explode()
	check(player.items.hits_received == hits, "Repeated explosion cannot apply damage again")
	for id in CharacterCatalog.IDS:
		player.character_id = id
		player.items.storm_left = 0
		player.items.hit_left = 0
		player.items.boost_left = 0
		for pose in [false, true, false]:
			player.burner_active = pose
			player.visual.refresh()
			await frames(10)
			var sprite: Sprite2D = player.get_node("Visual/CharacterSprite")
			var anchor: Vector2 = CharacterCatalog.basket_anchor(id, player.visual.current_state)
			check((sprite.transform * (anchor - sprite.texture.get_size() * 0.5)).is_equal_approx(Vector2(0, 61)), "Settled basket anchor: " + id)
	TranslationServer.set_locale("en")
	await frames(1)
	check(TranslationServer.translate("¡YA!") == "GO!" and TranslationServer.translate("Mantén ↑ para subir") == "Hold ↑ to rise", "English race and training catalog registered")
	check("Rocket" in hud.text, "Dynamic HUD uses active locale")
	TranslationServer.set_locale("es")
	check(TranslationServer.translate("¡YA!") == "¡YA!", "Spanish catalog registered")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/m72-hud.png")
	paused = true
	overlay._home()
	await frames(3)
	check(not paused and current_scene.scene_file_path == "res://scenes/StartMenu.tscn", "Pause Home clears session and pause")
	current_scene.queue_free()
	await process_frame
	print("POLISH TEST: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
