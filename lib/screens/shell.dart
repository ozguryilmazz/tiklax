import 'dart:async';
import 'package:flutter/material.dart';

import '../config.dart';
import '../game/game_state.dart';
import '../services/player_service.dart';
import '../services/session.dart';
import '../utils/format.dart';
import 'game_screen.dart';
import 'leaderboard_screen.dart';
import 'market_screen.dart';
import 'messages_screen.dart';
import 'settings_screen.dart';

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
    _gs.start();
    _upload();
    _timer = Timer.periodic(const Duration(seconds: kPollSeconds), (_) => _upload());
    WidgetsBinding.instance.addPostFrameCallback((_) => _showOffline());
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
    final score = _gs.score;
    if (score == _lastUploaded) return;
    final err = await PlayerService.uploadScore(Session.username!, score);
    if (err == null) _lastUploaded = score;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _gs.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = const [
      GameScreen(),
      MarketScreen(),
      LeaderboardScreen(),
      MessagesScreen(),
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
          NavigationDestination(icon: Icon(Icons.leaderboard), label: 'Skorlar'),
          NavigationDestination(icon: Icon(Icons.mail), label: 'Mesajlar'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Ayarlar'),
        ],
      ),
    );
  }
}
