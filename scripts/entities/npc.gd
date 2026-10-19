class_name NPC
extends Character

## Standard NPC entity inheriting from Character.
## Ensures strict 1:1 pixel scale, foot sole at (0, 0) / y=245 in scenes,
## proximity prompt "[E] Konuş: <isim>", tap-to-talk, and priority interaction.

@export var display_name: String = ""
@export var custom_inner_voice: String = ""
@export var is_suspect: bool = true
@export var npc_scale: float = 0.96
@export var has_physical_collision: bool = false

@onready var area_2d: Area2D = $Area2D
@onready var prompt_label: Label = $PromptLabel

var proximity_threshold: float = 65.0
var is_player_nearby: bool = false
var anim_breath_time: float = 0.0

var sprite_map = {
	"npc_dr_hale": "hale",
	"npc_raymond_pike": "pike",
	"npc_margaret_doyle": "margaret",
	"npc_julian_harlow": "julian",
	"npc_edmund_harlow": "edmund"
}

func _ready() -> void:
	super._ready()
	if not has_physical_collision:
		collision_layer = 0
		collision_mask = 0
		var col = get_node_or_null("CollisionShape2D")
		if col:
			col.disabled = true
	else:
		collision_layer = 1
		collision_mask = 1
		var col = get_node_or_null("CollisionShape2D")
		if col:
			col.disabled = false
			if col.shape is RectangleShape2D:
				col.shape.size = Vector2(28.0, 70.0)
				col.position.y = -35.0
	add_to_group("npcs")
	add_to_group("interactables")

	if sprite_2d:
		sprite_2d.scale = Vector2(npc_scale, npc_scale)
	if shadow:
		shadow.scale = Vector2(npc_scale, npc_scale)

	if prompt_label:
		prompt_label.visible = false
		prompt_label.position.y = -108.0 * npc_scale
		if display_name != "":
			prompt_label.text = "[E] Konuş: " + display_name

	if area_2d and not area_2d.input_event.is_connected(_on_area_input_event):
		area_2d.input_event.connect(_on_area_input_event)

	var area_col = area_2d.get_node_or_null("CollisionShape2D")
	if area_col and area_col.shape is RectangleShape2D:
		area_col.shape.size = Vector2(64.0 * npc_scale, 110.0 * npc_scale)
		area_col.position.y = -55.0 * npc_scale

	_load_npc_textures()
	set_facing("down")

func _load_npc_textures() -> void:
	var prefix = sprite_map.get(character_id, "")
	if prefix == "":
		for k in sprite_map.keys():
			if character_id.contains(sprite_map[k]):
				prefix = sprite_map[k]
				break

	if prefix == "":
		prefix = character_id.replace("npc_", "")

	var case_id = ""
	var ml = Engine.get_main_loop()
	if ml and ml.root:
		var gs = ml.root.get_node_or_null("GameState")
		if gs:
			case_id = gs.current_case_id

	var directions = ["down", "left", "right", "up"]
	for d in directions:
		var candidates = []
		if case_id != "":
			candidates.append("res://cases/%s/assets/characters/%s_idle_%s.png" % [case_id, prefix, d])
		candidates.append("res://assets/sprites/characters/%s_idle_%s.png" % [prefix, d])
		var tex: Texture2D = null
		for path in candidates:
			if ResourceLoader.exists(path):
				tex = load(path)
				break
			var gpath = ProjectSettings.globalize_path(path)
			if FileAccess.file_exists(gpath):
				var img = Image.load_from_file(gpath)
				if img:
					tex = ImageTexture.create_from_image(img)
					break
		if tex:
			directional_textures[d] = tex

	if directional_textures.has("down"):
		set_character_texture(directional_textures["down"])

func _process(_delta: float) -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player: Node2D = players[0]
	var dist = global_position.distance_to(player.global_position)
	var was_nearby = is_player_nearby
	is_player_nearby = (dist <= proximity_threshold)

	var eb = get_node_or_null("/root/EventBus")
	if is_player_nearby:
		if not was_nearby or (prompt_label and not prompt_label.visible):
			if prompt_label:
				prompt_label.text = "[E] " + get_localized_name()
				prompt_label.visible = true
			if eb and eb.has_signal("interaction_available"):
				eb.interaction_available.emit(self)
		
		# Turn toward Silas
		var dx = player.global_position.x - global_position.x
		if dx < -16.0:
			set_facing("left")
		elif dx > 16.0:
			set_facing("right")
		else:
			set_facing("down")
	else:
		if was_nearby:
			if prompt_label:
				prompt_label.visible = false
			if eb and eb.has_signal("interaction_unavailable"):
				eb.interaction_unavailable.emit(self)
			set_facing("down")

func _get_loc_mgr() -> Node:
	if is_inside_tree():
		return get_node_or_null("/root/LocalizationManager")
	var ml = Engine.get_main_loop()
	if ml and "root" in ml and ml.root:
		return ml.root.get_node_or_null("LocalizationManager")
	return null

func _get_game_state() -> Node:
	if is_inside_tree():
		return get_node_or_null("/root/GameState")
	var ml = Engine.get_main_loop()
	if ml and "root" in ml and ml.root:
		return ml.root.get_node_or_null("GameState")
	return null

func get_localized_name() -> String:
	var loc_mgr = _get_loc_mgr()
	var is_en = (loc_mgr and loc_mgr.get_locale() == "en")
	var s_id = _get_clean_suspect_id()
	var s_name = display_name if display_name != "" else character_name
	var gs = _get_game_state()
	if gs and gs.has_method("get_suspect_data"):
		var s_data = gs.get_suspect_data(s_id)
		if s_data and s_data.has("ad") and s_data["ad"] != "":
			s_name = s_data["ad"]
	if is_en:
		return "Talk: " + s_name
	return s_name + " ile Konuş"

func _get_clean_suspect_id() -> String:
	if sprite_map.has(character_id):
		return sprite_map[character_id]
	var id = character_id.to_lower()
	if "hale" in id: return "hale"
	if "pike" in id: return "pike"
	if "margaret" in id: return "margaret"
	if "julian" in id: return "julian"
	if id.begins_with("npc_"):
		return id.trim_prefix("npc_")
	return id

func interact() -> void:
	var eb = get_node_or_null("/root/EventBus")
	if is_suspect:
		var s_id = _get_clean_suspect_id()
		if s_id != "" and eb and eb.has_signal("interrogation_requested"):
			eb.interrogation_requested.emit(s_id)
			return
	if custom_inner_voice != "":
		if eb and eb.has_signal("inner_voice_requested"):
			eb.inner_voice_requested.emit(custom_inner_voice)
	else:
		if eb and eb.has_signal("inner_voice_requested"):
			var loc_mgr = _get_loc_mgr()
			var is_en = (loc_mgr and loc_mgr.get_locale() == "en")
			var s_name = display_name if display_name != "" else character_name
			var txt = "\"You are speaking with %s.\"" % s_name if is_en else "\"%s ile konuşuyorsun.\"" % s_name
			eb.inner_voice_requested.emit(txt)

func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var im = get_node_or_null("/root/InputManager")
		if im and im.has_signal("interact_target_requested"):
			im.interact_target_requested.emit(self)

func step_aside(target_x: float = 370.0, duration: float = 0.8) -> void:
	var tw = create_tween()
	tw.tween_property(self, "position:x", target_x, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var col = get_node_or_null("CollisionShape2D")
	if col:
		col.set_deferred("disabled", true)
	has_physical_collision = false
	collision_layer = 0
	collision_mask = 0
	set_facing("left")
