import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppUpdate {
  final String version;
  final String url;
  final String? releaseNotes;
  final bool isMandatory;

  AppUpdate({
    required this.version,
    required this.url,
    this.releaseNotes,
    this.isMandatory = false,
  });
}

class UpdateService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Checks if a newer version is available in the database.
  /// Returns [AppUpdate] if update is needed, null otherwise.
  static Future<AppUpdate?> checkForUpdate() async {
    try {
      // 1. Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

      // 2. Get latest version from Supabase
      final response = await _supabase
          .from('app_versions')
          .select()
          .order('version_code', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      final latestBuildNumber = response['version_code'] as int;

      // 3. Compare
      if (latestBuildNumber > currentBuildNumber) {
        return AppUpdate(
          version: response['version_name'] ?? 'New Version',
          url: response['download_url'] ?? '',
          releaseNotes: response['release_notes'],
          isMandatory: response['is_mandatory'] ?? false,
        );
      }

      return null;
    } catch (e) {
      // Fail silently or log error
      debugPrint('Update check failed: $e');
      return null;
    }
  }
}
