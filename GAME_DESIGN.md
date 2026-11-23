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
- Toplam: çekiç 80 + kazma 80 = **160 yükseltme basamağı** (doğrulanacak).

### Kritik
- Belirli ihtimalle o anki tıklama gelirinin **5 katı**. İhtimal: belirlenecek.

### Combo
- **5 saniye içinde 20 tıklama** yapılınca combo tetiklenir; tıklama geliri **×1,15**.
- Tıklama hızı 5 saniyede 20'nin altına düşünce combo durur.

### İksirler
- Savaş sonunda ganimet olarak düşer; oyuncu istediği zaman kullanır.
- Örnekler: 30 sn boyunca 2x tıklama geliri, 60 sn boyunca 2x sabit gelir.

## Sabit gelir (saniye başına) — henüz konuşulmadı
## Offline gelir — fikirler konuşuldu, karar bekliyor
## Savaş ve harita — henüz konuşulmadı
