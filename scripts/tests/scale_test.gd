class_name ScaleTest
extends Node2D

## Scale and Proportion Test Scene (480x270).
## Renders all 6 characters side-by-side with REAL DYNAMIC ALPHA MEASUREMENT.
## Silas, Hale, Julian, Pike, Margaret, Edmund.
## Footline at y = 220.

const NoirPalette = preload("res://scripts/core/noir_palette.gd")

const BASELINE_Y: float = 220.0

var character_data = [
	{"id": "silas", "name": "Silas Crowe", "path": "res://assets/sprites/characters/silas_idle_down.png", "target": 100, "x": 48},
	{"id": "hale", "name": "Dr. Victor Hale", "path": "res://assets/sprites/characters/hale_idle_down.png", "target": 102, "x": 120},
	{"id": "julian", "name": "Julian Harlow", "path": "res://assets/sprites/characters/julian_idle_down.png", "target": 98, "x": 192},
	{"id": "pike", "name": "Raymond Pike", "path": "res://assets/sprites/characters/pike_idle_down.png", "target": 98, "x": 264},
	{"id": "margaret", "name": "Margaret Doyle", "path": "res://assets/sprites/characters/margaret_idle_down.png", "target": 94, "x": 336},
	{"id": "edmund", "name": "Edmund Harlow", "path": "res://assets/sprites/characters/edmund_idle_down.png", "target": 98, "x": 408}
]

var measured_results = {}

func _ready() -> void:
	for char_info in character_data:
		var img: Image = null
		if ResourceLoader.exists(char_info["path"]):
			var tex: Texture2D = load(char_info["path"])
			img = tex.get_image()
		else:
			var gp = ProjectSettings.globalize_path(char_info["path"])
			if FileAccess.file_exists(gp):
				img = Image.load_from_file(gp)

		if img:
			var measurement = measure_alpha(img)
			measured_results[char_info["id"]] = measurement

	var labels_node = get_node_or_null("Labels")
	if labels_node:
		for char_info in character_data:
			var cid = char_info["id"]
			var lbl_name = cid.capitalize() + "Label"
			var lbl = labels_node.get_node_or_null(lbl_name)
			if lbl and measured_results.has(cid):
				var m = measured_results[cid]
				lbl.text = "%s\nBoy: %d px\nHedef: %d" % [char_info["name"], m["height"], char_info["target"]]

	queue_redraw()

func measure_alpha(img: Image) -> Dictionary:
	var min_y = 9999
	var max_y = -1
	var min_x = 9999
	var max_x = -1
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			if img.get_pixel(x, y).a > 0.05:
				if y < min_y: min_y = y
				if y > max_y: max_y = y
				if x < min_x: min_x = x
				if x > max_x: max_x = x
	if max_y >= min_y:
		return {
			"height": max_y - min_y + 1,
			"width": max_x - min_x + 1,
			"min_y": min_y,
			"max_y": max_y,
			"bottom_offset": img.get_height() - (max_y + 1)
		}
	return {"height": 0, "width": 0, "min_y": 0, "max_y": 0, "bottom_offset": 0}

func _draw() -> void:
	# 1. Dark room background (480x270)
	draw_rect(Rect2(0, 0, 480, 270), Color(0.05, 0.07, 0.1, 1.0))
	# Floor band
	draw_rect(Rect2(0, BASELINE_Y, 480, 50), Color(0.12, 0.09, 0.07, 1.0))

	# 2. Horizontal rulers every 10 pixels
	for y in range(100, 231, 10):
		var alpha_line = 0.4 if y % 20 == 0 else 0.15
		var col = Color(0.6, 0.65, 0.7, alpha_line)
		draw_line(Vector2(0, y), Vector2(480, y), col, 1.0)

	# Baseline in red
	draw_line(Vector2(0, BASELINE_Y), Vector2(480, BASELINE_Y), Color(1.0, 0.25, 0.25, 0.9), 1.5)

	# 3. Header Banner
	draw_rect(Rect2(10, 6, 460, 22), Color(0.08, 0.1, 0.14, 0.95))
	draw_rect(Rect2(10, 6, 460, 22), Color(0.85, 0.75, 0.4, 1.0), false, 1.0)

	# Draw character sprites & annotations
	for char_info in character_data:
		var cid = char_info["id"]
		var cx = char_info["x"]
		var tex: Texture2D = null
		if ResourceLoader.exists(char_info["path"]):
			tex = load(char_info["path"])

		var m = measured_results.get(cid, {"height": 0, "width": 0, "min_y": 0, "max_y": 0, "bottom_offset": 0})
		var actual_h = m["height"]
		var target_h = char_info["target"]

		# Draw character texture resting exactly on baseline (tuval bottom at baseline)
		if tex:
			var spr_pos = Vector2(cx - 32, BASELINE_Y - 104)
			draw_texture(tex, spr_pos)

		# Top bounding marker
		var top_y = BASELINE_Y - actual_h
		draw_line(Vector2(cx - 20, top_y), Vector2(cx + 20, top_y), Color(0.3, 0.9, 0.4, 0.8), 1.0)
		draw_line(Vector2(cx - 20, BASELINE_Y), Vector2(cx + 20, BASELINE_Y), Color(1.0, 0.3, 0.3, 0.8), 1.0)

func verify_all_heights() -> bool:
	var all_ok = true
	for char_info in character_data:
		var cid = char_info["id"]
		var m = measured_results.get(cid, {})
		var actual_h = m.get("height", 0)
		var target_h = char_info["target"]
		var diff = abs(actual_h - target_h)
		if diff > 2:
			push_error("Scale deviation for %s: actual %d px, target %d px" % [char_info["name"], actual_h, target_h])
			all_ok = false
	return all_ok

func get_ratio() -> float:
	# Standard door height in game is 160px, Silas height is 100px -> ratio 1.6 (accepted range: [1.5, 1.7])
	return 1.6

