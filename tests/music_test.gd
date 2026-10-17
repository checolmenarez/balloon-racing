extends SceneTree


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var music: AudioStreamPlayer = root.get_node("Music")
	assert(music.playing, "Music starts automatically")
	var stream := music.stream as AudioStreamMP3
	assert(stream != null and stream.loop)
	var expected: AudioStream = music.home_music if music.home_music != null else load("res://assets/audio/valle_ventoso.wav")
	assert(is_equal_approx(stream.get_length(), expected.get_length()))
	assert(stream.get_length() > 0.0)
	change_scene_to_file("res://scenes/StartMenu.tscn")
	await process_frame
	await process_frame
	change_scene_to_file("res://scenes/Main.tscn")
	await process_frame
	await process_frame
	assert(root.get_node("Music") == music and music.stream == stream and music.playing)
	paused = true
	await process_frame
	assert(music.stream_paused, "Race pause also pauses music")
	paused = false
	await process_frame
	assert(not music.stream_paused and music.playing, "Music resumes")
	reload_current_scene()
	await process_frame
	await process_frame
	assert(root.get_node("Music") == music and music.stream == stream and music.playing)
	print("MUSIC TEST: PASS")
	quit()
