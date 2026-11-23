import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../game/balance.dart';
import 'firebase_client.dart';
import 'session.dart';

class MapPlayer {
  final String uid;
  final String name;
  final int x;
  final int y;
  final double atk;
  final double def;
  const MapPlayer(this.uid, this.name, this.x, this.y, this.atk, this.def);
}

class Camp {
  final String id;
  final int x;
  final int y;
  final int stars;
  final double power;
  const Camp(this.id, this.x, this.y, this.stars, this.power);
}

class PendingCamp {
  final String id;
  final int stars;
  final int readyAt;
  const PendingCamp(this.id, this.stars, this.readyAt);
}

class MapData {
  final List<MapPlayer> players;
  final List<Camp> camps;
  final List<PendingCamp> pending;
  MapData(this.players, this.camps, this.pending);
  MapData.empty() : this([], [], []);
}

class CampFetch {
  final Camp camp;
  final String etag;
  const CampFetch(this.camp, this.etag);
}

/// Harita: oyuncu yerleşimi, barbar kampları. Tüm oyuncular aynı Firebase verisini okur/yazar;
/// kamp doğurma işini haritadaki telefonlar sırayla yapar (sunucu kodu yok).
class MapService {
  static String? mapId;
  static int myX = -1;
  static int myY = -1;
  static MapData data = MapData.empty();
  static bool _placing = false;
  static final Random _rng = Random();

  static bool get placed => mapId != null && myX >= 0 && myY >= 0;

  static double distanceTo(int x, int y) =>
      sqrt(pow(x - myX, 2) + pow(y - myY, 2).toDouble());

  static double _dist(int x1, int y1, int x2, int y2) =>
      sqrt(pow(x1 - x2, 2) + pow(y1 - y2, 2).toDouble());

  // ------------------------------------------------------------ Yerleşim
  /// Daha önce yerleştirildiyse onu okur; değilse boş yeri olan haritaya rastgele yerleşir.
  static Future<void> ensurePlaced() async {
    if (placed || _placing) return;
    _placing = true;
    try {
      final p = await SharedPreferences.getInstance();
      mapId = p.getString('mapId');
      myX = p.getInt('mapX') ?? -1;
      myY = p.getInt('mapY') ?? -1;
      if (placed) return;
      mapId = null;
      for (var n = 1; n < 1000; n++) {
        final mid = 'm$n';
        final pos = await _tryPlace(mid);
        if (pos != null) {
          mapId = mid;
          myX = pos.$1;
          myY = pos.$2;
          await p.setString('mapId', mid);
          await p.setInt('mapX', myX);
          await p.setInt('mapY', myY);
          return;
        }
      }
    } finally {
      _placing = false;
    }
  }

  static Future<(int, int)?> _tryPlace(String mid) async {
    final shallow =
        await FirebaseClient.send('GET', 'maps/$mid/players', query: {'shallow': 'true'});
    if (shallow.statusCode != 200) {
      throw Exception('Harita okunamadı (HTTP ${shallow.statusCode}): ${shallow.body}');
    }
    var count = 0;
    if (shallow.body != 'null') count = (jsonDecode(shallow.body) as Map).length;
    if (count >= kMapCapacity) return null;

    final d = await _fetch(mid);
    for (var i = 0; i < 300; i++) {
      final x = _rng.nextInt(kMapSize);
      final y = _rng.nextInt(kMapSize);
      if (!_isFree(d, x, y)) continue;
      if (d.players.any((p) => _dist(p.x, p.y, x, y) < kMinPlayerDistance)) continue;
      final r = await FirebaseClient.send('PUT', 'maps/$mid/cells/${x}_$y',
          body: FirebaseClient.uid, headers: {'if-match': 'null_etag'});
      if (r.statusCode == 200) {
        await FirebaseClient.send('PUT', 'maps/$mid/players/${FirebaseClient.uid}', body: {
          'name': Session.username ?? '?',
          'x': x,
          'y': y,
          'atk': 0,
          'def': 0,
        });
        return (x, y);
      }
      if (r.statusCode != 412) {
        throw Exception('Yerleşilemedi (HTTP ${r.statusCode}): ${r.body}');
      }
    }
    return null;
  }

  static bool _isFree(MapData d, int x, int y) =>
      !d.players.any((p) => p.x == x && p.y == y) && !d.camps.any((c) => c.x == x && c.y == y);

  // ------------------------------------------------------------ Okuma
  static Future<MapData> _fetch(String mid) async {
    final r = await FirebaseClient.send('GET', 'maps/$mid');
    if (r.statusCode != 200) {
      throw Exception('Harita okunamadı (HTTP ${r.statusCode}): ${r.body}');
    }
    if (r.body == 'null') return MapData.empty();
    final m = jsonDecode(r.body) as Map<String, dynamic>;
    final players = <MapPlayer>[];
    final camps = <Camp>[];
    final pending = <PendingCamp>[];
    (m['players'] as Map?)?.forEach((k, v) {
      if (v is Map) {
        players.add(MapPlayer(k as String, (v['name'] as String?) ?? '?',
            (v['x'] as num?)?.toInt() ?? 0, (v['y'] as num?)?.toInt() ?? 0,
            (v['atk'] as num?)?.toDouble() ?? 0, (v['def'] as num?)?.toDouble() ?? 0));
      }
    });
    (m['camps'] as Map?)?.forEach((k, v) {
      if (v is Map) camps.add(_campFrom(k as String, v));
    });
    (m['pending'] as Map?)?.forEach((k, v) {
      if (v is Map) {
        pending.add(PendingCamp(k as String, (v['stars'] as num?)?.toInt() ?? 1,
            (v['readyAt'] as num?)?.toInt() ?? 0));
      }
    });
    return MapData(players, camps, pending);
  }

  static Camp _campFrom(String id, Map v) => Camp(id, (v['x'] as num?)?.toInt() ?? 0,
      (v['y'] as num?)?.toInt() ?? 0, (v['stars'] as num?)?.toInt() ?? 1,
      (v['power'] as num?)?.toDouble() ?? kCampMinPower);

  /// Haritayı yeniler ve gerekirse kampları doğurur.
  static Future<void> poll() async {
    if (!placed) return;
    data = await _fetch(mapId!);
    await _maintainCamps();
  }

  /// Kendi gücünü haritaya yazar (kamp gücü ortalamaya göre hesaplanır).
  static Future<void> publishSelf(double atk, double def) async {
    if (!placed) return;
    await FirebaseClient.send('PUT', 'maps/$mapId/players/${FirebaseClient.uid}', body: {
      'name': Session.username ?? '?',
      'x': myX,
      'y': myY,
      'atk': atk,
      'def': def,
    });
  }

  // ------------------------------------------------------------ Kamplar
  static Future<void> _maintainCamps() async {
    if (!ServerClock.known) return;
    final now = ServerClock.nowMs;

    // Süresi dolan "bekleyen" kamplar: ilk sahiplenen telefon yenisini doğurur.
    for (final p in List<PendingCamp>.from(data.pending)) {
      if (p.readyAt <= now && await _claimPending(p)) {
        await _spawn(p.stars);
      }
    }
    // Eksik kamp varsa tamamla (haritanın ilk dolduruluşu dahil).
    for (final stars in kCampTargets.keys) {
      final existing = data.camps.where((c) => c.stars == stars).length;
      final waiting = data.pending.where((p) => p.stars == stars).length;
      final deficit = kCampTargets[stars]! - existing - waiting;
      for (var i = 0; i < deficit; i++) {
        await _spawn(stars);
      }
    }
  }

  static Future<bool> _claimPending(PendingCamp p) async {
    final g = await FirebaseClient.send('GET', 'maps/$mapId/pending/${p.id}',
        headers: {'X-Firebase-ETag': 'true'});
    if (g.statusCode != 200 || g.body == 'null') return false;
    final etag = g.headers['etag'];
    if (etag == null) return false;
    final d = await FirebaseClient.send('DELETE', 'maps/$mapId/pending/${p.id}',
        headers: {'if-match': etag});
    return d.statusCode == 200;
  }

  static Future<void> _spawn(int stars) async {
    var avg = 0.0;
    if (data.players.isNotEmpty) {
      avg = data.players.map((p) => p.atk).reduce((a, b) => a + b) / data.players.length;
    }
    final power = (max(kCampMinPower, avg) * kCampPowerFactor[stars]!).roundToDouble();
    for (var i = 0; i < 100; i++) {
      final x = _rng.nextInt(kMapSize);
      final y = _rng.nextInt(kMapSize);
      if (!_isFree(data, x, y)) continue;
      final r = await FirebaseClient.send('PUT', 'maps/$mapId/campcells/${x}_$y',
          body: true, headers: {'if-match': 'null_etag'});
      if (r.statusCode == 412) continue;
      if (r.statusCode != 200) return;
      final id = 'c${ServerClock.nowMs}_${_rng.nextInt(99999)}';
      final w = await FirebaseClient.send('PUT', 'maps/$mapId/camps/$id', body: {
        'x': x,
        'y': y,
        'stars': stars,
        'power': power,
        'spawnedAt': ServerClock.nowMs,
      });
      if (w.statusCode == 200) data.camps.add(Camp(id, x, y, stars, power));
      return;
    }
  }

  /// Kampı okur ve etag'ini verir; kamp yoksa null.
  static Future<CampFetch?> fetchCamp(String campId) async {
    final g = await FirebaseClient.send('GET', 'maps/$mapId/camps/$campId',
        headers: {'X-Firebase-ETag': 'true'});
    if (g.statusCode != 200) {
      throw Exception('Kamp okunamadı (HTTP ${g.statusCode}): ${g.body}');
    }
    if (g.body == 'null') return null;
    final etag = g.headers['etag'];
    if (etag == null) return null;
    return CampFetch(_campFrom(campId, jsonDecode(g.body) as Map), etag);
  }

  /// Kampı yok eder (aynı anda iki oyuncu vurursa sadece biri başarır) ve 5 dk sonra yenisini kuyruğa alır.
  static Future<bool> destroyCamp(CampFetch f) async {
    final d = await FirebaseClient.send('DELETE', 'maps/$mapId/camps/${f.camp.id}',
        headers: {'if-match': f.etag});
    if (d.statusCode != 200) return false;
    await FirebaseClient.send('DELETE', 'maps/$mapId/campcells/${f.camp.x}_${f.camp.y}');
    final pid = 'p${ServerClock.nowMs}_${_rng.nextInt(99999)}';
    await FirebaseClient.send('PUT', 'maps/$mapId/pending/$pid', body: {
      'stars': f.camp.stars,
      'readyAt': ServerClock.nowMs + kCampRespawnMs,
    });
    data.camps.removeWhere((c) => c.id == f.camp.id);
    return true;
  }
}
