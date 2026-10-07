import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart'
    show AuthorizationStatus;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/businesses/providers/business_providers.dart'
    show businessByIdProvider, businessReviewsProvider, reviewRepliesProvider;
import '../../features/auth/providers/auth_provider.dart';
import '../../features/steps/providers/steps_providers.dart' show activeChallengeProvider;
import '../../features/steps/widgets/challenge_prize.dart' show showChallengeWin;
import '../providers/locale_provider.dart';
import '../router/app_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import 'push_feed.dart';
import 'push_prompt.dart';
import 'push_service.dart';

/// Wraps the app (MaterialApp's `builder`) to start the push service, open
/// what a tapped notification points at, and show one that arrives while the
/// app is open — which the phone and the browser leave to the app to draw.
/// Before a notification's link opens — from the phone or from the bell —
/// what it is about is read again. A reply or review notification leads to a
/// business: a page of it still open underneath kept its reviews, replies,
/// rating and count as they were before the reply or the approval.
void refreshForPushLink(WidgetRef ref, String link) {
  final business = RegExp(r'^/business/([^/?#]+)').firstMatch(link)?.group(1);
  if (business == null) return;
  ref.invalidate(businessReviewsProvider(business));
  ref.invalidate(reviewRepliesProvider(business));
  ref.invalidate(businessByIdProvider(business));
}

class PushHost extends ConsumerStatefulWidget {
  final Widget child;

  const PushHost({super.key, required this.child});

  @override
  ConsumerState<PushHost> createState() => _PushHostState();
}

class _PushHostState extends ConsumerState<PushHost> {
  late final PushService _push = ref.read(pushServiceProvider);
  StreamSubscription<PushMessage>? _incoming;
  PushMessage? _banner;
  Timer? _bannerTimer;

  /// Back from the background, the badges ask again: a notification may
  /// have arrived while the app was away.
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _push.pendingLink.addListener(_openPending);
    _incoming = _push.foreground.stream.listen(_show);
    appRouter.routerDelegate.addListener(_onRoute);
    _lifecycle = AppLifecycleListener(
      onResume: () {
        ref.invalidate(pushFeedProvider);
        _push.retryIfMissing();
      },
    );
    _push.start().then((_) => _onRoute());
    // The step competition's win message (00058), wherever the winner is
    // when their steps are saved: the challenge is read again after every
    // save, and names them. Once per challenge (showChallengeWin keeps it).
    if (!kIsWeb) {
      // `fireImmediately`: also for the value already there — a win named
      // while the app was closed is shown at the next start, on any page.
      ref.listenManual(
        activeChallengeProvider,
        (_, next) => _maybeShowWin(next.valueOrNull),
        fireImmediately: true,
      );
      ref.listenManual(authProvider, (_, _) => _maybeShowWin(ref.read(activeChallengeProvider).valueOrNull));
    }
  }

  void _maybeShowWin(Map<String, dynamic>? challenge) {
    final me = ref.read(authProvider);
    if (challenge == null || me == null || challenge['winner_id'] != me.id) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = appRouter.routerDelegate.navigatorKey.currentContext;
      if (context == null || !context.mounted || !_inApp) return;
      showChallengeWin(
        context,
        challenge,
        hebrew: ref.read(localeProvider).languageCode == 'he',
      );
    });
  }

  @override
  void dispose() {
    _push.pendingLink.removeListener(_openPending);
    appRouter.routerDelegate.removeListener(_onRoute);
    _incoming?.cancel();
    _bannerTimer?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  /// Past the splash and the first-run pages, the app is somewhere a page can
  /// be opened over, and somewhere a permission question makes sense.
  bool get _inApp {
    final path = appRouter.routerDelegate.currentConfiguration.uri.path;
    return path != '/splash' && !path.startsWith('/onboarding');
  }

  void _onRoute() {
    final path = appRouter.routerDelegate.currentConfiguration.uri.path;
    if (path.startsWith('/onboarding')) {
      _inviteOnOnboarding();
      return;
    }
    if (!_inApp) return;
    _openPending();
    // A win found while the splash was up waits for the first page.
    if (!kIsWeb) _maybeShowWin(ref.read(activeChallengeProvider).valueOrNull);
    // Asked on the app's own pages — the tabs — not over sign-in or a form.
    if (shellDestinations.contains(path)) _askOnHome();
  }

  /// Once per launch, over onboarding: the app's own invitation, while the
  /// phone has never asked. "Not now" leaves the phone's one question unused
  /// for the home screen.
  bool _invited = false;

  Future<void> _inviteOnOnboarding() async {
    if (_invited || kIsWeb) return;
    final status = await _push.permissionStatus();
    if (status != AuthorizationStatus.notDetermined) return;
    _invited = true;
    // Let the onboarding page show first; the sheet comes up over it.
    await Future.delayed(const Duration(milliseconds: 1200));
    final path = appRouter.routerDelegate.currentConfiguration.uri.path;
    final context = appRouter.routerDelegate.navigatorKey.currentContext;
    final stillThere = path.startsWith('/onboarding');
    if (!stillThere || context == null || !context.mounted) return;
    _sheetOpen = true;
    final allow = await showPushInvite(context);
    _sheetOpen = false;
    if (allow == true) await _push.requestPermission();
  }

  static const _blockedNoteKey = 'push_blocked_note_shown';
  bool _sheetOpen = false;

  /// On the home screen: the phone's question if it was never asked; if it
  /// was refused, once ever, a note on how to turn notifications back on.
  Future<void> _askOnHome() async {
    if (kIsWeb || _sheetOpen) return;
    final status = await _push.permissionStatus();
    if (status == AuthorizationStatus.notDetermined) {
      await _push.askOnce();
      return;
    }
    if (status != AuthorizationStatus.denied) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_blockedNoteKey) == true) return;
    await prefs.setBool(_blockedNoteKey, true);
    final context = appRouter.routerDelegate.navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    _sheetOpen = true;
    final open = await showPushBlockedNote(context);
    _sheetOpen = false;
    if (open == true) await _push.openPhoneSettings();
  }

  void _openPending() {
    final link = _push.pendingLink.value;
    if (link == null || !_inApp) return;
    _push.pendingLink.value = null;
    refreshForPushLink(ref, link);
    appRouter.push(link);
  }

  void _show(PushMessage message) {
    // It is in the bell now; the badges should count it.
    ref.invalidate(pushFeedProvider);
    if (!message.inAppBanner) return;
    _bannerTimer?.cancel();
    setState(() => _banner = message);
    _bannerTimer = Timer(const Duration(seconds: 6), _dismiss);
  }

  void _dismiss() {
    if (mounted) setState(() => _banner = null);
  }

  @override
  Widget build(BuildContext context) {
    final banner = _banner;
    return Stack(
      children: [
        widget.child,
        if (banner != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _Banner(
                      message: banner,
                      onTap: () {
                        _dismiss();
                        _push.open(banner);
                      },
                      onClose: _dismiss,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  final PushMessage message;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _Banner({
    required this.message,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 6,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 4, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.notifications_active_outlined,
                  color: AppColors.turquoise,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (message.title.isNotEmpty)
                      Text(
                        message.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppFonts.rubik,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    if (message.body.isNotEmpty)
                      Text(
                        message.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppFonts.rubik,
                          fontSize: 13,
                          color: AppColors.grayMeta,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.close,
                  size: 18,
                  color: AppColors.grayLight,
                ),
                onPressed: onClose,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
