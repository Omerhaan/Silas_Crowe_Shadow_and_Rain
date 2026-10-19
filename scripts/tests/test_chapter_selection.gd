extends Node

## Automated test suite for Main Menu Chapter Selection and Case Progression.

func _ready() -> void:
	print("\n=== RUNNING CHAPTER SELECTION & PROGRESSION TEST ===")
	var passed = 0
	var total = 0

	# 1. MainMenu and CaseSelectModal presence
	total += 1
	var menu_scene = load("res://scenes/ui/main_menu.tscn")
	if menu_scene:
		var menu_inst = menu_scene.instantiate()
		add_child(menu_inst)
		var chap_btn = menu_inst.find_child("ChapterSelectBtn", true, false)
		var modal = menu_inst.find_child("CaseSelectModal", true, false)
		if chap_btn != null and modal != null:
			print("✔ [1] MainMenu contains ChapterSelectBtn and CaseSelectModal.")
			passed += 1
		else:
			printerr("❌ [1] Missing ChapterSelectBtn or CaseSelectModal in MainMenu!")
		menu_inst.queue_free()
	else:
		printerr("❌ [1] Failed to load main_menu.tscn")

	# 2. Case Registry initial state: Case 1 unlocked, Case 2 locked
	total += 1
	GameState.load_case_registry()
	GameState.completed_cases.clear()
	var c1 = _find_case("case01")
	var c2 = _find_case("case02")
	if c1.get("unlocked", false) == true and c2.get("unlocked", false) == false:
		print("✔ [2] Initial case registry: Case 1 is unlocked, Case 2 is locked.")
		passed += 1
	else:
		printerr("❌ [2] Initial case state unexpected: c1=%s, c2=%s" % [c1, c2])

	# 3. CaseSelectModal displays correct locked/unlocked button states initially
	total += 1
	var modal_scene = load("res://scenes/ui/case_select_modal.tscn")
	var modal_inst = modal_scene.instantiate()
	add_child(modal_inst)
	modal_inst.open_modal()
	if modal_inst.card1_btn.disabled == false and modal_inst.card2_btn.disabled == true and modal_inst.card3_btn.disabled == true:
		print("✔ [3] CaseSelectModal initial state: Card 1 enabled, Card 2 & 3 disabled.")
		passed += 1
	else:
		printerr("❌ [3] CaseSelectModal button states incorrect: card1=%s, card2=%s, card3=%s" % [
			modal_inst.card1_btn.disabled, modal_inst.card2_btn.disabled, modal_inst.card3_btn.disabled
		])

	# 4. Complete Case 1 and verify Case 2 unlocks automatically
	total += 1
	GameState.current_case_id = "case01"
	GameState.complete_current_case()
	var c1_after = _find_case("case01")
	var c2_after = _find_case("case02")
	if c1_after.get("completed", false) == true and c2_after.get("unlocked", false) == true:
		print("✔ [4] Case 1 completion automatically unlocks Case 2 in registry.")
		passed += 1
	else:
		printerr("❌ [4] Case 2 failed to unlock after Case 1 completed: c1=%s, c2=%s" % [c1_after, c2_after])

	# 5. CaseSelectModal updates to show Case 1 completed and Case 2 unlocked
	total += 1
	modal_inst._refresh_cards()
	if modal_inst.card1_btn.disabled == false and modal_inst.card2_btn.disabled == false and modal_inst.card3_btn.disabled == true:
		print("✔ [5] CaseSelectModal reflects progression: Card 1 and Card 2 are both playable, Card 3 remains locked.")
		passed += 1
	else:
		printerr("❌ [5] CaseSelectModal cards failed to update: card1=%s, card2=%s, card3=%s" % [
			modal_inst.card1_btn.disabled, modal_inst.card2_btn.disabled, modal_inst.card3_btn.disabled
		])

	# 6. Switch to Case 2 and verify dock_warehouse room loads
	total += 1
	var switch_ok = GameState.switch_case("case02")
	var warehouse_scene = load("res://scenes/rooms/dock_warehouse.tscn")
	if switch_ok and GameState.current_case_id == "case02" and warehouse_scene != null:
		var warehouse_inst = warehouse_scene.instantiate()
		add_child(warehouse_inst)
		var cable = warehouse_inst.find_child("Evidence_E201", true, false)
		if cable != null:
			print("✔ [6] Chapter 2 switch successful: loaded dock_warehouse with clue E201.")
			passed += 1
		else:
			printerr("❌ [6] Missing Evidence_E201 in dock_warehouse!")
		warehouse_inst.queue_free()
	else:
		printerr("❌ [6] Chapter 2 switch failed: switch_ok=%s, warehouse_scene=%s" % [switch_ok, warehouse_scene])

	# 7. Localization check for Chapter Select
	total += 1
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	if loc_mgr:
		loc_mgr.set_locale("tr")
		var tr_title = tr("UI_CHAPTER_SELECT")
		loc_mgr.set_locale("en")
		var en_title = tr("UI_CHAPTER_SELECT")
		loc_mgr.set_locale("tr")
		if tr_title == "Bölüm Seçimi" and en_title == "Chapter Select":
			print("✔ [7] Localization for Chapter Selection verified (TR: '%s', EN: '%s')." % [tr_title, en_title])
			passed += 1
		else:
			printerr("❌ [7] Localization mismatch: TR='%s', EN='%s'" % [tr_title, en_title])
	else:
		printerr("❌ [7] LocalizationManager not found!")

	modal_inst.queue_free()

	print("\n==========================================")
	print("CHAPTER SELECTION TEST RESULTS: %d / %d PASSED" % [passed, total])
	print("==========================================\n")

	if passed == total:
		print("ALL CHAPTER SELECTION TESTS PASSED SUCCESSFULLY!")
	else:
		printerr("SOME CHAPTER SELECTION TESTS FAILED!")

func _find_case(case_id: String) -> Dictionary:
	for c in GameState.case_registry:
		if c is Dictionary and c.get("id", "") == case_id:
			return c
	return {}
