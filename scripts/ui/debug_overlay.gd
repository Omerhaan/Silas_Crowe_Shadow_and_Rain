class_name DebugOverlay
extends CanvasLayer

## In-game Debug Overlay:
## - Toggles with F1 key
## - Top-right "DEBUG" button for touch compatibility (visible in debug builds)
## - Draws colored semi-transparent boxes for all hotspots, doors, NPCs, and evidence
## - Renders readable labels inside/above each box
## - Displays Silas foot line at y=245 and Silas's interaction radius (r=36)

@onready var debug_btn: Button = $DebugButton
@onready var overlay_draw: Control = $OverlayDraw

var is_debug_active: bool = false

func _ready() -> void:
	layer = 25
	# On-screen debug button hidden so it does not distract players
	debug_btn.visible = false
	debug_btn.pressed.connect(toggle_debug)
	overlay_draw.draw.connect(_on_overlay_draw)
	overlay_draw.visible = false
	_update_button_style()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			toggle_debug()
			get_viewport().set_input_as_handled()

func toggle_debug() -> void:
	is_debug_active = !is_debug_active
	overlay_draw.visible = is_debug_active
	_update_button_style()
	if is_debug_active:
		overlay_draw.queue_redraw()

func _update_button_style() -> void:
	if is_debug_active:
		debug_btn.text = "DEBUG [ON]"
		debug_btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4, 1.0))
	else:
		debug_btn.text = "DEBUG"
		debug_btn.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 0.8))

func _process(_delta: float) -> void:
	if is_debug_active:
		overlay_draw.queue_redraw()

func _on_overlay_draw() -> void:
	if not is_debug_active:
		return

	var font = overlay_draw.get_theme_default_font()
	if not font:
		font = ThemeDB.fallback_font

	# 1. Foot Baseline: Red line at y = 245
	overlay_draw.draw_line(Vector2(0, 245), Vector2(480, 245), Color(1.0, 0.2, 0.2, 0.9), 1.5)
	_draw_label(font, Vector2(10, 241), "y=245 [Ayak Cizgisi]", Color(1.0, 0.3, 0.3, 1.0), 6)

	# 2. Silas Crowe Position and Interaction Radius
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player):
		var p_pos = player.global_position
		var interact_center = p_pos + Vector2(0, -25)
		var radius = 36.0

		# Filled green circle + outline
		overlay_draw.draw_circle(interact_center, radius, Color(0.15, 0.85, 0.35, 0.22))
		overlay_draw.draw_arc(interact_center, radius, 0, TAU, 32, Color(0.2, 1.0, 0.45, 0.9), 1.5)

		# Foot position crosshair
		overlay_draw.draw_line(p_pos + Vector2(-6, 0), p_pos + Vector2(6, 0), Color(1.0, 0.9, 0.1, 1.0), 1.5)
		overlay_draw.draw_line(p_pos + Vector2(0, -6), p_pos + Vector2(0, 6), Color(1.0, 0.9, 0.1, 1.0), 1.5)

		# Label
		var silas_text = "Silas (%d, %d) r=%.0f" % [round(p_pos.x), round(p_pos.y), radius]
		_draw_label(font, p_pos + Vector2(-36, -64), silas_text, Color(0.4, 1.0, 0.5, 1.0), 6)

	# 3. Active Room Objects (Doors, NPCs, Evidence, Props, Spawns)
	var main_scene = get_tree().current_scene
	var room_container = main_scene.find_child("RoomContainer", true, false)
	var active_room = room_container.get_child(0) if room_container and room_container.get_child_count() > 0 else null

	if active_room and is_instance_valid(active_room):
		# Collect all nodes
		for child in active_room.get_children():
			if not is_instance_valid(child):
				continue

			# A) Doors
			if "target_room_id" in child:
				_draw_door_box(font, child)

			# B) Characters / NPCs
			elif child.has_method("set_character_texture") or child.is_in_group("npcs"):
				_draw_character_node(font, child)

			# C) Interactables (NPC, Evidence, Prop)
			elif "object_id" in child:
				_draw_interactable_box(font, child)

			# D) Spawn Markers
			elif child is Marker2D and child.name.begins_with("Spawn_"):
				_draw_spawn_marker(font, child)

			# E) Walls / Collisions
			elif child is StaticBody2D:
				_draw_wall_shapes(font, child)

		# F) Temporary Nav Buttons from HUD
		_draw_temporary_nav_buttons(font)

	# 4. Legend info box in top-left
	_draw_legend(font)

func _draw_temporary_nav_buttons(font: Font) -> void:
	var hud = get_tree().get_first_node_in_group("hud")
	if not hud:
		var main_scene = get_tree().current_scene
		hud = main_scene.find_child("HUD", true, false)
	if not hud:
		return

	for btn_name in ["NavLeftButton", "NavRightButton", "NavExtraButton"]:
		var btn: Button = hud.get_node_or_null(btn_name)
		if btn and btn.visible and btn.text.contains("GEÇİCİ"):
			var b_rect = btn.get_global_rect()
			overlay_draw.draw_rect(b_rect, Color(1.0, 0.7, 0.1, 0.35), true)
			overlay_draw.draw_rect(b_rect, Color(1.0, 0.85, 0.2, 0.95), false, 1.5)
			_draw_label(font, Vector2(b_rect.position.x, b_rect.position.y - 2), "[GEÇİCİ GEÇİŞ]", Color(1.0, 0.9, 0.3, 1.0), 6)

func _draw_character_node(font: Font, char_node: Node2D) -> void:
	var c_name = char_node.get("display_name")
	if not c_name or c_name == "":
		c_name = char_node.get("character_name")
	if not c_name or c_name == "":
		c_name = char_node.name

	var box_size = Vector2(36, 102)
	var pos = char_node.global_position
	var rect_pos = Vector2(pos.x - 18, pos.y - 102)
	var rect = Rect2(rect_pos, box_size)

	# Purple semi-transparent
	overlay_draw.draw_rect(rect, Color(0.85, 0.2, 0.85, 0.35), true)
	overlay_draw.draw_rect(rect, Color(1.0, 0.4, 1.0, 0.95), false, 1.5)

	# Foot marker at y=pos.y
	overlay_draw.draw_line(pos + Vector2(-8, 0), pos + Vector2(8, 0), Color(1.0, 0.9, 0.1, 1.0), 1.5)

	var label_text = "[NPC] %s (y=%d)" % [c_name, round(pos.y)]
	_draw_label(font, Vector2(rect_pos.x - 4, rect_pos.y - 3), label_text, Color(1.0, 0.6, 1.0, 1.0), 6)

func _draw_door_box(font: Font, door: Node2D) -> void:
	var shape_col = door.get_node_or_null("CollisionShape2D")
	if not shape_col:
		for c in door.get_children():
			if c is CollisionShape2D:
				shape_col = c
				break

	var box_size = Vector2(44, 80)
	var offset = Vector2(0, -40)
	if shape_col and shape_col.shape is RectangleShape2D:
		box_size = shape_col.shape.size
		offset = shape_col.position

	var rect_pos = door.global_position + offset - (box_size / 2.0)
	var rect = Rect2(rect_pos, box_size)

	var is_locked = door.get("is_locked") or (door.get("target_room_id") == "")
	var is_temp = door.get("is_temporary")

	var fill_color = Color(0.1, 0.55, 1.0, 0.32)
	var border_color = Color(0.2, 0.85, 1.0, 0.95)
	var label_color = Color(0.4, 0.9, 1.0, 1.0)
	var label = ""

	var d_name = door.get("door_name")
	var target_room = door.get("target_room_id")
	var target_spawn = door.get("target_spawn")

	if is_locked:
		fill_color = Color(0.9, 0.2, 0.1, 0.32)
		border_color = Color(1.0, 0.3, 0.2, 0.95)
		label_color = Color(1.0, 0.45, 0.35, 1.0)
		label = "[KİLİTLİ] %s" % d_name
	elif is_temp:
		fill_color = Color(1.0, 0.65, 0.1, 0.35)
		border_color = Color(1.0, 0.8, 0.2, 0.95)
		label_color = Color(1.0, 0.85, 0.3, 1.0)
		label = "[GEÇİCİ] %s -> %s" % [d_name, target_room]
	else:
		label = "[KAPI] %s -> %s" % [d_name, target_room]
		if target_spawn and target_spawn != "default":
			label += " (%s)" % target_spawn

	overlay_draw.draw_rect(rect, fill_color, true)
	overlay_draw.draw_rect(rect, border_color, false, 1.5)

	_draw_label(font, Vector2(rect_pos.x - 4, rect_pos.y - 3), label, label_color, 6)

func _draw_interactable_box(font: Font, obj: Node2D) -> void:
	var obj_id: String = obj.get("object_id")
	var ev_id: String = obj.get("evidence_id")
	var is_npc: bool = obj_id.begins_with("npc_")
	var is_evidence: bool = (ev_id != "")

	var box_size = Vector2(28, 28)
	var offset = Vector2.ZERO

	if "hotspot_size" in obj and obj.get("hotspot_size") != Vector2.ZERO:
		box_size = obj.get("hotspot_size")
	elif is_npc:
		box_size = Vector2(28, 86)
		offset = Vector2(0, -43)

	var area = obj.get_node_or_null("Area2D")
	if area:
		var col = area.get_node_or_null("CollisionShape2D")
		if col and col.shape is RectangleShape2D:
			box_size = col.shape.size
			offset = col.position

	var rect_pos = obj.global_position + offset - (box_size / 2.0)
	var rect = Rect2(rect_pos, box_size)

	var fill_color: Color
	var border_color: Color
	var label_color: Color
	var label_text: String

	if is_evidence:
		fill_color = Color(1.0, 0.82, 0.1, 0.35)
		border_color = Color(1.0, 0.9, 0.2, 0.95)
		label_color = Color(1.0, 0.92, 0.4, 1.0)
		label_text = "[%s] %s" % [ev_id, obj_id]
	elif is_npc:
		fill_color = Color(0.85, 0.2, 0.85, 0.35)
		border_color = Color(1.0, 0.4, 1.0, 0.95)
		label_color = Color(1.0, 0.6, 1.0, 1.0)
		label_text = "[NPC] %s" % obj_id
	else:
		fill_color = Color(1.0, 0.52, 0.1, 0.25)
		border_color = Color(1.0, 0.65, 0.2, 0.85)
		label_color = Color(1.0, 0.75, 0.3, 1.0)
		label_text = obj_id

	overlay_draw.draw_rect(rect, fill_color, true)
	overlay_draw.draw_rect(rect, border_color, false, 1.2)

	_draw_label(font, Vector2(rect_pos.x, rect_pos.y - 2), label_text, label_color, 6)

func _draw_spawn_marker(font: Font, marker: Marker2D) -> void:
	var pos = marker.global_position
	# Small cyan diamond
	var p1 = pos + Vector2(0, -4)
	var p2 = pos + Vector2(4, 0)
	var p3 = pos + Vector2(0, 4)
	var p4 = pos + Vector2(-4, 0)
	overlay_draw.draw_colored_polygon([p1, p2, p3, p4], Color(0.2, 0.9, 0.8, 0.9))
	_draw_label(font, pos + Vector2(6, 3), marker.name, Color(0.3, 1.0, 0.9, 1.0), 6)

func _draw_wall_shapes(font: Font, body: StaticBody2D) -> void:
	for shape_node in body.get_children():
		if shape_node is CollisionShape2D and shape_node.shape is RectangleShape2D:
			var s: Vector2 = shape_node.shape.size
			var rect_pos = shape_node.global_position - (s / 2.0)
			var rect = Rect2(rect_pos, s)
			overlay_draw.draw_rect(rect, Color(0.3, 0.35, 0.45, 0.18), true)
			overlay_draw.draw_rect(rect, Color(0.5, 0.6, 0.75, 0.6), false, 1.0)
			_draw_label(font, Vector2(rect_pos.x + 2, rect_pos.y + 8), shape_node.name, Color(0.6, 0.7, 0.85, 0.8), 6)

func _draw_label(font: Font, pos: Vector2, text: String, color: Color, font_size: int = 6) -> void:
	var text_w = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var bg_rect = Rect2(pos.x - 2, pos.y - font_size + 1, text_w + 4, font_size + 3)
	overlay_draw.draw_rect(bg_rect, Color(0.04, 0.05, 0.08, 0.85), true)
	overlay_draw.draw_rect(bg_rect, Color(color.r, color.g, color.b, 0.4), false, 0.5)
	overlay_draw.draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw_legend(font: Font) -> void:
	var legend_rect = Rect2(4, 26, 210, 14)
	overlay_draw.draw_rect(legend_rect, Color(0.04, 0.06, 0.1, 0.85), true)
	overlay_draw.draw_rect(legend_rect, Color(0.3, 0.4, 0.5, 0.6), false, 1.0)

	var legend_text = "[F1]: Kapat | Mavi: Kapi | Sari: Kanit | Mor: NPC | Turuncu: Prop"
	overlay_draw.draw_string(font, Vector2(8, 36), legend_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(0.9, 0.92, 0.95, 0.9))
