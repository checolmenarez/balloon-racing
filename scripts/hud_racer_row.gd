extends Control

var racer: Balloon
var portrait: TextureRect
var identity: Label
var place_label: Label
var progress: ProgressBar
var _highlight: Panel


func _ready() -> void:
	custom_minimum_size = Vector2(232, 64)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	HudStyle.image(self, "panel_leaderboard_row", Rect2(0, 0, 232, 64))
	_highlight = Panel.new()
	_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_highlight.position = Vector2(10, 5)
	_highlight.size = Vector2(214, 55)
	var border := StyleBoxFlat.new()
	border.bg_color = Color.TRANSPARENT
	border.border_color = Color("ffef91")
	border.set_border_width_all(2)
	border.set_corner_radius_all(18)
	_highlight.add_theme_stylebox_override("panel", border)
	add_child(_highlight)
	place_label = HudStyle.label(self, Rect2(22, 23, 22, 27), 18)
	portrait = HudStyle.image(self, "icon_turbo_bolt", Rect2(55, 13, 36, 40))
	identity = HudStyle.label(self, Rect2(99, 23, 118, 18), 13)
	identity.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	progress = ProgressBar.new()
	progress.position = Vector2(104, 44)
	progress.size = Vector2(104, 4)
	progress.add_theme_font_size_override("font_size", 1)
	progress.show_percentage = false
	progress.step = 0.0
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background := StyleBoxFlat.new()
	background.bg_color = Color("122c50")
	background.set_corner_radius_all(3)
	var fill := background.duplicate() as StyleBoxFlat
	fill.bg_color = Color("77cfee")
	progress.add_theme_stylebox_override("background", background)
	progress.add_theme_stylebox_override("fill", fill)
	add_child(progress)
	progress.size = Vector2(104, 4) # Shrink after removing the default theme minimum.


func refresh(competitor: Balloon, place: int, fraction: float) -> void:
	if racer != competitor:
		racer = competitor
		portrait.texture = MenuStyle.portrait(racer.character_id, "normal")
	identity.text = racer.competitor_name
	place_label.text = str(place)
	progress.value = fraction * 100.0
	_highlight.visible = racer.is_local_player
	identity.modulate = Color("ffe486") if racer.is_local_player else Color.WHITE
