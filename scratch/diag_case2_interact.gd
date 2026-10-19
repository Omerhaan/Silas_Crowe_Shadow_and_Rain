extends Node2D

func _ready() -> void:
	print("--- TEST CASE 2 INTERACTION DIAGNOSTIC ---")
	
	# 1. Switch to Case 2
	GameState.switch_case("case02")
	print("Switched to case02. Clues count in DB: ", GameState.evidence_db.size())
	
	# 2. Instantiate dock_pier room
	var room_scene = load("res://cases/case02/rooms/dock_pier.tscn")
	var room = room_scene.instantiate()
	add_child(room)
	print("Room instantiated: ", room.name)
	
	# 3. Instantiate Player
	var player_scene = load("res://scenes/entities/player.tscn")
	var player = player_scene.instantiate()
	room.add_child(player)
	player.global_position = Vector2(180, 245)
	print("Player position: ", player.global_position)
	
	# 4. Check interactables in room
	for child in room.get_children():
		if child.has_method("interact"):
			print("Found interactable: ", child.name, " (", child.get("object_id"), ") pos=", child.global_position)
			var area = child.get_node_or_null("Area2D")
			if area:
				var col = area.get_node_or_null("CollisionShape2D")
				var shape_size = col.shape.size if col and col.shape and "size" in col.shape else "N/A"
				print("   -> Area2D layer=", area.collision_layer, " mask=", area.collision_mask, " shape_size=", shape_size, " area_pos=", area.global_position, " col_pos=", col.position if col else "N/A")

	await get_tree().physics_frame
	await get_tree().physics_frame
	
	# Move player right next to Evidence_E208 at (310, 240)
	player.global_position = Vector2(310, 245)
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	print("\nPlayer at Vector2(310, 245) next to E208 (310, 240)...")
	var interact_area = player.get_node("InteractionArea")
	print("Player InteractionArea layer=", interact_area.collision_layer, " mask=", interact_area.collision_mask, " global_pos=", interact_area.global_position)
	print("Overlapping areas count on InteractionArea: ", interact_area.get_overlapping_areas().size())
	for a in interact_area.get_overlapping_areas():
		print("   overlapping area: ", a.name, " parent: ", a.get_parent().name)
	
	player._update_current_interactable()
	print("Player nearby_interactables count: ", player.nearby_interactables.size())
	for n in player.nearby_interactables:
		print("   nearby: ", n.name)
	print("Player current_interactable: ", player.current_interactable.name if player.current_interactable else "NULL")
	
	# Test pressing E
	print("\nTesting _on_interact_pressed()...")
	player._on_interact_pressed()
	
	# Test touch/click on Evidence_E208
	var e208 = room.get_node("Evidence_E208")
	print("\nTesting touch on Evidence_E208...")
	var touch_ev = InputEventScreenTouch.new()
	touch_ev.pressed = true
	touch_ev.position = e208.global_position
	e208._on_area_input_event(null, touch_ev, 0)
	
	await get_tree().create_timer(0.2).timeout
	get_tree().quit(0)
