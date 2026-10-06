import 'package:flutter/material.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

class ErrorRetry extends StatelessWidget {
  /// Null for the usual "Something went wrong", in the language showing.
  final String? message;
  final VoidCallback? onRetry;

  /// Smaller, for a row of fixed height (the home page's card rows), where
  /// the full size ran out of room and cut the button off.
  final bool compact;

  const ErrorRetry({super.key, this.message, this.onRetry, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final circle = compact ? 48.0 : 80.0;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 8 : 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: circle,
              height: circle,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wifi_off_rounded, size: compact ? 24 : 36, color: AppColors.error),
            ),
            SizedBox(height: compact ? 10 : 20),
            Text(message ?? l.somethingWentWrong, style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.navy), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(l.checkConnection, style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14, color: AppColors.grayMeta), textAlign: TextAlign.center),
            if (onRetry != null) ...[
              SizedBox(height: compact ? 12 : 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(l.tryAgain, style: TextStyle(fontFamily: AppFonts.rubik, fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({super.key, required this.icon, required this.title, this.subtitle, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.grayLight.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.navy), textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!, style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14, color: AppColors.grayMeta), textAlign: TextAlign.center),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!, style: TextStyle(fontFamily: AppFonts.rubik, fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
