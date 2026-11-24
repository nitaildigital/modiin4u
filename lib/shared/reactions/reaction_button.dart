import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/account_blocked.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/sign_in_action.dart';
import 'reactions.dart';

/// 👍 with its count — or, on a review, "Helpful" with its count (00089).
///
/// At least 44 high, so it is easy to hit; the thumb pops when pressed.
/// Signed out, it offers to sign in; a blocked account is told so. Not on the
/// website, where accounts are the app's.
class ReactionButton extends ConsumerStatefulWidget {
  final ReactionTarget target;
  final String id;
  final ReactionKind kind;

  /// Size of the icon and text; the tap area stays at least 44.
  final double size;
  final Color color;

  const ReactionButton({
    super.key,
    required this.target,
    required this.id,
    this.kind = ReactionKind.like,
    this.size = 16,
    this.color = const Color(0xFF6D6D6D),
  });

  @override
  ConsumerState<ReactionButton> createState() => _ReactionButtonState();
}

class _ReactionButtonState extends ConsumerState<ReactionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      ref.read(reactionsProvider(widget.target).notifier).ensure(widget.id);
    }
  }

  @override
  void didUpdateWidget(ReactionButton old) {
    super.didUpdateWidget(old);
    if (old.id != widget.id && !kIsWeb) {
      ref.read(reactionsProvider(widget.target).notifier).ensure(widget.id);
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  Future<void> _tap() async {
    final l = L.of(context);
    final messenger = ScaffoldMessenger.of(context);
    HapticFeedback.selectionClick();
    _pop.forward(from: 0);
    try {
      final signedIn = await ref
          .read(reactionsProvider(widget.target).notifier)
          .toggle(widget.id, widget.kind);
      if (signedIn || !mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(l.signInToLike, style: TextStyle(fontFamily: AppFonts.rubik)),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: signInAction(context),
        ));
    } catch (e) {
      final blocked = await refusedAsBlocked(e);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(
          blocked ? accountBlockedMessage(context) : l.errCouldNotSave,
          style: TextStyle(fontFamily: AppFonts.rubik),
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const SizedBox.shrink();
    final l = L.of(context);
    final info = ref.watch(
      reactionsProvider(widget.target).select((m) => m[widget.id]),
    ) ?? const ReactionInfo();
    final on = info.mine(widget.kind);
    final count = info.count(widget.kind);
    final helpful = widget.kind == ReactionKind.helpful;
    final tint = on ? AppColors.midBlue : widget.color;
    final icon = helpful
        ? (on ? Icons.check_circle : Icons.check_circle_outline)
        : (on ? Icons.thumb_up : Icons.thumb_up_outlined);
    final label = helpful ? l.helpfulAction : l.likeAction;

    return Semantics(
      button: true,
      toggled: on,
      label: count > 0 ? '$label, $count' : label,
      child: InkWell(
        onTap: _tap,
        borderRadius: BorderRadius.circular(22),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: TweenSequence<double>([
                    TweenSequenceItem(tween: Tween(begin: 1, end: 1.35), weight: 45),
                    TweenSequenceItem(tween: Tween(begin: 1.35, end: 1), weight: 55),
                  ]).animate(CurvedAnimation(parent: _pop, curve: Curves.easeOut)),
                  child: Icon(icon, size: widget.size + 2, color: tint),
                ),
                const SizedBox(width: 4),
                if (helpful || count > 0)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Text(
                      helpful ? (count > 0 ? '$label · $count' : label) : '$count',
                      key: ValueKey('$on$count'),
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: widget.size - 3,
                        fontWeight: on ? FontWeight.w600 : FontWeight.w500,
                        color: tint,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
