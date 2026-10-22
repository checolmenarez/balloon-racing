class_name ItemProjectile
extends CharacterBody2D

var source: Balloon
var combat: ItemCombat
var kind: BalloonItems.Kind
var age: float = 0.0
var exploded: bool = false
var explosion_left: float = 0.0
@export_range(0.25, 0.8, 0.05) var explosion_duration: float = 0.55
var _owner_contact_enabled: bool = false


func _ready() -> void:
	add_collision_exception_with(source)
	if kind == BalloonItems.Kind.BOMB:
		collision_mask = 3 # Terrain and racers; owner retains the existing grace period.
		velocity = Vector2(0, 70)
	else:
		velocity = Vector2(combat.config.rocket_speed, 0)


func _physics_process(delta: float) -> void:
	if exploded:
		explosion_left -= delta
		queue_redraw()
		if explosion_left <= 0.0:
			queue_free()
		return
	age += delta
	var config: ItemConfig = combat.config
	if kind == BalloonItems.Kind.BOMB:
		if not _owner_contact_enabled and age >= config.owner_protection:
			remove_collision_exception_with(source)
			_owner_contact_enabled = true
		velocity.y += config.bomb_gravity * delta
	var collision: KinematicCollision2D = move_and_collide(velocity * delta, false, 0.08, true)
	if kind == BalloonItems.Kind.ROCKET:
		if collision != null:
			combat.projectile_hit.emit(collision.get_collider(), source, kind)
			get_node("/root/Music").play_effect("explosion", global_position)
			var target := collision.get_collider() as Balloon
			if target != null and target != source:
				target.items.receive_hit(source, Vector2.ZERO)
			# Keep only the visual tail; no second collision or area damage.
			exploded = true
			explosion_left = explosion_duration
			collision_layer = 0
			collision_mask = 0
		elif age >= config.rocket_lifetime:
			queue_free()
	elif collision != null or age >= config.bomb_fuse or global_position.y >= source.ground_y:
		explode()
	queue_redraw()


func explode() -> void:
	if exploded:
		return
	exploded = true
	collision_layer = 0
	collision_mask = 0
	get_node("/root/Music").play_effect("explosion", global_position)
	explosion_left = explosion_duration
	for target in combat.competitors:
		if target == source and age < combat.config.owner_protection:
			continue
		var bounds: Rect2 = target.get_body_bounds()
		var closest: Vector2 = global_position.clamp(bounds.position, bounds.end)
		if closest.distance_to(global_position) <= combat.config.bomb_radius:
			var direction: Vector2 = (target.global_position - global_position).normalized()
			target.items.receive_hit(source, direction * combat.config.bomb_impulse)


func _draw() -> void:
	if exploded:
		var phase: float = clampf(1.0 - explosion_left / explosion_duration, 0.0, 1.0)
		var radius: float = combat.config.bomb_radius if kind == BalloonItems.Kind.BOMB else 76.0
		var intensity: float = 0.35 if GameFeel.reduced_motion else 1.0
		var expansion: float = 1.0 - pow(1.0 - phase, 3.0)
		# A fast shock front followed by warm lobes, sparks and drifting smoke.
		# Visual radius only: missile remains a single-target hit.
		draw_arc(Vector2.ZERO, lerpf(9, radius, expansion), 0, TAU, 48, Color(1, 0.8, 0.35, (1.0 - phase) * 0.75 * intensity), 3.0 * (1.0 - phase) + 1.0, true)
		for index in 10:
			var direction := Vector2.from_angle(index * 2.399 + 0.3)
			var at: Vector2 = direction * radius * expansion * (0.3 + index % 3 * 0.1) + Vector2(0, -phase * 18)
			var smoke: float = sin(phase * PI) * 0.32 * intensity
			draw_circle(at, (8 + index % 3 * 3) * (0.6 + phase), Color(0.24, 0.29, 0.35, smoke))
			var fire: float = maxf(0.0, 1.0 - phase * 1.6)
			draw_circle(direction * radius * expansion * 0.23, (16 + index % 3 * 5) * (1.0 - phase * 0.6), Color(1, 0.3 + index % 3 * 0.15, 0.08, sqrt(fire) * 0.95 * intensity))
		draw_circle(Vector2.ZERO, 24.0 * maxf(0.0, 1.0 - phase * 1.6), Color(1, 0.85, 0.3, (1.0 - phase) * intensity))
		for index in 12:
			var direction := Vector2.from_angle(index * TAU / 12.0)
			var at: Vector2 = direction * radius * expansion * (0.65 + index % 3 * 0.1) + Vector2(0, phase * phase * 24)
			draw_line(at, at + direction * 9.0 * (1.0 - phase), Color(1, 0.85, 0.4, (1.0 - phase) * intensity), 2.0, true)
	elif kind == BalloonItems.Kind.BOMB:
		draw_circle(Vector2.ZERO, 14, Color(1, 0.75, 0.3, 0.2 + sin(age * 18) * 0.1))
		draw_circle(Vector2.ZERO, 10, Color("343449"))
		draw_line(Vector2(0, -8), Vector2(5, -15), Color("ffc44d"), 3)
	else:
		# Brass-riveted arcade missile: turquoise casing, red nose and swept fins.
		draw_line(Vector2(-17, 0), Vector2(-34 - sin(age * 30) * 5, 0), Color("ef7730"), 8, true)
		draw_line(Vector2(-17, 0), Vector2(-28 - sin(age * 30) * 3, 0), Color("ffe89a"), 3, true)
		var fins := PackedVector2Array([Vector2(-17, -13), Vector2(-3, -6), Vector2(-3, 6), Vector2(-17, 13), Vector2(-12, 0)])
		draw_colored_polygon(fins, Color("b63d39"))
		draw_polyline(PackedVector2Array([fins[0], fins[1], fins[2], fins[3], fins[4], fins[0]]), Color("47372d"), 2, true)
		draw_style_box(_missile_body, Rect2(-17, -7, 31, 14))
		var nose := PackedVector2Array([Vector2(11, -7), Vector2(23, 0), Vector2(11, 7)])
		draw_colored_polygon(nose, Color("e95841"))
		draw_polyline(PackedVector2Array([nose[0], nose[1], nose[2]]), Color("47372d"), 2, true)
		draw_line(Vector2(-13, -3), Vector2(8, -3), Color("a6ece0"), 2, true)
		for x in [-11, 7]:
			draw_line(Vector2(x, -7), Vector2(x, 7), Color("e9b656"), 3, true)
			draw_circle(Vector2(x, 0), 1.5, Color("fff0b5"))


var _missile_body: StyleBoxFlat = _make_missile_body()


func _make_missile_body() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("368d91")
	style.border_color = Color("47372d")
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	return style
