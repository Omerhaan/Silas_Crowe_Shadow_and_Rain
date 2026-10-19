# -*- coding: utf-8 -*-
import os

base_dir = r"docs/vault"

files = {
    "00 - Genel Bakis/Ana Dizin.md": """# Silas Crowe: Shadow & Rain — Ana Dizin (MOC)

> **Proje:** 2D Pixel-Art Noir Dedektiflik Oyunu  
> **Motor:** Godot 4.3 (GDScript)  
> **Geliştirici:** Ömerhan Ulusoy  
> **Evren:** 1940'lar Savaş Sonrası İngiltere

---

## 📂 İçerik Haritası

### 🕵️ Karakterler
- [[Silas Crowe]] — Baş Karakter & Özel Dedektif
- [[Julian Harlow]] — Mirasçı (Vaka 1)
- [[Margaret Doyle]] — Kâhya (Vaka 1)
- [[Raymond Pike]] — Aile Avukatı (Vaka 1)
- [[Dr Victor Hale]] — Aile Hekimi (Vaka 1)
- [[Teddy Marsh]] — Silas'ın Eski Telsizcisi & Kurban (Vaka 2)
- [[Elias Wren]] — Eski Keskin Nişancı (Vaka 3)
- [[Madame Vane]] — Opera Direktörü (Vaka 3)

### 📁 Vakalar (Sezon 1)
- [[Vaka 01 - Karanlık Malikâne]] — Kilitli oda cinayeti (Lord Edmund Harlow)
- [[Vaka 02 - Sisli Liman]] — Rıhtımda vinç sabotajı (Teddy Marsh)
- [[Vaka 03 - Kör Nokta]] — Kraliyet Operası'nda tiyatral suikast

### 🏛️ Mekanlar
- [[Silas Dedektiflik Ofisi]] — Hub / Merkez Oda
- [[Harlow Malikânesi]] — 1. Vaka Mekanı
- [[Greywater Rıhtımı]] — 2. Vaka Mekanı
- [[Kraliyet Operası]] — 3. Vaka Mekanı

### 🧩 Bulmacalar & Sistemler
- [[Dedüksiyon Tahtası]] — Fair-play delil birleştirme mantığı
- [[Döner Diskli Kasa (Safe Dial)]] — Harlow kasası mekaniği (1944)
- [[Vinç Şalter Panosu (Crane Winch)]] — Rıhtım vinç kalibrasyonu (230)
- [[Tambur Kilit (Tumbler Lock)]] — Opera alet sandığı kilidi (112)
- [[Optik Işık Köprüsü (Light Range)]] — Kör nokta ve spot aydınlatma bulmacası

### ⚙️ Teknik Mimari
- [[Godot Mimarisi ve Autoloads]] — Singleton yöneticileri ve state yönetimi
- [[EventBus Sinyal Haritası]] — Modüller arası olay iletişimi
- [[Kontroller ve Platformlar]] — PC & Mobil dokunmatik şeması
""",

    "00 - Genel Bakis/Hikaye ve Evren.md": """# Hikaye ve Evren

#lore #atmosfer #noir

## Zaman ve Mekan
- **Dönem:** 1940'ların sonu, İkinci Dünya Savaşı sonrası İngiltere.
- **Şehir:** Greywater — Sürekli yağmur yağan, sanayileşmiş, gri tonların ve dumanın hakim olduğu kurgusal bir liman ve kültür kenti.

## Ana Temalar
1. **Savaş Sonrası Travması:** [[Silas Crowe]] ve [[Teddy Marsh]] gibi eski askerlerin sivil hayata tutunma çabası.
2. **Karanlık ve Yağmur:** Görsel olarak monokrom noir atmosferi, ışık-gölge kontrastı (Chiaroscuro).
3. **Fair-Play Dedektiflik:** Oyuncudan hiçbir delil gizlenmez; doğru sonuca ulaşmak için tahmin değil mantıksal çıkarım gerekir.

## Bağlantılar
- [[Silas Crowe]]
- [[Silas Dedektiflik Ofisi]]
- [[Vaka 01 - Karanlık Malikâne]]
""",

    "01 - Karakterler/Silas Crowe.md": """# Silas Crowe

#karakter #protagonist

- **Meslek:** Özel Soruşturma Ajanı / Dedektif
- **Geçmiş:** Kraliyet Piyadeleri eski askeri (İstihbarat / Keşif).
- **Merkez:** [[Silas Dedektiflik Ofisi]]

## Özellikleri
- Sakin, metodik ve gözlemci.
- Yağmurlu günlerde bacağındaki eski şarapnel yarası sızlar.
- Defterine aldığı notlar ve deliller arasında mantıksal bağ kurarak gerçeğe ulaşır ([[Dedüksiyon Tahtası]]).

## Dahil Olduğu Olaylar
- [[Vaka 01 - Karanlık Malikâne]] — Lord Harlow'un şüpheli ölümünü araştırır.
- [[Vaka 02 - Sisli Liman]] — Eski cephe arkadaşı [[Teddy Marsh]]'ın cinayetini çözer.
- [[Vaka 03 - Kör Nokta]] — Operadaki keskin nişancı [[Elias Wren]] ile yüzleşir.
""",

    "01 - Karakterler/Julian Harlow.md": """# Julian Harlow

#karakter #vaka1 #supheli

- **Konum:** Harlow Ailesi'nin tek varisi.
- **İlişki:** Maktul Lord Edmund Harlow'un oğlu.
- **Mekan:** [[Harlow Malikânesi]]

## Şüpheler & Profil
- Kumar borçları ve babasının servetine acil ihtiyaç duyması.
- Olay gecesi çalışma odasının anahtarını kaybettiğini iddia etmiştir.
- [[Raymond Pike]] ile miras konusunda gerilim yaşamaktadır.
""",

    "01 - Karakterler/Margaret Doyle.md": """# Margaret Doyle

#karakter #vaka1 #supheli

- **Konum:** Malikânenin 20 yıllık baş kâhyası.
- **Mekan:** [[Harlow Malikânesi]]

## Bilgiler & İpuçları
- Lord'un son akşam içtiği çayı hazırlayan kişi.
- Evdeki kilitli dolapların ve [[Döner Diskli Kasa (Safe Dial)]] odasının anahtarlarına erişimi vardır.
- Mutfakta bulunan kırık fincan ve digitalis kalıntısı üzerinde ifadesi alınmıştır.
""",

    "01 - Karakterler/Raymond Pike.md": """# Raymond Pike

#karakter #vaka1 #supheli

- **Meslek:** Harlow ailesinin kıdemli hukuk danışmanı ve vasiyet yöneticisi.
- **Mekan:** [[Harlow Malikânesi]]

## Notlar
- Lord Harlow'un vasiyetini cinayetten 2 gün önce değiştirmeyi planladığını bilmektedir.
- Malikânedeki bilardo salonunda bulunan yırtılmış evrak parçaları onun daktilosuyla eşleşir.
""",

    "01 - Karakterler/Dr Victor Hale.md": """# Dr. Victor Hale

#karakter #vaka1 #supheli

- **Meslek:** Lord Edmund Harlow'un şahsi hekimi.
- **Mekan:** [[Harlow Malikânesi]]

## Tıbbi Deliller
- Lord'a reçete edilen kalp ilacı (digitalis purpurea) dozajını kontrol eden tek kişi.
- Çalışma odasında bulunan kimyasal tüp ve tentürdiyot şişesiyle bağlantılıdır.
""",

    "01 - Karakterler/Teddy Marsh.md": """# Teddy Marsh

#karakter #vaka2 #kurban

- **Geçmiş:** [[Silas Crowe]] ile aynı birlikte telsiz operatörü olarak görev yaptı.
- **Son Durum:** Greywater Rıhtımı 4 No'lu ambarda vinç yükünün altında kalarak hayatını kaybetti.
- **Mekan:** [[Greywater Rıhtımı]]

## Soruşturma
- Ölümünün bir iş kazası değil, [[Vinç Şalter Panosu (Crane Winch)]] kablolarına yapılan asit sabotajı olduğu ortaya çıkmıştır.
""",

    "01 - Karakterler/Elias Wren.md": """# Elias Wren

#karakter #vaka3 #supheli

- **Meslek:** Eski ordu keskin nişancısı.
- **Mekan:** [[Kraliyet Operası]]

## Suikast Ayrıntıları
- Operadaki 112. ölçüdeki sahte top atışının ses perdesini kullanarak Lord Danvers'ı vurmuştur.
- Işık köprüsündeki kör noktaları hesaplayarak kaçış rotası çizmiştir ([[Optik Işık Köprüsü (Light Range)]]).
""",

    "01 - Karakterler/Madame Vane.md": """# Madame Vane

#karakter #vaka3 #supheli

- **Konum:** Greywater Kraliyet Operası Baş Rejisörü.
- **Mekan:** [[Kraliyet Operası]]

## İfadeler
- Partitürdeki 112. ölçü değişikliğini onaylayan kişi.
- Kulisteki alet sandığının şifresini bilmektedir ([[Tambur Kilit (Tumbler Lock)]]).
""",

    "02 - Vakalar/Vaka 01 - Karanlık Malikâne.md": """# Vaka 01: Karanlık Malikâne

#vaka #cinayet #kilitlioda

- **Kurban:** Lord Edmund Harlow
- **Olay Yeri:** [[Harlow Malikânesi]] — Kilitli Çalışma Odası
- **Ölüm Sebebi:** Digitalis zehirlenmesi / Kalp yetmezliği süsü verilmiş cinayet

## Şüpheliler
- [[Julian Harlow]] — Mirasçı oğul
- [[Margaret Doyle]] — Kâhya
- [[Raymond Pike]] — Aile Avukatı
- [[Dr Victor Hale]] — Şahsi Doktor

## Kritik Bulmaca
- [[Döner Diskli Kasa (Safe Dial)]] — Çalışma odasındaki gizli çelik kasa (`1944`).

## Önemli Çıkarımlar
- Dedektif [[Silas Crowe]], odadaki yırtık vasiyet taslağı ve tıbbi şişeleri [[Dedüksiyon Tahtası]] üzerinde birleştirerek katilin kimliğini ortaya çıkarır.
""",

    "02 - Vakalar/Vaka 02 - Sisli Liman.md": """# Vaka 02: Sisli Liman

#vaka #sabotaj #cinayet

- **Kurban:** [[Teddy Marsh]] (Silas'ın eski telsizcisi)
- **Olay Yeri:** [[Greywater Rıhtımı]] — 4 No'lu Kargo Ambarı
- **Ölüm Sebebi:** Çelik vinç yükünün düşmesi sonucu ezilme

## Kritik Bulmaca
- [[Vinç Şalter Panosu (Crane Winch)]] — 3 fazlı vinç şalterinin voltaj kalibrasyonu (`230`).

## Deliller
- Asitle aşındırılmış çelik halat lifleri.
- Gece vardiyası sahte geçiş kartı.
- Karaborsa mühimmat sandığı damgası.

## Soruşturmacı
- [[Silas Crowe]]
""",

    "02 - Vakalar/Vaka 03 - Kör Nokta.md": """# Vaka 03: Kör Nokta

#vaka #suikast #opera

- **Kurban:** Lord Alistair Danvers
- **Olay Yeri:** [[Kraliyet Operası]] — Kraliyet Locası
- **Ölüm Sebebi:** 112. ölçüdeki top sesine denk getirilen keskin nişancı mermisi

## Şüpheliler
- [[Elias Wren]] — Eski keskin nişancı
- [[Madame Vane]] — Rejisör

## Kritik Bulmacalar
1. [[Tambur Kilit (Tumbler Lock)]] — Kulisteki pirinç tamburlu alet sandığı kilidi (`1-1-2`).
2. [[Optik Işık Köprüsü (Light Range)]] — Spot aydınlatma matrisi ve kör nokta simülasyonu.

## Final
- Silas, opera çatısındaki parapette katille yüzleşir.
""",

    "03 - Mekanlar/Silas Dedektiflik Ofisi.md": """# Silas Dedektiflik Ofisi

#mekan #hub

[[Silas Crowe]]'un Greywater şehir merkezindeki çatı katı çalışma ofisidir. Oyundaki tüm vakaların başlangıç ve dinlenme noktasıdır (Hub).

## İçerideki Önemli Objeler
- **Telefon:** Her vakanın başında çalar, ahize kaldırılınca olay brifingi başlar.
- **Hafıza Duvarı (Memory Wall):** Çözülen vakalardan toplanan hatıra objeleri sergilenir.
- **Daktilo & Arşiv:** Dosya kayıtları ve gazete küpürleri.
- **Pencere:** Dışarıdaki dinmeyen Greywater yağmurunu gösterir.

## Bağlantılar
- [[Vaka 01 - Karanlık Malikâne]]
- [[Vaka 02 - Sisli Liman]]
- [[Vaka 03 - Kör Nokta]]
""",

    "03 - Mekanlar/Harlow Malikânesi.md": """# Harlow Malikânesi

#mekan #vaka1

[[Vaka 01 - Karanlık Malikâne]]'nin geçtiği izole, Viktorya dönemi malikâne. Fırtına nedeniyle dış dünyayla bağlantısı kesilmiştir.

## Odalar
- **Ana Salon (Main Hall):** Giriş holü ve merdivenler.
- **Çalışma Odası (Study):** Cinayet mahalli ve [[Döner Diskli Kasa (Safe Dial)]].
- **Kütüphane (Library):** Lord'un gizli yazışmaları.
- **Yemek Odası (Dining Room):** Şüphelilerin toplandığı alan.
- **Mutfak (Kitchen):** İlaç ve zehir kalıntılarının arandığı oda.
- **Bilardo Salonu (Billiard Room):** [[Raymond Pike]] ile sorgu yapılan oda.
""",

    "03 - Mekanlar/Greywater Rıhtımı.md": """# Greywater Rıhtımı

#mekan #vaka2

[[Vaka 02 - Sisli Liman]] soruşturmasının yapıldığı, sisli ve nemli endüstriyel liman bölgesi.

## Alanlar
- **4 No'lu Ambar:** [[Teddy Marsh]]'ın cansız bedeninin bulunduğu yer.
- **Vinç Kontrol Kulesi:** [[Vinç Şalter Panosu (Crane Winch)]]'nun bulunduğu kumanda kabini.
- **Rıhtım İskelesi:** Kaçak yük teknelerinin yanaştığı sisli hat.
""",

    "03 - Mekanlar/Kraliyet Operası.md": """# Kraliyet Operası

#mekan #vaka3

[[Vaka 03 - Kör Nokta]] suikastının gerçekleştiği görkemli tiyatro binası.

## Katlar & Bölümler
- **Oditoryum & Kraliyet Locası:** Suikast hedefinin oturduğu koltuk.
- **Kulis (Backstage):** [[Tambur Kilit (Tumbler Lock)]] ile kilitli alet sandığı.
- **Işık Köprüsü (Light Bridge):** [[Optik Işık Köprüsü (Light Range)]] mekaniğinin çözüldüğü tavan iskelesi.
- **Çatı Parapeti:** Keskin nişancı [[Elias Wren]] ile final yüzleşmesi.
""",

    "04 - Bulmacalar ve Mekanikler/Dedüksiyon Tahtası.md": """# Dedüksiyon Tahtası

#mekanik #oynanis

Oyuncunun topladığı fiziksel delilleri birbiriyle eşleştirerek mantıksal çıkarımlar ürettiği sistemdir.

## İşleyiş
- Her delilin kendine ait bir kimliği (`E1`, `E2`, ...) vardır.
- Oyuncu Defter (Notebook) arayüzünde iki veya üç delili seçip "Birleştir" der.
- Mantıklı bir bağ varsa yeni bir **Dedüksiyon (`D1 - D306`)** oluşur.
- Yanlış eşleştirmelerde oyun ceza vermez, ancak ilerleme de sağlanmaz.

## Bağlantılar
- [[Silas Crowe]]
- [[Vaka 01 - Karanlık Malikâne]]
- [[Vaka 02 - Sisli Liman]]
- [[Vaka 03 - Kör Nokta]]
""",

    "04 - Bulmacalar ve Mekanikler/Döner Diskli Kasa (Safe Dial).md": """# Döner Diskli Kasa (Safe Dial)

#bulmaca #vaka1

- **Bulunduğu Yer:** [[Harlow Malikânesi]] — Çalışma Odası
- **Şifre:** `1944` (Lord Harlow'un oğlunun savaştan dönüş yılı)

## Mekanik
- Oyuncu disk kadranını saat yönünde ve saat yönünün tersine çevirerek 4 haneli kombinasyonu tutturur.
- Ses efektleri her doğru tık sesinde ipucu verir.
- Açıldığında içinden değiştirilmemiş orijinal vasiyetname çıkar.
""",

    "04 - Bulmacalar ve Mekanikler/Vinç Şalter Panosu (Crane Winch).md": """# Vinç Şalter Panosu (Crane Winch)

#bulmaca #vaka2

- **Bulunduğu Yer:** [[Greywater Rıhtımı]] — Vinç Kumanda Odası
- **Şifre / Hedef Voltaj:** `230`

## Mekanik
- 3 fazlı şalter anahtarları (`Faz A`, `Faz B`, `Faz C`) dengelenerek vinç motorunun aşırı yüklenme raporu simüle edilir.
- Doğru akım sağlandığında vincin fren balatasındaki mekanik asit aşınması raporlanır.
""",

    "04 - Bulmacalar ve Mekanikler/Tambur Kilit (Tumbler Lock).md": """# Tambur Kilit (Tumbler Lock)

#bulmaca #vaka3

- **Bulunduğu Yer:** [[Kraliyet Operası]] — Sahne Arkası Kulis
- **Kombinasyon:** `1 - 1 - 2` (Operadaki top sesinin çaldığı ölçü numarası)

## Mekanik
- 3 silindirik pirinç tambur yukarı-aşağı kaydırılarak hizalanır.
- Kilit açıldığında içinden keskin nişancı tüfeğinin temizleme bezi ve boş kovan çıkar.
""",

    "04 - Bulmacalar ve Mekanikler/Optik Işık Köprüsü (Light Range).md": """# Optik Işık Köprüsü (Light Range)

#bulmaca #vaka3

- **Bulunduğu Yer:** [[Kraliyet Operası]] — Tavan Işık Köprüsü

## Mekanik
- Tavandaki 4 adet dev projektörün açıları ayarlanır.
- Amaç: Sahnedeki ışık huzmelerini dengeleyerek keskin nişancının kraliyet locasını hedef alırken saklandığı **kör noktayı (Blind Spot)** açığa çıkarmak.
""",

    "05 - Teknik Mimari/Godot Mimarisi ve Autoloads.md": """# Godot Mimarisi ve Autoloads

#teknik #godot #mimari

Proje, Godot 4.3 üzerinde modüler ve olay güdümlü (event-driven) bir mimariyle geliştirilmiştir.

## Temel Autoload (Singleton) Yöneticileri

| Autoload | Dosya Yolu | Görevi |
| :--- | :--- | :--- |
| **`GameState`** | `scripts/autoload/game_state.gd` | Envanter, deliller, aktif vaka ve ilerleme değişkenlerini tutar. |
| **`EventBus`** | `scripts/autoload/event_bus.gd` | Sahneler arası sinyal köprüsüdür. Doğrudan referans bağını engeller. |
| **`AudioManager`** | `scripts/autoload/audio_manager.gd` | Dinamik yağmur sesleri, noir caz müzikleri ve UI SFX'lerini yönetir. |
| **`SaveSystem`** | `scripts/autoload/save_system.gd` | JSON tabanlı profil ve ilerleme kayıt sistemidir. |
| **`LocalizationManager`** | `scripts/autoload/localization_manager.gd` | Türkçe ve İngilizce dil çevirilerini yönetir. |
| **`CutsceneManager`** | `scripts/autoload/cutscene_manager.gd` | Sinematik geçişleri ve telefon sekanslarını kontrol eder. |
""",

    "05 - Teknik Mimari/EventBus Sinyal Haritası.md": """# EventBus Sinyal Haritası

#teknik #sinyal

Tüm sahneler doğrudan birbirine bağlanmak yerine `EventBus` üzerinden konuşur:

```gdscript
# Örnek Temel Sinyaller
signal clue_discovered(clue_id: String)
signal room_change_requested(target_room: String)
signal minigame_completed(minigame_id: String)
signal dialogue_started(dialogue_id: String)
signal phone_call_finished(case_id: String)
```

## Avantajları
- Bir sahne (örneğin bir oda) silinse veya değiştirilse bile diğer sistemler çökmez.
- Test dosyaları (`tests/`) sahneleri tek başına headless çalıştırabilir.
""",

    "05 - Teknik Mimari/Kontroller ve Platformlar.md": """# Kontroller ve Platformlar

#teknik #kontroller

Oyun hem masaüstü (Windows) hem mobil (Android dokunmatik) için tek bir girdi mantığıyla çalışır.

| Eylem | PC (Klavye & Fare) | Android Dokunmatik |
| :--- | :--- | :--- |
| **Yürüme** | `A / D` veya `← / →` | Zemine dokunma (Tap-to-move) |
| **İnceleme** | `E` veya `Boşluk` | Nesneye dokunma |
| **Kapıdan Geçiş** | `W` veya `↑` | Kapıya dokunma |
| **Defter Aç/Kapa** | `TAB` veya `Q` | Üst bardaki Defter simgesi |
| **Menü / İptal** | `ESC` | Ekrandaki Geri butonu |
"""
}

for rel_path, content in files.items():
    full_path = os.path.join(base_dir, rel_path)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    with open(full_path, "w", encoding="utf-8") as f:
        f.write(content.strip() + "\n")

print(f"{len(files)} Obsidian vault files created successfully.")
