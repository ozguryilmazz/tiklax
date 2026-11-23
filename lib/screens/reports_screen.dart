import 'package:flutter/material.dart';

import '../game/game_state.dart';
import '../utils/format.dart';

/// Raporlar: offline kazanç (ileride saldırı ve casusluk raporları da burada).
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reports = GameState.instance.reports;
    return Scaffold(
      appBar: AppBar(title: const Text('Raporlar')),
      body: reports.isEmpty
          ? const Center(child: Text('Henüz rapor yok.'))
          : ListView.builder(
              itemCount: reports.length,
              itemBuilder: (context, i) {
                final r = reports[i];
                final d = DateTime.fromMillisecondsSinceEpoch(r.ts);
                final when =
                    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')} '
                    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
                return ListTile(
                  leading: const Icon(Icons.nights_stay),
                  title: Text(r.type == 'offline' ? 'Offline kazanç' : r.type),
                  subtitle: Text('$when\n${r.text}'),
                  isThreeLine: true,
                  trailing: r.amount > 0
                      ? Text('+${fmtNum(r.amount)}',
                          style: const TextStyle(fontWeight: FontWeight.bold))
                      : null,
                );
              },
            ),
    );
  }
}
