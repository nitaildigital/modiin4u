import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/providers/auth_provider.dart';

class BrandHeader extends ConsumerWidget {
  final String? searchHint;
  final ValueChanged<String>? onSearch;

  const BrandHeader({
    super.key,
    this.searchHint,
    this.onSearch,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final isLoggedIn = user != null;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.brandGradient),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top bar: avatar + logo
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.push('/notifications'),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_outlined, color: AppColors.white, size: 20),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => isLoggedIn ? context.push('/profile') : context.push('/login'),
                    child: isLoggedIn
                        ? Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.white.withValues(alpha: 0.4), width: 2),
                            ),
                            child: Center(
                              child: Text(
                                user.initials,
                                style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.white),
                              ),
                            ),
                          )
                        : Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person_outline, color: AppColors.white, size: 20),
                          ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Headline
            Text(
              'כל מה שמודיעין מציעה,',
              style: GoogleFonts.rubik(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              'הכל במקום אחד',
              style: GoogleFonts.rubik(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 10),

            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'עסקים, חדשות, אירועים, נדל״ן ועוד — הכל בפלטפורמה עירונית חכמה אחת.',
                style: GoogleFonts.rubik(
                  fontSize: 14,
                  color: AppColors.white.withValues(alpha: 0.8),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 24),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 6)),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    const Icon(Icons.search, color: AppColors.grayLight, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        textDirection: TextDirection.rtl,
                        onSubmitted: onSearch,
                        style: GoogleFonts.rubik(fontSize: 14, color: AppColors.navy),
                        decoration: InputDecoration(
                          hintText: 'מה אתם מחפשים?',
                          hintTextDirection: TextDirection.rtl,
                          hintStyle: GoogleFonts.rubik(fontSize: 14, color: AppColors.grayLight),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        margin: const EdgeInsets.all(5),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D3B4F),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome, color: AppColors.white, size: 16),
                            const SizedBox(width: 6),
                            Text('שאלו', style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Category chips
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _HeroChip(Icons.store_outlined, 'עסקים', () => context.go('/businesses')),
                  const SizedBox(width: 8),
                  _HeroChip(Icons.article_outlined, 'חדשות', () => context.go('/news')),
                  const SizedBox(width: 8),
                  _HeroChip(Icons.map_outlined, 'מפה', () => context.go('/map')),
                  const SizedBox(width: 8),
                  _HeroChip(Icons.apartment_outlined, 'נדל"ן', () => context.go('/realestate')),
                  const SizedBox(width: 8),
                  _HeroChip(Icons.engineering_outlined, 'מקצוענים', () => context.go('/businesses')),
                  const SizedBox(width: 8),
                  _HeroChip(Icons.local_offer_outlined, 'הטבות', () => context.go('/deals')),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HeroChip(this.icon, this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.white),
            ),
          ],
        ),
      ),
    );
  }
}
