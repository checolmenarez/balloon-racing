extends SceneTree

var failures: int = 0
var scene: Node2D


func check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	root.get_node("RaceSelection").selected = 2
	root.get_node("RaceSelection").launch_mode = &"free_flight"
	change_scene_to_file("res://scenes/SinglePlayer.tscn")
	await process_frame
	await process_frame
	scene = current_scene
	check(scene != null and scene.scene_file_path == "res://scenes/SinglePlayer.tscn", "Single Player scene loads")
	check(scene.find_children("*", "BotController", true, false).is_empty(), "Starts without bots")
	check(scene.find_children("*", "CharacterBody2D", true, false).size() == 1, "Contains one balloon body")
	check(scene.balloon.character_id == "greta", "Keeps selected character")
	var shared: BalloonPhysics = load("res://resources/default_balloon_physics.tres")
	check(scene.balloon.physics != shared and scene.balloon.physics.gravity == shared.gravity and scene.balloon.physics.burner_force == shared.burner_force and scene.balloon.physics.max_vertical_speed == shared.max_vertical_speed, "Shares vertical flight values without mutating race resource")
	check(scene.balloon.physics.horizontal_speed == scene.config.initial_speed and shared.horizontal_speed == 220.0, "Single Player speed is isolated from Race")
	check(not scene.has_node("ItemCombat") and scene.find_children("*", "ItemBox", true, false).is_empty(), "Has no competitive boxes or combat")
	check(scene.segments.active_segments.size() <= scene.config.segments_ahead + 1, "Initial segment window is bounded")
	check(scene.active_seed > 0, "A normal attempt receives a valid generated seed")
	_check_generation()
	_check_collectibles()
	_check_health()
	_check_speed()
	_check_persistence()
	await _check_long_run()
	await _check_home()
	_check_pause_and_game_over()
	print("SINGLE PLAYER TEST: failures=", failures)
	quit(failures)


func _check_generation() -> void:
	var config: SinglePlayerConfig = scene.config
	var manager_a := SinglePlayerSegmentManager.new()
	var manager_b := SinglePlayerSegmentManager.new()
	root.add_child(manager_a)
	root.add_child(manager_b)
	manager_a.setup(config, 12345)
	manager_b.setup(config, 12345)
	check(manager_a.generated_signatures == manager_b.generated_signatures, "Fixed seed reproduces segment sequence")
	for segment: Node2D in manager_a.active_segments.values():
		var gap := float(segment.get_meta("minimum_gap"))
		var start_y := float(segment.get_meta("safe_start_y"))
		var end_y := float(segment.get_meta("safe_end_y"))
		var route: PackedVector2Array = segment.get_meta("safe_route")
		var clears_balloon := gap >= Balloon.TOP_EXTENT + Balloon.BOTTOM_EXTENT + 70.0
		var connects_edges := not route.is_empty() and is_equal_approx(route[0].y, start_y) and is_equal_approx(route[-1].y, end_y)
		check(clears_balloon and connects_edges, "Segment exposes a passable, bounded route")
	manager_a.queue_free()
	manager_b.queue_free()


func _check_collectibles() -> void:
	scene._start_attempt()
	var effect_count := [0]
	var on_effect := func(effect: String) -> void:
		if effect == "coin": effect_count[0] += 1
	root.get_node("Music").effect_played.connect(on_effect)
	var coins: Array[Node] = scene.segments.find_children("*", "SinglePlayerCoin", true, false)
	check(not coins.is_empty(), "Segments contain collectible coin rows")
	var first := coins[0] as SinglePlayerCoin
	first._on_body_entered(scene.balloon)
	first._on_body_entered(scene.balloon)
	check(scene.coins == 1, "A coin increments the counter once")
	check(effect_count[0] == 1, "Every accepted coin requests one audio event")
	for index in range(1, mini(6, coins.size())):
		(coins[index] as SinglePlayerCoin)._on_body_entered(scene.balloon)
	check(scene.coins == mini(6, coins.size()) and effect_count[0] == mini(6, coins.size()), "Consecutive coins lose neither counter nor audio events")
	root.get_node("Music").effect_played.disconnect(on_effect)


func _check_health() -> void:
	scene.health.reset(100, 1.0)
	var collisions_before: int = scene.balloon.collision_count
	scene._last_collision_count = collisions_before
	scene.balloon.collision_count += 1
	scene._physics_process(0.0)
	check(scene.health.current_health == 75, "Accepted balloon collision reaches Single Player health")
	scene._physics_process(0.0)
	check(scene.health.current_health == 75, "One collision event is not applied twice")
	scene.health.reset(100, 1.0)
	check(scene.health.damage(25) and scene.health.current_health == 75, "Collision damage reduces health exactly")
	check(not scene.health.damage(25) and scene.health.current_health == 75, "Protection rejects continuous damage")
	scene.health.tick(1.01)
	check(scene.health.damage(25) and scene.health.current_health == 50, "Damage works after protection expires")
	var star := load("res://scenes/MagicStar.tscn").instantiate() as MagicStar
	scene.add_child(star)
	var star_audio := [0]
	var on_effect := func(effect: String) -> void:
		if effect == "magic_star": star_audio[0] += 1
	root.get_node("Music").effect_played.connect(on_effect)
	scene._collect_star(star)
	check(scene.health.current_health == 70 and star_audio[0] == 1, "Magic Star heals and requests distinct audio feedback")
	root.get_node("Music").effect_played.disconnect(on_effect)
	star.queue_free()
	check(scene.health.heal(200) == 30 and scene.health.current_health == 100, "Health never exceeds maximum")


func _check_speed() -> void:
	scene.balloon.position.x = 240.0 + scene.config.progression_interval * 4.0
	var before: float = scene.current_speed
	for index in 30:
		scene._physics_process(1.0 / 60.0)
	check(scene.current_speed > before, "Horizontal speed increases smoothly with distance")
	scene.distance = 1000000.0
	for index in 240:
		scene._physics_process(1.0 / 60.0)
	check(scene.current_speed <= scene.config.initial_speed * scene.config.maximum_speed_multiplier, "Horizontal speed respects configured maximum")


func _check_persistence() -> void:
	var path := "res://.godot/single_player_test.cfg"
	var progress := SinglePlayerSave.new()
	check(progress.register_attempt(1234.0, 17, path), "First result creates a distance record")
	var loaded := SinglePlayerSave.new()
	loaded.load_data(path)
	check(loaded.best_distance == 1234.0 and loaded.best_coins == 17 and loaded.total_coins == 17, "Records and accumulated coins persist")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("not a valid config")
	file.close()
	loaded.load_data(path)
	check(loaded.best_distance == 0.0 and loaded.total_coins == 0, "Invalid save falls back to safe defaults")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _check_long_run() -> void:
	var manager := SinglePlayerSegmentManager.new()
	root.add_child(manager)
	manager.setup(scene.config, 9090)
	var start_usec := Time.get_ticks_usec()
	for index in 180:
		manager.ensure_segments(index * scene.config.segment_length)
		if index % 20 == 0:
			await process_frame
	await process_frame
	var elapsed_ms := (Time.get_ticks_usec() - start_usec) / 1000.0
	check(manager.active_segments.size() <= scene.config.segments_ahead + scene.config.segments_behind + 1, "Long simulation keeps a bounded segment window")
	check(manager.active_collectible_count() < 100, "Long simulation keeps collectibles bounded")
	check(manager.generated_signatures.size() <= 64, "Generation diagnostics remain bounded")
	print("SINGLE PLAYER GENERATION BENCHMARK: 180 segments in %.2f ms; active=%d collectibles=%d" % [elapsed_ms, manager.active_segments.size(), manager.active_collectible_count()])
	manager.queue_free()


func _check_home() -> void:
	var home: Node = load("res://scenes/StartMenu.tscn").instantiate()
	root.add_child(home)
	await process_frame
	check(home.get_node("Layout/Rows/Buttons/FreeFlight").visible, "Home exposes Free Flight as a main mode")
	check(not home.get_node("Layout/Rows/Buttons/Training").visible, "Training is no longer a main visible mode")
	home.queue_free()


func _check_pause_and_game_over() -> void:
	scene._toggle_pause()
	check(paused and scene.pause_panel.visible, "Pause freezes the Single Player tree")
	scene._resume()
	check(not paused and not scene.pause_panel.visible, "Continue resumes the attempt")
	scene.distance = 4321.0
	scene.survival_time = 75.0
	scene._finish_attempt()
	var frozen := [scene.distance, scene.survival_time, scene.coins]
	scene._physics_process(1.0)
	scene._finish_attempt()
	check(scene.game_over and scene.game_over_panel.visible and frozen == [scene.distance, scene.survival_time, scene.coins], "Game Over occurs once and freezes result values")
	check(not scene.segments.generation_enabled and not scene.balloon.racing, "Game Over stops generation and collection")
