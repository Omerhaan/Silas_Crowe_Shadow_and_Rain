extends Node

func _ready() -> void:
	print("--- TEST NPC INTERACTION START ---")
	var main_scene = load("res://scenes/main.tscn").instantiate()
	add_child(main_scene)
	await get_tree().process_frame
	await get_tree().process_frame

	# Simulate starting game
	main_scene._on_new_game_started()
	await get_tree().process_frame

	# Close initial inner voice from new game start
	if main_scene.hud.inner_voice_panel.visible:
		main_scene.hud.close_inner_voice()
	await get_tree().process_frame

	var npcs_to_test = [
		{"room": "library", "npc": "npc_dr_hale", "name": "Dr. Victor Hale"},
		{"room": "dining_room", "npc": "npc_raymond_pike", "name": "Raymond Pike"},
		{"room": "kitchen", "npc": "npc_margaret_doyle", "name": "Margaret Doyle"},
		{"room": "billiard_room", "npc": "npc_julian_harlow", "name": "Julian Harlow"}
	]

	for info in npcs_to_test:
		print("\nTesting %s in room %s..." % [info["name"], info["room"]])
		main_scene.load_room(info["room"], "default")
		await get_tree().process_frame
		await get_tree().process_frame

		var room = main_scene.current_room_node
		var player = main_scene.player
		var interrog = main_scene.ui_overlays.get_node("Interrogation")

		# Find the NPC node
		var npc_node: Node2D = null
		for child in room.get_children():
			if child.get("object_id") == info["npc"]:
				npc_node = child
				break

		assert(npc_node != null, "NPC node not found: " + info["npc"])
		print("NPC found at position: ", npc_node.global_position)

		# 1. Place Silas near NPC and verify prompt label
		player.global_position = Vector2(npc_node.global_position.x - 25, 245)
		await get_tree().physics_frame
		await get_tree().physics_frame

		assert(player.current_interactable == npc_node, "NPC should have priority over props! Got: " + str(player.current_interactable))
		var prompt_lbl = npc_node.get_node_or_null("PromptLabel")
		assert(prompt_lbl != null and prompt_lbl.visible, "NPC prompt label should be visible!")
		assert("[E] Konuş:" in prompt_lbl.text, "Prompt label should show '[E] Konuş: ...', got: " + prompt_lbl.text)
		print("✔ Prompt label verified: ", prompt_lbl.text)

		# 2. Trigger interaction with E and verify interrogation UI
		InputManager.trigger_interact()
		await get_tree().process_frame
		await get_tree().process_frame

		assert(interrog.visible, "Interrogation UI should be visible!")
		var topics_container = interrog.get_node("InterrogationPanel/TopicsScroll/TopicsList")
		assert(topics_container.get_child_count() == 5, "Should have 5 interrogation topics! Found: " + str(topics_container.get_child_count()))
		print("✔ Interrogation opened with 5 topics:")
		for btn in topics_container.get_children():
			print("   - ", btn.text)

		# 3. Test topic selection
		var first_btn: Button = topics_container.get_child(0)
		first_btn.emit_signal("pressed")
		await get_tree().process_frame
		var dialogue_lbl = interrog.get_node("InterrogationPanel/DialogueScroll/DialogueLabel")
		assert(dialogue_lbl.text != "", "Dialogue response should be populated!")
		print("✔ Dialogue response verified: ", dialogue_lbl.text.substr(0, 45), "...")

		# Close interrogation
		interrog._on_exit_pressed()
		await get_tree().process_frame
		assert(!interrog.visible, "Interrogation should be closed!")

		# 4. Test Tap-To-Walk interaction from a distance
		player.global_position = Vector2(50, 245)
		player.reset_interaction_state()
		await get_tree().physics_frame
		await get_tree().physics_frame

		InputManager.request_interact_with(npc_node)
		# Step navigation forward
		for frame in range(120):
			player._physics_process(0.016)
			await get_tree().physics_frame
			if interrog.visible:
				break

		assert(interrog.visible, "Tap-to-interact should navigate and open interrogation!")
		print("✔ Tap-to-walk to NPC and auto-open interrogation passed!")
		interrog._on_exit_pressed()
		await get_tree().process_frame

	print("\n--- TEST NPC INTERACTION FINISHED ---")
	get_tree().quit(0)
