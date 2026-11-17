extends SceneTree

var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func settle() -> void:
	for frame in 4:
		await process_frame


func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await settle()
	event = InputEventKey.new()
	event.keycode = code
	event.pressed = false
	Input.parse_input_event(event)
	await settle()


func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/home-" + label + ".png")


func _run() -> void:
	change_scene_to_file("res://scenes/StartMenu.tscn")
	await settle()
	var home: Control = current_scene
	var buttons: VBoxContainer = home.get_node("Layout/Rows/Buttons")
	check(root.gui_get_focus_owner() == buttons.get_node("Race"), "Race has initial keyboard focus")
	for dimensions in [Vector2i(1280, 720), Vector2i(1280, 800)]:
		root.size = dimensions
		await settle()
		for index in buttons.get_child_count():
			var button: Button = buttons.get_child(index)
			check(button.get_global_rect().end.y < home.size.y, "Buttons fit viewport")
			check(button.get_node("Icon").size.x < 60, "Icon fits its badge")
			check(button.get_node("Icon").texture != null and button.get_theme_stylebox("normal") is StyleBoxTexture, "Independent icon and textured button")
			if index > 0:
				check(not button.get_global_rect().intersects(buttons.get_child(index - 1).get_global_rect()), "Buttons do not overlap")
		await capture(str(dimensions.y))
	await key(KEY_DOWN)
	check(buttons.get_node("FreeFlight").has_focus(), "Free Flight reachable as second main mode")
	await key(KEY_DOWN)
	check(buttons.get_node("Selection").has_focus(), "Selection reachable by keyboard")
	await key(KEY_DOWN)
	check(buttons.get_node("Help").has_focus(), "Arrow navigation reaches next available option")
	await key(KEY_ENTER)
	check(home.get_node("Help").visible, "Keyboard opens help")
	check(home.get_node("Help/Panel/Rows/Instructions").text.contains("SPACE"), "Instructions use current controls")
	await capture("help")
	await key(KEY_ESCAPE)
	check(not home.get_node("Help").visible and buttons.get_node("Help").has_focus(), "Escape restores home focus")
	await key(KEY_TAB)
	check(buttons.get_node("Options").has_focus(), "Tab follows available options")
	# Deliver a real mouse press/release to Options.
	var at: Vector2 = buttons.get_node("Options").get_global_rect().get_center()
	for pressed in [true, false]:
		var click := InputEventMouseButton.new()
		click.position = at
		click.global_position = at
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		Input.parse_input_event(click)
		await settle()
	check(home.get_node("Options").visible, "Mouse opens options")
	var music: Node = root.get_node("Music")
	var saved_music: float = music.audio_level("Music")
	var saved_effects: float = music.audio_level("SFX")
	home.get_node("Options/Panel/Rows/Music").value = 0
	check(music.audio_level("Music") == 0, "Music slider mutes real bus")
	home.get_node("Options/Panel/Rows/Effects").value = 40
	check(is_equal_approx(music.audio_level("SFX"), 0.4), "Effects slider controls separate bus")
	await capture("options")
	music.set_audio_level("Music", saved_music)
	music.set_audio_level("SFX", saved_effects)
	home.get_node("Options/Panel/Rows/Back").pressed.emit()
	await settle()
	check(buttons.get_node("Options").has_focus(), "Back restores originating button")
	buttons.get_node("Selection").pressed.emit()
	await settle()
	check(current_scene.scene_file_path == "res://scenes/CharacterSelect.tscn", "Race opens existing character selection")
	await key(KEY_ESCAPE)
	check(current_scene.scene_file_path == "res://scenes/StartMenu.tscn", "Selection returns to home")
	check(not current_scene.get_node("Layout/Rows/Buttons/Training").visible, "Training remains available in code but is hidden as a main mode")
	current_scene.get_node("Layout/Rows/Buttons/FreeFlight").pressed.emit()
	await settle()
	check(current_scene.scene_file_path == "res://scenes/CharacterSelect.tscn", "Free Flight reuses character selection")
	current_scene.get_node("Center/Rows/Play").pressed.emit()
	await settle()
	check(current_scene.scene_file_path == "res://scenes/SinglePlayer.tscn" and current_scene.find_children("*", "CharacterBody2D", true, false).size() == 1, "Free Flight starts one selected player")
	change_scene_to_file("res://scenes/StartMenu.tscn")
	await settle()
	await key(KEY_ENTER)
	check(current_scene.scene_file_path == "res://scenes/Main.tscn", "Initial focused CTA starts existing race")
	print("HOME TEST: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
