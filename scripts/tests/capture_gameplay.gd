extends Node

func _ready() -> void:
	var vp = SubViewport.new()
	vp.size = Vector2i(480, 270)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)

	var main_scene = load("res://scenes/main.tscn")
	var main = main_scene.instantiate()
	vp.add_child(main)

	# Direct skip to gameplay in silas_office
	if main.story_cutscene:
		main.story_cutscene.visible = false
		CutsceneManager.is_cutscene_active = false
	
	main.load_room("silas_office", "default")
	
	# Simulate telephone ringing
	if main.current_room_node and main.current_room_node.has_method("start_phone_timer"):
		main.current_room_node._on_phone_ring_timeout()

	for i in range(10):
		await get_tree().process_frame

	var tex = vp.get_texture()
	var img = tex.get_image()
	if img:
		var out_dir = ProjectSettings.globalize_path("res://screenshots")
		DirAccess.make_dir_recursive_absolute(out_dir)
		var p1x = out_dir + "/gameplay_office_480x270_1x.png"
		img.save_png(p1x)

		# Also 4x scale
		var img_4x = Image.create(img.get_width() * 4, img.get_height() * 4, false, Image.FORMAT_RGBA8)
		for y in range(img.get_height()):
			for x in range(img.get_width()):
				var c = img.get_pixel(x, y)
				for dy in range(4):
					for dx in range(4):
						img_4x.set_pixel(x * 4 + dx, y * 4 + dy, c)
		var p4x = out_dir + "/gameplay_office_480x270_4x.png"
		img_4x.save_png(p4x)
		print("SUCCESS: Captured gameplay at ", img.get_width(), "x", img.get_height())
	else:
		print("ERROR: Failed to capture texture")

	get_tree().quit(0)
