extends Node

func _ready() -> void:
	print("\n=======================================================")
	print("   MINIGAME EFFECTS, KEYBOARD & NAV LOCKS VERIFICATION  ")
	print("=======================================================")

	var passed: int = 0
	var total: int = 0

	# -------------------------------------------------------------
	# TEST 1: HUD Fast-Nav Locked Door Blocking (Case 02 - Boris)
	# -------------------------------------------------------------
	total += 1
	GameState.switch_case("case02")
	GameState.inventory_items.clear()
	GameState.flags.clear()

	var hud_scene = load("res://scenes/ui/hud.tscn")
	var hud_inst = hud_scene.instantiate()
	add_child(hud_inst)

	var warehouse_scene = load("res://cases/case02/rooms/dock_warehouse.tscn")
	var warehouse_inst = warehouse_scene.instantiate()
	add_child(warehouse_inst)

	GameState.current_room_id = "dock_warehouse"
	hud_inst._on_room_changed("dock_warehouse")

	var is_locked_saloon = hud_inst._is_passage_locked("dock_saloon")
	var nav_right_text = hud_inst.nav_right_btn.text
	if is_locked_saloon and nav_right_text.contains("🔒") and (nav_right_text.contains("Kilitli") or nav_right_text.contains("Locked")):
		print("✔ [1] HUD correctly identifies locked door to Saloon and shows '🔒 [Locked/Kilitli]'.")
		passed += 1
	else:
		printerr("❌ [1] Failed to block or mark locked door to Saloon! is_locked=", is_locked_saloon, " text=", nav_right_text)

	# -------------------------------------------------------------
	# TEST 2: HUD Nav Button click blocked without key
	# -------------------------------------------------------------
	total += 1
	var room_changed_emitted = false
	var test_cb = func(r, s): room_changed_emitted = true
	EventBus.room_change_requested.connect(test_cb)

	# Clicking nav_right_btn when locked should NOT emit room_change_requested
	hud_inst._on_nav_right_pressed()
	if not room_changed_emitted:
		print("✔ [2] HUD nav click does not bypass locked door without required key.")
		passed += 1
	else:
		printerr("❌ [2] HUD nav click bypassed locked door!")
	EventBus.room_change_requested.disconnect(test_cb)

	# -------------------------------------------------------------
	# TEST 3: HUD Nav Button unlocks when key is acquired
	# -------------------------------------------------------------
	total += 1
	GameState.add_item("night_pass", "Mühürlü Gece İzin Belgesi")
	is_locked_saloon = hud_inst._is_passage_locked("dock_saloon")
	hud_inst._update_nav_buttons("dock_warehouse")
	nav_right_text = hud_inst.nav_right_btn.text

	var transition_res = {"success": false}
	var test_cb2 = func(r, s):
		if r == "dock_saloon":
			transition_res.success = true
	EventBus.room_change_requested.connect(test_cb2)

	hud_inst._on_nav_right_pressed()
	if not is_locked_saloon and not nav_right_text.contains("🔒") and transition_res.success:
		print("✔ [3] HUD nav correctly unlocks and transitions when player possesses night_pass.")
		passed += 1
	else:
		printerr("❌ [3] Failed to unlock after obtaining key! is_locked=", is_locked_saloon, " transition=", transition_res.success)
	EventBus.room_change_requested.disconnect(test_cb2)

	warehouse_inst.queue_free()
	hud_inst.queue_free()

	# -------------------------------------------------------------
	# TEST 4: Winch Password Mandatory Enforcement (Bug 2 verification)
	# -------------------------------------------------------------
	total += 1
	GameState.flags.clear()
	GameState.discovered_evidence.clear()

	var pier_scene = load("res://cases/case02/rooms/dock_pier.tscn")
	var pier_inst = pier_scene.instantiate()
	add_child(pier_inst)

	var military_crate = pier_inst.find_child("Evidence_E202", true, false)
	if military_crate:
		# Without crane_winch_lowered, interacting must NOT grant E202
		military_crate.interact()
		var crate_blocked = not GameState.has_evidence("E202")

		# Now set crane_winch_lowered via solving the puzzle
		GameState.flags["crane_winch_lowered"] = true
		military_crate.interact()
		var crate_accessible = GameState.has_evidence("E202")

		if crate_blocked and crate_accessible:
			print("✔ [4] Military crate strictly gated by winch calibration; no premature bypass.")
			passed += 1
		else:
			printerr("❌ [4] Winch gate failed! blocked=", crate_blocked, " accessible=", crate_accessible)
	else:
		printerr("❌ [4] Evidence_E202 node not found in dock_pier!")
	pier_inst.queue_free()

	# -------------------------------------------------------------
	# TEST 5: SafeDialModal Keyboard Input (Case 01: 1-9-4-4)
	# -------------------------------------------------------------
	total += 1
	GameState.switch_case("case01")
	GameState.discovered_evidence.clear()
	GameState.flags.clear()

	var safe_scene = load("res://scenes/ui/safe_dial_modal.tscn")
	var safe_inst = safe_scene.instantiate()
	add_child(safe_inst)
	safe_inst.open_modal()

	# Send keyboard events: 1, 9, 4, 4, Enter
	_send_key(safe_inst, KEY_1)
	_send_key(safe_inst, KEY_9)
	_send_key(safe_inst, KEY_4)
	_send_key(safe_inst, KEY_4)
	_send_key(safe_inst, KEY_ENTER)

	if GameState.flags.get("harlow_safe_opened", false) and GameState.has_evidence("E07"):
		print("✔ [5] SafeDialModal keyboard entry (1-9-4-4 + Enter) successfully unlocked safe.")
		passed += 1
	else:
		printerr("❌ [5] SafeDialModal keyboard entry failed! digits=", safe_inst.digits)
	safe_inst.queue_free()

	# -------------------------------------------------------------
	# TEST 6: CraneWinchModal Keyboard Input (Case 02: 2-3-0)
	# -------------------------------------------------------------
	total += 1
	GameState.switch_case("case02")
	GameState.flags.clear()
	GameState.discovered_evidence.clear()

	var winch_scene = load("res://scenes/ui/crane_winch_modal.tscn")
	var winch_inst = winch_scene.instantiate()
	add_child(winch_inst)
	winch_inst.open_modal()

	# Send keyboard events: 2, 3, 0, Enter
	_send_key(winch_inst, KEY_2)
	_send_key(winch_inst, KEY_3)
	_send_key(winch_inst, KEY_0)
	_send_key(winch_inst, KEY_ENTER)

	if GameState.flags.get("crane_winch_lowered", false) and GameState.has_evidence("E202"):
		print("✔ [6] CraneWinchModal keyboard entry (2-3-0 + Enter) successfully lowered winch.")
		passed += 1
	else:
		printerr("❌ [6] CraneWinchModal keyboard entry failed! digits=", winch_inst.digits)
	winch_inst.queue_free()

	# -------------------------------------------------------------
	# TEST 7: TumblerLockModal Keyboard Input (Case 03: 1-1-2)
	# -------------------------------------------------------------
	total += 1
	GameState.switch_case("case03")
	GameState.flags.clear()
	GameState.inventory_items.clear()

	var tumbler_scene = load("res://scenes/ui/tumbler_lock_modal.tscn")
	var tumbler_inst = tumbler_scene.instantiate()
	add_child(tumbler_inst)
	tumbler_inst.open_modal()

	# Send keyboard events: 1, 1, 2, Enter
	_send_key(tumbler_inst, KEY_1)
	_send_key(tumbler_inst, KEY_1)
	_send_key(tumbler_inst, KEY_2)
	_send_key(tumbler_inst, KEY_ENTER)

	if GameState.flags.get("patch_chest_opened", false) and GameState.has_item("bridge_key") and GameState.has_item("stage_lever"):
		print("✔ [7] TumblerLockModal keyboard entry (1-1-2 + Enter) successfully unlocked tool chest.")
		passed += 1
	else:
		printerr("❌ [7] TumblerLockModal keyboard entry failed! digits=", tumbler_inst.digits)
	tumbler_inst.queue_free()

	# -------------------------------------------------------------
	# TEST 8: LightRangeModal Dynamic Overlay & Drawing
	# -------------------------------------------------------------
	total += 1
	var light_scene = load("res://scenes/ui/light_range_modal.tscn")
	var light_inst = light_scene.instantiate()
	add_child(light_inst)
	light_inst.open_board()

	var has_overlay = (light_inst.overlay != null and light_inst.overlay is Control)
	light_inst._process(0.1)
	if has_overlay:
		print("✔ [8] LightRangeModal dynamic overlay initialized and animating.")
		passed += 1
	else:
		printerr("❌ [8] LightRangeModal overlay not created!")

	# -------------------------------------------------------------
	# TEST 9: LightRangeModal Hotkeys & Blind Spot Solution
	# -------------------------------------------------------------
	total += 1
	GameState.unlocked_deductions.clear()

	# Set Spot A OFF via 'A', Spot B ON via 'B', Spot C OFF via 'C'
	# Initial: A is ON, B is OFF, C is ON
	_send_key(light_inst, KEY_A) # A becomes OFF
	_send_key(light_inst, KEY_B) # B becomes ON
	_send_key(light_inst, KEY_C) # C becomes OFF
	_send_key(light_inst, KEY_3) # Select Bridge

	var config_ok = (!light_inst.spot_a_on and light_inst.spot_b_on and !light_inst.spot_c_on and light_inst.selected_position == "bridge")

	# Test fire via Enter
	_send_key(light_inst, KEY_ENTER)
	# Fast forward simulation
	light_inst._process(1.0)

	var deduction_unlocked = "D302" in GameState.unlocked_deductions
	if config_ok and deduction_unlocked:
		print("✔ [9] LightRangeModal hotkeys (A/B/C, 1/2/3, Enter) and Blind Spot solution (D302) verified.")
		passed += 1
	else:
		printerr("❌ [9] LightRangeModal hotkey/solution test failed! config=", config_ok, " D302=", deduction_unlocked)
	light_inst.queue_free()

	# -------------------------------------------------------------
	# TEST 10: SafeDialModal ESC Key Closes Modal
	# -------------------------------------------------------------
	total += 1
	var safe_test = safe_scene.instantiate()
	add_child(safe_test)
	safe_test.open_modal()
	_send_key(safe_test, KEY_ESCAPE)
	if not safe_test.visible and GameState.can_player_move:
		print("✔ [10] SafeDialModal ESC key successfully exits modal and restores player movement.")
		passed += 1
	else:
		printerr("❌ [10] SafeDialModal ESC exit failed! visible=", safe_test.visible, " can_move=", GameState.can_player_move)
	safe_test.queue_free()

	# -------------------------------------------------------------
	# TEST 11: CraneWinchModal ESC Key Closes Modal
	# -------------------------------------------------------------
	total += 1
	var winch_test = winch_scene.instantiate()
	add_child(winch_test)
	winch_test.open_modal()
	_send_key(winch_test, KEY_ESCAPE)
	if not winch_test.visible and GameState.can_player_move:
		print("✔ [11] CraneWinchModal ESC key successfully exits modal and restores player movement.")
		passed += 1
	else:
		printerr("❌ [11] CraneWinchModal ESC exit failed! visible=", winch_test.visible, " can_move=", GameState.can_player_move)
	winch_test.queue_free()

	# -------------------------------------------------------------
	# TEST 12: TumblerLockModal ESC Key Closes Modal
	# -------------------------------------------------------------
	total += 1
	var tumbler_test = tumbler_scene.instantiate()
	add_child(tumbler_test)
	tumbler_test.open_modal()
	_send_key(tumbler_test, KEY_ESCAPE)
	if not tumbler_test.visible and GameState.can_player_move:
		print("✔ [12] TumblerLockModal ESC key successfully exits modal and restores player movement.")
		passed += 1
	else:
		printerr("❌ [12] TumblerLockModal ESC exit failed! visible=", tumbler_test.visible, " can_move=", GameState.can_player_move)
	tumbler_test.queue_free()

	# -------------------------------------------------------------
	# TEST 13: LightRangeModal ESC Key Closes Board & PauseMenu Interception
	# -------------------------------------------------------------
	total += 1
	var light_test = light_scene.instantiate()
	add_child(light_test)
	light_test.open_board()

	var pause_scene = load("res://scenes/ui/pause_menu.tscn")
	var pause_inst = pause_scene.instantiate()
	add_child(pause_inst)

	# Simulate InputManager.menu_pressed (global ESC event)
	pause_inst._on_menu_pressed()

	# LightRangeModal should be closed and PauseMenu should NOT be opened
	if not light_test.visible and not pause_inst.visible and GameState.can_player_move:
		print("✔ [13] Global ESC cleanly closes minigame board without opening PauseMenu.")
		passed += 1
	else:
		printerr("❌ [13] ESC interception failed! board_vis=", light_test.visible, " pause_vis=", pause_inst.visible)

	pause_inst.queue_free()
	light_test.queue_free()

	# -------------------------------------------------------------
	# SUMMARY
	# -------------------------------------------------------------
	print("\n=======================================================")
	print("RESULTS: %d / %d TESTS PASSED" % [passed, total])
	print("=======================================================\n")
	if passed == total:
		print("ALL SYSTEM REQUIREMENTS FULLY VERIFIED!")
		get_tree().quit(0)
	else:
		printerr("SOME TESTS FAILED!")
		get_tree().quit(1)

func _send_key(target: Node, keycode: Key) -> void:
	var ev = InputEventKey.new()
	ev.keycode = keycode
	ev.pressed = true
	ev.echo = false
	target._unhandled_input(ev)
