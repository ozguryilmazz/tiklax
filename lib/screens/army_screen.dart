import 'package:flutter/material.dart';

import '../game/balance.dart';
import '../game/game_state.dart';
import '../utils/format.dart';

/// Birim üretimi (anında, sınırsız). Her birim için x1, x10 ve "maks" düğmesi.
class ArmyScreen extends StatelessWidget {
  const ArmyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = GameState.instance;
    return AnimatedBuilder(
      animation: gs,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Center(
              child: Text('Para: ${fmtNum(gs.money)}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                  'Saldırı gücü: ${fmtNum(gs.atkPower)}   •   Savunma gücü: ${fmtNum(gs.defPower)}',
                  style: const TextStyle(color: Colors.white70)),
            ),
            const SizedBox(height: 12),
            _section('Saldırı birimleri'),
            for (final u in kUnits.where((u) => u.isAttack)) _unitCard(gs, u),
            _section('Savunma birimleri'),
            for (final u in kUnits.where((u) => u.isDefense)) _unitCard(gs, u),
            _section('Casus'),
            for (final u in kUnits.where((u) => !u.isAttack && !u.isDefense)) _unitCard(gs, u),
            const SizedBox(height: 8),
            const Text(
              'Elindeki birim arttıkça yenisi biraz daha pahalı olur (her birimde %0,5).',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        );
      },
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );

  Widget _unitCard(GameState gs, UnitDef u) {
    final owned = gs.unitCount(u.id);
    final stat = u.isAttack
        ? 'Saldırı ${fmtNum(u.atk)}'
        : u.isDefense
            ? 'Savunma ${fmtNum(u.def)}'
            : 'Kamp arar';
    final maxBuy = gs.maxBuyable(u);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${u.name}   x${fmtNum(owned.toDouble())}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('$stat   •   1 adet: ${fmtNum(unitBatchPrice(u, owned, 1))}'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilledButton(
                  onPressed: gs.money >= unitBatchPrice(u, owned, 1) ? () => gs.buyUnits(u, 1) : null,
                  child: const Text('+1'),
                ),
                FilledButton(
                  onPressed: gs.money >= unitBatchPrice(u, owned, 10) ? () => gs.buyUnits(u, 10) : null,
                  child: Text('+10 (${fmtNum(unitBatchPrice(u, owned, 10))})'),
                ),
                FilledButton(
                  onPressed: maxBuy > 0 ? () => gs.buyUnits(u, maxBuy) : null,
                  child: Text('Maks ($maxBuy)'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
