# BasBas

Flutter ile yazılmış Android oyunu. APK'yı GitHub Actions derler ve GitHub Releases'e yükler;
oyundaki "Güncellemeyi kontrol et" butonu en son release'i okuyup APK'yı indirir.

## Kurulum (bir kerelik)

1. **GitHub secret'ları** (Settings > Secrets and variables > Actions):
   `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS`
2. **Actions izni:** Settings > Actions > General > Workflow permissions > *Read and write permissions*
3. **Firebase projesi:**
   - Realtime Database oluştur (konum: Avrupa).
   - Authentication > Sign-in method > **Anonymous** açık olsun.
   - Realtime Database > Rules sekmesine `database.rules.json` içeriğini yapıştırıp yayınla.
     **Kurallar her güncellemede değişebilir: yeni bir aşama eklenince tekrar yapıştırıp yayınla** (harita için `maps` kuralları Aşama 2'de eklendi).
   - `lib/config.dart` içindeki `kDbUrl` ve `kApiKey` değerlerini doldur
     (API anahtarı: Project settings > General > Web API Key).

## Yeni sürüm çıkarmak

`main` dalına push yapmak yeterli: Actions APK'yı derler, `build-<numara>` etiketiyle release açar.
Telefondaki oyun, release numarası kendi build numarasından büyükse güncelleme önerir.

## Notlar

- Paket adı `com.ozgur.basbas`'tır, değiştirme: değişirse Android güncellemeyi yeni uygulama sayar.
- İmza anahtarını (`.jks`) kaybetme ve repoya koyma: aynı anahtarla imzalanmayan APK, mevcut oyunun üstüne kurulmaz.
- `lib/screens/game_screen.dart` geçici bir tıklama sayacıdır; asıl oyun içeriği sonra eklenecek.
- Skorlar ve gelen kutusu 10 saniyede bir yenilenir (`kPollSeconds`).
