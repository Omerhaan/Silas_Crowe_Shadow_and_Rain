# VAKA 3: KÖR NOKTA (THE BLIND SPOT)
## Genişletilmiş Sezon Finali Tasarım ve Uygulama Planı

---

## 1. Genel Bilgiler

| Parametre | Değer |
|---|---|
| **Vaka Kodu** | `case03` |
| **Bölüm Başlığı** | Kör Nokta *(The Blind Spot)* |
| **Alt Başlık** | Kraliyet Operası Suikastı *(Royal Opera Assassination)* |
| **Tarih / Yıl** | Kasım 1946 *(Kuzey Operasyonu'ndan 2 yıl sonra)* |
| **Mekân** | Greywater Kraliyet Operası *(Royal Opera House)* |
| **Hedef Çözünürlük** | 480 × 270 (16:9 Pixel-Art Retro) |
| **Kurban** | Dalton Reeve (K-4, eski keskin nişancı, operanın güvenlik şefi) |
| **Katil** | Elias Wren (Doğrudan icra; oyunda "Kimliği Belirsiz Tetikçi" olarak teşhis edilir) |
| **Konum** | 1. Oyunun (Gölge ve Yağmur) Sezon Finali |

---

## 2. Çekirdek Olay ve Kurgusal Çerçeve

### Olayın Özeti
1944 kışında Kuzey Birimi pusuya düştüğünde mevzisini terk edip kaçan keskin nişancı **Dalton Reeve (K-4)**, savaştan sonra Greywater'a sığınmış ve Kraliyet Operası'nın güvenlik şefi olmuştur. Bir süredir tehdit mektupları alan Reeve, opera partisyonundaki **112. ölçüde** patlatılacak sahne top atışı efekti sırasında vurulacağını sezinlemiş ve partisyona *"Burada mı?"* notunu düşmüştür.

Reeve yanlış yöne (karşı balkona ve kulise) bakmaktadır. Tetikçi ise operanın tavanındaki **ışık köprüsünden** ateş eder. 20:51'de sahne ışıkları sopranoyu ve locayı aydınlatırken ışık köprüsünün kuzey ucu tam bir **"kör noktada"** kalır. 20:52'de top patladığı anda tek bir .303 mermisi Reeve'i kalbinden vurur; silah sesi top gürültüsünde kaybolur.

### Mantık Düzeltmeleri ve Kurgu Standartları
* **Kurban Şüpheli Değildir:** Dalton Reeve kurbandır; 3 şüpheli, 1 kilit tanık ve 1 atmosferik NPC vardır.
* **Katilin Teşhisi:** Silas katilin adını (Elias) henüz bilmez; suçlama ekranında **"Kimliği Belirsiz Tetikçi" (`unknown_sniper`)** seçeneğini seçerek üç kilit kanıt ve çıkarımla suikastı çözer.
* **Kilit Çelişkisinin Çözümü:** Işık köprüsünün asma kilidi zorlanmamıştır çünkü kilit deliğinde **balmumu izi** vardır. Anahtar, tek anahtar sahibi Finch'ten bir hafta önce gizlice alınıp kopyalanmıştır (Finch aklanır).
* **Kör Nokta Tanımı:** Sahne projektörlerinin yoğun ışığı sahneyi ve locaları aydınlatırken, tavandaki ışık köprüsü izleyicilerin ve sahnedekilerin görüş alanı dışında, mutlak bir gölge cepleri içinde kalmaktadır.
* **Zaman Tutarlılığı:** Oyun 1946'da geçmektedir. Olay gecesi saatler sonra taze duman kokusu aranmaz; pirinç kovan ve barut lekesi incelenir. Savaş Bakanlığı "Fon Protokolü" adı Vaka 4'e saklanmıştır.

---

## 3. Karakterler ve Şüpheliler (5 Kişi)

| İsim | Rolü | Görünen Motif | Gerçek ve Alibi |
|---|---|---|---|
| **Dalton Reeve** *(Kurban)* | Güvenlik Şefi (K-4) | — | 1944'te mevzisini terk etti; kendi tüfeğiyle 20:52'de öldürüldü. |
| **Arthur Finch** | Sahne & Işık Amiri | Köprü anahtarı sadece onda, ağır kumar borcu var. | **Masum.** Anahtarı bir hafta önce "kaybolup" ertesi gün geri gelmiş; kilitte balmumu kopyalama izi var. |
| **Elena Vane** | Başsoprano | Reeve'in terk ettiği eski sevgilisi; intikam şüphesi. | **Masum.** "Dürbün parıltısı gördüm" der fakat sahne ışıkları gözünü kör etmekteydi; ifadesi fiziksel olarak geçersizdir. |
| **Cyril Sterling** | Loca Sahibi / Nüfuzlu Tüccar | Reeve onun yasadışı mühimmat sevkiyatlarını biliyordu. | **Masum.** Cinayet anında 100 seyircinin önünde kendi locasında alkış tutmaktaydı; çürütülemez alibisi var. |
| **Patch** *(Tanık)* | Ses Efekti Teknisyeni | — | 112. ölçüde top efektini ateşleyen kişi; "İki patlama oldu, biri boğuktu" diyen tek tanık. |
| **Kapıcı Henderson** *(Atmosferik NPC)* | Bilet Gişesi & Vestiyer Amiri | — | Huysuz tiyatro emektarı; Reeve'in son haftalardaki paranoyasını ve gelen mektupları anlatan dedikoducu tanık. |

---

## 4. Genişletilmiş 7 Oda Mimarisi

1. **`opera_foyer` (Giriş Fuayesi & Bilet Gişesi):** Mermer heykeller, dev avizeler, bilet gişesi, aristokrat dedikoduları, vestiyer.
2. **`opera_auditorium` (Büyük Salon & Sahne Önü):** Kırmızı kadife koltuklar, orkestra çukuru, dev avize, sahne perdesi.
3. **`royal_box` (Kraliyet Locası - *Müstakil Sahne*):** Reeve'in vurulduğu loca. Kırık kadehler, kanlı partisyon sayfası, pirinç loca dürbünü, mermi giriş deliği.
4. **`backstage` (Kulis & Makyaj Odası):** Işıklı aynalar, Elena Vane'in divan köşesi, duvar tipi ışık konsolu (*Işık-Menzil Panosu*).
5. **`prop_room` (Dekor & Kostüm Atölyesi - *Müstakil Sahne*):** Barut fıçıları, Patch'in efekt tezgâhı, sahte kılıçlar, antik zırhlar, askeri kamuflaj kumaşları.
6. **`light_bridge` (Tavan Işık Köprüsü):** Asma kilitli demir kapı, dar metal ızgaralar, dev spotlar, .303 boş kovan, karartılmış jel.
7. **`opera_roof` (Gotik Çatı & Çörtenler):** Yağmurlu çatı mahyası, gargoyle heykelleri, K-4 tüfeği ve 3 aşamalı sinematik kovalamaca.

---

## 5. 10 Kanıt Envanteri (E301 - E310)

| ID | Kanıt Adı | Bulunduğu Yer | Açıklama ve İnceleme |
|---|---|---|---|
| **E301** | K-4 Gravürlü Keskin Nişancı Tüfeği | Çatı Çıkışı | Reeve'in 1944 kışında mevzide bıraktığı özel dürbünlü tüfek. Kundak kısmına *"K-4"* kazınmış. |
| **E302** | .303 Boş Pirinç Kovan | Işık Köprüsü (Kuzey) | Köprünün metal ızgarası arasına sıkışmış sıcaklığını kaybetmiş pirinç kovan. |
| **E303** | Işık Cue Defteri | Kulis Masası | Gösteri ışık çizelgesi: *20:51'de A spotu söner, B spotu locayı aydınlatır.* |
| **E304** | Zorlanmamış Ağır Asma Kilit | Işık Köprüsü Kapısı | Köprü kapısını kilitleyen döküm pirinç asma kilit. Levye veya zorlama izi yok. |
| **E305** | Kilitteki Balmumu Kalıntısı | Işık Köprüsü Kapısı | Asma kilidin anahtar yuvasına bulaşmış ince balmumu tabakası; anahtarın kalıpla kopyalandığını kanıtlar. |
| **E306** | 112. Ölçü Partisyonu | Kraliyet Locası | Sahne top atışının yapılacağı ölçü kırmızı mürekkeple daireye alınmış, kenarında *"Burada mı?"* notu var. |
| **E307** | Karartılmış Filtre Jeli | Işık Köprüsü | Köprünün kuzey tarafındaki spotun arkasına bantlanmış mat siyah karton; tetikçinin bulunduğu yeri karanlıkta bırakmış. |
| **E308** | Tüfeğe Sarılı Daktilo Notu | Çatı (Tüfeğin Üzeri) | Tüfeğin kayışına tutturulmuş kâğıt: *"Gözünü kırptın ve beni görmezden geldin."* ('r' harfi aşağı kayık). |
| **E309** | K-4 Cep Saati | Reeve'in Yelek Cebinde | K-4 damgalı askeri kurmalı saat. Göğsüne isabet eden merminin basıncıyla **20:52**'de durmuş. *(Anı Duvarı parçası)* |
| **E310** | Islak Sağ Deri Eldiven | Çatı Mahyası | Çatı kapağının yanında düşürülmüş, yağmurdan sırılsıklam olmuş sağ teki deri eldiven. |

---

## 6. 6 Çıkarım (Deduction) Sistemi

1. **D301: Zaman Ayarlı Ses Maskesi** *(E306 + E309)* — Atış 20:52'deki top efektiyle kamufle edilmiş.
2. **D302: Işık Köprüsündeki Kör Nokta** *(E302 + E303)* — Spot B açıkken ışık köprüsünün kuzey ucu mutlak karanlıkta kalıyordu.
3. **D303: Kopyalanan Anahtar (Finch'in Masumiyeti)** *(E304 + E305)* — Kilit zorlanmadı çünkü balmumu kalıpla kopyalanmıştı.
4. **D304: 1944'ün Hayaleti** *(E301 + E308)* — Cinayette kurbanın bıraktığı tüfek kullanıldı; daktilo notundaki aşağı kayık 'r' harfi aynı gölgeyi gösteriyor.
5. **D305: Elena'nın İmkânsız Tanıklığı** *(Elena İfadesi + D302)* — Sahne spotları Elena'nın gözlerini kör ediyordu; karşı balkondan ışıltı gördüğü iddiası asılsız.
6. **D306: Gölgedeki Tetikçi** *(D302 + D304 + E310)* — Katil bina içinden değil; çatıyı, ışıkları ve tüfeği önceden kurgulayıp kaçan dışarıdan bir suikastçı.

---

## 7. Yeni Mekanik: Işık-Menzil Panosu (Light-Range Board)

* Kulis duvarındaki ışık konsoluyla etkileşime girildiğinde açılan 480×270 mini bulmaca.
* **Girdiler:** 3 Spot Aç/Kapa anahtarı (Spot A: Sahne, Spot B: Loca, Spot C: Balkon) + 3 Olası Atış Hattı (Karşı Balkon, Havalandırma, Işık Köprüsü).
* `E303` (20:51 cue) verisine göre `Spot A: Kapalı`, `Spot B: Açık`, `Spot C: Kapalı` yapılıp `Işık Köprüsü` seçildiğinde:
  - Locadaki Reeve hedef hattı yeşil (açık hat).
  - Seyircilerin ve Elena'nın görüş açısı kırmızı/kör bölge.
  - Bulmaca tamamlanınca `D302` çıkarımı otomatik kazanılır.

---

## 8. Sezon Finali Sinematiği ve Çatı Kovalamacası

* Suçlama ekranında `unknown_sniper` seçilip çözüm sağlandığında Silas çatıya koşar.
* 3 adımlı zamanlı seçim (Merdiven, Havalandırma, Çatı Mahyası).
* Şimşek çaktığında Silas ilk kez Elias'ın **sol yüzündeki yanık yarasını** görür.
* Elias yangın merdiveninden sisli ara sokağa atlayarak kaybolur; geride `E310` (ıslak sağ eldiven) kalır.
* **FB03 "Dürbün"** tetiklenir: 1944 kışında mevziyi terk edip kaçan Dalton Reeve'in hatırası.
* Ofise dönüşte Anı Duvarı'na 3. saat olan **K-4 Saati** asılır; 1. Oyunun genel skor kartı açılır.
