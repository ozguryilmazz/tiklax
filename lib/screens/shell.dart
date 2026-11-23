import 'dart:async';
import 'package:flutter/material.dart';

import '../config.dart';
import '../game/game_state.dart';
import '../services/map_service.dart';
import '../services/player_service.dart';
import '../services/session.dart';
import '../utils/format.dart';
import 'game_screen.dart';
import 'map_screen.dart';
import 'market_screen.dart';
import 'settings_screen.dart';
import 'social_screen.dart';

/// Alt menü + oyun zamanlayıcısı + skoru her [kPollSeconds] saniyede bir sunucuya gönderme.
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> with WidgetsBindingObserver {
  int _tab = 0;
  Timer? _timer;
  int _lastUploaded = -1;
  final GameState _gs = GameState.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _gs.addListener(_onGameChanged);
    MapService.ensurePlaced().catchError((_) {}); // haritaya yerleş (gücün yayınlanabilsin)
    _gs.start();
    _upload();
    _timer = Timer.periodic(const Duration(seconds: kPollSeconds), (_) => _upload());
    WidgetsBinding.instance.addPostFrameCallback((_) => _showOffline());
  }

  void _onGameChanged() {
    if (!mounted) return;
    final lvl = _gs.pendingLevelUp;
    if (lvl != null) {
      _gs.pendingLevelUp = null;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Seviye atladın! Yeni seviye: $lvl')));
    }
    final b = _gs.pendingBattle;
    if (b != null) {
      _gs.pendingBattle = null;
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Savaş raporu'),
          content: Text(b.text),
          actions: [
            FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tamam')),
          ],
        ),
      );
    }
  }

  Future<void> _showOffline() async {
    final r = _gs.pendingOffline;
    if (r == null || !mounted) return;
    _gs.pendingOffline = null;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hoş geldin!'),
        content: Text('${fmtDuration(r.seconds)} yoktun.\n'
            'Madenlerin ve pazarın sana ${fmtNum(r.earned)} para kazandırdı.\n\n'
            'İlk 2 saat %100, sonraki 2 saat %50, sonraki 2 saat %25 gelir sayılır; sonrası kazanılmaz.'),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tamam')),
        ],
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _gs.save();
    }
  }

  Future<void> _upload() async {
    // Gücü haritaya yaz (kamp gücü haritadaki oyuncuların ortalamasına göre hesaplanır).
    if (MapService.placed) {
      MapService.publishSelf(_gs.atkPower, _gs.defPower).catchError((_) {});
    }
    final score = _gs.score;
    if (score == _lastUploaded) return;
    final err = await PlayerService.uploadScore(Session.username!, score);
    if (err == null) _lastUploaded = score;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _gs.removeListener(_onGameChanged);
    _gs.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = const [
      GameScreen(),
      MarketScreen(),
      MapScreen(),
      SocialScreen(),
      SettingsScreen(),
    ];
    return Scaffold(
      body: SafeArea(child: pages[_tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.touch_app), label: 'Oyun'),
          NavigationDestination(icon: Icon(Icons.store), label: 'Market'),
          NavigationDestination(icon: Icon(Icons.map), label: 'Harita'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Sosyal'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Ayarlar'),
        ],
      ),
    );
  }
}
