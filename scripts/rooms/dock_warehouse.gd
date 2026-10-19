extends Node2D

## Dock Warehouse room controller: handles Boris physical blocker and Saloon access.

@onready var boris_npc: NPC = get_node_or_null("NPC_Boris")
@onready var door_saloon: Area2D = get_node_or_null("Door_To_Saloon")

func _ready() -> void:
	if EventBus.has_signal("statement_collected"):
		EventBus.statement_collected.connect(_on_statement_collected)

	_check_boris_state()

func _check_boris_state() -> void:
	var allowed = GameState.flags.get("boris_allowed", false) or GameState.has_item("night_pass")
	if boris_npc:
		if allowed:
			boris_npc.position.x = 370.0
			boris_npc.has_physical_collision = false
			var col = boris_npc.get_node_or_null("CollisionShape2D")
			if col:
				col.disabled = true
			boris_npc.collision_layer = 0
			boris_npc.collision_mask = 0
			boris_npc.set_facing("left")
		else:
			boris_npc.position.x = 420.0
			boris_npc.has_physical_collision = true
			var col = boris_npc.get_node_or_null("CollisionShape2D")
			if col:
				col.disabled = false
			boris_npc.collision_layer = 1
			boris_npc.collision_mask = 1
			boris_npc.set_facing("down")

	if door_saloon and allowed:
		door_saloon.is_locked = false

func _on_statement_collected(suspect_id: String, _statement: String) -> void:
	if suspect_id == "boris":
		if GameState.flags.get("boris_allowed", false) or GameState.has_item("night_pass"):
			_open_saloon_passage()

func _open_saloon_passage() -> void:
	GameState.flags["boris_allowed"] = true
	if door_saloon:
		door_saloon.is_locked = false
	if boris_npc:
		boris_npc.step_aside(370.0, 0.8)
		EventBus.toast_requested.emit("✔ Boris kenara çekildi. Saloon kapısı açıldı.")
