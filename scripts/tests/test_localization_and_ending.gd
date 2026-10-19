extends Node

func _ready() -> void:
	print("\n=== RUNNING LOCALIZATION & CASE ENDING VERIFICATION TEST ===")
	var passed = 0
	var total = 0

	# 1. LocalizationManager presence
	total += 1
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	if loc_mgr != null:
		print("✔ [1] LocalizationManager autoload is registered and active.")
		passed += 1
	else:
		printerr("❌ [1] LocalizationManager autoload missing!")

	# 2. English localization test
	total += 1
	if loc_mgr:
		loc_mgr.set_locale("en")
		var en_new_game = tr("UI_NEW_GAME")
		var en_clue1 = loc_mgr.tr_text("CLUE_E01_NAME")
		if en_new_game == "New Game" and en_clue1 == "Frozen Pocket Watch":
			print("✔ [2] English localization works: UI_NEW_GAME='%s', CLUE_E01='%s'" % [en_new_game, en_clue1])
			passed += 1
		else:
			printerr("❌ [2] English localization mismatch: '%s', '%s'" % [en_new_game, en_clue1])

	# 3. Turkish localization test
	total += 1
	if loc_mgr:
		loc_mgr.set_locale("tr")
		var tr_new_game = tr("UI_NEW_GAME")
		var tr_clue1 = loc_mgr.tr_text("CLUE_E01_NAME")
		if tr_new_game == "Yeni Oyun" and tr_clue1 == "Durmuş Cep Saati":
			print("✔ [3] Turkish localization works: UI_NEW_GAME='%s', CLUE_E01='%s'" % [tr_new_game, tr_clue1])
			passed += 1
		else:
			printerr("❌ [3] Turkish localization mismatch: '%s', '%s'" % [tr_new_game, tr_clue1])

	# 4. GameState dynamic localization getter test
	total += 1
	if loc_mgr:
		loc_mgr.set_locale("en")
		var ev_en = GameState.get_evidence_data("E01")
		loc_mgr.set_locale("tr")
		var ev_tr = GameState.get_evidence_data("E01")
		if ev_en.get("ad", "") == "Frozen Pocket Watch" and ev_tr.get("ad", "").begins_with("Kırık cep saati"):
			print("✔ [4] GameState evidence getter responds to active locale dynamically (EN: '%s', TR: '%s')." % [ev_en.get("ad", ""), ev_tr.get("ad", "")])
			passed += 1
		else:
			printerr("❌ [4] GameState getter localization failed! EN='%s', TR='%s'" % [ev_en.get("ad", ""), ev_tr.get("ad", "")])

	# 5. CaseEndingModal scene test
	total += 1
	var ending_scene = load("res://scenes/ui/case_ending_modal.tscn")
	if ending_scene:
		var ending_inst = ending_scene.instantiate()
		add_child(ending_inst)
		ending_inst.start_ending_sequence()
		assert(ending_inst.visible == true, "CaseEndingModal did not open!")
		assert(ending_inst.newspaper_panel.visible == true, "Newspaper stage not visible!")
		print("✔ [5.1] Stage 1: 1946 Newspaper front page active: '%s'" % ending_inst.headline_lbl.text)

		# Advance to stage 2: Rating
		ending_inst._show_stage(2)
		assert(ending_inst.rating_panel.visible == true, "Rating stage not visible!")
		assert(ending_inst.rank_badge_lbl.text != "", "Rank badge missing!")
		print("✔ [5.2] Stage 2: Case Rating active: Rank '%s' - '%s'" % [ending_inst.rank_badge_lbl.text, ending_inst.rank_title_lbl.text])

		# Advance to stage 3: Credits
		ending_inst._show_stage(3)
		assert(ending_inst.credits_panel.visible == true, "Credits stage not visible!")
		assert(ending_inst.return_office_btn.text != "", "Return button missing!")
		print("✔ [5.3] Stage 3: Credits Roll active: '%s'" % ending_inst.credits_title_lbl.text)

		ending_inst.queue_free()
		passed += 1
	else:
		printerr("❌ [5] CaseEndingModal scene could not be loaded!")

	# 6. Settings Modal Language selector test
	total += 1
	var settings_scene = load("res://scenes/ui/settings_modal.tscn")
	if settings_scene:
		var sett_inst = settings_scene.instantiate()
		add_child(sett_inst)
		sett_inst.open_settings()
		if sett_inst.language_btn != null:
			print("✔ [6] SettingsModal Language selector button present and verified: '%s'" % sett_inst.language_btn.text)
			passed += 1
		else:
			printerr("❌ [6] Language button missing from SettingsModal!")
		sett_inst.queue_free()

	# 7. Door Localization Test
	total += 1
	var door_scene = load("res://scenes/entities/door.tscn")
	if door_scene and loc_mgr:
		var door = door_scene.instantiate()
		door.door_name = "Ana Hol"
		door.target_room_id = "main_hall"
		loc_mgr.set_locale("en")
		var door_en = door.get_localized_name()
		loc_mgr.set_locale("tr")
		var door_tr = door.get_localized_name()
		assert(door_en == "Main Hall", "Door EN failed: " + door_en)
		assert(door_tr == "Ana Hol", "Door TR failed: " + door_tr)
		door.queue_free()
		print("✔ [7] Door localization verified (EN: '%s', TR: '%s')." % [door_en, door_tr])
		passed += 1

	# 8. Interactable Prop Localization Test
	total += 1
	var prop_scene = load("res://scenes/entities/interactable.tscn")
	if prop_scene and loc_mgr:
		var prop = prop_scene.instantiate()
		prop.object_id = "study_desk"
		prop.display_name = "Harlow'un Çalışma Masası"
		loc_mgr.set_locale("en")
		var prop_en = prop.get_localized_name()
		loc_mgr.set_locale("tr")
		var prop_tr = prop.get_localized_name()
		assert(prop_en == "Harlow's Desk", "Prop EN failed: " + prop_en)
		assert(prop_tr == "Harlow'un Çalışma Masası", "Prop TR failed: " + prop_tr)
		prop.queue_free()
		print("✔ [8] Interactable prop localization verified (EN: '%s', TR: '%s')." % [prop_en, prop_tr])
		passed += 1

	# 9. Interactable Inner Voice Localization Test
	total += 1
	if prop_scene and loc_mgr:
		var prop = prop_scene.instantiate()
		prop.object_id = "study_window"
		prop.custom_inner_voice = "\"Dışarıda köpüren deniz ve fırtına. Köprü çoktan çökmüş olmalı.\""
		loc_mgr.set_locale("en")
		var voice_en = prop.get_localized_inner_voice()
		loc_mgr.set_locale("tr")
		var voice_tr = prop.get_localized_inner_voice()
		assert("Churning sea" in voice_en, "Voice EN failed: " + voice_en)
		assert("köpüren deniz" in voice_tr, "Voice TR failed: " + voice_tr)
		prop.queue_free()
		print("✔ [9] Prop inner voice localization verified (EN: '%s', TR: '%s')." % [voice_en.substr(0, 30), voice_tr.substr(0, 30)])
		passed += 1

	# 10. NPC Localization Test
	total += 1
	var npc_scene = load("res://scenes/entities/npc.tscn")
	if npc_scene and loc_mgr:
		var npc = npc_scene.instantiate()
		npc.character_id = "npc_dr_hale"
		npc.display_name = "Dr. Victor Hale"
		loc_mgr.set_locale("en")
		var npc_en = npc.get_localized_name()
		loc_mgr.set_locale("tr")
		var npc_tr = npc.get_localized_name()
		assert(npc_en == "Talk: Dr. Victor Hale", "NPC EN failed: " + npc_en)
		assert(npc_tr == "Dr. Victor Hale ile Konuş", "NPC TR failed: " + npc_tr)
		npc.queue_free()
		print("✔ [10] NPC prompt localization verified (EN: '%s', TR: '%s')." % [npc_en, npc_tr])
		passed += 1

	# 11. InspectView Visual Texture Verification
	total += 1
	var inspect_scene = load("res://scenes/ui/inspect_view.tscn")
	if inspect_scene:
		var insp = inspect_scene.instantiate()
		add_child(insp)
		# Test Case 1 E01
		insp.open_inspect("E01")
		assert(insp.visual_texture.texture != null and insp.visual_texture.visible, "E01 inspect texture missing!")
		# Test Case 2 E208
		insp.open_inspect("E208")
		assert(insp.visual_texture.texture != null and insp.visual_texture.visible, "E208 inspect texture missing!")
		# Test Case 2 E208 back lid flip
		insp._on_special_action_pressed()
		assert(insp.visual_texture.texture != null and insp.visual_texture.visible, "E208 back lid texture missing!")
		insp.queue_free()
		print("✔ [11] InspectView visual textures verified for Case 1 and Case 2 (E01 & E208 front/back).")
		passed += 1

	# Reset locale to default Turkish
	if loc_mgr:
		loc_mgr.set_locale("tr")

	print("\n=== RESULTS: %d/%d TESTS PASSED ===" % [passed, total])
	if passed == total:
		print(">>> ALL LOCALIZATION & CASE ENDING TESTS PASSED! <<<\n")
	else:
		printerr(">>> SOME TESTS FAILED! <<<\n")
	get_tree().quit()
