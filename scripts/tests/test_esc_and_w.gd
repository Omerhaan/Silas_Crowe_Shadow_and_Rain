extends Node2D

## Automated test for:
## 1) 'W' does not trigger interaction, only 'E' (and space/touch) does
## 2) ESC closes active interaction / inspect / dialogue instead of opening pause menu

func _ready() -> void:
	print("\n========================================================")
	print(" RUNNING ESC INTERACTION CLOSING & 'W' REMOVAL TEST ")
	print("========================================================\n")

	var failed = false

	# ---------------------------------------------------------
	# TEST 1: Check player.gd doesn't trigger interaction on move_up (W)
	# ---------------------------------------------------------
	print("--- TEST 1: Checking player.gd for move_up interaction ---")
	var p_file = FileAccess.open("res://scripts/entities/player.gd", FileAccess.READ)
	if p_file:
		var p_text = p_file.get_as_text()
		p_file.close()
		if p_text.contains('is_action_just_pressed("move_up")'):
			print("FAIL: player.gd still contains move_up interaction check!")
			failed = true
		else:
			print("PASS: player.gd has removed move_up interaction trigger ('W' no longer interacts)")
	else:
		print("FAIL: Cannot open player.gd")
		failed = true

	# ---------------------------------------------------------
	# TEST 2: InspectView close on ESC
	# ---------------------------------------------------------
	print("\n--- TEST 2: Checking InspectView ESC handling ---")
	var inspect_scene = load("res://scenes/ui/inspect_view.tscn").instantiate()
	add_child(inspect_scene)
	inspect_scene.visible = true
	GameState.can_player_move = false

	# Simulate ESC on inspect view
	var esc_ev = InputEventKey.new()
	esc_ev.keycode = KEY_ESCAPE
	esc_ev.pressed = true
	esc_ev.echo = false

	inspect_scene._unhandled_input(esc_ev)
	if not inspect_scene.visible and GameState.can_player_move:
		print("PASS: InspectView closes on ESC and restores player movement")
	else:
		print("FAIL: InspectView did not close on ESC (visible=%s)" % inspect_scene.visible)
		failed = true
	inspect_scene.free()

	# ---------------------------------------------------------
	# TEST 3: PauseMenu _try_close_active_interaction
	# ---------------------------------------------------------
	print("\n--- TEST 3: Checking PauseMenu interaction priority on ESC ---")
	var pause_scene = load("res://scenes/ui/pause_menu.tscn").instantiate()
	add_child(pause_scene)
	pause_scene.visible = false

	# Case A: An inspect view is open
	var inspect_scene2 = load("res://scenes/ui/inspect_view.tscn").instantiate()
	inspect_scene2.name = "InspectView"
	add_child(inspect_scene2)
	inspect_scene2.visible = true

	pause_scene._on_menu_pressed()
	if inspect_scene2.visible == false and pause_scene.visible == false:
		print("PASS: PauseMenu closed InspectView and did NOT open itself")
	else:
		print("FAIL: PauseMenu opened or InspectView remained visible (pause_vis=%s, insp_vis=%s)" % [pause_scene.visible, inspect_scene2.visible])
		failed = true
	inspect_scene2.free()

	# Case B: Nothing is open -> PauseMenu opens
	pause_scene._on_menu_pressed()
	if pause_scene.visible:
		print("PASS: PauseMenu opens when no interaction is active")
	else:
		print("FAIL: PauseMenu did not open when idle")
		failed = true

	# Case C: PauseMenu is open -> pressing ESC closes it
	pause_scene._on_menu_pressed()
	if not pause_scene.visible:
		print("PASS: Pressing ESC while PauseMenu is open closes it")
	else:
		print("FAIL: PauseMenu did not close when open")
		failed = true

	pause_scene.free()

	print("\n========================================================")
	if failed:
		print(" SOME TESTS FAILED!")
		print("========================================================\n")
		get_tree().quit(1)
	else:
		print(" ALL ESC & 'W' TESTS PASSED (100%)! ")
		print("========================================================\n")
		get_tree().quit(0)
