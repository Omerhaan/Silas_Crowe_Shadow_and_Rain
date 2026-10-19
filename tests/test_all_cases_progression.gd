extends Node

func _ready() -> void:
	print("==================================================")
	print("--- BEGIN ALL CASES FULL PROGRESSION & LOGIC TEST ---")
	print("==================================================")

	_test_case_01()
	_test_case_02()
	_test_case_03_retest()

	print("\n==================================================")
	print("=== ALL CASES 1, 2, AND 3 VERIFIED FLAWLESSLY! ===")
	print("==================================================")
	get_tree().quit(0)

func _test_case_01() -> void:
	print("\n--- [CASE 01: HARLOW MANOR] ---")
	GameState.current_case_id = "case01"
	GameState.inventory_items.clear()
	GameState.flags.clear()
	GameState.discovered_evidence.clear()
	GameState.collected_statements.clear()
	GameState.load_all_case_data("case01")

	# 1. Upper Floor Pike's Door Lock
	var upper_scene = load("res://cases/case01/rooms/upper_floor.tscn").instantiate()
	add_child(upper_scene)
	var door_pike = upper_scene.get_node("Door_To_Pike")
	assert(door_pike != null, "Door_To_Pike must exist")
	assert(door_pike.is_locked, "Door_To_Pike must initially be locked")
	assert(door_pike.required_key_id == "key_ring", "Door_To_Pike must require key_ring")

	door_pike.interact()
	assert(door_pike.is_locked, "Door_To_Pike should stay locked without key_ring")
	print("  [C1-1] Pike's door initially locked: OK")

	# 2. Kitchen Margaret Gating & Key Grant
	var inter_scene = load("res://scenes/ui/interrogation.tscn").instantiate()
	add_child(inter_scene)

	inter_scene.open_interrogation("margaret")
	var keys_topic = null
	for t in inter_scene.current_dialogue_data.get("topics", []):
		if t.get("id") == "keys":
			keys_topic = t
			break
	assert(keys_topic != null, "Margaret must have keys topic")

	# Try asking keys before E14
	inter_scene._on_topic_selected(keys_topic)
	assert(not GameState.has_item("key_ring"), "Margaret must NOT give key_ring before E14")
	print("  [C1-2] Margaret refuses to hand over keys without cause: OK")

	# Now discover dismissal letter E14
	GameState.add_evidence("E14")
	inter_scene._on_topic_selected(keys_topic)
	assert(GameState.has_item("key_ring"), "Margaret MUST give key_ring after E14")
	print("  [C1-3] Margaret breaks down upon E14 and gives key_ring: OK")
	inter_scene._on_exit_pressed()

	# Unlocking Pike's Door with key_ring
	door_pike.interact()
	assert(not door_pike.is_locked, "Door_To_Pike must unlock with key_ring")
	print("  [C1-4] Pike's door unlocked using key_ring: OK")
	upper_scene.queue_free()

	# 3. Dr. Hale Alibi Gating with E06
	inter_scene.open_interrogation("hale")
	var hale_alibi = null
	for t in inter_scene.current_dialogue_data.get("topics", []):
		if t.get("id") == "alibi":
			hale_alibi = t
			break
	assert(hale_alibi != null, "Hale must have alibi topic")
	inter_scene._on_topic_selected(hale_alibi)
	assert(not GameState.collected_statements.has("hale") or GameState.collected_statements["hale"].is_empty(), "Hale denies entering study before E06")

	# Confront Hale with E06 prescription slip
	GameState.add_evidence("E06")
	inter_scene._on_topic_selected(hale_alibi)
	assert(GameState.collected_statements.has("hale") and GameState.collected_statements["hale"].size() > 0, "Hale must confess study visit upon E06")
	print("  [C1-5] Dr. Hale alibi gated until E06 prescription slip: OK")
	inter_scene._on_exit_pressed()

	# 4. Julian Harlow Alibi Gating with E11
	inter_scene.open_interrogation("julian")
	var julian_alibi = null
	for t in inter_scene.current_dialogue_data.get("topics", []):
		if t.get("id") == "alibi":
			julian_alibi = t
			break
	assert(julian_alibi != null, "Julian must have alibi topic")
	inter_scene._on_topic_selected(julian_alibi)
	assert(not GameState.collected_statements.has("julian") or GameState.collected_statements["julian"].is_empty(), "Julian claims solo billiards before E11")

	GameState.add_evidence("E11")
	inter_scene._on_topic_selected(julian_alibi)
	assert(GameState.collected_statements.has("julian") and GameState.collected_statements["julian"].size() > 0, "Julian must confess debt upon E11")
	print("  [C1-6] Julian alibi gated until E11 billiard evidence: OK")
	inter_scene._on_exit_pressed()

	# 5. Wall Safe Minigame (SafeDialModal - code 1 9 4 1 from E16)
	var safe_modal = load("res://scenes/ui/safe_dial_modal.tscn").instantiate()
	add_child(safe_modal)
	safe_modal.open_modal()
	assert(safe_modal.visible, "Safe modal should open")

	# Wrong code test
	safe_modal._on_unlock_pressed()
	assert(not GameState.has_evidence("E07"), "Safe must not open with 0000")

	# Dial 1 9 4 4
	safe_modal._change_digit(0, 1) # 1
	safe_modal._change_digit(1, 9) # 9
	safe_modal._change_digit(2, 4) # 4
	safe_modal._change_digit(3, 4) # 4
	assert(safe_modal.digits == [1, 9, 4, 4], "Digits must be 1, 9, 4, 4")

	safe_modal._on_unlock_pressed()
	assert(GameState.has_evidence("E07"), "Safe must unlock and discover E07 with 1944")
	assert(GameState.flags.get("harlow_safe_opened", false) == true, "harlow_safe_opened flag must be set")
	print("  [C1-7] Wall safe cracked with 1944, discovered E07: OK")
	safe_modal.queue_free()
	inter_scene.queue_free()

func _test_case_02() -> void:
	print("\n--- [CASE 02: GREYWATER DOCKS] ---")
	GameState.current_case_id = "case02"
	GameState.inventory_items.clear()
	GameState.flags.clear()
	GameState.discovered_evidence.clear()
	GameState.collected_statements.clear()
	GameState.load_all_case_data("case02")

	# 1. Customs Office & Night Permit (E209 -> night_pass item)
	assert(not GameState.has_item("night_pass"), "Must not have night_pass initially")
	GameState.add_evidence("E209")
	assert(GameState.has_item("night_pass"), "Discovering E209 must grant night_pass item")
	print("  [C2-1] E209 discovered and granted night_pass: OK")

	# 2. Warehouse Boris & Saloon Passage
	var wh_scene = load("res://cases/case02/rooms/dock_warehouse.tscn").instantiate()
	add_child(wh_scene)
	var door_saloon = wh_scene.get_node("Door_To_Saloon")
	assert(door_saloon != null, "Door_To_Saloon must exist")
	assert(door_saloon.required_key_id == "night_pass", "Door_To_Saloon requires night_pass")

	var inter_scene = load("res://scenes/ui/interrogation.tscn").instantiate()
	add_child(inter_scene)

	inter_scene.open_interrogation("boris")
	var offer_pass_topic = null
	for t in inter_scene.current_dialogue_data.get("topics", []):
		if t.get("id") == "offer_night_pass":
			offer_pass_topic = t
			break
	assert(offer_pass_topic != null, "offer_night_pass topic must be available with night_pass")
	inter_scene._on_topic_selected(offer_pass_topic)
	assert(GameState.flags.get("boris_allowed", false) == true, "boris_allowed flag must be set")
	print("  [C2-2] Boris inspected night permit and cleared passage: OK")
	inter_scene._on_exit_pressed()

	door_saloon.interact()
	assert(not door_saloon.is_locked, "Saloon door must unlock with night_pass")
	print("  [C2-3] Saloon door unlocked: OK")

	# 3. Crane Winch Minigame (CraneWinchModal - code 2 4 0 from E206)
	var winch_modal = load("res://scenes/ui/crane_winch_modal.tscn").instantiate()
	add_child(winch_modal)
	winch_modal.open_modal()
	assert(winch_modal.visible, "Winch modal must open")

	# Wrong calibration test
	winch_modal._on_activate_pressed()
	assert(not GameState.has_evidence("E202"), "Winch must not activate with 000")

	# Calibrate 2 - 3 - 0
	winch_modal._change_digit(0, 2) # 2
	winch_modal._change_digit(1, 3) # 3
	winch_modal._change_digit(2, 0) # 0
	assert(winch_modal.digits == [2, 3, 0], "Digits must be 2, 3, 0")

	winch_modal._on_activate_pressed()
	assert(GameState.has_evidence("E202"), "Winch must lower and discover E202 with 230")
	assert(GameState.flags.get("crane_winch_lowered", false) == true, "crane_winch_lowered flag must be set")
	print("  [C2-4] Crane winch engaged with 230, lowered contraband crate E202: OK")
	winch_modal.queue_free()

	# 4. Captain Vance Contraband Cargo Gating
	inter_scene.open_interrogation("vance")
	var cargo_topic = null
	for t in inter_scene.current_dialogue_data.get("topics", []):
		if t.get("id") == "cargo":
			cargo_topic = t
			break
	assert(cargo_topic != null, "Vance must have cargo topic")

	# E202 already found from winch minigame above, so Vance confesses!
	inter_scene._on_topic_selected(cargo_topic)
	assert(GameState.collected_statements.has("vance") and GameState.collected_statements["vance"].size() > 0, "Vance must confess upon E202")
	print("  [C2-5] Captain Vance confessed contraband stashed on ship upon E202: OK")
	inter_scene._on_exit_pressed()

	# 5. Saloon Owner Corley Gating with E210
	inter_scene.open_interrogation("corley")
	var vance_arg_topic = null
	for t in inter_scene.current_dialogue_data.get("topics", []):
		if t.get("id") == "vance_argument":
			vance_arg_topic = t
			break
	assert(vance_arg_topic != null, "Corley must have vance_argument topic")

	# Try before E210
	inter_scene._on_topic_selected(vance_arg_topic)
	assert(not GameState.collected_statements.has("corley") or GameState.collected_statements["corley"].is_empty(), "Corley refuses to speak before E210")

	# Now find bribe ledger E210
	GameState.add_evidence("E210")
	inter_scene._on_topic_selected(vance_arg_topic)
	assert(GameState.collected_statements.has("corley") and GameState.collected_statements["corley"].size() > 0, "Corley must confess altercation upon E210")
	print("  [C2-6] Victor Corley testified to Vance/Marsh altercation upon E210: OK")
	inter_scene._on_exit_pressed()

	wh_scene.queue_free()
	inter_scene.queue_free()

func _test_case_03_retest() -> void:
	print("\n--- [CASE 03: ROYAL OPERA (RE-VERIFY)] ---")
	GameState.current_case_id = "case03"
	GameState.inventory_items.clear()
	GameState.flags.clear()
	GameState.discovered_evidence.clear()
	GameState.collected_statements.clear()
	GameState.load_all_case_data("case03")

	# 1. Foyer Door & Ticket Booth
	var foyer = load("res://cases/case03/rooms/opera_foyer.tscn").instantiate()
	add_child(foyer)
	var door_bs = foyer.get_node("Door_To_Backstage2")
	assert(door_bs.is_locked, "Backstage door locked initially")
	var tb = foyer.get_node("Prop_TicketBooth")
	tb.interact()
	assert(GameState.has_item("backstage_key") and GameState.has_item("smelling_salts"), "Ticket booth gives keys")
	door_bs.interact()
	assert(not door_bs.is_locked, "Backstage door unlocked")
	foyer.queue_free()

	# 2. Tumbler Lock Box (1 1 2)
	var tumbler = load("res://scenes/ui/tumbler_lock_modal.tscn").instantiate()
	add_child(tumbler)
	tumbler.open_modal()
	tumbler._change_digit(0, 1)
	tumbler._change_digit(1, 1)
	tumbler._change_digit(2, 2)
	tumbler._on_unlock_pressed()
	assert(GameState.has_item("bridge_key") and GameState.has_item("stage_lever"), "Must get bridge key and stage lever")
	tumbler.queue_free()

	print("  [C3-1] Case 3 regression check passed: OK")
