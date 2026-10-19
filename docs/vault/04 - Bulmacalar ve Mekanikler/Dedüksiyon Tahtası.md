# 🧠 Dedüksiyon Tahtası ve Mantık Sistemi

#mekanik #oynanis #deduksiyon

Dedüksiyon Tahtası, *Silas Crowe: Shadow & Rain* oyununun temel araştırma ve çıkarım mekaniğidir. Oyuncunun etraftan topladığı fiziksel delilleri bir araya getirerek olayların arkasındaki gerçeği adım adım mantıksal olarak ortaya çıkarmasını sağlar.

---

## ⚙️ Sistem İşleyişi
1. **Delil Toplama:** Silas odaları araştırırken veya şüphelileri sorgularken defterine deliller (`E...`) ekler.
2. **Kombinasyon (Sentez):** Defterin Dedüksiyon sekmesinde 2 veya daha fazla delil seçilir ve "Birleştir" butonuna basılır.
3. **Yeni Çıkarım (Dedüksiyon):** Seçilen deliller arasında mantıksal bir ilişki varsa yeni bir **Dedüksiyon (`D...`)** kilidi açılır.
4. **Zincirleme İlerleme:** Bazı üst düzey dedüksiyonlar, daha önce yapılmış dedüksiyonların başka delillerle birleştirilmesiyle (`D3 + E03 -> D4`) üretilir.
5. **Nihai İddianame:** Her vakanın sonunda katili suçlamak için gereken "Nihai Dedüksiyon" (Cinayet Yöntemi + Fail + Sahte Alibi Çürütme) elde edilmelidir.

---

## 🕯️ Vaka 01: Karanlık Malikâne (Harlow Cinayeti)

### 📌 Delil Listesi
| ID | Delil Adı | Konum | Tür |
| :--- | :--- | :--- | :--- |
| **E01** | Kırık cep saati ("K-5" / 22:10) | Çalışma Odası | Kızıl Ringa |
| **E02** | Kilitte duran anahtar (içeriden) | Çalışma Odası | Kritik |
| **E03** | Yarım kalmış avukat notu | Çalışma Odası | İpucu |
| **E04** | Konyak kadehi (acı kokulu kalıntı) | Çalışma Odası | Kritik |
| **E05** | Kalp damlası şişesi (aşırı boşalmış) | Çalışma Odası | Kritik |
| **E06** | Çöp sepetinde yırtık reçete parçası (20:50) | Çalışma Odası | Kritik |
| **E07** | Pike'ın tehdit mektubu taslağı | Bilardo Odası | Kızıl Ringa |
| **E08** | Erimiş şömine mumu (1 saatlik yanma) | Çalışma Odası | Kritik |
| **E09** | Kütüphane şöminesi (soğuk, hiç yakılmamış) | Kütüphane | Kritik |
| **E10** | Şömine pervazındaki boş digitalis tüpü | Kütüphane | Kritik |
| **E11** | Julian'ın tefeci borç senetleri | Yatak Odası | Şüpheli |
| **E12** | Julian'ın kırık dolap anahtarı | Mutfak | Kızıl Ringa |
| **E13** | Pike'ın daktilosu (kayık 'e' harfi) | Çalışma Odası | Kızıl Ringa |
| **E14** | Margaret'in mutfak servis tepsisi (20:45) | Mutfak | Alibi |
| **E15** | Mermer holde kurumuş tek ayak izi | Ana Salon | Kritik |

### 🧩 Dedüksiyon Reçeteleri (Çıkarım Ağacı)
* **D1 — İçeriden Kilitlenen Kapı:** `E02` + `E15`
  > *Çıkarım:* Kapı içeriden kilitli ve holde tek iz Silas'a ait. Harlow, katil ayrıldıktan sonra kapıyı kendisi kilitledi.
* **D2 — Gecikmeli Zehirlenme Yöntemi:** `E04` + `E05`
  > *Çıkarım:* Kadehe ve kalp damlalarına ölümcül dozda digitalis karıştırıldı. Zehir odanın dışında ya da güven ilişkisi içinde verildi.
* **D3 — Sahte Ölüm Saati:** `E01` + `E08`
  > *Çıkarım:* Saat 22:10'da durmuş görünse de mumun sadece bir saatlik yanmış olması gerçek ölümün 21:30 - 21:45 arasında gerçekleştiğini kanıtlar.
* **D4 — Gerçek Cinayet Penceresi:** `D3` + `E03`
  > *Çıkarım:* Harlow akşam yemeğinden hemen sonra tek başınayken nöbet geçirdi.
* **D5 — Dr. Hale'in Yalanı:** `E06` + `E05`
  > *Çıkarım:* Odaya hiç girmediğini söyleyen Hale'in 20:50 saatli reçete taslağı odada bulundu. Odaya bizzat girdi.
* **D6 — Kütüphane Alibisinin Çöküşü:** `E09` + `E10`
  > *Çıkarım:* Hale buz gibi kütüphanede kitap okumadı; zehir tüpünü şömineye gizlemek için oradaydı.
* **D7 — NİHAİ DEDÜKSİYON: KATİL DR. HALE:** `D1` + `D2` + `D5` + `D6`
  > *Çıkarım:* Dr. Hale saat 20:45'te odaya girip ilaca digitalis kattı. Harlow şüphelenmeyip ilacı içti, ardından kapıyı kilitleyip vefat etti. Katil [[Dr Victor Hale]]!
* **D8 — Tehdit Mektuplarının Kaynağı (Pike Aklanır):** `E07` + `E13`
  > *Çıkarım:* Pike mektupları borç tahsili için yazdı, cinayetle ilgisi yok.
* **D9 — Julian'ın Borç Paniği (Julian Aklanır):** `E11` + `E12`
  > *Çıkarım:* Julian borçları yüzünden kasayı açmaya çalıştı ama zehirleme hakkında bilgisi yok.

---

## 🌫️ Vaka 02: Sisli Liman (Teddy Marsh Cinayeti)

### 📌 Delil Listesi
| ID | Delil Adı | Konum | Tür |
| :--- | :--- | :--- | :--- |
| **E201** | Kopmuş çelik halat (asit aşınması) | 4 No'lu Ambar | Kritik |
| **E202** | Mühürsüz ahşap askerî sandık | 4 No'lu Ambar | İpucu |
| **E203** | Teddy'nin kanlı telsizci feneri | Ambar Zemini | Kritik |
| **E204** | Vance'in ceketindeki asit yanığı | Gemi Kamarası | Kritik |
| **E205** | İsimsiz ihbar mektubu (aşağı kayık 'r') | Kaptan Masası | Ana Hikaye |
| **E206** | Seyir defterindeki tahrif edilmiş saatler | Kaptan Masası | Kritik |
| **E207** | Silas'ın cebindeki Kuzey cep saati ("K-1") | Envanter | Ana Hikaye |
| **E208** | Gümrük mühürlü gece geçiş belgesi | Gümrük Masası | İlerleme |
| **E209** | Colin Brandt'in boş viski şişesi | Ambar Köşesi | Kızıl Ringa |
| **E210** | Morris'in rüşvet çetelesi defteri | Gümrük Kasası | Kızıl Ringa |
| **E211** | Greywater Rıhtımı gelgit ve vardiya tablosu | Rıhtım Panosu | Kritik |
| **E212** | Victor Corley'nin kumar borç senetleri | Rıhtım Barı | Kızıl Ringa |

### 🧩 Dedüksiyon Reçeteleri
* **D201 — Kasıtlı Sabotaj ve Cinayet:** `E201` + `E203`
  > *Çıkarım:* Teddy önce fenerle bayıltıldı, ardından vinç halatı asitle zayıflatılarak kaza süsü verildi.
* **D202 — Kuzey Sevkiyatının Kaçırılması:** `E201` + `E202`
  > *Çıkarım:* Vinç kazası mühürsüz askerî mühimmat sandığının kaçırılmasını gizlemek için tezgâhlandı.
* **D203 — Katilin İmzası: Kaptan Vance:** `E201` + `E204`
  > *Çıkarım:* Vance'in ceketindeki asit ve çelik tozu halattaki kimyasalla birebir eşleşir.
* **D204 — Gölgedeki Kuklacının Oyunu:** `E205` + `E207`
  > *Çıkarım:* İsimsiz daktilo mektubu Vance'i panikletip cinayete sürükledi. Aşağı kayık 'r' harfi aynı gölgeyi işaret eder.
* **D205 — Morris'in Masumiyeti:** `E206` + `E210`
  > *Çıkarım:* Morris katil değil; korkusu cinayetten değil rüşvet çetesinin açığa çıkmasındandır.
* **D206 — NİHAİ DEDÜKSİYON: KATİL KAPTAN VANCE:** `E211` + `E206` (+ `D201`, `D203`)
  > *Çıkarım:* Gelgit tablosu Vance'in kamarada olduğu iddiasını çürütür. Katil [[Kaptan Thomas Vance]]!

---

## 🎭 Vaka 03: Kör Nokta (Kraliyet Operası Suikastı)

### 📌 Delil Listesi
| ID | Delil Adı | Konum | Tür |
| :--- | :--- | :--- | :--- |
| **E301** | Çatı parapetindeki K-4 keskin nişancı tüfeği | Çatı Parapeti | Kritik |
| **E302** | Işık köprüsü projektör cue panosu | Sahne Arkası | Kritik |
| **E303** | Işık köprüsünde .303 boş kovan | Işık Köprüsü | Kritik |
| **E304** | Sahne ambarında balmumu anahtar kalıbı | Sahne Arkası | Kritik |
| **E305** | Finch'in pirinç dolap anahtarı | Kulis | İpucu |
| **E306** | Dalton Reeve'in 112. ölçüsü işaretli partitürü | Kraliyet Locası | Kritik |
| **E307** | 2000W karartılmış spot ışık jeli | Işık Köprüsü | İpucu |
| **E308** | Dipçiğe sarılı daktilo mektubu (aşağı kayık 'r') | Çatı Parapeti | Ana Hikaye |
| **E309** | Dalton Reeve'in 20:52'de durmuş cep saati | Kraliyet Locası | Kritik |
| **E310** | Teatral barutlu top düzeneği | Efekt Balkonu | İpucu |

### 🧩 Dedüksiyon Reçeteleri
* **D301 — Ses Perdesi ve Kusursuz Zamanlama:** `E306` + `E309`
  > *Çıkarım:* Atış orkestranın 112. ölçüsündeki sahte top atışının tam gürültüsüne denk getirildi.
* **D302 — Kör Nokta Atış Hattı:** `E302` + `E303`
  > *Çıkarım:* Spot ışıklarının açısı ışık köprüsünün kuzey ucunu salondan görünmez bir kör noktaya çevirdi.
* **D303 — Kopyalanmış Anahtar (Finch Masum):** `E304` + `E305`
  > *Çıkarım:* Köprü kapısı zorlanmadı; balmumu kalıpla kopyalanan anahtarla açıldı. Finch masum.
* **D304 — 1944 Kuzey İntikamı:** `E301` + `E308`
  > *Çıkarım:* K-4 tüfeği ve dipçikteki not, cinayetin 1944 Kuzey Operasyonu intikam zincirinin bir parçası olduğunu gösterir.
* **D305 — Elena'nın İmkânsız İfadesi:** `E303` + `E307`
  > *Çıkarım:* Başsoprano Elena'nın sahneden ışık parıltısı gördüğü iddiası projektörlerin kör edici ışığı altında fiziksel bir yanılsamadır.
* **D306 — NİHAİ DEDÜKSİYON: GÖLGEDEKİ KESKİN NİŞANCI:** `D302` + `D304`
  > *Çıkarım:* Katil salondakilerden biri değil; 1944'ün intikam tüfeğini ateşleyip çatıdan sislere karışan profesyonel tetikçidir!

---

## 🔗 İlgili Bağlantılar
- [[Silas Crowe]]
- [[Vaka 01 - Karanlık Malikâne]]
- [[Vaka 02 - Sisli Liman]]
- [[Vaka 03 - Kör Nokta]]
