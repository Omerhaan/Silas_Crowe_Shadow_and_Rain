extends Node

## Global GameState manager.
## Loads case JSON data and tracks game progress, discovered evidence, statements, and state.
## Supports multi-case architecture with dynamic case switching and case registry tracking.

var current_case_id: String = "case01"
var current_room_id: String = "main_hall"
var current_spawn_point: String = "default"

var case_registry: Array = []
var completed_cases: Array[String] = []

var case_data: Dictionary = {}
var evidence_db: Dictionary = {}    # id -> Dictionary
var suspects_db: Dictionary = {}    # id -> Dictionary
var deductions_db: Dictionary = {}  # id -> Dictionary
var inner_voice_db: Dictionary = {} # category -> Array

# Player progression
var case_states: Dictionary = {} # case_id -> { evidence, statements, deductions, inspected, solved, chances, room }
var discovered_evidence: Array[String] = []
var collected_statements: Dictionary = {}  # suspect_id -> Array[String]
var unlocked_deductions: Array[String] = []
var inspected_objects: Array[String] = []

var can_player_move: bool = true
var accusation_chances_left: int = 3
var inner_voice_count: int = 0
var secret_drawers_opened: int = 0
var case_solved: bool = false
var selected_souvenir: String = ""
var selected_souvenirs: Array[String] = []
var flags: Dictionary = {}
var memory_wall_items: Array[String] = []
var achievements_db: Dictionary = {}
var unlocked_achievements: Array[String] = []
var inventory_items: Array[String] = []
var intro_seen: bool = false
var font_scale: String = "medium"

func _ready() -> void:
	font_scale = _load_font_scale()
	ThemeDB.fallback_font_size = 6 if font_scale == "small" else (10 if font_scale == "large" else 8)
	load_case_registry()
	SaveSystem.sync_case_progress()
	load_all_case_data(current_case_id)
	EventBus.inner_voice_requested.connect(_on_inner_voice_triggered)

func _on_inner_voice_triggered(_text: String) -> void:
	inner_voice_count += 1
	check_achievements()

func load_case_registry() -> void:
	var reg = _load_json_file("res://data/cases/case_registry.json")
	if reg is Array:
		case_registry = reg
	else:
		case_registry = [
			{
				"id": "case01",
				"title": "Karanlık Malikâne",
				"subtitle": "Edmund Harlow Cinayeti",
				"year": 1946,
				"unlocked": true,
				"completed": false
			}
		]

func get_case_data_path(case_id: String, filename: String) -> String:
	var modular_path = "res://cases/%s/data/%s" % [case_id, filename]
	if FileAccess.file_exists(ProjectSettings.globalize_path(modular_path)) or ResourceLoader.exists(modular_path):
		return modular_path
	return "res://data/cases/%s/%s" % [case_id, filename]

func load_all_case_data(case_id: String) -> void:
	current_case_id = case_id

	# Clear previous case databases
	evidence_db.clear()
	suspects_db.clear()
	deductions_db.clear()
	inner_voice_db.clear()

	var case_path = get_case_data_path(case_id, "case.json")
	case_data = _load_json_file(case_path)
	
	var ev_list = _load_json_file(get_case_data_path(case_id, "evidence.json"))
	if ev_list is Array:
		for item in ev_list:
			evidence_db[item.get("id", "")] = item
			
	var susp_list = _load_json_file(get_case_data_path(case_id, "suspects.json"))
	if susp_list is Array:
		for susp in susp_list:
			var s_id = susp.get("id", "")
			suspects_db[s_id] = susp
			if not collected_statements.has(s_id):
				collected_statements[s_id] = []

	var ded_list = _load_json_file(get_case_data_path(case_id, "deductions.json"))
	if ded_list is Array:
		for ded in ded_list:
			deductions_db[ded.get("id", "")] = ded

	inner_voice_db = _load_json_file(get_case_data_path(case_id, "inner_voice.json"))

	var ach_list = _load_json_file("res://data/hub/achievements.json")
	if ach_list is Array:
		for ach in ach_list:
			achievements_db[ach.get("id", "")] = ach

func store_current_case_state() -> void:
	if current_case_id.is_empty():
		return
	case_states[current_case_id] = {
		"discovered_evidence": discovered_evidence.duplicate(),
		"collected_statements": collected_statements.duplicate(true),
		"unlocked_deductions": unlocked_deductions.duplicate(),
		"inspected_objects": inspected_objects.duplicate(),
		"case_solved": case_solved,
		"accusation_chances_left": accusation_chances_left,
		"current_room_id": current_room_id
	}

func restore_case_state(case_id: String) -> void:
	if case_states.has(case_id):
		var state: Dictionary = case_states[case_id]
		discovered_evidence = Array(state.get("discovered_evidence", []), TYPE_STRING, "", null)
		collected_statements = state.get("collected_statements", {}).duplicate(true)
		unlocked_deductions = Array(state.get("unlocked_deductions", []), TYPE_STRING, "", null)
		inspected_objects = Array(state.get("inspected_objects", []), TYPE_STRING, "", null)
		case_solved = state.get("case_solved", false)
		accusation_chances_left = state.get("accusation_chances_left", 3)
		var starting = case_data.get("starting_room", "main_hall")
		current_room_id = state.get("current_room_id", starting)
	else:
		discovered_evidence.clear()
		collected_statements.clear()
		unlocked_deductions.clear()
		inspected_objects.clear()
		case_solved = false
		accusation_chances_left = 3
		current_room_id = case_data.get("starting_room", "main_hall")
		store_current_case_state()

func switch_case(case_id: String, emit_room_change: bool = false) -> bool:
	# Verify case exists and is unlocked
	var target_entry = null
	for c in case_registry:
		if c.get("id", "") == case_id:
			target_entry = c
			break
	if not target_entry or not target_entry.get("unlocked", false):
		push_warning("[GameState] Case is locked or does not exist: " + case_id)
		return false

	# Preserve current case progress before switching
	store_current_case_state()

	# Load target case data & restore its progression
	load_all_case_data(case_id)
	restore_case_state(case_id)

	var target_room = current_room_id
	if target_room.is_empty():
		target_room = case_data.get("starting_room", "main_hall")
		current_room_id = target_room

	if emit_room_change:
		EventBus.room_change_requested.emit(target_room, "default")
	SaveSystem.save_game()
	return true

func complete_current_case() -> void:
	case_solved = true
	if current_case_id not in completed_cases:
		completed_cases.append(current_case_id)

	# Update registry status and unlock next case
	var unlock_next = false
	for c in case_registry:
		if c.get("id", "") == current_case_id:
			c["completed"] = true
			unlock_next = true
		elif unlock_next:
			c["unlocked"] = true
			unlock_next = false

	store_current_case_state()
	check_achievements()
	EventBus.case_completed.emit(current_case_id)
	SaveSystem.save_game()

func _load_json_file(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_warning("[GameState] File not found: " + path)
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	var json_str = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(json_str)
	if error == OK:
		return json.data
	else:
		push_error("[GameState] JSON Parse Error in %s: %s" % [path, json.get_error_message()])
		return {}

func add_evidence(ev_id: String) -> bool:
	if ev_id in discovered_evidence:
		return false
	discovered_evidence.append(ev_id)
	if ev_id == "E209" and not has_item("night_pass"):
		var loc_mgr = get_node_or_null("/root/LocalizationManager")
		var is_en = (loc_mgr and loc_mgr.get_locale() == "en")
		var pass_name = "Sealed Night Permit" if is_en else "Mühürlü Gece İzin Belgesi"
		add_item("night_pass", pass_name)
	EventBus.evidence_collected.emit(ev_id)
	check_achievements()
	SaveSystem.save_game()
	return true

func add_statement(suspect_id: String, statement_text: String) -> void:
	if not collected_statements.has(suspect_id):
		collected_statements[suspect_id] = []
	if statement_text not in collected_statements[suspect_id]:
		collected_statements[suspect_id].append(statement_text)
		EventBus.statement_collected.emit(suspect_id, statement_text)
		SaveSystem.save_game()

const CLUE_VOICES_EN = {
	"E01": "\"This face from somewhere... No, I can't recall. 22:10... An engraving on the back: 'K-5'. I pull out the watch in my pocket: K-1. Same model, same military insignia. This cannot be a coincidence.\"",
	"E02": "\"The key is still inserted in the lock on the inside. No one from outside could lock it and slide the key in. Harlow locked this door himself... There was someone he feared.\"",
	"E03": "\"The ink is smeared. Harlow must have collapsed while writing. He was about to write Julian out of his will... or perhaps someone else.\"",
	"E04": "\"Good cognac doesn't smell this harsh and bitter. Something was spiked into this glass afterwards.\"",
	"E05": "\"Harlow's daily heart drops. Normally a few drops would suffice. The entire bottle was emptied into his glass or medicine.\"",
	"E06": "\"20:50. Hale claimed he never entered the study. Yet here is a time-stamped prescription slip in his own handwriting right on the desk.\"",
	"E07": "\"'You will pay for the North with your life.' Harlow kept these threat letters hidden behind a locked safe. Who was blackmailing him over the war?\"",
	"E08": "\"The candle has melted down completely. The burn time indicates the room went dark long before midnight.\"",
	"E09": "\"The fireplace in the library is ice-cold. The ashes are hours old. Hale couldn't possibly have been reading here all evening.\"",
	"E10": "\"An empty digitalis bottle concealed behind library books. Matches Dr. Hale's medical kit.\"",
	"E11": "\"The billiard table is dusted in chalk, but untouched. Julian wasn't playing alone — or playing at all.\"",
	"E12": "\"Fresh ash from an expensive imported cigar. Julian doesn't smoke these — this belonged to Pike.\"",
	"E13": "\"A heavy promissory note for 5,000 pounds. Julian was desperate for Harlow's inheritance.\"",
	"E14": "\"A formal dismissal letter addressed to Margaret. Thirty years of loyal service ended with a cold note.\"",
	"E15": "\"A muddy bootprint on the windowsill leading outside. Staged to create the illusion of a locked room.\"",
	"E16": "\"Northern Operation, 1941. Harlow, myself, and a third officer whose face was torn away. The phantom wound in my mind.\"",
	"E17": "\"The telephone receiver was left off the hook. Harlow collapsed while trying to make one last call.\"",
	"E201": "\"The heavy freight crane cable was cleanly severed with acid, not snapped under tension. Sabotage.\"",
	"E202": "\"An unsealed military crate containing contraband arms destined for the northern black market.\"",
	"E203": "\"A heavy brass lantern stained with dried blood. The blunt weapon used in the murder.\"",
	"E204": "\"Captain Vance's heavy trench coat, speckled with sulfuric acid burns around the sleeve.\"",
	"E205": "\"The shortwave radio log shows encoded transmissions between the lighthouse and an offshore trawler.\"",
	"E206": "\"The harbor tide chart. High tide peaked at 02:40, coinciding with the container drop.\"",
	"E207": "\"An anonymous note typed with a defective 'e' key: 'Deliver the cargo tonight or Vance talks.'\"",
	"E208": "\"Teddy Marsh's corpse. On his wrist, an officer's watch engraved with 'K-3'. Another member of our unit.\"",
	"E209": "\"An official night pass bearing Arthur Morris's signature and the harbor authority wax seal.\"",
	"E210": "\"Morris's clandestine ledger listing payoff amounts from dock smuggling syndicates.\"",
	"E211": "\"The logbook entries between 23:15 and 23:50 were hastily added later with the same pen. Vance was never in his cabin at that hour.\"",
	"E301": "\"The K-4 mark... Dalton Reeve's sniper rifle abandoned in the northern blizzards of 1944. Someone dug it up from the snow and brought it back to its master.\"",
	"E302": "\"A spent .303 casing. The sniper stood right here, masked behind the glare of the spotlights, aiming into the Royal Box.\"",
	"E303": "\"At 20:51, Spot A was cut and Spot B flared. That lighting angle cast the north end of the catwalk into total darkness for everyone in the hall.\"",
	"E304": "\"The padlock wasn't forced. Whoever accessed the bridge used either Finch's key or a flawless duplicate.\"",
	"E305": "\"Wax with the key's teeth imprinted. Someone stole Finch's key a week ago, molded it, and slipped it back into his pocket unnoticed.\"",
	"E306": "\"Measure 112... The thunderous theatrical cannon blast. Reeve knew he was marked; he anticipated the exact moment. But he looked in the wrong direction.\"",
	"E307": "\"The spot gel was smoked with soot. While light poured onto the stage, the sniper's catwalk remained in pitch-black shadow. Masterful blind-spot engineering.\"",
	"E308": "\"The dropped 'r' letter... The identical typewriter used in Dr. Hale's blackmail and Captain Vance's threat note! The same phantom puppetmaster behind all three.\"",
	"E309": "\"The pocket watch froze at 20:52 sharp. The exact second the overture's cannon fired in measure 112.\"",
	"E310": "\"The sniper climbed through the hatch to the fire escape and melted into the misty alleys below. Cold, agile, and methodical.\""
}

func add_item(item_id: String, item_name: String = "") -> bool:
	if item_id in inventory_items:
		return false
	inventory_items.append(item_id)
	var title = item_name if not item_name.is_empty() else item_id
	var eb = get_node_or_null("/root/EventBus")
	if eb and eb.has_signal("toast_requested"):
		var loc_mgr = get_node_or_null("/root/LocalizationManager")
		var is_en = (loc_mgr and loc_mgr.get_locale() == "en")
		var prefix = "🎒 Added to Bag: " if is_en else "🎒 Çantaya Eklendi: "
		eb.toast_requested.emit(prefix + title)
	SaveSystem.save_game()
	return true

func has_item(item_id: String) -> bool:
	return item_id in inventory_items

func get_evidence_data(ev_id: String) -> Dictionary:
	var ev = evidence_db.get(ev_id, {})
	if ev.is_empty():
		var target_case = current_case_id
		if ev_id.begins_with("E3"):
			target_case = "case03"
		elif ev_id.begins_with("E2"):
			target_case = "case02"
		elif ev_id.begins_with("E"):
			target_case = "case01"
		var ev_list = _load_json_file(get_case_data_path(target_case, "evidence.json"))
		if ev_list is Array:
			for item in ev_list:
				var i_id = item.get("id", "")
				evidence_db[i_id] = item
				if i_id == ev_id:
					ev = item
	if ev.is_empty():
		return {}
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	if loc_mgr and loc_mgr.get_locale() == "en":
		var cloned = ev.duplicate()
		var name_key = "CLUE_" + ev_id + "_NAME"
		var desc_key = "CLUE_" + ev_id + "_DESC"
		cloned["ad"] = loc_mgr.tr_text(name_key, ev.get("ad", ""))
		cloned["aciklama"] = loc_mgr.tr_text(desc_key, ev.get("aciklama", ""))
		if CLUE_VOICES_EN.has(ev_id):
			cloned["ic_ses_yorumu"] = CLUE_VOICES_EN[ev_id]
		return cloned
	return ev

func get_suspect_data(susp_id: String) -> Dictionary:
	var susp = suspects_db.get(susp_id, {})
	if susp.is_empty():
		return {}
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	if loc_mgr and loc_mgr.get_locale() == "en":
		var cloned = susp.duplicate()
		if susp_id == "hale":
			cloned["rol"] = "Family Physician"
			cloned["alibi_ozeti"] = "Claimed to read in the library, but fireplace was cold."
			cloned["gorunur_motif"] = "Blackmail over lethal digitalis prescription."
		elif susp_id == "margaret":
			cloned["rol"] = "Housekeeper"
			cloned["alibi_ozeti"] = "Working in the kitchen and serving tea."
			cloned["gorunur_motif"] = "Long-time loyalty, feared dismissal notice."
		elif susp_id == "julian":
			cloned["rol"] = "Harlow's Nephew & Heir"
			cloned["alibi_ozeti"] = "Claimed to play billiards alone."
			cloned["gorunur_motif"] = "Heavy gambling debts (IOU note)."
		elif susp_id == "pike":
			cloned["rol"] = "Lawyer & Business Partner"
			cloned["alibi_ozeti"] = "Drafting contracts in the guest room."
			cloned["gorunur_motif"] = "Bitter dispute over wartime Northern profits."
		elif susp_id == "vance":
			cloned["rol"] = "Cargo Ship Captain"
			cloned["alibi_ozeti"] = "Claimed to be asleep in his cabin."
			cloned["gorunur_motif"] = "Smuggling military contraband and fear of exposure."
		elif susp_id == "morris":
			cloned["rol"] = "Harbor Master"
			cloned["alibi_ozeti"] = "Working late in the customs office."
			cloned["gorunur_motif"] = "Secret extortion and bribery network."
		elif susp_id == "brandt":
			cloned["rol"] = "Crane Operator"
			cloned["alibi_ozeti"] = "Left the warehouse floor before the shift ended."
			cloned["gorunur_motif"] = "Acid tampering and financial coercion."
		elif susp_id == "corley":
			cloned["rol"] = "Saloon Owner & Smuggler"
			cloned["alibi_ozeti"] = "Hosting card games at the Lighthouse Saloon."
			cloned["gorunur_motif"] = "Control over northern black-market trade."
		elif susp_id == "boris":
			cloned["rol"] = "Warehouse Bouncer"
			cloned["alibi_ozeti"] = "Guarding the warehouse doors."
			cloned["gorunur_motif"] = "Enforcing smuggler security under orders."
		elif susp_id == "unknown_sniper":
			cloned["rol"] = "Shadow Sniper"
			cloned["alibi_ozeti"] = "Fled across the opera roof and down the fire escape immediately after the shot."
			cloned["gorunur_motif"] = "Unsettled vengeance from the 1944 Northern Operation."
		elif susp_id == "finch":
			cloned["rol"] = "Stage & Lighting Manager"
			cloned["alibi_ozeti"] = "Stationed at the lighting switchboard backstage, surrounded by crew."
			cloned["gorunur_motif"] = "Crippling gambling debts; sole keeper of the bridge key."
		elif susp_id == "elena":
			cloned["rol"] = "Prima Donna Soprano"
			cloned["alibi_ozeti"] = "Singing an aria mid-stage before hundreds of patrons at 20:52."
			cloned["gorunur_motif"] = "Turbulent, broken wartime romance with Dalton Reeve."
		elif susp_id == "sterling":
			cloned["rol"] = "Royal Box Patron & Munitions Merchant"
			cloned["alibi_ozeti"] = "Seated front row in the Royal Box alongside high dignitaries."
			cloned["gorunur_motif"] = "Reeve was probing his wartime surplus arms transactions."
		elif susp_id == "patch":
			cloned["rol"] = "Sound & Effects Technician"
			cloned["alibi_ozeti"] = "Firing the theatrical pyrotechnic cannon on the effects perch."
			cloned["gorunur_motif"] = "Wartime veteran; may harbor old grudges."
		elif susp_id == "henderson":
			cloned["rol"] = "Foyer Porter & Box Office Clerk"
			cloned["alibi_ozeti"] = "Checking patron tickets at the marble entrance all evening."
			cloned["gorunur_motif"] = "None. Elderly loyal theatre employee."
		return cloned
	return susp

func has_evidence(ev_id: String) -> bool:
	return ev_id in discovered_evidence

func unlock_deduction(ded_id: String) -> bool:
	if ded_id in unlocked_deductions:
		return false
	unlocked_deductions.append(ded_id)
	EventBus.deduction_made.emit(ded_id)
	check_achievements()
	SaveSystem.save_game()
	return true

func unlock_achievement(ach_id: String) -> void:
	if ach_id not in unlocked_achievements:
		unlocked_achievements.append(ach_id)
		var title = ach_id
		var desc = ""
		if achievements_db.has(ach_id):
			title = achievements_db[ach_id].get("ad", ach_id)
			desc = achievements_db[ach_id].get("aciklama", "")
		EventBus.achievement_unlocked.emit(ach_id, title, desc)
		SaveSystem.save_game()

func check_achievements() -> void:
	if case_solved:
		unlock_achievement("A01") # İlk Kan
		if accusation_chances_left == 3:
			unlock_achievement("A03") # Doğru Teşhis
	if discovered_evidence.size() >= 17:
		unlock_achievement("A02") # Titiz (17 kanıt)
	if "D8" in unlocked_deductions:
		unlock_achievement("A04") # Kızıl Ringa Avcısı
	if selected_souvenir != "" or selected_souvenirs.size() > 0:
		unlock_achievement("A05") # Hatıra Koleksiyoncusu
	if inner_voice_count >= 10:
		unlock_achievement("A06") # Sessiz Gözlemci
	if secret_drawers_opened >= 3:
		unlock_achievement("A07") # Gizli Çekmeceler

func is_souvenir_placed(item_id: String) -> bool:
	return item_id in selected_souvenirs or item_id == selected_souvenir

func toggle_souvenir(item_id: String, item_name: String = "") -> bool:
	if item_id in selected_souvenirs:
		selected_souvenirs.erase(item_id)
	else:
		selected_souvenirs.append(item_id)
	if selected_souvenirs.size() > 0:
		selected_souvenir = item_name if item_name != "" else selected_souvenirs[0]
	else:
		selected_souvenir = ""
	check_achievements()
	SaveSystem.save_game()
	return item_id in selected_souvenirs

func check_deduction_pair(clue_a: String, clue_b: String) -> Dictionary:
	if clue_a == "" or clue_b == "" or clue_a == clue_b:
		return {}

	for ded_id in deductions_db.keys():
		var ded = deductions_db[ded_id]
		var inputs: Array = ded.get("inputs", [])
		if inputs.size() == 2:
			if (inputs[0] == clue_a and inputs[1] == clue_b) or (inputs[0] == clue_b and inputs[1] == clue_a):
				return ded
		elif inputs.size() > 2:
			# For compound deductions like D7, check if both clues are in the inputs
			# and all inputs are currently unlocked/discovered
			var all_present = true
			for req in inputs:
				var found = false
				if req.begins_with("D"):
					found = req in unlocked_deductions
				else:
					found = req in discovered_evidence
				if not found:
					all_present = false
					break
			if all_present and (clue_a in inputs and clue_b in inputs):
				return ded
	return {}

func set_font_scale(scale: String) -> void:
	if scale != "small" and scale != "medium" and scale != "large":
		scale = "medium"
	font_scale = scale
	ThemeDB.fallback_font_size = 6 if scale == "small" else (10 if scale == "large" else 8)
	_save_font_scale(scale)
	EventBus.font_scale_changed.emit(scale)

func get_font_scale() -> String:
	return font_scale

func _load_font_scale() -> String:
	var path = "user://game_settings.json"
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var json = JSON.new()
			if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
				return json.data.get("font_scale", "medium")
	return "medium"

func _save_font_scale(scale: String) -> void:
	var path = "user://game_settings.json"
	var data: Dictionary = {}
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var json = JSON.new()
			if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
				data = json.data
	data["font_scale"] = scale
	var out = FileAccess.open(path, FileAccess.WRITE)
	if out:
		out.store_string(JSON.stringify(data, "\t"))
