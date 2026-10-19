# EventBus Sinyal Haritası

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
