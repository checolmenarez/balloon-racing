extends SceneTree

var failures: int = 0
var main: Node2D
var _mouse_entered: bool = false


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func frames(count: int = 4) -> void:
	for frame in count:
		await physics_frame
		await process_frame


func capture(label: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/hud-v1-%s.png" % label)


func send_mouse(event: InputEvent) -> void:
	if DisplayServer.get_name() == "headless":
		# Headless has no OS window-enter event or screen-coordinate transform.
		if not _mouse_entered:
			root.notify_mouse_entered()
			_mouse_entered = true
		root.push_input(event, true)
	else:
		Input.parse_input_event(event)


func check_layout() -> void:
	var hud: CanvasLayer = main.get_node("HUD")
	var viewport_rect := root.get_visible_rect()
	for control in [main.item_label, main.race_label, hud.leaderboard, hud.pause_button]:
		check(viewport_rect.encloses(control.get_global_rect()), "HUD component within viewport: " + control.name)
	var flight_corridor := Rect2(310, 185, viewport_rect.size.x - 620, 440)
	check(not hud.leaderboard.get_global_rect().intersects(flight_corridor), "Leaderboard leaves central flight/anticipation corridor clear")
	check(not main.item_label.get_global_rect().intersects(flight_corridor), "Inventory leaves flight corridor clear")
	check(not main.get_node("HUD/MobileControls").visible, "No mobile controls on PC")
	check(not main.get_node("HUD/Hint").visible and not main.debug_panel.visible, "No permanent debug/tutorial text")


func _run() -> void:
	TranslationServer.set_locale("es")
	main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	var hud: CanvasLayer = main.get_node("HUD")
	var item: Label = main.item_label
	var player: Balloon = main.balloon
	main.combat.set_physics_process(false)
	main.race_flow.set_physics_process(false)
	for box in main.track.get_node("ItemBoxes").get_children():
		box.combat = null # Isolate HUD state from automatic pickup at fixture positions.
	for racer in main.competitors:
		racer.set_physics_process(false)
	await frames(50)
	check(item.skin_icon != null and not item.skin_icon.visible, "Empty slot has no invented item")
	check_layout()
	main.race_flow._physics_process(3.0)
	main.race_flow.elapsed = 62.35
	player.position = Vector2(6100, 350)
	for index in range(1, 4):
		main.competitors[index].position = Vector2(6100 + index * 85, 120 + index * 140)
	await frames()
	check(main.get_node("HUD/RaceOverlay/Clock").text == "01:02.35", "Clock reads original race elapsed")
	check(main.race_label.text == "4/4", "Position reads actual standings")
	check(main.track_title.text == tr("%s\nTramo %d/%d") % [main.track.track_name, main.track.get_zone_index(player.position.x) + 1, main.track.zones.get_child_count()], "World and sector use track state")
	for index in 4:
		var row: Control = hud._rows[index]
		check(row.racer == main.standings.order[index], "Row follows existing order")
		check(row.portrait.texture == MenuStyle.portrait(row.racer.character_id, "normal"), "Portrait uses real project source")
		check(is_equal_approx(row.progress.value, main.track.get_progress(row.racer.position.x) * 100), "Row progress is real")
	await capture("empty-1280x720")
	player.items.collect(BalloonItems.Kind.ROCKET)
	await frames(ceili(item.roulette_duration * 60) + 5)
	check(item.skin_icon.texture == HudStyle.texture("icon_bomb"), "Rocket maps to rocket artwork despite reversed filename")
	check(item._item_name.text == "Misil", "Name matches equipped item")
	check(player.items.use_item(), "HUD does not delay item use")
	await frames()
	check(not item.skin_icon.visible, "Consumed item clears icon")
	player.items.collect(BalloonItems.Kind.BOMB)
	await frames(ceili(item.roulette_duration * 60) + 5)
	check(item.skin_icon.texture == HudStyle.texture("icon_rocket"), "Bomb maps to bomb artwork")
	player.items.initialize_turbo(2, 0)
	await frames()
	check(item._turbo_ready and item._turbo_state.text == "Listo", "Ready status reflects actual turbo availability")
	await capture("equipped-1280x720")
	check(player.items.use_turbo_charge(), "Original turbo activation still works")
	await frames()
	check("1" in item._turbo_count.text and item._turbo_state.text == "En uso", "Turbo count and active state update")
	player.position.x += 500
	await frames()
	check(main.race_label.text == "1/4" and hud._rows[0].racer == player, "Overtake updates place and order")
	await frames(20)
	check(main.race_label.scale.is_equal_approx(Vector2.ONE), "Place pop returns to rest")
	var node_count: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	await frames(90)
	check(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)) <= node_count, "HUD does not grow nodes during stable refresh")
	hud.pause_button.grab_focus()
	check(hud.pause_button.has_focus() and hud.pause_button.has_theme_stylebox_override("focus"), "Keyboard focus is visible on pause")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = hud.pause_button.get_global_rect().get_center()
	click.global_position = click.position
	var motion := InputEventMouseMotion.new()
	motion.position = click.position
	motion.global_position = click.position
	send_mouse(motion)
	await frames(2)
	click.pressed = true
	send_mouse(click)
	await frames(1)
	click = click.duplicate()
	click.pressed = false
	send_mouse(click)
	await frames(1)
	check(paused and main.get_node("HUD/RaceOverlay/PausePanel").visible, "Pause button uses existing pause route")
	await capture("pause")
	# Resume explicitly even after a failed input assertion, avoiding cascades.
	main.get_node("HUD/RaceOverlay")._resume()
	check(not paused, "Existing resume route works")
	hud.pause_button.grab_focus()
	for pressed in [true, false]:
		var key := InputEventKey.new()
		key.keycode = KEY_ENTER
		key.pressed = pressed
		Input.parse_input_event(key)
		await frames(1)
	check(paused, "Keyboard Enter activates focused pause button")
	main.get_node("HUD/RaceOverlay")._resume()
	root.size = Vector2i(1280, 800)
	root.content_scale_size = Vector2i(1280, 800)
	await frames()
	check_layout()
	await capture("equipped-1280x800")
	TranslationServer.set_locale("en")
	await frames(8)
	check("Sector" in main.track_title.text and item._item_name.text == "Bomb", "English labels refresh")
	await capture("english-1280x800")
	for racer in main.competitors:
		racer.position.x = main.track.finish.position.x + 1
	main.race_flow._physics_process(0.016)
	await frames()
	check(main.race_flow.state == RaceFlow.State.RESULTS and main.get_node("HUD/RaceOverlay/Results").visible, "Original finish/results flow works")
	check(not hud.leaderboard.visible and not hud.pause_button.visible and not item.visible, "Race HUD does not cover results")
	main.queue_free()
	await frames()
	print("HUD TEST: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
