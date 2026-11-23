import 'package:flutter/material.dart';

import '../game/balance.dart';
import '../game/game_state.dart';
import '../utils/format.dart';

/// Eşya (çekiç/kazma) ve bina (maden, pazar) yükseltmeleri.
class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});

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
            const SizedBox(height: 12),
            _toolCard(context, gs),
            const SizedBox(height: 12),
            const Text('Binalar (sabit gelir)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            for (var b = 0; b < kBuildings.length; b++) _buildingCard(context, gs, b),
          ],
        );
      },
    );
  }

  Widget _toolCard(BuildContext context, GameState gs) {
    final next = gs.toolStep + 1;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Eşya (tıklama geliri)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Şu an: ${toolName(gs.toolStep)} ${toolSubStep(gs.toolStep)}/$kToolSubSteps'
                '  (basamak ${gs.toolStep}/$kToolSteps)'),
            Text('${fmtNum(toolTap(gs.toolStep))} / tık'),
            const SizedBox(height: 8),
            if (gs.toolMaxed)
              const Text('En yüksek basamağa ulaştın.')
            else ...[
              Text('Sonraki: ${toolName(next)} ${toolSubStep(next)}/$kToolSubSteps'
                  ' → ${fmtNum(toolTap(next))} / tık'),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: gs.money >= gs.nextToolPrice ? () => gs.buyTool() : null,
                child: Text('Yükselt  (${fmtNum(gs.nextToolPrice)})'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildingCard(BuildContext context, GameState gs, int b) {
    final def = kBuildings[b];
    final level = gs.levels[b];
    final open = gs.buildingOpen(b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${def.name}   $level/${def.steps}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            if (!open)
              Text('Kilitli: önce ${kBuildings[b - 1].name} ${kBuildings[b - 1].steps}. kademeye ulaşmalı.',
                  style: const TextStyle(color: Colors.white54))
            else ...[
              Text(level == 0
                  ? 'Henüz açılmadı.'
                  : 'Gelir: ${fmtNum(buildingIncome(b, level))} / sn'),
              if (!gs.buildingMaxed(b)) ...[
                Text('Sonraki: ${fmtNum(buildingIncome(b, level + 1))} / sn'),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: gs.money >= gs.nextBuildingPrice(b) ? () => gs.buyBuilding(b) : null,
                  child: Text('${level == 0 ? 'Aç' : 'Yükselt'}  (${fmtNum(gs.nextBuildingPrice(b))})'),
                ),
              ] else
                const Text('En yüksek kademe.'),
            ],
          ],
        ),
      ),
    );
  }
}
