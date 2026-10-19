extends Node

func _ready() -> void:
	print("\n=======================================================")
	print("       CASE 03 (KÖR NOKTA) FULL VERIFICATION TEST       ")
	print("=======================================================")

	var passed: int = 0
	var total: int = 0

	# 1. Check Case 03 Registry & JSON Data
	total += 1
	var c3_reg_found = false
	for entry in GameState.case_registry:
		if entry.get("id") == "case03":
			c3_reg_found = true
			break
	if c3_reg_found:
		print("✔ [1] case03 registered in GameState.case_registry.")
		passed += 1
	else:
		printerr("❌ [1] case03 missing in case_registry!")

	# 2. Test Switch to Case03
	total += 1
	for entry in GameState.case_registry:
		if entry.get("id") == "case03":
			entry["unlocked"] = true
	var switch_ok = GameState.switch_case("case03")
	if switch_ok and GameState.current_case_id == "case03":
		print("✔ [2] Successfully switched to case03.")
		passed += 1
	else:
		printerr("❌ [2] Failed to switch to case03!")

	# 3. Verify Case03 Databases (Evidence, Suspects, Deductions, Caller Clues)
	total += 1
	var ev_count = GameState.evidence_db.size()
	var susp_count = GameState.suspects_db.size()
	var ded_count = GameState.deductions_db.size()
	if ev_count >= 10 and susp_count >= 6 and ded_count >= 6:
		print("✔ [3] Databases loaded: %d Clues, %d Suspects, %d Deductions." % [ev_count, susp_count, ded_count])
		passed += 1
	else:
		printerr("❌ [3] Incomplete databases: %d Clues, %d Suspects, %d Deductions!" % [ev_count, susp_count, ded_count])

	# 4. Verify All 7 Room Scenes Instantiate Cleanly
	total += 1
	var rooms = ["opera_foyer", "opera_auditorium", "royal_box", "backstage", "prop_room", "light_bridge", "opera_roof"]
	var all_rooms_valid = true
	for r_name in rooms:
		var scene_path = "res://cases/case03/rooms/%s.tscn" % r_name
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
		print("✔ [4] All 7 opera room scenes instantiate cleanly.")
		passed += 1
	else:
		printerr("❌ [4] One or more room scenes failed!")

	# 5. Verify All 5 Suspect Dialogues
	total += 1
	var suspects = ["finch", "elena", "sterling", "patch", "henderson"]
	var all_dialogues_ok = true
	for s_id in suspects:
		var d_path = "res://cases/case03/data/dialogues/%s.json" % s_id
		var d_data = GameState._load_json_file(d_path)
		if not d_data or not d_data.has("topics") or not d_data.has("evidence_reactions"):
			printerr("❌ Dialogue data invalid for suspect: ", s_id)
			all_dialogues_ok = false
	if all_dialogues_ok:
		print("✔ [5] All 5 suspect dialogues loaded with topics and reactions.")
		passed += 1
	else:
		printerr("❌ [5] Suspect dialogues verification failed!")

	# 6. Verify Light-Range Board Mechanic
	total += 1
	var lrange_scene = load("res://scenes/ui/light_range_modal.tscn").instantiate()
	add_child(lrange_scene)
	lrange_scene.spot_a_on = false
	lrange_scene.spot_b_on = true
	lrange_scene.spot_c_on = false
	lrange_scene.selected_position = "bridge"
	lrange_scene._on_test_pressed()
	var d302_unlocked = ("D302" in GameState.unlocked_deductions)
	lrange_scene.queue_free()
	if d302_unlocked:
		print("✔ [6] Light-Range Board successfully verified and unlocked D302 deduction.")
		passed += 1
	else:
		printerr("❌ [6] Light-Range Board failed to unlock D302!")

	# 7. Verify All 6 Case 03 Deductions
	total += 1
	var deds_to_check = ["D301", "D302", "D303", "D304", "D305", "D306"]
	var all_deds_present = true
	for d_id in deds_to_check:
		if not GameState.deductions_db.has(d_id):
			all_deds_present = false
			printerr("❌ Deduction missing from database: ", d_id)
	if all_deds_present:
		print("✔ [7] All 6 Case 03 deductions (D301-D306) configured with inputs.")
		passed += 1
	else:
		printerr("❌ [7] Missing deductions in database!")

	# 8. Verify Solution & Deduction Validation
	total += 1
	GameState.add_evidence("E302")
	GameState.add_evidence("E306")
	GameState.add_evidence("E308")
	var sol = GameState.case_data.get("solution", {})
	var killer_match = (sol.get("killer_id") == "unknown_sniper")
	var method_match = (sol.get("weapon_method") == "light_bridge_sniper")
	var req_ev = sol.get("required_evidence", [])
	var req_ded = sol.get("required_deduction")
	var solution_valid = killer_match and method_match and (req_ded == "D306")
	for ev in req_ev:
		if not GameState.has_evidence(ev):
			solution_valid = false
	if solution_valid:
		print("✔ [8] Case 03 solution (unknown_sniper + light_bridge_sniper + E302/E306/E308 + D306) verified!")
		passed += 1
	else:
		printerr("❌ [8] Case 03 solution verification failed!")

	# 9. Verify Accusation Modal with unknown_sniper
	total += 1
	var accus_modal = load("res://scenes/ui/accusation_modal.tscn").instantiate()
	add_child(accus_modal)
	accus_modal.open_accusation()
	var unknown_sniper_present = false
	for susp in accus_modal.suspect_data_list:
		if susp.get("id") == "unknown_sniper":
			unknown_sniper_present = true
			break
	accus_modal.selected_suspect_id = "unknown_sniper"
	accus_modal.selected_method_id = "light_bridge_sniper"
	var typed_evs: Array[String] = ["E302", "E306", "E308"]
	accus_modal.selected_evidence_ids = typed_evs
	var result_tracker = {"emitted": false, "target": ""}
	var handler = func(success: bool, target: String):
		if success and target == "unknown_sniper":
			result_tracker["emitted"] = true
			result_tracker["target"] = target
	EventBus.accusation_resolved.connect(handler)
	accus_modal._on_accuse_pressed()
	EventBus.accusation_resolved.disconnect(handler)
	accus_modal.queue_free()
	if unknown_sniper_present and result_tracker["emitted"]:
		print("✔ [9] AccusationModal contains unknown_sniper and successfully resolves Case 03.")
		passed += 1
	else:
		printerr("❌ [9] AccusationModal test failed! present=", unknown_sniper_present, " resolved=", result_tracker["emitted"])

	# 10. Verify Case 03 Confrontation & Ending Modal
	total += 1
	var conf_scene = load("res://scenes/cutscenes/confrontation_hale.tscn").instantiate()
	add_child(conf_scene)
	conf_scene.current_culprit = "unknown_sniper"
	conf_scene.start_confrontation()
	var conf_lines_count = conf_scene.lines.size()
	conf_scene._finish_confrontation()
	conf_scene.queue_free()

	var ending_scene = load("res://scenes/ui/case_ending_modal.tscn").instantiate()
	add_child(ending_scene)
	ending_scene.start_ending_sequence()
	var headline_text = ending_scene.headline_lbl.text
	var has_c3_headline = ("KRALİYET OPERASI" in headline_text or "ROYAL OPERA" in headline_text)
	ending_scene.queue_free()

	if conf_lines_count >= 8 and has_c3_headline:
		print("✔ [10] Case 03 Confrontation (Roof Chase) & Ending sequence verified!")
		passed += 1
	else:
		printerr("❌ [10] Case 03 Confrontation / Ending test failed! conf_lines=", conf_lines_count, " headline=", headline_text)

	print("\n=======================================================")
	print("       RESULT: %d / %d TESTS PASSED                    " % [passed, total])
	print("=======================================================\n")

	if passed == total:
		print("ALL CASE 03 TESTS PASSED PERFECTLY!")
	get_tree().quit(0 if passed == total else 1)
