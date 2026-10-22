extends SceneTree

var failures: int = 0
var main: Node2D
var combat: ItemCombat
var racers: Array[Balloon]


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func _start() -> void:
	main = load("res://scenes/Main.tscn").instantiate()
	main.get_node("RaceFlow").enabled = false # Isolate flight/items from lifecycle.
	root.add_child(main)
	combat = main.get_node("ItemCombat")
	combat.set_physics_process(false)
	combat.config = combat.config.duplicate()
	combat.config.storm_probability_by_place = Vector4.ZERO # Isolate original three objects.
	combat.rng.seed = 1234
	racers = main.competitors
	for index in racers.size():
		racers[index].set_physics_process(false)
		racers[index].position = Vector2(-1000 - index * 200, 350)
		racers[index].items.config = combat.config


func _step(seconds: float) -> void:
	for frame in ceili(seconds * Engine.physics_ticks_per_second):
		await physics_frame
		await process_frame


func _finish() -> void:
	main.queue_free()
	await process_frame
	await physics_frame


func _pickup_test() -> void:
	_start()
	combat.config.selection_weights = Vector3(1, 0, 0)
	racers[0].position = Vector2(1200, 310)
	await _step(0.1)
	_check(racers[0].items.equipped == BalloonItems.Kind.ROCKET, "Area box grants weighted item")
	_check(racers[0].items.collected == 1, "Box consumed once")
	var extra: Area2D = load("res://scenes/ItemBox.tscn").instantiate()
	extra.position = racers[0].position
	extra.combat = combat
	main.add_child(extra)
	await _step(0.1)
	_check(not extra.consumed and racers[0].items.collected == 1, "Full inventory leaves box intact")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_A
	key.pressed = true
	Input.parse_input_event(key)
	await _step(0.05)
	_check(racers[0].items.equipped == BalloonItems.Kind.NONE and racers[0].items.used == 1, "A uses and empties inventory")
	racers[0].position.x += 200
	await _step(0.1)
	racers[0].position = extra.position
	await _step(0.1)
	_check(extra.consumed and racers[0].items.collected == 2, "Can collect again after use")
	# Exercise all weighted outcomes without statistical/flaky assertions.
	combat.config.selection_weights = Vector3(0, 1, 0)
	_check(combat.choose_item() == BalloonItems.Kind.BOMB, "Bomb probability weight")
	combat.config.selection_weights = Vector3(0, 0, 1)
	_check(combat.choose_item() == BalloonItems.Kind.BOOST, "Boost probability weight")
	await _finish()


func _rocket_test() -> void:
	_start()
	racers[0].position = Vector2(300, 350)
	racers[1].position = Vector2(600, 350)
	racers[0].items.collect(BalloonItems.Kind.ROCKET)
	racers[0].items.use_item()
	await _step(0.6)
	_check(racers[1].items.hits_received == 1 and racers[0].items.hits_received == 0, "Rocket hits rival, not owner")
	_check(racers[0].items.hits_dealt == 1, "Missile applies a single hit")
	_check(is_equal_approx(racers[1]._forward_speed(), 132.0), "Rocket penalty applies to base speed")
	await _step(0.4)
	_check(combat.get_child_count() == 0, "Missile visual tail expires")
	racers[0].position = Vector2(1600, 550)
	racers[1].position = Vector2(2200, 550)
	racers[0].items.collect(BalloonItems.Kind.ROCKET)
	racers[0].items.use_item()
	await _step(1.0)
	_check(racers[1].items.hits_received == 1 and combat.get_child_count() == 0, "Obstacle stops rocket")
	racers[0].position = Vector2(20000, 350)
	racers[0].items.collect(BalloonItems.Kind.ROCKET)
	racers[0].items.use_item()
	await _step(2.7)
	_check(combat.get_child_count() == 0, "Rocket lifetime is bounded")
	await _finish()


func _bomb_test() -> void:
	_start()
	racers[0].position = Vector2(1000, 220)
	racers[1].position = Vector2(1000, 540)
	racers[2].position = Vector2(1350, 540)
	racers[0].items.collect(BalloonItems.Kind.BOMB)
	racers[0].items.use_item()
	await _step(1.3)
	_check(racers[1].items.hits_received == 1 and racers[2].items.hits_received == 0, "Contact explosion respects radius")
	_check(racers[1].velocity.y > 0.0, "Contact above rival pushes away from the blast")
	await _finish()
	_start()
	combat.config.bomb_gravity = 0.0
	combat.config.bomb_fuse = 0.2
	racers[0].position = Vector2(1000, 350)
	racers[1].position = Vector2(1000, 490)
	racers[0].items.collect(BalloonItems.Kind.BOMB)
	racers[0].items.use_item()
	await _step(0.3)
	_check(racers[0].items.hits_received == 0 and racers[1].items.hits_received == 1, "Fuse explosion and initial owner protection")
	await _finish()


func _boost_test() -> void:
	_start()
	for index in racers.size():
		racers[index].position = Vector2(20000 + (0 if index == 0 else 70), 150 + index * 140)
		racers[index].controller = null
		racers[index].set_physics_process(true)
	racers[0].items.collect(BalloonItems.Kind.BOOST)
	racers[0].items.use_item()
	await _step(1.2)
	_check(is_equal_approx(racers[0].velocity.x, 297.0), "Boost increases actual speed")
	_check(main.standings.get_place(racers[0]) == 1, "Boost produces a real overtake")
	racers[0].items.receive_hit(racers[1], Vector2.ZERO)
	await _step(0.05)
	_check(is_equal_approx(racers[0].velocity.x, 178.2), "Boost and weapon penalty multiply")
	racers[0]._apply_impact(Vector2.LEFT)
	await _step(0.05)
	_check(racers[0].velocity.x < 178.2, "Obstacle penalty also coexists")
	await _step(1.3)
	_check(is_equal_approx(racers[0].velocity.x, 220.0), "All modifiers expire without changing base")
	_check(racers[0].physics.horizontal_speed == 220.0 and racers[0].visual.modulate.a == 1.0, "Base resource and local opacity preserved")
	await _finish()


func _bot_test() -> void:
	for kind in [BalloonItems.Kind.ROCKET, BalloonItems.Kind.BOMB, BalloonItems.Kind.BOOST]:
		_start()
		var bot: Balloon = racers[int(kind)]
		bot.position = Vector2(20000, 300)
		racers[0].position = bot.position + (Vector2(250, 0) if kind == BalloonItems.Kind.ROCKET else Vector2(0, 160))
		combat.config.selection_weights = Vector3(1 if kind == 1 else 0, 1 if kind == 2 else 0, 1 if kind == 3 else 0)
		var box: Area2D = load("res://scenes/ItemBox.tscn").instantiate()
		box.position = bot.position
		box.combat = combat
		main.add_child(box)
		await _step(0.1)
		_check(bot.items.collected == 1, "Bot collects real box")
		_check(combat.bot_should_use(bot), "Bot recognizes tactical use condition")
		combat.set_physics_process(true)
		await _step(0.4)
		_check(bot.items.used == 1 and bot.items.equipped == BalloonItems.Kind.NONE, "Bot automatically uses item")
		await _finish()


func _race_test() -> void:
	_start()
	main.queue_free()
	await process_frame
	main = load("res://scenes/Main.tscn").instantiate()
	main.get_node("RaceFlow").enabled = false # Isolate flight/items from lifecycle.
	root.add_child(main)
	main.combat.rng.seed = 42
	for frame in Engine.physics_ticks_per_second * 100:
		await physics_frame
		await process_frame
		if main.balloon.items.equipped != BalloonItems.Kind.NONE:
			main.balloon.items.use_item()
	var pickups: int = 0
	var uses: int = 0
	for racer in main.competitors:
		_check(racer.position.x >= 18400.0, "Full M5 race reaches finish")
		pickups += racer.items.collected
		uses += racer.items.used
		print("M5 %s: collected=%d used=%d hits=%d" % [racer.competitor_name, racer.items.collected, racer.items.used, racer.items.hits_received])
	_check(pickups > 0 and uses > 0, "Real track boxes participate in race")
	await _finish()


func _run() -> void:
	if not OS.get_cmdline_user_args().is_empty():
		Engine.physics_ticks_per_second = int(OS.get_cmdline_user_args()[0])
	await _pickup_test()
	await _rocket_test()
	await _bomb_test()
	await _boost_test()
	await _bot_test()
	await _race_test()
	print("ITEMS TEST: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
