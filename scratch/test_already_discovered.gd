extends Node

func _ready() -> void:
	print("--- TEST: WHAT HAPPENS WHEN EVIDENCE IS ALREADY IN DISCOVERED_EVIDENCE ---")
	GameState.switch_case("case03")
	GameState.discovered_evidence.append("E305")

	var prop_room_scn = load("res://cases/case03/rooms/prop_room.tscn")
	var prop_room = prop_room_scn.instantiate()
	add_child(prop_room)

	var ev305 = prop_room.find_child("Evidence_E305", true, false)
	print("Evidence_E305 found: ", ev305 != null)
	
	var inspect_emitted = false
	var voice_emitted = false
	EventBus.inspect_evidence_requested.connect(func(_id): inspect_emitted = true)
	EventBus.inner_voice_requested.connect(func(_txt): voice_emitted = true)

	print("Calling ev305.interact() when already discovered...")
	ev305.interact()
	print("Inspect emitted? ", inspect_emitted)
	print("Voice emitted? ", voice_emitted)

	get_tree().quit(0)
