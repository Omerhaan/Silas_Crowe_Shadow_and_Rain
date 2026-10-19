extends Node

func _ready() -> void:
	print("\n=======================================================")
	print("       TESTING EVIDENCE INTERACTION IN FULL GAME       ")
	print("=======================================================")

	var main_scn = load("res://scenes/main.tscn")
	var main = main_scn.instantiate()
	add_child(main)

	# Simulate starting case03 from Case Select
	print("\n--- 1. Switching to Case 03 ---")
	main._on_case_selected("case03")

	# Wait and finish cutscene
	await get_tree().create_timer(0.5).timeout
	CutsceneManager.is_cutscene_active = false
	GameState.can_player_move = true
	await get_tree().create_timer(0.5).timeout

	print("Current case: %s" % GameState.current_case_id)
	print("Evidence DB size: %d" % GameState.evidence_db.size())

	# Load prop_room directly via main
	print("\n--- 2. Loading Prop Room ---")
	main.load_room("prop_room", "from_backstage")
	await get_tree().create_timer(0.5).timeout

	var prop_room = main.current_room_node
	print("Loaded room: %s" % prop_room.name)

	var ev_node = prop_room.find_child("Evidence_E305", true, false)
	print("Evidence_E305 node: %s" % ("FOUND" if ev_node else "NOT FOUND"))

	if ev_node:
		print("Evidence_E305 object_id: %s, evidence_id: %s, visible: %s" % [
			ev_node.object_id, ev_node.evidence_id, ev_node.visible
		])
		
		# Position player right next to E305
		var player = main.player
		player.global_position = Vector2(ev_node.global_position.x, 245.0)
		await get_tree().physics_frame
		await get_tree().physics_frame

		player._update_current_interactable()
		print("Player current_interactable: %s" % (player.current_interactable.name if player.current_interactable else "null"))

		var inspect_view = main.find_child("InspectView", true, false)
		print("InspectView before interact: visible=%s" % inspect_view.visible)

		print("GameState.can_player_move: %s" % GameState.can_player_move)
		print("CutsceneManager.is_cutscene_active: %s" % CutsceneManager.is_cutscene_active)
		# Trigger interact
		print("Triggering interact on player...")
		player._on_interact_pressed()
		await get_tree().process_frame
		await get_tree().process_frame

		print("InspectView after interact: visible=%s" % inspect_view.visible)
		print("Has evidence E305 in GameState: %s" % GameState.has_evidence("E305"))

	print("\n=======================================================")
	print("       TEST COMPLETE                                   ")
	print("=======================================================")
	get_tree().quit(0)
