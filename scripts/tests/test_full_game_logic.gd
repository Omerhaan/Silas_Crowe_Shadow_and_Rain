extends Node

## Comprehensive End-to-End Game Logic, Story, and Mechanics Verification.
## Simulates a complete walkthrough of Case 01: Karanlık Malikâne.

var passed_count: int = 0
var failed_count: int = 0
var main_scene: Node = null

func assert_test(cond: bool, test_name: String) -> void:
	if cond:
		passed_count += 1
		print("  ✔ PASS: %s" % test_name)
	else:
		failed_count += 1
		printerr("  ❌ FAIL: %s" % test_name)

func _ready() -> void:
	print("=====================================================================")
	print("       KAPSAMLI OYUN MEKANİKLERİ VE HİKÂYE MANTIK TESTİ              ")
	print("=====================================================================")

	var main_packed = load("res://scenes/main.tscn")
	assert_test(main_packed != null, "main.tscn yüklenebilir durumda")
	main_scene = main_packed.instantiate()
	add_child(main_scene)
	await get_tree().process_frame
	await get_tree().process_frame

	await _test_prologue_and_hub()
	await _test_room_integrity_and_doors()
	await _test_items_keys_and_evidence()
	await _test_npc_interrogations()
	await _test_deductions_engine()
	await _test_notebook_tabs()
	await _test_accusation_and_endings()
	await _test_save_load_system()

	print("=====================================================================")
	print("TEST SONUCU: %d BAŞARILI, %d HATALI" % [passed_count, failed_count])
	print("=====================================================================")

	if failed_count == 0:
		print("TÜM OYUN MEKANİKLERİ VE HİKÂYE AKIŞI %100 KUSURSUZ!")
	else:
		printerr("BAZI MANTIK HATALARI TESPİT EDİLDİ!")

	get_tree().quit(0 if failed_count == 0 else 1)

func _test_prologue_and_hub() -> void:
	print("\n--- 1. PROLOGUE VE OFİS HUB TESTİ ---")
	main_scene._on_new_game_started()
	await get_tree().process_frame
	main_scene._on_intro_completed()
	CutsceneManager.is_cutscene_active = false
	await get_tree().process_frame

	assert_test(GameState.current_case_id == "case01", "Vaka 1 aktif")
	assert_test(GameState.accusation_chances_left == 3, "Başlangıç şüphe hakkı 3")
	assert_test(GameState.discovered_evidence.is_empty(), "Başlangıçta kanıt listesi temiz")
	assert_test(GameState.unlocked_deductions.is_empty(), "Başlangıçta çıkarımlar temiz")

	if main_scene.hud and main_scene.hud.inner_voice_panel and main_scene.hud.inner_voice_panel.visible:
		main_scene.hud.close_inner_voice()
	await get_tree().process_frame

func _test_room_integrity_and_doors() -> void:
	print("\n--- 2. MEKÂNLAR, KAPILAR VE HAREKET ALANI DOĞRULAMASI ---")
	var room_list = [
		"silas_office", "main_hall", "study", "library", "billiard_room",
		"dining_room", "kitchen", "upper_floor", "harlow_bedroom",
		"julian_room", "pike_room"
	]

	for r_id in room_list:
		main_scene.load_room(r_id, "default")
		await get_tree().process_frame
		await get_tree().process_frame

		var current_r = main_scene.current_room_node
		assert_test(current_r != null, "Oda sahnesi başarıyla yüklendi: " + r_id)

		# Check all doors in the room
		for child in current_r.get_children():
			if child.has_method("interact") and (child.get("target_room_id") != null or child.name.begins_with("Door")):
				var target_room = child.get("target_room_id")
				var target_spawn = child.get("target_spawn")
				if target_room != "" and target_room != null:
					assert_test(room_list.has(target_room), "%s içindeki %s hedef odası geçerli: %s" % [r_id, child.name, target_room])

		# Check default spawn position
		var def_spawn = current_r.get_node_or_null("Spawn_default")
		assert_test(def_spawn != null, "%s varsayılan spawn noktasına sahip" % r_id)
		if def_spawn:
			var spos = def_spawn.global_position
			assert_test(spos.x >= 10.0 and spos.x <= 470.0 and spos.y >= 200.0 and spos.y <= 260.0,
				"%s spawn noktası harita sınırları içinde: %s" % [r_id, str(spos)])

func _test_items_keys_and_evidence() -> void:
	print("\n--- 3. ANAHTAR ZİNCİRİ VE 17 KANITIN TOPLANMASI ---")

	# A. Main Hall: E15 (paspas) & E17 (telefon)
	main_scene.load_room("main_hall", "default")
	await get_tree().process_frame
	var r = main_scene.current_room_node
	var e15 = r.get_node_or_null("Evidence_E15")
	assert_test(e15 != null, "main_hall'de Evidence_E15 mevcut")
	if e15: e15.interact()
	await get_tree().process_frame
	assert_test(GameState.has_evidence("E15"), "E15 başarıyla toplandı (Giriş holü yağmur izi)")

	var e17 = r.get_node_or_null("Evidence_E17")
	assert_test(e17 != null, "main_hall'de Evidence_E17 mevcut")
	if e17: e17.interact()
	await get_tree().process_frame
	assert_test(GameState.has_evidence("E17"), "E17 başarıyla toplandı (Kopuk telefon hattı)")

	# B. Study: E01, E02, E03, E04, E05, E06, E08 (and locked E07)
	main_scene.load_room("study", "default")
	await get_tree().process_frame
	r = main_scene.current_room_node
	for ev_pair in [["Evidence_E01", "E01"], ["Evidence_E02", "E02"], ["Evidence_E03", "E03"],
					["Evidence_E04", "E04"], ["Evidence_E05", "E05"], ["Evidence_E06", "E06"], ["Evidence_E08", "E08"]]:
		var n = r.get_node_or_null(ev_pair[0])
		assert_test(n != null, "study'de %s mevcut" % ev_pair[0])
		if n: n.interact()
		await get_tree().process_frame
		assert_test(GameState.has_evidence(ev_pair[1]), "%s başarıyla toplandı" % ev_pair[1])

	# Check E07 is locked without key_drawer
	var e07 = r.get_node_or_null("Evidence_E07")
	assert_test(e07 != null and e07.required_key_id == "key_drawer", "E07 kilitli ve key_drawer gerektiriyor")
	if e07: e07.interact()
	await get_tree().process_frame
	assert_test(not GameState.has_evidence("E07"), "Anahtar olmadan E07 açılamaz")

	# C. Library: E09 (flakon) & E10 (soğuk şömine)
	main_scene.load_room("library", "default")
	await get_tree().process_frame
	r = main_scene.current_room_node
	var e09 = r.get_node_or_null("Evidence_E09")
	assert_test(e09 != null, "library'de Evidence_E09 mevcut")
	if e09: e09.interact()
	await get_tree().process_frame
	assert_test(GameState.has_evidence("E09"), "E09 başarıyla toplandı (Boş digitalis flakonu)")

	var e10 = r.get_node_or_null("Evidence_E10")
	assert_test(e10 != null, "library'de Evidence_E10 mevcut")
	if e10: e10.interact()
	await get_tree().process_frame
	assert_test(GameState.has_evidence("E10"), "E10 başarıyla toplandı (Soğuk şömine)")

	# D. Billiard Room: E11 & Item_Key_Chest
	main_scene.load_room("billiard_room", "default")
	await get_tree().process_frame
	r = main_scene.current_room_node
	var e11 = r.get_node_or_null("Evidence_E11")
	assert_test(e11 != null, "billiard_room'da Evidence_E11 mevcut")
	if e11: e11.interact()
	await get_tree().process_frame
	assert_test(GameState.has_evidence("E11"), "E11 başarıyla toplandı (2 kadeh ve tek iz)")

	var item_chest_key = r.get_node_or_null("Item_Key_Chest")
	assert_test(item_chest_key != null, "billiard_room'da Item_Key_Chest mevcut")
	if item_chest_key: item_chest_key.interact()
	await get_tree().process_frame
	assert_test(GameState.has_item("key_chest"), "key_chest envantere eklendi")

	# E. Kitchen: E14
	main_scene.load_room("kitchen", "default")
	await get_tree().process_frame
	r = main_scene.current_room_node
	var e14 = r.get_node_or_null("Evidence_E14")
	assert_test(e14 != null, "kitchen'da Evidence_E14 mevcut")
	if e14: e14.interact()
	await get_tree().process_frame
	assert_test(GameState.has_evidence("E14"), "E14 başarıyla toplandı (Margaret kovulma bildirimi)")

	# F. Upper Floor: Door_To_Pike locked with key_ring
	main_scene.load_room("upper_floor", "default")
	await get_tree().process_frame
	r = main_scene.current_room_node
	var pike_door = r.get_node_or_null("Door_To_Pike")
	assert_test(pike_door != null and pike_door.is_locked, "Door_To_Pike kilitli")
	assert_test(pike_door.required_key_id == "key_ring", "Door_To_Pike key_ring gerektiriyor")

	# G. Julian's Room: E12 locked with key_chest
	main_scene.load_room("julian_room", "default")
	await get_tree().process_frame
	r = main_scene.current_room_node
	var e12 = r.get_node_or_null("Evidence_E12")
	assert_test(e12 != null and e12.required_key_id == "key_chest", "Evidence_E12 key_chest gerektiriyor")
	if e12: e12.interact()
	await get_tree().process_frame
	assert_test(GameState.has_evidence("E12"), "E12 key_chest ile başarıyla açıldı ve toplandı (Kumar borcu)")

	# H. Harlow Bedroom: Item_Key_Drawer & Evidence_E16
	main_scene.load_room("harlow_bedroom", "default")
	await get_tree().process_frame
	r = main_scene.current_room_node
	var item_drawer_key = r.get_node_or_null("Item_Key_Drawer")
	assert_test(item_drawer_key != null, "harlow_bedroom'da Item_Key_Drawer mevcut")
	if item_drawer_key: item_drawer_key.interact()
	await get_tree().process_frame
	assert_test(GameState.has_item("key_drawer"), "key_drawer envantere eklendi")

	var e16 = r.get_node_or_null("Evidence_E16")
	assert_test(e16 != null, "harlow_bedroom'da Evidence_E16 mevcut")
	if e16: e16.interact()
	await get_tree().process_frame
	assert_test(GameState.has_evidence("E16"), "E16 başarıyla toplandı (Kuzey 1944 birlik fotoğrafı)")

	# I. Unlock Study E07 with key_drawer
	main_scene.load_room("study", "default")
	await get_tree().process_frame
	r = main_scene.current_room_node
	e07 = r.get_node_or_null("Evidence_E07")
	if e07: e07.interact()
	await get_tree().process_frame
	assert_test(GameState.has_evidence("E07"), "E07 key_drawer ile açıldı ve toplandı (Tehdit mektupları)")

func _test_npc_interrogations() -> void:
	print("\n--- 4. NPC SORGULARI VE MARGARET'TAN ANAHTAR ALMA ---")
	var interrog = main_scene.ui_overlays.get_node("Interrogation")
	assert_test(interrog != null, "Interrogation paneli mevcut")

	# Talk to Margaret in kitchen -> get key_ring
	main_scene.load_room("kitchen", "default")
	await get_tree().process_frame
	var r = main_scene.current_room_node
	var margaret = r.get_node_or_null("NPC_Margaret")
	assert_test(margaret != null, "kitchen'da NPC_Margaret mevcut")

	interrog.open_interrogation("margaret")
	await get_tree().process_frame
	assert_test(interrog.visible, "Margaret sorgu paneli açıldı")

	# Select 'keys' topic to receive key_ring
	interrog._on_topic_selected({
		"id": "keys",
		"label": "Yedek Anahtarlar",
		"response": "Alın dedektif, misafir odalarının anahtarlığı.",
		"item_yield": "key_ring",
		"item_yield_name": "Kâhyanın Anahtarlığı"
	})
	await get_tree().process_frame
	assert_test(GameState.has_item("key_ring"), "Margaret'tan key_ring alındı ve envantere eklendi")
	interrog._on_exit_pressed()
	await get_tree().process_frame

	# Now unlock Upper Floor Door_To_Pike with key_ring and get E13
	main_scene.load_room("upper_floor", "default")
	await get_tree().process_frame
	r = main_scene.current_room_node
	var pike_door = r.get_node_or_null("Door_To_Pike")
	if pike_door: pike_door.interact()
	await get_tree().process_frame
	assert_test(not pike_door.is_locked, "Door_To_Pike key_ring ile kilit açıldı")

	# Enter Pike room and collect E13
	main_scene.load_room("pike_room", "default")
	await get_tree().process_frame
	r = main_scene.current_room_node
	var e13 = r.get_node_or_null("Evidence_E13")
	assert_test(e13 != null, "pike_room'da Evidence_E13 mevcut")
	if e13: e13.interact()
	await get_tree().process_frame
	assert_test(GameState.has_evidence("E13"), "E13 başarıyla toplandı (Pike'ın daktilosu ve şeridi)")

	# Verify all 17 evidence collected!
	var all_17 = ["E01", "E02", "E03", "E04", "E05", "E06", "E07", "E08", "E09", "E10", "E11", "E12", "E13", "E14", "E15", "E16", "E17"]
	var missing = []
	for e_id in all_17:
		if not GameState.has_evidence(e_id):
			missing.append(e_id)
	assert_test(missing.is_empty(), "17 Kanıtın 17'si de toplandı (Eksik: %s)" % str(missing))

func _test_deductions_engine() -> void:
	print("\n--- 5. DEDÜKSİYON (ÇIKARIM) MOTORU VE MANTIK DOĞRULAMASI ---")

	# Invalid pair test
	var invalid_result = GameState.check_deduction_pair("E01", "E14")
	assert_test(invalid_result.is_empty(), "Alakasız kanıt çifti (E01 + E14) dedüksiyon vermez")

	# Test all 10 deductions
	var ded_cases = [
		{"pair": ["E02", "E15"], "expected": "D1", "name": "İçeriden Kilitlenen Kapı"},
		{"pair": ["E04", "E05"], "expected": "D2", "name": "Gecikmeli Zehirlenme Yöntemi"},
		{"pair": ["E01", "E08"], "expected": "D3", "name": "Sahte Ölüm Saati"},
		{"pair": ["D3", "E03"], "expected": "D4", "name": "Gerçek Cinayet Penceresi"},
		{"pair": ["E06", "E05"], "expected": "D5", "name": "Dr. Hale'in Yalanı"},
		{"pair": ["E09", "E10"], "expected": "D6", "name": "Kütüphane Alibisinin Çöküşü"},
		{"pair": ["D1", "D2"], "expected": "D7", "name": "Nihai Çıkarım: Katil Dr. Hale"},
		{"pair": ["E07", "E13"], "expected": "D8", "name": "Tehdit Mektuplarının Kaynağı"},
		{"pair": ["E11", "E12"], "expected": "D9", "name": "Julian'ın Yalan Alibisi"},
		{"pair": ["E17", "E15"], "expected": "D10", "name": "İmkânsız Telefon Araması"}
	]

	for tc in ded_cases:
		var res = GameState.check_deduction_pair(tc["pair"][0], tc["pair"][1])
		var did = res.get("id", "")
		if did != "":
			GameState.unlock_deduction(did)
		assert_test(did == tc["expected"] or GameState.unlocked_deductions.has(tc["expected"]),
			"%s başarıyla çıkarıldı: %s" % [tc["expected"], tc["name"]])

	assert_test(GameState.unlocked_deductions.size() >= 10, "En az 10 çıkarım tamamlandı (Toplam: %d)" % GameState.unlocked_deductions.size())

func _test_notebook_tabs() -> void:
	print("\n--- 6. DEFTER (NOTEBOOK) 6 SEKME VE ARAYÜZ TESTİ ---")
	var notebook = main_scene.ui_overlays.get_node_or_null("Notebook")
	assert_test(notebook != null, "Notebook paneli mevcut")
	if not notebook:
		return

	var inspect_view = main_scene.ui_overlays.get_node_or_null("InspectView")
	if inspect_view and inspect_view.visible:
		inspect_view.close_inspect()
		await get_tree().process_frame

	CutsceneManager.is_cutscene_active = false
	notebook.open_notebook()
	await get_tree().process_frame
	assert_test(notebook.visible, "Defter açıldı")

	# Test all 6 tabs via tab_container
	var tab_names = ["Kanıtlar", "İfadeler", "Zaman", "Çıkarım", "Şüpheliler", "Harita"]
	for i in range(tab_names.size()):
		notebook.tab_container.current_tab = i
		await get_tree().process_frame
		assert_test(notebook.tab_container.current_tab == i, "Defter sekmesine geçildi: [%d] %s" % [i, tab_names[i]])

	notebook.close_notebook()
	await get_tree().process_frame
	assert_test(not notebook.visible, "Defter kapatıldı")

func _test_accusation_and_endings() -> void:
	print("\n--- 7. SUÇLAMA MODALI, YÜZLEŞME VE OYUN SONU AKIŞI ---")
	var accuse_modal = main_scene.ui_overlays.get_node("AccusationModal")
	var confrontation = main_scene.ui_overlays.get_node("ConfrontationHale")
	var ending_modal = main_scene.ui_overlays.get_node("CaseEndingModal")

	assert_test(accuse_modal != null, "AccusationModal mevcut")
	assert_test(confrontation != null, "ConfrontationHale mevcut")
	assert_test(ending_modal != null, "CaseEndingModal mevcut")

	accuse_modal.open_accusation()
	await get_tree().process_frame
	assert_test(accuse_modal.visible, "Suçlama modalı açıldı")

	# Test Wrong Accusation: Julian with bludgeoning
	accuse_modal.selected_suspect_id = "julian"
	accuse_modal.selected_method_id = "blunt"
	accuse_modal.selected_evidence_ids.clear()
	accuse_modal.selected_evidence_ids.append("E11")
	accuse_modal.selected_evidence_ids.append("E12")
	accuse_modal._on_accuse_pressed()
	await get_tree().process_frame
	assert_test(GameState.accusation_chances_left == 2, "Hatalı suçlamada hak 2'ye düştü")
	assert_test(not GameState.case_solved, "Hatalı suçlamada vaka çözülmedi")

	# Test True Accusation: Dr. Hale + Poison + key clues
	accuse_modal.selected_suspect_id = "hale"
	accuse_modal.selected_method_id = "poison"
	accuse_modal.selected_evidence_ids.clear()
	accuse_modal.selected_evidence_ids.append("E06")
	accuse_modal.selected_evidence_ids.append("E09")
	accuse_modal.selected_evidence_ids.append("E04")
	accuse_modal._on_accuse_pressed()
	await get_tree().process_frame

	assert_test(not accuse_modal.visible, "Doğru suçlamada modal kapandı")
	assert_test(confrontation.visible, "Yüzleşme sahnesi (ConfrontationHale) açıldı")

	# Step through confrontation dialogue
	while confrontation.visible and confrontation.current_line_index < confrontation.lines.size():
		confrontation._on_next_pressed()
		await get_tree().process_frame

	assert_test(GameState.case_solved == true, "Vaka 1 başarıyla çözüldü (case_solved == true)")
	assert_test(GameState.completed_cases.has("case01"), "completed_cases içinde case01 yer alıyor")
	assert_test(ending_modal.visible, "Gazete manşeti ve dedektif değerlendirme ekranı (CaseEndingModal) açıldı")

	# Test Ending Modal stages (Newspaper -> Rating -> Credits)
	assert_test(ending_modal.current_stage == 1, "Aşama 1: 1946 Gazete manşeti gösteriliyor")
	ending_modal._on_newspaper_next()
	await get_tree().process_frame
	assert_test(ending_modal.current_stage == 2, "Aşama 2: Dedektif Rütbe ve Skor kartı gösteriliyor")
	ending_modal._on_rating_next()
	await get_tree().process_frame
	assert_test(ending_modal.current_stage == 3, "Aşama 3: Jenerik (Credits) ve Ofise Dönüş butonları gösteriliyor")

	# Test return to office and post-credits second call flow
	ending_modal._on_return_office_pressed()
	await get_tree().create_timer(0.5).timeout
	assert_test(GameState.current_room_id == "silas_office", "Ofise başarıyla dönüldü")
	var second_call = main_scene.get_node_or_null("UIOverlays/SecondCall")
	if main_scene.current_room_node and main_scene.current_room_node.has_method("answer_phone"):
		main_scene.current_room_node.answer_phone()
		await get_tree().process_frame
		assert_test(second_call.visible == true, "Jenerik sonrası gizemli ikinci arama (SecondCall) tetiklendi")
		assert_test(not main_scene.phone_call_dialogue.visible, "Eski giriş araması (phone_call.json) tetiklenmedi")
		second_call._on_hangup_pressed()
		await get_tree().process_frame
		assert_test(second_call.summary_box.visible == true, "Vaka tamamlama özet kutusu açıldı")
		second_call._on_continue_pressed()
		await get_tree().process_frame
		assert_test(not second_call.visible, "İkinci arama başarıyla kapandı, oyuncu ofiste kaldı")
		assert_test(GameState.current_room_id == "silas_office", "Oyun malikâneye geri dönmedi, ofiste kalındı")

func _test_save_load_system() -> void:
	print("\n--- 8. KAYIT VE YÜKLEME (SAVE/LOAD) TESTİ ---")
	var save_ok = SaveSystem.save_game()
	assert_test(save_ok, "SaveSystem.save_game() başarılı")
	assert_test(SaveSystem.has_save_file(), "savegame.json dosyası mevcut")

	# Temporarily clear GameState
	GameState.discovered_evidence = []
	GameState.case_solved = false

	# Load game
	var load_ok = SaveSystem.load_game()
	assert_test(load_ok, "SaveSystem.load_game() başarılı")
	assert_test(GameState.discovered_evidence.size() >= 17, "Kayıt dosyasından 17 kanıt başarıyla geri yüklendi")
	assert_test(GameState.case_solved == true, "Kayıt dosyasından vaka çözülme durumu başarıyla geri yüklendi")
	assert_test(GameState.completed_cases.has("case01"), "Tamamlanan vakalar listesi korundu")
