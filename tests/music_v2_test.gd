extends SceneTree

var failures: int = 0


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
	check(music.home_music.resource_path == "res://assets/audio/music_home_v2.mp3", "New Home resource configured")
	check(music.race_music.size() == 2, "Both supplied race tracks configured")
	var tracks: Array = [music._themes.menu]
	tracks.append_array(music._race_tracks)
	for track in tracks:
		check(track is AudioStreamMP3 and track.loop, "Private MP3 stream is looped")
		var playback: AudioStreamPlayback = track.instantiate_playback()
		playback.start(maxf(0.0, track.get_length() - 0.02))
		var samples: PackedVector2Array = playback.mix_audio(1.0, 16384)
		check(samples.size() == 16384 and playback.get_loop_count() > 0, "MP3 decoder crosses loop boundary")
		playback.stop()
	var saved: float = music.audio_level("Music")
	music.set_audio_level("Music", 0.0)
	change_scene_to_file("res://scenes/StartMenu.tscn")
	await settle()
	var home_stream: AudioStream = music.stream
	current_scene.get_node("Layout/Rows/Buttons/Selection").pressed.emit()
	await settle()
	check(music.stream == home_stream, "Home to selection keeps current song")
	current_scene.get_node("Center/Rows/Play").pressed.emit()
	await process_frame
	await process_frame
	var main: Node = current_scene
	main.race_flow.set_physics_process(false)
	main.combat.set_physics_process(false)
	for racer in main.competitors:
		racer.set_physics_process(false)
	main.race_flow._physics_process(3.1)
	await settle()
	var race_stream: AudioStream = music.stream
	check(music.current_theme == "race" and race_stream in music._race_tracks, "GO plays a new race MP3")
	var transition: Tween = music._transition
	for repeat in 10:
		music.set_theme("race")
	check(music.stream == race_stream and music._transition == transition, "In-progress race never rerolls or restarts")
	check(music.audio_level("Music") == 0.0, "Transitions preserve player mute")
	for racer in main.competitors:
		racer.position.x = main.track.finish.position.x + 10
	main.race_flow._physics_process(0.016)
	await settle()
	check(main.race_flow.state == RaceFlow.State.RESULTS and music.stream == home_stream, "Podium restores new Home song")
	main.get_node("HUD/RaceOverlay/Results/Rows/Home").pressed.emit()
	await settle()
	check(current_scene.scene_file_path == "res://scenes/StartMenu.tscn" and music.stream == home_stream, "Podium to Home preserves music")
	music._music_rng.seed = 42
	var chosen: Array[AudioStream] = []
	for race in 32:
		music.set_theme("race")
		if music._themes.race not in chosen:
			chosen.append(music._themes.race)
		music.set_theme("menu")
	check(chosen.size() == 2, "Independent race starts can choose both tracks")
	# One-entry configuration also works without a second song.
	var original_tracks: Array = music._race_tracks.duplicate()
	music._race_tracks.resize(1)
	music.set_theme("race")
	await settle()
	check(music.stream == original_tracks[0], "Single-track configuration works")
	music._race_tracks.assign(original_tracks)
	music.set_theme("menu")
	await settle()
	check(music.stream == home_stream and is_equal_approx(music.volume_db, music._music_volume), "Interrupted fades settle at correct stream and gain")
	music.set_audio_level("Music", 0.35)
	check(is_equal_approx(music.audio_level("Music"), 0.35), "Volume control remains independent of fade")
	music.set_audio_level("Music", saved)
	check(root.get_node("Music") == music and music.get_children().size() == 8, "Same single music player and eight SFX voices")
	print("MUSIC V2 TEST: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
