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

### Harita
- **16 × 16 = 256 kare.**
- Her harita en fazla **12 oyuncu** alır; yeni oyuncu yeri olan bir haritaya yerleştirilir, dolunca yeni harita açılır.
- Oyuncular **rastgele** konumlanır; aralarında **en az 5 kare** mesafe olur (ilk "20 kare" fikri haritaya sığmıyordu, 5 kareyle ~12 oyuncu sığar).
- Rakip oyuncular **harita üzerinde** seçilir (konumlarından).

### Barbar kampları
- 3 çeşit: **1, 2 ve 3 yıldızlı**. Haritada aynı anda her çeşitten **birden fazla** bulunabilir
  (örn. 2 tane 1 yıldızlı, 3 tane 2 yıldızlı).
- Konumları **rastgele**; bulmak için **casus** kullanılır.
- Yok edilince **5 dakika sonra** başka rastgele bir yerde yenisi belirir.
- Ödül (yenince): **para ve XP**.

| Kamp | Para ödülü | XP (şimdilik) |
|---|---|---|
| 1 yıldız | Oyuncunun toplam bakiyesinin %10'u | 5 |
| 2 yıldız | %20'si | 10 |
| 3 yıldız | %30'u | 15 |

- **Kamp gücü (savunma):** kamp doğduğu anda, o haritadaki oyuncuların ortalama saldırı gücü hesaplanır;
  1 yıldız = ortalamanın **×0,3**'ü, 2 yıldız **×0,6**'sı, 3 yıldız **×1,0**'ı. Doğduktan sonra sabit kalır.
  Böylece kamplar oyuncularla birlikte büyür.
- Aynı anda kaç kamp bulunacağı (öneri: 1 yıldızdan 4, 2 yıldızdan 3, 3 yıldızdan 2): konuşulmadı.

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

## Birim üretimi
- Üretim **anında** olur (bekleme süresi yok).
- Birim sayısı için **sınır yok**; tek kısıt paradır.

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

## Skor / puan
- Puan **XP ve paradan** oluşur: `puan = XP + para ÷ 100` (öneri; ağırlıklar oynadıkça ayarlanır).
- Skor tablosu bu puana göre sıralanır.

## İksirler
- Sonra eklenecek.

## Mimari karar
- İlk sürümde oyun hesapları (gelir, savaş, kamp doğurma) **telefonda** yapılır; Firebase veri taşır.
  Oyuncular çocuk, hile riski şimdilik kabul edildi. Daha sonra **Cloud Functions**'a (Blaze planı) geçilecek.
- Geçişi kolaylaştırmak için oyun kuralları (gelir, savaş, XP formülleri) arayüzden ayrı, saf Dart
  dosyalarında (`lib/game/`) tutulur.

## Yol haritası
1. **Çekirdek:** tıklama, kritik, combo, çekiç/kazma (160 basamak), madenler ve tüccar pazarı (80 basamak),
   sabit gelir, offline gelir ve raporu, ilerlemenin kaydı (telefon + Firebase yedeği).
2. **Birimler ve harita:** birim üretimi, 16×16 harita, oyuncu yerleşimi, barbar kampları ve kamp saldırısı.
3. **Oyuncu savaşı:** rakibe saldırı, yağma, offline kalkan, raporlar, seviye ve XP, casus ve casusluk.
4. **Cila:** iksirler, ses, animasyon, skor tablosu ve mesajlaşmanın oyuna bağlanması.

## Denge önerisi (taslak; oynadıkça ayarlanır, değerler `lib/game/balance.dart` içinde olacak)

### Çekiç/kazma (160 basamak, basamak s = 1…160)
- Malzeme sırası `k = (s-1) ÷ 10` (0…15), malzeme içi kademe `j = (s-1) mod 10` (0…9).
- Tıklama geliri: `M(s) = 3,5^k × (1 + 0,25 × j)`  (s=1 → 1 para/tık; s=160 → ~470 milyon/tık).
- Basamak fiyatı: `fiyat(s) = hedef_geri_ödeme(s) × (M(s) − M(s−1))`, `hedef_geri_ödeme(s) = 20 × 1,035^(s−1)` tık
  (yani basamak başta ~20 tıkta, sonda ~4.800 tıkta kendini öder).

| Basamak | Tıklama geliri | Fiyat |
|---|---|---|
| 2 | 1,25 | 5 |
| 10 | 3,25 | 7 |
| 20 | 11 | 34 |
| 40 | 139 | 820 |
| 80 | 20,9 K | 487 K |
| 120 | 3,1 M | 290 M |
| 160 | 471 M | 172 B |

### Binalar (sabit gelir)
- Madenler ve pazar aynı mantıkla üretilir: bir kademenin saniyelik geliri, aynı "aşamadaki" tıklama gelirinin
  **~2 katı** olacak şekilde (oyuncu saniyede ~2 tık eşdeğeri pasif kazanır). Fiyat, hedef geri ödeme süresi
  (başta ~1 dk, sonda ~20 dk) × gelir artışı.
- Büyük sayılar K / M / B / T biçiminde gösterilir.

## Uygulama durumu
- **Aşama 1 (çekirdek):** tıklama, kritik, combo, çekiç/kazma, madenler ve pazar, sabit gelir, offline gelir, yerel kayıt.
- **Aşama 2 (kodlandı):** birim üretimi, seviye/XP (50 seviye), 16×16 harita, oyuncu yerleşimi (12 oyuncu/harita, en az 5 kare),
  barbar kampları (4/3/2 adet, 5 dk'da yenilenir), casusla kamp arama, kamp saldırısı, kamp raporları.
- Değerler `lib/game/balance.dart` içinde. İlerleme telefonda (SharedPreferences) saklanır.
- Henüz yok: oyuncuya saldırı, yağma, offline kalkan, oyuncular arası casusluk, iksirler.

### Aşama 2'de verilen kararlar (öneri; değiştirilebilir)
- Birim fiyatı, elde o birimden ne kadar çok varsa o kadar artar (her birimde %0,5). Sınır yok ama ekonomi dengelenir.
- Kamp saldırısına **tüm saldırı birimleri** gider; aynı anda **tek sefer**. Yolculuk: 5 sn + mesafe başına 2 sn.
- Savaş: şans çarpanı 0,9–1,1. Kazanınca kayıp %30'a kadar (güç farkı büyüdükçe azalır), kaybedince %50–90.
- XP: kamp XP'si (5/10/15) + kaybedilen birim başına yarım birim XP'si. Kamp gücü o haritadaki oyuncuların ortalama saldırı gücüne göre.
- Casus kamp ararken %20 ihtimalle yakalanıp kaybolur; yoksa gizli bir kampı görünür yapar.
- Kamp gücü ve oyuncu güçleri telefonlar tarafından yazılır (sunucu kodu yok); hile riski şimdilik kabul edildi.
