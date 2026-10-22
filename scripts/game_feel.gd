class_name GameFeel
extends RefCounted

static var _loaded: bool = false
static var _reduced: bool = false
static var reduced_motion: bool:
	get:
		if not _loaded:
			var config := ConfigFile.new()
			config.load("user://presentation.cfg")
			_reduced = bool(config.get_value("visual", "reduced_motion", false))
			_loaded = true
		return _reduced
	set(value):
		_loaded = true
		_reduced = value
		var config := ConfigFile.new()
		config.set_value("visual", "reduced_motion", value)
		config.save("user://presentation.cfg")
