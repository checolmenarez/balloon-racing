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
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	main.get_node("RaceFlow").enabled = false
	root.add_child(main)
	main.combat.set_physics_process(false)
	for index in 4:
		main.competitors[index].set_physics_process(false)
		main.competitors[index].position = Vector2(1000 + index * 250, 400)
	var source: Balloon = main.competitors[0]
	var target: Balloon = main.competitors[1]
	target.position.y = 370
	source.position = Vector2(1250, 180)
	main.combat.launch(source, BalloonItems.Kind.BOMB)
	var bomb: ItemProjectile = main.combat.get_child(-1)
	await frames(35)
	check(is_instance_valid(bomb) and bomb.exploded and bomb.age < main.combat.config.bomb_fuse, "Bomb detonates on racer before fuse/ground")
	check(target.items.hits_received == 1 and source.items.hits_received == 0, "Contact applies area hit once and preserves owner protection")
	check(bomb.collision_mask == 0 and bomb.collision_layer == 0, "Explosion tail cannot collide")
	bomb.explode()
	check(target.items.hits_received == 1, "Repeated explosion cannot hit again")
	paused = true
	var left: float = bomb.explosion_left
	await frames(4)
	check(bomb.explosion_left == left, "Pause freezes explosion")
	paused = false
	await frames(45)
	check(not is_instance_valid(bomb), "Explosion cleans up")
	main.combat.launch(source, BalloonItems.Kind.BOMB)
	bomb = main.combat.get_child(-1)
	bomb.position = target.position
	await frames(2)
	check(bomb.exploded, "Bomb born overlapping a protected racer also detonates")
	check(target.items.hits_received == 1, "Existing hit protection prevents repeated penalty")
	main.combat.launch(source, BalloonItems.Kind.BOMB)
	var own: ItemProjectile = main.combat.get_child(-1)
	own.position = source.position
	own.age = main.combat.config.owner_protection + 0.1
	await frames(2)
	check(own.exploded and source.items.hits_received == 1, "Owner can trigger contact once grace expires")
	check(is_equal_approx(main.get_node("BalloonVisibility").overlapping_opacity, 0.6), "Overlapping rivals use sixty percent opacity")
	source.items.equipped = BalloonItems.Kind.ROCKET
	TranslationServer.set_locale("es")
	check(source.items.item_name() == "Misil", "Spanish inventory uses Misil")
	main.queue_free()
	await frames(2)
	# Enlarged, controlled gallery to review eyes, hands, missile and blast silhouettes.
	var gallery := Node2D.new()
	root.add_child(gallery)
	for index in 4:
		var racer: Balloon = load("res://scenes/Balloon.tscn").instantiate()
		racer.character_id = CharacterCatalog.IDS[index]
		racer.position = Vector2(180 + index * 300, 290)
		racer.scale = Vector2.ONE * 3.0
		gallery.add_child(racer)
		racer.set_physics_process(false)
		racer.visual.set_process(false)
		racer.visual.refresh()
		racer.visual._time = racer.visual.blink_duration * 0.5 - racer.visual._phase
		racer.visual._process(0)
		check(racer.visual._blink > 0.99, "Blink closes eyes: " + racer.character_id)
		check(racer.visual._arms.length() > 0, "Arms gesture smoothly: " + racer.character_id)
		racer.visual._time = 2.0 - racer.visual._phase
		racer.visual._process(0)
		check(racer.visual._arms.is_zero_approx(), "Arms rest between gestures: " + racer.character_id)
		racer.visual._time = racer.visual.blink_duration * 0.5 - racer.visual._phase
		racer.visual._process(0)
	var combat := ItemCombat.new()
	gallery.add_child(combat)
	combat.set_physics_process(false)
	var shooter: Balloon = gallery.get_child(0)
	for index in 3:
		combat.launch(shooter, BalloonItems.Kind.BOMB if index == 2 else BalloonItems.Kind.ROCKET)
		var projectile: ItemProjectile = combat.get_child(-1)
		projectile.set_physics_process(false)
		projectile.position = Vector2(280 + index * 330, 570)
		if index == 0:
			projectile.scale = Vector2.ONE * 2.5
		else:
			projectile.exploded = true
			projectile.explosion_left = projectile.explosion_duration * 0.7
		projectile.queue_redraw()
	await frames(2)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/arcade-feedback.png")
	gallery.queue_free()
	await frames(2)
	print("ARCADE FEEDBACK TEST: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
