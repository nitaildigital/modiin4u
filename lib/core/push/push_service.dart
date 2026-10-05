import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart'
    show openAppSettings;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../firebase_options.dart';
import '../providers/locale_provider.dart';
import '../supabase/supabase_config.dart';
import 'push_config.dart';
import 'push_settings.dart';
import 'push_unread.dart';

/// Push notifications on this device: Firebase, the permission, the token,
/// and what happens when one is tapped.
///
/// The device is registered through `register_push_device` with its
/// [PushSettings] and language, and again whenever either changes or
/// Firebase hands out a new token. Nothing here needs an account.
///
/// Until `lib/firebase_options.dart` holds the project's keys, [start]
/// finds none and the service stays off: no prompt, no token, and the rest
/// of the app carries on.
final pushServiceProvider = Provider<PushService>((ref) => PushService(ref));

class PushService {
  PushService(this._ref);

  final Ref _ref;

  static const _tokenKey = 'push_token';

  bool _started = false;
  bool _ready = false;
  String? _token;
  Timer? _syncTimer;

  /// Whether this device has allowed notifications. Null until known, and
  /// on a device where Firebase is not set up.
  final allowed = ValueNotifier<bool?>(null);

  /// A page to open because a notification was tapped. [PushHost] takes it
  /// once the app is past its splash screen.
  final pendingLink = ValueNotifier<String?>(null);

  /// Notifications that arrive while the app is open, which the phone does
  /// not draw itself; [PushHost] shows them as a banner.
  final foreground = StreamController<PushMessage>.broadcast();

  /// Whether Firebase is set up on this build.
  bool get isAvailable => _ready;

  /// This device's token — what the bell and the open count are keyed to.
  /// Remembered between runs, so a browser that allowed notifications last
  /// time is known before Firebase answers.
  Future<String?> token() async {
    if (_token != null) return _token;
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint('Push notifications off: $e');
      return;
    }
    if (kIsWeb && webPushVapidKey.isEmpty) {
      debugPrint(
        'Push notifications off on the web: no VAPID key in push_config.dart',
      );
      return;
    }
    _ready = true;

    final messaging = FirebaseMessaging.instance;
    FirebaseMessaging.onMessage.listen(
      (m) => foreground.add(PushMessage.from(m)),
    );
    FirebaseMessaging.onMessageOpenedApp.listen(
      (m) => open(PushMessage.from(m)),
    );
    if (!kIsWeb) {
      final initial = await messaging.getInitialMessage();
      if (initial != null) open(PushMessage.from(initial));
    }
    messaging.onTokenRefresh.listen((t) {
      _token = t;
      _saveToken(t);
      _sync();
    });

    _ref.listen(pushSettingsProvider, (_, _) => _scheduleSync());
    _ref.listen(localeProvider, (_, _) => _scheduleSync());
    // The row records who is signed in, so a reply reaches the right person
    // and stops reaching them once they sign out.
    _ref.listen(authProvider.select((u) => u?.id), (_, _) => _scheduleSync());

    // Already allowed (a later run, or allowed in the browser before):
    // refresh the token and the row without asking anything.
    final settings = await messaging.getNotificationSettings();
    allowed.value = _granted(settings.authorizationStatus);
    if (allowed.value == true) await _fetchToken();

    // The website counts an open from the address the notification opened,
    // which carries `?push=<campaign>`.
    if (kIsWeb) {
      final campaign = Uri.base.queryParameters['push'];
      if (campaign != null) unawaited(_record(campaign));
    }
  }

  /// Asks once, the first time the app reaches its home screen. Later the
  /// switch in Settings asks again. A browser is never asked unprompted —
  /// browsers hold that against a site — only from a tap.
  Future<void> askOnce() async {
    if (!_ready || kIsWeb || allowed.value == true || _asking) return;
    // The phone's own answer decides: asked only while it has never been
    // asked. After "Don't Allow" the phone does not show the question again
    // anyway; the Settings switch then leads to the phone's settings. A flag
    // of our own once said "asked" for a question that never appeared.
    final status = (await FirebaseMessaging.instance.getNotificationSettings())
        .authorizationStatus;
    if (status != AuthorizationStatus.notDetermined) return;
    _asking = true;
    try {
      await requestPermission();
    } finally {
      _asking = false;
    }
  }

  bool _asking = false;

  /// The phone's answer so far; null where Firebase is not set up.
  Future<AuthorizationStatus?> permissionStatus() async {
    if (!_ready) return null;
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    return settings.authorizationStatus;
  }

  /// The app's page in the phone's settings — the only way back after a
  /// "Don't Allow".
  Future<void> openPhoneSettings() => openAppSettings();

  /// Shows the system's "allow notifications?" and, if allowed, registers.
  /// Returns whether notifications are allowed afterwards. Once someone has
  /// refused, iOS and Android no longer show the question; the caller then
  /// sends them to the phone's settings.
  ///
  /// With [openSettingsIfRefused], someone who refused before is taken to
  /// the app's page in the phone's settings, the only place left to allow
  /// it; the first refusal itself is respected, not followed by settings.
  Future<bool> requestPermission({bool openSettingsIfRefused = false}) async {
    if (!_ready) return false;
    final messaging = FirebaseMessaging.instance;
    final before = await messaging.getNotificationSettings();
    if (before.authorizationStatus == AuthorizationStatus.denied &&
        openSettingsIfRefused &&
        !kIsWeb) {
      await openAppSettings();
      return false;
    }
    final settings = await messaging.requestPermission();
    allowed.value = _granted(settings.authorizationStatus);
    if (allowed.value == true) await _fetchToken();
    return allowed.value == true;
  }

  /// A tapped notification: counted, then opened — a page in the app, or an
  /// outside address in the browser.
  Future<void> open(PushMessage message) async {
    if (message.campaignId != null) {
      unawaited(_record(message.campaignId!));
      unawaited(
        _ref.read(pushOpenedProvider.notifier).add(message.campaignId!),
      );
    }
    final link = message.link;
    if (link == null || link.isEmpty) return;
    if (link.startsWith('/')) {
      pendingLink.value = link;
    } else {
      final uri = Uri.tryParse(link);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  bool _granted(AuthorizationStatus s) =>
      s == AuthorizationStatus.authorized ||
      s == AuthorizationStatus.provisional;

  /// For a device that allowed notifications but has no token yet: Apple's
  /// part can arrive after the first attempt gave up, so coming back to the
  /// app tries again.
  Future<void> retryIfMissing() async {
    if (!_ready || _token != null || allowed.value != true) return;
    await _fetchToken();
  }

  bool _fetching = false;

  Future<void> _fetchToken() async {
    if (_fetching) return;
    _fetching = true;
    try {
      await _fetchTokenOnce();
    } finally {
      _fetching = false;
    }
  }

  Future<void> _fetchTokenOnce() async {
    final messaging = FirebaseMessaging.instance;
    String? token;
    var apnsMissing = false;
    // On an iPhone, Firebase's token waits on Apple's, which can take a while
    // after permission is granted — half a minute on a first install.
    for (var attempt = 0; attempt < 15 && token == null; attempt++) {
      try {
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
          if (await messaging.getAPNSToken() == null) {
            apnsMissing = true;
            await Future.delayed(const Duration(seconds: 2));
            continue;
          }
        }
        token = await messaging.getToken(
          vapidKey: kIsWeb ? webPushVapidKey : null,
        );
      } catch (e) {
        debugPrint('Push token: $e');
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    if (token == null) {
      debugPrint(
        apnsMissing
            ? 'Push: no APNs token from Apple yet; will try again on resume'
            : 'Push: no Firebase token yet; will try again on resume',
      );
      return;
    }
    debugPrint('Push: registered this device');
    _token = token;
    await _saveToken(token);
    await _sync();
  }

  Future<void> _saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } catch (_) {}
  }

  /// Several switches flipped in a row are one write, not several.
  void _scheduleSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer(const Duration(milliseconds: 600), _sync);
  }

  Future<void> _sync() async {
    final token = _token;
    if (token == null) return;
    final s = _ref.read(pushSettingsProvider);
    try {
      await SupabaseConfig.client.rpc(
        'register_push_device',
        params: {
          'p_token': token,
          'p_platform': _platform,
          'p_locale': _ref.read(localeProvider).languageCode,
          'p_enabled': s.enabled,
          'p_news': s.news,
          'p_events': s.events,
          'p_businesses': s.businesses,
          'p_deals': s.deals,
          'p_realestate': s.realestate,
          'p_neighborhood': s.neighborhood,
          'p_neighborhood_id': s.neighborhoodId,
          'p_app_version': null,
          'p_replies': s.replies,
        },
      );
    } catch (e) {
      // The next change, start or token refresh tries again.
      debugPrint('Push registration: $e');
    }
  }

  Future<void> _record(String campaignId) async {
    final token = await this.token();
    if (token == null) return;
    try {
      await SupabaseConfig.client.rpc(
        'record_push_event',
        params: {'p_campaign': campaignId, 'p_token': token, 'p_kind': 'open'},
      );
    } catch (_) {
      // An uncounted open is better than a failed one.
    }
  }

  String get _platform {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
  }
}

/// The parts of a Firebase message the app uses.
class PushMessage {
  final String? campaignId;
  final String? link;
  final String title;
  final String body;

  const PushMessage({
    this.campaignId,
    this.link,
    this.title = '',
    this.body = '',
  });

  factory PushMessage.from(RemoteMessage m) => PushMessage(
    campaignId: m.data['campaign_id'] as String?,
    link: m.data['link'] as String?,
    title: m.notification?.title ?? '',
    body: m.notification?.body ?? '',
  );
}
