extends CanvasLayer

## Presentation only. Existing Main nodes remain the public HUD references.
@export_range(0.02, 0.2, 0.01) var refresh_seconds: float = 0.05
@export var safe_margin: float = 16.0
var main: Node2D
var leaderboard: VBoxContainer
var pause_button: Button
var _rows: Array[Control] = []
var _left: float = 0.0
var _last_place: int = 0
var _place_tween: Tween


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_left = 0.0


func configure(race: Node2D) -> void:
	main = race
	# Use the existing labels and their sources, rather than a second HUD model.
	$Hint.hide()
	$ItemStatus.use_hud_skin = true
	$ItemStatus.build_skin()
	var position_frame := HudStyle.image($RacePosition, "panel_position", Rect2(-38, -28, 174, 115))
	position_frame.z_index = -1
	_style_label($RacePosition, 38)
	var timer_frame := HudStyle.image($RaceOverlay/Clock, "panel_timer", Rect2(-65, -16, 270, 82))
	timer_frame.z_index = -1
	_style_label($RaceOverlay/Clock, 30)
	$RaceOverlay.compact_clock = true
	var sector_frame := HudStyle.image($TrackTitle, "panel_sector", Rect2(-10, -6, 270, 64))
	sector_frame.z_index = -1
	_style_label($TrackTitle, 17)
	$TrackTitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	leaderboard = VBoxContainer.new()
	leaderboard.name = "Leaderboard"
	leaderboard.mouse_filter = Control.MOUSE_FILTER_IGNORE
	leaderboard.add_theme_constant_override("separation", 0)
	add_child(leaderboard)
	for racer in main.competitors:
		var row := Control.new()
		row.set_script(preload("res://scripts/hud_racer_row.gd"))
		leaderboard.add_child(row)
		_rows.append(row)
	pause_button = Button.new()
	pause_button.name = "PauseButton"
	pause_button.text = "Ⅱ"
	pause_button.add_theme_font_size_override("font_size", 28)
	for state in ["normal", "hover", "pressed"]:
		pause_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	MenuStyle.focus(pause_button)
	pause_button.tooltip_text = tr("Pausa") + " · " + HudStyle.binding("pause")
	pause_button.pressed.connect($RaceOverlay.toggle_pause)
	add_child(pause_button)
	var pause_frame := HudStyle.image(pause_button, "button_pause", Rect2(0, 0, 54, 54))
	pause_frame.z_index = -1
	# Empty, hidden and input-transparent. No mobile behavior is implemented.
	var future_mobile := Control.new()
	future_mobile.name = "MobileControls"
	future_mobile.hide()
	future_mobile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(future_mobile)
	get_viewport().size_changed.connect(_layout)
	refresh()
	_layout()


func _style_label(label: Label, font_size: int) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("fff3c5"))
	label.add_theme_color_override("font_outline_color", Color("112440"))
	label.add_theme_constant_override("outline_size", 3)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.clip_text = false


func _place(control: Control, rect: Rect2) -> void:
	control.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	control.position = rect.position
	control.size = rect.size


func _layout() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	_place($ItemStatus, Rect2(safe_margin, safe_margin, 270, 162))
	_place($RaceOverlay/Clock, Rect2(viewport_size.x * 0.5 - 65, safe_margin + 9, 185, 50))
	_place($TrackTitle, Rect2(viewport_size.x * 0.5 - 125, safe_margin + 64, 250, 52))
	_place($RacePosition, Rect2(viewport_size.x - safe_margin - 146, safe_margin + 22, 106, 62))
	_place(leaderboard, Rect2(viewport_size.x - safe_margin - 232, safe_margin + 100, 232, 256))
	_place($TrackProgress, Rect2(viewport_size.x * 0.5 - 170, viewport_size.y - 42, 340, 10))
	_place(pause_button, Rect2(safe_margin, viewport_size.y - safe_margin - 54, 54, 54))
	_place($StormWarning, Rect2(viewport_size.x * 0.5 - 230, safe_margin + 130, 460, 32))
	# Help exists only when F2 debug is visible.
	_place($Hint, Rect2(90, viewport_size.y - 36, 440, 28))
	_place($DebugPanel, Rect2(safe_margin, 190, 300, 400))


func _process(delta: float) -> void:
	if main == null:
		return
	_left -= delta
	if _left <= 0:
		_left = refresh_seconds
		refresh()


func refresh() -> void:
	var in_results: bool = main.race_flow.state == RaceFlow.State.RESULTS
	for node in [$ItemStatus, $TrackTitle, $TrackProgress, $RacePosition, leaderboard, pause_button]:
		node.visible = not in_results
	$Hint.visible = $DebugPanel.visible and not in_results
	$RaceOverlay/Clock.visible = not in_results
	pause_button.disabled = not main.race_flow.enabled
	var place: int = main.standings.get_place(main.balloon)
	$RacePosition.text = "%d/%d" % [place, main.competitors.size()]
	if _last_place != 0 and _last_place != place:
		_place_tween = HudStyle.pop($RacePosition, _place_tween)
	_last_place = place
	$TrackTitle.text = tr("%s\nTramo %d/%d") % [tr(main.track.track_name), main.track.get_zone_index(main.balloon.global_position.x) + 1, main.track.zones.get_child_count()]
	$TrackProgress.value = main.track.get_progress(main.balloon.global_position.x) * 100.0
	for index in main.standings.order.size():
		var racer: Balloon = main.standings.order[index]
		_rows[index].refresh(racer, index + 1, main.track.get_progress(racer.global_position.x))
