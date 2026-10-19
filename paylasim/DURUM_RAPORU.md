# Silas Crowe: Shadow & Rain — Proje Durum Raporu
**Tarih:** 16 Ekim 2026  
**Motor:** Godot Engine v4.3-stable (GL Compatibility)  
**Hedef Platformlar:** Android (Mobil) & Windows (PC)  
**Mevcut Aşama:** 1. Oyun ("Silas Crowe: Shadow & Rain" — Vaka 1 + 2 + 3) Kilitli Kapı Engellemeleri, Klavye Giriş Desteği, Dinamik Işık-Menzil Efektleri, Telefon-Sinematik Akışı ve Tam Test Kapsamıyla %100 Doğrulandı!

---

## 1. Oyun & Üçleme Yapısı
- **Seri Adı:** *Silas Crowe*
- **1. Oyun:** **Silas Crowe: Shadow & Rain** (Vaka 1: Karanlık Malikâne, Vaka 2: Sisli Liman, Vaka 3: Kör Nokta)
- **2. Oyun (Planlanan):** **Silas Crowe: Ash & Steel** (Vaka 4, 5, 6)
- **3. Oyun (Planlanan):** **Silas Crowe: Ice & Blood** (Vaka 7, 8 + Epilog)

---

## 2. Son Eklenen Sistemler ve İyileştirmeler (16 Ekim 2026)

### 1. Işık ve Menzil Panosu (Kör Nokta Minigame) Dinamik Görsel Motoru
- **Canlı Spot Işık Konileri:** Spot A (Altın Sarısı Sahne Odağı), Spot B (Tiyatro Çapraz Körlük Işığı) ve Spot C (Balkon Yıkama) buton durumlarına göre sinüs parlaklık dalgalanması ve yumuşak sönümleme geçişleriyle çizilmektedir.
- **Hareketli Nişan ve Lazer Hattı:** Hedef olan Kraliyet Locası'na yönelik dönen nişangâh köşebentleri ve sürekli kayan kesikli lazer çizgisi:
  - *1. Karşı Balkon:* Salona %100 açık hedef uyarısı.
  - *2. Çatı Havalandırması:* Çatı makası engeli, yanıp sönen kırmızı 'X' ve kapalı açı göstergesi.
  - *3. Işık Köprüsü:* Spot B açık ve A/C kapalıyken mutlak gölgede %100 doğrulanmış kör nokta yeşil radar halkası; yanlış ışıkta açık hedef ikazı.
- **Test Atış Simülasyonu:** `Test Et` butonuna basıldığında namlu alevi, hareket eden mermi izi (tracer) simülasyonu, isabet anında yeşil şok dalgası veya sarsıntı + kırmızı kıvılcım patlaması.
- **Klavye Kısayolları:** `A`, `B`, `C` ile spotları açma/kapama; `1`, `2`, `3` ile nişancı konumu seçme; `Enter`/`Boşluk` ile atış testi; `Esc` ile kapatma.

### 2. Şifre ve Kilit Panellerine Tam Klavye Desteği
- `SafeDialModal` (Vaka 1: `1-9-4-1` Duvar Kasası), `CraneWinchModal` (Vaka 2: `2-4-0` Vinç Panosu), `TumblerLockModal` (Vaka 3: `1-1-2` Alet Sandığı):
  - `0-9` ve Numpad tuşlarıyla doğrudan rakam yazma,
  - Rakam girildikçe bir sonraki haneye otomatik geçiş,
  - `Sol/Sağ` yön tuşlarıyla hane seçimi, `Yukarı/Aşağı` ile rakam çevirme,
  - `Backspace` ile silme / geri gitme, `Enter` ile kilidi açma, `Esc` ile kapatma,
  - Aktif hanede altın sarısı çerçeve vurgusu.

### 3. HUD Hızlı Geçiş Butonlarının Kilitli Odaları Engellemesi
- Alt gezinme butonları doğrudan sahne değiştirmek yerine odadaki `Door` etkileşim mantığını çalıştırmaktadır.
- Kapı kilitliyse buton üzerinde `🔒 [Kilitli]` göstergesi belirir.
- Butona basıldığında kapı kilitli sesi çalar, Silas'ın kilit repliği (örn: Boris uyarısı, Margaret anahtarı vb.) ekranda çıkar ve geçiş engellenir.
- İlgili anahtar / geçiş izni (`key_ring`, `night_pass`, `backstage_key`, `bridge_key`) alındığında kilit kalkar ve geçiş açılır.

### 4. Vinç Şifresiz Açık Hatasının Kesin Çözümü
- Askerî sandık vinç panosu `2-4-0` kodu ile kalibre edilmeden zemine indirilmez; sandığa tıklandığında havada asılı olduğu belirtilir.
- Erken kanıt bayrağı atlaması engellendi; bulmaca mecburi kılındı.

### 5. Şifre Panelleri ve Minigamelerden ESC ile Çıkış Desteği
- `PauseMenu` etkileşim yakalayıcısına (`_try_close_active_interaction`) ve tüm modallara (`SafeDialModal`, `CraneWinchModal`, `TumblerLockModal`, `LightRangeModal`, `CaseSelectModal`) `ESC` dinleyicileri eklendi.
- Oyuncu herhangi bir şifre paneli veya minigame açıkken `ESC` tuşuna bastığında duraklatma menüsü açılmaz; doğrudan aktif bulmaca kapatılır ve karakter hareketi kesintisiz geri verilir.

### 6. Ana Menüye Dönüş & Bölüm Seçimi Başlangıç Akışı
- Duraklatma menüsünden "Ana Menüye Dön" seçildiğinde oyun kapanmaz, doğrudan giriş ekranına döner.
- Bölüm seçiminden bir vaka seçildiğinde ofis telefonu çalarak başlar, telefon açılıp konuşma yapıldıktan sonra yolculuk ve varış sinematikleri sırayla oynatılıp olay yerine girilir.

### 7. 1. Oyun Resmi İkonunun (Shadow & Rain) Entegrasyonu
- Kullanıcı tarafından belirlenen resmi 1. Oyun (*Shadow & Rain*) ikonu tüm çözünürlüklerde üretildi:
  - `icon.png`: 512x512 Proje ve pencere ikonu (`project.godot`).
  - `icon.ico`: Windows masaüstü için çoklu çözünürlük (256, 128, 64, 48, 32, 16 px) çalıştırılabilir dosya ikonu (`export_presets.cfg`).
  - `assets/icons/`: Android başlatıcı (192, 128, 48 px) ve adaptif ön/arka plan (432 px) ikonları.
- Android APK (`build/Golge_ve_Yagmur.apk`) ve Windows PCK paketleri yeni ikonla derlenip imzalandı.

---

## 3. Doğrulama ve Test Sonuçları
- `tests/test_minigame_effects_and_nav_locks.tscn`: **13 / 13 test başarılı** (%100 Başarı).
- `tests/test_all_cases_progression.tscn`: **Tüm Vakalar 1, 2, 3 %100 hatasız ilerleme**.
- `tests/test_menu_and_case_flow.tscn`: **10 / 10 test başarılı** (%100 Başarı).
- `scenes/tests/test_dynamic_music.tscn`: **29 / 29 test başarılı** (%100 Başarı).
- `scenes/tests/test_full_game_logic.tscn`: **150 / 150 test başarılı** (%100 Başarı).

---

## 4. Dosya ve Paket Bilgisi
- `paylasim/paylasim.zip`: Güncellenmiş tam kaynak kod, sahneler, dinamik çizim motorları ve varlıkları içeren arşiv paketi.
- `paylasim/DOSYA_AGACI.txt`: Projenin güncel dosya dökümü.
- `paylasim/DURUM_RAPORU.md`: Bu durum raporu belgesi.
