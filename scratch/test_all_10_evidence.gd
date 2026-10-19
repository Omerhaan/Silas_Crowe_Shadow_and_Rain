extends Node

func _ready() -> void:
	print("\n=======================================================")
	print("       TESTING ALL 10 EVIDENCE INTERACTIONS           ")
	print("=======================================================")

	# Ensure Case 3 is loaded
	GameState.switch_case("case03")
	CutsceneManager.is_cutscene_active = false
	GameState.can_player_move = true

	var main_scn = load("res://scenes/main.tscn")
	var main = main_scn.instantiate()
	add_child(main)

	var inspect_view = main.find_child("InspectView", true, false)
	var player = main.player

	var evidence_map = {
		"E301": {"room": "opera_roof", "node": "Evidence_E301"},
		"E302": {"room": "light_bridge", "node": "Evidence_E302"},
		"E303": {"room": "backstage", "node": "Evidence_E303"},
		"E304": {"room": "light_bridge", "node": "Evidence_E304"},
		"E305": {"room": "prop_room", "node": "Evidence_E305"},
		"E306": {"room": "royal_box", "node": "Evidence_E306"},
		"E307": {"room": "light_bridge", "node": "Evidence_E307"},
		"E308": {"room": "opera_roof", "node": "Evidence_E308"},
		"E309": {"room": "royal_box", "node": "Evidence_E309"},
		"E310": {"room": "opera_roof", "node": "Evidence_E310"}
	}

	for ev_id in evidence_map.keys():
		var info = evidence_map[ev_id]
		var r_name = info["room"]
		var n_name = info["node"]

		# Clear discovered evidence so we can test interaction
		GameState.discovered_evidence.clear()
		CutsceneManager.is_cutscene_active = false
		GameState.can_player_move = true

		main.load_room(r_name, "default")
		await get_tree().process_frame
		await get_tree().process_frame

		var room = main.current_room_node
		var ev_node = room.find_child(n_name, true, false)

		if not ev_node:
			print("❌ %s: Node '%s' not found in room '%s'!" % [ev_id, n_name, r_name])
			continue

		var pos = ev_node.position
		var spawn_node = room.find_child("Spawn_default", true, false)
		var spawn_y = spawn_node.position.y if spawn_node else 245.0

		# Check walls
		var walls = room.find_child("Walls", true, false)
		var lw = walls.find_child("LeftWall", true, false) if walls else null
		var rw = walls.find_child("RightWall", true, false) if walls else null
		var left_x = lw.position.x if lw else -999.0
		var right_x = rw.position.x if rw else 999.0

		# Position player
		player.global_position = Vector2(pos.x, spawn_y)
		await get_tree().physics_frame
		await get_tree().physics_frame

		player._update_current_interactable()
		var cur = player.current_interactable
		var cur_name = cur.name if cur else "NONE"

		inspect_view.visible = false
		player._on_interact_pressed()
		await get_tree().process_frame
		await get_tree().process_frame

		var collected = GameState.has_evidence(ev_id)
		var iv_visible = inspect_view.visible

		if collected and iv_visible:
			print("✔ [PASS] %s (%s) in %s: Detected (%s) -> InspectView OPENED, Collected!" % [
				ev_id, ev_node.display_name, r_name, cur_name
			])
		else:
			print("❌ [FAIL] %s (%s) in %s: cur=%s, player=(%.1f, %.1f), ev_pos=(%.1f, %.1f), collected=%s, inspect=%s" % [
				ev_id, ev_node.display_name, r_name, cur_name, player.global_position.x, player.global_position.y, pos.x, pos.y, collected, iv_visible
			])

	print("\n=======================================================")
	print("       ALL 10 EVIDENCE TESTS FINISHED                  ")
	print("=======================================================")
	get_tree().quit(0)
