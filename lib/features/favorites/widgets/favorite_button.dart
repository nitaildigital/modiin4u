import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../shared/widgets/sign_in_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/supabase/account_blocked.dart';
import '../../../core/theme/app_fonts.dart';
import '../providers/favorite_providers.dart';
import '../repositories/favorite_repository.dart';
import '../../../l10n/app_localizations.dart';

/// Saves or unsaves [id] for the signed-in resident, and says why when it
/// cannot: no account (with Sign in), a blocked account, or a failure. The
/// heart and the article's Save use it alike.
Future<void> toggleFavorite(
  BuildContext context,
  WidgetRef ref,
  FavoriteKind kind,
  String id,
) async {
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
          L.of(context).signInToSave,
          style: TextStyle(fontFamily: AppFonts.rubik),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        // Back to this page after signing in; none on the website, where
        // accounts are the app's.
        action: signInAction(context),
      ),
    );
  } catch (e) {
    final blocked = await refusedAsBlocked(e);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          blocked ? accountBlockedMessage(context) : L.of(context).errCouldNotSave,
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Saving needs an account, and accounts belong to the app. In a browser
    // the heart could only ever say "sign in to save" and send the reader to
    // a sign-in page the website no longer has, so it is not drawn.
    if (kIsWeb) return const SizedBox.shrink();

    final saved = ref.watch(isFavoriteProvider((kind: kind, id: id)));

    return GestureDetector(
      onTap: () => toggleFavorite(context, ref, kind, id),
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
