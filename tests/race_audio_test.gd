extends SceneTree

var failures: int = 0
var events: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func settle() -> void:
	for frame in 40:
		await process_frame


func _run() -> void:
	var music: AudioStreamPlayer = root.get_node("Music")
	music.effect_played.connect(func(effect: String) -> void: events.append(effect))
	check(music.current_theme == "menu", "Startup uses original music")
	var menu_stream: AudioStream = music.stream
	change_scene_to_file("res://scenes/Main.tscn")
	await process_frame
	await process_frame
	var main: Node2D = current_scene
	main.race_flow.set_physics_process(false)
	main.combat.set_physics_process(false)
	for racer in main.competitors:
		racer.set_physics_process(false)
	check(music.current_theme == "menu", "Countdown retains calm music")
	main.race_flow._physics_process(3.1)
	await settle()
	check(music.current_theme == "race" and music.stream != menu_stream and music.playing, "GO switches to distinct race song")
	check(music.stream is AudioStreamMP3 and music.stream.loop and music.stream.get_length() > 0.0, "New race MP3 loops")
	main.balloon._apply_impact(Vector2.LEFT)
	check(events.count("collision") == 1, "Obstacle collision sounds once")
	main.balloon.items.turbo_wait_left = 0.0
	check(main.balloon.items.use_turbo_charge(), "Personal turbo activated")
	check(events.count("turbo") == 1, "Personal turbo has sound")
	check(not main.balloon.items.use_turbo_charge() and events.count("turbo") == 1, "Rejected turbo is silent")
	main.balloon.items.boost_left = 0.0
	main.balloon.items.collect(BalloonItems.Kind.BOOST)
	check(main.balloon.items.use_item() and events.count("turbo") == 2, "Inventory boost shares sound")
	main.balloon.items.receive_hit(main.competitors[1], Vector2.ZERO)
	main.balloon.items.receive_hit(main.competitors[1], Vector2.ZERO)
	check(events.count("collision") == 2, "Protected repeated hit is silent")
	main.combat.launch(main.balloon, BalloonItems.Kind.BOMB)
	var bomb: ItemProjectile = main.combat.get_child(main.combat.get_child_count() - 1)
	bomb.set_physics_process(false)
	bomb.explode()
	bomb.explode()
	check(events.count("explosion") == 1, "Bomb explosion plays once")
	main.combat.launch(main.balloon, BalloonItems.Kind.ROCKET)
	var rocket: ItemProjectile = main.combat.get_child(main.combat.get_child_count() - 1)
	var rival: Balloon = main.competitors[1]
	rival.position = rocket.position + Vector2(100, 0)
	for frame in 20:
		await physics_frame
		await process_frame
	check(events.count("explosion") == 2, "Rocket collision plays explosion")
	music.play_effect("turbo", main.balloon.global_position)
	for frame in 3:
		await physics_frame
		await process_frame
	paused = true
	await process_frame
	check(music.stream_paused, "Music pauses")
	for voice in music._voices:
		check(not voice.can_process(), "Effect players stop processing with gameplay")
		if voice.playing:
			check(voice.stream_paused, "Active effects pause with gameplay")
	var before: int = events.size()
	music.play_effect("turbo", Vector2.ZERO)
	check(events.size() == before, "No effects start while paused")
	paused = false
	for racer in main.competitors:
		racer.position.x = main.track.finish.position.x + 10.0
	main.race_flow._physics_process(0.016)
	await settle()
	check(main.race_flow.state == RaceFlow.State.RESULTS, "Race reaches podium")
	check(music.current_theme == "menu" and music.stream == menu_stream, "Podium restores original music")
	for voice in music._voices:
		check(not voice.playing, "Podium clears gameplay sounds")
	main.race_flow.restart()
	await process_frame
	await process_frame
	check(music.current_theme == "menu", "Restart resets audio to countdown")
	print("RACE AUDIO TEST: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
