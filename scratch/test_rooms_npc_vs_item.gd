extends Node2D

func _ready() -> void:
	print("--- TESTING ALL CASE 2 ROOMS: ITEM VS NPC INTERACTION ---")
	var main_scene = load("res://scenes/main.tscn")
	var main = main_scene.instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	
	main._on_case_selected("case02")
	await get_tree().process_frame
	
	var rooms = ["dock_office", "captain_cabin", "dock_saloon", "dock_warehouse"]
	var player = main.player
	
	for r_id in rooms:
		print("\n==================================================")
		print("TESTING ROOM: ", r_id)
		print("==================================================")
		main.load_room(r_id, "default")
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().physics_frame
		await get_tree().physics_frame
		
		var room = main.current_room_node
		var items = []
		var npcs = []
		for c in room.get_children():
			if c.is_in_group("npcs") or str(c.get("object_id")).begins_with("npc_"):
				npcs.append(c)
			elif c.has_method("interact") and c.get("target_room_id") == null:
				items.append(c)
		
		print("NPCs (%d): %s" % [npcs.size(), str(npcs.map(func(n): return n.name))])
		print("Items (%d): %s" % [items.size(), str(items.map(func(i): return i.name))])
		
		for it in items:
			# Place player directly at item's X coordinate, floor Y = 245
			player.global_position = Vector2(it.global_position.x, 245.0)
			player.reset_interaction_state()
			await get_tree().physics_frame
			await get_tree().physics_frame
			player._update_current_interactable()
			
			var cur = player.current_interactable
			var cur_name = cur.name if cur else "NULL"
			
			# Check what _on_interact_pressed would hit:
			# Check NPC priority in player.gd:
			var hit_npc = null
			for npc in get_tree().get_nodes_in_group("npcs"):
				if abs(player.global_position.x - npc.global_position.x) <= 65.0:
					hit_npc = npc
					break
			
			var actual_target = hit_npc if hit_npc else cur
			var actual_name = actual_target.name if actual_target else "NULL"
			
			var status = "OK (Hit Item)"
			if actual_target != it:
				status = "BLOCKED BY %s" % actual_name
			
			print("Item: %-22s at X=%5.1f, Y=%5.1f | In Area? %-5s | Current: %-15s | Press E Hits: %-18s -> %s" % [
				it.name, it.global_position.x, it.global_position.y,
				str(player.interaction_area.overlaps_area(it.get_node("Area2D")) if it.get_node_or_null("Area2D") else false),
				cur_name, actual_name, status
			])
	
	get_tree().quit(0)
