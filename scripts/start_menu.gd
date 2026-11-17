extends Control

@export var reduce_motion: bool = false
@export_range(0.0, 8.0) var bob_amplitude: float = 4.0
@export_range(1.0, 1.06) var selected_scale: float = 1.05
var _starting: bool = false
var _buttons: Array[Button] = []
var _art: Array[Texture2D] = []
var _scales: Dictionary = {}
var _bob: Tween
var _detail_tween: Tween
var _pulse: Tween
var _selected: int = -1
var _previous_snap: bool
var _portrait_origin: Vector2
var _bobbing_portrait: TextureRect
@onready var rows: VBoxContainer = $Center/Rows
@onready var details: HBoxContainer = $Center/Rows/Details/Content


func _ready() -> void:
	_previous_snap = get_viewport().gui_snap_controls_to_pixels
	get_viewport().gui_snap_controls_to_pixels = false
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	get_node("/root/Music").clear_effects()
	get_node("/root/Music").set_theme("menu")
	theme = preload("res://resources/ui_theme.tres").duplicate()
	theme.set_color("font_outline_color", "Label", Color("102a48"))
	theme.set_constant("outline_size", "Label", 2)
	$Center/Rows/Details.add_theme_stylebox_override("panel", _panel())
	_action_skin($Center/Rows/Play, true)
	_action_skin($Center/Rows/Back, false)
	var group := ButtonGroup.new()
	for index in SelectionProfiles.DATA.size():
		var profile: Dictionary = SelectionProfiles.DATA[index]
		var texture := load(profile.art_texture) as Texture2D
		_art.append(texture)
		var button := Button.new()
		button.name = profile.id
		button.custom_minimum_size = Vector2(0, 300)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggle_mode = true
		button.button_group = group
		button.tooltip_text = tr(profile.display_name)
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		for state in ["normal", "hover", "pressed", "hover_pressed"]:
			button.add_theme_stylebox_override(state, _sheet_box(Rect2(518, 0, 477, 482) if state in ["pressed", "hover_pressed"] else Rect2(110, 14, 410, 455)))
		MenuStyle.focus(button)
		button.pressed.connect(_select.bind(index))
		button.focus_entered.connect(_select.bind(index))
		button.mouse_entered.connect(_card_feedback.bind(index))
		button.mouse_exited.connect(_card_feedback.bind(index))
		button.button_down.connect(func() -> void: _feedback(button, 0.99, true))
		button.button_up.connect(_card_feedback.bind(index))
		$Center/Rows/Choices.add_child(button)
		_buttons.append(button)
		var content := VBoxContainer.new()
		button.add_child(content)
		content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		content.offset_left = 14
		content.offset_right = -14
		content.offset_top = 12
		content.offset_bottom = -26
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var portrait := TextureRect.new()
		portrait.name = "Portrait"
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.texture = texture
		portrait.custom_minimum_size.y = 200
		portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(portrait)
		for field in ["display_name", "short_role"]:
			var label := Label.new()
			label.text = tr(profile[field])
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			label.add_theme_font_size_override("font_size", 19 if field == "display_name" else 14)
			content.add_child(label)
	for index in _buttons.size():
		var button := _buttons[index]
		button.focus_neighbor_left = button.get_path_to(_buttons[posmod(index - 1, 4)])
		button.focus_neighbor_right = button.get_path_to(_buttons[(index + 1) % 4])
		button.focus_neighbor_bottom = button.get_path_to($Center/Rows/Play)
		button.focus_next = button.get_path_to(_buttons[index + 1] if index < 3 else $Center/Rows/Play)
		button.focus_previous = button.get_path_to(_buttons[index - 1] if index > 0 else $Center/Rows/Back)
	$Center/Rows/Play.focus_next = $Center/Rows/Play.get_path_to($Center/Rows/Back)
	$Center/Rows/Play.focus_previous = $Center/Rows/Play.get_path_to(_buttons[3])
	$Center/Rows/Back.focus_next = $Center/Rows/Back.get_path_to(_buttons[0])
	$Center/Rows/Back.focus_previous = $Center/Rows/Back.get_path_to($Center/Rows/Play)
	$Center/Rows/Play.focus_neighbor_bottom = $Center/Rows/Play.get_path_to($Center/Rows/Back)
	$Center/Rows/Back.focus_neighbor_top = $Center/Rows/Back.get_path_to($Center/Rows/Play)
	resized.connect(_resize_layout)
	_resize_layout()
	var initial: int = RaceSelection.selected if RaceSelection.selected in range(4) else 0
	_select(initial)
	_buttons[initial].grab_focus()
	$Center/Rows/Play.pressed.connect(_play)
	$Center/Rows/Back.pressed.connect(_back)
	$Center/Rows/Play.text = tr("Comenzar vuelo") if RaceSelection.launch_mode == &"free_flight" else tr("Comenzar carrera")
	if not reduce_motion:
		_pulse = create_tween().set_loops()
		_pulse.tween_interval(3.0)
		_pulse.tween_property($Center/Rows/Play, "self_modulate", Color(1.12, 1.12, 1.08), 0.35)
		_pulse.tween_property($Center/Rows/Play, "self_modulate", Color.WHITE, 0.5)


func _input(event: InputEvent) -> void:
	if _starting:
		return
	# This project's ui_accept/ui_cancel contain keyboard events only.
	# Keep gamepad confirmation local; do not change gameplay's global InputMap.
	if event is InputEventJoypadButton and event.button_index in [JOY_BUTTON_A, JOY_BUTTON_B]:
		get_viewport().set_input_as_handled()
		if event.pressed:
			if event.button_index == JOY_BUTTON_B:
				_back()
			else:
				var focused := get_viewport().gui_get_focus_owner() as BaseButton
				if focused != null and not focused.disabled:
					focused.pressed.emit()
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_back()
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
		var direction := 1 if event.is_action_pressed("ui_right") else -1
		_buttons[posmod(_selected + direction, 4)].grab_focus()
		get_viewport().set_input_as_handled()


func _select(index: int) -> void:
	if _starting or index == _selected:
		return
	_stop_bob()
	var animate: bool = _selected >= 0 and not reduce_motion
	_selected = index
	RaceSelection.selected = index
	$Center/Rows/Play.focus_neighbor_top = $Center/Rows/Play.get_path_to(_buttons[index])
	for choice in _buttons.size():
		_buttons[choice].set_pressed_no_signal(choice == index)
		_card_feedback(choice)
	var profile: Dictionary = SelectionProfiles.DATA[index]
	details.get_node("Portrait").texture = _art[index]
	details.get_node("Text/Name").text = tr(profile.display_name)
	details.get_node("Text/Subtitle").text = tr(profile.subtitle)
	details.get_node("Text/Description").text = tr(profile.description)
	var tags: HBoxContainer = details.get_node("Text/Tags")
	for child in tags.get_children():
		tags.remove_child(child)
		child.queue_free()
	for tag in profile.tags:
		var label := Label.new()
		label.text = tr(tag)
		label.add_theme_font_size_override("font_size", 13)
		var style := StyleBoxFlat.new()
		style.bg_color = Color("24548c")
		style.set_corner_radius_all(8)
		style.content_margin_left = 9
		style.content_margin_right = 9
		style.content_margin_top = 2
		style.content_margin_bottom = 2
		label.add_theme_stylebox_override("normal", style)
		tags.add_child(label)
	if _detail_tween != null:
		_detail_tween.kill()
	if animate:
		_detail_tween = create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_detail_tween.tween_property(details, "modulate:a", 1.0, 0.16).from(0.4)
		_detail_tween.tween_property(details, "position:x", 16.0, 0.16).from(24.0)
	_start_bob.call_deferred()


func _card_feedback(index: int) -> void:
	var button := _buttons[index]
	var factor: float = selected_scale if index == _selected else (1.015 if button.is_hovered() else 1.0)
	_feedback(button, factor, button.is_hovered())


func _feedback(button: Button, factor: float, bright: bool) -> void:
	if _scales.has(button):
		_scales[button].kill()
	button.pivot_offset = button.size * 0.5
	var target := Vector2.ONE * (1.0 if reduce_motion else factor)
	var tint := Color(1.12, 1.12, 1.12) if bright else Color.WHITE
	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_scales[button] = tween
	tween.tween_property(button, "scale", target, 0.16)
	tween.tween_property(button, "modulate", tint, 0.12)


func _stop_bob() -> void:
	if _bob != null:
		_bob.kill()
	if is_instance_valid(_bobbing_portrait):
		_bobbing_portrait.position = _portrait_origin


func _start_bob() -> void:
	_stop_bob()
	if reduce_motion or _starting:
		return
	_bobbing_portrait = _buttons[_selected].get_child(0).get_node("Portrait")
	_portrait_origin = _bobbing_portrait.position
	# Linear phase through a sine: zero speed at the extremes, continuous at wrap.
	_bob = create_tween().set_loops()
	_bob.tween_method(_bob_phase, 0.0, TAU, 3.2)


func _bob_phase(phase: float) -> void:
	_bobbing_portrait.position.y = _portrait_origin.y + sin(phase) * bob_amplitude


func _sheet_box(region: Rect2, target_height: int = 0) -> StyleBoxTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = preload("res://assets/ui/character_selection/ui_sheet_character_select.png")
	atlas.region = region
	atlas.filter_clip = true
	var box := StyleBoxTexture.new()
	box.texture = atlas
	if target_height > 0:
		var patch: Image = atlas.atlas.get_image().get_region(region)
		patch.resize(roundi(patch.get_width() * float(target_height) / patch.get_height()), target_height, Image.INTERPOLATE_LANCZOS)
		box.texture = ImageTexture.create_from_image(patch)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		box.set_texture_margin(side, 12 if target_height > 0 else 18)
		box.set_content_margin(side, 0)
	return box


func _panel() -> StyleBoxFlat:
	# Sheet-inspired plain panel: flags/skull would interfere with translated prose.
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("102f54ee")
	panel.border_color = Color("428acd")
	panel.set_border_width_all(2)
	panel.set_corner_radius_all(16)
	panel.content_margin_left = 16
	panel.content_margin_right = 16
	panel.content_margin_top = 8
	panel.content_margin_bottom = 8
	return panel


func _action_skin(button: Button, primary: bool) -> void:
	button.custom_minimum_size.x = 380 if primary else 220
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var y: float = 750 if primary else 875
	for state in ["normal", "hover", "pressed", "hover_pressed"]:
		var x: float = 32 if state == "normal" else (493 if state == "hover" else 967)
		button.add_theme_stylebox_override(state, _sheet_box(Rect2(x, y, 450, 110 if primary else 100), 48 if primary else 34))
	for state in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
		button.add_theme_color_override(state, Color("40280d") if primary else Color.WHITE)
	MenuStyle.focus(button)
	button.mouse_entered.connect(func() -> void: _feedback(button, 1.02, true))
	button.mouse_exited.connect(func() -> void: _feedback(button, 1.0, false))


func _back() -> void:
	if not _starting:
		_starting = true
		get_tree().change_scene_to_file("res://scenes/StartMenu.tscn")


func _play() -> void:
	if _starting:
		return
	_starting = true
	$Center/Rows/Play.disabled = true
	get_tree().change_scene_to_file(RaceSelection.scene_for_launch_mode())


func _resize_layout() -> void:
	rows.custom_minimum_size.x = minf(1160.0, size.x - 64.0)
	for button in _buttons:
		button.pivot_offset = button.size * 0.5


func _exit_tree() -> void:
	_stop_bob()
	for tween in _scales.values():
		tween.kill()
	if _pulse != null:
		_pulse.kill()
	if _detail_tween != null:
		_detail_tween.kill()
	get_viewport().gui_snap_controls_to_pixels = _previous_snap
