class_name RaceFlow
extends Node

enum State { COUNTDOWN, RUNNING, WAITING, RESULTS }

@export var enabled: bool = true
@export_range(0.1, 10.0, 0.1) var countdown_duration: float = 3.0
@export_range(1.0, 30.0, 0.5) var finish_timeout: float = 8.0
var state: State = State.COUNTDOWN
var countdown_left: float = 3.0
var elapsed: float = 0.0
var records: Array[Dictionary] = []
var competitors: Array[Balloon] = []
var track: BalloonTrack
var standings: RaceStandings
var combat: ItemCombat
var _previous_x: Dictionary = {}
var _player_finish_time: float = -1.0


func setup(racers: Array[Balloon], course: BalloonTrack, ranking: RaceStandings, items: ItemCombat) -> void:
	competitors.assign(racers)
	track = course
	standings = ranking
	combat = items
	get_node("/root/Music").clear_effects()
	get_node("/root/Music").set_theme("menu" if enabled else "race")
	# Observe movement after all bodies, independently of their tree order.
	process_physics_priority = 100
	countdown_left = countdown_duration
	if not enabled:
		set_physics_process(false)
		return
	combat.enabled = false
	for racer in competitors:
		var charges: int = combat.turbo_config.bot_initial_charges if racer.controller is BotController else combat.turbo_config.human_initial_charges
		racer.items.initialize_turbo(charges, combat.turbo_config.initial_delay)
		racer.racing = false
		_previous_x[racer] = racer.global_position.x
		racer.visual.present(minf(0.65, countdown_duration * 0.8))
	get_node("/root/Music").play_effect("countdown", track.start.global_position)


func _physics_process(delta: float) -> void:
	if not enabled or state == State.RESULTS:
		return
	if state == State.COUNTDOWN:
		var previous_tick: int = ceili(countdown_left)
		countdown_left = maxf(0.0, countdown_left - delta)
		if ceili(countdown_left) != previous_tick and countdown_left > 0.00001:
			get_node("/root/Music").play_effect("countdown", track.start.global_position)
		if countdown_left <= 0.00001:
			state = State.RUNNING
			get_node("/root/Music").set_theme("race")
			get_node("/root/Music").play_effect("race_start", track.start.global_position)
			combat.enabled = true
			for racer in competitors:
				racer.racing = true
		return
	var crossings: Array[Dictionary] = []
	var finish_x: float = track.finish.global_position.x
	for racer in competitors:
		if not racer.racing:
			continue
		var before: float = _previous_x[racer]
		var after: float = racer.global_position.x
		if before < finish_x and after >= finish_x:
			var fraction: float = clampf((finish_x - before) / (after - before), 0.0, 1.0)
			crossings.append({"racer": racer, "time": elapsed + delta * fraction})
		_previous_x[racer] = after
	crossings.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.time == b.time:
			return competitors.find(a.racer) < competitors.find(b.racer)
		return a.time < b.time)
	for crossing in crossings:
		if _player_finish_time >= 0.0 and crossing.time > _player_finish_time + finish_timeout:
			continue
		var racer: Balloon = crossing.racer
		records.append({"racer": racer, "time": crossing.time, "place": records.size() + 1,
			"collisions": racer.collision_count, "items": racer.items.used})
		standings.finished_order.append(racer)
		racer.visual.victory = records.size() == 1
		racer.stop_racing()
		if racer.controller == null:
			_player_finish_time = crossing.time
			state = State.WAITING
	elapsed += delta
	standings.update_positions()
	if records.size() == competitors.size() or (_player_finish_time >= 0.0 and elapsed >= _player_finish_time + finish_timeout):
		state = State.RESULTS
		get_node("/root/Music").clear_effects()
		get_node("/root/Music").set_theme("menu")
		combat.enabled = false
		for racer in competitors:
			racer.stop_racing()
		for projectile in combat.get_children():
			projectile.queue_free()


func record_for(racer: Balloon) -> Dictionary:
	for record in records:
		if record.racer == racer:
			return record
	return {}


func restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
