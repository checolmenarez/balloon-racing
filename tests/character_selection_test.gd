extends SceneTree

var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func settle(frames: int = 14) -> void:
	for frame in frames:
		await process_frame


func key(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await settle()


func joy(code: JoyButton) -> void:
	for pressed in [true, false]:
		var event := InputEventJoypadButton.new()
		event.button_index = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await settle()


func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.get_node("RaceSelection").selected = 99
	root.get_node("RaceSelection").launch_mode = &"race"
	change_scene_to_file("res://scenes/CharacterSelect.tscn")
	await settle()
	var menu: Control = current_scene
	var choices: HBoxContainer = menu.get_node("Center/Rows/Choices")
	check(root.get_node("RaceSelection").selected == 0, "Invalid selection defaults to Calaca")
	check(choices.get_child(0).has_focus(), "Current card has initial focus")
	for index in 4:
		var button: Button = choices.get_child(index)
		var point := button.get_global_rect().get_center()
		var motion := InputEventMouseMotion.new()
		motion.position = point
		motion.global_position = point
		Input.parse_input_event(motion)
		await settle()
		for pressed in [true, false]:
			var click := InputEventMouseButton.new()
			click.position = point
			click.global_position = point
			click.button_index = MOUSE_BUTTON_LEFT
			click.pressed = pressed
			Input.parse_input_event(click)
			await settle()
		var profile: Dictionary = SelectionProfiles.DATA[index]
		var text: VBoxContainer = menu.get_node("Center/Rows/Details/Content/Text")
		check(root.get_node("RaceSelection").selected == index and button.button_pressed, "Mouse selects card")
		for field in ["Name", "Subtitle", "Description"]:
			var property: String = {"Name": "display_name", "Subtitle": "subtitle", "Description": "description"}[field]
			check(text.get_node(field).text == profile[property], "Detail field updates: " + field)
		for tag in 3:
			check(text.get_node("Tags").get_child(tag).text == profile.tags[tag], "Tags update")
		check(button.get_child(0).get_node("Portrait").texture.resource_path == profile.art_texture, "Correct supplied artwork mapping")
	await key(KEY_RIGHT)
	check(root.get_node("RaceSelection").selected == 0, "Right wraps to first card")
	await key(KEY_LEFT)
	check(root.get_node("RaceSelection").selected == 3, "Left wraps to last card")
	await joy(JOY_BUTTON_DPAD_LEFT)
	check(root.get_node("RaceSelection").selected == 2, "Gamepad D-pad selects Greta")
	await joy(JOY_BUTTON_A)
	check(choices.get_child(2).button_pressed, "Gamepad accept retains selected card")
	await key(KEY_TAB)
	await key(KEY_TAB)
	check(menu.get_node("Center/Rows/Play").has_focus(), "Tab reaches CTA")
	for dimensions in [Vector2i(1280, 720), Vector2i(1280, 800), Vector2i(1600, 900)]:
		root.size = dimensions
		await settle()
		check(menu.get_global_rect().encloses(menu.get_node("Center/Rows").get_global_rect()), "All UI fits viewport")
		check(not choices.get_global_rect().intersects(menu.get_node("Center/Rows/Details").get_global_rect()), "Cards and details separated")
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://.godot/character-selection-%d.png" % dimensions.y)
	await key(KEY_ENTER)
	check(current_scene.scene_file_path == "res://scenes/Main.tscn", "Enter starts existing race")
	check(current_scene.balloon.character_id == "pomposo", "Tab selection is retained in race")
	change_scene_to_file("res://scenes/CharacterSelect.tscn")
	await settle()
	check(current_scene.get_node("Center/Rows/Choices").get_child(3).has_focus(), "Re-entry restores selection")
	await joy(JOY_BUTTON_B)
	check(current_scene.scene_file_path == "res://scenes/StartMenu.tscn", "Gamepad cancel returns Home")
	change_scene_to_file("res://scenes/CharacterSelect.tscn")
	await settle()
	current_scene.get_node("Center/Rows/Back").grab_focus()
	await joy(JOY_BUTTON_A)
	check(current_scene.scene_file_path == "res://scenes/StartMenu.tscn", "Gamepad accept activates Back")
	print("CHARACTER SELECTION TEST: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
