class_name CharacterCatalog
extends RefCounted

const IDS: Array[String] = ["calaca", "timo", "greta", "pomposo"]
const NAMES: Array[String] = ["Calaca Bonifacia", "Timo Chispa", "Greta Tuerca", "Lord Pomposo IV"]
const STATES: Array[String] = ["idle", "burner", "turbo", "hit", "victory"]
static var _textures: Dictionary = {}

# Source-pixel regions on the approved idle illustrations: eyes and gloved hands.
# Normal flight uses idle; special poses disable these localized gestures.
const GESTURES: Dictionary = {
	"calaca": [Vector4(194, 353, 15, 14), Vector4(237, 350, 13, 14), Vector4(174, 398, 26, 21), Vector4(245, 398, 23, 21)],
	"timo": [Vector4(194, 355, 9, 12), Vector4(227, 355, 8, 12), Vector4(171, 404, 29, 24), Vector4(240, 405, 27, 23)],
	"greta": [Vector4(211, 323, 11, 10), Vector4(251, 333, 10, 10), Vector4(141, 361, 42, 25), Vector4(258, 383, 23, 22)],
	"pomposo": [Vector4(191, 320, 10, 6), Vector4(231, 311, 7, 11), Vector4(158, 382, 26, 21), Vector4(253, 382, 26, 21)]}
const EYELIDS: Dictionary = {"calaca": Color("f4e8cf"), "timo": Color("ffd0a0"), "greta": Color("ffd0a0"), "pomposo": Color("ffe2bd")}


static func gesture_regions(id: String) -> Array:
	return GESTURES.get(id, [])


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


static func basket_anchor(id: String, state: String) -> Vector2:
	# Individual illustrations are not registered animation frames. In particular,
	# Greta's burner basket shifts right inside the otherwise identical PNG canvas.
	var centers: Dictionary = {
		"calaca": [192, 192, 192, 169, 192],
		"timo": [192, 192, 192, 171, 192],
		"greta": [192, 211, 192, 192, 192],
		"pomposo": [192, 192, 192, 192, 192]}
	var index: int = STATES.find(state)
	return Vector2(centers.get(id, [192, 192, 192, 192, 192])[maxi(0, index)], basket_y(id, state))
