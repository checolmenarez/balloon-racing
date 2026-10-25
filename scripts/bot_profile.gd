class_name BotProfile
extends Resource

enum Route { LOWER, UPPER }

## Scales anticipation and inverse reaction/error tolerances, never flight speed.
@export_range(0.5, 2.0, 0.01) var skill_multiplier: float = 1.85

@export var profile_name: String = "Equilibrado"
@export_range(100.0, 1000.0, 10.0) var look_ahead: float = 600.0
@export_range(0.02, 1.0, 0.01) var reaction_time: float = 0.18
@export_range(0.0, 50.0, 1.0) var height_precision: float = 8.0
@export_range(0.0, 80.0, 1.0) var error_margin: float = 18.0
@export_range(0.1, 1.0, 0.05) var inertia_prediction: float = 0.5
@export var preferred_route: Route = Route.LOWER
## Smooth, spatially coherent misjudgment; never a random velocity impulse.
@export var error_phase: float = 0.0
@export_range(0.0, 1.0, 0.05) var upper_route_probability: float = 0.4
@export_range(0.0, 150.0, 5.0) var anticipation_variation: float = 55.0
@export_range(0.0, 6.28, 0.1) var phase_variation: float = 3.14
