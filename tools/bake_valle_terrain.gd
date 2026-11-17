extends SceneTree
## Offline Godot render, not new artwork: caches exact compositions at desktop density.
const KIT := preload("res://scripts/terrain_kit_visual.gd")
const DENSITY := 1.5

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if DisplayServer.get_name() == "headless" or not "bake-terrain" in OS.get_cmdline_user_args():
		push_error("Run with a rendering driver and -- bake-terrain")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(KIT.CACHE)
	var track: Node2D = load("res://scenes/Track01.tscn").instantiate()
	track.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(track)
	await process_frame
	await process_frame
	var count: int = 0
	for part in track.get_node("WorldVisual/TerrainVisual").get_children():
		if not part is Polygon2D: continue
		var mask := part as Polygon2D
		var selected: bool = true
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("only=") and mask.name != arg.trim_prefix("only="): selected = false
		if not selected: continue
		var bounds := Rect2(mask.polygon[0], Vector2.ZERO)
		for point in mask.polygon: bounds = bounds.expand(point)
		bounds = bounds.grow(3.0)
		bounds.position = bounds.position.floor()
		bounds.size = bounds.size.ceil()
		var label: String = mask.name
		var viewport := SubViewport.new()
		viewport.transparent_bg = true
		viewport.disable_3d = true
		viewport.world_2d = World2D.new()
		viewport.size = Vector2i((bounds.size * DENSITY).ceil())
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		root.add_child(viewport)
		mask.reparent(viewport)
		mask.position = -bounds.position * DENSITY
		mask.scale = Vector2.ONE * DENSITY
		await process_frame
		await RenderingServer.frame_post_draw
		var error: Error = viewport.get_texture().get_image().save_png(KIT.CACHE + label + ".png")
		if error != OK:
			push_error("Bake failed: " + label)
			quit(1)
			return
		var info := {"revision": KIT.CACHE_REVISION, "outline_hash": str(mask.get_meta("collision_outline")).sha256_text(), "visual_hash": str(mask.polygon).sha256_text(), "x": bounds.position.x, "y": bounds.position.y, "density": DENSITY}
		FileAccess.open(KIT.CACHE + label + ".json", FileAccess.WRITE).store_string(JSON.stringify(info))
		viewport.queue_free()
		await process_frame
		count += 1
	track.queue_free()
	await process_frame
	print("TERRAIN BAKE: ", count, " formations at 1.5x; gameplay untouched")
	quit(0 if count > 0 else 1)
