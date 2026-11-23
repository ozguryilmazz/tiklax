import 'dart:convert';

import 'firebase_client.dart';
import 'session.dart';

class InboxMessage {
  final String id;
  final String fromName;
  final String text;
  final int ts;
  const InboxMessage(this.id, this.fromName, this.text, this.ts);
}

class MessageService {
  /// Kullanıcı adından uid bulup alıcının gelen kutusuna yazar. Hata metni döner, başarıda null.
  static Future<String?> send(String toName, String text) async {
    final to = toName.trim().toLowerCase();
    final msg = text.trim();
    if (to.isEmpty || msg.isEmpty) return 'Alıcı ve mesaj boş olamaz.';
    if (msg.length > 500) return 'Mesaj en fazla 500 karakter olabilir.';
    try {
      final g = await FirebaseClient.send('GET', 'usernames/$to');
      if (g.statusCode != 200) return 'HTTP ${g.statusCode}: ${g.body}';
      if (g.body == 'null') return '"$to" adında bir oyuncu yok.';
      final toUid = jsonDecode(g.body) as String;
      final r = await FirebaseClient.send('POST', 'inbox/$toUid', body: {
        'from': FirebaseClient.uid,
        'fromName': Session.username,
        'text': msg,
        'ts': DateTime.now().millisecondsSinceEpoch,
      });
      if (r.statusCode != 200) return 'HTTP ${r.statusCode}: ${r.body}';
      await Session.addSent('$to|$msg');
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Gelen kutusu, yeniden eskiye. Hata olursa fırlatır.
  static Future<List<InboxMessage>> inbox() async {
    final r = await FirebaseClient.send('GET', 'inbox/${FirebaseClient.uid}');
    if (r.statusCode != 200) {
      throw Exception('HTTP ${r.statusCode}: ${r.body}');
    }
    if (r.body == 'null' || r.body.isEmpty) return [];
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    final list = data.entries
        .where((e) => e.value is Map)
        .map((e) {
          final m = e.value as Map<String, dynamic>;
          return InboxMessage(e.key, (m['fromName'] as String?) ?? '?',
              (m['text'] as String?) ?? '', (m['ts'] as num?)?.toInt() ?? 0);
        })
        .toList();
    list.sort((a, b) => b.ts.compareTo(a.ts));
    return list;
  }

  static Future<void> delete(String id) async {
    await FirebaseClient.send('DELETE', 'inbox/${FirebaseClient.uid}/$id');
  }
}
