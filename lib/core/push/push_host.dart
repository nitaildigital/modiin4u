import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../router/app_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import 'push_service.dart';

/// Wraps the app (MaterialApp's `builder`) to start the push service, open
/// what a tapped notification points at, and show one that arrives while the
/// app is open — which the phone and the browser leave to the app to draw.
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

  @override
  void initState() {
    super.initState();
    _push.pendingLink.addListener(_openPending);
    _incoming = _push.foreground.stream.listen(_show);
    appRouter.routerDelegate.addListener(_onRoute);
    _push.start().then((_) => _onRoute());
  }

  @override
  void dispose() {
    _push.pendingLink.removeListener(_openPending);
    appRouter.routerDelegate.removeListener(_onRoute);
    _incoming?.cancel();
    _bannerTimer?.cancel();
    super.dispose();
  }

  /// Past the splash and the first-run pages, the app is somewhere a page can
  /// be opened over, and somewhere a permission question makes sense.
  bool get _inApp {
    final path = appRouter.routerDelegate.currentConfiguration.uri.path;
    return path != '/splash' && !path.startsWith('/onboarding');
  }

  void _onRoute() {
    if (!_inApp) return;
    _openPending();
    _push.askOnce();
  }

  void _openPending() {
    final link = _push.pendingLink.value;
    if (link == null || !_inApp) return;
    _push.pendingLink.value = null;
    appRouter.push(link);
  }

  void _show(PushMessage message) {
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

  const _Banner({required this.message, required this.onTap, required this.onClose});

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
                child: Icon(Icons.notifications_active_outlined, color: AppColors.turquoise),
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
                icon: const Icon(Icons.close, size: 18, color: AppColors.grayLight),
                onPressed: onClose,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
