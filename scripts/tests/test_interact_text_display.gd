extends Node2D

## Automated test to verify that interacting with items/props displays texts (dialogue_box/inner_voice/inspect_view)
## and does NOT immediately close in the same frame.

func _ready() -> void:
	print("\n========================================================")
	print(" RUNNING INTERACTION TEXT DISPLAY TEST ")
	print("========================================================\n")

	var failed = false

	# Instantiate HUD and Player
	var hud_scene = load("res://scenes/ui/hud.tscn")
	var hud = hud_scene.instantiate()
	add_child(hud)

	var player_scene = load("res://scenes/entities/player.tscn")
	var player = player_scene.instantiate()
	player.position = Vector2(200, 245)
	add_child(player)

	var item_scene = load("res://scenes/entities/interactable.tscn")
	var prop = item_scene.instantiate()
	prop.position = Vector2(200, 200)
	prop.object_id = "test_prop"
	prop.display_name = "Antika Sehpa"
	prop.custom_inner_voice = "\"Tozlu sehpa. Üzerinde eski bir iz var.\""
	prop.is_hotspot = true
	prop.hotspot_size = Vector2(60, 60)
	add_child(prop)

	await get_tree().physics_frame
	await get_tree().physics_frame

	player._update_current_interactable()
	print("Player current_interactable: %s" % (player.current_interactable.name if player.current_interactable else "None"))

	# 1. Silas interacts with prop
	print("Simulating interact on prop...")
	player._on_interact_pressed()

	print("After interact:")
	print("  hud.is_showing_inner_voice = %s" % hud.is_showing_inner_voice)
	var dbox = hud.get_node_or_null("SafeArea/DialogueBox")
	print("  hud.dialogue_box.visible = %s" % (dbox.visible if dbox else "null"))
	var dbox_label = dbox.get_node_or_null("Margin/HBox/ContentBox/DialogueLabel") if dbox else null
	print("  dialogue_box text = '%s'" % (dbox_label.text if dbox_label else ""))

	if not (dbox and dbox.visible and hud.is_showing_inner_voice):
		print("FAIL: Dialogue box did not open on interact!")
		failed = true

	# 2. Process frame immediately after opening (cooldown should prevent premature close)
	hud._process(0.016)

	print("\nAfter immediate hud._process(0.016):")
	print("  hud.is_showing_inner_voice = %s" % hud.is_showing_inner_voice)
	print("  hud.dialogue_box.visible = %s" % (dbox.visible if dbox else "null"))

	if dbox and dbox.visible and hud.is_showing_inner_voice:
		print("PASS: Dialogue box remains VISIBLE and open during cooldown!")
	else:
		print("FAIL: Dialogue box was CLOSED during cooldown!")
		failed = true

	# 3. Simulate cooldown expiration and user pressing 'E' to close
	hud._process(0.30)
	print("\nAfter cooldown expired (0.30s), advancing dialogue box...")
	dbox.advance() # Or pressing E after reading
	print("  hud.is_showing_inner_voice = %s" % hud.is_showing_inner_voice)
	print("  hud.dialogue_box.visible = %s" % (dbox.visible if dbox else "null"))

	prop.free()

	# -------------------------------------------------------------
	# TEST 2: Evidence Item inspection with InspectView
	# -------------------------------------------------------------
	print("\n--- TEST 2: Evidence Item inspection with InspectView ---")
	var inspect_scene = load("res://scenes/ui/inspect_view.tscn")
	var inspect_view = inspect_scene.instantiate()
	add_child(inspect_view)

	var ev_prop = item_scene.instantiate()
	ev_prop.position = Vector2(200, 200)
	ev_prop.object_id = "test_candle"
	ev_prop.display_name = "Mum ve Aplik"
	ev_prop.evidence_id = "E08"
	ev_prop.is_hotspot = true
	ev_prop.hotspot_size = Vector2(30, 30)
	add_child(ev_prop)

	await get_tree().physics_frame
	await get_tree().physics_frame

	player.nearby_interactables.clear()
	player._update_current_interactable()
	print("Player current_interactable for evidence: %s" % (player.current_interactable.name if player.current_interactable else "None"))

	# Silas interacts with Evidence E08
	player._on_interact_pressed()

	print("After evidence interact:")
	print("  inspect_view.visible = %s" % inspect_view.visible)
	var ev_dbox = inspect_view.get_node_or_null("ModalPanel/DialogueBox")
	var ev_label = ev_dbox.get_node_or_null("Margin/HBox/ContentBox/DialogueLabel") if ev_dbox else null
	print("  inspect_view dialogue text = '%s'" % (ev_label.text if ev_label else ""))

	if inspect_view.visible and ev_label and ev_label.text != "":
		print("PASS: InspectView successfully opened and displayed evidence text!")
	else:
		print("FAIL: InspectView was not displayed or dialogue text was empty!")
		failed = true

	# Test advance / close with E
	inspect_view._process(0.30)
	var e_event = InputEventKey.new()
	e_event.keycode = KEY_E
	e_event.pressed = true
	e_event.echo = false
	inspect_view._unhandled_input(e_event)

	print("After pressing 'E' on InspectView:")
	print("  inspect_view.visible = %s" % inspect_view.visible)
	if not inspect_view.visible and GameState.can_player_move:
		print("PASS: Pressing 'E' successfully closed InspectView and restored movement!")
	else:
		print("FAIL: InspectView did not close on 'E' press!")
		failed = true

	ev_prop.free()
	inspect_view.free()
	player.free()
	hud.free()

	print("\n========================================================")
	if failed:
		print(" SOME TESTS FAILED!")
		print("========================================================\n")
		get_tree().quit(1)
	else:
		print(" ALL INTERACTION TEXT TESTS PASSED (100%)! ")
		print("========================================================\n")
		get_tree().quit(0)
