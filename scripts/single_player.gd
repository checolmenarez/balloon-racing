extends Node2D

@export var config: SinglePlayerConfig = preload("res://resources/default_single_player.tres")
## Positive seeds reproduce the same segment sequence. Zero creates a fresh attempt.
@export var run_seed: int = 0

@onready var balloon: Balloon = $PlayerBalloon
@onready var camera: Camera2D = $Camera2D
@onready var segments: SinglePlayerSegmentManager = $SegmentManager
@onready var health: HealthComponent = $HealthComponent
@onready var health_bar: ProgressBar = $HUD/Top/Rows/Health
@onready var coins_label: Label = $HUD/Top/Rows/Stats/Coins
@onready var distance_label: Label = $HUD/Top/Rows/Stats/Distance
@onready var best_label: Label = $HUD/Top/Rows/Stats/Best
@onready var intro: Control = $HUD/Intro
@onready var pause_panel: Control = $HUD/PausePanel
@onready var game_over_panel: Control = $HUD/GameOver
@onready var record_notice: Label = $HUD/RecordNotice

var save := SinglePlayerSave.new()
var coins: int = 0
var distance: float = 0.0
var survival_time: float = 0.0
var current_speed: float = 0.0
var observed_horizontal_speed: float = 0.0
var peak_horizontal_speed: float = 0.0
var active_seed: int = 0
var started: bool = false
var game_over: bool = false
var _last_collision_count: int = 0
var _record_announced: bool = false
var _coin_combo: int = 0
var _combo_left: float = 0.0
var _record_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	save.load_data()
	RaceSelection.apply_characters([balloon])
	balloon.physics = balloon.physics.duplicate(true)
	balloon.physics.horizontal_speed = config.initial_speed
	balloon.physics.impact_protection_time = config.impact_protection_seconds
	balloon.set_vertical_bounds(32.0, 640.0)
	balloon.items.initialize_turbo(0, 0.0)
	current_speed = config.initial_speed
	health.reset(config.maximum_health, config.impact_protection_seconds)
	health.health_changed.connect(_on_health_changed)
	health.depleted.connect(_finish_attempt)
	segments.coin_collected.connect(_collect_coin)
	segments.star_collected.connect(_collect_star)
	if run_seed > 0:
		active_seed = run_seed
	else:
		var attempt_rng := RandomNumberGenerator.new()
		attempt_rng.randomize()
		active_seed = attempt_rng.randi_range(1, 2147483647)
	segments.setup(config, active_seed)
	$HUD/Top/Rows/Stats/Pause.pressed.connect(_toggle_pause)
	$HUD/Intro/Panel/Rows/Play.pressed.connect(_start_attempt)
	$HUD/Intro/Panel/Rows/HideAndPlay.pressed.connect(_hide_intro_and_start)
	$HUD/PausePanel/Panel/Rows/Continue.pressed.connect(_resume)
	$HUD/PausePanel/Panel/Rows/Restart.pressed.connect(_restart)
	$HUD/PausePanel/Panel/Rows/Home.pressed.connect(_home)
	$HUD/GameOver/Panel/Rows/Retry.pressed.connect(_restart)
	$HUD/GameOver/Panel/Rows/Home.pressed.connect(_home)
	_setup_audio()
	get_node("/root/Music").clear_effects()
	get_node("/root/Music").set_theme("race")
	intro.visible = not save.hide_intro
	balloon.racing = false
	_update_hud()
	_update_camera()
	if save.hide_intro:
		_start_attempt()


func _physics_process(delta: float) -> void:
	if get_tree().paused or not started or game_over:
		return
	health.tick(delta)
	survival_time += delta
	distance = maxf(distance, balloon.position.x - 240.0)
	var target_speed := config.target_speed(distance)
	current_speed = move_toward(current_speed, target_speed, config.initial_speed * config.speed_smoothing * delta)
	balloon.physics.horizontal_speed = current_speed
	observed_horizontal_speed = balloon.velocity.x
	peak_horizontal_speed = maxf(peak_horizontal_speed, observed_horizontal_speed)
	segments.ensure_segments(balloon.position.x)
	if balloon.collision_count > _last_collision_count:
		_last_collision_count = balloon.collision_count
		health.damage(config.collision_damage)
	_combo_left = maxf(0.0, _combo_left - delta)
	if _combo_left == 0.0:
		_coin_combo = 0
	if not _record_announced and distance >= 500.0 and distance > save.best_distance:
		_record_announced = true
		_show_record_notice()
	_update_hud()


func _process(_delta: float) -> void:
	if not get_tree().paused:
		_update_camera()


func _update_camera() -> void:
	camera.zoom = Vector2.ONE * get_viewport_rect().size.y / 720.0
	camera.position = Vector2(balloon.position.x + 280.0, 360.0)


func _start_attempt() -> void:
	if game_over:
		return
	intro.hide()
	started = true
	balloon.racing = true
	balloon.collision_layer = 1
	balloon.visual.refresh()


func _hide_intro_and_start() -> void:
	save.hide_intro = true
	save.save_data()
	_start_attempt()


func _collect_coin(coin: SinglePlayerCoin) -> void:
	if game_over:
		return
	coins += 1
	_coin_combo = _coin_combo + 1 if _combo_left > 0.0 else 1
	_combo_left = 0.45
	var pitch := 1.0 + minf(_coin_combo - 1, 5) * 0.035
	get_node("/root/Music").play_effect("coin", coin.global_position, pitch)
	_pulse_control(coins_label, Color("fff2a1"))
	_update_hud()


func _collect_star(star: MagicStar) -> void:
	if game_over:
		return
	health.heal(config.star_healing)
	get_node("/root/Music").play_effect("magic_star", star.global_position)
	_pulse_control(health_bar, Color("8fffd4"))


func _on_health_changed(current: int, maximum: int, delta: int) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	if delta < 0:
		_pulse_control(health_bar, Color("ff7b7b"))
	elif delta > 0:
		_pulse_control(health_bar, Color("8fffd4"))


func _finish_attempt() -> void:
	if game_over:
		return
	game_over = true
	started = false
	segments.generation_enabled = false
	balloon.stop_racing()
	get_node("/root/Music").clear_effects()
	get_node("/root/Music").play_effect("game_over", balloon.global_position)
	var new_record := save.register_attempt(distance, coins)
	$HUD/GameOver/Panel/Rows/Title.text = tr("¡FIN DEL VUELO!")
	$HUD/GameOver/Panel/Rows/Results.text = tr("Tiempo: %s\nDistancia: %s\nMonedas: %d\nMejor distancia: %s") % [_format_time(survival_time), _format_distance(distance), coins, _format_distance(save.best_distance)]
	$HUD/GameOver/Panel/Rows/NewRecord.visible = new_record
	game_over_panel.show()
	$HUD/GameOver/Panel/Rows/Retry.grab_focus()


func _update_hud() -> void:
	health_bar.max_value = health.maximum_health
	health_bar.value = health.current_health
	coins_label.text = tr("MONEDAS  %d") % coins
	distance_label.text = tr("DISTANCIA  %s") % _format_distance(distance)
	best_label.text = tr("RÉCORD  %s") % _format_distance(maxf(save.best_distance, distance if _record_announced else save.best_distance))


func _show_record_notice() -> void:
	record_notice.text = tr("¡NUEVO RÉCORD!")
	record_notice.show()
	get_node("/root/Music").play_effect("record", balloon.global_position)
	if _record_tween != null:
		_record_tween.kill()
	record_notice.modulate.a = 1.0
	record_notice.scale = Vector2.ONE * 0.8
	_record_tween = create_tween().set_parallel()
	_record_tween.tween_property(record_notice, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)
	_record_tween.chain().tween_interval(1.0)
	_record_tween.chain().tween_property(record_notice, "modulate:a", 0.0, 0.35)


func _pulse_control(control: Control, tint: Color) -> void:
	control.pivot_offset = control.size * 0.5
	control.modulate = tint
	control.scale = Vector2.ONE * 1.12
	var tween := create_tween().set_parallel()
	tween.tween_property(control, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)
	tween.tween_property(control, "modulate", Color.WHITE, 0.22)


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause") or event.is_echo() or intro.visible or game_over:
		return
	get_viewport().set_input_as_handled()
	_toggle_pause()


func _toggle_pause() -> void:
	if game_over or intro.visible:
		return
	if get_tree().paused:
		_resume()
	else:
		get_tree().paused = true
		pause_panel.show()
		$HUD/PausePanel/Panel/Rows/Continue.grab_focus()


func _resume() -> void:
	get_tree().paused = false
	pause_panel.hide()


func _restart() -> void:
	get_tree().paused = false
	get_node("/root/Music").clear_effects()
	get_tree().reload_current_scene()


func _home() -> void:
	get_tree().paused = false
	get_node("/root/Music").clear_effects()
	get_node("/root/Music").set_theme("menu")
	get_tree().change_scene_to_file("res://scenes/StartMenu.tscn")


func _format_distance(value: float) -> String:
	return "%d m" % roundi(maxf(0.0, value) / 10.0)


func _format_time(value: float) -> String:
	return "%02d:%02d" % [floori(value / 60.0), floori(fmod(value, 60.0))]


func _setup_audio() -> void:
	var music := get_node("/root/Music")
	music.register_effect("coin", _tone_stream([880.0, 1174.0], 0.11, 0.42))
	music.register_effect("magic_star", _tone_stream([523.0, 659.0, 784.0], 0.24, 0.28))
	music.register_effect("record", _tone_stream([659.0, 880.0, 1046.0], 0.28, 0.24))
	music.register_effect("game_over", _tone_stream([392.0, 330.0, 262.0], 0.34, 0.34))


func _tone_stream(frequencies: Array[float], duration: float, volume: float) -> AudioStreamWAV:
	var rate := 22050
	var sample_count := maxi(1, roundi(duration * rate))
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for sample in sample_count:
		var t := float(sample) / rate
		var envelope := pow(1.0 - float(sample) / sample_count, 2.0)
		var wave := 0.0
		for index in frequencies.size():
			var start := duration * float(index) / frequencies.size()
			if t >= start:
				wave += sin(TAU * frequencies[index] * (t - start)) / frequencies.size()
		data.encode_s16(sample * 2, roundi(clampf(wave * envelope * volume, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = data
	return stream
