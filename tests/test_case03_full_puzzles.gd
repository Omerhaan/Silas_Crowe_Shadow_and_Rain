extends Node

func _ready() -> void:
	print("--- BEGIN TEST CASE 03 FULL PUZZLE & PROGRESSION ---")

	# 1. Reset GameState to Case 03
	GameState.current_case_id = "case03"
	GameState.inventory_items.clear()
	GameState.flags.clear()
	GameState.discovered_evidence.clear()
	GameState.collected_statements.clear()
	GameState.load_all_case_data("case03")

	print("[1] Initial State:")
	assert(not GameState.has_item("backstage_key"), "Must not have backstage_key initially")
	assert(not GameState.has_item("smelling_salts"), "Must not have smelling_salts initially")
	assert(not GameState.has_item("bridge_key"), "Must not have bridge_key initially")
	assert(not GameState.has_item("stage_lever"), "Must not have stage_lever initially")
	print("  -> Initial inventory clean: OK")

	# 2. Test Opera Foyer Door & Ticket Booth
	var foyer_scene = load("res://cases/case03/rooms/opera_foyer.tscn").instantiate()
	add_child(foyer_scene)
	var door_backstage = foyer_scene.get_node("Door_To_Backstage2")
	assert(door_backstage != null, "Door_To_Backstage2 must exist")
	assert(door_backstage.is_locked, "Door_To_Backstage2 must be locked")
	assert(door_backstage.required_key_id == "backstage_key", "Requires backstage_key")

	# Try opening locked door without key
	door_backstage.interact()
	assert(door_backstage.is_locked, "Door should remain locked without key")
	print("  -> Foyer Backstage Door initially locked: OK")

	# Inspect Ticket Booth
	var ticket_booth = foyer_scene.get_node("Prop_TicketBooth")
	assert(ticket_booth != null, "Prop_TicketBooth must exist")
	ticket_booth.interact()
	assert(GameState.has_item("backstage_key"), "Must acquire backstage_key from ticket booth")
	assert(GameState.has_item("smelling_salts"), "Must acquire smelling_salts from ticket booth")
	print("  -> Ticket Booth granted backstage_key and smelling_salts: OK")

	# Re-attempt opening Backstage Door
	door_backstage.interact()
	assert(not door_backstage.is_locked, "Door should unlock now that key is possessed")
	print("  -> Backstage Door unlocked with backstage_key: OK")
	foyer_scene.queue_free()

	# 3. Test Backstage Light Bridge Door & Gated Dialogues
	var backstage_scene = load("res://cases/case03/rooms/backstage.tscn").instantiate()
	add_child(backstage_scene)
	var door_bridge = backstage_scene.get_node("Door_To_Light_Bridge")
	assert(door_bridge != null, "Door_To_Light_Bridge must exist")
	assert(door_bridge.is_locked, "Door_To_Light_Bridge must be locked")
	assert(door_bridge.required_key_id == "bridge_key", "Requires bridge_key")

	door_bridge.interact()
	assert(door_bridge.is_locked, "Bridge door should remain locked without bridge_key")
	print("  -> Backstage Door to Light Bridge initially locked: OK")

	# Test Interrogation Modal with Elena (Panicked -> Smelling salts -> Calmed)
	var inter_scene = load("res://scenes/ui/interrogation.tscn").instantiate()
	add_child(inter_scene)

	# Before smelling salts:
	GameState.inventory_items.erase("smelling_salts") # temporarily test without salts
	GameState.flags.erase("elena_calmed")
	inter_scene.open_interrogation("elena")
	# Try clicking night_events while panicked
	var night_topic = null
	for t in inter_scene.current_dialogue_data.get("topics", []):
		if t.get("id") == "night_events":
			night_topic = t
			break
	assert(night_topic != null, "night_events topic exists")
	inter_scene._on_topic_selected(night_topic)
	assert(not GameState.collected_statements.has("elena") or GameState.collected_statements["elena"].is_empty(), "Elena should yield no statement while panicked")
	print("  -> Elena locked response while in panic: OK")

	# Now give smelling salts back and calm Elena:
	GameState.add_item("smelling_salts", "Yatıştırıcı Koklama Tuzu")
	inter_scene._load_dialogue_topics()
	var offer_salts_topic = null
	for t in inter_scene.current_dialogue_data.get("topics", []):
		if t.get("id") == "offer_smelling_salts":
			offer_salts_topic = t
			break
	assert(offer_salts_topic != null, "offer_smelling_salts topic must be visible when holding smelling_salts")
	inter_scene._on_topic_selected(offer_salts_topic)
	assert(GameState.flags.get("elena_calmed", false) == true, "elena_calmed flag must be true")

	# Now test Elena's glint_claim topic:
	var glint_topic = null
	for t in inter_scene.current_dialogue_data.get("topics", []):
		if t.get("id") == "glint_claim":
			glint_topic = t
			break
	inter_scene._on_topic_selected(glint_topic)
	assert(GameState.collected_statements.has("elena") and GameState.collected_statements["elena"].size() > 0, "Elena must yield statement when calmed")
	print("  -> Elena calmed with smelling salts and provided statement: OK")

	# Test Finch's dialogue (evasive without E303, confesses with E303)
	inter_scene.open_interrogation("finch")
	var key_topic = null
	for t in inter_scene.current_dialogue_data.get("topics", []):
		if t.get("id") == "light_bridge_key":
			key_topic = t
			break
	assert(key_topic != null, "light_bridge_key topic must exist")
	inter_scene._on_topic_selected(key_topic)
	assert(not GameState.collected_statements.has("finch") or GameState.collected_statements["finch"].is_empty(), "Finch should yield no statement before E303")
	print("  -> Finch locked response without E303: OK")

	# Now collect E303
	GameState.add_evidence("E303")
	inter_scene._on_topic_selected(key_topic)
	assert(GameState.collected_statements.has("finch") and GameState.collected_statements["finch"].size() > 0, "Finch must confess after E303")
	print("  -> Finch confessed about key theft after E303: OK")
	inter_scene._on_exit_pressed()
	backstage_scene.queue_free()

	# 4. Test Prop Room Tool Chest & Tumbler Lock Minigame
	var prop_scene = load("res://cases/case03/rooms/prop_room.tscn").instantiate()
	add_child(prop_scene)
	var tool_chest = prop_scene.get_node("Prop_ToolChest")
	assert(tool_chest != null, "Prop_ToolChest must exist")
	print("  -> Prop_ToolChest exists in prop_room: OK")

	var tumbler_modal = load("res://scenes/ui/tumbler_lock_modal.tscn").instantiate()
	add_child(tumbler_modal)
	tumbler_modal.open_modal()
	assert(tumbler_modal.visible, "Tumbler modal should be open")

	# Test wrong combination [0, 0, 0]
	tumbler_modal._on_unlock_pressed()
	assert(not GameState.has_item("bridge_key"), "Must not unlock with [0, 0, 0]")
	assert(not GameState.flags.get("patch_chest_opened", false), "Flag should remain false")

	# Dial 1 - 1 - 2
	tumbler_modal._change_digit(0, 1) # Digit 0 -> 1
	tumbler_modal._change_digit(1, 1) # Digit 1 -> 1
	tumbler_modal._change_digit(2, 2) # Digit 2 -> 2
	assert(tumbler_modal.digits == [1, 1, 2], "Digits must be 1, 1, 2")

	tumbler_modal._on_unlock_pressed()
	assert(GameState.has_item("bridge_key"), "Must obtain bridge_key upon opening chest")
	assert(GameState.has_item("stage_lever"), "Must obtain stage_lever upon opening chest")
	assert(GameState.flags.get("patch_chest_opened", false) == true, "patch_chest_opened flag must be true")
	print("  -> Tumbler Lock solved with [1, 1, 2], obtained bridge_key & stage_lever: OK")

	# Test Patch's confession now that chest is opened
	inter_scene.open_interrogation("patch")
	var blast_topic = null
	for t in inter_scene.current_dialogue_data.get("topics", []):
		if t.get("id") == "two_blasts":
			blast_topic = t
			break
	assert(blast_topic != null, "two_blasts topic must exist")
	inter_scene._on_topic_selected(blast_topic)
	assert(GameState.collected_statements.has("patch") and GameState.collected_statements["patch"].size() > 0, "Patch must confess after chest opened")
	print("  -> Patch confessed to hearing second rifle shot: OK")
	inter_scene._on_exit_pressed()
	prop_scene.queue_free()

	# 5. Test Light Bridge & Roof Hatch Unlock
	var bridge_scene = load("res://cases/case03/rooms/light_bridge.tscn").instantiate()
	add_child(bridge_scene)
	var door_roof = bridge_scene.get_node("Door_To_Roof")
	assert(door_roof != null, "Door_To_Roof must exist")
	assert(door_roof.required_key_id == "stage_lever", "Roof door requires stage_lever")

	door_roof.interact()
	assert(not door_roof.is_locked, "Roof door must unlock with stage_lever")
	print("  -> Roof door unlocked using stage_lever: OK")
	bridge_scene.queue_free()

	print("=== ALL CASE 03 PUZZLE & GATING TESTS PASSED SUCCESSFULLY! ===")
	get_tree().quit(0)
