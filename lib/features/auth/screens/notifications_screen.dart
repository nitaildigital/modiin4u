import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      _NotificationItem(
        icon: Icons.local_offer,
        title: 'הטבה חדשה מפיצה פרגו',
        body: '20% הנחה על כל הפיצות — עד סוף השבוע',
        time: 'לפני שעה',
        isNew: true,
      ),
      _NotificationItem(
        icon: Icons.apartment,
        title: 'נכס חדש תואם לחיפוש שלך',
        body: '4 חדרים בהפרחים — 2,450,000 ₪',
        time: 'לפני 3 שעות',
        isNew: true,
      ),
      _NotificationItem(
        icon: Icons.event,
        title: 'אירוע מחר — פסטיבל אוכל רחוב',
        body: 'פארק ענבה, 18:00. אישרתם הגעה!',
        time: 'אתמול',
        isNew: false,
      ),
      _NotificationItem(
        icon: Icons.emoji_events,
        title: 'כל הכבוד! 50 נקודות חדשות',
        body: 'קיבלתם נקודות על ביקורת שכתבתם',
        time: 'לפני יומיים',
        isNew: false,
      ),
      _NotificationItem(
        icon: Icons.campaign,
        title: 'עדכון עירוני חדש',
        body: 'עבודות תשתית ברחוב הפלמ"ח — חסימה חלקית',
        time: 'לפני 3 ימים',
        isNew: false,
      ),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('התראות', style: GoogleFonts.rubik(fontWeight: FontWeight.w700)),
          actions: [
            TextButton(
              onPressed: () {},
              child: Text('סמן הכל כנקרא', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.turquoise)),
            ),
          ],
        ),
        body: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: notifications.length,
          separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 1, indent: 76),
          itemBuilder: (context, index) {
            final n = notifications[index];
            return Container(
              color: n.isNew ? AppColors.turquoise.withValues(alpha: 0.03) : null,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
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
                                  color: AppColors.navy,
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

  const _NotificationItem({
    required this.icon,
    required this.title,
    required this.body,
    required this.time,
    required this.isNew,
  });
}
