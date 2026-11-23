import 'dart:async';
import 'package:flutter/material.dart';

import '../config.dart';
import '../services/message_service.dart';

/// Gelen kutusu (her [kPollSeconds] saniyede bir yenilenir) ve mesaj gönderme.
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<InboxMessage> _messages = [];
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
      final list = await MessageService.inbox();
      if (!mounted) return;
      setState(() {
        _messages = list;
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

  Future<void> _compose({String to = ''}) async {
    final toCtrl = TextEditingController(text: to);
    final textCtrl = TextEditingController();
    final send = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mesaj gönder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: toCtrl,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'Kime (kullanıcı adı)'),
            ),
            TextField(
              controller: textCtrl,
              maxLength: 500,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Mesaj'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Vazgeç')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Gönder')),
        ],
      ),
    );
    if (send != true) return;
    final err = await MessageService.send(toCtrl.text, textCtrl.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err == null ? 'Gönderildi' : 'Gönderilemedi: $err')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _compose(),
        child: const Icon(Icons.edit),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_error != null)
                  Container(
                    width: double.infinity,
                    color: Colors.red.shade900,
                    padding: const EdgeInsets.all(8),
                    child: Text('Mesajlar alınamadı: $_error'),
                  ),
                Expanded(
                  child: _messages.isEmpty
                      ? const Center(child: Text('Gelen mesaj yok.'))
                      : ListView.builder(
                          itemCount: _messages.length,
                          itemBuilder: (context, i) {
                            final m = _messages[i];
                            return Dismissible(
                              key: ValueKey(m.id),
                              onDismissed: (_) {
                                MessageService.delete(m.id);
                                setState(() => _messages.removeAt(i));
                              },
                              background: Container(color: Colors.red.shade900),
                              child: ListTile(
                                title: Text(m.fromName),
                                subtitle: Text(m.text),
                                onTap: () => _compose(to: m.fromName),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
