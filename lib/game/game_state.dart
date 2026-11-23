import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/firebase_client.dart';
import '../utils/format.dart';
import 'balance.dart';

class GameReport {
  final String type; // 'offline' (ileride: 'attack', 'spy')
  final String text;
  final int ts;
  final double amount; // örn. offline kazanç
  const GameReport(this.type, this.text, this.ts, {this.amount = 0});

  Map<String, dynamic> toJson() => {'type': type, 'text': text, 'ts': ts, 'amount': amount};

  factory GameReport.fromJson(Map<String, dynamic> j) => GameReport(
      (j['type'] as String?) ?? '', (j['text'] as String?) ?? '', (j['ts'] as num?)?.toInt() ?? 0,
      amount: (j['amount'] as num?)?.toDouble() ?? 0);
}

class OfflineResult {
  final double seconds;
  final double earned;
  const OfflineResult(this.seconds, this.earned);
}

/// Oyuncunun ilerlemesi. Telefonda saklanır; hesaplar bu sınıftadır.
class GameState extends ChangeNotifier {
  static final GameState instance = GameState._();
  GameState._();

  final Random _rng = Random();
  late SharedPreferences _p;

  double money = 0;
  double xp = 0;
  int playerLevel = 1;
  int toolStep = 1; // 1..160
  List<int> levels = List<int>.filled(kBuildings.length, 0);
  List<GameReport> reports = [];
  int _lastSeen = 0; // sunucu saati (ms)

  /// Açılışta hesaplanan offline kazanç; ekran gösterince temizlenir.
  OfflineResult? pendingOffline;

  // Anlık durum
  double lastGain = 0;
  bool lastCrit = false;
  bool comboActive = false;
  final List<int> _taps = [];

  Timer? _timer;
  final Stopwatch _sw = Stopwatch();
  int _ticks = 0;

  // ------------------------------------------------------------ Hesaplar
  double get tapIncome => toolTap(toolStep) * levelPower(playerLevel);

  double get incomePerSec {
    var sum = 0.0;
    for (var b = 0; b < kBuildings.length; b++) {
      sum += buildingIncome(b, levels[b]);
    }
    return sum;
  }

  /// Puan = XP + para / 100
  int get score => min(xp + money / 100, 9e15).floor();

  // ------------------------------------------------------------ Yükle / kaydet
  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    final raw = _p.getString('save');
    if (raw != null) {
      try {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        money = (j['money'] as num?)?.toDouble() ?? 0;
        xp = (j['xp'] as num?)?.toDouble() ?? 0;
        playerLevel = (j['playerLevel'] as num?)?.toInt() ?? 1;
        toolStep = ((j['toolStep'] as num?)?.toInt() ?? 1).clamp(1, kToolSteps).toInt();
        final lv = (j['levels'] as List?)?.map((e) => (e as num).toInt()).toList() ?? [];
        for (var i = 0; i < levels.length && i < lv.length; i++) {
          levels[i] = lv[i].clamp(0, kBuildings[i].steps).toInt();
        }
        _lastSeen = (j['lastSeen'] as num?)?.toInt() ?? 0;
        reports = ((j['reports'] as List?) ?? [])
            .map((e) => GameReport.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        // Bozuk kayıt: sıfırdan başla.
      }
    }
    _applyOffline();
    await save();
  }

  void _applyOffline() {
    if (_lastSeen <= 0 || !ServerClock.known) return;
    final elapsed = (ServerClock.nowMs - _lastSeen) / 1000.0;
    final income = incomePerSec;
    if (elapsed < kOfflineMinSeconds || income <= 0) return;
    final earned = income * offlineEffectiveSeconds(elapsed);
    if (earned <= 0) return;
    money += earned;
    pendingOffline = OfflineResult(elapsed, earned);
    _addReport(GameReport('offline', '${fmtDuration(elapsed)} çevrimdışı kaldın.',
        DateTime.now().millisecondsSinceEpoch,
        amount: earned));
  }

  void _addReport(GameReport r) {
    reports.insert(0, r);
    if (reports.length > 50) reports.removeRange(50, reports.length);
  }

  Future<void> save() async {
    if (ServerClock.known) _lastSeen = ServerClock.nowMs;
    await _p.setString(
        'save',
        jsonEncode({
          'money': money,
          'xp': xp,
          'playerLevel': playerLevel,
          'toolStep': toolStep,
          'levels': levels,
          'lastSeen': _lastSeen,
          'reports': reports.map((r) => r.toJson()).toList(),
        }));
  }

  // ------------------------------------------------------------ Zamanlayıcı
  void start() {
    _timer?.cancel();
    _sw
      ..reset()
      ..start();
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    save();
  }

  void _tick() {
    final dt = _sw.elapsedMilliseconds / 1000.0;
    _sw.reset();
    money += incomePerSec * dt;
    _pruneTaps(DateTime.now().millisecondsSinceEpoch);
    comboActive = _taps.length >= kComboTaps;
    if (++_ticks % 20 == 0) save(); // ~5 sn'de bir
    notifyListeners();
  }

  void _pruneTaps(int now) {
    _taps.removeWhere((t) => now - t > kComboWindowMs);
  }

  // ------------------------------------------------------------ Eylemler
  void tap() {
    final now = DateTime.now().millisecondsSinceEpoch;
    _taps.add(now);
    _pruneTaps(now);
    comboActive = _taps.length >= kComboTaps;
    final crit = _rng.nextDouble() < kCritChance;
    final gain = tapIncome * (crit ? kCritMultiplier : 1.0) * (comboActive ? kComboMultiplier : 1.0);
    money += gain;
    lastGain = gain;
    lastCrit = crit;
    notifyListeners();
  }

  bool get toolMaxed => toolStep >= kToolSteps;
  double get nextToolPrice => toolMaxed ? 0 : toolPrice(toolStep + 1);

  bool buyTool() {
    if (toolMaxed) return false;
    final price = nextToolPrice;
    if (money < price) return false;
    money -= price;
    toolStep++;
    save();
    notifyListeners();
    return true;
  }

  bool buildingMaxed(int b) => levels[b] >= kBuildings[b].steps;
  bool buildingOpen(int b) => buildingUnlocked(b, levels);
  double nextBuildingPrice(int b) => buildingMaxed(b) ? 0 : buildingPrice(b, levels[b] + 1);

  bool buyBuilding(int b) {
    if (buildingMaxed(b) || !buildingOpen(b)) return false;
    final price = nextBuildingPrice(b);
    if (money < price) return false;
    money -= price;
    levels[b]++;
    save();
    notifyListeners();
    return true;
  }
}
