class_name ItemProjectile
extends CharacterBody2D

var source: Balloon
var combat: ItemCombat
var kind: BalloonItems.Kind
var age: float = 0.0
var exploded: bool = false
var explosion_left: float = 0.0


func _ready() -> void:
	add_collision_exception_with(source)
	if kind == BalloonItems.Kind.BOMB:
		collision_mask = 2
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
		velocity.y += config.bomb_gravity * delta
	var collision: KinematicCollision2D = move_and_collide(velocity * delta)
	if kind == BalloonItems.Kind.ROCKET:
		if collision != null:
			combat.projectile_hit.emit(collision.get_collider(), source, kind)
			get_node("/root/Music").play_effect("explosion", global_position)
			var target := collision.get_collider() as Balloon
			if target != null and target != source:
				target.items.receive_hit(source, Vector2.ZERO)
			# Keep only the visual tail; no second collision or area damage.
			exploded = true
			explosion_left = 0.25
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
	explosion_left = 0.25
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
		var phase: float = clampf(1.0 - explosion_left / 0.25, 0.0, 1.0)
		var radius: float = combat.config.bomb_radius if kind == BalloonItems.Kind.BOMB else 42.0
		draw_circle(Vector2.ZERO, lerpf(8, radius, phase), Color(1, 0.65, 0.15, (1.0 - phase) * 0.28))
		draw_arc(Vector2.ZERO, lerpf(8, radius, phase), 0, TAU, 32, Color(1, 0.93, 0.6, 1.0 - phase), 3.0, true)
		draw_circle(Vector2.ZERO, 14.0 * (1.0 - phase), Color(1, 1, 0.9, 1.0 - phase))
		for index in 8:
			var direction := Vector2.from_angle(index * TAU / 8.0)
			draw_line(direction * radius * phase * 0.65, direction * radius * phase, Color(1, 0.85, 0.4, 1.0 - phase), 2.0, true)
	elif kind == BalloonItems.Kind.BOMB:
		draw_circle(Vector2.ZERO, 14, Color(1, 0.75, 0.3, 0.2 + sin(age * 18) * 0.1))
		draw_circle(Vector2.ZERO, 10, Color("343449"))
		draw_line(Vector2(0, -8), Vector2(5, -15), Color("ffc44d"), 3)
	else:
		draw_colored_polygon(PackedVector2Array([Vector2(-15, -7), Vector2(10, -7), Vector2(20, 0), Vector2(10, 7), Vector2(-15, 7)]), Color("f9efe3"))
		draw_line(Vector2(-15, 0), Vector2(-30 - sin(age * 45) * 6, 0), Color("ff872f"), 5)
