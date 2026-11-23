import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/firebase_client.dart';
import '../services/map_service.dart';
import '../utils/format.dart';
import 'balance.dart';

class GameReport {
  final String type; // 'offline', 'camp', 'level' (ileride: 'attack', 'spy')
  final String text;
  final int ts;
  final double amount; // örn. kazanılan para
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

/// Kampa giden ordu.
class Expedition {
  final String campId;
  final int stars;
  final int x;
  final int y;
  final Map<String, int> units;
  final int arriveAt; // sunucu saati (ms)
  const Expedition(this.campId, this.stars, this.x, this.y, this.units, this.arriveAt);

  Map<String, dynamic> toJson() =>
      {'campId': campId, 'stars': stars, 'x': x, 'y': y, 'units': units, 'arriveAt': arriveAt};

  factory Expedition.fromJson(Map<String, dynamic> j) => Expedition(
      j['campId'] as String,
      (j['stars'] as num).toInt(),
      (j['x'] as num).toInt(),
      (j['y'] as num).toInt(),
      (j['units'] as Map).map((k, v) => MapEntry(k as String, (v as num).toInt())),
      (j['arriveAt'] as num).toInt());
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
  Map<String, int> units = {for (final u in kUnits) u.id: 0};
  Set<String> knownCamps = {};
  List<Expedition> expeditions = [];
  List<GameReport> reports = [];
  int _lastSeen = 0; // sunucu saati (ms)

  /// Açılışta hesaplanan offline kazanç; ekran gösterince temizlenir.
  OfflineResult? pendingOffline;

  /// Seviye atlanınca ekran bir kez gösterir.
  int? pendingLevelUp;

  // Anlık durum
  double lastGain = 0;
  bool lastCrit = false;
  bool comboActive = false;
  final List<int> _taps = [];

  Timer? _timer;
  final Stopwatch _sw = Stopwatch();
  int _ticks = 0;
  bool _resolving = false;

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

  double get atkPower => _power(units, (u) => u.atk);
  double get defPower => _power(units, (u) => u.def);

  static double _power(Map<String, int> m, double Function(UnitDef) f) {
    var sum = 0.0;
    for (final u in kUnits) {
      sum += (m[u.id] ?? 0) * f(u);
    }
    return sum;
  }

  int unitCount(String id) => units[id] ?? 0;

  // ------------------------------------------------------------ Yükle / kaydet
  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    final raw = _p.getString('save');
    if (raw != null) {
      try {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        money = (j['money'] as num?)?.toDouble() ?? 0;
        xp = (j['xp'] as num?)?.toDouble() ?? 0;
        playerLevel = levelForXp(xp);
        toolStep = ((j['toolStep'] as num?)?.toInt() ?? 1).clamp(1, kToolSteps).toInt();
        final lv = (j['levels'] as List?)?.map((e) => (e as num).toInt()).toList() ?? [];
        for (var i = 0; i < levels.length && i < lv.length; i++) {
          levels[i] = lv[i].clamp(0, kBuildings[i].steps).toInt();
        }
        (j['units'] as Map?)?.forEach((k, v) {
          if (units.containsKey(k)) units[k as String] = (v as num).toInt();
        });
        knownCamps = ((j['knownCamps'] as List?) ?? []).map((e) => e as String).toSet();
        expeditions = ((j['expeditions'] as List?) ?? [])
            .map((e) => Expedition.fromJson(e as Map<String, dynamic>))
            .toList();
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
          'toolStep': toolStep,
          'levels': levels,
          'units': units,
          'knownCamps': knownCamps.toList(),
          'expeditions': expeditions.map((e) => e.toJson()).toList(),
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
    if (expeditions.isNotEmpty && !_resolving) resolveDue();
    notifyListeners();
  }

  void _pruneTaps(int now) {
    _taps.removeWhere((t) => now - t > kComboWindowMs);
  }

  // ------------------------------------------------------------ Tıklama / alışveriş
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

  // ------------------------------------------------------------ Birimler
  int maxBuyable(UnitDef u) => maxAffordableUnits(u, unitCount(u.id), money);

  bool buyUnits(UnitDef u, int k) {
    if (k <= 0) return false;
    final price = unitBatchPrice(u, unitCount(u.id), k);
    if (money < price) return false;
    money -= price;
    units[u.id] = unitCount(u.id) + k;
    save();
    notifyListeners();
    return true;
  }

  // ------------------------------------------------------------ XP / seviye
  void awardXp(double amount) {
    if (amount <= 0) return;
    xp += amount;
    final newLevel = levelForXp(xp);
    if (newLevel > playerLevel) {
      playerLevel = newLevel;
      pendingLevelUp = newLevel;
      _addReport(GameReport('level', 'Seviye $newLevel oldun! Tıklama gelirin arttı.',
          DateTime.now().millisecondsSinceEpoch));
    }
  }

  // ------------------------------------------------------------ Casus (kamp arama)
  /// Casus yeni bir kamp bulmaya çıkar. Sonuç mesajı döner.
  String searchCamp(List<Camp> hidden) {
    if (unitCount('casus') < 1) return 'Casusun yok. Ordu sekmesinden casus eğit.';
    if (hidden.isEmpty) return 'Haritada keşfedilmemiş kamp kalmadı.';
    if (_rng.nextDouble() < kSpyFailChance) {
      units['casus'] = unitCount('casus') - 1;
      save();
      notifyListeners();
      return 'Casusun yakalandı ve kayboldu. Yenisini eğitmen gerekiyor.';
    }
    final c = hidden[_rng.nextInt(hidden.length)];
    knownCamps.add(c.id);
    save();
    notifyListeners();
    return 'Casusun ${c.stars} yıldızlı bir kamp buldu (${c.x},${c.y}).';
  }

  // ------------------------------------------------------------ Kamp saldırısı
  Map<String, int> get _attackUnits =>
      {for (final u in kUnits.where((u) => u.isAttack)) u.id: unitCount(u.id)};

  /// Tüm saldırı birimlerini kampa gönderir. Hata varsa metin döner, başarıda null.
  String? sendAttack(Camp camp) {
    if (!MapService.placed) return 'Harita henüz hazır değil.';
    if (!ServerClock.known) return 'Sunucu saati alınamadı, birazdan tekrar dene.';
    if (expeditions.isNotEmpty) return 'Ordun zaten seferde.';
    final send = Map<String, int>.from(_attackUnits)..removeWhere((k, v) => v <= 0);
    if (send.isEmpty) return 'Saldıracak birimin yok. Ordu sekmesinden asker üret.';
    final dist = MapService.distanceTo(camp.x, camp.y);
    final arrive = ServerClock.nowMs + (travelSeconds(dist) * 1000).round();
    send.forEach((id, n) => units[id] = unitCount(id) - n);
    expeditions.add(Expedition(camp.id, camp.stars, camp.x, camp.y, send, arrive));
    save();
    notifyListeners();
    return null;
  }

  /// Varış süresi gelen seferleri sonuçlandırır.
  Future<void> resolveDue() async {
    if (_resolving || !ServerClock.known) return;
    _resolving = true;
    try {
      for (final e in List<Expedition>.from(expeditions)) {
        if (e.arriveAt <= ServerClock.nowMs) await _resolve(e);
      }
    } catch (_) {
      // Ağ hatası: bir sonraki turda tekrar denenir.
    } finally {
      _resolving = false;
    }
  }

  void _returnUnits(Map<String, int> m) {
    m.forEach((id, n) => units[id] = unitCount(id) + n);
  }

  Future<void> _resolve(Expedition e) async {
    if (MapService.mapId == null) await MapService.ensurePlaced();
    final fetch = await MapService.fetchCamp(e.campId);
    final now = DateTime.now().millisecondsSinceEpoch;
    if (fetch == null) {
      _returnUnits(e.units);
      knownCamps.remove(e.campId);
      expeditions.remove(e);
      _addReport(GameReport('camp', 'Hedef kamp artık yok; ordun geri döndü.', now));
      await save();
      notifyListeners();
      return;
    }

    final atk = _power(e.units, (u) => u.atk);
    final res = resolveBattle(atk, fetch.camp.power, 0.9 + _rng.nextDouble() * 0.2);

    if (res.win && !await MapService.destroyCamp(fetch)) {
      // Başka bir oyuncu kampı bizden önce yok etti.
      _returnUnits(e.units);
      knownCamps.remove(e.campId);
      expeditions.remove(e);
      _addReport(GameReport('camp', 'Kampı başka bir oyuncu senden önce yok etti; ordun geri döndü.', now));
      await save();
      notifyListeners();
      return;
    }

    final survivors = <String, int>{};
    var lostXp = 0.0;
    var lostCount = 0;
    e.units.forEach((id, n) {
      final lost = min(n, (n * res.lossFraction).round());
      survivors[id] = n - lost;
      lostCount += lost;
      lostXp += lost * unitById(id).xp * 0.5; // kaybedilen birim başına yarım XP
    });
    _returnUnits(survivors);
    expeditions.remove(e);

    if (res.win) {
      final loot = money * kCampLootPercent[e.stars]!;
      money += loot;
      final gainedXp = kCampXp[e.stars]! + lostXp;
      awardXp(gainedXp);
      knownCamps.remove(e.campId);
      _addReport(GameReport(
          'camp',
          '${e.stars} yıldızlı kampı yok ettin. $lostCount birim kaybettin. '
          '+${fmtNum(gainedXp)} XP.',
          now,
          amount: loot));
    } else {
      awardXp(lostXp);
      _addReport(GameReport(
          'camp',
          '${e.stars} yıldızlı kampa yenildin. $lostCount birim kaybettin. '
          '+${fmtNum(lostXp)} XP.',
          now));
    }
    await save();
    notifyListeners();
  }
}
