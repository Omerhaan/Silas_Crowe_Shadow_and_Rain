extends Node2D

func _ready() -> void:
	print("--- TESTING ALL CASE 2 ROOMS & INTERACTABLES ---")
	
	var main_scene = load("res://scenes/main.tscn")
	var main = main_scene.instantiate()
	add_child(main)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	main._on_case_selected("case02")
	await get_tree().process_frame
	
	var rooms = ["dock_pier", "dock_office", "dock_warehouse", "captain_cabin", "dock_saloon"]
	var player = main.player
	var im = get_node_or_null("/root/InputManager")
	
	for r_id in rooms:
		print("\n==========================================")
		print("TESTING ROOM: ", r_id)
		print("==========================================")
		main.load_room(r_id, "default")
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().physics_frame
		await get_tree().physics_frame
		
		var room = main.current_room_node
		var interactables = []
		for c in room.get_children():
			if c.has_method("interact"):
				interactables.append(c)
		
		print("Total interactables in %s: %d" % [r_id, interactables.size()])
		
		for obj in interactables:
			var is_npc = obj.is_in_group("npcs") or str(obj.get("object_id")).begins_with("npc_")
			var is_door = obj.has_method("interact") and obj.get("target_room_id") != null
			var obj_desc = "%s (id=%s, evid=%s, is_npc=%s, is_door=%s)" % [obj.name, obj.get("object_id"), obj.get("evidence_id"), is_npc, is_door]
			
			# 1. Test Touch / Tap
			# Reset player state
			player.reset_interaction_state()
			im.request_interact_with(obj)
			# Simulate walking to it
			for f in range(60):
				await get_tree().physics_frame
			
			var can_interact_touch = (player.current_interactable == obj) or (player.pending_interact_target == null and not player.is_navigating)
			
			# 2. Test standing right below the object at floor Y=245 and pressing E
			player.reset_interaction_state()
			player.global_position = Vector2(obj.global_position.x, 245.0)
			await get_tree().physics_frame
			await get_tree().physics_frame
			player._update_current_interactable()
			
			var overlaps = player.interaction_area.get_overlapping_areas()
			var obj_area = obj.get_node_or_null("Area2D")
			var area_in_overlaps = (obj_area != null and overlaps.has(obj_area))
			var is_current = (player.current_interactable == obj)
			
			print("Item: %s | pos=(%.1f, %.1f)" % [obj_desc, obj.global_position.x, obj.global_position.y])
			print("   -> Area in overlaps: %s | current_interactable: %s" % [area_in_overlaps, player.current_interactable.name if player.current_interactable else "NULL"])
			
			if not area_in_overlaps and not is_npc:
				push_warning("   [FAIL OVERLAP] Player standing at (%.1f, 245) does NOT overlap %s at (%.1f, %.1f)!" % [obj.global_position.x, obj.name, obj.global_position.x, obj.global_position.y])

	await get_tree().create_timer(0.2).timeout
	get_tree().quit(0)
