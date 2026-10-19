extends Node

## Automated test for:
## 1. Return to Main Menu from Pause Menu (does not quit game, returns to title screen)
## 2. Chapter Selection Sequence (Office -> Phone Ring -> Conversation -> Cinematic -> Crime Scene)

func _ready() -> void:
	print("\n==================================================")
	print("--- TEST: MENU RETURN & CASE SELECTION FLOW ---")
	print("==================================================")

	var main_scene = load("res://scenes/main.tscn").instantiate()
	add_child(main_scene)

	# Wait a bit for _ready
	await get_tree().create_timer(0.1).timeout

	var main_menu = main_scene.get_node("UIOverlays/MainMenu")
	var pause_menu = main_scene.get_node("UIOverlays/PauseMenu")
	var hud = main_scene.get_node("HUD")

	# TEST 1: Initial state is Main Menu open
	assert(main_menu.visible == true, "Main menu should be visible initially")
	assert(hud.visible == false, "HUD should be hidden initially")
	print("  [1] Initial Main Menu state: OK")

	# TEST 2: Start Case 1 via chapter selection
	main_scene._on_case_selected("case01")
	await get_tree().create_timer(0.1).timeout

	assert(main_scene.current_room_node != null, "Current room must be instantiated")
	assert(main_scene.current_room_node.name == "SilasOffice", "Must start in SilasOffice, was: %s" % main_scene.current_room_node.name)
	assert(hud.visible == true, "HUD must be visible in office")
	print("  [2] Case 01 Chapter Select loads SilasOffice: OK")

	# Verify phone answers and starts phone call dialogue
	main_scene.current_room_node.answer_phone()
	assert(main_scene.phone_call_dialogue.visible == true, "Phone call dialogue must open on phone answer")
	assert(main_scene.phone_call_dialogue.call_data.get("dialogue_id") == "prologue_phone_call" or main_scene.phone_call_dialogue.call_data.get("dialogue_id") == "case01_phone_call", "Case 01 phone dialogue loaded")
	print("  [3] Case 01 Phone call dialogue triggered: OK")

	# Finish phone call -> must launch travel cutscene
	main_scene.phone_call_dialogue.finish_call()
	await get_tree().create_timer(0.35).timeout
	assert(main_scene.story_cutscene.visible == true, "Travel cutscene must be playing after phone call")
	print("  [4] Travel cutscene launched after phone call: OK")

	# Finish travel cutscene -> Case 1 triggers arrival dialogue -> then main_hall
	main_scene.story_cutscene.finish()
	await get_tree().create_timer(0.2).timeout
	main_scene.arrival_dialogue.finish()
	await get_tree().create_timer(0.35).timeout
	assert(GameState.current_room_id == "main_hall", "Must arrive at main_hall crime scene, was: %s" % GameState.current_room_id)
	print("  [5] Case 01 Full Sequence (Office -> Phone -> Travel -> Arrival -> MainHall): OK")

	# TEST 3: Pause Menu "Ana Menüye Dön" (Return to Menu)
	pause_menu.open_menu()
	assert(pause_menu.visible == true, "Pause menu must be open")
	
	# Click quit_btn (labeled "Ana Menüye Dön")
	pause_menu._on_quit_pressed()
	await get_tree().create_timer(0.1).timeout

	assert(pause_menu.visible == false, "Pause menu must be closed")
	assert(main_menu.visible == true, "Main menu must be open and visible")
	assert(hud.visible == false, "HUD must be hidden on main menu")
	assert(main_scene.current_room_node == null, "Active room must be unloaded")
	print("  [6] Return to Main Menu from Pause Menu without quitting: OK")

	# TEST 4: Case 2 Chapter Selection sequence
	main_scene._on_case_selected("case02")
	await get_tree().create_timer(0.1).timeout
	assert(GameState.current_room_id == "silas_office", "Case 2 must start in silas_office")
	main_scene.current_room_node.answer_phone()
	assert(main_scene.phone_call_dialogue.visible == true, "Case 2 phone dialogue must open")
	assert(main_scene.phone_call_dialogue.call_data.get("dialogue_id") == "case02_phone_call", "Case 2 phone dialogue loaded")
	
	main_scene.phone_call_dialogue.finish_call()
	await get_tree().create_timer(0.35).timeout
	assert(main_scene.story_cutscene.visible == true, "Case 2 travel cutscene playing")
	main_scene.story_cutscene.finish() # finish travel_case02 -> loads arrival_case02
	await get_tree().create_timer(0.35).timeout
	main_scene.story_cutscene.finish() # finish arrival_case02 -> loads dock_pier
	await get_tree().create_timer(0.35).timeout
	assert(GameState.current_room_id == "dock_pier", "Must arrive at dock_pier crime scene, was: %s" % GameState.current_room_id)
	print("  [7] Case 02 Full Sequence (Office -> Phone -> Travel -> Arrival -> DockPier): OK")

	# TEST 5: Return to Main Menu again from Case 2
	EventBus.main_menu_requested.emit()
	await get_tree().create_timer(0.1).timeout
	assert(main_menu.visible == true, "Main menu visible after returning from Case 2")
	print("  [8] Return to Main Menu from Case 2: OK")

	# TEST 6: Case 3 Chapter Selection sequence
	main_scene._on_case_selected("case03")
	await get_tree().create_timer(0.1).timeout
	assert(GameState.current_room_id == "silas_office", "Case 3 must start in silas_office")
	main_scene.current_room_node.answer_phone()
	assert(main_scene.phone_call_dialogue.visible == true, "Case 3 phone dialogue must open")
	assert(main_scene.phone_call_dialogue.call_data.get("dialogue_id") == "case03_phone_call", "Case 3 phone dialogue loaded")

	main_scene.phone_call_dialogue.finish_call()
	await get_tree().create_timer(0.35).timeout
	assert(main_scene.story_cutscene.visible == true, "Case 3 travel cutscene playing")
	main_scene.story_cutscene.finish() # finish travel_case03 -> loads arrival_case03
	await get_tree().create_timer(0.35).timeout
	main_scene.story_cutscene.finish() # finish arrival_case03 -> loads opera_foyer
	await get_tree().create_timer(0.55).timeout
	assert(GameState.current_room_id == "opera_foyer", "Must arrive at opera_foyer crime scene, was: %s" % GameState.current_room_id)
	print("  [9] Case 03 Full Sequence (Office -> Phone -> Travel -> Arrival -> OperaFoyer): OK")

	# Return to Main Menu from Case 3
	EventBus.main_menu_requested.emit()
	await get_tree().create_timer(0.2).timeout
	assert(main_menu.visible == true, "Main menu visible after returning from Case 3")
	print("  [10] Return to Main Menu from Case 3: OK")

	# TEST 7: Auto-ring and Auto-pickup without player interaction
	main_scene._on_case_selected("case01")
	# At 0.1s, phone has not answered yet
	await get_tree().create_timer(0.1).timeout
	assert(main_scene.current_room_node.has_answered == false, "Phone must initially be unanswered")
	assert(main_scene.phone_call_dialogue.visible == false, "Phone dialogue not yet open")
	# At 0.6s, ringing started
	await get_tree().create_timer(0.6).timeout
	assert(main_scene.current_room_node.is_phone_ringing == true, "Phone must be ringing with SFX")
	# At 2.3s total, auto-answer has triggered
	await get_tree().create_timer(1.6).timeout
	assert(main_scene.phone_call_dialogue.visible == true, "Phone call dialogue opened automatically after ringing")
	assert(main_scene.current_room_node.has_answered == true, "Phone marked answered")
	print("  [11] Auto-ring and Auto-pickup sequence without manual input: OK")

	# Clean up and return to Main Menu
	main_scene.phone_call_dialogue.finish_call()
	await get_tree().create_timer(0.35).timeout
	EventBus.main_menu_requested.emit()
	await get_tree().create_timer(0.2).timeout
	assert(main_menu.visible == true, "Final Main Menu state confirmed")
	print("  [12] Final Return to Main Menu: OK")

	print("==================================================")
	print("=== ALL MENU & CASE FLOW TESTS PASSED! ===")
	print("==================================================")
	get_tree().quit(0)
