import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../providers/favorite_providers.dart';
import '../repositories/favorite_repository.dart';

/// The heart on a card, saving to the `favorites` table.
///
/// Every card drew its own white circle with a heart in it and nothing behind
/// the tap. This keeps that shape — the size differs from card to card — and
/// gives it somewhere to write to.
class FavoriteButton extends ConsumerWidget {
  final FavoriteKind kind;
  final String id;

  /// The white circle's diameter, and the heart inside it.
  final double size;
  final double iconSize;
  final Color color;

  const FavoriteButton({
    super.key,
    required this.kind,
    required this.id,
    this.size = 28,
    this.iconSize = 16,
    this.color = AppColors.midBlue,
  });

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    try {
      final signedIn = await ref
          .read(favoritesProvider.notifier)
          .toggle(kind, id);
      if (signedIn || !context.mounted) return;

      // Saving needs an account, so offer one rather than doing nothing.
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'התחברו כדי לשמור',
            style: TextStyle(fontFamily: AppFonts.rubik),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          action: SnackBarAction(
            label: 'התחברות',
            onPressed: () => context.push('/login'),
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'לא ניתן היה לשמור. נסו שוב.',
            style: TextStyle(fontFamily: AppFonts.rubik),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(isFavoriteProvider((kind: kind, id: id)));

    return GestureDetector(
      onTap: () => _toggle(context, ref),
      // The circle is small, so the tap target is widened past the paint.
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            saved ? IconsaxPlusBold.heart : IconsaxPlusLinear.heart,
            size: iconSize,
            color: saved ? AppColors.error : color,
          ),
        ),
      ),
    );
  }
}
