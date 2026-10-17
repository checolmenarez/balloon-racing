extends Node2D

@export var ceiling_y: float = 32.0
@export var ground_y: float = 640.0
@export var camera_look_ahead: float = 280.0
## Zero uses a new seed; a positive value reproduces navigation and item draws.
@export var race_seed: int = 0

@onready var balloon: Balloon = $Balloon
@onready var track: BalloonTrack = $Track01
@onready var track_progress: ProgressBar = $HUD/TrackProgress
@onready var track_title: Label = $HUD/TrackTitle
@onready var camera: Camera2D = $Camera2D
@onready var debug_panel: PanelContainer = $HUD/DebugPanel
@onready var debug_label: Label = $HUD/DebugPanel/Margin/DebugLabel
@onready var standings: RaceStandings = $Standings
@onready var race_label: Label = $HUD/RacePosition
@onready var balloon_visibility: BalloonVisibility = $BalloonVisibility
@onready var combat: ItemCombat = $ItemCombat
@onready var item_label: Label = $HUD/ItemStatus
@onready var race_flow: RaceFlow = $RaceFlow
var competitors: Array[Balloon] = []


func _ready() -> void:
	balloon.global_position = track.start.global_position
	balloon.set_vertical_bounds(ceiling_y, ground_y)
	competitors = [balloon, $BotNovice, $BotBalanced, $BotCompetitive]
	RaceSelection.apply_characters(competitors)
	for rival in competitors:
		rival.set_vertical_bounds(ceiling_y, ground_y)
	standings.order.assign(competitors)
	combat.competitors.assign(competitors)
	combat.track = track
	combat.standings = standings
	if race_flow.enabled:
		if race_seed != 0:
			combat.rng.seed = race_seed
		for racer in competitors:
			if racer.controller is BotController:
				racer.controller.prepare_race(combat.rng)
	for racer in competitors:
		racer.items.combat = combat
		racer.items.config = combat.config
	for box in track.get_node("ItemBoxes").get_children():
		box.combat = combat
	balloon_visibility.competitors.assign(competitors)
	balloon_visibility.update_visuals(0.0)
	get_viewport().size_changed.connect(_fit_camera)
	_fit_camera()
	_update_camera()
	race_flow.setup(competitors, track, standings, combat)
	$HUD/RaceOverlay.flow = race_flow


func _process(delta: float) -> void:
	$HUD/StormWarning.visible = balloon.items.storm_warning_left > 0.0
	balloon_visibility.update_visuals(delta)
	item_label.text = "[A] %s" % balloon.items.item_name()
	item_label.text += "\n[D] Turbo: %d" % balloon.items.turbo_charges
	if balloon.items.boost_left > 0.0:
		item_label.text += "\nTurbo activo %.1f s" % balloon.items.boost_left
	elif balloon.items.turbo_charges > 0 and balloon.items.turbo_wait_left > 0.0:
		item_label.text += " · espera %.0f s" % ceilf(balloon.items.turbo_wait_left)
	_update_camera()
	standings.update_positions()
	race_label.text = "Posición: %d.º / 4" % standings.get_place(balloon)
	track_progress.value = track.get_progress(balloon.global_position.x) * 100.0
	track_title.text = "%s · %s" % [track.track_name, track.get_zone_title(balloon.global_position.x)]
	if debug_panel.visible:
		debug_label.text = "Velocidad X: %.1f px/s\nVelocidad Y: %.1f px/s\nQuemador: %s\nAltura: %.1f px\nColisiones: %d\nPenalización: %s" % [
			balloon.velocity.x, balloon.velocity.y,
			"ENCENDIDO" if balloon.burner_active else "APAGADO",
			ground_y - (balloon.global_position.y + Balloon.BOTTOM_EXTENT),
			balloon.collision_count,
			"%.2f s" % balloon.impact_time_left if balloon.is_impact_penalized() else "NO"]
		debug_label.text += "\nProgreso: %.1f%%\nZona: %d/6" % [
			track_progress.value, track.get_zone_index(balloon.global_position.x) + 1]
		debug_label.text += "\nPosición: %d/4" % standings.get_place(balloon)
		for rival in competitors:
			var bot := rival.controller as BotController
			var title: String = bot.profile.profile_name if bot != null else rival.competitor_name
			debug_label.text += "\n%s: %.1f%%" % [title, track.get_progress(rival.global_position.x) * 100.0]
			if bot != null:
				debug_label.text += " · Y objetivo %.0f" % bot.target_height
			debug_label.text += " · Turbos %d" % rival.items.turbo_charges
			debug_label.text += "\n  Objetos %d/%d · impactos %d/%d" % [rival.items.collected, rival.items.used, rival.items.hits_dealt, rival.items.hits_received]
			debug_label.text += "\n  #%d · VX %.0f · turbo %.1f · tormenta %.1f (%d)" % [standings.get_place(rival), rival.velocity.x, rival.items.boost_left, rival.items.storm_left, rival.items.storms_received]
			debug_label.text += " · viento %s" % ("SÍ" if rival.items.wind_multiplier() > 1.0 else "NO")
	queue_redraw()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug") and not event.is_echo():
		debug_panel.visible = not debug_panel.visible
		get_viewport().set_input_as_handled()


func _fit_camera() -> void:
	# Keep the entire vertical play area visible on window resize.
	var scale_factor: float = get_viewport_rect().size.y / 720.0
	camera.zoom = Vector2.ONE * scale_factor


func _update_camera() -> void:
	camera.position = Vector2(balloon.position.x + camera_look_ahead, 360.0)


func _draw() -> void:
	if is_instance_valid(track) and track.has_node("WorldVisual"):
		return
	if not is_instance_valid(camera):
		return
	var half_width: float = get_viewport_rect().size.x / camera.zoom.x * 0.5
	var left: float = camera.position.x - half_width - 200.0
	var right: float = camera.position.x + half_width + 200.0
	# Distant clouds move more slowly than ground details.
	var cloud_shift: float = camera.position.x * 0.65
	for index in range(floori((left - cloud_shift) / 410.0), ceili((right - cloud_shift) / 410.0) + 1):
		var center := Vector2(index * 410.0 + cloud_shift, 140.0 + posmod(index, 3) * 75.0)
		var color := Color(0.88, 0.96, 1.0, 0.85)
		draw_circle(center, 28.0, color)
		draw_circle(center + Vector2(32, -12), 37.0, color)
		draw_circle(center + Vector2(70, 1), 26.0, color)
		draw_rect(Rect2(center, Vector2(70, 26)), color)
	draw_rect(Rect2(left, ground_y, right - left, 720.0), Color("b88c5a"))
	draw_rect(Rect2(left, ground_y, right - left, 14.0), Color("69a850"))
	for index in range(floori(left / 100.0), ceili(right / 100.0) + 1):
		var x: float = index * 100.0
		draw_line(Vector2(x, ground_y + 5), Vector2(x + 12, ground_y - 5), Color("528b43"), 3.0)
		draw_line(Vector2(x + 30, ground_y + 40), Vector2(x + 50, ground_y + 40), Color("a77a4d"), 3.0)
