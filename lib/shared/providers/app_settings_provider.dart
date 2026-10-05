import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_config.dart';

/// `app_settings`, key to value: readable by everyone, written from the
/// panel's Settings (00014). Holds the store links the website offers people
/// without the app, and how long a closed job's applications are kept.
final appSettingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final rows = await SupabaseConfig.client.from('app_settings').select('key, value');
  return {
    for (final r in List<Map<String, dynamic>>.from(rows)) r['key'] as String: r['value'],
  };
});

/// The keys the panel edits.
abstract final class AppSettingKeys {
  static const androidStoreUrl = 'store_url_android';
  static const iosStoreUrl = 'store_url_ios';
  static const jobApplicationsKeepDays = 'job_applications_keep_days';
}

/// A store link, only when the panel has given an https address.
String? storeUrl(Map<String, dynamic> settings, String key) {
  final v = settings[key];
  return v is String && v.trim().startsWith('https://') ? v.trim() : null;
}
