extends Node

## Unit test for Dynamic Room & Case Music System in AudioManager.

var passed: int = 0
var total: int = 0

func assert_test(cond: bool, msg: String) -> void:
	total += 1
	if cond:
		passed += 1
		print("✔ [%d] %s" % [total, msg])
	else:
		printerr("❌ [%d] FAILED: %s" % [total, msg])

func _ready() -> void:
	print("\n=======================================================")
	print("       DYNAMIC ROOM & CASE MUSIC SYSTEM TEST           ")
	print("=======================================================")

	# 1. Verify AudioManager and room music mapping
	assert_test(AudioManager != null, "AudioManager autoload singleton exists")
	assert_test(AudioManager.ROOM_MUSIC_MAP.size() >= 20, "ROOM_MUSIC_MAP has at least 20 mapped rooms")

	# 2. Check room coverage across Hub, Case 1, Case 2, and Case 3
	assert_test(AudioManager.ROOM_MUSIC_MAP.has("silas_office"), "Hub office is mapped to noir_office")
	assert_test(AudioManager.ROOM_MUSIC_MAP["silas_office"] == "noir_office", "silas_office maps to noir_office track")
	assert_test(AudioManager.ROOM_MUSIC_MAP["main_hall"] == "manor_hall", "main_hall maps to manor_hall track")
	assert_test(AudioManager.ROOM_MUSIC_MAP["study"] == "manor_crime", "study maps to manor_crime track")
	assert_test(AudioManager.ROOM_MUSIC_MAP["dock_pier"] == "docks_fog", "dock_pier maps to docks_fog track")
	assert_test(AudioManager.ROOM_MUSIC_MAP["dock_tavern"] == "docks_tavern", "dock_tavern maps to docks_tavern track")
	assert_test(AudioManager.ROOM_MUSIC_MAP["opera_foyer"] == "opera_foyer", "opera_foyer maps to opera_foyer track")
	assert_test(AudioManager.ROOM_MUSIC_MAP["opera_auditorium"] == "opera_aria", "opera_auditorium maps to opera_aria track")
	assert_test(AudioManager.ROOM_MUSIC_MAP["opera_roof"] == "opera_roof", "opera_roof maps to opera_roof track")

	# 3. Stream resolution and fallback verification
	var base_stream = AudioManager.get_music_stream("manor_hall")
	assert_test(base_stream != null, "manor_hall returns a valid AudioStream")

	var tracks_to_check = [
		"noir_office", "manor_crime", "docks_fog", "docks_tavern",
		"opera_foyer", "opera_aria", "opera_roof", "tension_confront", "ending_credits"
	]
	for t_name in tracks_to_check:
		var st = AudioManager.get_music_stream(t_name)
		var is_loaded = AudioManager.cached_sounds.has("music_" + t_name)
		assert_test(is_loaded and st != null, "Dedicated audio file for %s is loaded into AudioManager" % t_name)

	var fallback_stream = AudioManager.get_music_stream("non_existent_track")
	assert_test(fallback_stream != null, "Non-existent track safely falls back to default music stream")

	# 4. Play and crossfade verification
	AudioManager.play_music("manor_hall", 0.1)
	assert_test(AudioManager.current_track == "manor_hall", "AudioManager.current_track is updated to manor_hall")
	assert_test(AudioManager.music_player.playing or AudioManager.music_player_b.playing, "A music player is currently playing")

	# 5. Room change trigger
	EventBus.room_changed.emit("study")
	await get_tree().create_timer(0.2).timeout
	assert_test(AudioManager.current_track == "manor_crime", "Entering study switches track to manor_crime")

	# 6. Interrogation tension override and restore
	EventBus.interrogation_requested.emit("hale")
	await get_tree().create_timer(0.2).timeout
	assert_test(AudioManager.current_track == "tension_confront", "Interrogation triggers tension_confront music")
	assert_test(AudioManager.is_tension_override == true, "Tension override flag is active during interrogation")

	EventBus.interrogation_finished.emit()
	await get_tree().create_timer(0.2).timeout
	assert_test(AudioManager.current_track == "manor_crime", "Finishing interrogation restores previous room track")
	assert_test(AudioManager.is_tension_override == false, "Tension override is deactivated")

	print("\n=======================================================")
	print("       RESULT: %d / %d TESTS PASSED                    " % [passed, total])
	print("=======================================================\n")

	get_tree().quit(0 if passed == total else 1)
