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
