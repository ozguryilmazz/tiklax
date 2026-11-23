/// 1234 -> "1,23K", 1500000 -> "1,50M" gibi kısa gösterim.
String fmtNum(double v) {
  if (v.isNaN || v.isInfinite) return '0';
  const units = ['', 'K', 'M', 'B', 'T', 'Qa', 'Qi', 'Sx'];
  var x = v.abs();
  var i = 0;
  while (x >= 1000 && i < units.length - 1) {
    x /= 1000;
    i++;
  }
  final String s;
  if (i == 0 && x == x.roundToDouble()) {
    s = x.toStringAsFixed(0);
  } else if (x < 10) {
    s = x.toStringAsFixed(2);
  } else if (x < 100) {
    s = x.toStringAsFixed(1);
  } else {
    s = x.toStringAsFixed(0);
  }
  return '${v < 0 ? '-' : ''}${s.replaceAll('.', ',')}${units[i]}';
}

/// Saniyeyi "2 sa 15 dk" biçiminde yazar.
String fmtDuration(double seconds) {
  final total = seconds.round();
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  if (h > 0) return m > 0 ? '$h sa $m dk' : '$h sa';
  if (m > 0) return '$m dk';
  return '$total sn';
}
