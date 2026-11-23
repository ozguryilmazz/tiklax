# BasBas — Oyun Tasarımı (taslak)

Rakamlar şimdilik "atıyorum"; oynadıkça ayarlanacak. Kararlar bu dosyada tutulur.

## Çekirdek
Para kazan → saldırı ve savunma birimleri üret → rakip oyunculara ve haritada rastgele
beliren barbar kamplarına saldır → XP ve puan topla.

## Oyuncu seviyesi
- En fazla **50 seviye**.
- Seviye atlama **savaş XP'siyle** olur: savaşta yok edilen ve kaybedilen birim başına XP.
- Tıklama gücü seviyeyle artar.
- Matematik (XP eğrisi, seviyeye göre tıklama geliri) **ertelendi**; sonra hesaplanacak.
  Taslak: `XP(L) = 100 × L^1.8`, tıklama = `L^1.6`.

## Tıklama başına gelir
`tıklama geliri = seviye gücü × eşya çarpanı × kritik × combo × iksir`
(Hepsi birbiriyle **çarpılır**.)

### Eşyalar (çekiç → kazma)
- Aynı anda tek eşya vardır, taşıma/envanter yok. Eşya **para ile** yükseltilir.
- Her yükseltme tıklama başına geliri artırır.
- Çekiç malzemeleri (sırayla), **her malzeme 10 kademe** (1…10):
  1. Tahta saplı taş çekiç
  2. Taş çekiç
  3. Bakır çekiç
  4. Bronz çekiç
  5. Demir çekiç
  6. Gümüş çekiç
  7. Altın çekiç
  8. Elmas çekiç
- Bir malzemenin 10 kademesi bitince bir sonraki malzemeye geçilir ve oradan devam edilir.
- **Kazma**, çekicin üst versiyonudur: aynı 8 malzeme ve her biri 10 kademe, çekiç zincirinden sonra gelir.
- Toplam: çekiç 80 + kazma 80 = **160 yükseltme basamağı**. Kazma, çekiç zincirinin devamıdır (81. basamaktan başlar), ayrı bir kol değil.

### Kritik
- Belirli ihtimalle o anki tıklama gelirinin **5 katı**. **Yükseltmeyle artmaz** (sabit).
- İhtimal: **%5**.

### Combo
- **5 saniye içinde 20 tıklama** yapılınca combo tetiklenir; tıklama geliri **×1,15**.
- Tıklama hızı 5 saniyede 20'nin altına düşünce combo durur.

### İksirler
- Savaş sonunda ganimet olarak düşer; oyuncu istediği zaman kullanır.
- Örnekler: 30 sn boyunca 2x tıklama geliri, 60 sn boyunca 2x sabit gelir.

## Sabit gelir (saniye başına)
Binalar para ile yükseltilir, her kademe saniyelik geliri artırır. Binalar:
1. Taş madeni
2. Altın madeni
3. Zümrüt madeni
4. Elmas madeni
5. Tüccar pazarı

Kademe sayısı: taş, altın, zümrüt ve elmas madenleri **10'ar kademe**, tüccar pazarı **40 kademe**
(toplam 40 + 40 = 80 basamak).

Kilit açma:
- Madenler ve tüccar pazarı **baştan kapalıdır**; oyuncu **parayla açar**.
- Madenler sırayla ilerler: elmas madenine gelene kadar öncekilerin kademeleri tamamlanır
  (taş 10 kademe → altın açılır → zümrüt → elmas).
- **Tüccar pazarı** ayrı bir bölümdür, madenlerden bağımsız başlayabilir. Madenler gibi para getirir.
- Taş madeninin açılış fiyatı ve fiyat/gelir değerleri: konuşulmadı.

## Offline gelir
Sadece **sabit (saniyelik) gelir** offline kazanılır; kazanç süreye göre azalır:

| Offline süre | Verim |
|---|---|
| İlk 2 saat | %100 |
| Sonraki 2 saat (2–4. saat) | %50 |
| Sonraki 2 saat (4–6. saat) | %25 |
| 6. saatten sonra | %0 |

Toplam: en fazla 2×1 + 2×0,5 + 2×0,25 = **3,5 saatlik tam gelire** denk gelir.
Süre sunucu zamanıyla ölçülür (telefon saatiyle hile yapılmasın).

## Raporlar bölümü
Oyuncu uygulamayı açınca / istediğinde görebileceği kayıtlar:
- **Saldırı raporu:** Oyuncu saldırı aldıysa savaş sonuç bilgileri.
- **Casusluk raporu:** Casusluk yapıldıysa (veya yapıldığında) elde edilen bilgiler.
- **Offline kazanç raporu:** Offline sürede ne kadar kazanıldığı.

## Savaş ve harita

### Hedef seçimi
- Rakip oyuncular **harita üzerinde** seçilir (konumlarından).
- Barbar kampları haritada **rastgele konumlarda** belirir; bulmak için **casus** kullanılır.

### Savaş
- Savaş **otomatik** çözülür (saldırı gücü ↔ savunma gücü).
- Oyuncu **offline** ise saldırıya karşı savunma gücüne **%20–30 arası rastgele koruma kalkanı** eklenir.
- **Yağma:** Kazanan, kaybedenin parasının **%20'sini** alır ve **XP** kazanır.
- Savaş sonucu iki tarafın raporuna da düşer.

### Casusluk
- **Casus birimi eğitilir.**
- Casus iki iş yapar: haritada **barbar kampı arar**, ve **düşman üssüne gidip askeri bilgi çalar**.
- Başarı, casusluk yapanın askeri gücünün rakibin askeri gücüne **oranına** göre belirlenir.
- Taslak eşikler (oran = kendi güç / rakip güç; sonra ayarlanacak):

| Oran | Sonuç |
|---|---|
| 0,25'ten küçük (örn. 100'e 1000) | Başarısız |
| 0,25 – 1 (örn. 100'e 200) | Sadece belli bina kademeleri |
| 1 – 2 | Daha çok bina kademesi |
| 2 ve üstü (örn. 100'e 50) | Çok bina kademesi ve belli askeri birimler |

### Kararlar
- Casus **yakalanınca kaybolur**, yeniden eğitilmesi gerekir.
- Saldırı ve casusluk **kısa bir yolculuk süresi** alır.

### Açık sorular
- Saldırı sıklığı koruması (saldırıdan sonra koruma süresi, günlük sınır).
- Askeri güç nasıl hesaplanır (saldırı ve savunma birimleri, değerleri): sonra konuşulacak.

## Birimler (taslak; maliyet ve güç değerleri önerilen, ayarlanacak)
Maliyetler "para" cinsindendir ve tıklama/sabit gelir dengesi kurulunca ölçeklenecek.
Birim XP değeri = maliyet ÷ 10 (savaşta yok edilen/kaybedilen birim başına XP).
Askeri güç (casusluk için) = toplam saldırı gücü + toplam savunma gücü.

### Saldırı birimleri
| Birim | Maliyet | Saldırı gücü | XP |
|---|---|---|---|
| Asker | 100 | 10 | 10 |
| Topçu | 500 | 55 | 50 |
| Tank | 2.500 | 300 | 250 |
| Uçak | 15.000 | 2.100 | 1.500 |
| SİHA | 8.000 | 1.040 | 800 |

### Savunma birimleri
| Birim | Maliyet | Savunma gücü | XP |
|---|---|---|---|
| Nöbetçi | 100 | 10 | 10 |
| Tank savar | 1.000 | 100 | 100 |
| Uçak savar | 2.000 | 200 | 200 |

### Karşılıklı etkiler (savunanın savunma çarpanı, saldırı türüne göre)
| Savunma birimi | Karşı çarpan |
|---|---|
| Nöbetçi | Hepsine ×1 |
| Tank savar | Tanka ×2, diğerlerine ×0,5 |
| Uçak savar | Uçağa ve SİHA'ya ×2, diğerlerine ×0,5 |

### Casus
- Maliyet: 300 (öneri). Yakalanınca kaybolur.
