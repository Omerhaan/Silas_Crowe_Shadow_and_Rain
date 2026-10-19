extends Node

## Comprehensive Verification Test for Case Transitions and Office Door Flow.

var passed: int = 0
var total: int = 0

func assert_test(cond: bool, msg: String) -> void:
	total += 1
	if cond:
		passed += 1
		print("✔ [%d] %s" % [total, msg])
	else:
		printerr("❌ [%d] FAILED: %s" % [total, msg])

func _ready() -> void:
	print("\n=======================================================")
	print("       CASE TRANSITIONS & OFFICE DOOR FLOW TEST        ")
	print("=======================================================")

	# 1. EventBus Signal Verification
	assert_test(EventBus.has_signal("case_continue_requested"), "EventBus has case_continue_requested signal")

	# 2. CaseEndingModal NextCaseBtn Verification across Case 1, 2, 3
	var modal_scene = load("res://scenes/ui/case_ending_modal.tscn")
	assert_test(modal_scene != null, "case_ending_modal.tscn is loadable")
	var modal = modal_scene.instantiate()
	add_child(modal)

	# Case 1 Ending
	GameState.current_case_id = "case01"
	modal.start_ending_sequence()
	modal._show_stage(3)
	assert_test(modal.next_case_btn != null, "NextCaseBtn exists in CreditsPanel")
	assert_test("Bölüm 2'ye Devam Et" in modal.next_case_btn.text or "Chapter 2" in modal.next_case_btn.text, "Case 1 Credits displays Chapter 2 button")

	var signal_received_case = [""]
	var on_continue_requested = func(next_id): signal_received_case[0] = next_id
	EventBus.case_continue_requested.connect(on_continue_requested)

	modal._on_next_case_pressed()
	assert_test(signal_received_case[0] == "case02", "Case 1 NextCaseBtn emits case_continue_requested('case02')")

	# Case 2 Ending
	signal_received_case[0] = ""
	GameState.current_case_id = "case02"
	modal.start_ending_sequence()
	modal._show_stage(3)
	assert_test("Bölüm 3'e Devam Et" in modal.next_case_btn.text or "Chapter 3" in modal.next_case_btn.text, "Case 2 Credits displays Chapter 3 button")

	modal._on_next_case_pressed()
	assert_test(signal_received_case[0] == "case03", "Case 2 NextCaseBtn emits case_continue_requested('case03')")

	# Case 3 Ending
	GameState.current_case_id = "case03"
	modal.start_ending_sequence()
	modal._show_stage(3)
	assert_test("1. Sezon Tamamlandı" in modal.next_case_btn.text or "Season 1 Complete" in modal.next_case_btn.text, "Case 3 Credits displays Season 1 Complete button")

	modal.queue_free()

	# 3. Silas Office Door Flow Verification
	var office_scene = load("res://scenes/hub/silas_office.tscn")
	assert_test(office_scene != null, "silas_office.tscn is loadable")
	var office = office_scene.instantiate()
	add_child(office)

	# Post-Case 1: Door exits to Case 2
	signal_received_case[0] = ""
	GameState.completed_cases = ["case01"]
	GameState.current_case_id = "case01"
	GameState.case_solved = true
	var inner_voice_received = [""]
	var on_inner_voice = func(text): inner_voice_received[0] = text
	EventBus.inner_voice_requested.connect(on_inner_voice)

	office.on_door_interacted()
	assert_test(signal_received_case[0] == "case02", "Office door transitions to Case 2 when Case 1 is solved")
	assert_test("rıhtım" in inner_voice_received[0], "Silas monologue mentions docks when leaving for Case 2")

	# Post-Case 2: Door exits to Case 3
	signal_received_case[0] = ""
	inner_voice_received[0] = ""
	GameState.completed_cases = ["case01", "case02"]
	GameState.current_case_id = "case02"
	GameState.case_solved = true

	office.on_door_interacted()
	assert_test(signal_received_case[0] == "case03", "Office door transitions to Case 3 when Case 2 is solved")
	assert_test("Opera" in inner_voice_received[0], "Silas monologue mentions Royal Opera when leaving for Case 3")

	# Post-Case 3: Season 1 Complete
	signal_received_case[0] = ""
	inner_voice_received[0] = ""
	GameState.completed_cases = ["case01", "case02", "case03"]
	GameState.current_case_id = "case03"
	GameState.case_solved = true

	office.on_door_interacted()
	assert_test(signal_received_case[0] == "", "Office door does not advance beyond Case 3")
	assert_test("1. Sezon" in inner_voice_received[0], "Silas monologue declares Season 1 complete")

	office.queue_free()

	# Reset state
	GameState.switch_case("case01")

	print("\n=======================================================")
	print("       RESULT: %d / %d TESTS PASSED                    " % [passed, total])
	print("=======================================================\n")

	get_tree().quit(0 if passed == total else 1)
