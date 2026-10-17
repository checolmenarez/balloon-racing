extends Node

const COLORS: Array[Color] = [Color("ed6344"), Color(0.25, 0.75, 0.36), Color(0.25, 0.55, 0.94), Color(0.98, 0.80, 0.20)]
const NAMES: Array[String] = CharacterCatalog.NAMES
var selected: int = 0


func apply_characters(racers: Array[Balloon]) -> void:
	var characters: Array[String] = CharacterCatalog.IDS.duplicate()
	var chosen: int = clampi(selected, 0, characters.size() - 1)
	var local_id: String = characters.pop_at(chosen)
	var available: Array[Color] = COLORS.duplicate()
	var player_color: Color = available.pop_at(clampi(selected, 0, COLORS.size() - 1))
	racers[0].envelope_color = player_color
	racers[0].character_id = local_id
	for index in range(1, racers.size()):
		racers[index].envelope_color = available[index - 1]
		racers[index].character_id = characters[index - 1]
	for racer in racers:
		racer.competitor_name = NAMES[CharacterCatalog.IDS.find(racer.character_id)]
		racer.visual.refresh()
