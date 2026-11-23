import 'dart:convert';

import 'firebase_client.dart';

class UsernameResult {
  final bool ok;
  final String? error;
  const UsernameResult(this.ok, [this.error]);
}

class PlayerEntry {
  final String name;
  final int score;
  const PlayerEntry(this.name, this.score);
}

class PlayerService {
  static final RegExp validName = RegExp(r'^[a-z0-9_]{3,16}$');

  /// Kullanıcı adını sunucuda sahiplenir. Ad zaten başkasındaysa başarısız olur.
  static Future<UsernameResult> claimUsername(String name) async {
    if (!validName.hasMatch(name)) {
      return const UsernameResult(
          false, '3-16 karakter; sadece küçük harf, rakam ve _ kullan.');
    }
    try {
      // "null_etag": sadece kayıt hiç yoksa yazar, varsa 412 döner.
      final r = await FirebaseClient.send('PUT', 'usernames/$name',
          body: FirebaseClient.uid, headers: {'if-match': 'null_etag'});
      if (r.statusCode == 200) return const UsernameResult(true);
      if (r.statusCode == 412) {
        // Daha önce bu telefon almış olabilir.
        final g = await FirebaseClient.send('GET', 'usernames/$name');
        if (g.statusCode == 200 && jsonDecode(g.body) == FirebaseClient.uid) {
          return const UsernameResult(true);
        }
        return const UsernameResult(false, 'Bu kullanıcı adı alınmış.');
      }
      return UsernameResult(false, 'HTTP ${r.statusCode}: ${r.body}');
    } catch (e) {
      return UsernameResult(false, e.toString());
    }
  }

  /// Kendi skorunu yükler.
  static Future<String?> uploadScore(String name, int score) async {
    try {
      final r = await FirebaseClient.send('PUT', 'players/${FirebaseClient.uid}',
          body: {
            'name': name,
            'score': score,
            'updatedAt': DateTime.now().millisecondsSinceEpoch,
          });
      return r.statusCode == 200 ? null : 'HTTP ${r.statusCode}: ${r.body}';
    } catch (e) {
      return e.toString();
    }
  }

  /// En yüksek skorlu 50 oyuncu. Hata olursa fırlatır (ekranda gösterilsin diye).
  static Future<List<PlayerEntry>> topPlayers() async {
    final r = await FirebaseClient.send('GET', 'players',
        query: {'orderBy': '"score"', 'limitToLast': '50'});
    if (r.statusCode != 200) {
      throw Exception('HTTP ${r.statusCode}: ${r.body}');
    }
    if (r.body == 'null' || r.body.isEmpty) return [];
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    final list = data.values
        .whereType<Map<String, dynamic>>()
        .map((m) => PlayerEntry(
            (m['name'] as String?) ?? '?', (m['score'] as num?)?.toInt() ?? 0))
        .toList();
    list.sort((a, b) => b.score.compareTo(a.score));
    return list;
  }
}
