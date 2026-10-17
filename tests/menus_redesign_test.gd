extends SceneTree

var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func settle() -> void:
	for frame in 5:
		await process_frame


func capture(label: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/menus-" + label + ".png")


func _run() -> void:
	for chosen in 4:
		change_scene_to_file("res://scenes/StartMenu.tscn")
		await settle()
		current_scene.get_node("Layout/Rows/Buttons/Selection").pressed.emit()
		await settle()
		var menu: Control = current_scene
		var choices: HBoxContainer = menu.get_node("Center/Rows/Choices")
		if chosen == 2:
			for pressed in [true, false]:
				var click := InputEventMouseButton.new()
				click.position = choices.get_child(chosen).get_global_rect().get_center()
				click.global_position = click.position
				click.button_index = MOUSE_BUTTON_LEFT
				click.pressed = pressed
				Input.parse_input_event(click)
				await settle()
		else:
			choices.get_child(chosen).grab_focus()
			for pressed in [true, false]:
				var event := InputEventKey.new()
				event.keycode = KEY_ENTER
				event.pressed = pressed
				Input.parse_input_event(event)
				await settle()
		check(root.get_node("RaceSelection").selected == chosen, "Selection uses existing session state")
		for index in 4:
			check(choices.get_child(index).button_pressed == (index == chosen), "Only chosen card highlighted")
		for dimensions in [Vector2i(1280, 720), Vector2i(1280, 800)]:
			root.size = dimensions
			await settle()
			check(menu.get_global_rect().encloses(menu.get_node("Center/Rows").get_global_rect()), "Selection fits viewport")
			if chosen == 2:
				await capture("selection-%d" % dimensions.y)
		menu.get_node("Center/Rows/Play").pressed.emit()
		await settle()
		var main: Node = current_scene
		check(main.balloon.character_id == CharacterCatalog.IDS[chosen], "Race uses selected character")
		var flow: RaceFlow = main.race_flow
		flow.set_physics_process(false)
		flow.state = RaceFlow.State.RUNNING
		flow.elapsed = 83.0
		# Real finish model receives controlled crossings; human crosses last.
		for index in 4:
			var racer: Balloon = main.competitors[index]
			racer.set_physics_process(false)
			racer.racing = true
			flow._previous_x[racer] = main.track.finish.position.x - 100
			racer.position.x = main.track.finish.position.x + 10 + index * 20
			racer.collision_count = index + 2
			racer.items.used = index + 1
		flow._physics_process(0.1)
		await settle()
		var overlay: Control = main.get_node("HUD/RaceOverlay")
		var podium: HBoxContainer = overlay.get_node("Results/Rows/Podium")
		check(podium.get_child_count() == 4, "All four racers shown")
		check(flow.records[3].racer == main.balloon, "Human is actually fourth")
		for place in range(1, 5):
			var column: VBoxContainer = podium.get_node("Place%d" % place)
			var record: Dictionary = flow.records[place - 1]
			check(column.get_meta("racer") == record.racer, "Podium follows actual finish order")
			check(column.get_node("Identity").text == record.racer.competitor_name, "Correct character name")
			check(column.get_node("Local").text == ("TÚ" if record.racer.is_local_player else ""), "Local marker follows actual racer")
			var expected := MenuStyle.portrait(record.racer.character_id, ["happy", "normal", "angry", "surprised"][place - 1])
			var actual: Texture2D = column.get_node("Portrait").texture
			check(actual == expected or (actual is AtlasTexture and expected is AtlasTexture and actual.atlas == expected.atlas and actual.region == expected.region), "Correct expression per place")
			var summary: String = overlay.get_node("Results/Rows/Classification").text
			check(summary.contains("%.2f s · Choques %d · Objetos %d" % [record.time, record.collisions, record.items]), "Real finish statistics shown")
		for dimensions in [Vector2i(1280, 720), Vector2i(1280, 800)]:
			root.size = dimensions
			await settle()
			check(overlay.get_global_rect().encloses(overlay.get_node("Results").get_global_rect()), "Results fit viewport")
			check(overlay.get_global_rect().encloses(overlay.get_node("Results/Rows/Home").get_global_rect()), "Home button remains visible")
			if chosen == 2:
				await capture("results-%d" % dimensions.y)
		overlay.get_node("Results/Rows/Restart").pressed.emit()
		await settle()
		check(current_scene.balloon.character_id == CharacterCatalog.IDS[chosen], "Another race retains selection")
		check(current_scene.race_flow.state == RaceFlow.State.COUNTDOWN, "Restart resets flow")
		current_scene.get_node("HUD/RaceOverlay/Results/Rows/Home").pressed.emit()
		await settle()
		check(current_scene.scene_file_path == "res://scenes/StartMenu.tscn", "Results return to Home")
		current_scene.get_node("Layout/Rows/Buttons/Race").pressed.emit()
		await settle()
		check(current_scene.balloon.character_id == CharacterCatalog.IDS[chosen], "Home Race preserves selected character")
	print("MENUS REDESIGN TEST: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
