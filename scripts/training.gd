extends Node2D

## World-space checkpoints define the four lessons, not timed spawns.
@export var camera_look_ahead: float = 280.0
@export var blocked_timeout: float = 5.0
var stage: int = 0
var completed: bool = false
var saw_burner: bool = false
var rose: bool = false
var descended: bool = false
var target_hit: bool = false
var turbo_used: bool = false
var wind_entered: bool = false
var wind_crossed: bool = false
var retries: int = 0
var _stage_collisions: int = 0
var _feedback_left: float = 0.0
var _blocked_left: float = 0.0
var _last_x: float = 0.0
var _retry_pending: bool = false
var visibility := BalloonVisibility.new()
@onready var balloon: Balloon = $PlayerBalloon
@onready var combat: ItemCombat = $ItemCombat
@onready var camera: Camera2D = $Camera2D
@onready var box: Area2D = $TrainingTrack/Box
@onready var target: StaticBody2D = $TrainingTrack/Target
@onready var wind: Area2D = $TrainingTrack/Wind
@onready var instruction: Label = $HUD/Info/Rows/Instruction
@onready var feedback: Label = $HUD/Info/Rows/Feedback


func _ready() -> void:
	RaceSelection.apply_characters([balloon])
	$HUD/ItemStatus.racer = balloon
	add_child(visibility)
	visibility.competitors.assign([balloon])
	visibility.update_visuals(0)
	balloon.set_vertical_bounds(32, 640)
	balloon.add_collision_exception_with(target)
	combat.competitors.assign([balloon])
	balloon.items.combat = combat
	balloon.items.config = combat.config
	balloon.items.initialize_turbo(0, 0)
	box.combat = combat
	combat.projectile_hit.connect(_projectile_hit)
	$HUD/Overlay.configure_standalone(_restart)
	$HUD/Info/Rows/Retry.pressed.connect(retry_stage)
	$HUD/Complete/Rows/Race.pressed.connect(_race)
	$HUD/Complete/Rows/Home.pressed.connect($HUD/Overlay._home)
	$HUD/Complete/Rows/Home.text = tr("Volver al menú")
	$HUD/Complete/Rows/Title.text = tr("¡ENTRENAMIENTO COMPLETADO!")
	$HUD/Complete/Rows/Message.text = tr("¡Ya estás listo para competir!")
	MenuStyle.button($HUD/Complete/Rows/Race, true)
	MenuStyle.button($HUD/Complete/Rows/Home)
	get_node("/root/Music").clear_effects()
	get_node("/root/Music").set_theme("race")
	process_physics_priority = 110
	_last_x = balloon.position.x
	_update_hud()
	_update_camera()


func _physics_process(delta: float) -> void:
	if completed or _retry_pending:
		return
	_feedback_left = maxf(0, _feedback_left - delta)
	if _feedback_left == 0:
		feedback.text = ""
	var x: float = balloon.position.x
	_blocked_left = _blocked_left + delta if x - _last_x < 0.1 else 0.0
	_last_x = x
	if _blocked_left >= blocked_timeout:
		_request_retry()
		return
	match stage:
		0:
			saw_burner = saw_burner or balloon.burner_active
			rose = rose or (balloon.burner_active and balloon.velocity.y < -20)
			descended = descended or (rose and not balloon.burner_active and balloon.velocity.y > 20)
			if x >= $Checkpoints/Zone2.position.x:
				if descended and balloon.collision_count == _stage_collisions:
					_advance()
				else:
					_request_retry()
		1:
			if x >= $Checkpoints/Zone3.position.x:
				if balloon.collision_count == _stage_collisions:
					_advance()
				else:
					_request_retry()
		2:
			if x > box.position.x + 120 and balloon.items.collected == 0:
				_request_retry()
			elif x > target.position.x + 100 and not target_hit and combat.get_child_count() == 0:
				_request_retry()
			elif x >= $Checkpoints/Zone4.position.x and target_hit:
				_advance()
		3:
			turbo_used = turbo_used or (balloon.items.turbo_charges == 0 and balloon.items.boost_left > 0)
			wind_entered = wind_entered or balloon.items.wind_zones.has(wind)
			wind_crossed = wind_crossed or (wind_entered and x - Balloon.HALF_WIDTH > wind.position.x + wind.size.x * 0.5)
			if x >= $TrainingTrack/References/Finish.position.x:
				if turbo_used and wind_crossed:
					_complete()
				else:
					_request_retry()
	_update_hud()


func _projectile_hit(collider: Object, source: Balloon, kind: BalloonItems.Kind) -> void:
	if stage == 2 and collider == target and source == balloon and kind == BalloonItems.Kind.ROCKET:
		target_hit = true
		target.hit = true
		_feedback("¡Diana! Sigue adelante")


func _advance() -> void:
	stage += 1
	_stage_collisions = balloon.collision_count
	if stage == 3:
		balloon.items.initialize_turbo(1, 0)
	_feedback("¡Etapa completada!")


func _request_retry() -> void:
	if _retry_pending:
		return
	_retry_pending = true
	retry_stage.call_deferred()


func retry_stage() -> void:
	if completed:
		return
	_retry_pending = false
	retries += 1
	for obstacle in balloon._ignored_obstacles:
		if is_instance_valid(obstacle):
			balloon.remove_collision_exception_with(obstacle)
	balloon._ignored_obstacles.clear()
	balloon.impact_time_left = 0
	balloon.protection_time_left = 0
	balloon._horizontal_rebound = 0
	balloon.impact_tint = Color.WHITE
	balloon.velocity = Vector2.ZERO
	balloon.burner_active = false
	balloon.position = $Checkpoints.get_child(stage).position
	var items: BalloonItems = balloon.items
	items.equipped = BalloonItems.Kind.NONE
	items.boost_left = 0
	items.hit_left = 0
	items.protection_left = 0
	items.storm_left = 0
	items.storm_warning_left = 0
	items.storm_protection_left = 0
	items.wind_zones.clear()
	items.collected = 0
	items.used = 0
	items.initialize_turbo(1 if stage == 3 else 0, 0)
	for projectile in combat.get_children():
		projectile.queue_free()
	get_node("/root/Music").clear_effects()
	box.consumed = false
	box._respawn_left = 0
	box._blocked_collectors.clear()
	box.show()
	if stage == 0:
		saw_burner = false
		rose = false
		descended = false
	if stage == 2:
		target_hit = false
		target.hit = false
	if stage == 3:
		turbo_used = false
		wind_entered = false
		wind_crossed = false
	_stage_collisions = balloon.collision_count
	_last_x = balloon.position.x
	_blocked_left = 0
	balloon.visual.refresh()
	_feedback("Probemos de nuevo desde esta etapa")
	_update_camera()
	_update_hud()


func _feedback(message: String) -> void:
	feedback.text = tr(message)
	_feedback_left = 3.0


func _update_hud() -> void:
	$HUD/Info/Rows/Progress.text = tr("ACADEMIA DE VUELO · %d/4 · SPACE: pausa") % (stage + 1)
	match stage:
		0:
			instruction.text = tr("Mantén ↑ para subir") if not saw_burner else (tr("¡Bien! Suelta ↑ para descender") if not descended else tr("El globo tiene inercia. Anticipa tus movimientos"))
		1:
			instruction.text = tr("Esquiva los obstáculos controlando tu altura") if balloon.position.x < 5500 else tr("¡Recuerda! El globo tarda en cambiar de dirección")
		2:
			instruction.text = tr("Recoge la caja para conseguir un objeto") if balloon.items.collected == 0 else (tr("Pulsa A para utilizar tu cohete") if balloon.items.equipped != BalloonItems.Kind.NONE else (tr("¡Diana alcanzada! Continúa") if target_hit else tr("El cohete va hacia delante; puedes repetir la etapa")))
		3:
			instruction.text = tr("Pulsa D para activar tu turbo") if not turbo_used else (tr("¡Atraviesa la corriente de viento para acelerar!") if not wind_crossed else tr("¡Muy bien! Cruza la meta del entrenamiento"))
	$HUD/Debug.text = "Etapa: %d · Reintentos: %d\nVX %.1f · VY %.1f\nQuemador: %s · Objeto: %s\nTurbo: %d · Viento: %.2f\nAscenso/descenso: %s/%s · Diana: %s" % [stage + 1, retries, balloon.velocity.x, balloon.velocity.y, balloon.burner_active, balloon.items.item_name(), balloon.items.turbo_charges, balloon.items.wind_multiplier(), rose, descended, target_hit]


func _process(_delta: float) -> void:
	visibility.update_visuals(_delta)
	_update_camera()


func _update_camera() -> void:
	camera.zoom = Vector2.ONE * get_viewport_rect().size.y / 720.0
	camera.position = Vector2(balloon.position.x + camera_look_ahead, 360)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug") and not event.is_echo():
		$HUD/Debug.visible = not $HUD/Debug.visible
		get_viewport().set_input_as_handled()


func _complete() -> void:
	completed = true
	balloon.stop_racing()
	combat.enabled = false
	$HUD/Overlay.pause_allowed = false
	$HUD/Info.hide()
	$HUD/Complete.show()
	$HUD/Complete/Rows/Race.grab_focus()
	get_node("/root/Music").set_theme("menu")


func _restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _race() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
