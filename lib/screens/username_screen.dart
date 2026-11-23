import 'package:flutter/material.dart';

import '../services/player_service.dart';
import '../services/session.dart';

class UsernameScreen extends StatefulWidget {
  final VoidCallback onDone;
  const UsernameScreen({super.key, required this.onDone});

  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {
  final _ctrl = TextEditingController();
  bool _busy = false;
  String? _error;

  Future<void> _save() async {
    final name = _ctrl.text.trim().toLowerCase();
    setState(() {
      _busy = true;
      _error = null;
    });
    final r = await PlayerService.claimUsername(name);
    if (!mounted) return;
    if (r.ok) {
      await Session.setUsername(name);
      widget.onDone();
    } else {
      setState(() {
        _busy = false;
        _error = r.error;
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('BasBas',
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              const Text('Bir kullanıcı adı seç', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              TextField(
                controller: _ctrl,
                maxLength: 16,
                autocorrect: false,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'Kullanıcı adı',
                  helperText: 'küçük harf, rakam ve _ (3-16 karakter)',
                  errorText: _error,
                ),
                onSubmitted: (_) => _busy ? null : _save(),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Başla'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
