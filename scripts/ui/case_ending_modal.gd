extends Control

## Case Ending, Evaluation & Credits Modal.
## Displays:
## 1. 1946 Vintage Newspaper Headline (Kara Vadi Postası / The Daily Chronicle)
## 2. Detective Evaluation & Rank Badge (S / A / B Rating)
## 3. Atmospheric Noir Credits Roll with Return buttons.

@onready var newspaper_panel: PanelContainer = $NewspaperPanel
@onready var paper_name_lbl: Label = $NewspaperPanel/MarginContainer/VBox/HeaderBox/PaperName
@onready var paper_date_lbl: Label = $NewspaperPanel/MarginContainer/VBox/HeaderBox/PaperDate
@onready var headline_lbl: Label = $NewspaperPanel/MarginContainer/VBox/Headline
@onready var subhead_lbl: Label = $NewspaperPanel/MarginContainer/VBox/Subhead
@onready var article_lbl: Label = $NewspaperPanel/MarginContainer/VBox/BodyHBox/ArticleText
@onready var photo_rect: TextureRect = $NewspaperPanel/MarginContainer/VBox/BodyHBox/PhotoBox/PhotoTexture
@onready var newspaper_next_btn: Button = $NewspaperPanel/MarginContainer/VBox/NewspaperNextBtn

@onready var rating_panel: PanelContainer = $RatingPanel
@onready var report_title_lbl: Label = $RatingPanel/MarginContainer/VBox/ReportTitle
@onready var stat_clues_lbl: Label = $RatingPanel/MarginContainer/VBox/StatsGrid/StatClues
@onready var stat_deds_lbl: Label = $RatingPanel/MarginContainer/VBox/StatsGrid/StatDeds
@onready var stat_acc_lbl: Label = $RatingPanel/MarginContainer/VBox/StatsGrid/StatAcc
@onready var stat_drawers_lbl: Label = $RatingPanel/MarginContainer/VBox/StatsGrid/StatDrawers
@onready var rank_badge_lbl: Label = $RatingPanel/MarginContainer/VBox/RankBadge
@onready var rank_title_lbl: Label = $RatingPanel/MarginContainer/VBox/RankTitle
@onready var monologue_lbl: Label = $RatingPanel/MarginContainer/VBox/SilasMonologue
@onready var rating_next_btn: Button = $RatingPanel/MarginContainer/VBox/RatingNextBtn

@onready var credits_panel: PanelContainer = $CreditsPanel
@onready var credits_title_lbl: Label = $CreditsPanel/MarginContainer/VBox/CreditsTitle
@onready var credits_sub_lbl: Label = $CreditsPanel/MarginContainer/VBox/CreditsSub
@onready var credits_body_lbl: Label = $CreditsPanel/MarginContainer/VBox/CreditsBody
@onready var next_case_btn: Button = $CreditsPanel/MarginContainer/VBox/ButtonsHBox/NextCaseBtn
@onready var return_office_btn: Button = $CreditsPanel/MarginContainer/VBox/ButtonsHBox/ReturnOfficeBtn
@onready var main_menu_btn: Button = $CreditsPanel/MarginContainer/VBox/ButtonsHBox/MainMenuBtn

var current_stage: int = 1
var is_active: bool = false
var input_cooldown: float = 0.0

func _ready() -> void:
	visible = false
	newspaper_panel.visible = false
	rating_panel.visible = false
	credits_panel.visible = false

	if newspaper_next_btn:
		newspaper_next_btn.pressed.connect(_on_newspaper_next)
	if rating_next_btn:
		rating_next_btn.pressed.connect(_on_rating_next)
	if next_case_btn:
		next_case_btn.pressed.connect(_on_next_case_pressed)
	if return_office_btn:
		return_office_btn.pressed.connect(_on_return_office_pressed)
	if main_menu_btn:
		main_menu_btn.pressed.connect(_on_main_menu_pressed)

	EventBus.case_ending_requested.connect(start_ending_sequence)

func _process(delta: float) -> void:
	if input_cooldown > 0.0:
		input_cooldown -= delta

func _input(event: InputEvent) -> void:
	if not visible or not is_active:
		return
	if input_cooldown > 0.0:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_E:
			if current_stage == 1:
				_on_newspaper_next()
				get_viewport().set_input_as_handled()
			elif current_stage == 2:
				_on_rating_next()
				get_viewport().set_input_as_handled()

func start_ending_sequence() -> void:
	visible = true
	is_active = true
	current_stage = 1
	input_cooldown = 0.3
	GameState.can_player_move = false

	# Play noir piano music
	AudioManager.play_music("noir_piano")

	_show_stage(1)

func _show_stage(stage_idx: int) -> void:
	current_stage = stage_idx
	newspaper_panel.visible = (stage_idx == 1)
	rating_panel.visible = (stage_idx == 2)
	credits_panel.visible = (stage_idx == 3)
	input_cooldown = 0.25

	if stage_idx == 1:
		_populate_newspaper()
	elif stage_idx == 2:
		_populate_rating()
	elif stage_idx == 3:
		_populate_credits()

func _populate_newspaper() -> void:
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = (loc_mgr and loc_mgr.get_locale() == "en")

	if GameState.current_case_id == "case02":
		paper_name_lbl.text = "GREYWATER RIHTIMI POSTASI" if not is_en else "THE GREYWATER CHRONICLE"
		paper_date_lbl.text = "28 KASIM 1946 — ÖZEL BASKI" if not is_en else "NOVEMBER 28, 1946 — SPECIAL EDITION"
		headline_lbl.text = "RIHTIM CİNAYETİ AYDINLATILDI! KAPTAN VANCE TUTUKLANDI!" if not is_en else "DOCK MURDER SOLVED! CAPTAIN VANCE ARRESTED!"
		subhead_lbl.text = "Vinç Sabotajı ve 1944 Kuzey İntikal Askerî Sandıkları Ortaya Çıkarıldı" if not is_en else "Crane Sabotage and 1944 Northern Unit Contraband Uncovered"
		article_lbl.text = "Dedektif Silas Crowe, ambar işçisi Teddy Marsh'ın şüpheli ölümünü aydınlattı. Kargo gemisi kaptanı Donald Vance'in vinç halatını asitle zayıflatarak kaza süsü verdiği kesinleşti. Cinayetin ardındaki karaborsa mühimmat ağı ve gizemli daktilo mektubu soruşturuluyor." if not is_en else "Detective Silas Crowe has resolved the suspicious death of dock worker Teddy Marsh. Captain Donald Vance was caught red-handed for deliberately sabotaging the crane cable with acid. The black-market contraband munitions and an unsigned puppetmaster letter remain under deep investigation."
		newspaper_next_btn.text = "Vaka Değerlendirmesi ▶" if not is_en else "Case Evaluation ▶"
		var crime_p = "res://cases/case02/assets/cinematics/cinematic_case02_07_body_k3.jpg"
		var crime_tex = null
		if ResourceLoader.exists(crime_p):
			crime_tex = load(crime_p)
		else:
			var gp = ProjectSettings.globalize_path(crime_p)
			if FileAccess.file_exists(gp):
				var img = Image.load_from_file(gp)
				if img:
					crime_tex = ImageTexture.create_from_image(img)
		if crime_tex:
			photo_rect.texture = crime_tex
	elif GameState.current_case_id == "case03":
		paper_name_lbl.text = "GREYWATER TİYATRO POSTASI" if not is_en else "THE ROYAL THEATRE CHRONICLE"
		paper_date_lbl.text = "15 ARALIK 1946 — GECE YARISI EK BASKI" if not is_en else "DECEMBER 15, 1946 — MIDNIGHT EDITION"
		headline_lbl.text = "KRALİYET OPERASI SUİKASTI! KÖR NOKTADAN TEK KURŞUN!" if not is_en else "ROYAL OPERA ASSASSINATION! SINGLE BULLET FROM BLIND SPOT!"
		subhead_lbl.text = "Dalton Reeve Locada Vuruldu — Katil Çatıdan Sislerin İçine Kaçtı" if not is_en else "Dalton Reeve Slain in Royal Box — Sniper Vanished into the Fog"
		article_lbl.text = "Dedektif Silas Crowe, orkestranın top sesini ses perdesi olarak kullanan gizemli tetikçinin ışık köprüsündeki kör noktadan ateş ettiğini kanıtladı. K-4 tüfeği ve aşağı kayık 'r' harfli daktilo notu bulundu. Katil Elias Wren'in kaçışı ve üçlemenin gizemi koca bir insan avına dönüştü." if not is_en else "Detective Silas Crowe proved that the phantom sniper utilized the overture's cannon roar as an acoustic mask, firing from a carefully engineered blind spot on the light bridge. The K-4 rifle and the defective typewriter note were recovered. The manhunt for Elias Wren has begun."
		newspaper_next_btn.text = "Vaka Değerlendirmesi ▶" if not is_en else "Case Evaluation ▶"
		var crime_p = "res://cases/case02/assets/cinematics/cinematic_case02_07_body_k3.jpg"
		var crime_tex = null
		if ResourceLoader.exists(crime_p):
			crime_tex = load(crime_p)
		if crime_tex:
			photo_rect.texture = crime_tex
	else:
		paper_name_lbl.text = tr("ENDING_PAPER_NAME")
		paper_date_lbl.text = tr("ENDING_PAPER_DATE")
		headline_lbl.text = tr("ENDING_HEADLINE")
		subhead_lbl.text = tr("ENDING_SUBHEAD")
		article_lbl.text = tr("ENDING_ARTICLE")
		newspaper_next_btn.text = "Vaka Değerlendirmesi ▶" if not is_en else "Case Evaluation ▶"
		var crime_tex = load("res://assets/sprites/cinematics/cinematic_crime_scene_harlow.png")
		if crime_tex:
			photo_rect.texture = crime_tex

func _populate_rating() -> void:
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = (loc_mgr and loc_mgr.get_locale() == "en")

	report_title_lbl.text = tr("ENDING_REPORT_TITLE")

	var clues_found = GameState.discovered_evidence.size()
	var total_clues = GameState.evidence_db.size()
	if total_clues <= 0:
		total_clues = 17 if GameState.current_case_id == "case01" else 10
	stat_clues_lbl.text = ("Collected Clues: %d / %d" if is_en else "Toplanan Kanıtlar: %d / %d") % [clues_found, total_clues]

	var deds_solved = GameState.unlocked_deductions.size()
	var total_deds = GameState.deductions_db.size()
	if total_deds <= 0:
		total_deds = 10 if GameState.current_case_id == "case01" else 6
	stat_deds_lbl.text = ("Solved Deductions: %d / %d" if is_en else "Çözülen Çıkarımlar: %d / %d") % [deds_solved, total_deds]

	var mistakes = 3 - GameState.accusation_chances_left
	var acc_str = ""
	if mistakes == 0:
		acc_str = "Kusursuz (Sıfır Hata)" if not is_en else "Flawless (Zero Mistakes)"
	else:
		acc_str = "%d Hata Yapıldı" % mistakes if not is_en else "%d Mistakes Made" % mistakes
	stat_acc_lbl.text = tr("ENDING_STAT_ACCURACY") % acc_str

	if GameState.current_case_id == "case02":
		stat_drawers_lbl.text = ("Liman Belgeleri: 2 / 2" if not is_en else "Dock Records: 2 / 2")
		var rank = "B"
		var rank_text = "LİMAN MÜFETTİŞİ" if not is_en else "HARBOR INVESTIGATOR"
		var badge_color = Color(0.85, 0.65, 0.4)
		if clues_found >= 9 and deds_solved >= 4 and mistakes == 0:
			rank = "S"
			rank_text = "KUSURSUZ DEDEKTİF" if not is_en else "MASTER DETECTIVE"
			badge_color = Color(1.0, 0.88, 0.25)
		elif clues_found >= 7:
			rank = "A"
			rank_text = "KIDEMLİ DEDEKTİF" if not is_en else "SENIOR DETECTIVE"
			badge_color = Color(0.4, 0.85, 1.0)
		rank_badge_lbl.text = "★ %s ★" % rank
		rank_badge_lbl.add_theme_color_override("font_color", badge_color)
		rank_title_lbl.text = rank_text
		rank_title_lbl.add_theme_color_override("font_color", badge_color)
		monologue_lbl.text = "\"K-3 saati sustu. Teddy Marsh da kar fırtınasının bedelini ödedi... Ama o daktilo mektubu... İpleri çeken o gölge hâlâ bir sonraki adımı planlıyor.\"" if not is_en else "\"The K-3 watch fell silent. Teddy Marsh paid the toll of the blizzard... But that typewriter note... The shadow pulling the strings is already calculating his next strike.\""
	elif GameState.current_case_id == "case03":
		stat_drawers_lbl.text = ("Opera Belgeleri: 2 / 2" if not is_en else "Opera Records: 2 / 2")
		var rank = "B"
		var rank_text = "OPERA GÖZLEMCİSİ" if not is_en else "OPERA OBSERVER"
		var badge_color = Color(0.85, 0.65, 0.4)
		if clues_found >= 9 and deds_solved >= 5 and mistakes == 0:
			rank = "S"
			rank_text = "GÖLGE AVCISI" if not is_en else "SHADOW HUNTER"
			badge_color = Color(1.0, 0.88, 0.25)
		elif clues_found >= 7:
			rank = "A"
			rank_text = "UZMAN DEDEKTİF" if not is_en else "EXPERT DETECTIVE"
			badge_color = Color(0.4, 0.85, 1.0)
		rank_badge_lbl.text = "★ %s ★" % rank
		rank_badge_lbl.add_theme_color_override("font_color", badge_color)
		rank_title_lbl.text = rank_text
		rank_title_lbl.add_theme_color_override("font_color", badge_color)
		monologue_lbl.text = "\"Dalton Reeve'in K-4 saati avucumda durdu. Üçüncü kurban da toprağa verildi... Ama katil artık bir silüet değil, adını biliyorum: Elias Wren. Üçleme burada bitmedi, henüz yeni başlıyor.\"" if not is_en else "\"Dalton Reeve's K-4 watch ticks no more in my palm. The third victim is buried... but the killer is no longer just a shadow; I have his name: Elias Wren. The trilogy has not ended, it has only begun.\""
	else:
		stat_drawers_lbl.text = ("Gizli Bölmeler: %d / 3" if not is_en else "Secret Drawers: %d / 3") % GameState.secret_drawers_opened
		var rank = "B"
		var rank_text = tr("ENDING_RANK_B")
		var badge_color = Color(0.85, 0.65, 0.4)
		if clues_found >= 15 and deds_solved >= 8 and mistakes == 0:
			rank = "S"
			rank_text = tr("ENDING_RANK_S")
			badge_color = Color(1.0, 0.88, 0.25)
		elif clues_found >= 10:
			rank = "A"
			rank_text = tr("ENDING_RANK_A")
			badge_color = Color(0.4, 0.85, 1.0)
		rank_badge_lbl.text = "★ %s ★" % rank
		rank_badge_lbl.add_theme_color_override("font_color", badge_color)
		rank_title_lbl.text = rank_text
		rank_title_lbl.add_theme_color_override("font_color", badge_color)
		monologue_lbl.text = tr("ENDING_SILAS_MONOLOGUE")

	rating_next_btn.text = tr("ENDING_CREDITS_BTN")
	AudioManager.play_sfx("evidence_found")

func _populate_credits() -> void:
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = (loc_mgr and loc_mgr.get_locale() == "en")

	credits_title_lbl.text = tr("CREDITS_TITLE")
	if GameState.current_case_id == "case02":
		credits_sub_lbl.text = ("Bölüm 2 — Sisli Liman" if not is_en else "Chapter 2 — The Foggy Docks")
	elif GameState.current_case_id == "case03":
		credits_sub_lbl.text = ("Bölüm 3 — Kör Nokta (1. Oyun Finali)" if not is_en else "Chapter 3 — The Blind Spot (Game 1 Finale)")
	else:
		credits_sub_lbl.text = tr("CREDITS_SUBTITLE") + " — " + tr("CREDITS_CASE1")

	var credits_lines = [
		tr("CREDITS_DEV"),
		tr("CREDITS_STORY"),
		tr("CREDITS_ART"),
		tr("CREDITS_MUSIC"),
		"",
		"★ " + tr("CREDITS_THANKS") + " ★"
	]
	credits_body_lbl.text = "\n".join(credits_lines)

	if next_case_btn:
		if GameState.current_case_id == "case01":
			next_case_btn.text = "Bölüm 2'ye Devam Et (Sisli Liman) ▶" if not is_en else "Continue to Chapter 2 (Foggy Docks) ▶"
		elif GameState.current_case_id == "case02":
			next_case_btn.text = "Bölüm 3'e Devam Et (Kör Nokta) ▶" if not is_en else "Continue to Chapter 3 (Blind Spot) ▶"
		elif GameState.current_case_id == "case03":
			next_case_btn.text = "1. Sezon Tamamlandı (Ana Menü) ★" if not is_en else "Season 1 Complete (Main Menu) ★"
		else:
			next_case_btn.text = "Sonraki Bölüme Devam Et ▶" if not is_en else "Continue to Next Chapter ▶"

	return_office_btn.text = tr("ENDING_RETURN_OFFICE")
	main_menu_btn.text = tr("UI_RETURN_MENU")

func _on_newspaper_next() -> void:
	_show_stage(2)

func _on_rating_next() -> void:
	_show_stage(3)

func _on_next_case_pressed() -> void:
	if GameState.current_case_id == "case03":
		_on_main_menu_pressed()
		return

	var target_case = "case02" if GameState.current_case_id == "case01" else "case03"
	visible = false
	is_active = false
	GameState.can_player_move = true
	EventBus.case_ending_completed.emit()
	EventBus.case_continue_requested.emit(target_case)

func _on_return_office_pressed() -> void:
	visible = false
	is_active = false
	GameState.can_player_move = true
	EventBus.case_ending_completed.emit()
	# Transition back to Silas office with next case unlocked
	EventBus.room_change_requested.emit("silas_office", "from_case")

func _on_main_menu_pressed() -> void:
	visible = false
	is_active = false
	EventBus.case_ending_completed.emit()
	EventBus.main_menu_requested.emit()
