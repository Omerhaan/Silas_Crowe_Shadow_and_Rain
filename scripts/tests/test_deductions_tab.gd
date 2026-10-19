extends Node

func _ready() -> void:
	print("\n========================================================")
	print(" RUNNING DEDUCTIONS TAB ENHANCEMENT TEST SUITE ")
	print("========================================================\n")

	GameState.discovered_evidence.clear()
	GameState.unlocked_deductions.clear()

	var nb_res = load("res://scenes/ui/notebook.tscn")
	var nb = nb_res.instantiate()
	add_child(nb)

	# 1. Add some evidence
	GameState.add_evidence("E02") # Kilitteki Anahtar
	GameState.add_evidence("E15") # Çamurlu Ayak İzi
	GameState.add_evidence("E04") # Konyak Kadehi

	nb.open_notebook()
	nb.tab_container.current_tab = 3 # Çıkarımlar
	nb._refresh_deductions_tab()

	print("--- 1. TESTING CLUE CARD DISPLAY AND NAMES ---")
	var clue_btns = nb.deduction_clues_container.get_children()
	assert(clue_btns.size() == 3, "3 clue buttons generated")
	print("PASS: Generated %d clue buttons with names" % clue_btns.size())
	for btn in clue_btns:
		print("  Button text: '" + btn.text + "'")
		assert("[" in btn.text and "]" in btn.text, "Button displays bracketed ID and name")

	print("\n--- 2. TESTING SLOT SELECTION AND DESELECTION ---")
	nb._select_clue_for_slot("E02")
	assert(nb.selected_clue_1 == "E02", "E02 placed in Slot 1")
	assert("E02" in nb.slot1_btn.text, "Slot 1 button displays E02")
	assert("Kilit" in nb.slot1_btn.text, "Slot 1 button displays clue name")
	print("PASS: Slot 1 formatted text: " + nb.slot1_btn.text)

	nb._select_clue_for_slot("E15")
	assert(nb.selected_clue_2 == "E15", "E15 placed in Slot 2")
	print("PASS: Slot 2 formatted text: " + nb.slot2_btn.text)
	assert(nb.combine_btn.disabled == false, "Combine button is enabled when both slots filled")

	# Deselect slot 2 by clicking again
	nb._select_clue_for_slot("E15")
	assert(nb.selected_clue_2 == "", "Clicking selected clue deselects it")
	print("PASS: Toggle deselect verified for slot 2")

	# Reselect E15
	nb._select_clue_for_slot("E15")
	assert(nb.selected_clue_2 == "E15", "Reselected E15")

	print("\n--- 3. TESTING DEDUCTION COMBINE (E02 + E15 -> D1) ---")
	nb._on_combine_pressed()
	assert("D1" in GameState.unlocked_deductions, "D1 unlocked successfully")
	print("PASS: Deduction D1 successfully unlocked!")
	assert(nb.selected_clue_1 == "" and nb.selected_clue_2 == "", "Slots cleared after successful deduction")

	print("\n--- 4. TESTING UNLOCKED DEDUCTION CARD FORMAT ---")
	var unlocked_items = nb.unlocked_deductions_container.get_children()
	assert(unlocked_items.size() == 1, "1 unlocked deduction card shown")
	var card = unlocked_items[0]
	assert(card is PanelContainer, "Deduction item rendered in styled PanelContainer")
	print("PASS: Unlocked deduction displayed in styled card panel")

	print("\n========================================================")
	print(" ALL DEDUCTIONS TAB TESTS PASSED (100%)! ")
	print("========================================================\n")

	nb.queue_free()
	get_tree().quit(0)
