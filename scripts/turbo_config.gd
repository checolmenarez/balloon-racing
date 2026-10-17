class_name TurboConfig
extends Resource

@export_range(0, 20, 1) var bot_initial_charges: int = 2
@export_range(0, 20, 1) var human_initial_charges: int = 2
@export_range(0.0, 60.0, 0.5) var minimum_interval: float = 12.0
@export_range(0.0, 30.0, 0.5) var initial_delay: float = 5.0
@export var minimum_clearance: float = 650.0
@export var braking_margin: float = 80.0
@export var vertical_margin: float = 45.0
@export var maximum_vertical_speed: float = 90.0
@export var maximum_target_error: float = 60.0
