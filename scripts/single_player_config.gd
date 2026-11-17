class_name SinglePlayerConfig
extends Resource

@export_group("Progression")
@export_range(100.0, 600.0, 5.0) var initial_speed: float = 220.0
@export_range(0.0, 0.25, 0.005) var speed_increment: float = 0.055
@export_range(100.0, 2000.0, 25.0) var progression_interval: float = 900.0
@export_range(1.0, 2.0, 0.05) var maximum_speed_multiplier: float = 1.55
@export_range(0.0, 5000.0, 100.0) var initial_difficulty_distance: float = 1200.0
@export_range(0.1, 10.0, 0.1) var speed_smoothing: float = 1.8
@export_range(1000.0, 15000.0, 100.0) var intermediate_distance: float = 3600.0
@export_range(2000.0, 30000.0, 100.0) var advanced_distance: float = 9000.0

@export_group("Survival")
@export_range(1, 500, 1) var maximum_health: int = 100
@export_range(1, 100, 1) var collision_damage: int = 25
@export_range(1, 100, 1) var star_healing: int = 20
@export_range(0.1, 5.0, 0.1) var impact_protection_seconds: float = 1.0

@export_group("Segments")
@export_range(800.0, 4000.0, 50.0) var segment_length: float = 2400.0
@export_range(2, 10, 1) var segments_ahead: int = 4
@export_range(0, 5, 1) var segments_behind: int = 1
@export_range(160.0, 400.0, 5.0) var beginner_gap: float = 280.0
@export_range(160.0, 400.0, 5.0) var advanced_gap: float = 215.0
@export_range(200.0, 1200.0, 25.0) var minimum_reaction_distance: float = 700.0
@export_range(3, 12, 1) var relief_interval_segments: int = 6
@export_range(2, 20, 1) var star_minimum_segments: int = 8
@export_range(0.0, 1.0, 0.05) var star_spawn_chance: float = 0.35
@export var default_seed: int = 82472


func target_speed(distance: float) -> float:
	var progression := maxf(0.0, distance) / maxf(progression_interval, 1.0)
	var multiplier := minf(maximum_speed_multiplier, 1.0 + progression * speed_increment)
	return initial_speed * multiplier


func difficulty(distance: float) -> float:
	return clampf((distance - initial_difficulty_distance) / maxf(advanced_distance - initial_difficulty_distance, 1.0), 0.0, 1.0)


func difficulty_tier(distance: float) -> int:
	if distance >= advanced_distance:
		return 2
	if distance >= intermediate_distance:
		return 1
	return 0

