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

/// The daily step goal from the panel, or 10,000 until one is set.
final dailyStepGoalProvider = Provider<int>((ref) {
  final v = ref.watch(appSettingsProvider).valueOrNull?[AppSettingKeys.dailyStepGoal];
  final n = v is num ? v.toInt() : int.tryParse('${v ?? ''}');
  return n != null && n > 0 ? n : 10000;
});

/// The keys the panel edits.
abstract final class AppSettingKeys {
  static const androidStoreUrl = 'store_url_android';
  static const iosStoreUrl = 'store_url_ios';
  static const jobApplicationsKeepDays = 'job_applications_keep_days';

  /// The day's step goal, the one the Steps screen's ring fills against.
  /// 0, or never set, 10,000.
  static const dailyStepGoal = 'daily_step_goal';

  /// Whether residents' replies to reviews wait for approval (00063). Off,
  /// or never set, they appear at once.
  static const repliesNeedApproval = 'replies_need_approval';

  /// How many open reports hide a review or a reply until someone looks
  /// (00064). 0, or never set, nothing hides itself.
  static const reportsAutoHideAt = 'reports_auto_hide_at';

  /// How many days an approved listing stays up (00066). 0, or never set,
  /// it never expires.
  static const listingsExpireDays = 'listings_expire_days';

  /// The latest build of each platform: an older one asks for the update.
  /// 0, or never set, no prompt. See core/update/force_update.dart.
  static const minBuildAndroid = 'min_build_android';
  static const minBuildIos = 'min_build_ios';

  /// Whether that update is required (the app does not open until it is
  /// done) or may be put off with "Later". Off, or never set: "Later".
  static const forceUpdateAndroid = 'force_update_android';
  static const forceUpdateIos = 'force_update_ios';
}

/// A store link, only when the panel has given an https address.
String? storeUrl(Map<String, dynamic> settings, String key) {
  final v = settings[key];
  return v is String && v.trim().startsWith('https://') ? v.trim() : null;
}
