/// Firebase Console > Realtime Database sayfasındaki adres (sonunda "/" olmasın).
/// Örnek: 'https://basbas-xxxxx-default-rtdb.europe-west1.firebasedatabase.app'
const String kDbUrl = 'https://basbas-6cccd-default-rtdb.europe-west1.firebasedatabase.app';

/// Firebase Console > Project settings > General > "Web API Key".
const String kApiKey = 'AIzaSyDx0i2gPYSDtQAx6DakHsTGSsev_KJAmgM';

/// Güncellemelerin indirildiği GitHub deposu (Releases).
const String kGithubRepo = 'ozguryilmazz/tiklax';

/// Skorlar ve gelen kutusu kaç saniyede bir yenilensin.
const int kPollSeconds = 10;

bool get isConfigured =>
    !kDbUrl.startsWith('BURAYA_') && !kApiKey.startsWith('BURAYA_');
