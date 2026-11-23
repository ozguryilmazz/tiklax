import 'package:flutter/material.dart';

import '../services/session.dart';

/// GEÇİCİ oyun ekranı: sadece skor altyapısını denemek için bir tıklama sayacı.
/// Asıl oyun içeriği konuşulduktan sonra bu dosya değişecek.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late int _score = Session.score;

  void _tap() {
    setState(() => _score++);
    Session.setScore(_score);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${Session.username}', style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          Text('$_score',
              style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _tap,
            child: Container(
              width: 200,
              height: 200,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Color(0xFF7C4DFF)),
              alignment: Alignment.center,
              child: const Text('BAS',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
