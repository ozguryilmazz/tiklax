import 'package:flutter/material.dart';

import '../game/balance.dart';
import '../game/game_state.dart';
import '../services/session.dart';
import '../utils/format.dart';

/// Ana oyun ekranı: para, gelir ve tıklama düğmesi.
class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = GameState.instance;
    return AnimatedBuilder(
      animation: gs,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text('${Session.username}   •   Puan ${fmtNum(gs.score.toDouble())}',
                  style: const TextStyle(fontSize: 14, color: Colors.white70)),
              const SizedBox(height: 12),
              Text(fmtNum(gs.money),
                  style: const TextStyle(fontSize: 52, fontWeight: FontWeight.bold)),
              const Text('para', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Text('+${fmtNum(gs.incomePerSec)} / sn', style: const TextStyle(fontSize: 18)),
              Text('${fmtNum(gs.tapIncome)} / tık', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 4),
              Text(
                '${toolName(gs.toolStep)} ${toolSubStep(gs.toolStep)}/$kToolSubSteps',
                style: const TextStyle(color: Colors.white70),
              ),
              const Spacer(),
              SizedBox(
                height: 56,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (gs.lastGain > 0)
                      Text(
                        '${gs.lastCrit ? 'KRİTİK! ' : ''}+${fmtNum(gs.lastGain)}',
                        style: TextStyle(
                          fontSize: gs.lastCrit ? 26 : 20,
                          fontWeight: FontWeight.bold,
                          color: gs.lastCrit ? Colors.amber : Colors.white,
                        ),
                      ),
                    if (gs.comboActive)
                      Text('KOMBO ×${kComboMultiplier.toString().replaceAll('.', ',')}',
                          style: const TextStyle(
                              color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTapDown: (_) => gs.tap(),
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF7C4DFF),
                    boxShadow: [
                      BoxShadow(
                        color: gs.comboActive ? Colors.orangeAccent : Colors.black54,
                        blurRadius: gs.comboActive ? 24 : 8,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text('BAS',
                      style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                ),
              ),
              const Spacer(),
            ],
          ),
        );
      },
    );
  }
}
