import 'dart:async';
import 'package:flutter/material.dart';

import '../config.dart';
import '../services/player_service.dart';
import '../services/session.dart';
import 'game_screen.dart';
import 'leaderboard_screen.dart';
import 'messages_screen.dart';
import 'settings_screen.dart';

/// Alt menü + skoru her [kPollSeconds] saniyede bir sunucuya gönderen zamanlayıcı.
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;
  Timer? _timer;
  int _lastUploaded = -1;

  @override
  void initState() {
    super.initState();
    _upload();
    _timer = Timer.periodic(const Duration(seconds: kPollSeconds), (_) => _upload());
  }

  Future<void> _upload() async {
    final score = Session.score;
    if (score == _lastUploaded) return;
    final err = await PlayerService.uploadScore(Session.username!, score);
    if (err == null) _lastUploaded = score;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = const [
      GameScreen(),
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
          NavigationDestination(icon: Icon(Icons.leaderboard), label: 'Skorlar'),
          NavigationDestination(icon: Icon(Icons.mail), label: 'Mesajlar'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Ayarlar'),
        ],
      ),
    );
  }
}
