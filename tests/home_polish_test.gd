extends SceneTree

var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func _run() -> void:
	var original_snap := root.gui_snap_controls_to_pixels
	change_scene_to_file("res://scenes/StartMenu.tscn")
	for frame in 4:
		await process_frame
	var home: Control = current_scene
	check(not root.gui_snap_controls_to_pixels, "Home disables GUI pixel quantization")
	var music: AudioStreamPlayer = root.get_node("Music")
	var stream: AudioStream = music.stream
	var before: float = music.get_playback_position()
	music.set_theme("menu")
	check(music.stream == stream and music.get_playback_position() >= before, "Same theme never restarts")
	var body: Font = home.get_node("Layout/Rows/Hint").get_theme_font("font")
	var title: Font = home.get_node("Layout/Rows/Buttons/Race").get_theme_font("font")
	check(body.get_font_name().contains("Fredoka"), "Global body font resolves to Fredoka")
	check(title.get_font_name().contains("Lilita"), "CTA uses Lilita")
	for font in [body, title]:
		for letter in "áéíóúüñÁÉÍÓÚÜÑ¡¿ºª0123456789":
			check(font.has_char(letter.unicode_at(0)), "Spanish/rank glyph: " + letter)
	var elapsed: float = 0.0
	var character: TextureRect = home.get_node("Characters/Calaca")
	var previous: float = character.offset_top
	var previous_time: float = home._time
	var base_size: Vector2 = character.size
	var fractional_steps: int = 0
	while elapsed < 30.0:
		await process_frame
		# process_frame fires before nodes process: compare the sampled animation times.
		var delta: float = home._time - previous_time
		previous_time = home._time
		elapsed += delta
		var step: float = absf(character.offset_top - previous)
		# A 6px, 3.4s sine has a maximum speed of 11.09px/s.
		check(step <= 12.0 * delta + 0.01, "Continuous motion across cycle boundaries")
		check(character.size.is_equal_approx(base_size), "No size drift")
		if step > 0.0001 and step < 0.9:
			fractional_steps += 1
		previous = character.offset_top
	check(fractional_steps > 100, "Subpixel samples preserved for 30 seconds")
	for dimensions in [Vector2i(1280, 720), Vector2i(1280, 800)]:
		root.size = dimensions
		for frame in 4:
			await process_frame
		var buttons: Control = home.get_node("Layout/Rows/Buttons")
		var logo: Control = home.get_node("Layout/Rows/Logo")
		for balloon in home.get_node("Characters").get_children():
			check(not balloon.get_global_rect().grow(10).intersects(buttons.get_global_rect()), "Balloon clears buttons and sway margin")
			check(not balloon.get_global_rect().grow(10).intersects(logo.get_global_rect()), "Balloon clears logo")
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://.godot/home-v21-%d.png" % dimensions.y)
	home.reduce_motion = true
	for frame in 3:
		await process_frame
	var still: float = character.offset_top
	await process_frame
	check(character.offset_top == still and character.rotation == 0, "Reduced motion is static")
	check(is_equal_approx(music.volume_db, music._music_volume), "Startup fade reaches configured gain")
	var saved_level: float = music.audio_level("Music")
	music.set_audio_level("Music", 0)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "Mute persists through fade")
	music.set_audio_level("Music", saved_level)
	var old_home: WeakRef = weakref(home)
	change_scene_to_file("res://scenes/CharacterSelect.tscn")
	for frame in 4:
		await process_frame
	check(root.gui_snap_controls_to_pixels == original_snap, "Leaving restores viewport setting")
	check(old_home.get_ref() == null, "Home and bound tweens are released")
	check(root.get_node("Music") == music and music.stream == stream, "Navigation reuses single music player")
	print("HOME POLISH TEST: %s (%d failures), 30 seconds sampled" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
