import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/push/push_feed.dart';
import '../../../core/push/push_unread.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/m_account_widgets.dart' show mTr;
import '../widgets/push_feed_list.dart';
import 'web_notifications_screen.dart';
import '../../../l10n/app_localizations.dart';

/// The bell: the notifications sent so far that this device would have
/// received (`push_feed`, migration 00045), newest first.
///
/// This screen once opened with six notifications written into its source —
/// an offer nobody had made, a property "matching your search" with
/// `listings` empty, an event the reader was told they had confirmed. What
/// it lists now is only what the panel actually sent.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  /// What was unread when the bell was opened. Read before it is marked seen,
  /// so this visit still shows which ones are new; the badges clear at once.
  late final DateTime? _seenBefore = ref.read(pushSeenProvider);

  @override
  void initState() {
    super.initState();
    // After the first frame: a provider may not change while widgets build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(pushFeedProvider);
      ref.read(pushSeenProvider.notifier).markSeen();
    });
  }

  /// Said plainly. An empty scroll area reads as a screen that failed to
  /// load, and this one has not failed — there is nothing yet.
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none,
              size: 48,
              color: AppColors.grayLight,
            ),
            const SizedBox(height: 16),
            Text(
              L.of(context).noNotifications,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.rubik,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              L.of(context).notificationsAppearHere,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.rubik,
                fontSize: 14,
                height: 1.5,
                color: AppColors.grayText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) {
          return WebNotificationsContent(unreadAfter: _seenBefore);
        }
        return _buildMobile(context);
      },
    );
  }

  Widget _buildMobile(BuildContext context) {
    // The app's language sets the direction; this page was held right to
    // left, so in English its text read back to front.
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            L.of(context).notifications,
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: Column(
          children: [
            PushTurnOnCard(
              title: mTr(context, 'Get a notification when something new is published',
                  'קבלו התראה כשמתפרסם משהו חדש'),
              action: mTr(context, 'Turn on', 'הפעלה'),
            ),
            Expanded(
              child: PushFeedList(
                languageCode: ref.watch(localeProvider).languageCode,
                empty: _buildEmptyState(),
                unreadAfter: _seenBefore,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
