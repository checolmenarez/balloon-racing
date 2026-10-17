extends SceneTree

var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func geometry(track: Node) -> Array:
	var result: Array = []
	for obstacle in track.get_node("Obstacles").get_children():
		result.append([obstacle.position, obstacle.collision_layer, obstacle.collision_mask,
			obstacle.get_node("LowerCollision").polygon, obstacle.get_node("LowerCollision").disabled,
			obstacle.get_node("UpperCollision").polygon, obstacle.get_node("UpperCollision").disabled])
	return result


func check_visual_only(node: Node) -> void:
	check(not node is CollisionObject2D, "World artwork adds no physics objects")
	for child in node.get_children():
		check_visual_only(child)


func _run() -> void:
	var manifest: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tools/valle_crops.json"))
	for entry in manifest:
		check(ResourceLoader.exists("res://assets/worlds/valle_ventoso/" + entry.path + ".png"), "Extracted asset exists: " + entry.path)
	var baseline: Node = load("res://scenes/Track01.tscn").instantiate()
	baseline.get_node("WorldVisual").free()
	root.add_child(baseline)
	var before: Array = geometry(baseline)
	baseline.free()
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	check(geometry(main.track) == before, "Every collision polygon, position, mask and enabled state is unchanged")
	check(before.size() == 17, "Original 17 formations retained")
	check(main.track.get_node("ItemBoxes").get_child_count() == 32, "All item boxes retained")
	check(main.track.get_node("WindZones").get_child_count() == 3, "Only original wind zones are active")
	var world: Node = main.track.get_node("WorldVisual")
	check_visual_only(world)
	var layers: Array[Node] = world.get_node("ParallaxBackground").get_children()
	check(layers.size() == 6, "Six parallax layers")
	var speeds: Array[float] = []
	for layer in layers:
		check(layer.texture != null, "Parallax texture loads")
		check(layer.scroll_factor not in speeds, "Each layer has independent depth")
		speeds.append(layer.scroll_factor)
	main.camera.position.x = 1000.0
	for layer in layers:
		layer._process(0.016)
		check(is_equal_approx(layer.position.x, 1000.0 * (1.0 - layer.scroll_factor)), "Parallax responds to camera only")
	for box in main.track.get_node("ItemBoxes").get_children():
		check(box.get_node("Shape").shape.size == Vector2(48, 48), "Item sensor unchanged")
		check(box._world_texture != null and not box.get_node("Symbol").visible, "Illustrated box replaces placeholder")
	for kind in ["roca_flotante", "barril_explosivo", "mina_aerea", "turbina", "nube_electrica"]:
		var visual: Node2D = load("res://scenes/WorldHazardVisual.tscn").instantiate()
		visual.appearance = kind
		root.add_child(visual)
		check_visual_only(visual)
		visual.queue_free()
	for kind in ["ascendente", "lateral", "descendente", "remolino", "nube_tormentosa"]:
		var visual: Node2D = load("res://scenes/WorldWindVisual.tscn").instantiate()
		visual.appearance = kind
		root.add_child(visual)
		check_visual_only(visual)
		visual.queue_free()
	await process_frame
	main.queue_free()
	await process_frame
	print("WORLD VISUAL TEST: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
