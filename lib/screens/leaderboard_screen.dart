import 'dart:async';
import 'package:flutter/material.dart';

import '../config.dart';
import '../services/player_service.dart';
import '../services/session.dart';

/// Skor tablosu: açıkken her [kPollSeconds] saniyede bir otomatik yenilenir.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<PlayerEntry> _entries = [];
  String? _error;
  bool _loading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: kPollSeconds), (_) => _load());
  }

  Future<void> _load() async {
    try {
      final list = await PlayerService.topPlayers();
      if (!mounted) return;
      setState(() {
        _entries = list;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Column(
      children: [
        if (_error != null)
          Container(
            width: double.infinity,
            color: Colors.red.shade900,
            padding: const EdgeInsets.all(8),
            child: Text('Skorlar alınamadı: $_error'),
          ),
        Expanded(
          child: _entries.isEmpty
              ? const Center(child: Text('Henüz skor yok.'))
              : ListView.builder(
                  itemCount: _entries.length,
                  itemBuilder: (context, i) {
                    final e = _entries[i];
                    final me = e.name == Session.username;
                    return ListTile(
                      leading: Text('${i + 1}',
                          style: const TextStyle(fontSize: 18)),
                      title: Text(e.name,
                          style: TextStyle(
                              fontWeight: me ? FontWeight.bold : FontWeight.normal)),
                      trailing: Text('${e.score}',
                          style: const TextStyle(fontSize: 18)),
                      tileColor: me ? Colors.white10 : null,
                    );
                  },
                ),
        ),
      ],
    );
  }
}
