class_name BalloonVisibility
extends Node

@export var overlap_transparency_enabled: bool = true
@export_range(0.0, 1.0, 0.05) var overlapping_opacity: float = 0.45
@export var local_marker_visible: bool = true
@export_range(0.01, 0.5, 0.01) var fade_time: float = 0.12
@export_range(0.0, 40.0, 1.0) var release_margin: float = 12.0

var competitors: Array[Balloon] = []
var _overlapping: Dictionary = {}
var _opacity: Dictionary = {}


func update_visuals(delta: float) -> void:
	var local: Balloon = null
	for competitor in competitors:
		if competitor.is_local_player:
			local = competitor
			break
	for competitor in competitors:
		var is_local: bool = competitor == local
		competitor.visual.set_local_outline(is_local)
		# Only the visual subtree changes order. Foreground scenery uses Z >= 3.
		competitor.visual.z_as_relative = false
		competitor.visual.z_index = 2 if is_local else 1
		competitor.visual.get_node("LocalMarker").visible = is_local and local_marker_visible
		var overlaps: bool = false
		if local != null and not is_local and overlap_transparency_enabled:
			var local_rect: Rect2 = _bounds(local)
			if _overlapping.get(competitor, false):
				local_rect = local_rect.grow(release_margin)
			overlaps = local_rect.intersects(_bounds(competitor))
		_overlapping[competitor] = overlaps
		var target: float = overlapping_opacity if overlaps else 1.0
		var opacity: float = move_toward(float(_opacity.get(competitor, 1.0)), target, delta / fade_time)
		if is_local:
			opacity = 1.0
		_opacity[competitor] = opacity
		var tint: Color = competitor.impact_tint
		# Preserve impact color, but never make the local balloon translucent.
		tint.a = 1.0 if is_local else minf(tint.a, opacity)
		competitor.visual.modulate = tint


func _bounds(balloon: Balloon) -> Rect2:
	return balloon.visual.get_global_transform() * balloon.visual.get_visual_bounds()
