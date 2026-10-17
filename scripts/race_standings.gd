class_name RaceStandings
extends Node

## Preserve the previous ordering for differences of at most two pixels.
@export_range(0.0, 10.0, 0.5) var tie_distance: float = 2.0
var order: Array[Balloon] = []
var finished_order: Array[Balloon] = []


func update_positions() -> void:
	var active: Array[Balloon] = []
	for racer in order:
		if racer not in finished_order:
			active.append(racer)
	order.assign(active)
	# Stable insertion avoids non-transitive approximate sort comparisons.
	for index in range(1, order.size()):
		var cursor: int = index
		while cursor > 0 and order[cursor].global_position.x > order[cursor - 1].global_position.x + tie_distance:
			var ahead: Balloon = order[cursor]
			order[cursor] = order[cursor - 1]
			order[cursor - 1] = ahead
			cursor -= 1
	order = finished_order + order


func get_place(balloon: Balloon) -> int:
	return order.find(balloon) + 1
