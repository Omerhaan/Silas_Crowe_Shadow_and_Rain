# Gölge ve Yağmur (Shadow & Rain) — Silas Crowe Vakaları (1-3)
*2D Pixel-Art Noir Dedektiflik ve Araştırma Oyunu (Godot 4.3 — GDScript)*

![Godot Engine](https://img.shields.io/badge/Godot-v4.3--stable-478cbf?logo=godotengine&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Android-green)
![Tests](https://img.shields.io/badge/Tests-100%25%20Passing-brightgreen)
![License](https://img.shields.io/badge/License-MIT-blue)

1940'lar savaş sonrası İngiltere'sinde, geçmişiyle yüzleşen eski asker ve özel dedektif **Silas Crowe**'un adımlarını takip edin. Dinmeyen yağmur, karanlık sırlar, döner diskli çelik kasalar, vinç kalibrasyonları ve optik kör nokta bulmacalarıyla örülü 3 kapsamlı cinayet soruşturmasını çözün.

---

## 🕵️ Vakalar (Sezon 1)

1. **Bölüm 1: Karanlık Malikâne (Harlow Cinayeti)**
   - *Yer:* Fırtınanın yolları kapattığı izole Harlow Malikânesi.
   - *Olay:* Lord Edmund Harlow kilitli çalışma odasında ölü bulunur.

2. **Bölüm 2: Sisli Liman (Teddy Marsh Cinayeti)**
   - *Yer:* Greywater Rıhtımı ve yük ambarları.
   - *Olay:* Silas'ın eski ordu telsizcisi tonlarca çelik vinç yükünün altında ezilir.

3. **Bölüm 3: Kör Nokta (Kraliyet Operası Suikastı)**
   - *Yer:* Greywater Kraliyet Operası.
   - *Olay:* 112. ölçüdeki tiyatral top sesinin ses perdesi olarak kullanıldığı profesyonel bir keskin nişancı suikastı.

---

## 🎮 Kontroller (PC & Dokunmatik Uyumlu)

| Eylem | PC (Klavye / Fare) | Dokunmatik / Mobil |
| :--- | :--- | :--- |
| **Yürüme** | **A / D** veya **← / →** | Zemine dokun (Tap-to-move) |
| **Etkileşim / İnceleme** | **E** veya **Boşluk** | Nesneye dokun (Tap-to-interact) |
| **Kapı / Oda Geçişi** | **W** veya **↑** | Kapıya dokun |
| **Dedektif Defteri** | **TAB** veya **Q** | Üst bardaki **Defter** butonu |
| **Hızlı Oda Geçişi (HUD)** | **1 / 2 / 3** | Alt gezinme butonları (kilit korumalı) |
| **Şifre / Minigame Girişi** | **Rakam Tuşları + Enter** | Ekrana dokunarak çevirme / kaydırma |
| **İptal / Menüden Çıkış** | **ESC** | Ekrandaki **Kapat / Menü** butonu |

---

## 🛠️ Temel Sistemler ve Mimari

- **Tam Modüler Vaka Mimarisi:** Her vaka kendi odalarını, delillerini, şüphelilerini, diyaloglarını ve sinematiklerini bağımsız JSON/TSCN modülleri olarak taşır.
- **Fair-Play Dedüksiyon Sistemi:** Tahmin yok; toplanan fiziksel delilleri Defter üzerinden birleştirerek mantıksal çıkarımlar (`D1-D306`) üretme.
- **İnteraktif Minigameler:**
  - Harlow çelik kasa kadranı (rotary dial).
  - Rıhtım vinç şalteri (crane winch phase controller).
  - Tiyatro alet sandığı mekanik tambur kilidi (tumbler lock).
  - Opera ışık köprüsü aydınlatma & kör nokta matrisi (light-range matrix).
- **Zil Sesi, Titreşim ve Sinematik Geçiş Akışı:** Her vaka Silas'ın ofisinde çalan telefonla başlar; ses ve görsel efektlerin ardından sinematik yolculuk ve olay yerine varış gerçekleşir.
- **Çift Dil Desteği:** Türkçe ve İngilizce tam yerelleştirme desteği (`LocalizationManager`).
- **Otomasyon Testleri:** Headless olarak çalışan 4 ayrı regresyon ve mantık doğrulama test süiti (%100 geçiş).

---

## 🚀 Projeyi Çalıştırma

### Godot Editörü ile:
1. [Godot Engine 4.3 Stable](https://godotengine.org) sürümünü indirin.
2. `project.godot` dosyasını Godot ile açın.
3. `F5` tuşuna basarak oyunu başlatın.

### Testleri Çalıştırma (Headless):
```bash
godot --headless --scene "res://tests/test_menu_and_case_flow.tscn"
godot --headless --scene "res://tests/test_all_cases_progression.tscn"
godot --headless --scene "res://tests/test_minigame_effects_and_nav_locks.tscn"
godot --headless --scene "res://tests/test_case03_full_puzzles.tscn"
```
