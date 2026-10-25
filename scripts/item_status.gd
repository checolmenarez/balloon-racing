extends Label

@export_range(0.0, 3.0, 0.05) var roulette_duration: float = 1.55
var racer: Balloon
var roulette_left: float = 0.0
var displayed_kind: int = BalloonItems.Kind.NONE
var _collected: int = 0
@export var use_hud_skin: bool = false
var skin_icon: TextureRect
var _item_name: Label
var _item_state: Label
var _turbo_count: Label
var _turbo_state: Label
var _item_binding: Label
var _turbo_frame: TextureRect
var _pop: Tween
var _glow: Tween
var _turbo_ready: bool = false
var _refresh_left: float = 0.0
var _refresh_elapsed: float = 0.0
var _last_equipped: int = -1
var _last_charges: int = -1
var _last_boost: bool = false
# Supplied filenames are reversed: icon_bomb depicts a rocket, icon_rocket a bomb.
const ICONS: Array[String] = ["", "icon_bomb", "icon_rocket", "icon_turbo_bolt", "icon_storm"]


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_refresh_left = 0.0


func build_skin() -> void:
	if skin_icon != null:
		return
	self_modulate.a = 0.0 # Retain the text-only presentation used by training.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	HudStyle.image(self, "panel_item", Rect2(0, 0, 94, 80))
	skin_icon = HudStyle.image(self, "icon_rocket", Rect2(23, 12, 54, 54))
	_item_name = HudStyle.label(self, Rect2(101, 0, 162, 27), 21)
	_item_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	HudStyle.image(self, "panel_keyhint", Rect2(101, 32, 35, 34))
	_item_binding = HudStyle.label(self, Rect2(101, 32, 35, 34), 21)
	HudStyle.image(self, "panel_status", Rect2(139, 31, 127, 45))
	_item_state = HudStyle.label(self, Rect2(146, 38, 113, 27), 14)
	_turbo_frame = HudStyle.image(self, "panel_turbo", Rect2(0, 82, 270, 84))
	# The kit contains decorative cells; cover them, since gameplay has charges.
	var charge_backing := ColorRect.new()
	charge_backing.color = Color("083361")
	charge_backing.position = Vector2(78, 116)
	charge_backing.size = Vector2(168, 32)
	charge_backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(charge_backing)
	_turbo_count = HudStyle.label(self, Rect2(74, 108, 178, 26), 19)
	_turbo_state = HudStyle.label(self, Rect2(76, 133, 175, 20), 14)
	for icon in ICONS:
		if not icon.is_empty():
			HudStyle.texture(icon) # Load once, not while roulette runs.


func _process(delta: float) -> void:
	if not is_instance_valid(racer):
		return
	var items: BalloonItems = racer.items
	_refresh_left -= delta
	_refresh_elapsed += delta
	var changed: bool = items.equipped != _last_equipped or items.turbo_charges != _last_charges or (items.boost_left > 0) != _last_boost or items.collected != _collected
	if not changed and _refresh_left > 0:
		return
	var elapsed: float = _refresh_elapsed
	_refresh_elapsed = 0.0
	_refresh_left = 0.05
	_last_equipped = items.equipped
	_last_charges = items.turbo_charges
	_last_boost = items.boost_left > 0
	if items.collected > _collected:
		roulette_left = roulette_duration
		if skin_icon != null:
			_pop = HudStyle.pop(skin_icon, _pop)
	_collected = items.collected
	roulette_left = maxf(0, roulette_left - elapsed)
	if items.equipped == BalloonItems.Kind.NONE or not racer.racing:
		roulette_left = 0 # Use/retry cancels presentation immediately.
	displayed_kind = items.equipped
	if roulette_left > 0:
		displayed_kind = 1 + int((roulette_duration - roulette_left) / 0.07) % 4
	var available: bool = racer.racing and items.combat != null and items.combat.enabled
	var status: String = tr("Listo") if available else tr("En espera")
	if items.equipped == BalloonItems.Kind.NONE:
		status = tr("Busca una caja")
	elif items.equipped == BalloonItems.Kind.BOOST and items.boost_left > 0:
		status = tr("En uso")
	elif items.equipped == BalloonItems.Kind.STORM and available:
		var target: Balloon = items.combat.storm_target(racer)
		if target == null or not target.items.can_receive_storm():
			status = tr("Sin objetivo")
	text = tr("[Z] %s · %s") % [items.item_name(), status]
	text += "\n" + tr("[SPACE] Turbo: %d") % items.turbo_charges
	if items.boost_left > 0:
		text += " · " + tr("En uso")
	elif items.turbo_charges > 0:
		text += " · " + (tr("Espera %.0f s") % ceilf(items.turbo_wait_left) if items.turbo_wait_left > 0 else (tr("Listo") if available else tr("En espera")))
	if use_hud_skin and skin_icon != null:
		skin_icon.visible = displayed_kind != BalloonItems.Kind.NONE
		skin_icon.texture = HudStyle.texture(ICONS[displayed_kind]) if skin_icon.visible else null
		_item_name.text = items.item_name()
		_item_state.text = status
		_item_binding.text = HudStyle.binding("use_item")
		_turbo_count.text = tr("[%s] Turbo: %d") % [HudStyle.binding("use_turbo"), items.turbo_charges]
		var ready_now: bool = available and items.turbo_charges > 0 and items.turbo_wait_left <= 0 and items.boost_left <= 0
		_turbo_state.text = tr("En uso") if items.boost_left > 0 else (tr("Sin cargas") if items.turbo_charges <= 0 else (tr("Espera %.0f s") % ceilf(items.turbo_wait_left) if items.turbo_wait_left > 0 else (tr("Listo") if available else tr("En espera"))))
		if ready_now and not _turbo_ready:
			if _glow != null:
				_glow.kill()
			_glow = create_tween()
			_glow.tween_property(_turbo_frame, "self_modulate", Color(1.25, 1.2, 1.0), 0.2)
			_glow.tween_property(_turbo_frame, "self_modulate", Color.WHITE, 0.4)
		_turbo_ready = ready_now
	queue_redraw()


func _draw() -> void:
	if use_hud_skin:
		return
	# Temporary native icons: the same four kinds as gameplay, no RNG consumed.
	var center := Vector2(-30, 25)
	draw_circle(center, 24, Color("203b52"))
	match displayed_kind:
		BalloonItems.Kind.ROCKET:
			draw_colored_polygon(PackedVector2Array([center + Vector2(-13, -7), center + Vector2(7, -7), center + Vector2(16, 0), center + Vector2(7, 7), center + Vector2(-13, 7)]), Color("fff0d1"))
			draw_line(center + Vector2(-13, 0), center + Vector2(-19, 0), Color("ff9b40"), 5)
		BalloonItems.Kind.BOMB:
			draw_circle(center, 11, Color("b4c7df"))
			draw_line(center + Vector2(0, -10), center + Vector2(7, -17), Color("ffd26a"), 3)
		BalloonItems.Kind.BOOST:
			draw_colored_polygon(PackedVector2Array([center + Vector2(4, -18), center + Vector2(-12, 3), center, center + Vector2(-4, 18), center + Vector2(12, -3), center]), Color("ffd26a"))
		BalloonItems.Kind.STORM:
			draw_circle(center + Vector2(-7, -4), 9, Color("afbbef"))
			draw_circle(center + Vector2(5, -7), 12, Color("afbbef"))
			draw_polyline(PackedVector2Array([center + Vector2(4, 3), center + Vector2(-4, 10), center + Vector2(4, 10), center + Vector2(-2, 18)]), Color("ffe278"), 3)
		_:
			draw_arc(center, 12, 0, TAU, 24, Color("8196a7"), 2, true)
