# Harlow Malikânesi ve Ofis Oda Bağlantıları Tablosu (v0.9.4)

Bu belge, oyundaki tüm odaların çıkış noktalarını, geçiş türlerini, arka plan plakasındaki görsel durumlarını ve spawn koordinatlarını listeler. Malikâne zemin katındaki odalar tutarlı bir doğrusal mimariyle düzenlenmiştir: Mutfak ◀──▶ Yemek Odası ◀──▶ Ana Hol ◀──▶ Kütüphane ◀──▶ Bilardo Odası. Ana Hol'den ayrıca Çalışma Odası (Kuzey/Yukarı) ve Üst Kat Koridoru (Merdiven) bağlantıları bulunur.

---

## 1. Genel Kurallar ve Standartlar
1. **Kapı Hotspot'u:** Yalnızca odanın arka plan plakasında somut olarak çizilmiş bir kapı varsa yerleştirilir. Hotspot doğrudan plaka kapısının üzerine oturur.
2. **Kilitli / Hedefsiz Kapılar:** Malikâneden dışarı açılan kapılar (Ana Hol Ön Kapısı, Mutfak Arka Çıkışı) hedefsizdir; etkileşimde uygun kilit / atmosfer iç sesi verir.
3. **Ekran Kenarı Ok Butonları:** Plakada çizili kapısı bulunmayan oda geçişleri ekranın alt köşelerindeki yön butonları (`NavLeftButton`, `NavRightButton`, boyutu $\ge 36\times 36$ px, yanında hedef oda adı yazılı) ile gerçekleştirilir.
4. **Tutarlılık:** Tüm oda geçişleri iki yönlü simetriye sahiptir ($A$'nın solu $B$ ise, $B$'nin sağı $A$'dır).

---

## 2. Oda Bağlantı Tablosu

| Oda | Çıkış / Geçiş Türü | Plakada Görünüyor mu? | Konum (x, y) | Hedef Oda | Spawn Noktası | Notlar / Durum |
| :--- | :--- | :---: | :---: | :--- | :--- | :--- |
| **Silas'ın Ofisi** (`silas_office`) | Kapı | Evet (Sağ Duvar) | (450, 245) | `main_hall` | default | Durum makinesine bağlı: Arama öncesi kilitli ("Bu yağmurda dışarı çıkacak..."), arama sonrası yolculuk sinematiğiyle geçiş, vaka sonu ("Sıradaki vaka...") |
| **Ana Hol** (`main_hall_v2`) | Merdiven | Evet (Sol Merdiven) | (50, 245) | `upper_floor` | `from_main_hall` | Üst kata tırmanış merdiveni |
| **Ana Hol** (`main_hall_v2`) | Kapı (Merdiven Yanı) | **Evet (v2 Plakası)** | (95, 245) | `study` | `from_main_hall` | **Çalışma Odası Kapısı**: Merdivenin sağındaki somut ahşap kapı |
| **Ana Hol** (`main_hall_v2`) | Kapı (Ön Kapı) | Evet (Sağ Taraf) | (415, 238) | *Yok (Kilitli)* | - | "Köprü çöktü. Sabaha kadar kimse gelip gidemez." |
| **Ana Hol** (`main_hall_v2`) | Kapı / Ok (Sol Duvar) | Evet | (18, 245) | `dining_room` | `from_main_hall` | `◀ Yemek Odası` |
| **Ana Hol** (`main_hall_v2`) | Kapı / Ok (Sağ Duvar) | Evet | (462, 245) | `library` | `from_main_hall` | `Kütüphane ▶` |
| **Çalışma Odası** (`study`) | Kapı | Evet (Sağ Duvar) | (445, 245) | `main_hall` | `from_study` | **TEK ÇIKIŞ**: Sağ duvardaki ahşap kapı $\rightarrow$ Ana Hol |
| **Yemek Odası** (`dining_room_v2`) | Kapı (Sol Duvar) | **Evet (v2 Plakası)** | (32, 245) | `kitchen` | `from_dining_room` | **Mutfak Kapısı**: Sol duvardaki somut kapı |
| **Yemek Odası** (`dining_room_v2`) | Kapı (Sağ Duvar) | Evet (Sağ Duvar) | (448, 245) | `main_hall` | `from_dining_room` | **Ana Hol Kapısı**: Hol'de soldan ($x \approx 40$) spawn |
| **Mutfak** (`kitchen`) | Kapı (Arka Çıkış) | Evet (Sol Duvar) | (25, 245) | *Yok (Kilitli)* | - | "Köprü çöktü. Sabaha kadar kimse gelip gidemez." |
| **Mutfak** (`kitchen`) | Kapı / Ok (Sağ Duvar) | Evet | (462, 245) | `dining_room` | `from_kitchen` | `Yemek Odası ▶` |
| **Kütüphane** (`library_v2`) | Kapı / Ok (Sol Duvar) | Evet | (25, 245) | `main_hall` | `from_library` | `◀ Ana Hol`: Hol'de sağdan ($x \approx 440$) spawn |
| **Kütüphane** (`library_v2`) | Kapı (Sağ Duvar) | **Evet (v2 Plakası)** | (465, 245) | `billiard_room` | `from_library` | **Bilardo Odası Kapısı**: Sağ duvardaki somut kapı |
| **Bilardo Odası** (`billiard_room`) | Kapı (Sol Duvar) | Evet | (18, 245) | `library` | `from_billiard_room` | `◀ Kütüphane` |
| **Üst Kat** (`upper_floor`) | Merdiven | Evet (Sol Alt) | (10, 245) | `main_hall` | `from_upper_floor` | Alt kata iniş merdiveni |
| **Üst Kat** (`upper_floor`) | Kapı (Sol) | Evet (Sol Kapı) | (62, 245) | `julian_room` | `from_corridor` | Julian'ın odasına giriş |
| **Üst Kat** (`upper_floor`) | Kapı (Orta) | Evet (Orta Çift Kapı) | (236, 245) | `harlow_bedroom` | `from_corridor` | Harlow'un yatak odasına giriş |
| **Üst Kat** (`upper_floor`) | Kapı (Sağ) | Evet (Sağ Kapı) | (444, 245) | `pike_room` | `from_corridor` | Pike'ın odasına giriş |
| **Harlow'un Odası** (`harlow_bedroom`) | Ok (Sol Alt Köşe) | Hayır ($\ge 36\times 36$) | Sol Alt (x: 6, y: 228) | `upper_floor` | `from_harlow_bedroom` | `◀ Koridor` |
| **Julian'ın Odası** (`julian_room`) | Ok (Sol Alt Köşe) | Hayır ($\ge 36\times 36$) | Sol Alt (x: 6, y: 228) | `upper_floor` | `from_julian_room` | `◀ Koridor` |
| **Pike'ın Odası** (`pike_room`) | Ok (Sol Alt Köşe) | Hayır ($\ge 36\times 36$) | Sol Alt (x: 6, y: 228) | `upper_floor` | `from_pike_room` | `◀ Koridor` |

---

## 3. Spawn ve Ayak Çizgisi Doğrulaması
- **Standart Zemin Düzlemi (Ayak Çizgisi):** $y = 245.0 \text{ px}$
- **Tüm Giriş Spawn Noktaları:** $y = 245.0 \text{ px}$
- **Karakter Boyutları ve Konumlandırma:**
  - Silas Crowe: $100 \text{ px}$ görünen boy, $y = 245.0$ taban çizgisi
  - Dr. Victor Hale: $102 \text{ px}$ görünen boy, $y = 245.0$ taban çizgisi (Kütüphane $x = 195$)
  - Raymond Pike: $98 \text{ px}$ görünen boy, $y = 245.0$ taban çizgisi (Yemek Odası $x = 135$)
  - Margaret Doyle: $94 \text{ px}$ görünen boy, $y = 245.0$ taban çizgisi (Mutfak $x = 215$)
  - Julian Harlow: $98 \text{ px}$ görünen boy, $y = 245.0$ taban çizgisi (Bilardo Odası $x = 330$)
  - Edmund Harlow (Ceset): $98 \text{ px}$ referans boy, Çalışma Odası masasında $y = 182$
