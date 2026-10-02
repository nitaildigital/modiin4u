import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../admin_language.dart';

/// What a section shows in place of its list when the list failed to load:
/// what failed, the database's own reason, and a way to try again without
/// reloading the whole panel.
class AdminLoadError extends StatelessWidget {
  /// In Hebrew, e.g. "שגיאה בטעינת הקטגוריות".
  final String message;
  final Object error;
  final VoidCallback onRetry;

  const AdminLoadError({
    super.key,
    required this.message,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontFamily: AppFonts.rubik,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.rubik,
                fontSize: 12,
                color: AppColors.grayText,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(
                tr('נסה שוב', 'Try again'),
                style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Runs a row action — a toggle, a status change, a hide — and says so when
/// it fails.
///
/// The menus used to fire these without waiting, so a refused write left the
/// row as it was and nothing told the client why. Returns whether it worked.
Future<bool> runAdminAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  // Taken before the wait: the row that asked may be rebuilt away by the
  // reload the action itself triggers.
  final messenger = ScaffoldMessenger.of(context);
  try {
    await action();
    return true;
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          tr('הפעולה נכשלה: $e', 'The action failed: $e'),
          style: TextStyle(fontFamily: AppFonts.rubik),
        ),
        backgroundColor: AppColors.error,
      ),
    );
    return false;
  }
}
