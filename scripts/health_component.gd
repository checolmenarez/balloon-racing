class_name HealthComponent
extends Node

signal health_changed(current: int, maximum: int, delta: int)
signal damaged(amount: int)
signal healed(amount: int)
signal depleted

@export_range(1, 500, 1) var maximum_health: int = 100
@export_range(0.0, 5.0, 0.05) var protection_seconds: float = 1.0
var current_health: int = 100
var protection_left: float = 0.0
var active: bool = true


func reset(new_maximum: int = maximum_health, new_protection: float = protection_seconds) -> void:
	maximum_health = maxi(1, new_maximum)
	protection_seconds = maxf(0.0, new_protection)
	current_health = maximum_health
	protection_left = 0.0
	active = true
	health_changed.emit(current_health, maximum_health, 0)


func tick(delta: float) -> void:
	protection_left = maxf(0.0, protection_left - delta)


func damage(amount: int) -> bool:
	if not active or amount <= 0 or protection_left > 0.0 or current_health <= 0:
		return false
	var before := current_health
	current_health = maxi(0, current_health - amount)
	protection_left = protection_seconds
	var applied := before - current_health
	health_changed.emit(current_health, maximum_health, -applied)
	damaged.emit(applied)
	if current_health == 0:
		active = false
		depleted.emit()
	return true


func heal(amount: int) -> int:
	if not active or amount <= 0:
		return 0
	var before := current_health
	current_health = mini(maximum_health, current_health + amount)
	var applied := current_health - before
	health_changed.emit(current_health, maximum_health, applied)
	healed.emit(applied)
	return applied

