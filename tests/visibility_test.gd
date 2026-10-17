extends SceneTree

var failures: int = 0
var main: Node2D
var racers: Array[Balloon]
var visibility: BalloonVisibility


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _settle() -> void:
	for step in 30:
		visibility.update_visuals(1.0 / 60.0)


func _show(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var captured: Image = root.get_texture().get_image()
	captured.save_png("res://.godot/m41-%s.png" % label)
	if label == "four-overlap" or label == "blue-local":
		var local: Balloon = racers[0] if label == "four-overlap" else racers[2]
		var pixel: Vector2 = main.get_node("Camera2D").get_canvas_transform() * (local.position + Vector2(0, -25))
		var actual: Color = captured.get_pixelv(Vector2i(pixel))
		for racer in racers:
			if racer != local:
				racer.visual.hide()
		await process_frame
		await RenderingServer.frame_post_draw
		var expected: Color = root.get_texture().get_image().get_pixelv(Vector2i(pixel))
		for racer in racers:
			racer.visual.show()
		_check(absf(actual.r - expected.r) < 0.04 and absf(actual.g - expected.g) < 0.04
			and absf(actual.b - expected.b) < 0.04, "Rendered local silhouette is visible and opaque")
	if "--preview" in OS.get_cmdline_user_args():
		await create_timer(3.0).timeout


func _run() -> void:
	main = load("res://scenes/Main.tscn").instantiate()
	main.get_node("ItemCombat").enabled = false # Isolate pre-M5 regression.
	main.get_node("RaceFlow").enabled = false # Isolate flight/items from lifecycle.
	root.add_child(main)
	racers = main.competitors
	visibility = main.get_node("BalloonVisibility")
	for racer in racers:
		racer.set_physics_process(false)
		racer.position = Vector2(240, 350)
	_settle()
	_check(racers[0].visual.z_index == 2, "Local visual is above all rivals")
	_check(racers[0].visual.local_outline_visible and not racers[1].visual.local_outline_visible, "Only local has a contour")
	_check(racers[0].visual.modulate.a == 1.0, "Local stays opaque")
	for index in range(1, 4):
		_check(is_equal_approx(racers[index].visual.modulate.a, 0.45), "All overlapping rivals fade")
		_check(racers[index].visual.z_index == 1, "Rival visual layer")
	for racer in racers:
		_check(racer.position == Vector2(240, 350) and racer.velocity == Vector2.ZERO,
			"Presentation leaves position and velocity untouched")
		_check(racer.z_index == 1 and racer.collision_mask == 2, "Body layer and mask unchanged")
	await _show("four-overlap")
	# Partial overlap exposes the faded silhouettes as well as the local balloon.
	for index in range(1, 4):
		racers[index].position += Vector2(index * 16.0, -index * 8.0)
	_settle()
	await _show("partial-overlap")
	# Jitter around the entry edge must not repeatedly restore opacity.
	for step in 120:
		racers[1].position = racers[0].position + Vector2(Balloon.HALF_WIDTH * 2.0 - 3.0 if step % 2 == 0 else Balloon.HALF_WIDTH * 2.0 + 6.0, 0)
		visibility.update_visuals(1.0 / 60.0)
		_check(is_equal_approx(racers[1].visual.modulate.a, 0.45), "Hysteresis suppresses edge flicker")
	for index in range(1, 4):
		racers[index].position = racers[0].position + Vector2(index * 130.0, 0)
	_settle()
	for index in range(1, 4):
		_check(racers[index].visual.modulate.a == 1.0, "Opacity restores after separation")
	await _show("separated")
	for racer in racers:
		racer.position = Vector2(240, 350)
	visibility.overlap_transparency_enabled = false
	_settle()
	for racer in racers:
		_check(racer.visual.modulate.a == 1.0, "Transparency can be disabled")
	visibility.overlap_transparency_enabled = true
	visibility.overlapping_opacity = 0.30
	_settle()
	_check(is_equal_approx(racers[1].visual.modulate.a, 0.30), "Opacity is configurable")
	visibility.overlapping_opacity = 0.45
	# Ownership is explicit; the blue balloon becomes local without changing input.
	racers[0].is_local_player = false
	racers[2].is_local_player = true
	_settle()
	_check(racers[2].visual.z_index == 2 and racers[0].visual.z_index == 1, "Priority follows ownership, not color")
	_check(racers[2].visual.local_outline_visible and not racers[0].visual.local_outline_visible, "Contour transfers ownership while frozen")
	_check(racers[2].visual.modulate.a == 1.0, "New local becomes fully opaque immediately")
	_check(racers[2].visual.get_node("LocalMarker").visible and not racers[0].visual.get_node("LocalMarker").visible, "Marker transfers to new local")
	await _show("blue-local")
	for racer in racers:
		racer.position.y = 106.0
	await _show("ceiling-marker")
	for racer in racers:
		racer.position.y = 350.0
	visibility.local_marker_visible = false
	_settle()
	_check(not racers[2].visual.get_node("LocalMarker").visible, "Marker can be hidden")
	racers[2].impact_tint = Color(1, 0.65, 0.65, 0.65)
	_settle()
	_check(racers[2].visual.modulate.a == 1.0 and racers[2].visual.modulate.g < 1.0, "Local impact tint remains, without transparency")
	# Foreground ordering uses ordinary world Z, not an always-on-top CanvasLayer.
	var foreground := Polygon2D.new()
	foreground.polygon = PackedVector2Array([Vector2(-16, -50), Vector2(16, -50), Vector2(16, -18), Vector2(-16, -18)])
	foreground.position = racers[2].position
	foreground.color = Color(0, 1, 1, 1)
	foreground.z_index = 3
	main.add_child(foreground)
	_check(foreground.z_index > racers[2].visual.z_index, "Foreground retains occlusion priority")
	await _show("foreground")
	if DisplayServer.get_name() != "headless":
		var pixel: Vector2 = main.get_node("Camera2D").get_canvas_transform() * (foreground.position + Vector2(0, -34))
		var captured: Image = root.get_texture().get_image()
		var color: Color = captured.get_pixelv(Vector2i(pixel))
		_check(color.g > 0.9 and color.b > 0.9 and color.r < 0.1, "Rendered foreground hides local balloon")
	foreground.queue_free()
	racers[2].is_local_player = false
	for racer in racers:
		racer.impact_tint = Color.WHITE
	_settle()
	for racer in racers:
		_check(racer.visual.modulate.a == 1.0 and not racer.visual.get_node("LocalMarker").visible, "No owner restores neutral visuals")
	print("VISIBILITY TEST: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
