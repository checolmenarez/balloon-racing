extends ProgressBar

var racers: Array[Balloon] = []
var track: BalloonTrack
var _marker: TextureRect


func configure(competitors: Array[Balloon], course: BalloonTrack) -> void:
	racers.assign(competitors)
	track = course
	var frame := HudStyle.image(self, "panel_progress", Rect2(-70, -48, 480, 90))
	frame.z_index = -1
	# Cover the four decorative dots; they are not gameplay milestones.
	var background := StyleBoxFlat.new()
	background.bg_color = Color("092d57")
	background.set_corner_radius_all(5)
	background.expand_margin_top = 14
	background.expand_margin_bottom = 12
	var fill := background.duplicate() as StyleBoxFlat
	fill.bg_color = Color("ffe270")
	add_theme_stylebox_override("background", background)
	add_theme_stylebox_override("fill", fill)
	show_percentage = false
	add_theme_font_size_override("font_size", 1)
	for racer in racers:
		if racer.is_local_player:
			_marker = HudStyle.image(self, "icon_turbo_bolt", Rect2(0, -12, 24, 28))
			_marker.texture = MenuStyle.portrait(racer.character_id, "normal")
	# Explicit endpoints use the supplied marker assets, without new milestones.
	var start := HudStyle.image(self, "marker_start", Rect2(-46, -15, 30, 32))
	start.name = "StartMarker"
	var finish := HudStyle.image(self, "marker_finish", Rect2(356, -15, 30, 32))
	finish.name = "FinishMarker"


func _process(_delta: float) -> void:
	if _marker != null:
		_marker.position.x = value / max_value * (size.x - _marker.size.x)
