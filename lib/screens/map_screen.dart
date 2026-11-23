import 'dart:async';
import 'package:flutter/material.dart';

import '../config.dart';
import '../game/balance.dart';
import '../game/game_state.dart';
import '../services/firebase_client.dart';
import '../services/map_service.dart';
import '../utils/format.dart';

/// 16x16 harita: sen, diğer oyuncular ve (casusla bulunmuş) barbar kampları.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Timer? _timer;
  String? _error;
  int _selX = -1;
  int _selY = -1;

  final GameState _gs = GameState.instance;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: kPollSeconds), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      await MapService.ensurePlaced();
      await MapService.poll();
      // Yok olmuş kampları "bilinen" listesinden temizle.
      final ids = MapService.data.camps.map((c) => c.id).toSet();
      _gs.knownCamps.removeWhere((id) => !ids.contains(id));
      if (mounted) setState(() => _error = null);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  List<Camp> get _knownCamps =>
      MapService.data.camps.where((c) => _gs.knownCamps.contains(c.id)).toList();

  List<Camp> get _hiddenCamps =>
      MapService.data.camps.where((c) => !_gs.knownCamps.contains(c.id)).toList();

  @override
  Widget build(BuildContext context) {
    if (!MapService.placed) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _error != null
              ? Text('Harita yüklenemedi:\n$_error', textAlign: TextAlign.center)
              : const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [CircularProgressIndicator(), SizedBox(height: 12), Text('Haritaya yerleşiliyor...')],
                ),
        ),
      );
    }
    return AnimatedBuilder(
      animation: _gs,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (_error != null)
            Container(
              color: Colors.red.shade900,
              padding: const EdgeInsets.all(8),
              child: Text('Harita yenilenemedi: $_error'),
            ),
          Text(
              'Harita ${MapService.mapId}   •   Konumun (${MapService.myX},${MapService.myY})'
              '   •   Oyuncu ${MapService.data.players.length}/$kMapCapacity',
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          AspectRatio(aspectRatio: 1, child: _grid()),
          const SizedBox(height: 8),
          _expeditions(),
          _info(),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: () => _snack(_gs.searchCamp(_hiddenCamps)),
            child: Text('Casusla kamp ara  (casus: ${_gs.unitCount('casus')})'),
          ),
          const SizedBox(height: 4),
          const Text(
            'Kamplar haritada gizlidir; casus bulunca görünür (%20 ihtimalle casus yakalanır ve kaybolur).',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _grid() {
    final players = MapService.data.players;
    final camps = _knownCamps;
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: kMapSize * kMapSize,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: kMapSize),
      itemBuilder: (context, i) {
        final x = i % kMapSize;
        final y = i ~/ kMapSize;
        final me = x == MapService.myX && y == MapService.myY;
        final player = players.where((p) => p.x == x && p.y == y && !me).toList();
        final camp = camps.where((c) => c.x == x && c.y == y).toList();
        Color color = Colors.white10;
        String label = '';
        if (me) {
          color = Colors.blueAccent;
          label = 'S';
        } else if (player.isNotEmpty) {
          color = Colors.green.shade700;
          label = 'O';
        } else if (camp.isNotEmpty) {
          color = Colors.red.shade700;
          label = '${camp.first.stars}★';
        }
        final selected = x == _selX && y == _selY;
        return GestureDetector(
          onTap: () => setState(() {
            _selX = x;
            _selY = y;
          }),
          child: Container(
            margin: const EdgeInsets.all(0.5),
            decoration: BoxDecoration(
              color: color,
              border: selected ? Border.all(color: Colors.white, width: 2) : null,
            ),
            alignment: Alignment.center,
            child: Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Widget _expeditions() {
    if (_gs.expeditions.isEmpty) return const SizedBox.shrink();
    final now = ServerClock.nowMs;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final e in _gs.expeditions)
              Text(e.arriveAt <= now
                  ? '${e.stars} yıldızlı kampa saldırı sonuçlanıyor...'
                  : '${e.stars} yıldızlı kampa sefer: ${((e.arriveAt - now) / 1000).ceil()} sn kaldı'),
          ],
        ),
      ),
    );
  }

  Widget _info() {
    if (_selX < 0) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Text('Bir kareye dokun.', style: TextStyle(color: Colors.white54)),
      );
    }
    final dist = MapService.distanceTo(_selX, _selY);
    final isMe = _selX == MapService.myX && _selY == MapService.myY;
    final players = MapService.data.players.where((p) => p.x == _selX && p.y == _selY).toList();
    final camps = _knownCamps.where((c) => c.x == _selX && c.y == _selY).toList();

    Widget body;
    if (isMe) {
      body = Text('Senin üssün (${_selX},${_selY}).\nSaldırı gücün: ${fmtNum(_gs.atkPower)}   '
          'Savunma gücün: ${fmtNum(_gs.defPower)}');
    } else if (players.isNotEmpty) {
      final p = players.first;
      body = Text('${p.name}   (${p.x},${p.y})\nMesafe: ${dist.toStringAsFixed(1)} kare\n'
          'Saldırı ${fmtNum(p.atk)}   Savunma ${fmtNum(p.def)}\n'
          'Oyuncuya saldırı bir sonraki aşamada eklenecek.');
    } else if (camps.isNotEmpty) {
      final c = camps.first;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${c.stars} yıldızlı barbar kampı   (${c.x},${c.y})\n'
              'Kamp gücü: ${fmtNum(c.power)}   •   Senin saldırı gücün: ${fmtNum(_gs.atkPower)}\n'
              'Mesafe: ${dist.toStringAsFixed(1)} kare   •   Yolculuk: ~${travelSeconds(dist).round()} sn\n'
              'Ödül: bakiyenin %${(kCampLootPercent[c.stars]! * 100).round()}\'i + ${kCampXp[c.stars]!.round()} XP'),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () {
              final err = _gs.sendAttack(c);
              _snack(err ?? 'Ordun yola çıktı!');
            },
            child: const Text('Tüm saldırı birimleriyle saldır'),
          ),
        ],
      );
    } else {
      body = Text('Boş alan (${_selX},${_selY}).   Mesafe: ${dist.toStringAsFixed(1)} kare');
    }
    return Card(
      child: Padding(padding: const EdgeInsets.all(12), child: body),
    );
  }
}
