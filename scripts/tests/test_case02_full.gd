extends Node

func _ready() -> void:
	print("\n=======================================================")
	print("       CASE 02 (SİSLİ LİMAN) FULL VERIFICATION TEST     ")
	print("=======================================================")

	var passed: int = 0
	var total: int = 0

	# 1. Check Case 02 Registry & JSON Data
	total += 1
	var c2_reg_found = false
	for entry in GameState.case_registry:
		if entry.get("id") == "case02":
			c2_reg_found = true
			break
	if c2_reg_found:
		print("✔ [1] case02 registered in GameState.case_registry.")
		passed += 1
	else:
		printerr("❌ [1] case02 missing in case_registry!")

	# 2. Test Switch to Case02
	total += 1
	for entry in GameState.case_registry:
		if entry.get("id") == "case02":
			entry["unlocked"] = true
	var switch_ok = GameState.switch_case("case02")
	if switch_ok and GameState.current_case_id == "case02":
		print("✔ [2] Successfully switched to case02.")
		passed += 1
	else:
		printerr("❌ [2] Failed to switch to case02!")

	# 3. Verify Case02 Databases (Evidence, Suspects, Deductions, Caller Clues)
	total += 1
	var ev_count = GameState.evidence_db.size()
	var susp_count = GameState.suspects_db.size()
	var ded_count = GameState.deductions_db.size()
	if ev_count >= 11 and susp_count >= 5 and ded_count >= 6:
		print("✔ [3] Databases loaded: %d Clues, %d Suspects, %d Deductions." % [ev_count, susp_count, ded_count])
		passed += 1
	else:
		printerr("❌ [3] Incomplete databases: %d Clues, %d Suspects, %d Deductions!" % [ev_count, susp_count, ded_count])

	# 4. Verify All 5 Room Scenes Instantiate
	total += 1
	var rooms = ["dock_warehouse", "dock_pier", "dock_office", "dock_saloon", "captain_cabin"]
	var all_rooms_valid = true
	for r_name in rooms:
		var scene_path = "res://cases/case02/rooms/%s.tscn" % r_name
		if not ResourceLoader.exists(scene_path):
			scene_path = "res://scenes/cases/case02/rooms/%s.tscn" % r_name
		if not ResourceLoader.exists(scene_path):
			scene_path = "res://scenes/rooms/%s.tscn" % r_name
		if not ResourceLoader.exists(scene_path):
			printerr("❌ Room scene missing: ", scene_path)
			all_rooms_valid = false
			continue
		var res = load(scene_path)
		var inst = res.instantiate()
		if not inst:
			printerr("❌ Failed to instantiate room: ", scene_path)
			all_rooms_valid = false
		else:
			inst.queue_free()
	if all_rooms_valid:
		print("✔ [4] All 5 dock room scenes instantiate cleanly.")
		passed += 1
	else:
		printerr("❌ [4] One or more room scenes failed!")

	# 5. Verify Gatekeeper & Boris Door Lock Mechanism
	total += 1
	var wh_path = "res://cases/case02/rooms/dock_warehouse.tscn"
	if not ResourceLoader.exists(wh_path):
		wh_path = "res://scenes/cases/case02/rooms/dock_warehouse.tscn"
	if not ResourceLoader.exists(wh_path):
		wh_path = "res://scenes/rooms/dock_warehouse.tscn"
	var wh_res = load(wh_path)
	var wh = wh_res.instantiate()
	add_child(wh)
	var saloon_door = wh.get_node_or_null("Door_To_Saloon")
	var gatekeeper_ok = false
	if saloon_door and saloon_door.is_locked and saloon_door.required_key_id == "night_pass":
		# Test without pass: must stay locked
		saloon_door.interact()
		if saloon_door.is_locked:
			# Give pass to player
			GameState.add_item("night_pass", "Mühürlü Gece İzin Belgesi")
			saloon_door.interact()
			if not saloon_door.is_locked:
				gatekeeper_ok = true
	wh.queue_free()
	if gatekeeper_ok:
		print("✔ [5] Gatekeeper & Boris door locking mechanism verified (unlocks with night_pass).")
		passed += 1
	else:
		printerr("❌ [5] Boris door locking test failed!")

	# 6. Verify All 5 Suspect Dialogues
	total += 1
	var suspects = ["vance", "morris", "corley", "brandt", "boris"]
	var all_dialogues_ok = true
	for s_id in suspects:
		var d_path = "res://cases/case02/data/dialogues/%s.json" % s_id
		if not ResourceLoader.exists(d_path) and not FileAccess.file_exists(ProjectSettings.globalize_path(d_path)):
			d_path = "res://data/cases/case02/dialogues/%s.json" % s_id
		var d_data = GameState._load_json_file(d_path)
		if not d_data or not d_data.has("topics") or not d_data.has("evidence_reactions"):
			printerr("❌ Dialogue data invalid for suspect: ", s_id)
			all_dialogues_ok = false
	if all_dialogues_ok:
		print("✔ [6] All 5 suspect dialogues loaded with topics and reactions.")
		passed += 1
	else:
		printerr("❌ [6] Suspect dialogues verification failed!")

	# 7. Verify Case Solution & Deduction Synthesis
	total += 1
	GameState.add_evidence("E201")
	GameState.add_evidence("E204")
	GameState.add_evidence("E206")
	GameState.add_evidence("E207")
	GameState.add_evidence("E211")
	# Check D203 can be made
	var d203_inputs = GameState.deductions_db.get("D203", {}).get("inputs", [])
	var d203_ok = ("E201" in d203_inputs and "E204" in d203_inputs)
	# Check D206 can be made
	var d206_inputs = GameState.deductions_db.get("D206", {}).get("inputs", [])
	var d206_ok = ("E211" in d206_inputs and "E206" in d206_inputs)
	GameState.unlocked_deductions.append("D203")
	GameState.unlocked_deductions.append("D206")
	# Check solution validation
	var sol = GameState.case_data.get("solution", {})
	var killer_match = (sol.get("killer_id") == "vance")
	var method_match = (sol.get("weapon_method") == "cargo_crane_sabotage")
	var req_ev = sol.get("required_evidence", [])
	var req_ded = sol.get("required_deduction")
	var solution_valid = killer_match and method_match and (req_ded == "D203")
	for ev in req_ev:
		if not GameState.has_evidence(ev):
			solution_valid = false
	if d203_ok and d206_ok and solution_valid:
		print("✔ [7] Case 02 solution (Kaptan Vance + Vinç Sabotajı + D203 & D206) verified!")
		passed += 1
	else:
		printerr("❌ [7] Case 02 solution / deduction verification failed! d203_ok=", d203_ok, " d206_ok=", d206_ok)

	# 8. Verify All 7 Case 02 Cinematics
	total += 1
	var cin_files = [
		"cinematic_case02_01_office_exit.jpg",
		"cinematic_case02_02_road_sign.jpg",
		"cinematic_case02_travel.jpg",
		"cinematic_case02_04_dock_gates.jpg",
		"cinematic_case02_arrival.jpg",
		"cinematic_case02_06_crane_sabotage.jpg",
		"cinematic_case02_07_body_k3.jpg"
	]
	var all_cin_found = true
	for c_name in cin_files:
		var p1 = "res://cases/case02/assets/cinematics/" + c_name
		var p2 = "res://assets/cases/case02/cinematics/" + c_name
		var p3 = "res://assets/sprites/cinematics/" + c_name
		var exists = ResourceLoader.exists(p1) or ResourceLoader.exists(p2) or ResourceLoader.exists(p3) or FileAccess.file_exists(ProjectSettings.globalize_path(p1)) or FileAccess.file_exists(ProjectSettings.globalize_path(p2)) or FileAccess.file_exists(ProjectSettings.globalize_path(p3))
		if not exists:
			printerr("❌ Case 02 Cinematic missing: ", c_name)
			all_cin_found = false
	if all_cin_found:
		print("✔ [8] All 7 Case 02 Cinematics verified in modular assets!")
		passed += 1
	else:
		printerr("❌ [8] One or more Case 02 Cinematics missing!")

	# 9. Verify All 11 Case 02 Clue Visuals
	total += 1
	var inspect_scene = load("res://scenes/ui/inspect_view.tscn").instantiate()
	add_child(inspect_scene)
	var all_clues_visual_ok = true
	for i in range(1, 12):
		var ev_id = "E2%02d" % i
		inspect_scene.open_inspect(ev_id)
		var tex = inspect_scene.visual_texture.texture
		if tex == null:
			printerr("❌ InspectView failed to load texture for: ", ev_id)
			all_clues_visual_ok = false
	inspect_scene.queue_free()
	if all_clues_visual_ok:
		print("✔ [9] All 11 Case 02 Clue Visuals verified in InspectView (E201 - E211)!")
		passed += 1
	else:
		printerr("❌ [9] One or more Case 02 Clue Visuals missing!")

	# 10. Verify Case 02 Vance Confrontation & Newspaper Ending
	total += 1
	var conf_scene = load("res://scenes/cutscenes/confrontation_hale.tscn").instantiate()
	add_child(conf_scene)
	conf_scene._on_accusation_resolved(true, "vance")
	var conf_started = conf_scene.visible and conf_scene.lines.size() >= 5
	var conf_vance_speaker = (conf_scene.lines.size() > 3 and conf_scene.lines[3].get("speaker", "").contains("Vance"))
	# Advance all lines
	while conf_scene.current_line_index < conf_scene.lines.size():
		conf_scene._on_next_pressed()

	# Test ending modal
	var ending_modal = load("res://scenes/ui/case_ending_modal.tscn").instantiate()
	add_child(ending_modal)
	ending_modal.start_ending_sequence()
	var headline_text = ending_modal.headline_lbl.text
	var c2_ending_ok = headline_text.contains("KAPTAN VANCE") or headline_text.contains("CAPTAIN VANCE")
	conf_scene.queue_free()
	ending_modal.queue_free()

	if conf_started and conf_vance_speaker and c2_ending_ok:
		print("✔ [10] Case 02 Vance Confrontation & Newspaper Ending sequence verified!")
		passed += 1
	else:
		printerr("❌ [10] Case 02 Vance Confrontation / Ending test failed! headline=", headline_text)

	# Switch back to case01 to keep default state clean
	GameState.switch_case("case01")

	print("\n=======================================================")
	if passed == total:
		print("  ALL %d/%d CASE 02 TESTS PASSED! READY FOR PRODUCTION! " % [passed, total])
	else:
		printerr("  WARNING: %d/%d TESTS PASSED. CHECK ERRORS!" % [passed, total])
	print("=======================================================\n")
	get_tree().quit(0 if passed == total else 1)
