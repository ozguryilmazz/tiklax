import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../config.dart';

class UpdateResult {
  final bool updateAvailable;
  final int? latestBuild;
  final String? downloadUrl;
  final String? notes;
  final String? error;
  const UpdateResult(
      {this.updateAvailable = false,
      this.latestBuild,
      this.downloadUrl,
      this.notes,
      this.error});
}

/// GitHub Releases'teki en son sürümü kontrol eder.
/// Release etiketi "build-<numara>" biçimindedir; numara, APK'nın build numarasıdır.
class UpdateService {
  static Future<UpdateResult> check() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final current = int.tryParse(info.buildNumber) ?? 0;
      final r = await http
          .get(
            Uri.parse('https://api.github.com/repos/$kGithubRepo/releases/latest'),
            headers: {'Accept': 'application/vnd.github+json'},
          )
          .timeout(const Duration(seconds: 10));
      if (r.statusCode == 404) return const UpdateResult(); // henüz release yok
      if (r.statusCode != 200) {
        return UpdateResult(error: 'HTTP ${r.statusCode}: ${r.body}');
      }
      final d = jsonDecode(r.body) as Map<String, dynamic>;
      final tag = (d['tag_name'] as String?) ?? '';
      final latest = int.tryParse(tag.replaceFirst('build-', '')) ?? 0;
      String? url;
      for (final a in (d['assets'] as List? ?? [])) {
        final name = (a['name'] as String?) ?? '';
        if (name.endsWith('.apk')) {
          url = a['browser_download_url'] as String?;
          break;
        }
      }
      if (latest > current && url != null) {
        return UpdateResult(
            updateAvailable: true,
            latestBuild: latest,
            downloadUrl: url,
            notes: d['body'] as String?);
      }
      return const UpdateResult();
    } catch (e) {
      return UpdateResult(error: e.toString());
    }
  }
}
