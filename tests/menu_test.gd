extends SceneTree

var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func settle() -> void:
	await process_frame
	await process_frame


func _run() -> void:
	check(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/StartMenu.tscn", "F5 opens selection")
	change_scene_to_file("res://scenes/StartMenu.tscn")
	await settle()
	var menu: Control = current_scene
	menu.get_node("Layout/Rows/Buttons/Selection").pressed.emit()
	await settle()
	menu = current_scene
	var choices: HBoxContainer = menu.get_node("Center/Rows/Choices")
	check(choices.get_child_count() == 4, "Four balloon choices")
	for button in choices.get_children():
		var preview: TextureRect = button.get_child(0).get_node("Portrait")
		check(preview.texture != null, "UI portraits loaded without gameplay bodies")
	choices.get_child(2).pressed.emit()
	check(root.get_node("RaceSelection").selected == 2, "Selecting Greta updates session")
	check(menu.get_node("Center/Rows/Details/Content/Text/Name").text.contains("Greta Tuerca"), "Visible selected name")
	if "--capture" in OS.get_cmdline_user_args():
		await settle()
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/menu-preview.png")
	menu.get_node("Center/Rows/Play").pressed.emit()
	await settle()
	var main: Node2D = current_scene
	check(main.scene_file_path == "res://scenes/Main.tscn", "Play opens actual race")
	check(main.race_flow.state == RaceFlow.State.COUNTDOWN, "Race begins with countdown")
	check(main.balloon.character_id == "greta", "Human uses selected Greta")
	var characters: Array[String] = []
	for racer in main.competitors:
		check(racer.character_id not in characters, "All rivals retain distinct characters")
		characters.append(racer.character_id)
		check(racer.physics == main.balloon.physics and racer.items.turbo_charges == 2, "Selection changes no abilities")
	check(main.balloon.is_local_player and main.balloon.visual.local_outline_visible, "Local identity follows selected balloon")
	main.race_flow.restart()
	await settle()
	main = current_scene
	check(main.scene_file_path == "res://scenes/Main.tscn" and main.balloon.character_id == "greta", "Restart retains choice without returning to menu")
	print("MENU TEST: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
