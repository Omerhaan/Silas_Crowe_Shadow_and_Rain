extends Node2D

## Automated test for top AchievementBanner display.

func _ready() -> void:
	print("\n========================================================")
	print(" RUNNING TOP ACHIEVEMENT BANNER DISPLAY TEST ")
	print("========================================================\n")

	var failed = false

	var hud_scene = load("res://scenes/ui/hud.tscn")
	var hud = hud_scene.instantiate()
	add_child(hud)

	await get_tree().physics_frame
	await get_tree().physics_frame

	var banner = hud.get_node_or_null("AchievementBanner")
	if not banner:
		print("FAIL: AchievementBanner node not found in HUD!")
		get_tree().quit(1)
		return

	print("Initial banner visible: %s" % banner.visible)
	print("Banner top offset: %.1f (expected >= 40)" % banner.offset_top)
	if banner.offset_top < 40.0:
		print("FAIL: Banner is not positioned at the top of the screen!")
		failed = true
	else:
		print("PASS: Banner is positioned at the top (y=%.1f) below TopBar" % banner.offset_top)

	# Trigger achievement unlock
	print("\nUnlocking achievement A06 (Sessiz Gözlemci)...")
	GameState.unlock_achievement("A06")

	await get_tree().physics_frame

	print("After unlock:")
	print("  banner.visible = %s" % banner.visible)
	var title_lbl = hud.get_node_or_null("AchievementBanner/MarginContainer/HBoxContainer/VBoxContainer/TitleLabel")
	var desc_lbl = hud.get_node_or_null("AchievementBanner/MarginContainer/HBoxContainer/VBoxContainer/DescLabel")
	print("  title = '%s'" % (title_lbl.text if title_lbl else ""))
	print("  desc = '%s'" % (desc_lbl.text if desc_lbl else ""))

	if banner.visible and title_lbl and title_lbl.text.contains("Sessiz Gözlemci"):
		print("PASS: AchievementBanner is VISIBLE at the top with correct title!")
	else:
		print("FAIL: AchievementBanner did not show with correct title!")
		failed = true

	if desc_lbl and desc_lbl.text.contains("10"):
		print("PASS: AchievementBanner displays full description!")
	else:
		print("FAIL: Description not displayed properly!")
		failed = true

	# Test timer countdown
	hud._process(5.1)
	print("After 5.1s timer countdown:")
	print("  banner.visible = %s" % banner.visible)
	if not banner.visible:
		print("PASS: AchievementBanner hidden automatically after timer expired!")
	else:
		print("FAIL: AchievementBanner did not hide after timer expired!")
		failed = true

	hud.free()

	print("\n========================================================")
	if failed:
		print(" SOME TESTS FAILED!")
		print("========================================================\n")
		get_tree().quit(1)
	else:
		print(" ALL ACHIEVEMENT BANNER TESTS PASSED (100%)! ")
		print("========================================================\n")
		get_tree().quit(0)
