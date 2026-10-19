extends Node2D

func _ready() -> void:
	print("--- SIMULATING MAIN GAME TO CASE 2 ---")
	
	# Load Main scene
	var main_scene = load("res://scenes/main.tscn")
	var main = main_scene.instantiate()
	add_child(main)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	print("Main initialized. current_room: ", main.current_room_node)
	print("Simulating Case 2 selection from MainMenu...")
	main._on_case_selected("case02")
	
	await get_tree().process_frame
	print("Current room after switch: ", main.current_room_node.name if main.current_room_node else "NULL")
	print("GameState.current_case_id: ", GameState.current_case_id)
	
	# Fast-forward to dock_pier
	print("Calling load_room('dock_pier', 'default')...")
	main.load_room("dock_pier", "default")
	
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	print("Room loaded: ", main.current_room_node.name)
	var player = main.player
	print("Player pos: ", player.global_position)
	print("Player can_player_move: ", GameState.can_player_move)
	
	# Move player to Evidence_E208 at (310, 240)
	player.global_position = Vector2(310, 245)
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	print("\n--- CHECKING INTERACTION AT (310, 245) ---")
	print("nearby_interactables count: ", player.nearby_interactables.size())
	for n in player.nearby_interactables:
		print("  nearby: ", n.name, " (", n.get("object_id"), ") evid=", n.get("evidence_id"))
	print("current_interactable: ", player.current_interactable.name if player.current_interactable else "NULL")
	
	# Check HUD interaction button or prompt
	var hud = main.hud
	print("HUD visible: ", hud.visible)
	var interact_btn = hud.find_child("InteractBtn", true, false)
	if interact_btn:
		print("HUD InteractBtn visible: ", interact_btn.visible, " disabled: ", interact_btn.disabled)
	
	# Try pressing E
	print("\nSimulating pressing 'E'...")
	player._on_interact_pressed()
	
	# Check if InspectView or toast opened
	var inspect_view = main.find_child("InspectView", true, false)
	print("InspectView visible: ", inspect_view.visible if inspect_view else "N/A")
	
	# Try touch on Evidence_E208
	var e208 = main.current_room_node.find_child("Evidence_E208", true, false)
	if e208:
		print("\nSimulating tap on Evidence_E208...")
		var im = get_node_or_null("/root/InputManager")
		im.request_interact_with(e208)
		await get_tree().process_frame
		print("Player is_navigating: ", player.is_navigating, " pending_interact_target: ", player.pending_interact_target)
		print("InspectView visible: ", inspect_view.visible if inspect_view else "N/A")
	
	await get_tree().create_timer(0.2).timeout
	get_tree().quit(0)
