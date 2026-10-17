class_name ItemCombat
extends Node2D

signal projectile_hit(collider: Object, source: Balloon, kind: BalloonItems.Kind)

@export var enabled: bool = true
@export var config: ItemConfig = preload("res://resources/default_items.tres")
@export var turbo_config: TurboConfig = preload("res://resources/default_turbo.tres")
var competitors: Array[Balloon] = []
var track: BalloonTrack
var standings: RaceStandings
var rng := RandomNumberGenerator.new()
var _decision_left: float = 0.0


func _ready() -> void:
	rng.randomize()


func choose_item(racer: Balloon = null) -> BalloonItems.Kind:
	if racer != null and rng.randf() < storm_probability(racer):
		return BalloonItems.Kind.STORM
	var weights: Vector3 = config.selection_weights.max(Vector3.ZERO)
	var total: float = weights.x + weights.y + weights.z
	var value: float = rng.randf() * total
	if total <= 0.0 or value < weights.x:
		return BalloonItems.Kind.ROCKET
	if value < weights.x + weights.y:
		return BalloonItems.Kind.BOMB
	return BalloonItems.Kind.BOOST


func active_order() -> Array[Balloon]:
	var result: Array[Balloon] = []
	if standings == null:
		return result
	standings.update_positions()
	for racer in standings.order:
		if racer.racing:
			result.append(racer)
	return result


func storm_probability(racer: Balloon) -> float:
	var place: int = active_order().find(racer)
	return clampf(config.storm_probability_by_place[clampi(place, 0, 3)], 0.0, 1.0) if place >= 0 else 0.0


func storm_target(source: Balloon) -> Balloon:
	var order: Array[Balloon] = active_order()
	if not source.racing or order.is_empty() or order[0] == source or order[0].global_position.x <= source.global_position.x:
		return null
	return order[0]


func launch_storm(source: Balloon) -> bool:
	var target: Balloon = storm_target(source)
	if not enabled or target == null or not target.items.warn_storm(source):
		return false
	var effect: Node2D = load("res://scenes/StormEffect.tscn").instantiate()
	effect.target = target
	add_child(effect)
	return true


func _unhandled_key_input(event: InputEvent) -> void:
	if enabled and event.is_action_pressed("use_turbo") and not event.is_echo():
		for racer in competitors:
			if racer.controller == null:
				racer.items.use_turbo_charge()
		get_viewport().set_input_as_handled()
	if enabled and event.is_action_pressed("use_item") and not event.is_echo():
		for racer in competitors:
			if racer.controller == null:
				racer.items.use_item()
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if not enabled:
		return
	_decision_left -= delta
	if _decision_left > 0.0:
		return
	_decision_left = config.bot_decision_interval
	for racer in competitors:
		if racer.controller is BotController and bot_should_use(racer):
			racer.items.use_item()
		if racer.controller is BotController and bot_should_turbo(racer):
			racer.items.use_turbo_charge()


func bot_should_turbo(racer: Balloon) -> bool:
	if not enabled or not racer.racing or track == null or racer.items.turbo_charges <= 0:
		return false
	if racer.items.boost_left > 0.0 or racer.items.turbo_wait_left > 0.0:
		return false
	var bot := racer.controller as BotController
	if bot == null or absf(bot.target_height - racer.position.y) > turbo_config.maximum_target_error:
		return false
	if racer.is_impact_penalized() or racer.items.hit_left > 0.0 or absf(racer.velocity.y) > turbo_config.maximum_vertical_speed:
		return false
	if racer.position.y < racer.ceiling_y + Balloon.TOP_EXTENT + turbo_config.vertical_margin or racer.position.y > racer.ground_y - Balloon.BOTTOM_EXTENT - turbo_config.vertical_margin:
		return false
	# Reserve room for the whole boost, including a margin before the next rock.
	var distance: float = maxf(turbo_config.minimum_clearance,
		racer.physics.horizontal_speed * config.boost_multiplier * config.boost_duration + turbo_config.braking_margin)
	return racer.global_position.x + distance < track.finish.global_position.x and track.get_upcoming_obstacles(racer.global_position.x, distance).is_empty()


func bot_should_use(racer: Balloon) -> bool:
	if not racer.racing:
		return false
	match racer.items.equipped:
		BalloonItems.Kind.STORM:
			var target: Balloon = storm_target(racer)
			return target != null and target.items.can_receive_storm()
		BalloonItems.Kind.ROCKET:
			for rival in competitors:
				var offset: Vector2 = rival.global_position - racer.global_position
				if rival != racer and rival.racing and offset.x > 80.0 and offset.x < config.bot_rocket_range and absf(offset.y) < config.bot_alignment:
					return true
		BalloonItems.Kind.BOMB:
			for rival in competitors:
				var offset: Vector2 = rival.global_position - racer.global_position
				if rival != racer and rival.racing and offset.y > 75.0 and offset.y < config.bot_bomb_range and absf(offset.x) < config.bomb_radius:
					return true
		BalloonItems.Kind.BOOST:
			return track != null and track.get_upcoming_obstacles(racer.global_position.x, config.bot_boost_clearance).is_empty()
	return false


func launch(source: Balloon, kind: BalloonItems.Kind) -> void:
	var projectile: ItemProjectile = load("res://scenes/ItemProjectile.tscn").instantiate()
	projectile.source = source
	projectile.kind = kind
	projectile.combat = self
	projectile.position = to_local(source.global_position + (Vector2(Balloon.HALF_WIDTH + 11, -25 * Balloon.SIZE_SCALE) if kind == BalloonItems.Kind.ROCKET else Vector2(0, Balloon.BOTTOM_EXTENT + 11)))
	add_child(projectile)
