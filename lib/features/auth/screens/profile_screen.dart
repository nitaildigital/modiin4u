import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/login'));
      return const SizedBox.shrink();
    }

    final favCount = user.favoriteBusinessIds.length + user.favoriteListingIds.length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(gradient: AppColors.brandGradient),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_forward_ios, color: AppColors.white, size: 20),
                              onPressed: () => context.pop(),
                            ),
                            Text('הפרופיל שלי', style: GoogleFonts.rubik(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.white)),
                            IconButton(
                              icon: const Icon(Icons.settings_outlined, color: AppColors.white, size: 22),
                              onPressed: () => context.push('/settings'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.white.withValues(alpha: 0.4), width: 3),
                        ),
                        child: Center(
                          child: Text(
                            user.initials,
                            style: GoogleFonts.rubik(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(user.name, style: GoogleFonts.rubik(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.white)),
                      const SizedBox(height: 6),
                      if (user.neighborhood != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_on, size: 16, color: AppColors.white.withValues(alpha: 0.8)),
                            const SizedBox(width: 4),
                            Text(user.neighborhood!, style: GoogleFonts.rubik(fontSize: 14, color: AppColors.white.withValues(alpha: 0.8))),
                          ],
                        ),
                      if (user.isVerifiedResident) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified, size: 14, color: AppColors.gold),
                              const SizedBox(width: 4),
                              Text('תושב מאומת', style: GoogleFonts.rubik(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.white)),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            _StatItem('${user.points}', 'נקודות', Icons.emoji_events, AppColors.gold),
                            Container(width: 1, height: 36, color: AppColors.white.withValues(alpha: 0.2)),
                            _StatItem('$favCount', 'מועדפים', Icons.favorite, AppColors.error),
                            Container(width: 1, height: 36, color: AppColors.white.withValues(alpha: 0.2)),
                            _StatItem('7', 'ביקורות', Icons.star, AppColors.gold),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -20),
                child: Container(
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('פעולות מהירות', style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w600, color: context.isDark ? const Color(0xFF9E9E9E) : AppColors.grayMeta)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _QuickAction(Icons.edit_outlined, 'עריכה', AppColors.turquoise, () => context.push('/edit-profile')),
                            const SizedBox(width: 12),
                            _QuickAction(Icons.favorite_outline, 'מועדפים', AppColors.error, () => context.push('/favorites')),
                            const SizedBox(width: 12),
                            _QuickAction(Icons.local_offer_outlined, 'הטבות', AppColors.success, () => context.push('/deals')),
                            const SizedBox(width: 12),
                            _QuickAction(Icons.notifications_outlined, 'התראות', AppColors.gold, () => context.push('/notifications')),
                          ],
                        ),
                        const SizedBox(height: 28),
                        _MenuCard(
                          icon: Icons.directions_walk_outlined,
                          label: 'צעדים והישגים',
                          subtitle: '72,000 צעדים החודש',
                          color: AppColors.success,
                          onTap: () => context.push('/steps'),
                        ),
                        _MenuCard(
                          icon: Icons.rate_review_outlined,
                          label: 'הביקורות שלי',
                          subtitle: '7 ביקורות',
                          color: AppColors.turquoise,
                          onTap: () => _showReviewsSheet(context),
                        ),
                        _MenuCard(
                          icon: Icons.apartment_outlined,
                          label: 'הנכסים שלי',
                          subtitle: 'מודעות שפרסמתם',
                          color: AppColors.midBlue,
                          onTap: () => context.push('/realestate'),
                        ),
                        const SizedBox(height: 8),
                        const Divider(color: AppColors.border),
                        const SizedBox(height: 8),
                        _MenuCard(
                          icon: Icons.help_outline,
                          label: 'עזרה ותמיכה',
                          color: AppColors.grayMeta,
                          onTap: () => context.push('/settings'),
                        ),
                        _MenuCard(
                          icon: Icons.info_outline,
                          label: 'אודות האפליקציה',
                          subtitle: 'גרסה 1.0.0',
                          color: AppColors.grayMeta,
                          onTap: () => _showAboutDialog(context),
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () {
                            ref.read(authProvider.notifier).logout();
                            context.go('/');
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                            ),
                            child: Center(
                              child: Text('התנתקות', style: GoogleFonts.rubik(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.error)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showReviewsSheet(BuildContext context) {
  final reviews = [
    ('מסעדת נאיתאי', 5.0, 'אוכל מעולה, שירות אדיב!'),
    ('קפה גרג', 4.0, 'קפה טוב, אווירה נעימה'),
    ('פיצה פרגו', 4.5, 'הפיצה הכי טובה במודיעין'),
    ('מספרת שיער חיים', 5.0, 'תספורת מושלמת, ממליץ בחום'),
    ('סופר יוחננוף', 3.5, 'מגוון רחב, מחירים סבירים'),
    ('חנות פרחים ורדים', 4.0, 'זרים יפים, משלוח מהיר'),
    ('מוסך רונן', 4.5, 'אמין ומקצועי'),
  ];
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        minChildSize: 0.3,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Column(
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 16),
                  Text('הביקורות שלי', style: GoogleFonts.rubik(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.navy)),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                itemCount: reviews.length,
                separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 24),
                itemBuilder: (_, i) {
                  final (name, rating, text) = reviews[i];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(name, style: GoogleFonts.rubik(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.navy))),
                          Row(children: List.generate(5, (s) => Icon(s < rating.round() ? Icons.star_rounded : Icons.star_outline_rounded, size: 16, color: AppColors.gold))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(text, style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showAboutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(gradient: AppColors.cyanGradient, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.location_city, color: AppColors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text('מודיעין בשבילך', style: GoogleFonts.rubik(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.navy))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('גרסה 1.0.0', style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.turquoise)),
            const SizedBox(height: 12),
            Text(
              'סופר-אפליקציה עירונית למודיעין-מכבים-רעות.\n\nעסקים, אירועים, חדשות, נדל"ן, שירותים עירוניים ועוד — הכל במקום אחד.',
              style: GoogleFonts.rubik(fontSize: 14, color: AppColors.grayText, height: 1.5),
            ),
            const SizedBox(height: 16),
            Text('© 2026 מודיעין בשבילך', style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayLight)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('סגירה', style: GoogleFonts.rubik(color: AppColors.turquoise, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    ),
  );
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatItem(this.value, this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.rubik(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.white)),
          Text(label, style: GoogleFonts.rubik(fontSize: 11, color: AppColors.white.withValues(alpha: 0.7))),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(this.icon, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(height: 6),
              Text(label, style: GoogleFonts.rubik(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.navy)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;
  const _MenuCard({required this.icon, required this.label, this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.rubik(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.navy)),
                  if (subtitle != null)
                    Text(subtitle!, style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayMeta)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.grayLight),
          ],
        ),
      ),
    );
  }
}
