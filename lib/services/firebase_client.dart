import 'dart:async';
import 'dart:convert';
import 'dart:io' show HttpDate;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';

/// Sunucu saati: Firebase yanıtlarının "Date" başlığından, telefon saatiyle farkı öğrenir.
/// Offline kazanç gibi süreler telefon saatiyle değil bununla ölçülür (saat oynayarak hile yapılamasın).
class ServerClock {
  static int _offsetMs = 0;
  static bool known = false;

  static int get nowMs => DateTime.now().millisecondsSinceEpoch + _offsetMs;

  static void update(http.Response r) {
    final d = r.headers['date'];
    if (d == null) return;
    try {
      _offsetMs = HttpDate.parse(d).millisecondsSinceEpoch -
          DateTime.now().millisecondsSinceEpoch;
      known = true;
    } catch (_) {}
  }
}

/// Firebase Realtime Database'e REST ile konuşur. Giriş "anonim" yapılır:
/// her telefon kendine bir uid alır, kurallar bu uid'ye göre çalışır.
class FirebaseClient {
  static final http.Client _http = http.Client();
  static String? uid;
  static String? _idToken;
  static String? _refreshToken;
  static int _expiresAt = 0;

  static Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    _refreshToken = p.getString('refreshToken');
    uid = p.getString('uid');
    if (_refreshToken == null) {
      await _signUp();
    } else {
      await _refresh();
    }
  }

  static Future<void> _signUp() async {
    final r = await _http
        .post(
          Uri.parse(
              'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$kApiKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'returnSecureToken': true}),
        )
        .timeout(const Duration(seconds: 15));
    ServerClock.update(r);
    if (r.statusCode != 200) {
      throw Exception('Giriş başarısız (HTTP ${r.statusCode}): ${r.body}');
    }
    final d = jsonDecode(r.body) as Map<String, dynamic>;
    await _apply(d['idToken'] as String, d['refreshToken'] as String,
        int.parse(d['expiresIn'] as String), d['localId'] as String);
  }

  static Future<void> _refresh() async {
    final r = await _http
        .post(
          Uri.parse('https://securetoken.googleapis.com/v1/token?key=$kApiKey'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: 'grant_type=refresh_token&refresh_token=$_refreshToken',
        )
        .timeout(const Duration(seconds: 15));
    ServerClock.update(r);
    if (r.statusCode != 200) {
      // Token geçersizse yeniden anonim giriş yap.
      if (r.statusCode == 400) {
        await _signUp();
        return;
      }
      throw Exception('Oturum yenilenemedi (HTTP ${r.statusCode}): ${r.body}');
    }
    final d = jsonDecode(r.body) as Map<String, dynamic>;
    await _apply(d['id_token'] as String, d['refresh_token'] as String,
        int.parse(d['expires_in'] as String), d['user_id'] as String);
  }

  static Future<void> _apply(
      String idToken, String refreshToken, int expiresIn, String userId) async {
    _idToken = idToken;
    _refreshToken = refreshToken;
    uid = userId;
    _expiresAt = DateTime.now().millisecondsSinceEpoch + expiresIn * 1000;
    final p = await SharedPreferences.getInstance();
    await p.setString('refreshToken', refreshToken);
    await p.setString('uid', userId);
  }

  static Future<String> _token() async {
    if (_idToken == null ||
        DateTime.now().millisecondsSinceEpoch > _expiresAt - 60000) {
      await _refresh();
    }
    return _idToken!;
  }

  /// [path] örn. 'players/abc'. Yanıt gövdesi 'null' ise veri yok demektir.
  static Future<http.Response> send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
    Map<String, String>? headers,
  }) async {
    final token = await _token();
    final uri = Uri.parse('$kDbUrl/$path.json')
        .replace(queryParameters: {...?query, 'auth': token});
    final req = http.Request(method, uri);
    if (headers != null) req.headers.addAll(headers);
    if (body != null) {
      req.headers['Content-Type'] = 'application/json';
      req.body = jsonEncode(body);
    }
    final streamed = await _http.send(req).timeout(const Duration(seconds: 10));
    final res = await http.Response.fromStream(streamed);
    ServerClock.update(res);
    return res;
  }
}
