extends Node2D

func _ready() -> void:
	print("\n=======================================================")
	print(">>> RUNNING COMPREHENSIVE CASE 1 & CASE 2 INTERACTION TESTS <<<")
	print("=======================================================\n")
	
	var main_scene = load("res://scenes/main.tscn")
	var main = main_scene.instantiate()
	add_child(main)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	var player = main.player
	var im = get_node_or_null("/root/InputManager")
	var hud = main.hud
	
	assert(player != null, "Player must exist")
	assert(im != null, "InputManager must exist")
	
	var passed_tests = 0
	var total_tests = 0
	
	# =========================================================
	# TEST SUITE 1: CASE 1 (Karanlık Malikâne)
	# =========================================================
	print("\n--- [TEST SUITE 1: CASE 1] ---")
	main._on_case_selected("case01")
	await get_tree().create_timer(0.5).timeout
	
	# Test 1.1: Library (Dr. Hale vs Fireplace E10)
	print("\n[Case 1] Testing Room: library")
	main.load_room("library", "default")
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	var lib_room = main.current_room_node
	var dr_hale = lib_room.find_child("NPC_Hale", true, false)
	if not dr_hale:
		for c in lib_room.get_children():
			if c.is_in_group("npcs") or "hale" in str(c.get("object_id")).to_lower():
				dr_hale = c
				break
	
	var flacon = lib_room.find_child("Evidence_E09", true, false)
	if not flacon:
		for c in lib_room.get_children():
			if c.get("evidence_id") in ["E09", "E10"]:
				flacon = c
				break
				
	print("Dr. Hale found: ", dr_hale != null, " | Flacon E11 found: ", flacon != null)
	if dr_hale:
		total_tests += 1
		player.global_position = Vector2(dr_hale.global_position.x, 245.0)
		player.reset_interaction_state()
		await get_tree().physics_frame
		await get_tree().physics_frame
		player._update_current_interactable()
		var cur = player.current_interactable
		var is_cur_hale = (cur == dr_hale) or (cur and ("hale" in cur.name.to_lower() or "hale" in str(cur.get("object_id")).to_lower()))
		print("  Standing at Dr. Hale -> current_interactable: ", cur.name if cur else "NULL", " (Expect Hale)")
		if is_cur_hale:
			passed_tests += 1
			print("  ✔ PASS: Player near Dr. Hale targets Dr. Hale")
		else:
			push_error("  FAIL: Player near Dr. Hale targeted " + (cur.name if cur else "NULL"))
	
	if flacon:
		total_tests += 1
		player.global_position = Vector2(flacon.global_position.x, 245.0)
		player.reset_interaction_state()
		await get_tree().physics_frame
		await get_tree().physics_frame
		player._update_current_interactable()
		var cur = player.current_interactable
		print("  Standing at E09/E10 -> current_interactable: ", cur.name if cur else "NULL", " (Expect Flacon or Fireplace)")
		if cur and cur.get("evidence_id") in ["E09", "E10"]:
			passed_tests += 1
			print("  ✔ PASS: Player near E09/E10 targets clue")
		else:
			push_error("  FAIL: Player near E09/E10 targeted " + (cur.name if cur else "NULL"))

	# Test 1.2: Study (Harlow's corpse E01, Cognac glass E02)
	print("\n[Case 1] Testing Room: study")
	main.load_room("study", "default")
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	var study_room = main.current_room_node
	var e01 = study_room.find_child("Evidence_E01", true, false)
	if not e01:
		for c in study_room.get_children():
			if c.get("evidence_id") == "E01":
				e01 = c
				break
	if e01:
		total_tests += 1
		player.global_position = Vector2(e01.global_position.x, 245.0)
		player.reset_interaction_state()
		await get_tree().physics_frame
		await get_tree().physics_frame
		player._update_current_interactable()
		var cur = player.current_interactable
		print("  Standing at E01 -> current_interactable: ", cur.name if cur else "NULL", " (Expect E01)")
		if cur == e01:
			passed_tests += 1
			print("  ✔ PASS: Player near E01 targets Harlow Body E01")
		else:
			push_error("  FAIL: Player near E01 targeted " + (cur.name if cur else "NULL"))
	
	# =========================================================
	# TEST SUITE 2: CASE 2 (Sisli Liman)
	# =========================================================
	print("\n--- [TEST SUITE 2: CASE 2] ---")
	main._on_case_selected("case02")
	await get_tree().create_timer(0.5).timeout
	
	# Test 2.1: dock_office (Morris vs Tide Chart E206 & Night Pass E209)
	print("\n[Case 2] Testing Room: dock_office")
	main.load_room("dock_office", "default")
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	var office_room = main.current_room_node
	var morris = office_room.find_child("NPC_Morris", true, false)
	var e206 = office_room.find_child("Evidence_E206", true, false)
	var e209 = office_room.find_child("Evidence_E209", true, false)
	
	assert(morris != null and e206 != null and e209 != null)
	
	# 2.1.a: Stand at Morris (X=175) -> Target Morris
	total_tests += 1
	player.global_position = Vector2(morris.global_position.x, 245.0)
	player.reset_interaction_state()
	await get_tree().physics_frame
	await get_tree().physics_frame
	player._update_current_interactable()
	print("  Standing at Morris (X=175) -> current_interactable: ", player.current_interactable.name if player.current_interactable else "NULL")
	if player.current_interactable == morris:
		passed_tests += 1
		print("  ✔ PASS: Morris selected when standing at Morris")
	else:
		push_error("  FAIL: Expected Morris, got: " + (player.current_interactable.name if player.current_interactable else "NULL"))
	
	# 2.1.b: Stand at E206 Tide Chart (X=195) -> Target E206 even though Morris is at 175 (20px away!)
	total_tests += 1
	player.global_position = Vector2(e206.global_position.x, 245.0)
	player.reset_interaction_state()
	await get_tree().physics_frame
	await get_tree().physics_frame
	player._update_current_interactable()
	print("  Standing at E206 (X=195) -> current_interactable: ", player.current_interactable.name if player.current_interactable else "NULL")
	if player.current_interactable == e206:
		passed_tests += 1
		print("  ✔ PASS: E206 selected over nearby Morris (20px away)")
	else:
		push_error("  FAIL: Expected E206, got: " + (player.current_interactable.name if player.current_interactable else "NULL"))

	# 2.1.c: Stand at E209 Night Pass (X=285) -> Target E209
	total_tests += 1
	player.global_position = Vector2(e209.global_position.x, 245.0)
	player.reset_interaction_state()
	await get_tree().physics_frame
	await get_tree().physics_frame
	player._update_current_interactable()
	print("  Standing at E209 (X=285) -> current_interactable: ", player.current_interactable.name if player.current_interactable else "NULL")
	if player.current_interactable == e209:
		passed_tests += 1
		print("  ✔ PASS: E209 selected")
	else:
		push_error("  FAIL: Expected E209, got: " + (player.current_interactable.name if player.current_interactable else "NULL"))

	# Test 2.2: captain_cabin (Vance vs Logbook E211 & Note E207)
	print("\n[Case 2] Testing Room: captain_cabin")
	main.load_room("captain_cabin", "default")
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	var cabin_room = main.current_room_node
	var vance = cabin_room.find_child("NPC_Vance", true, false)
	var e211 = cabin_room.find_child("Evidence_E211", true, false)
	var e207 = cabin_room.find_child("Evidence_E207", true, false)
	var e204 = cabin_room.find_child("Evidence_E204", true, false)
	
	print("  cabin_room: ", cabin_room.name if cabin_room else "NULL")
	print("  vance: ", vance != null, " e211: ", e211 != null, " e207: ", e207 != null, " e204: ", e204 != null)
	if not vance or not e211:
		for c in cabin_room.get_children():
			print("    cabin child: ", c.name, " type: ", c.get_class(), " evid: ", c.get("evidence_id"))
	
	# Stand at E211 (X=280) vs Vance (X=275 - 5px away!)
	total_tests += 1
	player.global_position = Vector2(e211.global_position.x, 245.0)
	player.reset_interaction_state()
	await get_tree().physics_frame
	await get_tree().physics_frame
	player._update_current_interactable()
	print("  Overlapping areas at E211: ", player.interaction_area.get_overlapping_areas().map(func(a): return a.get_parent().name if a.get_parent() else a.name))
	print("  nearby_interactables at E211: ", player.nearby_interactables.map(func(n): return n.name))
	print("  Standing at E211 (X=280) -> current_interactable: ", player.current_interactable.name if player.current_interactable else "NULL")
	if player.current_interactable == e211:
		passed_tests += 1
		print("  ✔ PASS: E211 selected over Vance (5px away)")
	else:
		push_error("  FAIL: Expected E211, got: " + (player.current_interactable.name if player.current_interactable else "NULL"))

	# Stand at E207 (X=310) -> Target E207
	total_tests += 1
	player.global_position = Vector2(e207.global_position.x, 245.0)
	player.reset_interaction_state()
	await get_tree().physics_frame
	await get_tree().physics_frame
	player._update_current_interactable()
	print("  Overlapping areas at E207: ", player.interaction_area.get_overlapping_areas().map(func(a): return a.get_parent().name if a.get_parent() else a.name))
	print("  nearby_interactables at E207: ", player.nearby_interactables.map(func(n): return n.name))
	print("  Standing at E207 (X=310) -> current_interactable: ", player.current_interactable.name if player.current_interactable else "NULL")
	if player.current_interactable == e207:
		passed_tests += 1
		print("  ✔ PASS: E207 selected")
	else:
		push_error("  FAIL: Expected E207, got: " + (player.current_interactable.name if player.current_interactable else "NULL"))

	# Test 2.3: dock_warehouse (Brandt vs Radio Desk E205)
	print("\n[Case 2] Testing Room: dock_warehouse")
	main.load_room("dock_warehouse", "default")
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	var wh_room = main.current_room_node
	var brandt = wh_room.find_child("NPC_Brandt", true, false)
	var e205 = wh_room.find_child("Evidence_E205", true, false)
	
	assert(brandt != null and e205 != null)
	
	# Stand at E205 (X=115) vs Brandt (X=150 - 35px away)
	total_tests += 1
	player.global_position = Vector2(e205.global_position.x, 245.0)
	player.reset_interaction_state()
	await get_tree().physics_frame
	await get_tree().physics_frame
	player._update_current_interactable()
	print("  Standing at E205 (X=115) -> current_interactable: ", player.current_interactable.name if player.current_interactable else "NULL")
	if player.current_interactable == e205:
		passed_tests += 1
		print("  ✔ PASS: E205 selected over Brandt (35px away)")
	else:
		push_error("  FAIL: Expected E205, got: " + (player.current_interactable.name if player.current_interactable else "NULL"))

	# Test 2.4: dock_pier (Teddy Marsh corpse E208, Bloody Lantern E203)
	print("\n[Case 2] Testing Room: dock_pier")
	main.load_room("dock_pier", "default")
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	var pier_room = main.current_room_node
	var e208 = pier_room.find_child("Evidence_E208", true, false)
	var e203 = pier_room.find_child("Evidence_E203", true, false)
	
	assert(e208 != null and e203 != null)
	
	total_tests += 1
	player.global_position = Vector2(e208.global_position.x, 245.0)
	player.reset_interaction_state()
	await get_tree().physics_frame
	await get_tree().physics_frame
	player._update_current_interactable()
	print("  Standing at E208 (X=310) -> current_interactable: ", player.current_interactable.name if player.current_interactable else "NULL")
	if player.current_interactable == e208:
		passed_tests += 1
		print("  ✔ PASS: E208 Marsh corpse selected")
	else:
		push_error("  FAIL: Expected E208, got: " + (player.current_interactable.name if player.current_interactable else "NULL"))

	# Test 2.5: Touch/Tap interaction test
	print("\n--- [TEST SUITE 3: TOUCH / TAP INTERACTION] ---")
	total_tests += 1
	player.reset_interaction_state()
	player.global_position = Vector2(100.0, 245.0) # Far from E208 (at 310)
	await get_tree().physics_frame
	
	print("  Simulating tap on E208 at X=310 while player is at X=100...")
	im.request_interact_with(e208)
	await get_tree().process_frame
	print("  Player navigating to target: ", player.is_navigating, " target_x: ", player.nav_target.x)
	
	# Simulate walk frames until reached
	for f in range(120):
		await get_tree().physics_frame
		if not player.is_navigating:
			break
	
	print("  After walking: player_x: %.1f, is_navigating: %s, pending_target: %s" % [player.global_position.x, player.is_navigating, player.pending_interact_target])
	var inspect_view = main.find_child("InspectView", true, false)
	var inspect_open = inspect_view and inspect_view.visible
	print("  InspectView visible after tap walk: ", inspect_open)
	if inspect_open or GameState.has_evidence("E208"):
		passed_tests += 1
		print("  ✔ PASS: Tap on E208 caused player to walk and inspect clue successfully!")
	else:
		push_error("  FAIL: Tap on E208 did not open InspectView or collect evidence!")
		
	# Test 2.6: InspectView Texture resolution for all 11 clues
	print("\n--- [TEST SUITE 4: INSPECTVIEW VISUAL TEXTURES (ALL 11 CASE 2 CLUES)] ---")
	var case2_clues = ["E201", "E202", "E203", "E204", "E205", "E206", "E207", "E208", "E209", "E210", "E211"]
	var textures_ok = 0
	for cid in case2_clues:
		total_tests += 1
		inspect_view.open_inspect(cid)
		var visual_texture = inspect_view.find_child("VisualTexture", true, false)
		var has_tex = visual_texture and visual_texture.texture != null
		var tex_name = visual_texture.texture.resource_path.get_file() if (has_tex and visual_texture.texture.resource_path != "") else "IN_MEMORY"
		print("  Clue %s: has_texture=%s (%s)" % [cid, has_tex, tex_name])
		if has_tex:
			passed_tests += 1
			textures_ok += 1
		else:
			push_error("  FAIL: Clue %s has no texture in InspectView!" % cid)
		inspect_view.close_inspect()

	print("\n=======================================================")
	print("TEST RESULTS: %d / %d TESTS PASSED!" % [passed_tests, total_tests])
	print("=======================================================\n")
	
	if passed_tests == total_tests:
		print(">>> ALL TESTS PASSED SUCCESSFULLY! <<<")
		get_tree().quit(0)
	else:
		print(">>> SOME TESTS FAILED! <<<")
		get_tree().quit(1)
