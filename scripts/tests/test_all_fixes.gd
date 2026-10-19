extends Node2D

## Comprehensive Automated Test Suite for All 5 Fixes:
## 1. NPC Interaction & Topics
## 2. Character Alpha Bounding Box Scale Measurement (±2px, bottom aligned)
## 3. DialogueBox formatting, speaker matching, caller glitch silhouette & spoiler check
## 4. Hub state machine, exit lock before call, and locked mansion doors
## 5. Mansion 3x2 topology, single Study exit, bedroom integration, bidirectional reachability

var passed_count: int = 0
var failed_count: int = 0

func _ready() -> void:
	print("==================================================")
	print("--- STARTING 5 FIXES AUTOMATED TEST SUITE ---")
	print("==================================================")

	test_fix1_npc_interaction()
	test_fix2_character_scales()
	test_fix3_dialogue_box()
	test_fix4_hub_state_and_locks()
	test_fix5_mansion_topology()

	print("==================================================")
	print("TEST RESULTS: Passed: %d, Failed: %d" % [passed_count, failed_count])
	print("==================================================")

	if failed_count == 0:
		print(">>> ALL TESTS PASSED SUCCESSFULLY! <<<")
	else:
		push_error(">>> SOME TESTS FAILED! <<<")

	await get_tree().create_timer(0.5).timeout
	get_tree().quit(0 if failed_count == 0 else 1)

func assert_true(cond: bool, test_name: String) -> void:
	if cond:
		passed_count += 1
		print("  [PASS] " + test_name)
	else:
		failed_count += 1
		push_error("  [FAIL] " + test_name)

func test_fix1_npc_interaction() -> void:
	print("\n--- TEST 1: NPC Interaction & Topics ---")
	var suspects = ["hale", "pike", "margaret", "julian"]
	var required_topic_ids = ["night_events", "harlow_relation", "alibi", "who_called", "present_evidence"]

	for s in suspects:
		var path = "res://data/cases/case01/dialogues/%s.json" % s
		var file = FileAccess.open(path, FileAccess.READ)
		assert_true(file != null, "Dialogue JSON exists: " + path)
		if file:
			var json_text = file.get_as_text()
			var data = JSON.parse_string(json_text)
			assert_true(data is Dictionary, "JSON parsed as Dictionary: " + s)
			var topics_list = data.get("topics", [])
			var found_ids = []
			for t in topics_list:
				found_ids.append(t.get("id", ""))
			for req in required_topic_ids:
				assert_true(found_ids.has(req), "Suspect '%s' has topic '%s'" % [s, req])

	# Test in room scenes
	var npc_rooms = {
		"library": "hale",
		"dining_room": "pike",
		"kitchen": "margaret",
		"billiard_room": "julian"
	}
	for r_id in npc_rooms.keys():
		var scene_path = "res://scenes/rooms/%s.tscn" % r_id
		var scn = load(scene_path)
		assert_true(scn != null, "Scene loaded: " + scene_path)
		if scn:
			var inst = scn.instantiate()
			var found = false
			for c in inst.get_children():
				var cid = str(c.get("character_id"))
				var oid = str(c.get("object_id"))
				if cid == npc_rooms[r_id] or oid == "npc_" + npc_rooms[r_id] or c.name.to_lower().contains(npc_rooms[r_id]):
					found = true
					var dname = c.get("display_name")
					if dname == "" and c.get("character_name") != null:
						dname = c.get("character_name")
					assert_true(dname != "", "NPC '%s' has talk prompt or name: %s" % [r_id, dname])
			assert_true(found, "NPC found in room: " + r_id)
			inst.queue_free()

func test_fix2_character_scales() -> void:
	print("\n--- TEST 2: Character Alpha Heights & Bottom Alignment ---")
	var targets = {
		"res://assets/sprites/characters/silas_idle_down.png": 100,
		"res://assets/sprites/characters/hale_idle_down.png": 102,
		"res://assets/sprites/characters/julian_idle_down.png": 98,
		"res://assets/sprites/characters/pike_idle_down.png": 98,
		"res://assets/sprites/characters/margaret_idle_down.png": 94,
		"res://assets/sprites/characters/edmund_idle_down.png": 98
	}

	for path in targets.keys():
		var expected = targets[path]
		var real_path = ProjectSettings.globalize_path(path)
		var img = Image.load_from_file(real_path)
		assert_true(img != null, "Sprite image loaded: " + path)
		if img:
			var min_y = 9999
			var max_y = -1
			for y in range(img.get_height()):
				for x in range(img.get_width()):
					if img.get_pixel(x, y).a > 0.05:
						if y < min_y: min_y = y
						if y > max_y: max_y = y

			var measured_height = (max_y - min_y + 1) if max_y >= min_y else 0
			var diff = abs(measured_height - expected)
			assert_true(diff <= 2, "Height %s: measured=%d, expected=%d (diff=%d <= 2px)" % [path.get_file(), measured_height, expected, diff])
			var bottom_gap = img.get_height() - 1 - max_y
			assert_true(bottom_gap == 0, "Soles touching canvas bottom: %s (bottom_gap=%d)" % [path.get_file(), bottom_gap])

func test_fix3_dialogue_box() -> void:
	print("\n--- TEST 3: DialogueBox Component & Spoiler Check ---")
	var scn = load("res://scenes/ui/dialogue_box.tscn")
	assert_true(scn != null, "DialogueBox scene exists")
	if scn:
		var dbox = scn.instantiate()
		add_child(dbox)

		# 1. Silas inner voice
		dbox.set_dialogue("INNER_VOICE", "Fırtına gittikçe artıyor.")
		assert_true(dbox.inner_voice_badge.visible == true, "Inner voice badge visible")
		assert_true(dbox.speaker_name_label.text.to_upper().contains("SILAS") or dbox.speaker_name_label.text.to_upper().contains("SİLAS"), "Inner voice speaker is Silas Crowe")
		assert_true(dbox.portrait_texture.texture != null, "Silas portrait loaded")

		# 2. Suspect Dr. Hale
		dbox.set_dialogue("Dr. Victor Hale", "Ben suçsuzum.")
		assert_true(dbox.inner_voice_badge.visible == false, "Suspect badge hidden")
		assert_true(dbox.speaker_name_label.text.to_upper().contains("HALE"), "Speaker is Dr. Victor Hale")
		assert_true(dbox.portrait_texture.texture != null, "Hale portrait loaded")

		# 3. Mystery Caller (GLITCH SILHOUETTE)
		dbox.set_dialogue("Arayan", "Kuzey Operasyonu'nu hatırla...")
		assert_true(dbox.speaker_name_label.text == "???", "Caller name masked as ???")
		assert_true(dbox.portrait_texture.texture != null, "Caller glitch silhouette loaded")

		# 4. Spoiler test: Elias Wren must not be revealed
		dbox.set_dialogue("Elias Wren", "Gerçekler ortaya çıkacak.")
		assert_true(dbox.speaker_name_label.text != "Elias Wren", "Spoiler protected: Elias Wren masked")
		assert_true(dbox.speaker_name_label.text == "???", "Elias Wren masked as ???")

		# 5. System observation
		dbox.set_dialogue("", "Eski ahşap zemin gıcırdıyor.")
		assert_true(dbox.portrait_container.visible == false, "System text hides portrait")
		assert_true(dbox.speaker_name_label.visible == false, "System text hides name")

		dbox.queue_free()

func test_fix4_hub_state_and_locks() -> void:
	print("\n--- TEST 4: Hub State Machine & Door Locks ---")
	# Check HUD has no silas_office nav connections
	var hud_scn = load("res://scenes/ui/hud.tscn")
	var hud = hud_scn.instantiate()
	add_child(hud)
	var room_conns = hud.get("room_connections")
	assert_true(not room_conns.has("silas_office"), "HUD room_connections does NOT contain silas_office")
	hud.queue_free()

	# Check Office door exit logic
	var office_scn = load("res://scenes/hub/silas_office.tscn")
	var office = office_scn.instantiate()
	add_child(office)
	assert_true(office.has_method("on_door_interacted"), "Office has on_door_interacted method")

	# Before call:
	GameState.case_solved = false
	var voice_holder = [""]
	var callable = func(text: String): voice_holder[0] = text
	EventBus.inner_voice_requested.connect(callable)

	office.on_door_interacted()
	assert_true(voice_holder[0].contains("Bu yağmurda dışarı çıkacak bir sebebim yok"), "Before call: exit gives inner voice '%s'" % voice_holder[0])

	# Case solved:
	GameState.case_solved = true
	office.current_state = office.HubState.CASE_SOLVED
	voice_holder[0] = ""
	office.on_door_interacted()
	assert_true(voice_holder[0].contains("Sıradaki vaka henüz yok"), "Case solved: exit gives inner voice '%s'" % voice_holder[0])

	EventBus.inner_voice_requested.disconnect(callable)
	GameState.case_solved = false
	office.queue_free()

	# Check locked mansion doors: Main Hall front door and Kitchen back door
	var hall_scn = load("res://scenes/rooms/main_hall.tscn")
	var hall = hall_scn.instantiate()
	var front_door = hall.get_node_or_null("Door_FrontDoor")
	assert_true(front_door != null, "Main Hall has Door_FrontDoor")
	if front_door:
		assert_true(front_door.is_locked == true, "Door_FrontDoor is locked")
		assert_true(front_door.locked_message.contains("Köprü çöktü"), "Door_FrontDoor has bridge collapsed message")
	hall.queue_free()

	var kit_scn = load("res://scenes/rooms/kitchen.tscn")
	var kit = kit_scn.instantiate()
	var back_door = kit.get_node_or_null("Door_KitchenBackDoor")
	assert_true(back_door != null, "Kitchen has Door_KitchenBackDoor")
	if back_door:
		assert_true(back_door.is_locked == true, "Door_KitchenBackDoor is locked")
		assert_true(back_door.locked_message.contains("Köprü çöktü"), "Door_KitchenBackDoor has bridge collapsed message")
	kit.queue_free()

func test_fix5_mansion_topology() -> void:
	print("\n--- TEST 5: Mansion 3x2 Topology & Bedrooms ---")
	# 1. Study has EXACTLY 1 exit (to Main Hall)
	var study_scn = load("res://scenes/rooms/study.tscn")
	var study = study_scn.instantiate()
	var door_count = 0
	var door_targets = []
	for c in study.get_children():
		if c.name.begins_with("Door_"):
			door_count += 1
			door_targets.append(c.get("target_room_id"))
	assert_true(door_count == 1, "Study has EXACTLY 1 door (found: %d)" % door_count)
	assert_true(door_targets.has("main_hall"), "Study's only door leads to main_hall")
	assert_true(not door_targets.has("library"), "Study does NOT lead to library")
	study.queue_free()

	# 2. Library has Door_To_Billiard, but NOT Door_To_Study
	var lib_scn = load("res://scenes/rooms/library.tscn")
	var lib = lib_scn.instantiate()
	var lib_door_to_study = lib.get_node_or_null("Door_To_Study")
	assert_true(lib_door_to_study == null, "Library does NOT have Door_To_Study")
	var lib_door_to_billiard = lib.get_node_or_null("Door_To_Billiard")
	assert_true(lib_door_to_billiard != null, "Library has Door_To_Billiard")
	if lib_door_to_billiard:
		assert_true(lib_door_to_billiard.get("target_room_id") == "billiard_room", "Library door leads to billiard_room")
	lib.queue_free()

	# 2b. Main Hall has door next to stairs leading to Study
	var hall_scn = load("res://scenes/rooms/main_hall.tscn")
	var hall = hall_scn.instantiate()
	var hall_door_to_study = hall.get_node_or_null("Door_To_Study")
	assert_true(hall_door_to_study != null, "Main Hall has Door_To_Study")
	if hall_door_to_study:
		assert_true(hall_door_to_study.get("target_room_id") == "study", "Main Hall door leads to study")
	hall.queue_free()

	# 2c. Dining Room has left door to kitchen and right door to billiard room
	var din_scn = load("res://scenes/rooms/dining_room.tscn")
	var din = din_scn.instantiate()
	var din_to_kitchen = din.get_node_or_null("Door_To_Kitchen")
	var din_to_billiard = din.get_node_or_null("Door_To_Billiard")
	assert_true(din_to_kitchen != null, "Dining Room has Door_To_Kitchen")
	assert_true(din_to_billiard != null, "Dining Room has Door_To_Billiard")
	if din_to_kitchen:
		assert_true(din_to_kitchen.get("target_room_id") == "kitchen", "Dining left door leads to kitchen")
	if din_to_billiard:
		assert_true(din_to_billiard.get("target_room_id") == "billiard_room", "Dining right door leads to billiard_room")
	din.queue_free()

	var hud_scn = load("res://scenes/ui/hud.tscn")
	var hud_inst = hud_scn.instantiate()

	# 3. Upper Floor has 3 doors to bedrooms + 1 door to Main Hall
	var upper_scn = load("res://scenes/rooms/upper_floor.tscn")
	var upper = upper_scn.instantiate()
	assert_true(upper.get_node_or_null("Door_To_MainHall") != null, "Upper Floor has Door_To_MainHall")
	assert_true(upper.get_node_or_null("Door_To_Julian") != null, "Upper Floor has Door_To_Julian")
	assert_true(upper.get_node_or_null("Door_To_Harlow") != null, "Upper Floor has Door_To_Harlow")
	assert_true(upper.get_node_or_null("Door_To_Pike") != null, "Upper Floor has Door_To_Pike")
	upper.queue_free()

	# 4. Bedroom scenes exist and exit to upper_floor via corridor arrow
	var bedrooms = ["harlow_bedroom", "julian_room", "pike_room"]
	for b in bedrooms:
		var scn_path = "res://scenes/rooms/%s.tscn" % b
		var scn = load(scn_path)
		assert_true(scn != null, "Bedroom scene exists: " + scn_path)
		var exits_to_upper = false
		if hud_inst.get("room_connections") and hud_inst.room_connections.has(b):
			var b_conns = hud_inst.room_connections[b]
			for side in b_conns.keys():
				if b_conns[side].get("room") == "upper_floor":
					exits_to_upper = true
		assert_true(exits_to_upper, "%s exits to upper_floor via corridor arrow" % b)
	hud_inst.queue_free()

	# 5. Evidence locations: E12 in julian_room, E13 in pike_room, E16 in harlow_bedroom
	var ev_file = FileAccess.open("res://data/cases/case01/evidence.json", FileAccess.READ)
	if ev_file:
		var ev_data = JSON.parse_string(ev_file.get_as_text())
		var ev_locs = {}
		for item in ev_data:
			ev_locs[item.get("id")] = item.get("bulundugu_yer")
		assert_true(ev_locs.get("E12") == "julian_room", "E12 located in julian_room")
		assert_true(ev_locs.get("E13") == "pike_room", "E13 located in pike_room")
		assert_true(ev_locs.get("E16") == "harlow_bedroom", "E16 located in harlow_bedroom")
