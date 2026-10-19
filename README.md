# Gölge ve Yağmur — Vaka 1: "Karanlık Malikane"
*2D Pixel Art Noir Dedektiflik ve Araştırma Oyunu (Godot 4.3 — GDScript)*

Bu proje, 1940'lar noir atmosferinde geçen, derin hikâye anlatımına ve adil dedüksiyon (fair-play) mekaniklerine sahip bir cinayet & gizem çözme oyunudur.

---

## 🎮 Kontroller (PC & Dokunmatik Uyumlu)

| Eylem | PC (Klavye / Fare) | Dokunmatik / Mobil |
| :--- | :--- | :--- |
| **Yürüme** | **A / D** veya **← / →** | Zemine dokun (Tap-to-move) |
| **Etkileşim / İnceleme** | **E** veya **Boşluk** | Nesneye dokun (Tap-to-interact) |
| **Kapı / Geçiş** | **W** veya **↑** | Kapıya dokun |
| **Dedektif Defteri** | **TAB** | Ekranda sabit **Defter** butonu |
| **Katili Suçla** | — | Üst bardaki **Suçla** butonu |
| **İptal / Menü** | **ESC** | Ekranda **⚙ (Menü)** butonu |

---

## 🔍 Temel Sistemler ve Mekanikler

1. **İkili Girdi Mimarisi (`InputManager`):** Klavye, fare ve dokunmatik girişleri tek bir soyutlama katmanından geçirir; hiçbir mekanik hover bağımlı değildir. Tüm butonlar minimum 24x24 oyun pikseli boyutundadır.
2. **Prolog & Telefon Açılışı:** Silas'ın dairesinde başlayan açılış sinematiği, 3 seçenekli ikna diyaloğu ve köprünün çöküşü ile Harlow Malikanesi'ne varış.
3. **Yakın Plan İnceleme (`InspectView`):** Kanıtları (kırık cep saati, konyak kadehi, yırtık reçete vb.) yakından inceleme ve arka kapağı açarak `K-5` askerî oymasını keşfetme.
4. **Flashback Sistemi (FB01 "Kar"):** E16 rozeti bulunduğunda tetiklenen, solgun paletli, şok dalgalı ve çift anlamlı *"Git!"* anısı.
5. **Dedektif Defteri (6 Sekme):**
   - *Kanıtlar:* 17 kanıtın listesi ve yakın plan incelemesi.
   - *İfadeler:* Şüphelilerin ifade tutanakları.
   - *Zaman Çizelgesi:* 20:00 - 23:00 kronolojik akış.
   - *Çıkarımlar (Dedüksiyon):* Tap-to-select ile iki kanıtı eşleştirip `Birleştir` butonuyla D1-D10 çıkarımlarını yapma.
   - *Şüpheliler:* Margaret, Julian, Dr. Hale ve Raymond Pike profilleri.
   - *Harita:* Malikanenin 2 katlı kesit şeması ve mevcut konum göstergesi.
6. **Sorgulama & İtiraz (Objection):** Şüphelilere ifade ve çelişkilerine göre toplanan delilleri sunma mekanizması.
7. **Suçlama & Yüzleşme Finali:** Katil, yöntem ve 3 kilit delili seçerek Dr. Hale ile yüzleşme.
8. **Anı Duvarı & Hatıra Rafı:** Hub'a dönüşte 9 saat yuvası (K-1 ve K-5 dolu, K-2 boş), birlik fotoğrafı ve seçilen hatıra eşyası.
9. **İkinci Telefon Araması:** Vaka tamamlandığında çalan ikinci arama: *"İlk kapı açıldı. Sıradaki seni bekliyor."*

---

## 📁 Proje Klasör Yapısı

```
├── data/                      # Tüm JSON veri tabanları (Sıfır hardcoded metin)
│   ├── cases/case01/          # Vaka 1 kanıt, şüpheli, dedüksiyon ve diyalogları
│   ├── cutscenes/             # Sinematik ve flashback JSON verileri
│   ├── hub/                   # Başarım ve hatıra verileri
│   └── story/                 # Gizli Kuzey Birimi arka plan verisi
├── scenes/                    # Godot .tscn sahne dosyaları
│   ├── cutscenes/             # Sinematikler (Giriş, FB01, Yüzleşme, İkinci Arama)
│   ├── entities/              # Oyuncu, kapı ve etkileşimli nesneler
│   ├── hub/                   # Silas'ın ofisi, Anı Duvarı ve Hatıra Rafı
│   ├── rooms/                 # Harlow Malikanesi 7 odası
│   ├── tests/                 # Otomasyon test sahneleri
│   ├── ui/                    # HUD, Defter, İnceleme, Sorgulama ve Suçlama modalları
│   └── main.tscn              # Ana oyun sahnesi
├── scripts/                   # GDScript kaynak kodları
│   ├── autoload/              # EventBus, GameState, InputManager, AudioManager, vb.
│   └── ...                    # Modüler kontrolcü sınıfları
├── godot_oyna.bat             # Tek tıkla oyunu başlatan Windows betiği
└── project.godot              # Godot 4.3 proje yapılandırması
```

---

## 🚀 Oyunu Başlatma

Windows ortamında oyunu çalıştırmak için:

1. Masaüstündeki proje klasöründe bulunan **`godot_oyna.bat`** dosyasına çift tıklayın.
2. Veya Godot Editor içerisinden `scenes/main.tscn` sahnesini çalıştırın.
