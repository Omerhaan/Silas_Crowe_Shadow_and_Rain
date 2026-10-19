extends Node

## Automated test suite for the Noir Intro Sequence (Gölge ve Yağmur).

var failed: bool = false

func _ready() -> void:
	call_deferred("_run_all_tests")

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		print("PASS: " + msg)
	else:
		push_error("FAIL: " + msg)
		print("FAIL: " + msg)
		failed = true

func _run_all_tests() -> void:
	print("\n========================================================")
	print(" RUNNING INTRO SEQUENCE AUTOMATED VERIFICATION SUITE ")
	print("========================================================\n")

	test_intro_json_data()
	test_intro_scene_layout_and_margins()
	test_intro_flow_and_input_advance()
	test_intro_skip_button()
	test_audio_and_thunder_trigger()
	test_settings_replay_integration()
	test_save_system_intro_seen_flag()

	print("\n========================================================")
	if failed:
		print(" SOME TESTS FAILED! ")
		print("========================================================\n")
		get_tree().quit(1)
	else:
		print(" ALL INTRO SEQUENCE TESTS PASSED (100%)! ")
		print("========================================================\n")
		get_tree().quit(0)

func test_intro_json_data() -> void:
	print("--- 1. TESTING INTRO JSON STORY DATA ---")
	var path = "res://data/story/intro.json"
	assert_true(FileAccess.file_exists(path), "intro.json exists at data/story/intro.json")

	var file = FileAccess.open(path, FileAccess.READ)
	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	assert_true(err == OK, "intro.json is valid JSON")

	var data = json.data
	var cards: Array = data.get("cards", [])
	assert_true(cards.size() == 8, "intro.json contains exactly 8 cards (found: %d)" % cards.size())

	var expected_texts = [
		"1946. Kış.",
		"Savaş bitti. Şehir, kazananların ve unutanların şehri oldu.",
		"Yağmur üç gündür dinmiyor.",
		"Silas Crowe. Otuz sekiz yaşında. Eski bir istihbaratçı.",
		"Savaştan birkaç ay önce döndü. Kuzey'e giden birliğinden kimseyle bir daha karşılaşmadı.",
		"Resmî kayıtlara göre Kuzey Operasyonu hiç yaşanmadı.",
		"Silas'ın uykusu yok. Gök gürlediğinde elleri titriyor. Nedenini tam olarak hatırlamıyor.",
		"Şehirde ölüm hâlâ iş çıkarıyor. Ve bazı geceler, telefon yanlış kişiyi arıyor."
	]

	for i in range(cards.size()):
		var card = cards[i]
		assert_true(card.get("text", "") == expected_texts[i], "Card %d text matches expected: '%s'" % [i + 1, expected_texts[i]])
		assert_true(card.get("duration", 0.0) >= 3.0, "Card %d has reasonable duration (>= 3.0s)" % [i + 1])

	assert_true(cards[6].get("sfx", "") == "thunder", "Card 7 has remote thunder sfx specified")

	var title_card = data.get("title_card", {})
	assert_true(title_card.get("title", "") == "SILAS CROWE: SHADOW & RAIN", "Title card title is 'SILAS CROWE: SHADOW & RAIN'")
	assert_true(title_card.get("prompt", "") == "Başlamak için dokun", "Title card prompt is 'Başlamak için dokun'")

	var ui_data = data.get("ui", {})
	assert_true(ui_data.get("skip_button", "") == "Atla", "UI skip button text is 'Atla'")

func test_intro_scene_layout_and_margins() -> void:
	print("\n--- 2. TESTING INTRO SCENE LAYOUT, FONTS & MARGINS ---")
	var intro_scene_res = load("res://scenes/intro/intro.tscn")
	assert_true(intro_scene_res != null, "intro.tscn loaded successfully")

	var intro_node = intro_scene_res.instantiate()
	add_child(intro_node)

	var bg: ColorRect = intro_node.get_node("Background")
	assert_true(bg != null and bg.color == Color(0, 0, 0, 1), "Background is pure black Color(0, 0, 0, 1)")

	var card_label: Label = intro_node.get_node("CardContainer/CardLabel")
	assert_true(card_label != null, "CardLabel exists in CardContainer")

	var width = card_label.offset_right - card_label.offset_left
	assert_true(width <= 380.0, "CardLabel max width is ~380 px (found: %.1f)" % width)

	var left_margin = 240.0 + card_label.offset_left
	var right_margin = 480.0 - (240.0 + card_label.offset_right)
	assert_true(left_margin >= 12.0 and right_margin >= 12.0, "CardLabel maintains >= 12 px safe margin (left: %.1f, right: %.1f)" % [left_margin, right_margin])

	var skip_btn: Button = intro_node.get_node("TopBar/SkipButton")
	assert_true(skip_btn != null, "SkipButton exists in TopBar")
	var btn_w = skip_btn.offset_right - skip_btn.offset_left
	var btn_h = skip_btn.offset_bottom - skip_btn.offset_top
	assert_true(btn_w >= 36.0 and btn_h >= 36.0, "SkipButton size meets >= 36x36 requirement (width: %.1f, height: %.1f)" % [btn_w, btn_h])
	assert_true(skip_btn.offset_top >= 12.0, "SkipButton top offset is >= 12 px (found: %.1f)" % skip_btn.offset_top)

	assert_true(card_label.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART or card_label.autowrap_mode == TextServer.AUTOWRAP_WORD, "CardLabel has word autowrap enabled")
	assert_true(card_label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER, "CardLabel horizontal alignment is CENTER")

	intro_node.queue_free()

func test_intro_flow_and_input_advance() -> void:
	print("\n--- 3. TESTING INPUT ADVANCE FLOW THROUGH ALL CARDS ---")
	var intro_scene_res = load("res://scenes/intro/intro.tscn")
	var intro = intro_scene_res.instantiate()
	add_child(intro)
	intro.fade_duration = 0.0

	var card_label: Label = intro.get_node("CardContainer/CardLabel")

	assert_true(intro.current_card_index == 0, "Intro starts at card index 0")
	assert_true(card_label.text == "1946. Kış.", "First card text is '1946. Kış.'")

	# Advance through all 8 cards (cards 0 to 7)
	# Each card: 1st advance finishes fade-in (snaps to DISPLAYING), 2nd advance moves to next card
	for i in range(8):
		intro.advance()
		intro.advance()

	assert_true(intro.current_state == intro.State.TITLE_CARD, "Intro transitioned to TITLE_CARD state after 8 cards")
	var title_lbl: Label = intro.get_node("TitleContainer/TitleVBox/TitleLabel")
	assert_true(title_lbl.text == "SILAS CROWE: SHADOW & RAIN", "Title card shows 'SILAS CROWE: SHADOW & RAIN'")

	var completed = [false]
	intro.intro_completed.connect(func(): completed[0] = true)
	intro.advance()
	assert_true(completed[0], "Title card advance emits intro_completed signal")

	intro.queue_free()

func test_intro_skip_button() -> void:
	print("\n--- 4. TESTING ATLA (SKIP) BUTTON BEHAVIOR ---")
	var intro_scene_res = load("res://scenes/intro/intro.tscn")
	var intro = intro_scene_res.instantiate()
	add_child(intro)
	intro.fade_duration = 0.0

	assert_true(intro.current_card_index == 0, "Intro starts at card 0")
	
	# Press skip button while cards are playing
	intro._on_skip_pressed()
	assert_true(intro.current_state == intro.State.TITLE_CARD, "Pressing Skip jumps directly to TITLE_CARD")

	var completed = [false]
	intro.intro_completed.connect(func(): completed[0] = true)
	intro._on_skip_pressed()
	assert_true(completed[0], "Pressing Skip on TITLE_CARD completes intro immediately")

	intro.queue_free()

func test_audio_and_thunder_trigger() -> void:
	print("\n--- 5. TESTING AUDIO & CARD 7 THUNDER TRIGGER ---")
	var intro_scene_res = load("res://scenes/intro/intro.tscn")
	var intro = intro_scene_res.instantiate()
	add_child(intro)

	assert_true(AudioManager.cached_sounds.has("rain"), "AudioManager has rain stream synthesized")
	assert_true(AudioManager.cached_sounds.has("thunder"), "AudioManager has thunder stream synthesized")

	intro._show_card(6)
	assert_true(intro.current_card_index == 6, "Loaded Card 7 (index 6)")
	assert_true(intro.cards[6].get("text").begins_with("Silas'ın uykusu yok"), "Card 7 text matches 'Silas'ın uykusu yok...'")
	assert_true(AudioManager.thunder_player.stream != null, "Thunder player has stream loaded for card 7")

	intro.queue_free()

func test_settings_replay_integration() -> void:
	print("\n--- 6. TESTING SETTINGS MODAL INTRO REPLAY INTEGRATION ---")
	var sett_res = load("res://scenes/ui/settings_modal.tscn")
	var sett = sett_res.instantiate()
	add_child(sett)

	var replay_btn: Button = sett.get_node_or_null("Panel/VBoxContainer/ReplayIntroBtn")
	assert_true(replay_btn != null, "SettingsModal contains ReplayIntroBtn ('Giriş Hikayesini İzle')")
	assert_true(replay_btn.text.contains("Giriş"), "Button text mentions 'Giriş'")

	var replay_signaled = [false]
	EventBus.intro_replay_requested.connect(func(): replay_signaled[0] = true)
	sett._on_replay_intro_pressed()
	assert_true(replay_signaled[0], "ReplayIntroBtn successfully emits EventBus.intro_replay_requested")

	sett.queue_free()

func test_save_system_intro_seen_flag() -> void:
	print("\n--- 7. TESTING SAVE SYSTEM INTRO_SEEN FLAG ---")
	GameState.intro_seen = true
	SaveSystem.save_game()
	
	GameState.intro_seen = false
	var loaded = SaveSystem.load_game()
	assert_true(loaded, "Save file loaded successfully")
	assert_true(GameState.intro_seen == true, "intro_seen flag was persisted and loaded as true")
