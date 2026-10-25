class_name BotController
extends FlightController

@export var profile: BotProfile
@export var track: BalloonTrack

var target_height: float = 350.0
var _reaction_left: float = 0.0
var _burner: bool = false


func prepare_race(rng: RandomNumberGenerator) -> void:
	# Per-race choices, independent of positions/ranking; resource stays unchanged.
	profile = profile.duplicate()
	profile.look_ahead += rng.randf_range(-profile.anticipation_variation, profile.anticipation_variation)
	profile.error_phase += rng.randf_range(-profile.phase_variation, profile.phase_variation)
	profile.preferred_route = BotProfile.Route.UPPER if rng.randf() < profile.upper_route_probability else BotProfile.Route.LOWER


func wants_burner(body: CharacterBody2D, delta: float) -> bool:
	_reaction_left -= delta
	if _reaction_left > 0.0:
		return _burner
	_reaction_left = profile.reaction_time / profile.skill_multiplier
	var balloon := body as Balloon
	var minimum: float = balloon.ceiling_y + Balloon.TOP_EXTENT
	var maximum: float = balloon.ground_y - Balloon.BOTTOM_EXTENT
	var x: float = balloon.global_position.x
	var anticipation: float = profile.look_ahead * profile.skill_multiplier
	var in_fork: bool = x + anticipation >= track.fork.global_position.x and x < track.merge.global_position.x
	var desired: float = (minimum + maximum) * 0.5
	var route_y: float = desired
	if in_fork:
		var marker_name: String = "UpperRoute" if profile.preferred_route == BotProfile.Route.UPPER else "LowerRoute"
		route_y = track.get_node("References/" + marker_name).global_position.y
		desired = route_y
	# Inspect actual geometry, including simultaneous island and ceiling constraints.
	for obstacle in track.get_upcoming_obstacles(x, anticipation):
		var previous_minimum: float = minimum
		var previous_maximum: float = maximum
		var top: float = obstacle.global_position.y + obstacle.upper_tip_y
		var bottom: float = obstacle.global_position.y + obstacle.lower_tip_y
		match obstacle.kind:
			FlightObstacle.Kind.LOWER:
				maximum = minf(maximum, bottom - Balloon.BOTTOM_EXTENT)
			FlightObstacle.Kind.UPPER:
				minimum = maxf(minimum, top + Balloon.TOP_EXTENT)
			FlightObstacle.Kind.GAP:
				minimum = maxf(minimum, top + Balloon.TOP_EXTENT)
				maximum = minf(maximum, bottom - Balloon.BOTTOM_EXTENT)
			FlightObstacle.Kind.ISLAND:
				# Irregular technical islands have a broad local bypass below.
				# Keep S4's existing route choice and avoid treating all crests as flat.
				if obstacle.outline.is_empty() and profile.preferred_route == BotProfile.Route.UPPER:
					maximum = minf(maximum, top - Balloon.BOTTOM_EXTENT)
				else:
					minimum = maxf(minimum, bottom + Balloon.TOP_EXTENT)
		# Passable vertical gates must not override the solid island bypass.
		if minimum > maximum:
			minimum = previous_minimum
			maximum = previous_maximum
	# Local moving-obstacle adaptation: reserve its full predictable vertical sweep.
	# Keep the existing corridor if terrain leaves no compatible side.
	var creatures: Node = track.get_node_or_null("FlyingObstacles")
	if creatures != null:
		for creature: FlyingCreatureObstacle in creatures.get_children():
			var bounds: Rect2 = creature.get_swept_bounds()
			if bounds.end.x < x - Balloon.HALF_WIDTH or bounds.position.x > x + anticipation:
				continue
			var above: float = bounds.position.y - Balloon.BOTTOM_EXTENT - 8.0
			var below: float = bounds.end.y + Balloon.TOP_EXTENT + 8.0
			var can_above: bool = above >= minimum
			var can_below: bool = below <= maximum
			if can_above and (not can_below or profile.preferred_route == BotProfile.Route.UPPER):
				maximum = minf(maximum, above)
			elif can_below:
				minimum = maxf(minimum, below)
	if minimum <= maximum:
		desired = (minimum + maximum) * 0.5
		if in_fork:
			var clearance: float = minf(20.0, (maximum - minimum) * 0.25)
			desired = clampf(route_y, minimum + clearance, maximum - clearance)
	var bias: float = sin(x / 700.0 + profile.error_phase) * (profile.error_margin / profile.skill_multiplier)
	target_height = clampf(desired + bias, balloon.ceiling_y + Balloon.TOP_EXTENT,
		balloon.ground_y - Balloon.BOTTOM_EXTENT)
	if minimum <= maximum:
		var safety_margin: float = minf(12.0, (maximum - minimum) * 0.25)
		target_height = clampf(target_height, minimum + safety_margin, maximum - safety_margin)
	var predicted_y: float = balloon.global_position.y + balloon.velocity.y * profile.inertia_prediction
	if predicted_y > target_height + (profile.height_precision / profile.skill_multiplier):
		_burner = true
	elif predicted_y < target_height - (profile.height_precision / profile.skill_multiplier):
		_burner = false
	return _burner
