extends SceneTree

var failures: int = 0
var training: Node2D


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func step(count: int = 1) -> void:
	for frame in count:
		await physics_frame
		await process_frame


func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)


func tap(code: Key) -> void:
	key(code, true)
	await step()
	key(code, false)
	await step()


func capture(label: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/training-" + label + ".png")


func _run() -> void:
	root.get_node("RaceSelection").selected = 2
	change_scene_to_file("res://scenes/StartMenu.tscn")
	await step(3)
	check(not current_scene.get_node("Layout/Rows/Buttons/Training").disabled, "Home enables real training")
	current_scene.get_node("Layout/Rows/Buttons/Training").pressed.emit()
	await step(3)
	training = current_scene
	check(training.scene_file_path == "res://scenes/Training.tscn", "Home opens training")
	check(training.combat.competitors.size() == 1 and training.balloon.controller == null, "One human, no bots")
	check(training.find_children("*", "CharacterBody2D", true, false).size() == 1, "Only one balloon body")
	check(training.balloon.physics == load("res://resources/default_balloon_physics.tres"), "Shared unmodified physics")
	check(training.balloon.character_id == "greta" and training.balloon.visual.local_outline_visible, "Selection and local marker retained")
	await capture("start")
	# Passing the first boundary without learning cannot unlock the next lesson.
	training.balloon.position.x = 3801
	await step(3)
	check(training.stage == 0 and training.retries == 1 and training.balloon.position.x < 300, "Missing action resets only current checkpoint")
	# Simulate a human using the actual UP action with inertial anticipation.
	var stage_seen: int = -1
	var paused_projectile: bool = false
	var wind_speed: bool = false
	var boosted_speed: bool = false
	for frame in 6500:
		if training.completed:
			break
		var body: Balloon = training.balloon
		var x: float = body.position.x
		var desired: float = 340
		if training.stage == 0 and x < 450:
			desired = 200
		elif training.stage == 1:
			desired = 330 if x < 5500 else 430
		elif training.stage == 2:
			desired = 540
		elif training.stage == 3:
			desired = 370
		var predicted: float = body.position.y + body.velocity.y * absf(body.velocity.y) / 600.0
		if predicted > desired:
			Input.action_press("burner")
		else:
			Input.action_release("burner")
		if training.stage != stage_seen:
			stage_seen = training.stage
			await capture("stage%d" % (stage_seen + 1))
		if training.stage == 2 and body.items.equipped != BalloonItems.Kind.NONE and x > 9000:
			check(body.items.equipped == BalloonItems.Kind.ROCKET, "Box guarantees rocket")
			await tap(KEY_Z)
			check(body.items.used == 1 and training.combat.get_child_count() == 1, "Z launches existing rocket")
			if not paused_projectile:
				await tap(KEY_ESCAPE)
				var projectile: ItemProjectile = training.combat.get_child(0)
				var snapshot: Array = [body.position, projectile.position, projectile.age, training._feedback_left, training.stage]
				await step(20)
				check(paused and snapshot == [body.position, projectile.position, projectile.age, training._feedback_left, training.stage], "Pause freezes body, projectile, timers and stage")
				await capture("pause")
				training.get_node("HUD/Overlay/PausePanel/Rows/Continue").pressed.emit()
				check(not paused, "Continue button resumes")
				paused_projectile = true
		if training.stage == 3 and body.items.turbo_charges > 0:
			await tap(KEY_SPACE)
			check(body.items.turbo_charges == 0 and body.items.boost_left > 0, "SPACE consumes the lesson charge")
		boosted_speed = boosted_speed or (body.items.boost_left > 0 and body.velocity.x > body.physics.horizontal_speed)
		wind_speed = wind_speed or (body.items.wind_multiplier() > 1 and body.velocity.x > body.physics.horizontal_speed)
		check(body._forward_speed() <= body.physics.horizontal_speed * body.items.config.maximum_speed_bonus + 0.1, "Speed aids never stack")
		await step()
	Input.action_release("burner")
	print("TRAINING ROUTE: stage=%d x=%.0f retries=%d collisions=%d ascent=%s descent=%s target=%s" % [training.stage, training.balloon.position.x, training.retries, training.balloon.collision_count, training.rose, training.descended, training.target_hit])
	check(training.completed and training.stage == 3, "Four lessons completed through real movement and actions")
	check(training.retries == 1, "Route traversable without collisions or extra recovery")
	check(training.target_hit and training.turbo_used and training.wind_crossed and boosted_speed and wind_speed, "Target, personal turbo and full wind crossing verified")
	await capture("complete")
	training.get_node("HUD/Complete/Rows/Race").pressed.emit()
	await step(3)
	check(current_scene.scene_file_path == "res://scenes/Main.tscn" and current_scene.balloon.character_id == "greta", "Completion starts real race with selection")
	check(current_scene.competitors.size() == 4 and current_scene.balloon.items.turbo_charges == 2, "Normal race unchanged")
	change_scene_to_file("res://scenes/Training.tscn")
	await step(3)
	training = current_scene
	# Missed pickup and missed shot can be retried, preserving earlier stages.
	training.stage = 2
	training.retry_stage()
	training.balloon.position.x = 8400
	await step(3)
	check(training.stage == 2 and training.balloon.position.x < 7700, "Missing box recovers stage three")
	training.box._on_body_entered(training.balloon)
	await tap(KEY_Z)
	for projectile in training.combat.get_children():
		projectile.queue_free()
	training.balloon.position.x = 10200
	await step(4)
	check(training.stage == 2 and training.balloon.position.x < 7700 and not training.box.consumed, "Missed shot restores box and checkpoint")
	training.stage = 3
	training.retry_stage()
	await tap(KEY_SPACE)
	training.retry_stage()
	check(training.balloon.items.turbo_charges == 1 and training.balloon.items.boost_left == 0 and training.balloon.items.wind_zones.is_empty(), "Recovery clears effects and restores one charge")
	await tap(KEY_ESCAPE)
	training.get_node("HUD/Overlay/PausePanel/Rows/Restart").pressed.emit()
	await step(4)
	training = current_scene
	check(not paused and training.stage == 0 and training.balloon.items.turbo_charges == 0, "Pause restart resets entire training")
	await tap(KEY_ESCAPE)
	await tap(KEY_ESCAPE)
	check(not paused, "ESC resumes training")
	await tap(KEY_ESCAPE)
	training.get_node("HUD/Overlay/PausePanel/Rows/Home").pressed.emit()
	await step(3)
	check(not paused and current_scene.scene_file_path == "res://scenes/StartMenu.tscn", "Paused Home navigation unpauses")
	print("TRAINING TEST: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
