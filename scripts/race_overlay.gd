extends Control

var flow: RaceFlow
var standalone_restart: Callable
var pause_allowed: bool = true
var _results_shown: bool = false
var _results_background: TextureRect
@onready var countdown: Label = $Countdown
@onready var clock_label: Label = $Clock
@onready var results: PanelContainer = $Results
@onready var pause_panel: PanelContainer = $PausePanel


func _ready() -> void:
	_results_background = MenuStyle.background(self)
	_results_background.z_index = 20
	_results_background.hide()
	results.z_index = 21
	results.add_theme_stylebox_override("panel", MenuStyle.box("components/podium_panel.png", 24))
	MenuStyle.button($Results/Rows/Restart, true)
	MenuStyle.button($Results/Rows/Home)
	$Results/Rows/Home.pressed.connect(_home)
	$Results/Rows/Restart.pressed.connect(func() -> void: flow.restart.call_deferred())
	$PausePanel/Rows/Continue.pressed.connect(_resume)
	$PausePanel/Rows/Restart.pressed.connect(_restart)
	$PausePanel/Rows/Home.pressed.connect(_home)


func configure_standalone(restart: Callable) -> void:
	standalone_restart = restart
	countdown.hide()
	clock_label.hide()
	$PausePanel/Rows/Restart.text = "Reiniciar entrenamiento"
	$PausePanel/Rows/Home.show()


func _restart() -> void:
	get_tree().paused = false
	if standalone_restart.is_valid():
		standalone_restart.call_deferred()
	elif flow != null:
		flow.restart.call_deferred()


func _input(event: InputEvent) -> void:
	if not event.is_action("pause"):
		return
	# Handle before GUI ui_accept: SPACE resumes even if Restart has focus.
	get_viewport().set_input_as_handled()
	if event.is_echo() or not event.is_action_pressed("pause"):
		return
	if not pause_allowed or (not standalone_restart.is_valid() and (flow == null or not flow.enabled or flow.state == RaceFlow.State.RESULTS)):
		return
	if get_tree().paused:
		_resume()
	else:
		get_tree().paused = true
		pause_panel.show()
		$PausePanel/Rows/Continue.grab_focus()


func _resume() -> void:
	get_tree().paused = false
	pause_panel.hide()
	var focused: Control = get_viewport().gui_get_focus_owner()
	if focused != null and pause_panel.is_ancestor_of(focused):
		focused.release_focus()


func _process(_delta: float) -> void:
	if standalone_restart.is_valid():
		return
	if flow == null or not flow.enabled:
		hide()
		return
	countdown.visible = flow.state == RaceFlow.State.COUNTDOWN or (flow.state == RaceFlow.State.RUNNING and flow.elapsed < 0.75)
	countdown.text = str(ceili(flow.countdown_left)) if flow.state == RaceFlow.State.COUNTDOWN else "¡GO!"
	clock_label.text = "%.2f s" % flow.elapsed
	if flow.state == RaceFlow.State.WAITING:
		clock_label.text += " · Esperando llegadas…"
	if flow.state == RaceFlow.State.RESULTS and not _results_shown:
		_show_results()


func _show_results() -> void:
	_results_shown = true
	results.show()
	_results_background.show()
	for place in [2, 1, 3, 4]:
		if flow.standings.order.size() < place:
			continue
		var racer: Balloon = flow.standings.order[place - 1]
		var column := VBoxContainer.new()
		column.name = "Place%d" % place
		column.set_meta("racer", racer)
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var spacer := Control.new()
		spacer.custom_minimum_size.y = [0, 28, 44, 60][place - 1]
		column.add_child(spacer)
		var portrait := MenuStyle.image("portraits/%s_idle.png" % racer.character_id, 140)
		portrait.name = "Portrait"
		portrait.texture = MenuStyle.portrait(racer.character_id, ["happy", "normal", "angry", "surprised"][place - 1])
		column.add_child(portrait)
		var step := PanelContainer.new()
		step.custom_minimum_size.y = 68
		step.add_theme_stylebox_override("panel", MenuStyle.box("components/podium_%s.png" % ["gold", "silver", "bronze", "fourth"][place - 1]))
		var number := Label.new()
		number.name = "Position"
		number.text = "%d.º" % place
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		number.add_theme_font_size_override("font_size", 28)
		step.add_child(number)
		column.add_child(step)
		var name_label := Label.new()
		name_label.name = "Identity"
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.text = racer.competitor_name
		name_label.add_theme_font_size_override("font_size", 19)
		column.add_child(name_label)
		var local := Label.new()
		local.name = "Local"
		local.text = "TÚ" if racer.is_local_player else ""
		local.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		local.add_theme_color_override("font_color", Color("ffe275"))
		column.add_child(local)
		$Results/Rows/Podium.add_child(column)
	var lines: PackedStringArray = []
	for racer in flow.standings.order:
		var record: Dictionary = flow.record_for(racer)
		var identity: String = racer.competitor_name + (" · TÚ" if racer.is_local_player else "")
		if record.is_empty():
			lines.append("—  %s · Sin terminar · Choques %d · Objetos %d" % [identity, racer.collision_count, racer.items.used])
		else:
			lines.append("%d.º  %s · %.2f s · Choques %d · Objetos %d" % [record.place, identity, record.time, record.collisions, record.items])
	$Results/Rows/Classification.text = "\n".join(lines)
	$Results/Rows/Restart.grab_focus()


func _home() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/StartMenu.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if _results_shown and event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		_home()
