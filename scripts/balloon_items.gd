class_name BalloonItems
extends Node

enum Kind { NONE, ROCKET, BOMB, BOOST, STORM }

var equipped: Kind = Kind.NONE
var boost_left: float = 0.0
var hit_left: float = 0.0
var protection_left: float = 0.0
var collected: int = 0
var used: int = 0
var hits_received: int = 0
var hits_dealt: int = 0
var config: ItemConfig = preload("res://resources/default_items.tres")
var combat: ItemCombat
var turbo_charges: int = 0
var turbo_wait_left: float = 0.0
var storm_warning_left: float = 0.0
var storm_left: float = 0.0
var storm_protection_left: float = 0.0
var storms_received: int = 0
var _storm_source: Balloon
var wind_zones: Dictionary = {}


func wind_multiplier() -> float:
	var strongest: float = 1.0
	for zone in wind_zones.keys():
		if not is_instance_valid(zone):
			wind_zones.erase(zone)
		else:
			strongest = maxf(strongest, wind_zones[zone])
	return strongest


func can_receive_storm() -> bool:
	return get_parent().racing and storm_warning_left <= 0.0 and storm_left <= 0.0 and storm_protection_left <= 0.0


func warn_storm(source: Balloon) -> bool:
	if not can_receive_storm() or source == get_parent():
		return false
	_storm_source = source
	storm_warning_left = config.storm_warning
	storm_protection_left = maxf(config.storm_protection, config.storm_warning + config.storm_duration)
	return true


func initialize_turbo(charges: int, initial_delay: float) -> void:
	turbo_charges = maxi(0, charges)
	turbo_wait_left = maxf(0.0, initial_delay)


func _activate_boost() -> bool:
	if not get_parent().racing or combat == null or not combat.enabled or boost_left > 0.0:
		return false
	boost_left = config.boost_duration
	get_node("/root/Music").play_effect("turbo", get_parent().global_position)
	return true


func use_turbo_charge() -> bool:
	if turbo_charges <= 0 or turbo_wait_left > 0.0 or not _activate_boost():
		return false
	turbo_charges -= 1
	turbo_wait_left = combat.turbo_config.minimum_interval
	return true


func tick(delta: float) -> void:
	storm_left = maxf(0.0, storm_left - delta)
	storm_protection_left = maxf(0.0, storm_protection_left - delta)
	if storm_warning_left > 0.0:
		storm_warning_left = maxf(0.0, storm_warning_left - delta)
		if storm_warning_left <= 0.0:
			storm_left = config.storm_duration
			get_node("/root/Music").play_effect("collision", get_parent().global_position)
			storms_received += 1
			hits_received += 1
			if is_instance_valid(_storm_source):
				_storm_source.items.hits_dealt += 1
	turbo_wait_left = maxf(0.0, turbo_wait_left - delta)
	boost_left = maxf(0.0, boost_left - delta)
	hit_left = maxf(0.0, hit_left - delta)
	protection_left = maxf(0.0, protection_left - delta)


func speed_multiplier(obstacle_multiplier: float = 1.0) -> float:
	# Strongest aid and strongest penalty; overlapping sources never multiply.
	var bonus: float = minf(config.maximum_speed_bonus, maxf(wind_multiplier(), config.boost_multiplier if boost_left > 0.0 else 1.0))
	var penalty: float = minf(obstacle_multiplier, minf(config.hit_multiplier if hit_left > 0.0 else 1.0, config.storm_multiplier if storm_left > 0.0 else 1.0))
	return bonus * penalty


func collect(kind: Kind) -> bool:
	if not get_parent().racing or equipped != Kind.NONE or kind == Kind.NONE:
		return false
	equipped = kind
	collected += 1
	return true


func use_item() -> bool:
	if not get_parent().racing or equipped == Kind.NONE or combat == null or not combat.enabled:
		return false
	var kind: Kind = equipped
	if kind == Kind.BOOST and not _activate_boost():
		return false
	if kind == Kind.STORM and not combat.launch_storm(get_parent()):
		return false
	equipped = Kind.NONE
	used += 1
	if kind != Kind.BOOST and kind != Kind.STORM:
		combat.launch(get_parent(), kind)
	return true


func receive_hit(source: Balloon, impulse: Vector2) -> bool:
	if not get_parent().racing or protection_left > 0.0:
		return false
	hit_left = config.hit_duration
	get_node("/root/Music").play_effect("collision", get_parent().global_position)
	protection_left = config.hit_protection
	hits_received += 1
	if is_instance_valid(source):
		source.items.hits_dealt += 1
	var body := get_parent() as Balloon
	body.velocity.y = clampf(body.velocity.y + impulse.y, -body.physics.max_vertical_speed, body.physics.max_vertical_speed)
	return true


func item_name() -> String:
	return tr(["Vacío", "Cohete", "Bomba", "Turbo", "Tormenta"][equipped])
