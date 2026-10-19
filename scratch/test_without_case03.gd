extends Node

func _ready() -> void:
	print("--- TEST: WHAT HAPPENS WHEN CASE_ID IS NOT CASE03 ---")
	print("GameState.current_case_id = ", GameState.current_case_id)
	
	# Try interacting with Evidence_E305 when current_case_id is case01 (default)
	var prop_room_scn = load("res://cases/case03/rooms/prop_room.tscn")
	var prop_room = prop_room_scn.instantiate()
	add_child(prop_room)

	var ev305 = prop_room.find_child("Evidence_E305", true, false)
	print("Evidence_E305 found: ", ev305 != null)
	
	var signal_emitted = false
	EventBus.inspect_evidence_requested.connect(func(_id): signal_emitted = true)
	EventBus.inner_voice_requested.connect(func(_txt): signal_emitted = true)

	print("Calling ev305.interact() while current_case_id == 'case01'...")
	ev305.interact()
	print("Signal emitted? ", signal_emitted)
	print("Has evidence E305? ", GameState.has_evidence("E305"))

	get_tree().quit(0)
