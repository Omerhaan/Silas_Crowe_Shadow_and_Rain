extends Node

func _ready() -> void:
	print("\n=======================================================")
	print("       TESTING INTERACTIONS AT ACTUAL SPAWN_Y          ")
	print("=======================================================")

	GameState.switch_case("case03")

	var player_scn = load("res://scenes/entities/player.tscn")
	var rooms = [
		"opera_foyer",
		"opera_auditorium",
		"royal_box",
		"backstage",
		"prop_room",
		"light_bridge",
		"opera_roof"
	]

	var inner_voice_log = []
	var inspect_log = []
	var interrogation_log = []
	var toast_log = []
	var room_change_log = []
	var light_range_log = []

	EventBus.inner_voice_requested.connect(func(txt): inner_voice_log.append(txt))
	EventBus.inspect_evidence_requested.connect(func(ev_id): inspect_log.append(ev_id))
	EventBus.interrogation_requested.connect(func(s_id): interrogation_log.append(s_id))
	EventBus.toast_requested.connect(func(t): toast_log.append(t))
	EventBus.room_change_requested.connect(func(r, s): room_change_log.append(r + "::" + s))
	EventBus.light_range_requested.connect(func(): light_range_log.append("light_range_board"))

	for r_name in rooms:
		print("\n--- ROOM: %s ---" % r_name)
		var r_path = "res://cases/case03/rooms/%s.tscn" % r_name
		var room = load(r_path).instantiate()
		add_child(room)

		var player = player_scn.instantiate()
		room.add_child(player)

		var interactables = []
		for child in room.get_children():
			if child.has_method("interact"):
				interactables.append(child)

		# Get spawn Y (from Spawn_default)
		var def_spawn = room.find_child("Spawn_default", true, false)
		var spawn_y = def_spawn.position.y if def_spawn else 245.0

		# Get room boundaries
		var left_wall_x = -9999.0
		var right_wall_x = 9999.0
		var walls = room.find_child("Walls", true, false)
		if walls:
			var lw = walls.find_child("LeftWall", true, false)
			if lw: left_wall_x = lw.position.x
			var rw = walls.find_child("RightWall", true, false)
			if rw: right_wall_x = rw.position.x

		print("Walkable X: [%.1f .. %.1f], Player Y = %.1f" % [left_wall_x, right_wall_x, spawn_y])

		for item in interactables:
			var item_name = item.name
			var obj_id = item.get("object_id") if "object_id" in item else ""
			var ev_id = item.get("evidence_id") if "evidence_id" in item else ""
			var disp_name = item.get("display_name") if "display_name" in item else (item.get("door_name") if "door_name" in item else "")
			var pos = item.position

			var within_walls = (pos.x >= left_wall_x and pos.x <= right_wall_x)
			if not within_walls:
				print("  ❌ [BLOCKED BY WALL] %s ('%s') at (%.1f, %.1f) is outside [%.1f, %.1f]" % [
					item_name, disp_name, pos.x, pos.y, left_wall_x, right_wall_x
				])
				continue

			# Place player at item's X and room's spawn_y
			player.global_position = Vector2(pos.x, spawn_y)
			
			await get_tree().physics_frame
			await get_tree().physics_frame

			# Check if player's interaction area detects the item
			var detected = false
			if player.interaction_area:
				var overlapping = player.interaction_area.get_overlapping_areas()
				for a in overlapping:
					if a == item or a.get_parent() == item or a == item.get_node_or_null("Area2D"):
						detected = true
						break

			inner_voice_log.clear()
			inspect_log.clear()
			interrogation_log.clear()
			toast_log.clear()
			room_change_log.clear()
			light_range_log.clear()

			# Direct interact test
			item.interact()

			var has_response = (inner_voice_log.size() > 0 or inspect_log.size() > 0 or interrogation_log.size() > 0 or toast_log.size() > 0 or room_change_log.size() > 0 or light_range_log.size() > 0)
			var response_desc = ""
			if inner_voice_log.size() > 0: response_desc += "Voice: " + inner_voice_log[0].substr(0, 25) + "... "
			if inspect_log.size() > 0: response_desc += "Inspect: " + inspect_log[0] + " "
			if interrogation_log.size() > 0: response_desc += "Interrogate: " + interrogation_log[0] + " "
			if room_change_log.size() > 0: response_desc += "Door: " + room_change_log[0] + " "
			if light_range_log.size() > 0: response_desc += "LightBoardModal "

			if not detected:
				print("  ⚠️ [CANNOT OVERLAP / REACH] %s ('%s') at (%.1f, %.1f). Player at Y=%.1f cannot reach it!" % [
					item_name, disp_name, pos.x, pos.y, spawn_y
				])
			elif not has_response:
				print("  ❌ [NO RESPONSE ON E] %s ('%s') at (%.1f, %.1f) - Overlapped, but interact() produced nothing!" % [
					item_name, disp_name, pos.x, pos.y
				])
			else:
				print("  ✔ [OK] %s ('%s') -> %s" % [item_name, disp_name, response_desc])

		room.queue_free()
		await get_tree().process_frame

	print("\n=======================================================")
	print("       TEST COMPLETE                                   ")
	print("=======================================================")
	get_tree().quit(0)
