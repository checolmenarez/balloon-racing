extends Control

const ART: String = "res://assets/ui/home/"
## Assign the real training scene when it exists; never redirect to a fake mode.
@export_file("*.tscn") var training_scene: String = "res://scenes/Training.tscn"
@export_range(0.0, 12.0) var float_amplitude: float = 6.0
@export var float_periods := Vector4(3.4, 2.8, 3.8, 3.1)
@export_range(0.0, 2.0) var sway_degrees: float = 1.2
@export var reduce_motion: bool = false
var _time: float = 0.0
var _origin_offsets: Array[float] = []
var _bottom_offsets: Array[float] = []
var _previous_gui_snap: bool
var _logo_tween: Tween
static var _button_textures: Dictionary = {}
var _animations: Dictionary = {}
var _return_focus: Button
var _leaving: bool = false
@onready var buttons: VBoxContainer = $Layout/Rows/Buttons
@onready var music: AudioStreamPlayer = get_node("/root/Music")


func _ready() -> void:
	_previous_gui_snap = get_viewport().gui_snap_controls_to_pixels
	# GUI snapping quantizes the subpixel sine wave. Restore it when leaving Home.
	get_viewport().gui_snap_controls_to_pixels = false
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	$Layout/Rows/Logo.texture = _trimmed($Layout/Rows/Logo.texture)
	for character in $Characters.get_children():
		character.texture = _trimmed(character.texture)
	music.clear_effects()
	music.set_theme("menu")
	$Layout/Rows/Buttons/Training.disabled = training_scene.is_empty() or not ResourceLoader.exists(training_scene)
	$Layout/Rows/Buttons/Training.tooltip_text = "Entrenamiento no disponible" if $Layout/Rows/Buttons/Training.disabled else "Practicar vuelo"
	$Layout/Rows/Buttons/Race.text = "¡CORRER!"
	$Layout/Rows/Hint.text = "Tu corredor: %s   |   Mouse / Flechas / Tab + Enter" % RaceSelection.NAMES[RaceSelection.selected]
	$Layout/Rows/Buttons/Help.text = "Cómo jugar"
	$Help/Panel/Rows/Title.text = "Cómo jugar"
	$Help/Panel/Rows/Instructions.text = "↑  Mantener para subir; soltar para descender.\nZ  Usar el objeto equipado.\nSPACE  Activar una carga de turbo personal.\nESC  Pausar o continuar la carrera.\nF2  Mostrar u ocultar la depuración.\n\nEsquiva obstáculos, recoge cajas y alcanza la meta.\nTienes dos cargas de turbo; la primera está\ndisponible cinco segundos después de GO."
	$Options/Panel/Rows/MusicLabel.text = "Música"
	$Options/Panel/Rows/EffectsLabel.text = "Efectos de sonido"
	$Options/Panel/Rows/Title.text = "Opciones"
	var motion := CheckButton.new()
	motion.name = "ReducedMotion"
	motion.text = "Reducir movimiento y efectos"
	motion.button_pressed = GameFeel.reduced_motion
	motion.toggled.connect(func(enabled: bool) -> void: GameFeel.reduced_motion = enabled)
	$Options/Panel/Rows.add_child(motion)
	$Options/Panel/Rows.move_child(motion, $Options/Panel/Rows/Back.get_index())
	for panel in [$Help/Panel, $Options/Panel]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("19394bea")
		style.set_corner_radius_all(18)
		style.content_margin_left = 32
		style.content_margin_right = 32
		style.content_margin_top = 28
		style.content_margin_bottom = 28
		panel.add_theme_stylebox_override("panel", style)
	var icons: Array[String] = ["race", "race", "training", "help", "settings"]
	for index in buttons.get_child_count():
		var button: Button = buttons.get_child(index)
		_skin(button, index == 0, icons[index])
		button.mouse_entered.connect(_highlight.bind(button, true))
		button.mouse_exited.connect(_highlight.bind(button, false))
		button.focus_entered.connect(_highlight.bind(button, true))
		button.focus_exited.connect(_highlight.bind(button, false))
	var available: Array[Button] = []
	for button in buttons.get_children():
		if not button.disabled:
			available.append(button)
	for index in available.size():
		var button: Button = available[index]
		button.focus_neighbor_top = button.get_path_to(available[posmod(index - 1, available.size())])
		button.focus_neighbor_bottom = button.get_path_to(available[(index + 1) % available.size()])
		button.focus_previous = button.focus_neighbor_top
		button.focus_next = button.focus_neighbor_bottom
	$Layout/Rows/Buttons/Race.pressed.connect(_race)
	$Layout/Rows/Buttons/Selection.pressed.connect(_selection)
	$Layout/Rows/Buttons/Training.pressed.connect(_training)
	$Layout/Rows/Buttons/Help.pressed.connect(_open_panel.bind($Help, $Layout/Rows/Buttons/Help))
	$Layout/Rows/Buttons/Options.pressed.connect(_open_panel.bind($Options, $Layout/Rows/Buttons/Options))
	$Help/Panel/Rows/Back.pressed.connect(_back)
	$Options/Panel/Rows/Back.pressed.connect(_back)
	$Options/Panel/Rows/Music.value = music.audio_level("Music") * 100.0
	$Options/Panel/Rows/Effects.value = music.audio_level("SFX") * 100.0
	$Options/Panel/Rows/Music.value_changed.connect(func(value: float) -> void: music.set_audio_level("Music", value / 100.0))
	$Options/Panel/Rows/Effects.value_changed.connect(func(value: float) -> void: music.set_audio_level("SFX", value / 100.0))
	for character in $Characters.get_children():
		_origin_offsets.append(character.offset_top)
		_bottom_offsets.append(character.offset_bottom)
	_process(0.0)
	$Layout/Rows/Buttons/Race.grab_focus()
	_enter_logo.call_deferred()


func _skin(button: Button, primary: bool, icon_name: String) -> void:
	# Regions in the supplied 1448 ? 1086 sheet; update these if artwork is repacked.
	var regions: Array = [Rect2(22, 85, 700, 260), Rect2(734, 85, 704, 260), Rect2(350, 363, 750, 255)] if primary else [Rect2(60, 642, 650, 216), Rect2(742, 642, 649, 216), Rect2(410, 870, 635, 197)]
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var index: int = 1 if state == "hover" else (2 if state in ["pressed", "hover_pressed"] else 0)
		var style := StyleBoxTexture.new()
		# Scale the source before nine-slicing so the circular badge stays round.
		var cache_key := Vector2i(int(primary), index)
		if not _button_textures.has(cache_key):
			var source := load(ART + "buttons/buttons_sheet.png") as Texture2D
			var patch: Image = source.get_image().get_region(regions[index])
			var height: int = 86 if primary else 64
			patch.resize(roundi(patch.get_width() * float(height) / patch.get_height()), height, Image.INTERPOLATE_LANCZOS)
			_button_textures[cache_key] = ImageTexture.create_from_image(patch)
		style.texture = _button_textures[cache_key]
		style.texture_margin_left = 90.0
		style.texture_margin_right = 50.0
		style.content_margin_left = 94.0
		style.content_margin_right = 30.0
		style.content_margin_top = 0.0
		style.content_margin_bottom = 0.0
		button.add_theme_stylebox_override(state, style)
	button.add_theme_color_override("font_disabled_color", Color("665d51"))
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color("fff6b0")
	focus.set_border_width_all(3)
	focus.set_corner_radius_all(32)
	button.add_theme_stylebox_override("focus", focus)
	# Icons remain separate from editable button text. Selection uses the flag.
	var icon_regions: Dictionary = {"race": Rect2(0, 0, 625, 625), "training": Rect2(625, 0, 629, 625), "help": Rect2(0, 625, 625, 629), "settings": Rect2(625, 625, 629, 629)}
	var icon_texture := _region("icons/icons_sheet.png", icon_regions[icon_name])
	# Draw the icon over the badge, independently of the text layout.
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.position = Vector2(15, 17 if primary else 10)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.texture = icon_texture
	icon.size = Vector2(52, 52) if primary else Vector2(44, 44)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(icon)
	button.expand_icon = true
	button.add_theme_constant_override("h_separation", 0)
	button.add_theme_font_size_override("font_size", 32 if primary else 22)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, Color("3e2517"))


func _highlight(button: Button, active: bool) -> void:
	if _animations.has(button):
		_animations[button].kill()
	var tween: Tween = create_tween()
	_animations[button] = tween
	var lit: bool = active or button.has_focus() or button.is_hovered()
	tween.tween_property(button, "modulate", Color(1.08, 1.08, 1.08) if lit else Color.WHITE, 0.15)


func _process(delta: float) -> void:
	if _leaving or not $Characters.visible:
		return
	_time += delta
	for index in $Characters.get_child_count():
		var character: TextureRect = $Characters.get_child(index)
		var phase: float = _time * TAU / maxf(0.1, float_periods[index]) + index * 1.7
		var displacement: float = 0.0 if reduce_motion or GameFeel.reduced_motion else sin(phase) * float_amplitude
		# Both edges use immutable baselines: no resize/drift feedback from current size.
		character.offset_top = _origin_offsets[index] + displacement
		character.offset_bottom = _bottom_offsets[index] + displacement
		character.pivot_offset = character.size * Vector2(0.5, 0.65)
		character.rotation = 0.0 if reduce_motion or GameFeel.reduced_motion else deg_to_rad(sway_degrees) * sin(phase + 0.5)
	if (reduce_motion or GameFeel.reduced_motion) and _logo_tween != null and _logo_tween.is_running():
		_logo_tween.kill()
		$Layout/Rows/Logo.scale = Vector2.ONE


func _enter_logo() -> void:
	if reduce_motion or GameFeel.reduced_motion or _leaving:
		return
	var logo: TextureRect = $Layout/Rows/Logo
	logo.pivot_offset = logo.size * 0.5
	logo.scale = Vector2.ONE * 0.95
	_logo_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_logo_tween.tween_property(logo, "scale", Vector2.ONE, 0.5)


func _exit_tree() -> void:
	set_process(false)
	if _logo_tween != null:
		_logo_tween.kill()
	for tween in _animations.values():
		tween.kill()
	get_viewport().gui_snap_controls_to_pixels = _previous_gui_snap


func _race() -> void:
	if _leaving:
		return
	_leaving = true
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _selection() -> void:
	if _leaving:
		return
	_leaving = true
	get_tree().change_scene_to_file("res://scenes/CharacterSelect.tscn")


func _training() -> void:
	if not _leaving and not training_scene.is_empty() and ResourceLoader.exists(training_scene):
		_leaving = true
		get_tree().change_scene_to_file(training_scene)


func _open_panel(panel: Control, from_button: Button) -> void:
	_return_focus = from_button
	$Layout.hide()
	$Characters.hide()
	panel.show()
	if panel == $Options:
		$Options/Panel/Rows/Music.grab_focus()
	else:
		$Help/Panel/Rows/Back.grab_focus()


func _back() -> void:
	$Help.hide()
	$Options.hide()
	$Layout.show()
	$Characters.show()
	if is_instance_valid(_return_focus):
		_return_focus.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		_back()
		get_viewport().set_input_as_handled()


func _region(path: String, rect: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = load(ART + path)
	texture.region = rect
	texture.filter_clip = true
	return texture


func _trimmed(source: Texture2D) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = source
	texture.region = source.get_image().get_used_rect()
	return texture
