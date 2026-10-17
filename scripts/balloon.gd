class_name Balloon
extends CharacterBody2D

const SIZE_SCALE: float = 0.88
const TOP_EXTENT: float = 74.0 * SIZE_SCALE
const BOTTOM_EXTENT: float = 61.0 * SIZE_SCALE
const HALF_WIDTH: float = 44.0 * SIZE_SCALE


func get_body_bounds() -> Rect2:
	return global_transform * Rect2(-HALF_WIDTH, -TOP_EXTENT, HALF_WIDTH * 2.0, TOP_EXTENT + BOTTOM_EXTENT)

@export var physics: BalloonPhysics = preload("res://resources/default_balloon_physics.tres")
@export var ceiling_y: float = 32.0
@export var ground_y: float = 640.0
@export var controller: FlightController
@export var envelope_color: Color = Color("ed6344")
@export_enum("calaca", "timo", "greta", "pomposo") var character_id: String = "calaca"
@export var is_local_player: bool = false
@export var competitor_name: String = "Jugador"

@onready var visual: BalloonVisual = $Visual
@onready var items: BalloonItems = $Items

var impact_tint: Color = Color.WHITE
var racing: bool = true

@onready var human_controller: FlightController = $HumanController

var burner_active: bool = false
var collision_count: int = 0
var impact_time_left: float = 0.0
var protection_time_left: float = 0.0
var _horizontal_rebound: float = 0.0
var _ignored_obstacles: Array[FlightObstacle] = []


func is_impact_penalized() -> bool:
	return impact_time_left > 0.0


func _physics_process(delta: float) -> void:
	if not racing:
		return
	items.tick(delta)
	_update_impact(delta)
	var active_controller: FlightController = controller if controller != null else human_controller
	burner_active = active_controller.wants_burner(self, delta)
	var acceleration: float = physics.gravity
	if burner_active:
		acceleration -= physics.burner_force
	velocity.x = _forward_speed()
	velocity.y = clampf(velocity.y + acceleration * delta,
		-physics.max_vertical_speed, physics.max_vertical_speed)
	move_and_slide()
	for index in get_slide_collision_count():
		var collision: KinematicCollision2D = get_slide_collision(index)
		var obstacle := collision.get_collider() as FlightObstacle
		if obstacle == null or obstacle in _ignored_obstacles:
			continue
		# A struck formation stays passable until we have completely cleared it.
		# A timer alone could re-enable solidity while still inside a wide rock.
		add_collision_exception_with(obstacle)
		_ignored_obstacles.append(obstacle)
		if protection_time_left <= 0.0:
			_apply_impact(collision.get_normal())
	_enforce_vertical_bounds()
	visual.refresh()


func stop_racing() -> void:
	racing = false
	velocity = Vector2.ZERO
	burner_active = false
	items.boost_left = 0.0
	items.hit_left = 0.0
	items.storm_left = 0.0
	items.storm_warning_left = 0.0
	items.wind_zones.clear()
	set_deferred("collision_layer", 0)
	visual.refresh()


func _forward_speed() -> float:
	var remaining: float = clampf(impact_time_left / physics.impact_recovery_time, 0.0, 1.0)
	var multiplier: float = lerpf(1.0, physics.impact_speed_multiplier, remaining)
	return physics.horizontal_speed * items.speed_multiplier(multiplier) + _horizontal_rebound * remaining


func _apply_impact(normal: Vector2) -> void:
	get_node("/root/Music").play_effect("collision", global_position)
	collision_count += 1
	impact_time_left = physics.impact_recovery_time
	protection_time_left = physics.impact_protection_time
	# Only backward horizontal recoil: hitting a back slope cannot accelerate us.
	_horizontal_rebound = minf(normal.x, 0.0) * physics.impact_rebound_force
	velocity.x = _forward_speed()
	velocity.y = clampf(velocity.y + normal.y * physics.impact_rebound_force,
		-physics.max_vertical_speed, physics.max_vertical_speed)


func _update_impact(delta: float) -> void:
	impact_time_left = maxf(0.0, impact_time_left - delta)
	if is_zero_approx(impact_time_left):
		impact_time_left = 0.0
	protection_time_left = maxf(0.0, protection_time_left - delta)
	for index in range(_ignored_obstacles.size() - 1, -1, -1):
		var obstacle: FlightObstacle = _ignored_obstacles[index]
		if not is_instance_valid(obstacle):
			_ignored_obstacles.remove_at(index)
		elif protection_time_left <= 0.0 and global_position.x - HALF_WIDTH > obstacle.get_right_edge() + 2.0:
			remove_collision_exception_with(obstacle)
			_ignored_obstacles.remove_at(index)
	# Keep the silhouette visible even while passing through the struck formation.
	if not _ignored_obstacles.is_empty():
		impact_tint = Color(1.0, 0.65, 0.65, 0.65)
	elif items.storm_left > 0.0:
		impact_tint = Color(0.72, 0.8, 1.0)
	elif is_impact_penalized() or items.hit_left > 0.0:
		impact_tint = Color(1.0, 0.65, 0.65)
	else:
		impact_tint = Color.WHITE


func set_vertical_bounds(top: float, bottom: float) -> void:
	ceiling_y = top
	ground_y = maxf(bottom, top + TOP_EXTENT + BOTTOM_EXTENT)
	_enforce_vertical_bounds()


func _enforce_vertical_bounds() -> void:
	# Include the whole envelope and basket; discard only outward velocity.
	var minimum_y: float = ceiling_y + TOP_EXTENT
	var maximum_y: float = maxf(minimum_y, ground_y - BOTTOM_EXTENT)
	global_position.y = clampf(global_position.y, minimum_y, maximum_y)
	if global_position.y <= minimum_y or is_equal_approx(global_position.y, minimum_y):
		velocity.y = maxf(velocity.y, 0.0)
	if global_position.y >= maximum_y or is_equal_approx(global_position.y, maximum_y):
		velocity.y = minf(velocity.y, 0.0)

