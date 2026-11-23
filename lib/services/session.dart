import 'package:shared_preferences/shared_preferences.dart';

/// Telefonda saklanan veriler: kullanıcı adı ve oyun ilerlemesi.
class Session {
  static late SharedPreferences _p;

  static Future<void> init() async {
    _p = await SharedPreferences.getInstance();
  }

  static String? get username => _p.getString('username');
  static Future<void> setUsername(String v) => _p.setString('username', v);

  static int get score => _p.getInt('score') ?? 0;
  static Future<void> setScore(int v) => _p.setInt('score', v);

  /// Gönderilen mesajlar telefonda tutulur (sunucuda sadece alıcının kutusu var).
  static List<String> get sentMessages => _p.getStringList('sent') ?? [];
  static Future<void> addSent(String line) {
    final l = sentMessages..add(line);
    if (l.length > 100) l.removeRange(0, l.length - 100);
    return _p.setStringList('sent', l);
  }
}
