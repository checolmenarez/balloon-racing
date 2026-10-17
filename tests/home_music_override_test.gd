extends SceneTree


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	# Replace the autoload only in this isolated test, never run two music players.
	root.get_node("Music").queue_free()
	await process_frame
	var player := load("res://scenes/Music.tscn").instantiate() as AudioStreamPlayer
	var fixture := load("res://assets/audio/carrera.wav") as AudioStreamWAV
	player.home_music = fixture
	root.add_child(player)
	assert(player.playing and player.current_theme == "menu")
	assert(player.stream != fixture, "Loop configuration does not mutate source resource")
	assert(is_equal_approx(player.stream.get_length(), fixture.get_length()))
	assert(player.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD)
	var saved: float = player.audio_level("Music")
	player.set_audio_level("Music", 0.0)
	for frame in 40:
		await process_frame
	assert(player.audio_level("Music") == 0.0, "Fade never overrides user mute")
	var position: float = player.get_playback_position()
	player.set_theme("menu")
	assert(player.get_playback_position() >= position, "Same theme continues playing")
	player.set_audio_level("Music", saved)
	player.queue_free()
	await process_frame
	print("HOME MUSIC OVERRIDE TEST: PASS (existing WAV used only as test fixture)")
	quit()
