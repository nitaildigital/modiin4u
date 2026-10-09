import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import '../auth/providers/auth_provider.dart';
import 'data/urban_profile.dart';

/// Opens the Urban Profile onboarding once, at an account's first sign-in
/// (the client, 9 Oct: sign up, confirm the e-mail, then the three steps).
/// Registration requires confirming the address, so there is no session
/// right after "Register" — the first sign-in after it is the first moment
/// anything can be saved.
///
/// Once only: the profile's `urban_profile_seen_at` is set as it opens, and
/// it never opens by itself again. Only for residents' accounts made from
/// the launch on; older accounts, and anyone who skipped, finish it from the
/// Profile screen. The app only — accounts are the app's.
class UrbanProfileGate extends ConsumerStatefulWidget {
  final Widget child;
  const UrbanProfileGate({super.key, required this.child});

  @override
  ConsumerState<UrbanProfileGate> createState() => _UrbanProfileGateState();
}

class _UrbanProfileGateState extends ConsumerState<UrbanProfileGate> {
  /// The account already looked at in this run of the app.
  String? _checked;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) return;
    ref.listenManual(authProvider, (_, _) => _maybeOpen(), fireImmediately: true);
    appRouter.routerDelegate.addListener(_maybeOpen);
  }

  @override
  void dispose() {
    if (!kIsWeb) appRouter.routerDelegate.removeListener(_maybeOpen);
    super.dispose();
  }

  /// Not over the start of the app, the sign-in and sign-up pages, the
  /// e-mail links or a new password: they lead somewhere of their own, and
  /// the check waits for the page they lead to.
  bool get _somewhereToOpenOver {
    final path = appRouter.routerDelegate.currentConfiguration.uri.path;
    const busy = ['/splash', '/onboarding', '/login', '/signup', '/auth', '/reset-password', '/urban-profile'];
    return !busy.any(path.startsWith);
  }

  Future<void> _maybeOpen() async {
    final user = ref.read(authProvider);
    if (user == null || _busy || _checked == user.id) return;
    if (ref.read(passwordResetPendingProvider) || !_somewhereToOpenOver) return;
    _busy = true;
    try {
      _checked = user.id;
      // A business account is a business, not a resident with a profile.
      if (user.isBusinessOwner) return;
      final repo = ref.read(urbanProfileRepositoryProvider);
      final p = await repo.mine();
      if (p == null || p.seenAt != null) return;
      final created = p.createdAt;
      if (created == null || created.isBefore(urbanProfileLaunch)) return;
      if (ref.read(authProvider)?.id != user.id) return;
      await repo.markSeen();
      appRouter.push('/urban-profile/1');
    } catch (_) {
      // Not this time; the Profile screen offers it all the same.
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
