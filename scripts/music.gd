extends AudioStreamPlayer

## Optional licensed Home replacement. Empty keeps the original song.
## WAV, OGG and MP3 are looped on private copies, leaving imports untouched.
@export var home_music: AudioStream
## Optional cues: no placeholder paths or substitute fanfare.
@export var countdown_sound: AudioStream
@export var race_start_sound: AudioStream
@export var race_music: Array[AudioStream] = []
@export_range(0.05, 1.0, 0.05) var startup_fade_seconds: float = 0.4
@export_range(-40.0, 0.0, 1.0) var effects_volume_db: float = -12.0
@export_range(100.0, 2000.0, 50.0) var effects_distance: float = 1000.0
@export_range(0.05, 1.0, 0.05) var transition_seconds: float = 0.25
signal effect_played(effect: String)

var current_theme: String = ""
var _themes: Dictionary = {}
var _effects: Dictionary = {}
var _voices: Array[AudioStreamPlayer2D] = []
var _next_voice: int = 0
var _transition: Tween
var _music_volume: float
var _race_tracks: Array[AudioStream] = []
var _music_rng := RandomNumberGenerator.new()


func _ready() -> void:
	_setup_audio_buses()
	_music_volume = volume_db
	_music_rng.randomize() # Independent from gameplay's random sequence.
	_themes.menu = _looped(home_music if home_music != null else load("res://assets/audio/valle_ventoso.wav"))
	for track in race_music:
		if track != null:
			_race_tracks.append(_looped(track))
	if _race_tracks.is_empty():
		_race_tracks.append(_looped(load("res://assets/audio/carrera.wav")))
	_themes.race = _race_tracks[0]
	for effect in ["collision", "turbo", "explosion"]:
		_effects[effect] = load("res://assets/audio/%s.wav" % effect)
	if countdown_sound != null:
		_effects["countdown"] = countdown_sound
	if race_start_sound != null:
		_effects["race_start"] = race_start_sound
	for index in 8:
		var voice := AudioStreamPlayer2D.new()
		voice.max_distance = effects_distance
		voice.volume_db = effects_volume_db
		voice.bus = "SFX"
		add_child(voice)
		_voices.append(voice)
	current_theme = "menu"
	stream = _themes.menu
	volume_db = -60.0
	play()
	_transition = create_tween()
	_transition.tween_property(self, "volume_db", _music_volume, startup_fade_seconds)


func _setup_audio_buses() -> void:
	var config := ConfigFile.new()
	config.load("user://audio.cfg")
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
		var index: int = AudioServer.get_bus_index(bus_name)
		var level: float = clampf(float(config.get_value("audio", bus_name, 1.0)), 0.0, 1.0)
		AudioServer.set_bus_mute(index, level <= 0.0)
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(level, 0.0001)))
	bus = "Music"


func audio_level(bus_name: String) -> float:
	var index: int = AudioServer.get_bus_index(bus_name)
	if index < 0 or AudioServer.is_bus_mute(index):
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(index))


func set_audio_level(bus_name: String, level: float) -> void:
	if bus_name not in ["Music", "SFX"]:
		return
	level = clampf(level, 0.0, 1.0)
	var index: int = AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_mute(index, level <= 0.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(level, 0.0001)))
	var config := ConfigFile.new()
	for name in ["Music", "SFX"]:
		config.set_value("audio", name, audio_level(name))
	config.save("user://audio.cfg")


func set_theme(theme: String) -> void:
	if theme == current_theme or not _themes.has(theme):
		return
	# RaceFlow requests race at GO, menu at podium/countdown. Choose once per entry.
	# Repeated requests during a race return above, preserving its song and position.
	if theme == "race":
		_themes.race = _race_tracks[_music_rng.randi_range(0, _race_tracks.size() - 1)]
	current_theme = theme
	if _transition != null:
		_transition.kill()
	_transition = create_tween()
	_transition.tween_property(self, "volume_db", -60.0, transition_seconds)
	_transition.tween_callback(func() -> void:
		stream = _themes[theme]
		play())
	_transition.tween_property(self, "volume_db", _music_volume, transition_seconds)


func _looped(source: AudioStream) -> AudioStream:
	var copy := source.duplicate() as AudioStream
	if copy is AudioStreamWAV:
		copy.loop_mode = AudioStreamWAV.LOOP_FORWARD
		copy.loop_begin = 0
		copy.loop_end = roundi(copy.get_length() * copy.mix_rate)
	elif copy is AudioStreamMP3 or copy is AudioStreamOggVorbis:
		copy.loop = true
	return copy


func register_effect(effect: String, audio: AudioStream) -> void:
	if not effect.is_empty() and audio != null:
		_effects[effect] = audio


func play_effect(effect: String, world_position: Vector2, pitch_scale: float = 1.0) -> void:
	if get_tree().paused or not _effects.has(effect):
		return
	# World-space voices attenuate distant bots and survive projectile deletion.
	var voice: AudioStreamPlayer2D = _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	voice.stop()
	voice.global_position = world_position
	voice.volume_db = effects_volume_db
	voice.max_distance = effects_distance
	voice.pitch_scale = clampf(pitch_scale, 0.75, 1.35)
	voice.stream = _effects[effect]
	voice.play()
	effect_played.emit(effect)


func clear_effects() -> void:
	for voice in _voices:
		voice.stop()
		voice.stream = null


func _exit_tree() -> void:
	if _transition != null:
		_transition.kill()
	clear_effects()
	stop()
	stream = null
