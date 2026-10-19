extends Node2D

var passed_count: int = 0
var failed_count: int = 0

func _ready() -> void:
	print("==================================================")
	print("--- TEST SUITE: 3 CRITICAL FIXES VERIFICATION ---")
	print("==================================================")

	test_issue1_elias_spoiler_masking()
	test_issue2_dynamic_counters()
	await test_issue3_accusation_marquee()

	print("==================================================")
	print("RESULTS: Passed: %d, Failed: %d" % [passed_count, failed_count])
	print("==================================================")

	if failed_count == 0:
		print(">>> ALL 3 FIXES VERIFIED SUCCESSFULLY! <<<")
	else:
		push_error(">>> SOME TESTS FAILED! <<<")

	await get_tree().create_timer(0.3).timeout
	get_tree().quit(0 if failed_count == 0 else 1)

func assert_test(cond: bool, test_name: String) -> void:
	if cond:
		passed_count += 1
		print("  ✔ [PASS] " + test_name)
	else:
		failed_count += 1
		push_error("  ✘ [FAIL] " + test_name)

func test_issue1_elias_spoiler_masking() -> void:
	print("\n--- TEST 1: Elias Spoiler Masking in Case 2 ---")
	
	# 1. Phone call cutscene
	var pc_file = FileAccess.open("res://cases/case02/data/cutscenes/phone_call.json", FileAccess.READ)
	if pc_file:
		var text = pc_file.get_as_text()
		pc_file.close()
		assert_test(not "ELIAS" in text, "phone_call.json: No ELIAS speaker found")
		assert_test(not "Elias" in text, "phone_call.json: No Elias in dialogue")
	else:
		assert_test(false, "phone_call.json file could not be read")

	# 2. Case 2 Deductions
	var ded_file = FileAccess.open("res://cases/case02/data/deductions.json", FileAccess.READ)
	if ded_file:
		var text = ded_file.get_as_text()
		ded_file.close()
		assert_test(not "Elias" in text and not "elias" in text.to_lower(), "deductions.json: No Elias in Case 2 deductions")

	# 3. Case 2 Clues & Caller Clues
	var cc_file = FileAccess.open("res://cases/case02/data/caller_clues.json", FileAccess.READ)
	if cc_file:
		var text = cc_file.get_as_text()
		cc_file.close()
		assert_test(not "Elias" in text and not "elias" in text.to_lower(), "caller_clues.json: No Elias in caller clues")

	# 4. DialogueBox runtime spoiler filter
	var dbox_scene = load("res://scenes/ui/dialogue_box.tscn")
	var dbox = dbox_scene.instantiate()
	add_child(dbox)
	dbox.set_dialogue("ELIAS", "Beni bulamazsın Silas.")
	assert_test(dbox.speaker_name_label.text == "???", "DialogueBox masks ELIAS to ???")
	dbox.set_dialogue("Elias Wren", "Oyun yeni başlıyor.")
	assert_test(dbox.speaker_name_label.text == "???", "DialogueBox masks Elias Wren to ???")
	dbox.queue_free()

func test_issue2_dynamic_counters() -> void:
	print("\n--- TEST 2: Dynamic Evidence & Deduction Counters ---")
	
	# Load Case 01
	GameState.switch_case("case01")
	assert_test(GameState.evidence_db.size() == 17, "Case 1 evidence count is 17")
	assert_test(GameState.deductions_db.size() == 10, "Case 1 deductions count is 10")

	# Load Case 02
	GameState.switch_case("case02")
	assert_test(GameState.evidence_db.size() == 11, "Case 2 evidence count is 11")
	assert_test(GameState.deductions_db.size() == 6, "Case 2 deductions count is 6")

	# Verify CaseEndingModal calculation for Case 2
	var ending_scene = load("res://scenes/ui/case_ending_modal.tscn")
	var ending_modal = ending_scene.instantiate()
	add_child(ending_modal)

	# Simulate 11 clues found and 6 deductions solved in Case 2
	GameState.discovered_evidence.clear()
	for i in range(11):
		GameState.discovered_evidence.append("E20%d" % (i + 1) if i < 9 else "E2%d" % (i + 1))
	GameState.unlocked_deductions.clear()
	for i in range(6):
		GameState.unlocked_deductions.append("D20%d" % (i + 1))
	GameState.accusation_chances_left = 3

	ending_modal._populate_rating()
	var clues_text = ending_modal.stat_clues_lbl.text
	var deds_text = ending_modal.stat_deds_lbl.text
	print("  Ending clues text: ", clues_text)
	print("  Ending deds text: ", deds_text)
	assert_test("11 / 11" in clues_text, "Case 2 Ending reports 11 / 11 clues (not / 17)")
	assert_test("6 / 6" in deds_text, "Case 2 Ending reports 6 / 6 deductions (not / 10)")
	ending_modal.queue_free()

func test_issue3_accusation_marquee() -> void:
	print("\n--- TEST 3: Accusation Modal Marquee Slider ---")
	var accus_scene = load("res://scenes/ui/accusation_modal.tscn")
	var accus_modal = accus_scene.instantiate()
	add_child(accus_modal)

	accus_modal.open_accusation()
	assert_test(accus_modal.suspect_marquee.has("label"), "Suspect marquee label created")
	assert_test(accus_modal.method_marquee.has("label"), "Method marquee label created")
	assert_test(accus_modal.suspect_marquee["btn"].text == "", "Suspect button native text is blank (handled by marquee)")
	assert_test(accus_modal.method_marquee["btn"].text == "", "Method button native text is blank (handled by marquee)")

	# Set a long method text that exceeds 144px width
	var long_method = "• Gecikmeli Zehirleme (Digitalis) - Ekstra Uzun Cinayet Yöntemi Açıklaması"
	accus_modal._set_marquee_text(accus_modal.method_marquee, long_method)
	var m_label: Label = accus_modal.method_marquee["label"]
	var m_cont: Control = accus_modal.method_marquee["container"]
	var overflow: float = m_label.get_minimum_size().x - m_cont.size.x
	print("  Method text width: %.1f, container width: %.1f, overflow: %.1f" % [m_label.get_minimum_size().x, m_cont.size.x, overflow])
	assert_test(overflow > 10.0, "Method text has significant overflow to slide")
	assert_test(m_label.position.x == 0.0, "Marquee starts at position x = 0")

	# Simulate 1.6 seconds to pass the initial pause timer (1.5s)
	accus_modal._process(1.6)
	var x_after_start = m_label.position.x
	print("  Method label pos x after 1.6s: %.2f" % x_after_start)
	assert_test(x_after_start < -1.0, "Marquee has begun sliding left (position.x < -1.0)")

	# Simulate several seconds to reach end
	for i in range(20):
		accus_modal._process(0.2)
	print("  Method label pos x after sliding: %.2f" % m_label.position.x)
	assert_test(m_label.position.x <= -10.0, "Marquee slid deep into overflowed text")

	# Test dropdown tooltip
	var test_btn = accus_modal._create_dropdown_item("Test Option With Long Description", func(): pass)
	assert_test(test_btn.tooltip_text == "Test Option With Long Description", "Dropdown button has tooltip_text")
	test_btn.queue_free()

	accus_modal.queue_free()
