class_name MenuStyle
extends RefCounted

const ROOT: String = "res://assets/ui/menus/"


static func texture(path: String) -> Texture2D:
	return load(ROOT + path) as Texture2D


static func portrait(id: String, pose: String) -> Texture2D:
	var path := ROOT + "portraits/%s_%s.png" % [id, pose]
	if ResourceLoader.exists(path):
		var source := load(path) as Texture2D
		# This supplied portrait includes an unrelated basket fragment above the head.
		# Crop only its display region; keep the source asset unchanged.
		if id == "greta" and pose == "surprised":
			var cropped := AtlasTexture.new()
			cropped.atlas = source
			cropped.region = Rect2(0, 52, source.get_width(), source.get_height() - 52)
			return cropped
		return source
	return CharacterCatalog.texture_for(id, "idle")


static func box(path: String, margin: float = 16.0) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture(path)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_texture_margin(side, margin)
		style.set_content_margin(side, margin)
	return style


static func button(control: Button, primary: bool = false) -> void:
	control.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	control.custom_minimum_size.x = 380
	var kind := "primary" if primary else "secondary"
	for state in ["normal", "hover", "pressed", "hover_pressed"]:
		control.add_theme_stylebox_override(state, box("background/button_%s_%s.png" % [kind, "pressed" if state == "hover_pressed" else state], 12.0))
	control.add_theme_font_size_override("font_size", 23)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		control.add_theme_color_override(state, Color("243750"))
	focus(control)


static func focus(control: Control) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = Color.WHITE
	style.set_border_width_all(3)
	style.set_corner_radius_all(18)
	control.add_theme_stylebox_override("focus", style)


static func image(path: String, height: float) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = texture(path)
	rect.custom_minimum_size.y = height
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


static func background(parent: Control) -> TextureRect:
	var rect := image("background/background_valle_ventoso.jpg", 0)
	parent.add_child(rect)
	parent.move_child(rect, 0)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	return rect
