extends Node

func _ready() -> void:
	print("\n=======================================================")
	print(">>> RUNNING CASE 3 ROOM & INTERACTION VERIFICATION <<<")
	print("=======================================================\n")

	GameState.current_case_id = "case03"
	GameState.load_all_case_data("case03")

	var rooms = [
		"opera_foyer",
		"opera_auditorium",
		"royal_box",
		"backstage",
		"prop_room",
		"light_bridge",
		"opera_roof"
	]

	var total_objects = 0
	var reachable_objects = 0
	var unreached = []

	var player_scene = load("res://scenes/entities/player.tscn")

	for r_name in rooms:
		print("-------------------------------------------------------")
		print("TESTING ROOM: " + r_name)
		print("-------------------------------------------------------")
		var r_path = "res://cases/case03/rooms/%s.tscn" % r_name
		var room = load(r_path).instantiate()
		add_child(room)

		# Add player to room
		var player = player_scene.instantiate()
		room.add_child(player)

		# Find all interactables and doors and npcs
		var interactables = []
		for child in room.get_children():
			if child.is_in_group("interactables") or child.has_method("interact"):
				interactables.append(child)

		# Check walls
		var left_wall_x = 0.0
		var right_wall_x = 480.0
		var walls = room.get_node_or_null("Walls")
		if walls:
			var lw = walls.get_node_or_null("LeftWall")
			var rw = walls.get_node_or_null("RightWall")
			if lw: left_wall_x = lw.position.x
			if rw: right_wall_x = rw.position.x
		print("  Walkable area: X [%.1f .. %.1f]" % [left_wall_x, right_wall_x])

		for obj in interactables:
			total_objects += 1
			var obj_name = obj.name
			var pos = obj.global_position
			var is_reachable = true
			var reason = ""

			# Check if outside walls
			if pos.x < left_wall_x or pos.x > right_wall_x:
				is_reachable = false
				reason = "BLOCKED BY WALL (x=%.1f outside [%.1f, %.1f])" % [pos.x, left_wall_x, right_wall_x]

			# Check door collision if door
			if obj.has_node("DoorArea"):
				var door_col = obj.get_node_or_null("DoorArea/CollisionShape2D")
				if door_col and door_col.disabled:
					is_reachable = false
					reason = "DOOR COLLISION DISABLED"

			# Position player at object's X
			var test_x = clampf(pos.x, left_wall_x + 10.0, right_wall_x - 10.0)
			player.global_position = Vector2(test_x, 245.0)
			
			# Check distance
			var dist = abs(player.global_position.x - pos.x)
			if dist > 55.0 and is_reachable:
				is_reachable = false
				reason = "CANNOT GET WITHIN REACH (min_dist=%.1f > 55.0)" % dist

			if is_reachable:
				reachable_objects += 1
				print("  ✔ REACHABLE: %-26s pos=(%5.1f, %5.1f)" % [obj_name, pos.x, pos.y])
			else:
				print("  ❌ UNREACHABLE: %-24s pos=(%5.1f, %5.1f) -> %s" % [obj_name, pos.x, pos.y, reason])
				unreached.append("%s :: %s -> %s" % [r_name, obj_name, reason])

		room.queue_free()

	print("\n=======================================================")
	print("RESULTS: %d / %d OBJECTS REACHABLE" % [reachable_objects, total_objects])
	if not unreached.is_empty():
		print("\nUNREACHABLE OBJECTS LIST:")
		for u in unreached:
			print(" - " + u)
	print("=======================================================\n")
	get_tree().quit(0)
