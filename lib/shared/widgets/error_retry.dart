import 'package:flutter/material.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/app_colors.dart';

class ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorRetry({super.key, this.message = 'משהו השתבש', this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded, size: 36, color: AppColors.error),
            ),
            const SizedBox(height: 20),
            Text(message, style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.navy), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('בדקו את החיבור לאינטרנט ונסו שוב', style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14, color: AppColors.grayMeta), textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text('נסו שוב', style: TextStyle(fontFamily: AppFonts.rubik, fontWeight: FontWeight.w600)),
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
