/// Firebase Console > Realtime Database sayfasındaki adres (sonunda "/" olmasın).
/// Örnek: 'https://basbas-xxxxx-default-rtdb.europe-west1.firebasedatabase.app'
const String kDbUrl = 'BURAYA_DB_URL';

/// Firebase Console > Project settings > General > "Web API Key".
const String kApiKey = 'BURAYA_API_KEY';

/// Güncellemelerin indirildiği GitHub deposu (Releases).
const String kGithubRepo = 'ozguryilmazz/tiklax';

/// Skorlar ve gelen kutusu kaç saniyede bir yenilensin.
const int kPollSeconds = 10;

bool get isConfigured =>
    !kDbUrl.startsWith('BURAYA_') && !kApiKey.startsWith('BURAYA_');
