import 'package:flutter/material.dart';

import 'config.dart';
import 'screens/shell.dart';
import 'screens/username_screen.dart';
import 'services/firebase_client.dart';
import 'services/session.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BasBasApp());
}

class BasBasApp extends StatelessWidget {
  const BasBasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BasBas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF7C4DFF),
        useMaterial3: true,
      ),
      home: const Boot(),
    );
  }
}

/// Açılışta: yerel veriyi yükle, Firebase'e anonim giriş yap, kullanıcı adı yoksa iste.
class Boot extends StatefulWidget {
  const Boot({super.key});

  @override
  State<Boot> createState() => _BootState();
}

class _BootState extends State<Boot> {
  late Future<void> _init;

  @override
  void initState() {
    super.initState();
    _init = _start();
  }

  Future<void> _start() async {
    await Session.init();
    if (!isConfigured) {
      throw Exception(
          'Firebase ayarlanmamış. lib/config.dart içine kDbUrl ve kApiKey yaz.');
    }
    await FirebaseClient.init();
  }

  void _retry() => setState(() => _init = _start());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _init,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Bağlanılamadı\n\n${snap.error}',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _retry, child: const Text('Tekrar dene')),
                  ],
                ),
              ),
            ),
          );
        }
        if (Session.username == null) {
          return UsernameScreen(onDone: () => setState(() {}));
        }
        return const Shell();
      },
    );
  }
}
