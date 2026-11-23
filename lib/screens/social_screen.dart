import 'package:flutter/material.dart';

import 'leaderboard_screen.dart';
import 'messages_screen.dart';

/// Skorlar ve Mesajlar tek sekmede.
class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(tabs: [Tab(text: 'Skorlar'), Tab(text: 'Mesajlar')]),
          Expanded(child: TabBarView(children: [LeaderboardScreen(), MessagesScreen()])),
        ],
      ),
    );
  }
}
