class_name HudStyle
extends RefCounted

const ROOT: String = "res://assets/ui/hud/"
static var _textures: Dictionary = {}


static func texture(asset: String) -> Texture2D:
	if not _textures.has(asset):
		_textures[asset] = load(ROOT + asset + ".png")
	return _textures[asset]


static func image(parent: Node, asset: String, rect: Rect2) -> TextureRect:
	var control := TextureRect.new()
	control.texture = texture(asset)
	control.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	control.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	control.position = rect.position
	control.size = rect.size
	parent.add_child(control)
	return control


static func label(parent: Node, rect: Rect2, font_size: int = 18) -> Label:
	var control := Label.new()
	control.position = rect.position
	control.size = rect.size
	control.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	control.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	control.add_theme_font_size_override("font_size", font_size)
	control.add_theme_color_override("font_color", Color("fff6d8"))
	control.add_theme_color_override("font_outline_color", Color("102845"))
	control.add_theme_constant_override("outline_size", 3)
	parent.add_child(control)
	return control


static func binding(action: StringName) -> String:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var code: Key = event.physical_keycode if event.physical_keycode != 0 else event.keycode
			return OS.get_keycode_string(code).to_upper()
	return "—"


static func pop(node: Control, previous: Tween) -> Tween:
	if previous != null:
		previous.kill()
	node.pivot_offset = node.size * 0.5
	node.scale = Vector2.ONE * 1.08
	var tween := node.create_tween()
	tween.tween_property(node, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	return tween
