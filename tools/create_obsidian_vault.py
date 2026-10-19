# -*- coding: utf-8 -*-
import os

base_dir = r"docs/vault"

files = {
    "04 - Bulmacalar ve Mekanikler/Dedüksiyon Tahtası.md": """# 🧠 Dedüksiyon Tahtası ve Mantık Sistemi

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
""",

    "02 - Vakalar/Vaka 02 - Sisli Liman.md": """# 🌫️ Vaka 02: Sisli Liman

#vaka #sabotaj #cinayet #rihtim

- **Kurban:** [[Teddy Marsh]] (Silas'ın eski cephe telsizcisi)
- **Olay Yeri:** [[Greywater Rıhtımı]] — 4 No'lu Kargo Ambarı
- **Ölüm Sebebi:** Çelik vinç yükünün düşmesi sonucu ezilme (öncesinde fenerle bayıltılmış)

---

## 👥 Şüpheliler ve Tanıklıklar

* **[[Kaptan Thomas Vance]] (KATİL):**
  - *Rol:* Yük Gemisi Kaptanı
  - *Motif:* İsimsiz şantaj mektubu alarak Teddy'nin kendisini polise ihbar edeceğini sandı.
  - *Kilit Delil:* Ceketindeki asit yanığı ve çelik tozu halat lifleriyle eşleşir (`E204`).
* **[[Arthur Morris]]:**
  - *Rol:* Baş Gümrük Şefi (Masum)
  - *Durum:* Rüşvet çetelesi korkusuyla delilleri saklamaya çalıştı (`E210`).
* **[[Victor Corley]]:**
  - *Rol:* Rıhtım Mafyası Lideri (Masum)
  - *Durum:* Cinayet saatinde poker oynuyordu; Kaptan Vance ile Teddy'nin kavgasını doğruladı.
* **[[Colin Brandt]]:**
  - *Rol:* Liman Vinç Operatörü (Kızıl Ringa)
  - *Durum:* Olay anında ambarda sarhoş sızmıştı; asit kullanmayı bilmez (`E209`).
* **[['Kaya' Boris]]:**
  - *Rol:* Mafya Fedaisi
  - *Durum:* Rıhtım barının kapısını tutar; Silas mühürlü izin kâğıdı (`E208`) verene dek yolu açmaz.

---

## 🧩 Kritik Bulmaca
* **[[Vinç Şalter Panosu (Crane Winch)]]:**
  - 3 fazlı şalter kontrol mekanizması (`230`).
  - Doğru voltaj kalibre edildiğinde vincin fren sistemindeki asit korozyonu tescillenir.

---

## 🧠 Dedüksiyonlar
- Tüm çıkarım kombinasyonları ve ipuçları için: [[Dedüksiyon Tahtası#🌫️ Vaka 02: Sisli Liman (Teddy Marsh Cinayeti)]]

## 🔗 Bağlantılar
- [[Silas Crowe]]
- [[Teddy Marsh]]
- [[Greywater Rıhtımı]]
""",

    "02 - Vakalar/Vaka 03 - Kör Nokta.md": """# 🎭 Vaka 03: Kör Nokta

#vaka #suikast #opera #keskinnisanci

- **Kurban:** Dalton Reeve (1944 Kuzey Operasyonu eski subayı)
- **Olay Yeri:** [[Kraliyet Operası]] — Kraliyet Locası
- **Ölüm Sebebi:** 112. ölçüdeki teatral top sesine senkronize edilmiş tek kurşunla keskin nişancı suikastı

---

## 👥 Şüpheliler ve Tanıklıklar

* **[[Gölgedeki Keskin Nişancı]] (KATİL):**
  - *Rol:* 1944 Kuzey Operasyonu'ndan geride kalan intikam suikastçısı.
  - *Kilit Delil:* Çatı parapetindeki K-4 tüfeği (`E301`) ve köprüdeki .303 boş kovan (`E303`).
* **[[Arthur Finch]]:**
  - *Rol:* Sahne ve Işık Amiri (Masum)
  - *Durum:* Anahtarı bir hafta önce marangoz atölyesinde balmumu kalıpla kopyalanmıştır (`E304`).
* **[[Elena Vane]]:**
  - *Rol:* Başsoprano (Görgü Tanığı)
  - *Durum:* Aryasını söylerken parıltı gördüğünü sanmıştır; ancak spot ışıkları köprüyü görünmez kılmaktadır (`E307`).
* **[[Cyril Sterling]]:**
  - *Rol:* Mühimmat Tüccarı ve Loca Sahibi (Kızıl Ringa)
  - *Durum:* Kurbanla yan yana otururken kurşun başını sıyırmış, ölüm korkusu yaşamıştır.
* **[[Barnaby Miller]] ("Patch"):**
  - *Rol:* Ses ve Efekt Teknisyeni (Kilit Tanık)
  - *Durum:* 112. ölçüdeki barutlu topu patlatırken ikinci kuru bir tüfek patlaması duyduğunu ifade eder (`E310`).

---

## 🧩 Kritik Bulmacalar
1. **[[Tambur Kilit (Tumbler Lock)]]:**
   - Kulisteki pirinç alet sandığı kilidi (`1 - 1 - 2`).
2. **[[Optik Işık Köprüsü (Light Range)]]:**
   - Tavan iskeletindeki 4 projektörün açı matrisi. Tetikçinin gizlendiği mutlak kör noktayı açığa çıkarır.

---

## 🧠 Dedüksiyonlar
- Tüm çıkarım kombinasyonları ve ipuçları için: [[Dedüksiyon Tahtası#🎭 Vaka 03: Kör Nokta (Kraliyet Operası Suikastı)]]

## 🔗 Bağlantılar
- [[Silas Crowe]]
- [[Kraliyet Operası]]
""",

    "01 - Karakterler/Kaptan Thomas Vance.md": """# ⚓ Kaptan Thomas Vance

#karakter #vaka2 #katil

- **Meslek:** Yük Gemisi Kaptanı (Greywater Rıhtımı)
- **Rolü:** [[Vaka 02 - Sisli Liman]] Cinayetinin Faili (Katil)
- **Mekan:** [[Greywater Rıhtımı]] — Kaptan Kamarası

## Suç Profili & Gerçek
- İsimsiz bir daktilo mektubu alarak [[Teddy Marsh]]'ın kendisini polise teslim edeceğini sandı.
- Ambarda Teddy'yi fenerle bayıltıp vinç halatını asitle aşındırdı ve kaza süsü verdi.
- Ceketindeki asit yanığı ve tahrif edilmiş seyir defteri suçunu kesinleştirdi.

## Bağlantılar
- [[Teddy Marsh]]
- [[Vaka 02 - Sisli Liman]]
- [[Vinç Şalter Panosu (Crane Winch)]]
""",

    "01 - Karakterler/Arthur Morris.md": """# 📋 Arthur Morris

#karakter #vaka2 #supheli

- **Meslek:** Baş Gümrük Şefi
- **Rolü:** Vaka 2 Şüphelisi (Masum Bürokrat)
- **Mekan:** [[Greywater Rıhtımı]] — Gümrük Ofisi

## Notlar
- Rıhtım mafyası [[Victor Corley]]'den rüşvet alıyordu.
- Masasındaki mühürlü izin belgesi fedaiyi aşmak için kullanılır.
- Cinayetle ilgisi yoktur, korkusu rüşvet defterinin açığa çıkmasındandır.
""",

    "01 - Karakterler/Victor Corley.md": """# ♠️ Victor 'Kuzgun' Corley

#karakter #vaka2 #supheli

- **Meslek:** Rıhtım Mafyası Lideri & Bar Sahibi
- **Rolü:** Vaka 2 Şüphelisi
- **Mekan:** [[Greywater Rıhtımı]] — Rıhtım Barı (Saloon)

## Notlar
- Teddy'nin kendisine yüklü kumar borcu vardı.
- Cinayet saatinde poker masasındaydı; Kaptan Vance ile kurban arasındaki son gerilimi Silas'a anlattı.
""",

    "01 - Karakterler/Colin Brandt.md": """# 🏗️ Colin Brandt

#karakter #vaka2 #kizilringa

- **Meslek:** Liman Vinç Operatörü
- **Rolü:** Vaka 2 Kızıl Ringası
- **Mekan:** [[Greywater Rıhtımı]] — 4 No'lu Kargo Ambarı

## Notlar
- Vinç mekanizmasını bilen tek kişi olduğu için ilk şüpheliydi.
- Olay saatinde ambarın kuytusunda viski içip sızıp kalmıştı; asit kullanmayı bilmez.
""",

    "01 - Karakterler/Kaya Boris.md": """# 🚪 'Kaya' Boris

#karakter #vaka2 #fedai

- **Meslek:** Mafya Fedaisi
- **Rolü:** Rıhtım Barının Kapı Muhafızı
- **Mekan:** [[Greywater Rıhtımı]] — Bar Girişi

## Notlar
- [[Victor Corley]]'nin korumasıdır.
- Silas ona gümrükten onaylı mühürlü Gece İzin Belgesi (`E208`) getirmedikçe bara girişine izin vermez.
""",

    "01 - Karakterler/Dalton Reeve.md": """# 🎖️ Dalton Reeve

#karakter #vaka3 #kurban

- **Geçmiş:** 1944 Kuzey Operasyonu eski subayı.
- **Rolü:** [[Vaka 03 - Kör Nokta]] Cinayetinin Maktulü.
- **Mekan:** [[Kraliyet Operası]] — Kraliyet Locası

## Ölüm Ayrıntısı
- Operanın 112. ölçüsündeki top sesine denk getirilen tek kurşunla vuruldu.
- Cebinden çıkan cep saati 20:52'de durmuştu ve arkasında 'K-4' gravürü vardı.
""",

    "01 - Karakterler/Arthur Finch.md": """# 💡 Arthur Finch

#karakter #vaka3 #supheli

- **Meslek:** Sahne ve Işık Amiri
- **Rolü:** Vaka 3 Şüphelisi (Masum)
- **Mekan:** [[Kraliyet Operası]] — Sahne Arkası

## Notlar
- Işık köprüsünün tek anahtarına sahipti.
- Anahtarı marangozhanede düşürdüğünde balmumu kalıpla kopyalanmıştı. Kendi suçu yoktur.
""",

    "01 - Karakterler/Elena Vane.md": """# 🎶 Elena Vane

#karakter #vaka3 #tanik

- **Meslek:** Başsoprano
- **Rolü:** Vaka 3 Baş Görgü Tanığı
- **Mekan:** [[Kraliyet Operası]] — Kulis & Sahne

## Notlar
- Atış anında sahnede arya söylüyordu.
- Işık köprüsünde bir parıltı gördüğünü söylemiş olsa da, yüzüne vuran 2000 watt'lık projektörler nedeniyle bunun panik anında bir göz aldanması olduğu kanıtlanmıştır.
""",

    "01 - Karakterler/Cyril Sterling.md": """# 💼 Cyril Sterling

#karakter #vaka3 #kizilringa

- **Meslek:** Mühimmat Tüccarı ve Loca Sahibi
- **Rolü:** Vaka 3 Şüphelisi
- **Mekan:** [[Kraliyet Operası]] — Kraliyet Locası

## Notlar
- Maktul Dalton Reeve ile aynı locada yan yana oturuyordu.
- Kurşunun kendisini hedef aldığını sanarak paniğe kapıldı; cinayetle doğrudan bağı yoktur.
""",

    "01 - Karakterler/Barnaby Miller.md": """# 💥 Barnaby 'Patch' Miller

#karakter #vaka3 #tanik

- **Meslek:** Ses ve Teatral Efekt Teknisyeni
- **Rolü:** Vaka 3 Kilit Tanığı
- **Mekan:** [[Kraliyet Operası]] — Efekt Balkonu

## Notlar
- 112. ölçüdeki sahte top patlamasını gerçekleştiren teknisyen.
- Top patlarken eş zamanlı kuru bir tüfek patlaması duyduğunu doğrulayan tek kişidir.
""",

    "01 - Karakterler/Gölgedeki Keskin Nişancı.md": """# 🎯 Gölgedeki Keskin Nişancı

#karakter #vaka3 #katil #tetikci

- **Geçmiş:** 1944 Kuzey Operasyonu gazisi / Hayalet keskin nişancı.
- **Rolü:** [[Vaka 03 - Kör Nokta]] Cinayetinin Faili (Katil).
- **Mekan:** [[Kraliyet Operası]] — Çatı Parapeti & Işık Köprüsü

## Cinayet Planı
- Işık köprüsünü kör nokta olarak kullandı.
- Top atışının ses perdesiyle Dalton Reeve'i vurdu.
- Çatı parapetine K-4 gravürlü tüfeğini ve aşağı kayık 'r' harfli daktilo notunu bırakıp sislerin içine karıştı.

## Bağlantılar
- [[Silas Crowe]]
- [[Vaka 03 - Kör Nokta]]
- [[Optik Işık Köprüsü (Light Range)]]
""",

    "03 - Mekanlar/Greywater Rıhtımı.md": """# ⚓ Greywater Rıhtımı

#mekan #vaka2

[[Vaka 02 - Sisli Liman]] soruşturmasının cereyan ettiği sisli, yağmurlu ve tehlikeli endüstriyel liman bölgesi.

---

## 🚪 Odalar ve Bölgeler
1. **4 No'lu Ambar (`dock_warehouse`):** [[Teddy Marsh]]'ın cansız bedeninin ve kopmuş vinç halatının bulunduğu cinayet mahalli.
2. **Rıhtım İskelesi (`dock_pier`):** Yük gemilerinin yanaştığı, sisin en yoğun olduğu sahil şeridi.
3. **Gümrük Ofisi (`dock_office`):** [[Arthur Morris]]'in çalıştığı, gece izin belgesinin ve rüşvet defterinin bulunduğu bina.
4. **Rıhtım Barı (`dock_saloon`):** [[Victor Corley]] ve fedaisi [['Kaya' Boris]]'in bulunduğu yeraltı kumar mekânı.
5. **Kaptan Kamarası (`captain_cabin`):** [[Kaptan Thomas Vance]]'in seyir defteri ve asitli ceketinin bulunduğu gemi kamarası.

---

## 🔗 İlgili Vaka
- [[Vaka 02 - Sisli Liman]]
- [[Vinç Şalter Panosu (Crane Winch)]]
""",

    "03 - Mekanlar/Kraliyet Operası.md": """# 🎻 Kraliyet Operası

#mekan #vaka3

[[Vaka 03 - Kör Nokta]] suikastının gerçekleştiği, 19. yüzyıldan kalma devasa neoklasik tiyatro yapısı.

---

## 🚪 Odalar ve Bölgeler
1. **Opera Fuayesi (`opera_foyer`):** Giriş salonu, kırmızı halılar ve seyirci kalabalığı.
2. **Kraliyet Locası (`royal_box`):** Maktul Dalton Reeve ve [[Cyril Sterling]]'in oturduğu hedef locası.
3. **Sahne Arkası & Kulis (`backstage`):** [[Arthur Finch]] ve [[Elena Vane]]'in bulunduğu, [[Tambur Kilit (Tumbler Lock)]] ile korunan alet sandığının yer aldığı alan.
4. **Işık Köprüsü (`light_bridge`):** Tavan iskeletindeki dev projektörlerin ve [[Optik Işık Köprüsü (Light Range)]] bulmacasının bulunduğu kör nokta platformu.
5. **Efekt Balkonu & Aksesuar Odası (`prop_room`):** [[Barnaby Miller]]'ın teatral top bataryasını patlattığı oda.
6. **Çatı Parapeti (`opera_roof`):** K-4 suikast tüfeğinin bırakıldığı ve [[Gölgedeki Keskin Nişancı]]'nın sislere karıştığı çatı hattı.

---

## 🔗 İlgili Vaka
- [[Vaka 03 - Kör Nokta]]
""",

    "00 - Genel Bakis/Ana Dizin.md": """# 🧭 Silas Crowe: Shadow & Rain — Ana Dizin (MOC)

> **Proje:** 2D Pixel-Art Noir Dedektiflik Oyunu  
> **Motor:** Godot 4.3 (GDScript)  
> **Geliştirici:** Ömerhan Ulusoy  
> **Evren:** 1940'lar Savaş Sonrası İngiltere

---

## 📂 İçerik Haritası

### 🕵️ Karakterler
#### Ana Karakter
- [[Silas Crowe]] — Baş Karakter & Özel Dedektif

#### Vaka 1: Karanlık Malikâne
- [[Julian Harlow]] — Mirasçı Üvey Kardeş
- [[Margaret Doyle]] — Kâhya
- [[Raymond Pike]] — Eski İş Ortağı & Avukat
- [[Dr Victor Hale]] — Aile Hekimi (Katil)

#### Vaka 2: Sisli Liman
- [[Teddy Marsh]] — Silas'ın Eski Telsizcisi (Kurban)
- [[Kaptan Thomas Vance]] — Yük Gemisi Kaptanı (Katil)
- [[Arthur Morris]] — Baş Gümrük Şefi
- [[Victor Corley]] — Rıhtım Mafyası Lideri
- [[Colin Brandt]] — Vinç Operatörü
- [['Kaya' Boris]] — Mafya Fedaisi

#### Vaka 3: Kör Nokta
- [[Dalton Reeve]] — Eski Subay (Kurban)
- [[Gölgedeki Keskin Nişancı]] — 1944 Gazisi (Katil)
- [[Arthur Finch]] — Işık Amiri
- [[Elena Vane]] — Başsoprano
- [[Cyril Sterling]] — Mühimmat Tüccarı
- [[Barnaby Miller]] — Ses ve Efekt Teknisyeni

---

### 📁 Vakalar (Sezon 1)
- [[Vaka 01 - Karanlık Malikâne]] — Edmund Harlow Kilitli Oda Cinayeti
- [[Vaka 02 - Sisli Liman]] — Teddy Marsh Rıhtım Vinç Sabotajı
- [[Vaka 03 - Kör Nokta]] — Kraliyet Operası Teatral Suikastı

---

### 🏛️ Mekanlar
- [[Silas Dedektiflik Ofisi]] — Hub / Merkez Oda
- [[Harlow Malikânesi]] — Vaka 1 Malikânesi (6 Oda)
- [[Greywater Rıhtımı]] — Vaka 2 Liman Bölgesi (5 Bölge)
- [[Kraliyet Operası]] — Vaka 3 Tiyatrosu (6 Bölge)

---

### 🧩 Bulmacalar & Sistemler
- [[Dedüksiyon Tahtası]] — Tüm vakaların eksiksiz delil ve dedüksiyon matrisi (`D1 - D306`)
- [[Döner Diskli Kasa (Safe Dial)]] — Harlow kasası mekaniği (`1944`)
- [[Vinç Şalter Panosu (Crane Winch)]] — Rıhtım vinç voltaj kalibrasyonu (`230`)
- [[Tambur Kilit (Tumbler Lock)]] — Opera alet sandığı pirinç tamburları (`1-1-2`)
- [[Optik Işık Köprüsü (Light Range)]] — Projektör açısı ve kör nokta simülasyonu

---

### ⚙️ Teknik Mimari
- [[Godot Mimarisi ve Autoloads]] — Singleton yöneticileri ve durum yönetimi
- [[EventBus Sinyal Haritası]] — Sahneler arası olay köprüsü
- [[Kontroller ve Platformlar]] — PC & Mobil dokunmatik şeması
"""
}

for rel_path, content in files.items():
    full_path = os.path.join(base_dir, rel_path)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    with open(full_path, "w", encoding="utf-8") as f:
        f.write(content.strip() + "\n")

print(f"{len(files)} files written to Obsidian vault successfully.")
