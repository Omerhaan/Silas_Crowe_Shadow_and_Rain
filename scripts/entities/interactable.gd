extends Node2D

## Interactive object / clue / drawer in rooms.
## Supports proximity detection [E / W] and direct touch/click tap-to-interact.
const NoirPalette = preload("res://scripts/core/noir_palette.gd")

@export var object_id: String = ""
@export var display_name: String = "Nesne"
@export var evidence_id: String = ""
@export var prop_type: String = ""
@export var is_secret_drawer: bool = false
@export var is_hotspot: bool = false
@export var hotspot_size: Vector2 = Vector2.ZERO
@export_multiline var custom_inner_voice: String = ""
@export var required_key_id: String = ""
@export var locked_message: String = ""

const FIXED_OBSERVATION_EVIDENCE = ["E01", "E02", "E04", "E08", "E10", "E11", "E15", "E17", "E201", "E203", "E206", "E304", "E307", "E310"]

@onready var area_2d: Area2D = $Area2D
@onready var prompt_label: Label = $PromptLabel
@onready var highlight: ReferenceRect = $Highlight
@onready var npc_sprite: Sprite2D = $NPCSprite
@onready var prop_sprite: Sprite2D = get_node_or_null("PropSprite")

var is_highlighted: bool = false
var flicker_timer: float = 0.0
var npc_anim_time: float = 0.0
var npc_directional_textures: Dictionary = {}
var current_npc_facing: String = "down"
var is_light_source: bool = false
var light_color: Color = Color(1.0, 0.82, 0.45)
var light_radius: float = 24.0
var light_anim_time: float = 0.0
var is_inspected: bool = false

const PROP_NAMES_EN = {
	# Silas Office
	"silas_books_stack": "Old Book Stack",
	"silas_armchair": "Leather Armchair",
	"silas_whiskey_tray": "Ashtray on Whiskey Table",
	"silas_vintage_radio": "Vintage Wooden Radio",
	"silas_coat_rack": "Coat & Hat Rack",
	"silas_telephone": "Telephone",
	"silas_memory_wall": "Memory Wall",
	"silas_souvenir_shelf": "Souvenir Shelf",
	"silas_lamp": "Banker's Lamp",
	"silas_typewriter": "Old Typewriter",
	"silas_rejection_letter": "Ministry Rejection Letter",
	"silas_desk": "Office Desk",
	"silas_filing_cabinet": "Filing Cabinet",
	"silas_rainy_window": "Rainy Window",
	"silas_pocket_watch": "Broken Pocket Watch",
	"silas_office_door": "Office Door",
	# Main Hall
	"hall_grandfather_clock": "Grandfather Clock",
	"hall_plant_left": "Potted Plant",
	"hall_marble_bust": "Marble Bust",
	"hall_grand_mirror": "Gilded Mirror",
	"chandelier_grand": "Grand Chandelier",
	"hall_coat_rack": "Coat & Hat Rack",
	"hall_plant_right": "Potted Palm",
	"main_hall_mat": "Entrance Doormat",
	"hall_umbrella_stand": "Wet Umbrella Stand",
	"main_hall_phone_table": "Severed Phone Table",
	# Study
	"study_door_lock": "Key in Door Lock",
	"study_desk": "Harlow's Desk",
	"harlow_body_watch": "Corpse & Broken Watch",
	"study_lawyer_note": "Attorney's Letter",
	"study_cognac_glass": "Cognac Glass",
	"study_secret_drawer_drops": "Secret Drawer (Heart Drops)",
	"study_waste_basket": "Wastebasket",
	"study_locked_safe_letters": "Safe Behind Portrait (Threat Letters)",
	"study_wall_sconce": "Wall Sconce & Candle",
	"study_window": "Study Window",
	"study_armchair": "Leather Armchair",
	"study_lamp": "Desk Lamp",
	# Library
	"library_grandfather_clock": "Grandfather Clock",
	"library_bookcase_left": "Left Bookcase",
	"library_bookcase_middle": "Middle Bookcase",
	"library_ladder": "Rolling Ladder",
	"library_wall_sconce": "Wall Sconce",
	"library_painting": "Antique Painting",
	"library_cold_fireplace": "Cold Fireplace",
	"library_hidden_flacon": "Mantelpiece (Poison Flacon)",
	"library_bookcase_right": "Right Bookcase",
	"library_reading_chair": "Reading Armchair",
	"library_reading_desk": "Reading Desk & Lamp",
	"library_globe": "Brass Floor Globe",
	# Dining Room
	"dining_sideboard": "Dining Sideboard",
	"dining_sideboard_drawer": "Sideboard Drawer",
	"dining_wall_sconce": "Wall Sconce",
	"dining_table": "Dining Table",
	"dining_candelabra": "Silver Candelabra",
	"dining_window": "Rainy Window",
	"dining_chandelier": "Crystal Chandelier",
	"dining_grandfather_clock": "Corner Clock",
	"dining_china_cabinet": "China Cabinet",
	# Kitchen
	"kitchen_pantry_cupboard": "Pantry Cupboard",
	"kitchen_cupboard_letter": "Kitchen Cupboard (Dismissal Warning)",
	"kitchen_meat_block": "Butcher's Block",
	"kitchen_counter": "Kitchen Counter",
	"kitchen_stove": "Cast Iron Stove",
	"kitchen_sink_counter": "Sink Counter",
	"kitchen_wall_shelves": "Wall Pot Shelf",
	"kitchen_pot_rack": "Pot & Pan Rack",
	# Billiard Room
	"billiard_armchair": "Club Chair",
	"billiard_cue_rack": "Cue Rack",
	"billiard_table": "Billiard Table",
	"billiard_lamp": "Billiard Lamp",
	"billiard_whiskey_table": "Whiskey Glass & Footprint",
	"billiard_bar_cart": "Bar Cart",
	"item_key_chest": "Antique Chest Key",
	"billiard_trophy_stag": "Stag Trophy",
	# Upper Floor
	"upper_chaise_lounge": "Corridor Chaise Lounge",
	# Harlow Bedroom
	"harlow_wardrobe": "Large Wardrobe",
	"harlow_bed": "Harlow's Bed",
	"harlow_nightstand_lamp": "Nightstand Lamp",
	"harlow_bedroom_photo": "Locked Drawer (E16 Unit Photo)",
	"item_key_drawer": "Desk Drawer Key",
	# Julian Room
	"julian_bed": "Unmade Bed",
	"upper_vintage_trunk": "Julian's Travel Trunk (E12 Debt Note)",
	"julian_desk": "Julian's Writing Desk",
	# Pike Room
	"pike_bed": "Guest Bed",
	"pike_suitcase": "Leather Suitcase",
	"pike_desk_lamp": "Desk Lamp",
	"pike_typewriter_ribbon": "Pike's Typewriter & Ribbon (E13)",
	# Case 2 Props
	"acid_coat": "Acid-Stained Overcoat",
	"typewriter_note": "Anonymous Typewritten Note",
	"ships_logbook": "Ship's Logbook",
	"cabin_porthole": "Stormy Porthole Window",
	"radio_transmitter": "Shortwave Marine Radio",
	"captain_bunk": "Captain's Bunk",
	"compass_table": "Compass & Chart Table",
	"tide_chart": "Tide Chart",
	"desk_pass_permit": "Sealed Night Permit",
	"bribe_ledger": "Customs Bribery Ledger",
	"office_safe": "Morris's Heavy Steel Safe",
	"sea_map": "Greywater Navigation Map",
	"typewriter": "Underwood Typewriter",
	"coat_rack": "Morris's Wet Overcoat",
	"military_crate": "Unsealed Military Crate",
	"bloody_lantern": "Bloody Brass Lantern",
	"marsh_body": "Teddy Marsh (K-3 Corpse)",
	"crane_pulley": "Crane Pulley & Snapped Hook",
	"mooring_ropes": "Mooring Ropes",
	"blood_stain": "Bloody Steel Plate",
	"fog_lamp": "Pier Streetlamp",
	"poker_table": "Poker Table",
	"mobster_1": "Armed Guard",
	"mobster_2": "Card Dealer",
	"bar_cabinet": "Bootleg Liquor Cabinet",
	"saloon_gramophone": "Crackling Gramophone",
	"account_book": "Secret Bribery Ledger",
	"saloon_clock": "Brass Bar Wall Clock",
	"crane_cable": "Snapped Crane Cable",
	"radio_desk": "Radio Desk",
	"dock_lantern": "Storm Lantern",
	"warehouse_hoist": "Rusty Hoist",
	"smuggle_crates": "Smuggled Munitions Crates",
	"fuse_box": "Electrical Fuse Box",
	"guard_desk": "Boris's Guard Desk",
	"sea_chest": "Locked Heavy Chest",
	"office_window": "Rainy Dock Window",
	"patch_tool_chest": "Patch's Combination Tool Chest"
}

const DISPLAY_NAME_TRANSLATIONS = {
	"Patch'in Şifreli Sandığı": "Patch's Combination Chest",
	"Büyükbaba Saati": "Grandfather Clock",
	"Büyük Saksı Bitkisi": "Potted Plant",
	"Kaideli Mermer Büst": "Marble Bust",
	"Altın Varaklı Ayna": "Gilded Mirror",
	"Büyük Hol Avizesi": "Grand Chandelier",
	"Palto ve Şapka Askılığı": "Coat & Hat Rack",
	"Palmiye Saksısı": "Potted Palm",
	"Giriş Kapısı Paspası": "Entrance Doormat",
	"Islak Şemsiyelik": "Wet Umbrella Stand",
	"Kopuk Telefon Masası": "Severed Phone Table",
	"Kilitteki Anahtar": "Key in Door Lock",
	"Harlow'un Çalışma Masası": "Harlow's Desk",
	"Ceset ve Kırık Saat": "Corpse & Broken Watch",
	"Avukat Mektubu": "Attorney's Letter",
	"Konyak Kadehi": "Cognac Glass",
	"Gizli Çekmece (Kalp Damlası)": "Secret Drawer (Heart Drops)",
	"Çöp Sepeti": "Wastebasket",
	"Portre Arkasındaki Kasa (Tehdit Mektupları)": "Safe Behind Portrait (Threat Letters)",
	"Duvar Apliği ve Mum": "Wall Sconce & Candle",
	"Pencere": "Window",
	"Deri Koltuk": "Leather Armchair",
	"Masa Lambası": "Desk Lamp",
	"Sol Kitaplık": "Left Bookcase",
	"Orta Kitaplık": "Middle Bookcase",
	"Raylı Merdiven": "Rolling Ladder",
	"Duvar Apliki": "Wall Sconce",
	"Eski Tablo": "Antique Painting",
	"Soğuk Şömine": "Cold Fireplace",
	"Şömine Rafı (Zehir Şişesi)": "Mantelpiece (Poison Flacon)",
	"Sağ Kitaplık": "Right Bookcase",
	"Kütüphane Koltuğu": "Reading Armchair",
	"Okuma Masası ve Lamba": "Reading Desk & Lamp",
	"Ayaklı Pirinç Küre": "Brass Floor Globe",
	"Yemek Büfesi": "Dining Sideboard",
	"Büfe Çekmecesi": "Sideboard Drawer",
	"Duvar Mumu": "Wall Sconce",
	"Yemek Masası": "Dining Table",
	"Gümüş Şamdan": "Silver Candelabra",
	"Yağmurlu Pencere": "Rainy Window",
	"Kristal Avize": "Crystal Chandelier",
	"Köşe Saati": "Corner Clock",
	"Porselen Vitrini": "China Cabinet",
	"Kiler Dolabı": "Pantry Cupboard",
	"Mutfak Dolabı (Kovulma İhtarı)": "Kitchen Cupboard (Dismissal Warning)",
	"Masif Et Kütüğü": "Butcher's Block",
	"Mutfak Tezgâhı": "Kitchen Counter",
	"Döküm Kuzine & Ocak": "Cast Iron Stove",
	"Evye ve Lavabo Tezgahı": "Sink Counter",
	"Duvar Tencere Rafı": "Wall Pot Shelf",
	"Tava ve Tencere Askılığı": "Pot & Pan Rack",
	"Kulüp Koltuğu": "Club Chair",
	"İsteka Rafı": "Cue Rack",
	"Bilardo Masası": "Billiard Table",
	"Bilardo Lambası": "Billiard Lamp",
	"Viski Kadehi ve Ayak İzi": "Whiskey Glass & Footprint",
	"İçki Arabası": "Bar Cart",
	"Antika Sandık Anahtarı": "Antique Chest Key",
	"Geyik Kafası Trofe": "Stag Trophy",
	"Koridor Dinlenme Sediri": "Corridor Chaise Lounge",
	"Koridor Avizesi": "Corridor Chandelier",
	"Büyük Gardırop": "Large Wardrobe",
	"Harlow'un Yatağı": "Harlow's Bed",
	"Komodin Lambası": "Nightstand Lamp",
	"Kilitli Çekmece (E16 Birlik Fotoğrafı)": "Locked Drawer (E16 Unit Photo)",
	"Çalışma Masası Çekmece Anahtarı": "Desk Drawer Key",
	"Dağınık Yatak": "Unmade Bed",
	"Julian'ın Seyahat Sandığı (E12 Kumar Borcu)": "Julian's Travel Trunk (E12 Debt Note)",
	"Julian'ın Yazı Masası": "Julian's Writing Desk",
	"Misafir Yatağı": "Guest Bed",
	"Deri Valiz": "Leather Suitcase",
	"Pike'ın Daktilosu ve Şeridi (E13)": "Pike's Typewriter & Ribbon (E13)"
}

const GENERIC_CYNICAL_THOUGHTS_TR = [
	"\"Toz, yağmur ve zaman kaybı. Katil burada saklanmıyor.\"",
	"\"Ceketimin cebini yokladım; kibritim bile bundan daha çok ipucu verirdi.\"",
	"\"Cansız nesnelerin bir huyu vardır; cinayeti görseler bile asla konuşmazlar.\"",
	"\"Buna bakarak cinayet çözülseydi, polis teşkilatı bir antikacı dükkânı açardı.\"",
	"\"Boş yere oyalanıyorum. Katil dışarıda, ben ise mobilyaları sorguluyorum.\""
]

const GENERIC_CYNICAL_THOUGHTS_EN = [
	"\"Dust, rain, and wasted time. The killer isn't hiding here.\"",
	"\"I patted my trench coat pockets; even my spent matches offer better clues.\"",
	"\"Inanimate objects have a peculiar habit: even if they witnessed murder, they stay dead silent.\"",
	"\"If staring at furniture solved homicides, the police department would be an antique shop.\"",
	"\"Wasting precious time. The killer is out in the night while I interrogate upholstery.\""
]

const PROP_VOICE_TR = {
	# Silas Office
	"silas_books_stack": "\"Kriminalistik ve askeri tıp kitapları. Çoğu sararmış sayfalar... Zihnimdeki boşlukları doldurmaya yetmiyorlar.\"",
	"silas_armchair": "\"Deri koltuğun yayları çökmüş. Uykusuz gecelerimin ve sigara dumanımın tek sessiz şahidi.\"",
	"silas_whiskey_tray": "\"Yarım kadeh ucuz viski ve sönmüş bir izmarit. Bir dedektifin en sadık iki dostu.\"",
	"silas_vintage_radio": "\"Parazitten başka ses yok. Bu fırtınada dalgalar bile rotasını şaşırmış.\"",
	"silas_telephone": "\"Siyah antika telefon. Bu saatte çalan bir telefon ya ölüm getirir ya da borç tahsildarı.\"",
	"silas_souvenir_shelf": "\"Kapanan vakalardan geriye kalan hatıralar... Her biri çözülmüş bir sır, ama hiçbiri içimi rahatlatmadı.\"",
	"silas_lamp": "\"Yeşil opalin camlı bankacı lambası. Titrek ışığı sadece masadaki dosyayı aydınlatıyor; karanlık ise her zamanki gibi odada bekliyor.\"",
	"silas_typewriter": "\"Eski daktilo. Son aylarda bu tuşlara dokunan tek şey toz ve unutulmuş evraklar oldu.\"",
	"silas_rejection_letter": "\"\\\"Belirttiğiniz tarihe ve operasyona dair arşivlerimizde herhangi bir kayıt bulunmamaktadır.\\\" — Üç ayda dördüncü ret mektubu. Gerçeği dosyalardan silebilirler ama zihnimdeki karları silemezler.\"",
	"silas_rainy_window": "\"Durmak bilmeyen bir yağmur. Şimşek her çaktığında sol elimin titremesi yeniden başlıyor.\"",
	"silas_pocket_watch": "\"03:12'de durmuş gümüş cep saati. Yıllardır bir saniye bile ilerlemedi... O geceden beri zaman benim için dondu.\"",
	# Case 1: Main Hall
	"hall_grandfather_clock": "\"Tık-tıkları bir idam mahkûmunun son adımları gibi yankılanıyor. Yüz elli yıllık ahşap kule, hâlâ benden daha dakik.\"",
	"hall_plant_left": "\"Solgun yapraklı bir salon eğreltisi. Güneş görmeden bu malikânede hayatta kalmaya çalışıyor; tıpkı benim gibi.\"",
	"hall_plant_right": "\"Kuru yapraklı bir palmiye. Malikânedeki sahte ihtişamın yapay süslerinden biri daha.\"",
	"hall_marble_bust": "\"Mermer gözleriyle beni süzüyor. Sanırım bu köşkteki tek asık suratlı adam ben değilim.\"",
	"hall_grand_mirror": "\"Aynadaki yorgun adama baktım. İki gündür uyumamış bir dedektif ve kırışık bir trençkot... Katil görse acır, teslim olurdu.\"",
	"chandelier_grand": "\"Tepemde sallanan yüzlerce Bohemya kristali. Bir cinayet mahallinde kafana kristal avize düşmesi fena bir şaka olurdu.\"",
	"hall_coat_rack": "\"Islandığında koyun gibi kokan pahalı yün paltolar. Harlow'un zengin misafirleri yağmurdan kaçmış ama ölümden kaçamamış.\"",
	"hall_umbrella_stand": "\"Pirinç şemsiyelik göle dönmüş. Yağmur sadece dışarıda değil, bu ailenin içine de sızıyor.\"",
	"main_hall_mat": "\"Çamurla kaplanmış bir giriş paspası. 'Hoş Geldiniz' yazısı çamurun altında kalmış; en azından dürüst bir karşılama.\"",
	"main_hall_phone_table": "\"Telefon hattı sel sırasında kopmuş. Ahize tamamen sessiz... Peki Silas Crowe'un bürosundaki telefon nasıl çaldı?\"",
	# Case 1: Study
	"study_waste_basket": "\"Buruşturulup atılmış birkaç hesap kâğıdı ve puro külü. Harlow'un öfkesini döktüğü ama cinayet kanıtı bırakmadığı bir teneke kutu.\"",
	"study_wall_sconce": "\"Duvarda titreyen gaz aplikleri. Dans eden gölgeler bana eski siper gecelerini hatırlatıyor.\"",
	"study_armchair": "\"İçine gömüldüğünde kalkması imkânsız gibi duran derin bir deri koltuk. Zenginlerin vicdan azabını yumuşatmak için tasarlanmış olmalı.\"",
	"study_lamp": "\"Masa lambasının soluk ışığı. Cinayeti aydınlatmaya yetiyor ama bu ailenin karanlık geçmişini aydınlatamaz.\"",
	"study_window": "\"Dışarıda köpüren deniz ve fırtına. Köprü çoktan çökmüş olmalı; bu adadan kimse sağ çıkamayacak gibi.\"",
	# Case 1: Library
	"library_bookcase_left": "\"Ciltli hukuk kitapları. Yıllardır kimsenin dokunmadığı toz tabakasından belli. Kanunlar sadece kütüphane süsüymüş.\"",
	"library_bookcase_middle": "\"Tıp ve farmakoloji ansiklopedileri. Kalp hastalıkları, panzehirler ve zehirler... Dr. Hale'in ilgi alanına giren türden.\"",
	"library_bookcase_right": "\"Felsefe ve ahlak üzerine yazılmış kalın ciltler. Bu malikânede en az rağbet gören kitaplar bunlar olmalı.\"",
	"library_ladder": "\"Tekerlekli ahşap merdiven. En üst raftaki tozlu kitaplara ulaşmak için... ya da şömineye zehir saklarken boyu yetmeyen biri için.\"",
	"library_painting": "\"Fırtınalı denizde kayalıklara sürüklenen bir yelkenli tablosu. Bu evdeki herkes batmakta olan bir gemide olduğunun farkında.\"",
	"library_globe": "\"Ayaklı pirinç dünya küresi. Üzerinde imparatorluk sınırları çizili. Biz dağlarda donarken bu çizgiler için mi savaştık?\"",
	"library_reading_chair": "\"Deri koltuk henüz sıcaklığını yitirmemiş. Biri burada yakın zamanda oturuyordu.\"",
	"library_reading_desk": "\"Okuma masasında yarım bırakılmış bir fincan soğuk çay. Hale burayı kanıt olarak gösterdi ama masada okunmuş tek bir sayfa bile yok.\"",
	# Case 1: Dining Room
	"dining_table": "\"On iki kişilik maun masa. Ortasında soğumuş rosto ve dokunulmamış çorba kâseleri. Katil ziyafetten önce servisini yapmış.\"",
	"dining_candelabra": "\"Erimiş mum tabakalarıyla kaplı ağır gümüş şamdan. Birinin kafasına indirmek için harika bir ağırlığı var ama cinayet aleti bu kadar kaba değildi.\"",
	"dining_china_cabinet": "\"Kraliyet porselenleri. O kadar narinler ki Silas Crowe'un bir öksürüğüyle tuzla buz olabilirler.\"",
	"dining_grandfather_clock": "\"Sarkaç ağır ağır salınıyor. Zaman bu yemek odasında akmıyor, sadece bir cinayeti bekliyormuş gibi sürünüyor.\"",
	"dining_window": "\"Pencere camına vuran sert yağmur. Fırtına ada köprüsünü çoktan yutmuştur.\"",
	"dining_chandelier": "\"Yemek masasının üzerindeki küçük kristal avize. Aşağıdaki soğuk kâselere soluk bir ışıltı veriyor.\"",
	"dining_sideboard_drawer": "\"Gümüş çatal bıçak takımları ve eski peçeteler duruyor. Zehir katmak için bıçağa gerek kalmamış.\"",
	# Case 1: Kitchen
	"kitchen_meat_block": "\"Üzerinde derin satır izleri olan meşe et kütüğü. Cinayet bir bıçak darbesiyle işlenseydi ilk şüpheli bu kütük olurdu.\"",
	"kitchen_counter": "\"Un ve baharat kokusu. Margaret bu tezgâhta otuz yıldır aristokratlara yemek pişirmiş, ama bir teşekkür bile alamamış.\"",
	"kitchen_stove": "\"İçinde meşe kömürü yanan döküm kuzine. Bu koca malikânede tek sıcak yer burası; belki de sırlar bu yüzden burada kaynıyor.\"",
	"kitchen_sink_counter": "\"Damlatan pirinç musluk. Çinko evyeye düşen her damla, bir suikastçının geri sayımı gibi ritmik.\"",
	"kitchen_wall_shelves": "\"Sıralanmış baharat kavanozları ve porselen tabaklar. Zehir karıştırılacaksa bu mutfakta seçenek çok.\"",
	"kitchen_pot_rack": "\"Bakır tavalar ayna gibi parlatılmış. Bir aşçının gururu ya da zehir cinayetinde izleri yok etmenin en temiz yolu.\"",
	# Case 1: Billiard Room
	"billiard_armchair": "\"Deri kulüp koltuğunda taze puro külü kokusu var. Julian burada viskisini yudumlarken amcasının mirasını hesaplıyordu.\"",
	"billiard_cue_rack": "\"Cilalı dişbudak istekalar. Hepsi yerli yerinde duruyor; bilardo bu gece sadece bir bahaneymiş, kimse oyun oynamamış.\"",
	"billiard_table": "\"Yeşil çuhanın üzerinde mavi tebeşir tozu. Julian amcası can çekişirken burada ıstaka salladığını iddia ediyordu; ama masada tek bir top bile hareket etmemiş.\"",
	"billiard_lamp": "\"Alçak tavan lambası yeşil masayı bir sorgu odası gibi aydınlatıyor.\"",
	"billiard_trophy_stag": "\"Duvardan bana bakan cam gözlü bir geyik kafası. Bu evdeki herkes bir avcı olduğunu sanıyor ama aslında hepsi birer av.\"",
	"billiard_bar_cart": "\"İçki arabasındaki gümüş kül tablasının dibine gizlenmiş süslü bir demir anahtar... Julian bunu neden buraya saklamış?\"",
	# Case 1: Upper Floor & Bedrooms
	"upper_chaise_lounge": "\"Kadife kaplı koridor sediri. Üst kattaki entrikaları dinlemek için mükemmel bir pusu noktası.\"",
	"harlow_wardrobe": "\"Harlow'un takım elbiseleri ve askeri üniformaları düzenle asılmış. Madalyalar bile asılı; vicdanı hariç her şeyi ütülü.\"",
	"harlow_bed": "\"Yatak hiç bozulmamış. Harlow bu gece yatağına hiç yatmamış; son uykusu çalışma odasında oldu.\"",
	"harlow_nightstand_lamp": "\"Titrek ışığı boş yatağa vuruyor. Bu odada uyumak yerine son nefesini çalışma odasında verdi.\"",
	"julian_bed": "\"Çarşaflar buruşuk. Julian aceleyle kalkmış ya da valizini burada hazırlamış.\"",
	"julian_desk": "\"Kumar borçları, hipodrom biletleri ve acil ödeme ihtarnameleri. Julian miras için amcasının ölmesini dört gözle bekliyormuş.\"",
	"pike_bed": "\"Yatak düzgünce toplanmış. Pike eski bir tüccar alışkanlığıyla düzenli.\"",
	"pike_suitcase": "\"Kilitli deri bir seyahat valizi. Üzerinde 'R. Pike - Londra' etiketi var.\"",
	"pike_desk_lamp": "\"Pike'ın masası bir muhasebeci titizliğiyle düzenlenmiş. Ama o daktilo şeridi tüm titizliğini çöpe attı.\"",
	# Case 2: Dock Props
	"crane_pulley": "\"Paslı devasa döküm makara. Üzerinde hidrolik yağ ve tuzlu sis kokusu var. Bir insanın üzerine düşmesi için birkaç tonluk ağırlık yeterli.\"",
	"mooring_ropes": "\"Katran kokulu kalın kendir halatlar. Bir yük gemisini rıhtıma bağlayabilir ama bir cinayetin vicdan azabını zapt edemez.\"",
	"blood_stain": "\"Rıhtım babasının dibindeki çelik sacda kurumuş kan. Teddy Marsh vinç kablosu kopmadan önce burada yere serilmişti.\"",
	"fog_lamp": "\"Sarı, cılız bir gaz lambası. Sis o kadar yoğun ki ışık iki metre ötesini bile göremiyor. Katilin en sadık dostu bu sis.\"",
	"poker_table": "\"Meyhanedeki poker masasında yarım kalmış bir el. İskambil kâğıtları, sigara izmaritleri ve viski halkaları. Burada herkes hile yapar; gümrükçüler hariç, onlar doğrudan çalar.\"",
	"mobster_1": "\"Deri ceketli, burnu kırık bir liman fedaisi. Bana öyle bir bakıyor ki elim gayriihtiyari cebimdeki tabancama gidiyor.\"",
	"mobster_2": "\"Dişlerinin arasında kürdan geveleyen bir kumarbaz. Gözleri masadaki paradan başka hiçbir şeyi görmüyor.\"",
	"bar_cabinet": "\"Kaçak viski dolabı. Şişelerin üzerindeki sahte mühürler, gümrük şefinin ne kadar ucuza satıldığını gösteriyor.\"",
	"saloon_gramophone": "\"İğnesi takılmış, boğuk bir caz melodisi çalıyor. Greywater'ın bataklığında müzik bile paslı tınlıyor.\"",
	"saloon_clock": "\"Pirinç çerçeveli duvar saati. Deniz tuzundan içi paslanmış; her saniyede bir sonrakini vurmakta zorlanıyor.\"",
	"crane_cable": "\"Asitle eritilmiş çelik lifler. Metal testere talaşı ve asit kokusu. Bir kaza süsü için fazla profesyonel bir kimya bilgisi.\"",
	"radio_desk": "\"Kısa dalga telsiz konsolu. Frekans kadranı hâlâ 312'de takılı. Teddy Marsh sekiz yıl önceki frekansı unutamamış.\"",
	"dock_lantern": "\"Rüzgârda sallanan isli fener. Camı çatlamış ama ışığı hâlâ dalgaların üzerindeki petrol tabakasını aydınlatıyor.\"",
	"warehouse_hoist": "\"Ambar tavanına asılı zincirli vinç. Kancasında pas ve güvercin pisliği birikmiş; bu ambarda canlı kalan tek şey fareler.\"",
	"smuggle_crates": "\"Mühürleri sökülmüş askeri sandıklar. Üzerinde silinmeye çalışılmış 'Kuzey İntikal' damgaları. Savaş bitti ama ganimetleri bu limanda hâlâ el değiştiriyor.\"",
	"fuse_box": "\"Kurcalanmış porselen sigortalar. Cinayetten hemen önce ambarın ışıkları buradan ana şalter indirilerek kesilmiş.\"",
	"guard_desk": "\"Kurutulmuş balık kılçıkları, boş votka şişesi ve kırık bir cop. Boris'in güvenliği korumaktan anladığı tek şey uyuklamak.\"",
	"sea_chest": "\"Kararmış pirinç köşeli ağır bir kaptan sandığı. Üzerinde 'SS Mary - 1938' kazılı. İçinde eski seyir haritaları ve güvelerin kemirdiği bir denizci üniforması var.\"",
	"office_window": "\"Pencereden bakınca 4 Nolu Rıhtım'ın dev vinçleri ve simsiyah İrlanda Denizi görünüyor. Greywater'ın suyu hiçbir günahı temizlemez; sadece dibe batırır.\"",
	"cabin_porthole": "\"Kaptanın pirinç lombozuna vuran yağmur damlaları. Dışarıdaki dalgalar sanki kamaranın içine girmek istiyor.\"",
	"captain_bunk": "\"Sert ve dar bir ranza. Kaptan Vance kamarada uyuduğunu iddia ediyordu; ama yatakta kırışık bile yok, çarşaf gergin.\"",
	"compass_table": "\"Pirinç jiroskoplu pusula. İğnesi manyetik kuzeyi gösteriyor. Keşke insan vicdanı da pusula kadar şaşmaz olsaydı.\"",
	"office_safe": "\"Ağır çelik kasa. Morris rüşvet defterini buraya kilitlemiş. Bir memurun korkusu adaletten değil, payının kesilmesindendir.\"",
	"sea_map": "\"Greywater açıklarının derinlik haritası. Kayalık bölgeler kırmızıyla işaretlenmiş; ceset atmak için en elverişli kör noktalar.\"",
	"typewriter": "\"Morris'in masasında duran eski daktilo. Şeridi kurumuş. Tuşlarına basınca metalik bir inilti çıkarıyor; bürokrasinin resmi sesi.\"",
	"coat_rack": "\"Morris'in gümrük şapkası ve sırılsıklam olmuş pardösüsü asılı. Dışarıda ne kadar ıslandıysa içeride de o kadar terlemiş.\"",
	# Case 3 Props (Opera)
	"ticket_booth": "\"Pirinç parmaklıklı bilet gişesi. Soylular buraya servet dökerken arka kapıdan cesetler taşınıyor.\"",
	"opera_poster": "\"1812 Tören Uvertürü afişi. 'Top Atışları Eşliğinde Görkemli Bir Gece!'... Dalton Reeve için fazlasıyla görkemli bir veda oldu.\"",
	"crystal_chandelier": "\"Tavandan sarkan devasa kristal avize. Binlerce mum ışığı yansıtıyor ama salondaki en karanlık sırrı bile aydınlatmaya yetmemiş.\"",
	"orchestra_pit": "\"Orkestra çukuru. Müzisyenler enstrümanlarını fırlatıp kaçmış; bir keman kırık yayının üzerinde yetim kalmış.\"",
	"stage_curtain": "\"Ağır kırmızı kadife perde. Kan kırmızısı kumaş bu gece sahnelenen trajediyi fazlasıyla ciddiye almış.\"",
	"auditorium_seats": "\"Sıra sıra dizilmiş bordo kadife koltuklar. Seyircilerin unuttuğu eldivenler, opera dürbünleri ve çiğnenmiş program broşürleri.\"",
	"reeve_corpse": "\"Dalton Reeve koltuğunda cansız yatıyor. Göğsündeki kurşun deliği tam kalbine isabet etmiş; 1944 kışındaki usta bir nişancının elinden çıktığı kesin.\"",
	"champagne_table": "\"Devrilmiş şampanya kadehleri ve dökülmüş pahalı şarap. Kanla karışınca ikisi de aynı lekeyi bırakıyor.\"",
	"dressing_mirror": "\"Ampullerle çevrili kulis makyaj aynası. Ruj lekeleri ve pudra kokusu. Herkes bir başkası gibi görünmek için buraya oturur; katiller hariç, onlar zaten gölgedir.\"",
	"theatrical_cannon": "\"Döküm demirden yapılmış uvertür topu. Namlusundan hâlâ bayat kükürt kokusu geliyor; tek görevi bir cinayetin sesini örtmekmiş gibi.\"",
	"armor_racks": "\"Sahne için yapılmış sahte şövalye zırhları ve kalay kılıçlar. Gerçek bir kurşunun karşısında teneke kadar bile korumazlar.\"",
	"prop_workbench": "\"Talaş, tutkal ve boya kokan marangoz masası. Burada kral taçları da yapılır, bir cinayetin anahtar kalıbı da.\"",
	"bridge_spotlights": "\"2000 vatlık kör edici projektörler. Sahneye baktığında seyircilerin gözünü kamaştırır, ışık köprüsünü ise zifiri bir mezara çevirir.\"",
	"bridge_railing": "\"İskele demirleri pas ve yağ içinde. Buradan aşağı bakmak baş döndürüyor; bir mermi sıkan içinse kusursuz bir av mevzisi.\"",
	"roof_gargoyle": "\"Taş oluk heykeli. Ağzından yağmur suları boşalırken bana alaycı bir sırıtışla bakıyor. Bu opera çatısı kimbilir kaç hayaletin kaçışına şahit oldu.\"",
	"roof_fire_escape": "\"Arka sokağın çıkmazına inen paslı yangın merdiveni. Basamaklardaki taze çamur izleri katilin aceleyle aşağı indiğini gösteriyor.\"",
	"roof_parapet": "\"Yağmur altındaki taş parapet. Sisler içindeki Londra silüeti uzanıyor; bir hayalet bu sisin içine atladı ve kayboldu.\"",
	"patch_tool_chest": "\"Barnaby Miller'ın ağır meşe alet sandığı. Üzerinde 3 haneli pirinç döner bir şifreli kilit var.\""
}

const PROP_VOICE_EN = {
	# Silas Office
	"silas_books_stack": "\"Criminalistics and military forensic books. Most pages have yellowed with age.\"",
	"silas_armchair": "\"A leather wingback armchair. Silas spends long nights here lost in cigarette smoke.\"",
	"silas_whiskey_tray": "\"Half a glass of cheap whiskey and an extinguished cigarette. The only companions of long nights.\"",
	"silas_vintage_radio": "\"Nothing on the radio but static. In this storm, the airwaves are entirely drowned out.\"",
	"silas_telephone": "\"A black antique desk phone. Ringing in this violent storm bodes no good.\"",
	"silas_souvenir_shelf": "\"Mementos left behind from closed cases rest upon this shelf.\"",
	"silas_lamp": "\"Banker's lamp with green opal glass. Its flickering glow lights only the case before me.\"",
	"silas_typewriter": "\"Client reports. In recent months, only dust and forgotten files have visited this desk.\"",
	"silas_rejection_letter": "\"\\\"No records found regarding the mentioned operation in our archives.\\\" — Fourth rejection in three months. Erased from files, but I still smell the snow.\"",
	"silas_rainy_window": "\"An unceasing storm outside. With every flash of lightning, I feel my left hand tremble.\"",
	"silas_pocket_watch": "\"My silver pocket watch stopped at 03:12. Unchanged for years... Time hasn't moved since that night.\"",
	# Main Hall
	"hall_grandfather_clock": "\"Ticking echoes like the final footsteps of a condemned man. A century-old clock tower, still more punctual than me.\"",
	"hall_plant_left": "\"A pale parlor fern struggling to survive without sunlight in this manor; much like myself.\"",
	"hall_plant_right": "\"A withered potted palm. Yet another artificial ornament in this manor's hollow opulence.\"",
	"hall_marble_bust": "\"Cold marble eyes scrutinizing me. Apparently I'm not the only gloomy face in this house.\"",
	"hall_grand_mirror": "\"I gazed at the exhausted man in the mirror. Two sleepless nights and a rumpled trench coat... Even a murderer might pity me.\"",
	"chandelier_grand": "\"Hundreds of Bohemian crystals swaying overhead. A falling chandelier would be a dark punchline in a murder house.\"",
	"hall_coat_rack": "\"Expensive wool coats that smell like wet sheep in the rain. Wealthy guests fled the storm, but not death.\"",
	"hall_umbrella_stand": "\"The brass umbrella stand has turned into a miniature pond. The rain seeps deep into this family.\"",
	"main_hall_mat": "\"A mud-caked doormat. 'Welcome' is buried under silt; at least an honest greeting.\"",
	"main_hall_phone_table": "\"The phone line was severed during the flood. The receiver is completely dead... Then how did the phone ring in Silas Crowe's office?\"",
	# Study
	"study_waste_basket": "\"Crumpled balance sheets and cigar ash. Harlow vented his rage here, but left no clues of the crime.\"",
	"study_wall_sconce": "\"Flickering gas sconces. Dancing shadows evoke memories of freezing trench nights.\"",
	"study_armchair": "\"A deep leather armchair impossible to rise from once settled. Engineered to cushion aristocratic guilt.\"",
	"study_lamp": "\"The dim glow of the banker's lamp. Sufficient to illuminate the corpse, but useless against this family's dark past.\"",
	"study_window": "\"Churning sea and torrential storm outside. The causeway bridge must have washed out long ago.\"",
	# Library
	"library_bookcase_left": "\"Leatherbound law volumes. Thick layers of dust prove justice is merely an ornamental shelf display here.\"",
	"library_bookcase_middle": "\"Pharmacology and toxicology tomes. Cardiac ailments and deadly poisons... Dr. Hale's specialty.\"",
	"library_bookcase_right": "\"Heavy treatises on moral philosophy. Undeniably the least consulted books in this household.\"",
	"library_ladder": "\"Rolling wooden ladder. Convenient for reaching high philosophy shelves... or concealing vials atop cold mantelpieces.\"",
	"library_painting": "\"A battered schooner drifting towards jagged reefs. Everyone in this manor senses they are aboard a sinking vessel.\"",
	"library_globe": "\"A brass floor globe charting fallen empires. Did we freeze in northern mountains just for lines drawn upon this brass?\"",
	"library_reading_chair": "\"The leather armchair is still warm. Someone was sitting here very recently.\"",
	"library_reading_desk": "\"A half-finished cup of cold tea on the reading desk. Hale claimed this alibi, but not a single page was turned.\"",
	# Dining Room
	"dining_table": "\"A twelve-seat mahogany table with cold roast and untouched soup bowls. The killer served the main course early.\"",
	"dining_candelabra": "\"A heavy silver candelabra coated in tallow. Substantial enough to shatter a skull, though the killer employed subtler means.\"",
	"dining_china_cabinet": "\"Fine bone china. Delicate enough that a cough from Silas Crowe might reduce it to porcelain dust.\"",
	"dining_grandfather_clock": "\"The pendulum sways languidly. Time crawls in this dining hall as if waiting for death.\"",
	"dining_window": "\"Rain lashings against the windowpane. The island causeway is entirely submerged.\"",
	"dining_chandelier": "\"A crystal chandelier casting a pale luminescence across freezing bowls of broth.\"",
	"dining_sideboard_drawer": "\"Silver cutlery sets and vintage linen napkins are neatly arranged.\"",
	# Kitchen
	"kitchen_meat_block": "\"Heavy butcher's block gouged with cleaver marks. Had this been a stabbing, the block would be prime suspect.\"",
	"kitchen_counter": "\"Smells of flour and dry seasoning. Margaret served thirty years without receiving a single word of gratitude.\"",
	"kitchen_stove": "\"A cast iron stove radiating oak embers. The only warm spot in this vast estate; no wonder secrets simmer here.\"",
	"kitchen_sink_counter": "\"A dripping brass tap. Each drop against zinc sounds like an assassin's countdown.\"",
	"kitchen_wall_shelves": "\"Jars of herbs and condiments. If one sought to lace a drink with poison, options were abundant.\"",
	"kitchen_pot_rack": "\"Copper pots buffed to a mirror shine. A cook's pride, or the cleanest method to erase traces.\"",
	# Billiard Room
	"billiard_armchair": "\"Faint traces of fresh cigar ash cling to the leather. Julian nursed his whiskey while calculating his inheritance.\"",
	"billiard_cue_rack": "\"Polished ash cues aligned in pristine order. Billiards was merely an alibi tonight; no game was played.\"",
	"billiard_table": "\"Blue chalk dust over green baize. Julian claimed he was playing alone while his uncle perished, yet not a single ball was struck.\"",
	"billiard_lamp": "\"The low-hanging lampshade illuminates the green felt like a police interrogation desk.\"",
	"billiard_trophy_stag": "\"Glass eyes of a mounted stag gazing down. Everyone under this roof imagines themselves hunters; all are prey.\"",
	"billiard_bar_cart": "\"An ornate iron key hidden beneath the silver ashtray on the bar cart... Why did Julian hide this here?\"",
	# Harlow Bedroom
	"harlow_wardrobe": "\"Harlow's suits and military uniforms hang in meticulous order. Medals polished; conscience left unchecked.\"",
	"harlow_bed": "\"The bed is untouched. Harlow never went to sleep tonight.\"",
	"harlow_nightstand_lamp": "\"A flickering lamp casting shadows over vacant sheets. His final sleep took place downstairs.\"",
	"julian_bed": "\"Crumpled sheets. Julian either got up in haste or packed his suitcase right here.\"",
	"julian_desk": "\"Scattered papers and IOUs regarding gambling debts cover the desk.\"",
	"pike_bed": "\"The bed is neatly made. Pike keeps everything orderly out of merchant habit.\"",
	"pike_suitcase": "\"A locked leather travel suitcase bearing a tag: 'R. Pike - London'.\"",
	"pike_desk_lamp": "\"Pike's desk is arranged with accountant precision. Yet the typewriter ribbon shattered his alibi.\"",
	# Case 2 Props
	"crane_pulley": "\"A massive cast pulley coated in hydraulic grease and brine. Several tons suffice to snuff out a life instantly.\"",
	"mooring_ropes": "\"Tarred hemp mooring lines. Sturdy enough to dock a freighter, yet powerless against runaway guilt.\"",
	"blood_stain": "\"Dried blood on a rusted steel plate. Teddy Marsh fell here before the freight crane cable severed.\"",
	"fog_lamp": "\"A faint yellow streetlamp struggling against maritime fog. The assassin's truest confidant is this mist.\"",
	"poker_table": "\"An abandoned hand on the saloon table. Cigarette stubs, spilled spirits, and marked cards. Everyone cheats here; customs officials simply steal outright.\"",
	"mobster_1": "\"A broken-nosed dock enforcer in weathered leather. His stare instinctively guides my hand toward my holster.\"",
	"mobster_2": "\"A cardsharp rolling a toothpick between yellowed teeth. His gaze never strays far from the pot.\"",
	"bar_cabinet": "\"Contraband spirits. Counterfeit customs stamps reveal how cheaply the harbor master was bought.\"",
	"saloon_gramophone": "\"A stuck needle rasping out a melancholic tune. In Greywater's mire, even jazz echoes with rust.\"",
	"saloon_clock": "\"Brass wall clock corroded with sea spray, struggling to strike each passing second.\"",
	"crane_cable": "\"Acid-corroded steel strands and hacksaw filings. Far too sophisticated chemistry for a simple workplace mishap.\"",
	"radio_desk": "\"Shortwave transceiver dial still tuned to 312. Teddy Marsh never escaped that frequency.\"",
	"dock_lantern": "\"Soot-stained hurricane lantern flickering above diesel slicks on the harbor surface.\"",
	"warehouse_hoist": "\"Rusty hoist chain draped from the rafters. The only thriving creatures in this shed are the rats.\"",
	"smuggle_crates": "\"Military crates with scratched-out 'Northern Depot' stamps. The war ended, but contraband still circulates.\"",
	"fuse_box": "\"Tampered porcelain fuses. The warehouse circuit was killed at the main breaker before the strike.\"",
	"guard_desk": "\"Dried fish bones, an empty vodka bottle, and a cracked baton. Boris's concept of sentry duty is a long nap.\"",
	"sea_chest": "\"A heavy sailor's chest with blackened brass corners. 'SS Mary - 1938' is engraved into the lid.\"",
	"office_window": "\"Looking through the window, the towering cranes of Pier 4 and the storm-tossed dark ocean are visible.\"",
	"cabin_porthole": "\"Rain lashes the captain's brass porthole. Dark swells outside seem desperate to flood the cabin.\"",
	"captain_bunk": "\"A Spartan cot. Vance claimed he slept through the midnight hours, yet the blanket is taut without a crease.\"",
	"compass_table": "\"A brass gimbaled compass pointing to magnetic north. If only human virtue were half as steadfast.\"",
	"office_safe": "\"A reinforced safe where Morris hid the bribery records. A bureaucrat fears not justice, but a withheld envelope.\"",
	"sea_map": "\"Nautical bathymetry charts of Greywater approaches. Shallows and deep trenches marked in red ink.\"",
	"typewriter": "\"Morris's Underwood with a dried-out ribbon. Striking its keys produces the metallic groan of bureaucracy.\"",
	"coat_rack": "\"Morris's soaked overcoat and peaked harbor hat. As drenched outside as he was sweating within.\"",
	"patch_tool_chest": "\"Barnaby Miller's heavy oak tool chest. Secured with a 3-digit rotary brass combination lock.\""
}

func _get_loc_mgr() -> Node:
	if is_inside_tree():
		return get_node_or_null("/root/LocalizationManager")
	var ml = Engine.get_main_loop()
	if ml and "root" in ml and ml.root:
		return ml.root.get_node_or_null("LocalizationManager")
	return null

func get_localized_name() -> String:
	var loc_mgr = _get_loc_mgr()
	var is_en = (loc_mgr and loc_mgr.get_locale() == "en")
	var base_name = display_name
	base_name = base_name.replace("[İncelendi] ", "").replace("[Inspected] ", "")

	if evidence_id != "":
		var ev_data = GameState.get_evidence_data(evidence_id)
		if ev_data and ev_data.has("ad") and ev_data["ad"] != "":
			base_name = ev_data["ad"]
	elif object_id.begins_with("npc_"):
		var susp_id = object_id.replace("npc_", "")
		if susp_id.begins_with("dr_"):
			susp_id = susp_id.replace("dr_", "")
		var s_data = GameState.get_suspect_data(susp_id)
		if s_data and s_data.has("ad"):
			if is_en:
				base_name = "Talk to " + s_data["ad"]
			else:
				base_name = s_data["ad"] + " ile Konuş"
	elif is_en:
		if PROP_NAMES_EN.has(object_id):
			base_name = PROP_NAMES_EN[object_id]
		elif DISPLAY_NAME_TRANSLATIONS.has(base_name):
			base_name = DISPLAY_NAME_TRANSLATIONS[base_name]
		else:
			var obj_key = "PROP_" + object_id.to_upper()
			if loc_mgr:
				base_name = loc_mgr.tr_text(obj_key, base_name)
	else:
		var obj_key = "PROP_" + object_id.to_upper()
		if loc_mgr:
			base_name = loc_mgr.tr_text(obj_key, base_name)

	var inspected = is_inspected or (evidence_id != "" and GameState.has_evidence(evidence_id))
	if inspected and evidence_id in FIXED_OBSERVATION_EVIDENCE:
		var prefix = "[Inspected] " if is_en else "[İncelendi] "
		return prefix + base_name
	return base_name

func get_localized_inner_voice() -> String:
	var loc_mgr = _get_loc_mgr()
	var is_en = (loc_mgr and loc_mgr.get_locale() == "en")
	if not is_en:
		if custom_inner_voice != "":
			return custom_inner_voice
		if PROP_VOICE_TR.has(object_id):
			return PROP_VOICE_TR[object_id]
		var idx = abs(object_id.hash()) % GENERIC_CYNICAL_THOUGHTS_TR.size()
		return GENERIC_CYNICAL_THOUGHTS_TR[idx]

	if PROP_VOICE_EN.has(object_id):
		return PROP_VOICE_EN[object_id]

	var idx_en = abs(object_id.hash()) % GENERIC_CYNICAL_THOUGHTS_EN.size()
	return GENERIC_CYNICAL_THOUGHTS_EN[idx_en]


func _ready() -> void:
	if has_node("Sprite"):
		$Sprite.visible = false
	if prompt_label:
		prompt_label.visible = false
	if highlight:
		highlight.visible = false
	if area_2d:
		area_2d.input_pickable = true
		area_2d.input_event.connect(_on_area_input_event)

	var eb_init = get_node_or_null("/root/EventBus")
	if eb_init and eb_init.has_signal("focus_pulse_requested"):
		eb_init.focus_pulse_requested.connect(pulse_highlight)

	# Check persistent state (already collected or inspected)
	var gs = get_node_or_null("/root/GameState")
	if gs:
		if evidence_id != "" and gs.has_evidence(evidence_id):
			if evidence_id in FIXED_OBSERVATION_EVIDENCE:
				is_inspected = true
				if highlight:
					highlight.border_color = Color(0.4, 0.45, 0.5, 0.35)
			else:
				visible = false
				if area_2d:
					area_2d.monitoring = false
					area_2d.monitorable = false
					var col = area_2d.get_node_or_null("CollisionShape2D")
					if col:
						col.set_deferred("disabled", true)
				return
		elif object_id != "" and gs.has_item(object_id.replace("item_", "")):
			visible = false
			if area_2d:
				area_2d.monitoring = false
				area_2d.monitorable = false
				var col = area_2d.get_node_or_null("CollisionShape2D")
				if col:
					col.set_deferred("disabled", true)
			return

	# Light source detection for candlelight, lamps, fireplaces
	var ptype_init = _detect_prop_type()
	var oid_init = object_id.to_lower()
	if oid_init != "library_cold_fireplace" and not "cold" in oid_init:
		if ptype_init in ["lamp", "fireplace"] or "candle" in oid_init or "sconce" in oid_init or "chandelier" in oid_init or oid_init in ["silas_lamp", "study_lamp"]:
			is_light_source = true
			if ptype_init == "fireplace":
				light_color = Color(1.0, 0.62, 0.22)
				light_radius = 36.0
			elif "chandelier" in oid_init:
				light_color = Color(1.0, 0.88, 0.55)
				light_radius = 32.0
			elif "candle" in oid_init or "sconce" in oid_init:
				light_color = Color(1.0, 0.78, 0.38)
				light_radius = 20.0
			else:
				light_color = Color(1.0, 0.84, 0.48)
				light_radius = 24.0

	# Check NPC character textures with full 4-directional support
	var npc_dir_definitions = {
		"npc_margaret_doyle": {
			"down": "res://assets/sprites/characters/margaret_idle_down.png",
			"left": "res://assets/sprites/characters/margaret_idle_left.png",
			"right": "res://assets/sprites/characters/margaret_idle_right.png",
			"up": "res://assets/sprites/characters/margaret_idle_up.png"
		},
		"npc_dr_hale": {
			"down": "res://assets/sprites/characters/hale_idle_down.png",
			"left": "res://assets/sprites/characters/hale_idle_left.png",
			"right": "res://assets/sprites/characters/hale_idle_right.png",
			"up": "res://assets/sprites/characters/hale_idle_up.png"
		},
		"npc_julian_harlow": {
			"down": "res://assets/sprites/characters/julian_idle_down.png",
			"left": "res://assets/sprites/characters/julian_idle_left.png",
			"right": "res://assets/sprites/characters/julian_idle_right.png",
			"up": "res://assets/sprites/characters/julian_idle_up.png"
		},
		"npc_raymond_pike": {
			"down": "res://assets/sprites/characters/pike_idle_down.png",
			"left": "res://assets/sprites/characters/pike_idle_left.png",
			"right": "res://assets/sprites/characters/pike_idle_right.png",
			"up": "res://assets/sprites/characters/pike_idle_up.png"
		}
	}

	if npc_dir_definitions.has(object_id):
		var dir_map = npc_dir_definitions[object_id]
		for d in dir_map.keys():
			var t = _load_texture(dir_map[d])
			if t:
				npc_directional_textures[d] = t

		if npc_directional_textures.has("down") and npc_sprite:
			npc_sprite.texture = npc_directional_textures["down"]
			current_npc_facing = "down"
			npc_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			npc_sprite.scale = Vector2(1.0, 1.0)
			npc_sprite.centered = false
			npc_sprite.offset = Vector2(-32.0, -104.0)
			npc_sprite.position = Vector2(0.0, 0.0)
			npc_sprite.visible = true
			if highlight:
				highlight.offset_top = -104.0
				highlight.offset_bottom = 0
				highlight.offset_left = -20.0
				highlight.offset_right = 20.0
			if prompt_label:
				prompt_label.position.y = -118.0
			var col = area_2d.get_node_or_null("CollisionShape2D")
			if col:
				var rect_shape = RectangleShape2D.new()
				rect_shape.size = Vector2(36.0, 102.0)
				col.shape = rect_shape
				col.position = Vector2(0, -51.0)
			area_2d.z_index = 10
			if not has_node("NPCShadow"):
				var shadow_tex: Texture2D = null
				if ResourceLoader.exists("res://assets/sprites/shadow_silas.png"):
					shadow_tex = load("res://assets/sprites/shadow_silas.png")
				else:
					var s_path = ProjectSettings.globalize_path("res://assets/sprites/shadow_silas.png")
					if FileAccess.file_exists(s_path):
						var s_img = Image.load_from_file(s_path)
						if s_img:
							shadow_tex = ImageTexture.create_from_image(s_img)
				if shadow_tex:
					var shadow = Sprite2D.new()
					shadow.name = "NPCShadow"
					shadow.texture = shadow_tex
					shadow.scale = Vector2(1.0, 1.0)
					shadow.position = Vector2(0, -2)
					shadow.z_index = -1
					add_child(shadow)
		return

	# Hotspots: invisible interaction areas over the painted room plate
	if is_hotspot:
		if prop_sprite:
			prop_sprite.visible = false
			prop_sprite.texture = null
		if hotspot_size != Vector2.ZERO:
			if highlight:
				highlight.offset_left = -hotspot_size.x / 2.0
				highlight.offset_right = hotspot_size.x / 2.0
				highlight.offset_top = -hotspot_size.y / 2.0
				highlight.offset_bottom = hotspot_size.y / 2.0
			if prompt_label:
				prompt_label.position.y = -hotspot_size.y / 2.0 - 10.0
			var col = area_2d.get_node_or_null("CollisionShape2D")
			if col:
				var rect_shape = RectangleShape2D.new()
				var touch_w = maxf(hotspot_size.x, 38.0)
				var touch_h = maxf(hotspot_size.y, 38.0)
				rect_shape.size = Vector2(touch_w, touch_h)
				col.shape = rect_shape
		return

	# Standalone visible prop: try loading texture
	var loaded_from_manifest = _try_load_manifest_texture()
	if not loaded_from_manifest:
		queue_redraw()

func _process(delta: float) -> void:
	# Dynamic facing towards Silas
	if npc_sprite and npc_sprite.visible:

		# Check distance to player
		var player_node: Node2D = null
		var players = get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			player_node = players[0]

		if player_node:
			var dist = global_position.distance_to(player_node.global_position)
			if dist < 130.0:
				var dx = player_node.global_position.x - global_position.x
				var target_dir = "down"
				if dx < -20.0:
					target_dir = "left"
				elif dx > 20.0:
					target_dir = "right"
				else:
					target_dir = "down"

				if target_dir != current_npc_facing and npc_directional_textures.has(target_dir):
					current_npc_facing = target_dir
					npc_sprite.texture = npc_directional_textures[target_dir]
			elif current_npc_facing != "down" and dist > 160.0:
				current_npc_facing = "down"
				if npc_directional_textures.has("down"):
					npc_sprite.texture = npc_directional_textures["down"]

	# Subtle flickering for light sources
	if is_light_source:
		light_anim_time += delta * 3.5
		flicker_timer += delta
		if flicker_timer > 0.07:
			flicker_timer = 0.0
			queue_redraw()

func _detect_prop_type() -> String:
	if prop_type != "":
		return prop_type.to_lower()
	var id = object_id.to_lower()
	if "chandelier" in id or "pendant" in id or "ceiling" in id: return "ceiling"
	if "painting" in id or "portrait" in id or "frame" in id or "mirror" in id or "sconce" in id or "trophy" in id: return "wall"
	if "telephone" in id or "phone" in id: return "telephone"
	if "lamp" in id or "candle" in id: return "lamp"
	if "window" in id: return "window"
	if "armchair" in id or "chair" in id or "couch" in id or "kanepe" in id or "sofa" in id: return "armchair"
	if "desk" in id or "table" in id: return "desk"
	if "door" in id or "exit" in id or "entry" in id: return "door"
	if "watch" in id: return "watch"
	if "typewriter" in id: return "typewriter"
	if "rejection" in id or "letter" in id or "document" in id or "note" in id: return "paper"
	if "key" in id or "lock" in id: return "key"
	if "counter" in id or "stove" in id or "cupboard" in id: return "counter"
	if "billiard" in id: return "billiard"
	if "drawer" in id: return "drawer"
	if "bookcase" in id or "books" in id: return "bookcase"
	if "fireplace" in id: return "fireplace"
	if "shelf" in id: return "shelf"
	if "memory_wall" in id or "board" in id or "photo" in id: return "board"
	if "bottle" in id or "vial" in id or "medicine" in id or "glass" in id: return "bottle"
	if id.begins_with("npc_"): return "npc"
	return "prop"

func _try_load_manifest_texture() -> bool:
	var tex: Texture2D = null

	# 1. Direct file in assets/sprites/props/
	var direct_path = "res://assets/sprites/props/" + object_id + ".png"
	if ResourceLoader.exists(direct_path) or FileAccess.file_exists(ProjectSettings.globalize_path(direct_path)):
		tex = _load_texture(direct_path)

	# 2. Check AssetManager singleton
	if not tex:
		var am = get_node_or_null("/root/AssetManager")
		if am:
			tex = am.get_texture(object_id)
			if not tex:
				tex = am.get_texture("prop_" + object_id)

	if tex and prop_sprite:
		prop_sprite.texture = tex
		prop_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var ptype = _detect_prop_type()
		var p_offset_y = 0.0
		if ptype == "ceiling":
			p_offset_y = tex.get_height() / 2.0
		elif ptype == "wall" or ptype == "window" or ptype == "board" or ptype == "shelf":
			p_offset_y = 0.0
		else:
			p_offset_y = -tex.get_height() / 2.0
		prop_sprite.position = Vector2(0, p_offset_y)
		prop_sprite.visible = true

		var w = hotspot_size.x if hotspot_size.x > 0 else float(tex.get_width())
		var h = hotspot_size.y if hotspot_size.y > 0 else float(tex.get_height())
		if highlight:
			highlight.offset_left = -w / 2.0
			highlight.offset_right = w / 2.0
			highlight.offset_top = p_offset_y - h / 2.0
			highlight.offset_bottom = p_offset_y + h / 2.0
		if prompt_label:
			prompt_label.position.y = p_offset_y - h / 2.0 - 12.0
		var col = area_2d.get_node_or_null("CollisionShape2D")
		if col:
			var rect_shape = RectangleShape2D.new()
			rect_shape.size = Vector2(max(w, 24.0), max(h, 24.0))
			col.shape = rect_shape
			col.position = Vector2(0, p_offset_y)
		return true
	return false

func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	var real_path = ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(real_path):
		var img = Image.load_from_file(real_path)
		if img:
			return ImageTexture.create_from_image(img)
	var case_path = path.replace("res://assets/sprites/characters/", "res://cases/case01/assets/characters/")
	if ResourceLoader.exists(case_path):
		return load(case_path)
	var real_case_path = ProjectSettings.globalize_path(case_path)
	if FileAccess.file_exists(real_case_path):
		var img2 = Image.load_from_file(real_case_path)
		if img2:
			return ImageTexture.create_from_image(img2)
	return null

func _draw() -> void:
	if is_light_source:
		# Multi-octave natural flame flicker: slow breathing + fast micro-jitter
		var slow_breathe = sin(light_anim_time * 2.5) * 0.05
		var fast_flutter = sin(light_anim_time * 9.0) * 0.03 + randf_range(-0.02, 0.02)
		var current_radius = light_radius * (1.0 + slow_breathe + fast_flutter * 0.5)
		var current_alpha = clampf(0.20 + slow_breathe + fast_flutter, 0.08, 0.30)
		_draw_dithered_halo(Vector2.ZERO, current_radius, light_color, current_alpha)

	if not is_hotspot and (prop_sprite == null or not prop_sprite.visible) and (npc_sprite == null or not npc_sprite.visible):
		# Draw subtle amber point of interest marker if no sprite could be loaded
		draw_rect(Rect2(-3, -3, 6, 6), Color(0.85, 0.75, 0.35, 0.8))
		draw_rect(Rect2(-2, -2, 4, 4), Color(0.95, 0.90, 0.60, 1.0))

func _draw_dithered_halo(center: Vector2, radius: float, base_col: Color, alpha_peak: float) -> void:
	# 3-tiered stepped halo with low alpha
	var col1 = Color(base_col.r, base_col.g, base_col.b, alpha_peak)
	var col2 = Color(base_col.r, base_col.g, base_col.b, alpha_peak * 0.50)
	var col3 = Color(base_col.r, base_col.g, base_col.b, alpha_peak * 0.22)

	draw_circle(center, radius * 1.0, col3)
	draw_circle(center, radius * 0.65, col2)
	draw_circle(center, radius * 0.35, col1)

	# Checkerboard dither points along the outer perimeter (retro pixel-art edge)
	var dither_col = Color(base_col.r, base_col.g, base_col.b, alpha_peak * 0.12)
	var r_out = int(radius * 1.15)
	var r_in = int(radius * 0.85)
	for dy in range(-r_out, r_out + 1, 2):
		for dx in range(-r_out, r_out + 1, 2):
			var dist_sq = dx * dx + dy * dy
			if dist_sq >= r_in * r_in and dist_sq <= r_out * r_out:
				if (int(center.x + dx) + int(center.y + dy)) % 4 == 0:
					draw_rect(Rect2(center.x + dx, center.y + dy, 1, 1), dither_col)

func _draw_books_row(x_start: float, y_start: float, width: float, height: float) -> void:
	var book_cols = [
		NoirPalette.CRIMSON_DEEP, NoirPalette.GREEN_MOSS, NoirPalette.PETROL_MID,
		NoirPalette.AMBER_MID, NoirPalette.PLUM_LIGHT, NoirPalette.PAPER_WARM
	]
	var cur_x = x_start
	var i = 0
	while cur_x < x_start + width - 3:
		var bw = randf_range(3.0, 5.0)
		var bh = randf_range(height - 4.0, height)
		var col = book_cols[i % book_cols.size()]
		draw_rect(Rect2(cur_x, y_start + height - bh, bw, bh), col)
		draw_line(Vector2(cur_x + bw, y_start + height - bh), Vector2(cur_x + bw, y_start + height), NoirPalette.SHADOW_DEEP, 1)
		cur_x += bw + 1.0
		i += 1

func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed):
		var im = get_node_or_null("/root/InputManager")
		if im and im.has_method("request_interact_with"):
			im.request_interact_with(self)
		get_viewport().set_input_as_handled()

func set_highlight(active: bool) -> void:
	is_highlighted = active
	if highlight:
		highlight.visible = false
	if prompt_label:
		if active and object_id.begins_with("npc_"):
			var loc_mgr = get_node_or_null("/root/LocalizationManager")
			var is_en = (loc_mgr and loc_mgr.get_locale() == "en")
			var char_name = display_name
			if char_name.ends_with(" ile Konuş"):
				char_name = char_name.replace(" ile Konuş", "")
			var susp_id = object_id.replace("npc_", "").replace("dr_", "")
			var s_data = GameState.get_suspect_data(susp_id) if GameState else {}
			if s_data and s_data.has("ad") and s_data["ad"] != "":
				char_name = s_data["ad"]
			prompt_label.text = ("[E] Talk: " if is_en else "[E] Konuş: ") + char_name
			prompt_label.visible = true
		else:
			prompt_label.visible = false

var pulse_tween: Tween = null

func pulse_highlight(duration: float = 1.6) -> void:
	if not visible or not is_inside_tree():
		return

	if pulse_tween and pulse_tween.is_valid():
		pulse_tween.kill()

	if highlight:
		highlight.visible = true
		highlight.border_color = Color(1.0, 0.88, 0.45, 0.95)
		highlight.border_width = 1.5
		highlight.modulate.a = 1.0

	if prompt_label:
		var lbl_text = get_localized_name()
		if object_id.begins_with("npc_"):
			lbl_text = "👤 " + lbl_text.replace(" ile Konuş", "").replace("Talk to ", "")
		prompt_label.text = lbl_text
		prompt_label.visible = true
		prompt_label.modulate.a = 1.0

	pulse_tween = create_tween()
	if highlight:
		pulse_tween.parallel().tween_property(highlight, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if prompt_label:
		pulse_tween.parallel().tween_property(prompt_label, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	pulse_tween.tween_callback(func():
		if not is_instance_valid(self): return
		if highlight and not is_highlighted:
			highlight.visible = false
		if prompt_label and not is_highlighted:
			prompt_label.visible = false
	)

func interact() -> void:
	var gs = get_node_or_null("/root/GameState")
	if gs:
		if not gs.inspected_objects.has(object_id):
			gs.inspected_objects.append(object_id)
			gs.inner_voice_count += 1

		if is_secret_drawer and not gs.inspected_objects.has(object_id + "_drawer"):
			gs.inspected_objects.append(object_id + "_drawer")
			gs.secret_drawers_opened += 1

	# Silas inspect animation
	var players = get_tree().get_nodes_in_group("player")
	var player_node: Node2D = players[0] if not players.is_empty() else null
	if player_node and player_node.has_method("play_inspect_lean") and not object_id.begins_with("npc_") and object_id != "silas_telephone":
		player_node.play_inspect_lean()

	# Handle NPC interrogation
	var suspect_id = ""
	if object_id == "npc_margaret_doyle":
		suspect_id = "margaret"
	elif object_id == "npc_julian_harlow":
		suspect_id = "julian"
	elif object_id == "npc_dr_hale":
		suspect_id = "hale"
	elif object_id == "npc_raymond_pike":
		suspect_id = "pike"
	elif object_id.begins_with("npc_"):
		suspect_id = object_id.trim_prefix("npc_")

	var eb = get_node_or_null("/root/EventBus")

	if suspect_id != "":
		# Face Silas directly when interrogated
		if player_node:
			var dx = player_node.global_position.x - global_position.x
			var face_dir = "right" if dx > 0 else "left"
			if npc_directional_textures.has(face_dir):
				current_npc_facing = face_dir
				npc_sprite.texture = npc_directional_textures[face_dir]

		if eb and eb.has_signal("interrogation_requested"):
			eb.interrogation_requested.emit(suspect_id)
		return

	if object_id == "silas_memory_wall":
		if eb and eb.has_signal("memory_wall_requested"):
			eb.memory_wall_requested.emit()
		return
	elif object_id == "silas_souvenir_shelf":
		if eb and eb.has_signal("souvenir_shelf_requested"):
			eb.souvenir_shelf_requested.emit()
		return
	elif object_id == "light_range_board":
		if eb and eb.has_signal("light_range_requested"):
			eb.light_range_requested.emit()
		return
	elif object_id == "ticket_booth":
		var loc_mgr = get_node_or_null("/root/LocalizationManager")
		var is_en = (loc_mgr and loc_mgr.get_locale() == "en")
		if gs and not gs.has_item("backstage_key"):
			var key_name = "Brass Backstage Key" if is_en else "Kulis Pirinç Anahtarı"
			var salts_name = "Soothing Smelling Salts" if is_en else "Yatıştırıcı Koklama Tuzu"
			gs.add_item("backstage_key", key_name)
			gs.add_item("smelling_salts", salts_name)
			var am = get_node_or_null("/root/AudioManager")
			if am and am.has_method("play_sfx"):
				am.play_sfx("evidence_found")
			var voice = "\"Inside the ticket booth drawer lies the backstage brass key and a vial of smelling salts left by the night guard. Exactly what I need.\"" if is_en else "\"Gişe çekmecesinin içinde nöbetçinin bıraktığı kulis pirinç anahtarı ve bir şişe yatıştırıcı koklama tuzu duruyor. Tam da ihtiyacım olan şeyler.\""
			if eb and eb.has_signal("inner_voice_requested"):
				eb.inner_voice_requested.emit(voice)
			return
		else:
			var voice = "\"The brass-barred ticket booth. The key and smelling salts have already been taken from the drawer.\"" if is_en else "\"Pirinç parmaklıklı bilet gişesi. Çekmecedeki anahtar ve koklama tuzunu zaten aldım.\""
			if eb and eb.has_signal("inner_voice_requested"):
				eb.inner_voice_requested.emit(voice)
			return
	elif object_id == "patch_tool_chest":
		if gs and gs.flags.get("patch_chest_opened", false):
			var loc_mgr = get_node_or_null("/root/LocalizationManager")
			var is_en = (loc_mgr and loc_mgr.get_locale() == "en")
			var msg = "\"The heavy chest is unlocked. The secret compartment lies empty.\"" if is_en else "\"Ağır sandığın kilidi zaten açık. Gizli bölme artık boş.\""
			if eb and eb.has_signal("inner_voice_requested"):
				eb.inner_voice_requested.emit(msg)
			return
		if eb and eb.has_signal("tumbler_lock_requested"):
			eb.tumbler_lock_requested.emit()
		return
	elif object_id == "study_locked_safe_letters":
		if gs and (gs.flags.get("harlow_safe_opened", false) or gs.has_evidence("E07")):
			var loc_mgr = get_node_or_null("/root/LocalizationManager")
			var is_en = (loc_mgr and loc_mgr.get_locale() == "en")
			var msg = "\"The steel wall safe is open. The threat letters have already been recovered.\"" if is_en else "\"Çelik duvar kasası açık. Tehdit mektuplarını zaten aldım.\""
			if eb and eb.has_signal("inner_voice_requested"):
				eb.inner_voice_requested.emit(msg)
			return
		if eb and eb.has_signal("safe_dial_requested"):
			eb.safe_dial_requested.emit()
		return
	elif object_id == "military_crate":
		if gs and not gs.flags.get("crane_winch_lowered", false):
			var loc_mgr = get_node_or_null("/root/LocalizationManager")
			var is_en = (loc_mgr and loc_mgr.get_locale() == "en")
			var msg = "\"The heavy military contraband crate is suspended high above on the crane cable. I need to calibrate and engage the winch from the warehouse fuse panel to lower it.\"" if is_en else "\"Mühürsüz askerî sandık vinç makarasıyla metrelerce yukarıda asılı duruyor. İndirmek için ambar içindeki şalter panosundan vinci kalibre edip çalıştırmam gerek.\""
			if eb and eb.has_signal("inner_voice_requested"):
				eb.inner_voice_requested.emit(msg)
			return
	elif object_id in ["warehouse_hoist", "fuse_box"]:
		if gs and gs.flags.get("crane_winch_lowered", false):
			var loc_mgr = get_node_or_null("/root/LocalizationManager")
			var is_en = (loc_mgr and loc_mgr.get_locale() == "en")
			var msg = "\"The winch circuit is active. The military contraband crate has already been lowered to the deck.\"" if is_en else "\"Vinç devresi devrede. Mühürsüz askerî sandık zaten ambar zeminine indirildi.\""
			if eb and eb.has_signal("inner_voice_requested"):
				eb.inner_voice_requested.emit(msg)
			return
		if eb and eb.has_signal("crane_winch_requested"):
			eb.crane_winch_requested.emit()
		return
	elif object_id == "silas_telephone":
		var office_nodes = get_tree().get_nodes_in_group("office_hub")
		if not office_nodes.is_empty():
			office_nodes[0].answer_phone()
			return
	elif object_id == "silas_office_door":
		var office_nodes = get_tree().get_nodes_in_group("office_hub")
		if not office_nodes.is_empty():
			office_nodes[0].on_door_interacted()
			return
	elif object_id == "silas_rejection_letter":
		if eb:
			var loc_mgr = get_node_or_null("/root/LocalizationManager")
			var is_en = (loc_mgr and loc_mgr.get_locale() == "en")
			var title = "MINISTRY OF WAR REJECTION LETTER" if is_en else "SAVAŞ BAKANLIĞI RET MEKTUBU"
			var desc = "\"No records exist in our archives regarding the specified date and operation.\" — Fourth rejection in three months. They can erase the files, but they cannot erase the snow from my mind." if is_en else "\"Belirttiğiniz tarihe ve operasyona dair arşivlerimizde herhangi bir kayıt bulunmamaktadır.\" — Üç ayda dördüncü ret mektubu. Gerçeği dosyalardan silebilirler ama zihnimdeki karları silemezler."
			var alt_desc = "An empty glass on the desk, flickering lamplight, and an officially sealed rejection letter." if is_en else "Masanın üzerindeki boş kadeh, titrek lamba ışığı ve resmi mühürlü ret mektubu."
			eb.inspect_custom_requested.emit(
				title,
				desc,
				"res://assets/sprites/story/story_ministry_letter.png",
				"res://assets/sprites/inspect/inspect_silas_ministry_desk.png",
				alt_desc
			)
		return
	elif object_id == "silas_pocket_watch":
		if eb:
			var loc_mgr = get_node_or_null("/root/LocalizationManager")
			var is_en = (loc_mgr and loc_mgr.get_locale() == "en")
			var title = "STOPPED POCKET WATCH" if is_en else "DURMUŞ CEP SAATİ"
			var desc = "Hands frozen at 03:12. Time stopped for me that night." if is_en else "Akrep ve yelkovan 03:12'de donup kalmış. O geceden beri zaman benim için durdu."
			var alt_desc = "A faded military engraving on the back: 'K-1'. The command watch of the Northern Unit." if is_en else "Arka kapakta silik bir askerî oyma: 'K-1'. Kuzey Birliği'nin komuta saati."
			eb.inspect_custom_requested.emit(
				title,
				desc,
				"res://assets/sprites/story/story_pocket_watch_front.png",
				"res://assets/sprites/story/story_pocket_watch_back.png",
				alt_desc
			)
		return

	# Check key requirement if locked
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = (loc_mgr and loc_mgr.get_locale() == "en")

	if required_key_id != "":
		if gs and not gs.has_item(required_key_id):
			var am = get_node_or_null("/root/AudioManager")
			if am and am.has_method("play_sfx"):
				am.play_sfx("door_locked")
			var msg = locked_message
			if msg.is_empty():
				msg = "Locked. A proper key is required." if is_en else "Kilitli. Açmak için uygun bir anahtar gerekiyor."
			if eb and eb.has_signal("inner_voice_requested"):
				eb.inner_voice_requested.emit("\"" + msg + "\"")
			return
		elif gs and gs.has_item(required_key_id):
			required_key_id = "" # Unlocked
			if eb and eb.has_signal("toast_requested"):
				var toast_txt = "🔑 Unlocked: " if is_en else "🔑 Kilit Açıldı: "
				eb.toast_requested.emit(toast_txt + get_localized_name())

	# Direct inventory item pickup
	if object_id.begins_with("item_"):
		var item_key = object_id.replace("item_", "")
		if gs:
			gs.add_item(item_key, get_localized_name())
		var am = get_node_or_null("/root/AudioManager")
		if am and am.has_method("play_sfx"):
			am.play_sfx("evidence_found")
		visible = false
		if area_2d:
			area_2d.monitoring = false
			area_2d.monitorable = false
			var col = area_2d.get_node_or_null("CollisionShape2D")
			if col:
				col.set_deferred("disabled", true)
		if eb:
			eb.inner_voice_requested.emit(get_localized_inner_voice())
		return

	# Handle Evidence inspection
	var voice_text = ""
	if evidence_id != "" and gs:
		var ev_data = gs.get_evidence_data(evidence_id)
		if ev_data:
			gs.add_evidence(evidence_id)
			voice_text = ev_data.get("ic_ses_yorumu", "")
			if eb:
				eb.inspect_evidence_requested.emit(evidence_id)

			# Disappear or mark as inspected
			if evidence_id in FIXED_OBSERVATION_EVIDENCE:
				is_inspected = true
				if highlight:
					highlight.border_color = Color(0.4, 0.45, 0.5, 0.35)
			else:
				# Collectible disappears into the bag!
				visible = false
				if prop_sprite:
					prop_sprite.visible = false
				if highlight:
					highlight.visible = false
				if prompt_label:
					prompt_label.visible = false
				if area_2d:
					area_2d.monitoring = false
					area_2d.monitorable = false
					var col = area_2d.get_node_or_null("CollisionShape2D")
					if col:
						col.set_deferred("disabled", true)

			# Trigger Flashback FB01 if discovering E16 for the first time
			if evidence_id == "E16" and not gs.flags.get("fb01_played", false):
				gs.flags["fb01_played"] = true
				if eb:
					eb.flashback_requested.emit("FB01")

			# Add gatekeeper item when discovering E209 (Gece İzin Belgesi)
			if evidence_id == "E209":
				if gs and not gs.has_item("night_pass"):
					var pass_name = "Sealed Night Permit" if is_en else "Mühürlü Gece İzin Belgesi"
					gs.add_item("night_pass", pass_name)

			# Trigger Flashback FB02 if discovering E205 (Telsiz Defteri)
			if evidence_id == "E205" and not gs.flags.get("fb02_played", false):
				gs.flags["fb02_played"] = true
				if eb:
					eb.flashback_requested.emit("FB02")

	if evidence_id == "":
		voice_text = get_localized_inner_voice()
		if eb:
			eb.inner_voice_requested.emit(voice_text)
