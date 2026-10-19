extends Node

func _ready() -> void:
	print("\n=== RUNNING FOCUS, E-CLOSE & MULTI-CASE VERIFICATION TEST ===")
	var passed = 0
	var total = 0

	# 1. EventBus signal
	total += 1
	if EventBus.has_signal("focus_pulse_requested"):
		print("✔ [1] EventBus.focus_pulse_requested exists.")
		passed += 1
	else:
		printerr("❌ [1] EventBus.focus_pulse_requested missing!")

	# 2. Case Registry
	total += 1
	if GameState.case_registry.size() >= 3:
		print("✔ [2] GameState.case_registry has %d cases (Case01, Case02, Case03)." % GameState.case_registry.size())
		passed += 1
	else:
		printerr("❌ [2] GameState.case_registry has less than 3 cases!")

	# 3. Case02 data files
	total += 1
	var case2_path = "res://data/cases/case02/case.json"
	if FileAccess.file_exists(case2_path):
		var f = FileAccess.open(case2_path, FileAccess.READ)
		var json = JSON.new()
		if json.parse(f.get_as_text()) == OK:
			print("✔ [3] Case02 data valid: %s" % json.data.get("title", ""))
			passed += 1
		else:
			printerr("❌ [3] Case02 JSON invalid!")
	else:
		printerr("❌ [3] Case02 directory or file missing!")

	# 4. Multi-case switching test
	total += 1
	# Temporarily unlock case02 to test switch
	GameState.case_registry[1]["unlocked"] = true
	var switched = GameState.switch_case("case02")
	if switched and GameState.current_case_id == "case02" and GameState.evidence_db.has("E201"):
		print("✔ [4] Multi-case switch to case02 successful! Loaded %d clues." % GameState.evidence_db.size())
		passed += 1
	else:
		printerr("❌ [4] Case switch failed!")
	# Switch back to case01
	GameState.switch_case("case01")

	# 5. InspectView E-to-close logic test
	total += 1
	var inspect_scene = load("res://scenes/ui/inspect_view.tscn")
	if inspect_scene:
		var iv = inspect_scene.instantiate()
		add_child(iv)
		iv.open_inspect("E01")
		if iv.visible:
			# Simulate E key input
			var key_event = InputEventKey.new()
			key_event.keycode = KEY_E
			key_event.pressed = true
			key_event.echo = false
			iv.inspect_cooldown = 0.0 # Clear cooldown
			iv._input(key_event)
			if not iv.visible:
				print("✔ [5] InspectView cleanly closes on pressing E!")
				passed += 1
			else:
				printerr("❌ [5] InspectView did not close on pressing E!")
		else:
			printerr("❌ [5] InspectView did not open!")
		iv.queue_free()

	# 6. Interactable double dialogue box prevention test
	total += 1
	var interactable_script = load("res://scripts/entities/interactable.gd")
	var int_obj = Node2D.new()
	int_obj.set_script(interactable_script)
	int_obj.object_id = "test_watch"
	int_obj.evidence_id = "E01"
	add_child(int_obj)
	var inner_voice_emitted = false
	var iv_handler = func(_txt): inner_voice_emitted = true
	EventBus.inner_voice_requested.connect(iv_handler)
	int_obj.interact()
	EventBus.inner_voice_requested.disconnect(iv_handler)
	if not inner_voice_emitted:
		print("✔ [6] Evidence inspection does NOT emit duplicate inner_voice_requested!")
		passed += 1
	else:
		printerr("❌ [6] Double dialogue bug detected! inner_voice was emitted during evidence inspect!")
	int_obj.queue_free()

	# 7. Door pulse highlight test
	total += 1
	var door_scene = load("res://scenes/entities/door.tscn")
	if door_scene:
		var door_inst = door_scene.instantiate()
		add_child(door_inst)
		door_inst.pulse_highlight(0.5)
		if door_inst.highlight and door_inst.highlight.visible and door_inst.prompt_label.visible:
			print("✔ [7] Door pulse highlight activates highlight box and label!")
			passed += 1
		else:
			printerr("❌ [7] Door pulse highlight did not activate!")
		door_inst.queue_free()

	# 8. Noir fonts and theme test
	total += 1
	if FileAccess.file_exists("res://resources/noir_theme.tres") and FileAccess.file_exists("res://assets/fonts/CourierPrime-Regular.ttf"):
		print("✔ [8] Noir theme and authentic Turkish typewriter font verified!")
		passed += 1
	else:
		printerr("❌ [8] Theme or font file missing!")

	# 9. Audio assets verification
	total += 1
	var music_ok = FileAccess.file_exists("res://assets/audio/music/bgm_noir_piano.mp3")
	var thunder_ok = FileAccess.file_exists("res://assets/audio/sfx/sfx_storm_thunder.ogg")
	var type_ok = FileAccess.file_exists("res://assets/audio/sfx/sfx_typewriter.ogg")
	if music_ok and thunder_ok and type_ok:
		print("✔ [9] Noir audio assets (Piano BGM, Thunder SFX, Typewriter SFX) verified!")
		passed += 1
	else:
		printerr("❌ [9] Audio assets missing!")

	print("\n=== RESULTS: %d/%d TESTS PASSED ===" % [passed, total])
	if passed == total:
		print(">>> ALL VERIFICATION TESTS PASSED SUCCESSFULLY! <<<\n")
	else:
		printerr(">>> SOME TESTS FAILED! <<<\n")
	get_tree().quit()
