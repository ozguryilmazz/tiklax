import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/session.dart';
import '../services/update_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _checking = false;
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((i) {
      if (mounted) setState(() => _version = '${i.version} (build ${i.buildNumber})');
    });
  }

  Future<void> _check() async {
    setState(() => _checking = true);
    final r = await UpdateService.check();
    if (!mounted) return;
    setState(() => _checking = false);
    if (r.error != null) {
      _snack('Kontrol edilemedi: ${r.error}');
    } else if (!r.updateAvailable) {
      _snack('Oyun güncel.');
    } else {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Yeni sürüm: build ${r.latestBuild}'),
          content: Text(r.notes?.trim().isNotEmpty == true
              ? r.notes!
              : 'Yeni sürümü indirmek ister misin?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Sonra')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('İndir')),
          ],
        ),
      );
      if (go == true) {
        await launchUrl(Uri.parse(r.downloadUrl!),
            mode: LaunchMode.externalApplication);
      }
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text('Kullanıcı adı'),
          subtitle: Text(Session.username ?? ''),
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('Sürüm'),
          subtitle: Text(_version),
        ),
        ListTile(
          leading: _checking
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.system_update),
          title: const Text('Güncellemeyi kontrol et'),
          onTap: _checking ? null : _check,
        ),
      ],
    );
  }
}
