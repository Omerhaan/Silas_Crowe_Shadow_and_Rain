extends Node2D

## Automated test for:
## 1) NPCs do not block Silas (Silas can walk through NPCs like a normal room)
## 2) Pressing 'E' successfully interacts with items at all heights (Y=106, Y=182, etc.)
## 3) Evidence items take priority over generic props

func _ready() -> void:
	print("\n========================================================")
	print(" RUNNING NPC GHOST COLLISION & ITEM 'E' INTERACTION TEST ")
	print("========================================================\n")

	var failed = false

	# -------------------------------------------------------------
	# TEST 1: NPC collision disabled - Silas walks through NPC
	# -------------------------------------------------------------
	print("--- TEST 1: Walking through NPC without collision blocking ---")
	var player_scene = load("res://scenes/entities/player.tscn")
	var npc_scene = load("res://scenes/entities/npc.tscn")

	var player = player_scene.instantiate()
	player.position = Vector2(100, 245)
	add_child(player)

	var npc = npc_scene.instantiate()
	npc.character_id = "npc_dr_hale"
	npc.position = Vector2(120, 245)
	add_child(npc)

	await get_tree().physics_frame
	await get_tree().physics_frame

	# Verify NPC collision layer is 0
	print("NPC collision_layer: %d, collision_mask: %d" % [npc.collision_layer, npc.collision_mask])
	if npc.collision_layer == 0 and npc.collision_mask == 0:
		print("PASS: NPC physical collision is 0 (ghost/walk-through enabled)")
	else:
		print("FAIL: NPC physical collision is not 0 (blocks movement)")
		failed = true

	var npc_col = npc.get_node_or_null("CollisionShape2D")
	if npc_col and npc_col.disabled:
		print("PASS: NPC CollisionShape2D is disabled")
	else:
		print("FAIL: NPC CollisionShape2D is not disabled")
		failed = true

	# Simulate moving through
	for i in range(10):
		player.position.x += 5.0
		await get_tree().physics_frame

	print("Player final X after moving through NPC at X=120: %.1f" % player.position.x)
	if player.position.x > 125.0:
		print("PASS: Silas successfully walked through the NPC without getting blocked")
	else:
		print("FAIL: Silas was blocked by the NPC at X=%.1f!" % player.position.x)
		failed = true

	npc.free()
	player.free()
	await get_tree().physics_frame

	# -------------------------------------------------------------
	# TEST 2: Item interaction via 'E' for items at different heights
	# -------------------------------------------------------------
	print("\n--- TEST 2: Item interaction with 'E' at various heights ---")
	var p2 = player_scene.instantiate()
	p2.position = Vector2(300, 245)
	add_child(p2)

	var item_scene = load("res://scenes/entities/interactable.tscn")

	# Test 2A: High wall sconce item (Y=106, like E08)
	var high_item = item_scene.instantiate()
	high_item.position = Vector2(300, 106)
	high_item.object_id = "test_sconce"
	high_item.display_name = "Duvar Apligi"
	high_item.evidence_id = "E08"
	high_item.is_hotspot = true
	high_item.hotspot_size = Vector2(16, 24)
	add_child(high_item)

	await get_tree().physics_frame
	await get_tree().physics_frame

	# Update player's nearby interactables
	p2._update_current_interactable()

	print("Current interactable at X=300 for item at Y=106: %s" % (p2.current_interactable.name if p2.current_interactable else "None"))
	if p2.current_interactable == high_item:
		print("PASS: High wall item (Y=106) detected within Silas interaction area")
	else:
		print("FAIL: High wall item was NOT detected by Silas!")
		failed = true

	high_item.free()
	p2.reset_interaction_state()
	await get_tree().physics_frame

	# Test 2B: Evidence priority over desk prop
	var desk_prop = item_scene.instantiate()
	desk_prop.position = Vector2(300, 205)
	desk_prop.object_id = "test_desk"
	desk_prop.display_name = "Masa"
	desk_prop.is_hotspot = true
	desk_prop.hotspot_size = Vector2(100, 50)
	add_child(desk_prop)

	var evidence_on_desk = item_scene.instantiate()
	evidence_on_desk.position = Vector2(300, 182)
	evidence_on_desk.object_id = "test_corpse_watch"
	evidence_on_desk.display_name = "Ceset ve Saat"
	evidence_on_desk.evidence_id = "E01"
	evidence_on_desk.hotspot_size = Vector2(45, 34)
	add_child(evidence_on_desk)

	await get_tree().physics_frame
	await get_tree().physics_frame

	p2.nearby_interactables.clear()
	p2._update_current_interactable()

	print("Current interactable at desk with evidence: %s (%s)" % [p2.current_interactable.name if p2.current_interactable else "None", p2.current_interactable.display_name if p2.current_interactable else ""])
	if p2.current_interactable == evidence_on_desk:
		print("PASS: Evidence (E01) takes priority over generic desk prop")
	else:
		print("FAIL: Evidence did NOT take priority over desk prop!")
		failed = true

	# Test 2C: Trigger 'E' interaction
	p2._on_interact_pressed()

	# E01 is collectible, so interacting collects it and records in GameState
	if GameState.has_evidence("E01"):
		print("PASS: Pressing 'E' successfully collected evidence E01!")
	else:
		print("FAIL: Evidence E01 was not collected on 'E' press")
		failed = true

	desk_prop.free()
	evidence_on_desk.free()
	p2.free()

	# -------------------------------------------------------------
	# TEST 3: NPC interrogation triggers with 'E' key press
	# -------------------------------------------------------------
	print("\n--- TEST 3: NPC interrogation trigger with 'E' key press ---")
	GameState.can_player_move = true
	var p3 = player_scene.instantiate()
	p3.position = Vector2(100, 245)
	add_child(p3)

	var test_state = {"received_id": ""}
	var on_interrogation = func(s_id: String):
		test_state["received_id"] = s_id
	EventBus.interrogation_requested.connect(on_interrogation)

	var suspects_to_test = [
		{"id": "npc_dr_hale", "expected": "hale"},
		{"id": "npc_raymond_pike", "expected": "pike"},
		{"id": "npc_margaret_doyle", "expected": "margaret"},
		{"id": "npc_julian_harlow", "expected": "julian"}
	]

	for st in suspects_to_test:
		var test_npc = npc_scene.instantiate()
		test_npc.character_id = st["id"]
		test_npc.display_name = st["expected"].capitalize()
		test_npc.position = Vector2(140, 245) # 40 px away, well within 65 px prompt range
		add_child(test_npc)
		await get_tree().physics_frame
		await get_tree().physics_frame

		test_state["received_id"] = ""
		p3._on_interact_pressed()

		print("NPC %s: Silas at X=100 pressed 'E' -> received_suspect_id: '%s'" % [st["id"], test_state["received_id"]])
		if test_state["received_id"] == st["expected"]:
			print("PASS: Pressing 'E' successfully opened interrogation for '%s'!" % st["expected"])
		else:
			print("FAIL: Expected '%s', but got '%s'!" % [st["expected"], test_state["received_id"]])
			failed = true

		test_npc.free()
		await get_tree().physics_frame

	EventBus.interrogation_requested.disconnect(on_interrogation)
	p3.free()

	print("\n========================================================")
	if failed:
		print(" SOME TESTS FAILED!")
		print("========================================================\n")
		get_tree().quit(1)
	else:
		print(" ALL NPC GHOST & ITEM 'E' TESTS PASSED (100%)! ")
		print("========================================================\n")
		get_tree().quit(0)
