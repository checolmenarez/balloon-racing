class_name CharacterCatalog
extends RefCounted

const IDS: Array[String] = ["calaca", "timo", "greta", "pomposo"]
const NAMES: Array[String] = ["Calaca Bonifacia", "Timo Chispa", "Greta Tuerca", "Lord Pomposo IV"]
const STATES: Array[String] = ["idle", "burner", "turbo", "hit", "victory"]
static var _textures: Dictionary = {}


static func texture_for(id: String, state: String) -> Texture2D:
	if id not in IDS:
		return null # Unknown characters retain the procedural fallback.
	var path: String = "res://assets/characters/%s/%s_%s.png" % [id, id, state]
	if not _textures.has(path):
		_textures[path] = load(path) if ResourceLoader.exists(path) else null
	var texture: Texture2D = _textures[path]
	if texture == null and state != "idle":
		return texture_for(id, "idle")
	return texture


static func basket_y(id: String, state: String) -> float:
	# Source-pixel basket anchors, excluding exhaust/confetti. Never move the body.
	if state == "turbo":
		return {"calaca": 452.0, "timo": 480.0, "greta": 446.0, "pomposo": 446.0}.get(id, 486.0)
	return 486.0
