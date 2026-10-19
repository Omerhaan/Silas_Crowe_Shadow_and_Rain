extends Node

func _ready() -> void:
	print("--- TESTING LIGHT RANGE MODAL LOAD ---")
	var scn = load("res://scenes/ui/light_range_modal.tscn")
	var inst = scn.instantiate()
	add_child(inst)
	print("Instantiated successfully!")
	var schematic = inst.find_child("SchematicRect", true, false)
	print("SchematicRect texture: ", schematic.texture)
	print("Texture size: ", schematic.texture.get_size() if schematic.texture else "NONE")
	inst.open_board()
	print("Opened board successfully!")
	print("RayLine exists? ", inst.find_child("RayLine", true, false) != null)
	get_tree().quit(0)
