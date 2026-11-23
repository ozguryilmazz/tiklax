import 'dart:math';

/// Oyunun tüm sayısal kuralları burada. Dengeyi değiştirmek için sadece bu dosyaya bak.
/// (GAME_DESIGN.md içindeki formüllerle aynıdır.)

// ---------------------------------------------------------------- Genel
const double kCritChance = 0.05; // %5
const double kCritMultiplier = 5.0;
const double kComboMultiplier = 1.15;
const int kComboTaps = 20; // bu kadar tıklama...
const int kComboWindowMs = 5000; // ...bu süre içinde yapılırsa kombo

/// Oyuncu seviyesinin tıklama gücü (şimdilik seviye hep 1).
double levelPower(int level) => pow(level, 1.6).toDouble();

// ---------------------------------------------------------------- Çekiç / kazma
const int kToolSteps = 160; // 8 malzeme x 10 kademe x (çekiç + kazma)
const int kToolSubSteps = 10;
const List<String> kToolMaterials = [
  'Tahta saplı taş',
  'Taş',
  'Bakır',
  'Bronz',
  'Demir',
  'Gümüş',
  'Altın',
  'Elmas',
];

/// s: 1..160. 1..80 çekiç, 81..160 kazma.
String toolName(int s) {
  final k = (s - 1) ~/ kToolSubSteps;
  final kind = k >= 8 ? 'kazma' : 'çekiç';
  return '${kToolMaterials[k % 8]} $kind';
}

/// Malzeme içindeki kademe (1..10).
int toolSubStep(int s) => (s - 1) % kToolSubSteps + 1;

/// Basamak s'deki tıklama başına gelir: 3,5^malzeme x (1 + 0,25 x kademe).
double toolTap(int s) {
  final k = (s - 1) ~/ kToolSubSteps;
  final j = (s - 1) % kToolSubSteps;
  return pow(3.5, k) * (1 + 0.25 * j);
}

/// s. basamağa yükseltmenin fiyatı (s >= 2).
double toolPrice(int s) {
  if (s <= 1) return 0;
  final payback = 20 * pow(1.035, s - 1); // tık cinsinden hedef geri ödeme
  final gain = toolTap(s) - toolTap(s - 1);
  return (payback * gain).ceilToDouble();
}

// ---------------------------------------------------------------- Binalar
class BuildingDef {
  final String name;
  final int steps;
  const BuildingDef(this.name, this.steps);
}

const List<BuildingDef> kBuildings = [
  BuildingDef('Taş madeni', 10),
  BuildingDef('Altın madeni', 10),
  BuildingDef('Zümrüt madeni', 10),
  BuildingDef('Elmas madeni', 10),
  BuildingDef('Tüccar pazarı', 40),
];

const int kMerchantIndex = 4;

/// Madenler sırayla açılır; tüccar pazarı bağımsızdır.
bool buildingUnlocked(int b, List<int> levels) {
  if (b == 0 || b == kMerchantIndex) return true;
  return levels[b - 1] >= kBuildings[b - 1].steps;
}

/// Binanın genel sırası (1..40): madenlerde zincir boyunca, pazarda kendi kademesi.
int _globalIndex(int b, int n) => b == kMerchantIndex ? n : b * 10 + n;

/// Binanın saniyelik geliri: aynı aşamadaki tıklama gelirinin 2 katı.
double buildingIncome(int b, int n) {
  if (n <= 0) return 0;
  final stage = min(4 * _globalIndex(b, n), kToolSteps);
  return 2 * toolTap(stage);
}

/// b binasının n. kademesinin (n=1: açılış) fiyatı.
double buildingPrice(int b, int n) {
  final g = _globalIndex(b, n);
  final paybackSec = 60 * pow(20, (g - 1) / 39); // ~1 dk ... ~20 dk
  final gain = buildingIncome(b, n) - buildingIncome(b, n - 1);
  return (paybackSec * gain).ceilToDouble();
}

// ---------------------------------------------------------------- Offline gelir
const double kOfflineMinSeconds = 60;

/// İlk 2 saat %100, sonraki 2 saat %50, sonraki 2 saat %25, sonrası %0.
/// Dönen değer "tam gelir saniyesi" cinsindendir.
double offlineEffectiveSeconds(double elapsed) {
  const h2 = 7200.0;
  final a = min(elapsed, h2);
  final b = (min(elapsed, 2 * h2) - h2).clamp(0.0, h2);
  final c = (min(elapsed, 3 * h2) - 2 * h2).clamp(0.0, h2);
  return a * 1.0 + b * 0.5 + c * 0.25;
}

// ---------------------------------------------------------------- Birimler
class UnitDef {
  final String id;
  final String name;
  final double cost;
  final double atk; // saldırı gücü
  final double def; // savunma gücü
  const UnitDef(this.id, this.name, this.cost, this.atk, this.def);

  bool get isAttack => atk > 0;
  bool get isDefense => def > 0;
  double get xp => cost / 10; // savaşta yok edilen/kaybedilen birim başına XP
}

const List<UnitDef> kUnits = [
  // Saldırı
  UnitDef('asker', 'Asker', 100, 10, 0),
  UnitDef('topcu', 'Topçu', 500, 55, 0),
  UnitDef('tank', 'Tank', 2500, 300, 0),
  UnitDef('ucak', 'Uçak', 15000, 2100, 0),
  UnitDef('siha', 'SİHA', 8000, 1040, 0),
  // Savunma
  UnitDef('nobetci', 'Nöbetçi', 100, 0, 10),
  UnitDef('tanksavar', 'Tank savar', 1000, 0, 100),
  UnitDef('ucaksavar', 'Uçak savar', 2000, 0, 200),
  // Casus
  UnitDef('casus', 'Casus', 300, 0, 0),
];

/// Bir birimden ne kadar çok varsa yenisi o kadar pahalıdır (sınır yok, ekonomi dengesi için).
const double kUnitPriceGrowth = 1.005;

UnitDef unitById(String id) => kUnits.firstWhere((u) => u.id == id);

/// k adet birimi, elde [owned] adet varken almanın toplam fiyatı.
double unitBatchPrice(UnitDef u, int owned, int k) {
  if (k <= 0) return 0;
  final g = kUnitPriceGrowth;
  return (u.cost * pow(g, owned) * (pow(g, k) - 1) / (g - 1)).ceilToDouble();
}

/// Eldeki parayla en fazla kaç adet alınabilir.
int maxAffordableUnits(UnitDef u, int owned, double money) {
  if (money < unitBatchPrice(u, owned, 1)) return 0;
  final g = kUnitPriceGrowth;
  final first = u.cost * pow(g, owned);
  var k = (log(1 + money * (g - 1) / first) / log(g)).floor();
  while (k > 0 && unitBatchPrice(u, owned, k) > money) {
    k--;
  }
  return max(0, k);
}

// ---------------------------------------------------------------- Seviye / XP
const int kMaxLevel = 50;

/// L seviyesinden L+1'e geçmek için gereken XP.
double xpToNextLevel(int level) => (100 * pow(level, 1.8)).roundToDouble();

/// L seviyesine ulaşmak için gereken toplam XP.
double xpTotalForLevel(int level) {
  var sum = 0.0;
  for (var l = 1; l < level; l++) {
    sum += xpToNextLevel(l);
  }
  return sum;
}

int levelForXp(double xp) {
  var level = 1;
  var rest = xp;
  while (level < kMaxLevel && rest >= xpToNextLevel(level)) {
    rest -= xpToNextLevel(level);
    level++;
  }
  return level;
}

// ---------------------------------------------------------------- Harita ve kamplar
const int kMapSize = 16;
const int kMapCapacity = 12; // bir haritadaki en fazla oyuncu
const double kMinPlayerDistance = 5; // oyuncular arası en az mesafe (kare)

const Map<int, int> kCampTargets = {1: 4, 2: 3, 3: 2}; // aynı anda kaç kamp
const Map<int, double> kCampPowerFactor = {1: 0.3, 2: 0.6, 3: 1.0};
const Map<int, double> kCampLootPercent = {1: 0.10, 2: 0.20, 3: 0.30};
const Map<int, double> kCampXp = {1: 5, 2: 10, 3: 15};
const double kCampMinPower = 100;
const int kCampRespawnMs = 5 * 60 * 1000; // yok edilince 5 dk sonra yenisi

const double kSpyFailChance = 0.2; // casus yakalanma ihtimali (kamp ararken)

/// Yolculuk süresi (saniye): mesafe (kare) başına 2 sn + 5 sn.
double travelSeconds(double distance) => 5 + distance * 2;

class BattleResult {
  final bool win;
  final double lossFraction; // gönderilen birimlerin kaybettiği oran
  const BattleResult(this.win, this.lossFraction);
}

/// Saldıran güç [atk] ile savunan güç [defPower] (luck: ~0,9–1,1 şans çarpanı).
BattleResult resolveBattle(double atk, double defPower, double luck) {
  final a = atk * luck;
  if (a > defPower) {
    final r = a / defPower;
    return BattleResult(true, (0.3 / r).clamp(0.0, 0.3).toDouble());
  }
  final r = a / max(defPower, 1);
  return BattleResult(false, (0.5 / max(r, 0.0001)).clamp(0.5, 0.9).toDouble());
}
