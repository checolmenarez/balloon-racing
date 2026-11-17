class_name SinglePlayerSave
extends RefCounted

const PATH := "user://single_player.cfg"

var best_distance: float = 0.0
var best_coins: int = 0
var total_coins: int = 0
var hide_intro: bool = false


func load_data(path: String = PATH) -> void:
	best_distance = 0.0
	best_coins = 0
	total_coins = 0
	hide_intro = false
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return
	best_distance = clampf(_number(config.get_value("records", "best_distance", 0.0)), 0.0, 1000000000.0)
	best_coins = clampi(int(_number(config.get_value("records", "best_coins", 0))), 0, 1000000000)
	total_coins = clampi(int(_number(config.get_value("records", "total_coins", 0))), 0, 1000000000)
	hide_intro = config.get_value("preferences", "hide_intro", false) == true


func register_attempt(distance: float, coins: int, path: String = PATH) -> bool:
	var safe_distance := clampf(distance, 0.0, 1000000000.0)
	var safe_coins := clampi(coins, 0, 1000000000)
	var new_record := safe_distance > best_distance
	best_distance = maxf(best_distance, safe_distance)
	best_coins = maxi(best_coins, safe_coins)
	total_coins = clampi(total_coins + safe_coins, 0, 1000000000)
	save_data(path)
	return new_record


func save_data(path: String = PATH) -> Error:
	var config := ConfigFile.new()
	config.set_value("records", "best_distance", best_distance)
	config.set_value("records", "best_coins", best_coins)
	config.set_value("records", "total_coins", total_coins)
	config.set_value("preferences", "hide_intro", hide_intro)
	return config.save(path)


func _number(value: Variant) -> float:
	return float(value) if value is int or value is float else 0.0

