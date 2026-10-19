extends Node

func _ready() -> void:
	print("\n=======================================================")
	print(">>> AUDITING CASE 1 -> 2 -> 3 TRANSITIONS & DEVAM FLOW <<<")
	print("=======================================================\n")

	# Step 1: Initial state
	GameState.load_case_registry()
	GameState.completed_cases.clear()
	print("[1] Initial Case ID:", GameState.current_case_id)
	print("    Completed cases:", GameState.completed_cases)
	
	# Step 2: Complete Case 1
	GameState.current_case_id = "case01"
	GameState.complete_current_case()
	print("\n[2] After Case 1 Completion:")
	print("    Completed cases:", GameState.completed_cases)
	var c2_unlocked = false
	for c in GameState.case_registry:
		if c.get("id") == "case02":
			c2_unlocked = c.get("unlocked", false)
	print("    Case 2 Unlocked in Registry:", c2_unlocked)

	# Check what happens in case_ending_modal
	var ending_scene = load("res://scenes/ui/case_ending_modal.tscn")
	var ending_inst = ending_scene.instantiate()
	add_child(ending_inst)
	print("    CaseEndingModal buttons present on Credits panel:")
	print("      return_office_btn:", ending_inst.return_office_btn != null, "text:", ending_inst.return_office_btn.text if ending_inst.return_office_btn else "")
	print("      main_menu_btn:", ending_inst.main_menu_btn != null, "text:", ending_inst.main_menu_btn.text if ending_inst.main_menu_btn else "")
	print("      next_case_btn (direct Continue to next case):", ending_inst.find_child("NextCaseBtn", true, false) != null)

	# Check what happens in silas_office after Case 1
	var office_scene = load("res://scenes/hub/silas_office.tscn")
	var office_inst = office_scene.instantiate()
	add_child(office_inst)
	print("\n[3] In silas_office after Case 1 solved:")
	print("    current_state:", office_inst.current_state)
	print("    phone_ring_timer running:", not office_inst.phone_ring_timer.is_stopped())
	print("    door interaction message when interacted:")
	office_inst.on_door_interacted()

	# Check what happens after second_call
	var second_call_scene = load("res://scenes/cutscenes/second_call.tscn")
	var second_call_inst = second_call_scene.instantiate()
	add_child(second_call_inst)
	print("\n[4] second_call cutscene:")
	print("    continue_btn text:", second_call_inst.continue_btn.text)
	
	# Step 3: Complete Case 2 and check Case 3 transition
	GameState.current_case_id = "case02"
	GameState.complete_current_case()
	print("\n[5] After Case 2 Completion:")
	print("    Completed cases:", GameState.completed_cases)
	var c3_unlocked = false
	for c in GameState.case_registry:
		if c.get("id") == "case03":
			c3_unlocked = c.get("unlocked", false)
	print("    Case 3 Unlocked in Registry:", c3_unlocked)

	# Check what happens in silas_office after Case 2
	var office_inst2 = office_scene.instantiate()
	add_child(office_inst2)
	print("\n[6] In silas_office after Case 2 solved:")
	print("    GameState.flags['second_call_done']:", GameState.flags.get("second_call_done", false))
	print("    phone_ring_timer running for Case 3 call?:", not office_inst2.phone_ring_timer.is_stopped())
	office_inst2.on_door_interacted()

	# Step 4: Check Main Menu CaseSelectModal
	var modal_scene = load("res://scenes/ui/case_select_modal.tscn")
	var modal_inst = modal_scene.instantiate()
	add_child(modal_inst)
	modal_inst.open_modal()
	print("\n[7] CaseSelectModal Cards status:")
	print("    Card 1 disabled?:", modal_inst.card1_btn.disabled, "text:", modal_inst.card1_btn.text)
	print("    Card 2 disabled?:", modal_inst.card2_btn.disabled, "text:", modal_inst.card2_btn.text)
	print("    Card 3 disabled?:", modal_inst.card3_btn.disabled, "text:", modal_inst.card3_btn.text)

	print("\n=======================================================")
	print("AUDIT COMPLETE")
	print("=======================================================\n")
	get_tree().quit(0)
