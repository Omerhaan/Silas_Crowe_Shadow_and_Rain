extends Node

## Procedural & Asset-Driven Noir Audio Manager for Gölge ve Yağmur.
## Supports both high-fidelity atmospheric recordings (Noir piano BGM, real thunderclaps,
## vintage typewriter keys) and resilient procedural GDScript PCM fallback synthesis.

var rain_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var thunder_player: AudioStreamPlayer
var music_player: AudioStreamPlayer
var music_player_b: AudioStreamPlayer

var current_track: String = ""
var active_stream: AudioStream = null
var previous_room_track: String = ""
var is_tension_override: bool = false
var _active_player_idx: int = 0
var _crossfade_tween: Tween = null

var cached_sounds: Dictionary = {}
var _rain_filter_state: float = 0.0
var _thunder_filter_state: float = 0.0

var master_volume: float = 1.0
var music_volume: float = 0.75
var ambiance_volume: float = 0.8
var sfx_volume: float = 1.0
var subtitles_enabled: bool = true

const SETTINGS_PATH = "user://settings.json"

const ROOM_MUSIC_MAP = {
	# Office Hub
	"silas_office": "opera_foyer",
	"hub_office": "opera_foyer",

	# Case 1 (Harlow Manor)
	"main_hall": "manor_hall",
	"dining_room": "manor_hall",
	"billiard_room": "manor_hall",
	"kitchen": "manor_hall",
	"upper_floor": "manor_hall",
	"harlow_bedroom": "manor_hall",
	"julian_room": "manor_hall",
	"pike_room": "manor_hall",
	"study": "manor_crime",
	"library": "manor_hall",

	# Case 2 (Greywater Docks)
	"dock_pier": "docks_fog",
	"dock_warehouse": "docks_fog",
	"dock_office": "docks_fog",
	"dock_tavern": "docks_tavern",
	"dock_cabin": "docks_tavern",

	# Case 3 (Royal Opera)
	"opera_foyer": "opera_foyer",
	"backstage": "opera_foyer",
	"prop_room": "opera_foyer",
	"opera_auditorium": "opera_aria",
	"royal_box": "opera_aria",
	"light_bridge": "opera_roof",
	"opera_roof": "opera_roof"
}

const MUSIC_TRACK_FILES = {
	"noir_office": [
		"res://assets/audio/music/bgm_noir_office.ogg",
		"res://assets/audio/music/bgm_noir_office.mp3",
		"res://assets/audio/music/bgm_silas_office.ogg",
		"res://assets/audio/music/bgm_silas_office.mp3"
	],
	"manor_hall": [
		"res://assets/audio/music/bgm_noir_piano.mp3",
		"res://assets/audio/music/bgm_manor_hall.ogg",
		"res://assets/audio/music/bgm_manor_hall.mp3"
	],
	"manor_crime": [
		"res://assets/audio/music/bgm_manor_crime.ogg",
		"res://assets/audio/music/bgm_manor_crime.mp3"
	],
	"docks_fog": [
		"res://assets/audio/music/bgm_docks_fog.ogg",
		"res://assets/audio/music/bgm_docks_fog.mp3"
	],
	"docks_tavern": [
		"res://assets/audio/music/bgm_docks_tavern.ogg",
		"res://assets/audio/music/bgm_docks_tavern.mp3"
	],
	"opera_foyer": [
		"res://assets/audio/music/bgm_opera_foyer.ogg",
		"res://assets/audio/music/bgm_opera_foyer.mp3"
	],
	"opera_aria": [
		"res://assets/audio/music/bgm_opera_aria.ogg",
		"res://assets/audio/music/bgm_opera_aria.mp3"
	],
	"opera_roof": [
		"res://assets/audio/music/bgm_opera_roof.ogg",
		"res://assets/audio/music/bgm_opera_roof.mp3"
	],
	"tension_confront": [
		"res://assets/audio/music/bgm_tension_confront.ogg",
		"res://assets/audio/music/bgm_tension_confront.mp3",
		"res://assets/audio/music/bgm_tension.ogg",
		"res://assets/audio/music/bgm_tension.mp3"
	],
	"ending_credits": [
		"res://assets/audio/music/bgm_ending_credits.ogg",
		"res://assets/audio/music/bgm_ending_credits.mp3",
		"res://assets/audio/music/bgm_noir_piano.mp3"
	]
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Audio stream player instances
	rain_player = AudioStreamPlayer.new()
	rain_player.bus = "Master"
	rain_player.volume_db = -14.0
	add_child(rain_player)

	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "Master"
	sfx_player.volume_db = -6.0
	add_child(sfx_player)

	thunder_player = AudioStreamPlayer.new()
	thunder_player.bus = "Master"
	thunder_player.volume_db = -4.0
	add_child(thunder_player)

	# Dual music players for seamless crossfading
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	music_player.volume_db = -18.0
	add_child(music_player)

	music_player_b = AudioStreamPlayer.new()
	music_player_b.bus = "Master"
	music_player_b.volume_db = -60.0
	add_child(music_player_b)

	# Load saved settings if any
	load_settings()

	# Generate procedural streams as resilient baseline
	_synthesize_all_audio()

	# Load real audio assets if present on disk
	_load_real_audio_assets()

	# Start ambient rain loop
	start_rain()

	# Start initial music
	play_music("noir_office")

	# Hook gameplay audio triggers
	EventBus.evidence_collected.connect(func(_id): play_sfx("clue"))
	EventBus.deduction_made.connect(func(_id): play_sfx("chime"))
	EventBus.lightning_occurred.connect(func(): play_thunder())
	EventBus.room_changed.connect(_on_room_changed)
	EventBus.interrogation_requested.connect(_on_interrogation_requested)
	EventBus.interrogation_finished.connect(_on_interrogation_finished)
	EventBus.accusation_requested.connect(_on_accusation_requested)
	EventBus.accusation_resolved.connect(_on_accusation_resolved)
	EventBus.case_ending_requested.connect(func(): play_music("ending_credits", 1.5))

func _on_room_changed(room_id: String) -> void:
	_update_room_ambiance(room_id)

	var target_track = ROOM_MUSIC_MAP.get(room_id, "manor_hall")
	if is_tension_override:
		previous_room_track = target_track
	else:
		play_music(target_track, 1.5)

func _update_room_ambiance(room_id: String) -> void:
	if not rain_player or not rain_player.playing:
		return
	var base_db = linear_to_db(ambiance_volume) if ambiance_volume > 0.001 else -80.0
	var target_db = base_db - 14.0
	match room_id:
		"main_hall":
			target_db = base_db - 11.0
		"silas_office", "hub_office":
			target_db = base_db - 15.0
		"study", "harlow_bedroom", "pike_room", "julian_room":
			target_db = base_db - 21.0
		"dock_pier":
			target_db = base_db - 10.0
		"opera_roof", "light_bridge":
			target_db = base_db - 8.0
		_:
			target_db = base_db - 16.0
	var tw = create_tween()
	tw.tween_property(rain_player, "volume_db", target_db, 1.2)

func _on_interrogation_requested(_suspect_id: String) -> void:
	is_tension_override = true
	previous_room_track = current_track
	play_music("tension_confront", 1.0)

func _on_interrogation_finished() -> void:
	is_tension_override = false
	var restore_track = previous_room_track
	if restore_track == "" or restore_track == "tension_confront":
		var cur_room = GameState.current_room_id if GameState else ""
		restore_track = ROOM_MUSIC_MAP.get(cur_room, "manor_hall")
	previous_room_track = ""
	play_music(restore_track, 1.5)

func _on_accusation_requested() -> void:
	is_tension_override = true
	previous_room_track = current_track
	play_music("tension_confront", 0.8)

func _on_accusation_resolved(success: bool, _culprit_id: String) -> void:
	if not success:
		is_tension_override = false
		var restore_track = previous_room_track
		if restore_track == "":
			var cur_room = GameState.current_room_id if GameState else ""
			restore_track = ROOM_MUSIC_MAP.get(cur_room, "manor_hall")
		previous_room_track = ""
		play_music(restore_track, 1.5)

func _load_audio_stream(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		var s = load(path) as AudioStream
		if s:
			if s is AudioStreamMP3:
				(s as AudioStreamMP3).loop = true
			elif s is AudioStreamOggVorbis:
				(s as AudioStreamOggVorbis).loop = true
			return s
	elif FileAccess.file_exists(path):
		if path.ends_with(".mp3"):
			var bytes = FileAccess.get_file_as_bytes(path)
			if bytes.size() > 0:
				var mp3 = AudioStreamMP3.new()
				mp3.data = bytes
				mp3.loop = true
				return mp3
		elif path.ends_with(".ogg"):
			var ogg = AudioStreamOggVorbis.load_from_file(path)
			if ogg:
				ogg.loop = true
				return ogg
	return null

func _load_real_audio_assets() -> void:
	# 1. Base Noir Piano BGM (Gymnopédie No. 1)
	var mp3_path = "res://assets/audio/music/bgm_noir_piano.mp3"
	var base_piano_stream = _load_audio_stream(mp3_path)
	if base_piano_stream:
		cached_sounds["music_noir_piano"] = base_piano_stream
		cached_sounds["music_manor_hall"] = base_piano_stream

	# 2. Check and load all mapped music tracks
	for track_key in MUSIC_TRACK_FILES.keys():
		var candidates = MUSIC_TRACK_FILES[track_key]
		for path in candidates:
			if ResourceLoader.exists(path) or FileAccess.file_exists(path):
				var stream = _load_audio_stream(path)
				if stream:
					cached_sounds["music_" + track_key] = stream
					break

	# 3. Real Thunderstorm Sound (OGG)
	var thunder_path = "res://assets/audio/sfx/sfx_storm_thunder.ogg"
	var thunder_stream = _load_audio_stream(thunder_path)
	if thunder_stream:
		cached_sounds["thunder_real"] = thunder_stream

	# 4. Real Vintage Typewriter Sound (OGG)
	var type_path = "res://assets/audio/sfx/sfx_typewriter.ogg"
	var type_stream = _load_audio_stream(type_path)
	if type_stream:
		cached_sounds["typewriter"] = type_stream

func _synthesize_all_audio() -> void:
	cached_sounds["rain"] = _create_wav(22050 * 2, _gen_rain_sample, true)
	cached_sounds["thunder"] = _create_wav(int(22050 * 2.8), _gen_thunder_sample, false)
	cached_sounds["phone_ring"] = _create_wav(int(22050 * 1.4), _gen_phone_sample, false)
	cached_sounds["page"] = _create_wav(int(22050 * 0.22), _gen_page_sample, false)
	cached_sounds["click"] = _create_wav(int(22050 * 0.05), _gen_click_sample, false)
	cached_sounds["clue"] = _create_wav(int(22050 * 0.55), _gen_clue_sample, false)
	cached_sounds["chime"] = _create_wav(int(22050 * 0.8), _gen_chime_sample, false)
	cached_sounds["footstep"] = _create_wav(int(22050 * 0.12), _gen_footstep_sample, false)
	cached_sounds["door_locked"] = _create_wav(int(22050 * 0.25), _gen_door_locked_sample, false)
	cached_sounds["door_open"] = _create_wav(int(22050 * 0.35), _gen_door_open_sample, false)
	cached_sounds["objection"] = _create_wav(int(22050 * 0.85), _gen_objection_sample, false)
	cached_sounds["music_noir_piano"] = _create_wav(22050 * 6, _gen_noir_piano_sample, true)

func _gen_noir_piano_sample(t: float, _i: int) -> float:
	var notes = [130.81, 155.56, 196.00, 233.08, 146.83, 174.61, 220.00, 261.63]
	var beat = int(t * 1.5) % notes.size()
	var freq = notes[beat]
	var note_t = fmod(t, 1.0 / 1.5)
	var env = exp(-note_t * 3.5)
	var wave = sin(note_t * freq * TAU) * 0.7 + sin(note_t * freq * 2.0 * TAU) * 0.2
	return wave * env * 0.25

func get_music_stream(track_name: String) -> AudioStream:
	var key = "music_" + track_name.to_lower()
	if cached_sounds.has(key) and cached_sounds[key] != null:
		return cached_sounds[key]
	if cached_sounds.has("music_manor_hall") and cached_sounds["music_manor_hall"] != null:
		return cached_sounds["music_manor_hall"]
	if cached_sounds.has("music_noir_piano") and cached_sounds["music_noir_piano"] != null:
		return cached_sounds["music_noir_piano"]
	return null

func play_music(track_name: String = "manor_hall", crossfade_time: float = 1.5) -> void:
	var stream = get_music_stream(track_name)
	if stream == null:
		return

	var current_player = music_player if _active_player_idx == 0 else music_player_b
	var next_player = music_player_b if _active_player_idx == 0 else music_player

	# If same stream is already playing and matching track, do not interrupt
	if current_player and current_player.playing and active_stream == stream and current_track == track_name:
		return

	current_track = track_name
	active_stream = stream

	var target_db = (linear_to_db(music_volume) - 6.0) if music_volume > 0.001 else -80.0

	if _crossfade_tween and _crossfade_tween.is_valid():
		_crossfade_tween.kill()

	if not current_player or not current_player.playing:
		if current_player:
			current_player.stream = stream
			current_player.volume_db = target_db
			current_player.play()
		return

	# Dual-player seamless crossfade
	_crossfade_tween = create_tween().set_parallel(true)
	next_player.stream = stream
	next_player.volume_db = -60.0
	next_player.play()
	_crossfade_tween.tween_property(next_player, "volume_db", target_db, crossfade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_crossfade_tween.tween_property(current_player, "volume_db", -60.0, crossfade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	_active_player_idx = 1 if _active_player_idx == 0 else 0
	var old_player = current_player
	_crossfade_tween.chain().tween_callback(func():
		if old_player and old_player != (music_player if _active_player_idx == 0 else music_player_b):
			old_player.stop()
	)

func stop_music(fade_duration: float = 1.5) -> void:
	current_track = ""
	active_stream = null
	if _crossfade_tween and _crossfade_tween.is_valid():
		_crossfade_tween.kill()
	_crossfade_tween = create_tween().set_parallel(true)
	if music_player and music_player.playing:
		_crossfade_tween.tween_property(music_player, "volume_db", -60.0, fade_duration)
	if music_player_b and music_player_b.playing:
		_crossfade_tween.tween_property(music_player_b, "volume_db", -60.0, fade_duration)
	_crossfade_tween.chain().tween_callback(func():
		if music_player: music_player.stop()
		if music_player_b: music_player_b.stop()
	)


func start_rain() -> void:
	if cached_sounds.has("rain"):
		rain_player.stream = cached_sounds["rain"]
		rain_player.play()

func stop_rain() -> void:
	rain_player.stop()

func play_sfx(sound_name: String) -> void:
	var key = sound_name.to_lower()
	if cached_sounds.has(key):
		sfx_player.stream = cached_sounds[key]
		sfx_player.play()
	elif (key == "clue_found" or key == "evidence_found") and cached_sounds.has("clue"):
		sfx_player.stream = cached_sounds["clue"]
		sfx_player.play()
	elif key == "page_turn" and cached_sounds.has("page"):
		sfx_player.stream = cached_sounds["page"]
		sfx_player.play()

func play_thunder() -> void:
	if cached_sounds.has("thunder_real"):
		thunder_player.stream = cached_sounds["thunder_real"]
		thunder_player.play()
	elif cached_sounds.has("thunder"):
		thunder_player.stream = cached_sounds["thunder"]
		thunder_player.play()

func trigger_thunder() -> void:
	EventBus.lightning_occurred.emit()

# --- Procedural Audio Synthesis Core ---

func _create_wav(sample_count: int, generator: Callable, loop: bool) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = sample_count

	var bytes = PackedByteArray()
	bytes.resize(sample_count * 2)

	for i in range(sample_count):
		var t = float(i) / 22050.0
		var sample_f: float = clampf(generator.call(t, i), -1.0, 1.0)
		var val_16: int = int(sample_f * 32760.0)
		bytes[i * 2] = val_16 & 0xFF
		bytes[i * 2 + 1] = (val_16 >> 8) & 0xFF

	wav.data = bytes
	return wav

func _gen_rain_sample(_t: float, _i: int) -> float:
	var white = (randf() * 2.0 - 1.0) * 0.16
	_rain_filter_state = (_rain_filter_state * 0.88) + (white * 0.12)
	return _rain_filter_state

func _gen_thunder_sample(t: float, _i: int) -> float:
	var env = exp(-t * 1.6)
	if t < 0.09:
		env = t / 0.09
	var noise = (randf() * 2.0 - 1.0)
	_thunder_filter_state = (_thunder_filter_state * 0.94) + (noise * 0.06)
	return _thunder_filter_state * env * 1.4

func _gen_phone_sample(t: float, _i: int) -> float:
	if t > 0.9:
		return 0.0
	var pulse = 0.5 + 0.5 * sin(2.0 * PI * 20.0 * t)
	var tone = (sin(2.0 * PI * 440.0 * t) + sin(2.0 * PI * 480.0 * t)) * 0.28
	return tone * pulse

func _gen_page_sample(t: float, _i: int) -> float:
	var env = sin(t / 0.22 * PI)
	return (randf() * 2.0 - 1.0) * 0.22 * env

func _gen_click_sample(t: float, _i: int) -> float:
	var env = exp(-t * 70.0)
	return sin(2.0 * PI * 1400.0 * t) * env * 0.35

func _gen_clue_sample(t: float, _i: int) -> float:
	var freq = 523.25 # C5
	var env = exp(-t * 7.0)
	return (sin(2.0 * PI * freq * t) + 0.25 * sin(2.0 * PI * freq * 2.0 * t)) * env * 0.4

func _gen_chime_sample(t: float, _i: int) -> float:
	var freq = 440.0 if t < 0.3 else 659.25 # A4 -> E5
	var rel_t = t if t < 0.3 else (t - 0.3)
	var env = exp(-rel_t * 5.0)
	return (sin(2.0 * PI * freq * t) + 0.3 * sin(2.0 * PI * freq * 2.0 * t)) * env * 0.35

func _gen_footstep_sample(t: float, _i: int) -> float:
	var freq = 120.0 + (1.0 - t / 0.12) * 50.0
	var env = exp(-t * 32.0)
	var noise = (randf() * 2.0 - 1.0) * 0.2
	return (sin(2.0 * PI * freq * t) * 0.7 + noise) * env * 0.22

func _gen_door_locked_sample(t: float, _i: int) -> float:
	var click1 = sin(2.0 * PI * 800.0 * t) * exp(-t * 80.0) * 0.45
	var click2 = 0.0
	if t > 0.06:
		click2 = sin(2.0 * PI * 620.0 * (t - 0.06)) * exp(-(t - 0.06) * 70.0) * 0.45
	return click1 + click2

func _gen_door_open_sample(t: float, _i: int) -> float:
	var low_thud = sin(2.0 * PI * 95.0 * t) * exp(-t * 14.0) * 0.5
	var creak = sin(2.0 * PI * (210.0 + sin(t * 35.0) * 70.0) * t) * exp(-t * 9.0) * 0.25
	return low_thud + creak

func _gen_objection_sample(t: float, _i: int) -> float:
	var env = exp(-t * 3.5)
	var chord = (sin(2.0 * PI * 174.61 * t) * 0.4 + sin(2.0 * PI * 207.65 * t) * 0.35 + sin(2.0 * PI * 261.63 * t) * 0.3)
	return chord * env * 0.75

# --- Volume Controls and Settings ---

func set_master_volume(val: float) -> void:
	master_volume = clampf(val, 0.0, 1.0)
	var bus_idx = AudioServer.get_bus_index("Master")
	if bus_idx != -1:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(master_volume) if master_volume > 0.001 else -80.0)

func set_music_volume(val: float) -> void:
	music_volume = clampf(val, 0.0, 1.0)
	var db = (linear_to_db(music_volume) - 6.0) if music_volume > 0.001 else -80.0
	if music_player and music_player.playing:
		music_player.volume_db = db
	if music_player_b and music_player_b.playing:
		music_player_b.volume_db = db

func set_ambiance_volume(val: float) -> void:
	ambiance_volume = clampf(val, 0.0, 1.0)
	if rain_player:
		rain_player.volume_db = (linear_to_db(ambiance_volume) - 14.0) if ambiance_volume > 0.001 else -80.0

func set_sfx_volume(val: float) -> void:
	sfx_volume = clampf(val, 0.0, 1.0)
	var db = (linear_to_db(sfx_volume) - 6.0) if sfx_volume > 0.001 else -80.0
	if sfx_player:
		sfx_player.volume_db = db
	if thunder_player:
		thunder_player.volume_db = db + 2.0

func set_subtitles_enabled(enabled: bool) -> void:
	subtitles_enabled = enabled

func save_settings() -> void:
	var data: Dictionary = {}
	if FileAccess.file_exists(SETTINGS_PATH):
		var f_in = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
		if f_in:
			var json = JSON.new()
			if json.parse(f_in.get_as_text()) == OK and json.data is Dictionary:
				data = json.data
	data["master_volume"] = master_volume
	data["music_volume"] = music_volume
	data["ambiance_volume"] = ambiance_volume
	data["sfx_volume"] = sfx_volume
	data["subtitles_enabled"] = subtitles_enabled
	var f = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))

func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var f = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if not f:
		return
	var json = JSON.new()
	if json.parse(f.get_as_text()) == OK and json.data is Dictionary:
		var d = json.data
		set_master_volume(float(d.get("master_volume", 1.0)))
		set_music_volume(float(d.get("music_volume", 0.75)))
		set_ambiance_volume(float(d.get("ambiance_volume", 0.8)))
		set_sfx_volume(float(d.get("sfx_volume", 1.0)))
		subtitles_enabled = bool(d.get("subtitles_enabled", true))
