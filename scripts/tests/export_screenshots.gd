extends Node

## Helper to capture 1x (320x180) and 4x (1280x720) PNGs of scale_test and all rooms.

const OUT_DIR = "res://screenshots"

var scenes_to_capture = [
	{"id": "scale_test", "path": "res://scenes/tests/scale_test.tscn"},
	{"id": "silas_office", "path": "res://scenes/hub/silas_office.tscn"},
	{"id": "main_hall", "path": "res://scenes/rooms/main_hall.tscn"},
	{"id": "study", "path": "res://scenes/rooms/study.tscn"},
	{"id": "library", "path": "res://scenes/rooms/library.tscn"},
	{"id": "dining_room", "path": "res://scenes/rooms/dining_room.tscn"},
	{"id": "kitchen", "path": "res://scenes/rooms/kitchen.tscn"},
	{"id": "billiard_room", "path": "res://scenes/rooms/billiard_room.tscn"},
	{"id": "upper_floor", "path": "res://scenes/rooms/upper_floor.tscn"}
]

func _ready() -> void:
	var global_out = ProjectSettings.globalize_path(OUT_DIR)
	DirAccess.make_dir_recursive_absolute(global_out)

	print("Exporting screenshots for scale_test and all 8 rooms...")

	# Use a SubViewport of 320x180
	var vp = SubViewport.new()
	vp.size = Vector2i(320, 180)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)

	for item in scenes_to_capture:
		var scene_res = load(item["path"])
		if not scene_res:
			print("Error: Could not load ", item["path"])
			continue
		var inst = scene_res.instantiate()
		vp.add_child(inst)

		# Wait frames for rendering
		for i in range(3):
			await get_tree().process_frame

		var tex = vp.get_texture()
		var img = tex.get_image()

		if img:
			# Save 1x
			var path_1x = global_out + "/" + item["id"] + "_1x.png"
			img.save_png(path_1x)

			# Save 4x nearest
			var img_4x = Image.create(1280, 720, false, Image.FORMAT_RGBA8)
			for y in range(180):
				for x in range(320):
					var col = img.get_pixel(x, y)
					for dy in range(4):
						for dx in range(4):
							img_4x.set_pixel(x * 4 + dx, y * 4 + dy, col)
			var path_4x = global_out + "/" + item["id"] + "_4x.png"
			img_4x.save_png(path_4x)

			print("Saved: ", item["id"], " (1x and 4x)")

		inst.queue_free()
		await get_tree().process_frame

	print("Screenshot export complete!")
	get_tree().quit()
