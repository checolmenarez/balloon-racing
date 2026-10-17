class_name ItemConfig
extends Resource

@export var rocket_speed: float = 720.0
@export var rocket_lifetime: float = 2.5
@export var hit_multiplier: float = 0.60
@export var hit_duration: float = 1.0
@export var hit_protection: float = 0.4
@export var bomb_gravity: float = 650.0
@export var bomb_radius: float = 120.0
@export var bomb_fuse: float = 1.8
@export var bomb_impulse: float = 90.0
@export var owner_protection: float = 0.4
@export var boost_multiplier: float = 1.35
@export var boost_duration: float = 2.0
@export var selection_weights: Vector3 = Vector3(1, 1, 1)
@export var bot_decision_interval: float = 0.35
@export var bot_rocket_range: float = 650.0
@export var bot_alignment: float = 45.0
@export var bot_bomb_range: float = 220.0
@export var bot_boost_clearance: float = 400.0
@export_range(0.5, 60.0, 0.5) var box_respawn_time: float = 8.0
## Remaining probability is distributed using selection_weights (rocket/bomb/turbo).
@export var storm_probability_by_place: Vector4 = Vector4(0.0, 0.05, 0.15, 0.25)
@export_range(0.1, 3.0, 0.1) var storm_warning: float = 0.8
@export_range(0.1, 5.0, 0.1) var storm_duration: float = 1.5
@export_range(0.2, 1.0, 0.05) var storm_multiplier: float = 0.65
@export_range(0.0, 15.0, 0.5) var storm_protection: float = 4.0
@export_range(1.0, 2.0, 0.05) var maximum_speed_bonus: float = 1.35
