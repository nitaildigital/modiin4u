import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late List<_NotificationItem> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = [
      _NotificationItem(
        icon: Icons.local_offer,
        title: 'הטבה חדשה מפיצה פרגו',
        body: '20% הנחה על כל הפיצות — עד סוף השבוע',
        time: 'לפני שעה',
        isNew: true,
        route: '/deals',
      ),
      _NotificationItem(
        icon: Icons.apartment,
        title: 'נכס חדש תואם לחיפוש שלך',
        body: '4 חדרים בהפרחים — 2,450,000 ₪',
        time: 'לפני 3 שעות',
        isNew: true,
        route: '/realestate',
      ),
      _NotificationItem(
        icon: Icons.event,
        title: 'אירוע מחר — פסטיבל אוכל רחוב',
        body: 'פארק ענבה, 18:00. אישרתם הגעה!',
        time: 'אתמול',
        isNew: false,
        route: '/events',
      ),
      _NotificationItem(
        icon: Icons.emoji_events,
        title: 'כל הכבוד! 50 נקודות חדשות',
        body: 'קיבלתם נקודות על ביקורת שכתבתם',
        time: 'לפני יומיים',
        isNew: false,
        route: '/steps',
      ),
      _NotificationItem(
        icon: Icons.campaign,
        title: 'עדכון עירוני חדש',
        body: 'עבודות תשתית ברחוב הפלמ"ח — חסימה חלקית',
        time: 'לפני 3 ימים',
        isNew: false,
        route: '/municipal',
      ),
    ];
  }

  void _markAllRead() {
    setState(() {
      _notifications = _notifications.map((n) => _NotificationItem(
        icon: n.icon, title: n.title, body: n.body, time: n.time, isNew: false, route: n.route,
      )).toList();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('כל ההתראות סומנו כנקראו', style: GoogleFonts.rubik()),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _notifications.any((n) => n.isNew);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('התראות', style: GoogleFonts.rubik(fontWeight: FontWeight.w700)),
          actions: [
            if (hasUnread)
              TextButton(
                onPressed: _markAllRead,
                child: Text('סמן הכל כנקרא', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.turquoise)),
              ),
          ],
        ),
        body: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _notifications.length,
          separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 1, indent: 76),
          itemBuilder: (context, index) {
            final n = _notifications[index];
            return InkWell(
              onTap: () {
                if (n.isNew) {
                  setState(() {
                    _notifications[index] = _NotificationItem(
                      icon: n.icon, title: n.title, body: n.body, time: n.time, isNew: false, route: n.route,
                    );
                  });
                }
                context.push(n.route);
              },
              child: Container(
                color: n.isNew ? AppColors.turquoise.withValues(alpha: 0.03) : null,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                                  style: GoogleFonts.rubik(
                                    fontSize: 14,
                                    fontWeight: n.isNew ? FontWeight.w600 : FontWeight.w500,
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
                            style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayMeta),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            n.time,
                            style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayLight),
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
