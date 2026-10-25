extends SceneTree

const Route = preload("res://tests/valle_routes.gd")
var failures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _geometry(main: Node2D) -> void:
	var track: BalloonTrack = main.track
	check(track.start.position.x == 240 and track.finish.position.x == 18400, "Unchanged course length")
	check(track.get_node("ItemBoxes").get_child_count() == 24, "Reduced box count")
	var boxes_per_sector: Array[int] = [0,0,0,0,0,0]
	for box in track.get_node("ItemBoxes").get_children():
		boxes_per_sector[track.get_zone_index(box.position.x)] += 1
	check(boxes_per_sector == [4,4,4,4,4,4], "Equal supply across all six sectors")
	for i in 6:
		check(track.zones.get_child(i).position.x == [240,2700,6000,9700,13400,16800][i], "Sector boundary preserved")
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := RectangleShape2D.new()
	query.shape = shape
	query.collision_mask = 2
	var space := main.get_world_2d().direct_space_state
	var divider: FlightObstacle = track.get_node("Obstacles/RouteDivider")
	var lower_rock: FlightObstacle = track.get_node("Obstacles/LowerRouteRock")
	check(divider.upper_tip_y - 120.0 > lower_rock.lower_tip_y - divider.lower_tip_y,
		"S4 lower bottleneck is narrower than its upper bottleneck")
	for wind_name in ["LowerCurrent", "LowerCurrentMiddle", "LowerCurrentExit"]:
		var lower_wind: Area2D = track.get_node("WindZones/" + wind_name)
		check(lower_wind.position.y - lower_wind.size.y * 0.5 > divider.lower_tip_y,
			"S4 fast currents are entirely below the divider")
	for island_name in ["TechnicalIslandS3", "PrecisionB"]:
		var island: FlightObstacle = track.get_node("Obstacles/" + island_name)
		check(island.upper_tip_y - island.ceiling_y < island.ground_y - island.lower_tip_y,
			"S3/S5 upper crest passage is narrower than lower bypass")
	for wind in track.get_node("WindZones").get_children():
		if track.get_zone_index(wind.position.x) in [2,4]:
			check(wind.size == Vector2(120,24), "Minimal technical current windows")
		shape.size = wind.size
		query.transform = Transform2D(0.0, wind.global_position)
		check(space.intersect_shape(query).is_empty(), "Wind rectangle is outside solid rock: " + wind.name)
	for obstacle in track.get_node("Obstacles").get_children():
		for side in ["Lower", "Upper"]:
			var collision: CollisionPolygon2D = obstacle.get_node(side + "Collision")
			var visual: Polygon2D = obstacle.get_node(side + "Visual")
			if not collision.disabled:
				check(visual.polygon == collision.polygon, "Visible silhouette matches collider")
	# A full balloon with 10 px extra on each side can follow both technical corridors.
	shape.size = Vector2(Balloon.HALF_WIDTH * 2 + 20, Balloon.TOP_EXTENT + Balloon.BOTTOM_EXTENT + 20)
	for entry in [Vector2(7500,130),Vector2(8000,325),Vector2(8500,140),Vector2(14600,130),Vector2(15100,325),Vector2(15600,140),Vector2(9750,335),Vector2(11750,530),Vector2(11250,220)]:
		query.transform = Transform2D(0.0, entry + Vector2(0,(Balloon.BOTTOM_EXTENT-Balloon.TOP_EXTENT)*0.5))
		check(space.intersect_shape(query).is_empty(), "10 px clearance at technical gate: %s" % entry)
	for interval in [Vector2i(7100,8900),Vector2i(14200,16000)]:
		for x in range(interval.x,interval.y+1,25):
			var clear: bool = false
			for y in range(125,380,5):
				query.transform = Transform2D(0.0,Vector2(x,y+(Balloon.BOTTOM_EXTENT-Balloon.TOP_EXTENT)*0.5))
				if space.intersect_shape(query).is_empty():
					clear = true
					break
			check(clear,"Upper corridor retains 10 px margins at X %d" % x)
			query.transform = Transform2D(0.0,Vector2(x,558+(Balloon.BOTTOM_EXTENT-Balloon.TOP_EXTENT)*0.5))
			check(space.intersect_shape(query).is_empty(),"Lower bypass retains 10 px margins at X %d" % x)
	# No fixed height can cross the fast upper corridor: the hanging lip is lower
	# than the maximum balloon centre allowed by the two adjacent crests.
	for pair in [["TechnicalIslandS3", "FirstCorridor"], ["PrecisionB", "PrecisionA"]]:
		var island: FlightObstacle = track.get_node("Obstacles/" + pair[0])
		var roof: FlightObstacle = track.get_node("Obstacles/" + pair[1])
		check(island.upper_tip_y - Balloon.BOTTOM_EXTENT < roof.upper_tip_y + Balloon.TOP_EXTENT,
			"Constant altitude cannot traverse technical route: " + pair[0])

func _course(technical: bool, wind_on: bool) -> Dictionary:
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	main.get_node("RaceFlow").enabled = false
	main.get_node("ItemCombat").enabled = false
	for wind in main.get_node("Track01/WindZones").get_children():
		wind.enabled = wind_on
	root.add_child(main)
	for racer in main.competitors:
		if racer != main.balloon: racer.set_physics_process(false)
	await physics_frame
	await process_frame
	if technical and wind_on: _geometry(main)
	var balloon: Balloon = main.balloon
	var times: Dictionary = {}
	var previous_collisions: int = 0
	var elapsed: float = 0.0
	var peak_speed: float = 0.0
	for frame in 60 * 100:
		var x: float = balloon.position.x
		var target: float = Route.height(x, true, technical)
		if balloon.position.y + balloon.velocity.y * 0.5 > target:
			Input.action_press("burner")
		else:
			Input.action_release("burner")
		await physics_frame
		await process_frame
		elapsed = float(frame + 1) / 60
		peak_speed = maxf(peak_speed, balloon.velocity.x)
		check(balloon.items.boost_left == 0.0, "No turbo in route measurement")
		for boundary in [6000,9700,13400,16800]:
			if balloon.position.x >= boundary and not times.has(boundary): times[boundary] = elapsed
		if balloon.collision_count > previous_collisions:
			print("REDESIGN contact technical=", technical, " wind=",wind_on, " at ",balloon.position, " ",balloon._ignored_obstacles)
		previous_collisions = balloon.collision_count
		if main.track.get_progress(balloon.position.x) == 1.0: break
	check(main.track.get_progress(balloon.position.x) == 1.0, "Complete race without turbo")
	check(balloon.collision_count == 0, "Clean fast/safe route, wind on/off")
	check(is_equal_approx(peak_speed,264.0 if wind_on else 220.0), "Unchanged base speed and 1.20 wind multiplier")
	var result: Dictionary = {"technical":technical,"wind":wind_on,"seconds":elapsed,"S3":times.get(9700,0)-times.get(6000,0),"S5":times.get(16800,0)-times.get(13400,0),"contacts":balloon.collision_count}
	print("REDESIGN ROUTE ", JSON.stringify(result))
	Input.action_release("burner")
	main.queue_free()
	await process_frame
	await physics_frame
	return result

func _run() -> void:
	var fast: Dictionary = await _course(true,true)
	var control: Dictionary = await _course(true,false)
	var safe: Dictionary = await _course(false,true)
	for sector in ["S3","S5"]:
		check(fast[sector] < control[sector] - 0.1, "Measurable current time saving in " + sector)
		check(fast[sector] < safe[sector], "Fast route beats clean bypass in " + sector)
	print("VALLE REDESIGN TEST: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL",failures])
	quit(0 if failures == 0 else 1)
