import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../shared/providers/app_settings_provider.dart';
import '../supabase/supabase_config.dart';
import '../theme/app_fonts.dart';

/// Stops an app that is too old, until it is updated.
///
/// The client (8 Oct): force an update from the panel. Settings in the panel
/// holds the oldest build each platform may still use
/// (`min_build_android`, `min_build_ios` in `app_settings`) — the build
/// number, the part after "+" in pubspec's version. Below it, the app shows
/// only a page asking for the update, with a button to the store link the
/// panel holds. 0 or empty means no minimum.
///
/// Asked at start and on every return from the background, so a minimum set
/// while the app is open applies the next time it is opened. Never on the
/// website, which is always the latest. When the answer cannot be had — no
/// connection, no table — the app is let through: a check that fails must
/// not lock people out.
class ForceUpdateGate extends StatefulWidget {
  final Widget child;
  const ForceUpdateGate({super.key, required this.child});

  @override
  State<ForceUpdateGate> createState() => _ForceUpdateGateState();
}

class _ForceUpdateGateState extends State<ForceUpdateGate> {
  AppLifecycleListener? _lifecycle;

  /// The store to send to, once this build is found too old; null while it
  /// may run. An empty string: too old, but the panel has no store link.
  String? _blockedStore;

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
      final rows = await SupabaseConfig.client
          .from('app_settings')
          .select('key, value')
          .inFilter('key', [minKey, storeKey]);
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
      setState(
        () => _blockedStore = blocked
            ? (storeUrl(settings, storeKey) ?? '')
            : null,
      );
    } catch (_) {
      // Left as it was: a failed check neither blocks nor unblocks.
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = _blockedStore;
    if (store == null) return widget.child;
    return _UpdateRequired(
      store: store.isEmpty ? null : store,
      android: _android,
    );
  }
}

class _UpdateRequired extends StatelessWidget {
  final String? store;
  final bool android;
  const _UpdateRequired({required this.store, required this.android});

  @override
  Widget build(BuildContext context) {
    final he = Localizations.localeOf(context).languageCode == 'he';
    String t(String en, String hebrew) => he ? hebrew : en;
    final storeName = android ? 'Google Play' : 'App Store';
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
                  t('Update required', 'נדרש עדכון'),
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
                  store == null
                      ? t(
                          'A new version of Modiin4u is out. Update it from $storeName to keep using the app.',
                          'יצאה גרסה חדשה של מודיעין בשבילך. עדכנו אותה ב-$storeName כדי להמשיך להשתמש באפליקציה.',
                        )
                      : t(
                          'A new version of Modiin4u is out. Update to keep using the app.',
                          'יצאה גרסה חדשה של מודיעין בשבילך. עדכנו כדי להמשיך להשתמש באפליקציה.',
                        ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
