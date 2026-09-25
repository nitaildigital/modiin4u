import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  /// Empty, and it stays empty until there is a table behind it.
  ///
  /// This screen opened with six notifications written into the source: a
  /// 20% offer from פיצה פרגו, a new four-room property "matching your
  /// search" at ₪2,450,000, a street-food festival tomorrow that told the
  /// reader **"you confirmed you were coming"**, fifty points awarded for a
  /// review, and roadworks on a named street. Nobody had offered, listed,
  /// RSVP'd, earned or announced any of it.
  ///
  /// The schema has `admin_notifications` and nothing for residents, so
  /// there is no source to read. The bell in the header opens this from
  /// every screen in the app.
  final List<_NotificationItem> _notifications = const [];

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
              'אין התראות',
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
              'כשיהיו עדכונים עבורכם, הם יופיעו כאן.',
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'התראות',
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: _notifications.isEmpty
            ? _buildEmptyState()
            : ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _notifications.length,
          separatorBuilder: (_, __) =>
              const Divider(color: AppColors.border, height: 1, indent: 76),
          itemBuilder: (context, index) {
            final n = _notifications[index];
            return InkWell(
              onTap: () {
                if (n.isNew) {
                  setState(() {
                    _notifications[index] = _NotificationItem(
                      icon: n.icon,
                      title: n.title,
                      body: n.body,
                      time: n.time,
                      isNew: false,
                      route: n.route,
                    );
                  });
                }
                context.push(n.route);
              },
              child: Container(
                color: n.isNew
                    ? AppColors.turquoise.withValues(alpha: 0.03)
                    : null,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: context.surfaceDim,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(n.icon, size: 22, color: AppColors.turquoise),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  n.title,
                                  style: TextStyle(
                                    fontFamily: AppFonts.rubik,
                                    fontSize: 14,
                                    fontWeight: n.isNew
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: context.textPrimary,
                                  ),
                                ),
                              ),
                              if (n.isNew)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.turquoise,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            n.body,
                            style: TextStyle(
                              fontFamily: AppFonts.rubik,
                              fontSize: 13,
                              color: AppColors.grayMeta,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            n.time,
                            style: TextStyle(
                              fontFamily: AppFonts.rubik,
                              fontSize: 12,
                              color: AppColors.grayLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NotificationItem {
  final IconData icon;
  final String title;
  final String body;
  final String time;
  final bool isNew;
  final String route;

  const _NotificationItem({
    required this.icon,
    required this.title,
    required this.body,
    required this.time,
    required this.isNew,
    required this.route,
  });
}
