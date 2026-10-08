import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../shared/providers/app_settings_provider.dart';
import '../supabase/supabase_config.dart';
import '../theme/app_fonts.dart';

/// Asks an app that is out of date to be updated — required, or with "Later".
///
/// The client (8 Oct): update the app from the panel, forced or not. Settings
/// in the panel holds the latest build of each platform (`min_build_android`,
/// `min_build_ios` in `app_settings`) — the build number, the part after "+"
/// in pubspec's version — and whether updating to it is required
/// (`force_update_android`, `force_update_ios`). An older build shows a page
/// asking for the update, with a button to the store link the panel holds.
/// Required, that page is all the app shows; otherwise "Later" closes it until
/// the app is next started. 0 or empty means no update is asked for.
///
/// Asked at start and on every return from the background, so a change in
/// the panel applies the next time the app is opened — and an update made
/// required after "Later" still stops the app. Never on the website, which is
/// always the latest. When the answer cannot be had — no connection, no table
/// — the app is let through: a check that fails must not lock people out.
class ForceUpdateGate extends StatefulWidget {
  final Widget child;
  const ForceUpdateGate({super.key, required this.child});

  @override
  State<ForceUpdateGate> createState() => _ForceUpdateGateState();
}

class _ForceUpdateGateState extends State<ForceUpdateGate> {
  AppLifecycleListener? _lifecycle;

  /// The store to send to, once this build is found out of date; null while
  /// it is current. An empty string: out of date, but no store link.
  String? _blockedStore;

  /// Whether the update is required; otherwise "Later" may close the page.
  bool _required = false;

  /// "Later" was pressed in this run of the app.
  bool _later = false;

  bool get _android => defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) return;
    _check();
    _lifecycle = AppLifecycleListener(onResume: _check);
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    try {
      final build =
          int.tryParse((await PackageInfo.fromPlatform()).buildNumber) ?? 0;
      final minKey = _android
          ? AppSettingKeys.minBuildAndroid
          : AppSettingKeys.minBuildIos;
      final storeKey = _android
          ? AppSettingKeys.androidStoreUrl
          : AppSettingKeys.iosStoreUrl;
      final forceKey = _android
          ? AppSettingKeys.forceUpdateAndroid
          : AppSettingKeys.forceUpdateIos;
      final rows = await SupabaseConfig.client
          .from('app_settings')
          .select('key, value')
          .inFilter('key', [minKey, storeKey, forceKey]);
      final settings = {
        for (final r in List<Map<String, dynamic>>.from(rows))
          r['key'] as String: r['value'],
      };
      final minimum = switch (settings[minKey]) {
        final num n => n.toInt(),
        final String s => int.tryParse(s.trim()) ?? 0,
        _ => 0,
      };
      final blocked = minimum > 0 && build > 0 && build < minimum;
      if (!mounted) return;
      setState(() {
        _blockedStore = blocked ? (storeUrl(settings, storeKey) ?? '') : null;
        _required = settings[forceKey] == true;
      });
    } catch (_) {
      // Left as it was: a failed check neither blocks nor unblocks.
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = _blockedStore;
    if (store == null || (_later && !_required)) return widget.child;
    return _UpdateRequired(
      store: store.isEmpty ? null : store,
      android: _android,
      onLater: _required ? null : () => setState(() => _later = true),
    );
  }
}

class _UpdateRequired extends StatelessWidget {
  final String? store;
  final bool android;

  /// Null when the update is required.
  final VoidCallback? onLater;
  const _UpdateRequired({
    required this.store,
    required this.android,
    required this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    final he = Localizations.localeOf(context).languageCode == 'he';
    String t(String en, String hebrew) => he ? hebrew : en;
    // "from the App Store" in English; Hebrew names it bare (ב-App Store).
    final storeName = android
        ? 'Google Play'
        : (he ? 'App Store' : 'the App Store');
    // Above the navigator, so the phone's back button has nothing to go back
    // to: it leaves the app, and opening it again shows this page again.
    return Scaffold(
      backgroundColor: const Color(0xFF0A1230),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: Image.asset(
                    'assets/images/app_icon.png',
                    width: 112,
                    height: 112,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  onLater == null
                      ? t('Update required', 'נדרש עדכון')
                      : t('Update available', 'עדכון זמין'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  switch ((store == null, onLater == null)) {
                    (true, true) => t(
                      'A new version of Modiin4u is out. Update it from $storeName to keep using the app.',
                      'יצאה גרסה חדשה של מודיעין בשבילך. עדכנו אותה ב-$storeName כדי להמשיך להשתמש באפליקציה.',
                    ),
                    (false, true) => t(
                      'A new version of Modiin4u is out. Update to keep using the app.',
                      'יצאה גרסה חדשה של מודיעין בשבילך. עדכנו כדי להמשיך להשתמש באפליקציה.',
                    ),
                    (true, false) => t(
                      'A new version of Modiin4u is out. You can update it from $storeName.',
                      'יצאה גרסה חדשה של מודיעין בשבילך. אפשר לעדכן אותה ב-$storeName.',
                    ),
                    (false, false) => t(
                      'A new version of Modiin4u is out.',
                      'יצאה גרסה חדשה של מודיעין בשבילך.',
                    ),
                  },
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 15,
                    height: 1.5,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                if (store != null) ...[
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => launchUrl(
                        Uri.parse(store!),
                        mode: LaunchMode.externalApplication,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0A1230),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: Text(
                        t('Update', 'עדכון'),
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
                if (onLater != null) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: onLater,
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    child: Text(
                      t('Later', 'אחר כך'),
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
