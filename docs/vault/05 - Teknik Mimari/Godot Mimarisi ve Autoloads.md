# Godot Mimarisi ve Autoloads

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
