extends Node2D

func _ready() -> void:
	print("\n=======================================================")
	print(">>> RUNNING PORTRAIT & DIALOGUE VERIFICATION TESTS <<<")
	print("=======================================================\n")

	var tests_passed = 0
	var total_tests = 0

	# 1. Test AssetManager portrait loading
	print("--- TEST SUITE 1: ASSET MANAGER PORTRAITS ---")
	var manifest_portraits = ["portrait_silas", "portrait_hale", "portrait_margaret", "portrait_julian", "portrait_pike"]
	for p_id in manifest_portraits:
		total_tests += 1
		var tex = AssetManager.get_texture(p_id)
		if tex != null and tex.get_width() >= 48 and tex.get_height() >= 48:
			print("✔ PASS: %s loaded (%dx%d)" % [p_id, tex.get_width(), tex.get_height()])
			tests_passed += 1
		else:
			print("❌ FAIL: %s failed to load or wrong size: %s" % [p_id, str(tex)])

	# 2. Test DialogueBox
	print("\n--- TEST SUITE 2: DIALOGUE BOX PORTRAITS ---")
	var dbox_scene = load("res://scenes/ui/dialogue_box.tscn")
	var dbox = dbox_scene.instantiate()
	add_child(dbox)

	var dbox_speakers = [
		{"name": "Dr. Victor Hale", "expected_visible": true},
		{"name": "Margaret Doyle", "expected_visible": true},
		{"name": "Julian Harlow", "expected_visible": true},
		{"name": "Raymond Pike", "expected_visible": true},
		{"name": "Silas Crowe", "expected_visible": true},
		{"name": "???", "expected_visible": true},
		{"name": "Kaptan Vance", "expected_visible": true},
		{"name": "Sean Morris", "expected_visible": true},
		{"name": "İhtiyar Boris", "expected_visible": true},
		{"name": "SYSTEM", "expected_visible": false}
	]

	for spk in dbox_speakers:
		total_tests += 1
		dbox.set_dialogue(spk["name"], "Konusma metni...")
		var p_tex = dbox.portrait_texture.texture
		var p_vis = dbox.portrait_container.visible
		if spk["expected_visible"]:
			if p_vis and p_tex != null and p_tex.get_width() > 0:
				print("✔ PASS: DialogueBox [%s] shows portrait %dx%d" % [spk["name"], p_tex.get_width(), p_tex.get_height()])
				tests_passed += 1
			else:
				print("❌ FAIL: DialogueBox [%s] missing portrait (vis=%s, tex=%s)" % [spk["name"], p_vis, str(p_tex)])
		else:
			if not p_vis:
				print("✔ PASS: DialogueBox [%s] correctly hides portrait" % spk["name"])
				tests_passed += 1
			else:
				print("❌ FAIL: DialogueBox [%s] should hide portrait" % spk["name"])

	# 3. Test Interrogation Interface
	print("\n--- TEST SUITE 3: INTERROGATION MODAL PORTRAITS ---")
	var interr_scene = load("res://scenes/ui/interrogation.tscn")
	var interr = interr_scene.instantiate()
	add_child(interr)

	GameState.current_case_id = "case01"
	var case01_suspects = ["hale", "margaret", "julian", "pike"]
	for s_id in case01_suspects:
		total_tests += 1
		interr.open_interrogation(s_id)
		var p_tex = interr.portrait_texture.texture
		if p_tex != null and p_tex.get_width() >= 48 and p_tex.get_height() >= 48:
			print("✔ PASS: Case 1 Interrogation [%s] portrait loaded %dx%d" % [s_id, p_tex.get_width(), p_tex.get_height()])
			tests_passed += 1
		else:
			print("❌ FAIL: Case 1 Interrogation [%s] portrait failed: %s" % [s_id, str(p_tex)])

	GameState.current_case_id = "case02"
	var case02_suspects = ["vance", "morris", "boris", "brandt", "corley"]
	for s_id in case02_suspects:
		total_tests += 1
		interr.open_interrogation(s_id)
		var p_tex = interr.portrait_texture.texture
		if p_tex != null and p_tex.get_width() >= 48 and p_tex.get_height() >= 48:
			print("✔ PASS: Case 2 Interrogation [%s] portrait loaded %dx%d" % [s_id, p_tex.get_width(), p_tex.get_height()])
			tests_passed += 1
		else:
			print("❌ FAIL: Case 2 Interrogation [%s] portrait failed: %s" % [s_id, str(p_tex)])

	print("\n=======================================================")
	print("TEST RESULTS: %d / %d TESTS PASSED!" % [tests_passed, total_tests])
	print("=======================================================\n")

	if tests_passed == total_tests:
		print(">>> ALL PORTRAIT TESTS PASSED SUCCESSFULLY! <<<")
	else:
		print(">>> SOME TESTS FAILED! <<<")

	get_tree().quit(0 if tests_passed == total_tests else 1)
