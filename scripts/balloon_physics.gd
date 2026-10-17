class_name BalloonPhysics
extends Resource

@export_range(0.0, 2000.0, 1.0) var gravity: float = 350.0
## Upward acceleration added by the burner; gravity is always active.
@export_range(0.0, 2000.0, 1.0) var burner_force: float = 650.0
@export_range(0.0, 1000.0, 1.0) var horizontal_speed: float = 220.0
@export_range(1.0, 1000.0, 1.0) var max_vertical_speed: float = 250.0

@export_group("Impact")
@export_range(0.1, 1.0, 0.05) var impact_speed_multiplier: float = 0.60
@export_range(0.05, 5.0, 0.05) var impact_recovery_time: float = 0.8
@export_range(0.0, 250.0, 1.0) var impact_rebound_force: float = 90.0
@export_range(0.05, 5.0, 0.05) var impact_protection_time: float = 0.75
