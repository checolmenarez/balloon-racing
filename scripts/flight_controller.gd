class_name FlightController
extends Node


func wants_burner(_body: CharacterBody2D, _delta: float) -> bool:
	return Input.is_action_pressed("burner")
