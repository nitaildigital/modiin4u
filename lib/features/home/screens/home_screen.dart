import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/brand_header.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../widgets/category_row.dart';
import '../widgets/news_preview.dart';
import '../widgets/municipal_alert_strip.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  Future<void> _onRefresh() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        color: const Color(0xFF17A9D0),
        child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: BrandHeader(
              searchHint: 'חפשו עסק, מסעדה, שירות...',
              onSearch: (query) {
                if (query.trim().isNotEmpty) {
                  context.push('/search?q=${Uri.encodeComponent(query.trim())}');
                }
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          const SliverToBoxAdapter(child: CategoryRow()),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          const SliverToBoxAdapter(child: MunicipalAlertStrip()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(
            child: _SectionHeader(
              title: 'חדשות אחרונות',
              onSeeAll: () => context.go('/news'),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          if (_isLoading) ...[
            const SliverToBoxAdapter(child: ShimmerLoading(type: ShimmerType.carousel, itemCount: 3)),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            const SliverToBoxAdapter(child: ShimmerLoading(type: ShimmerType.carousel, itemCount: 3)),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            const SliverToBoxAdapter(child: ShimmerLoading(type: ShimmerType.card, itemCount: 2)),
          ] else ...[
            const SliverToBoxAdapter(child: NewsPreview()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'מומלץ בשבילך',
                onSeeAll: () => context.go('/businesses'),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            SliverToBoxAdapter(child: _RecommendedBusinesses()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'אירועים קרובים',
                onSeeAll: () => context.go('/events'),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            SliverToBoxAdapter(child: _UpcomingEvents()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'הטבות חמות',
                onSeeAll: () => context.go('/deals'),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            SliverToBoxAdapter(child: _HotDeals()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(child: _QuickAccessGrid()),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.rubik(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                'הכל',
                style: GoogleFonts.rubik(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.turquoise,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UpcomingEvents extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final events = [
      ('פסטיבל אוכל רחוב', 'יום ה׳ 14.08', 'פארק ענבה', Icons.restaurant),
      ('הופעה — עידן רייכל', 'שבת 16.08', 'היכל התרבות', Icons.music_note),
      ('שוק קהילתי', 'יום ו׳ 15.08', 'כיכר המייסדים', Icons.storefront),
    ];

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: events.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final (title, date, location, icon) = events[index];
          return GestureDetector(
            onTap: () => context.push('/event/demo_$index'),
            child: Container(
              width: 220,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: context.isDark ? Colors.black26 : AppColors.cardShadow, blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: context.surfaceDim,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, size: 18, color: AppColors.turquoise),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(date, style: GoogleFonts.rubik(fontSize: 12, color: AppColors.turquoise, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(location, style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayMeta)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HotDeals extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final deals = [
      ('20% הנחה', 'פיצה פרגו', 'עד סוף השבוע'),
      ('1+1 קפה', 'קפה גרג', 'לתושבים בלבד'),
      ('חינם — שיעור ראשון', 'סטודיו פילאטיס', 'מוגבל'),
    ];

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: deals.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final (discount, business, expiry) = deals[index];
          return GestureDetector(
            onTap: () => context.push('/deal/demo_$index'),
            child: Container(
              width: 200,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: context.isDark ? Colors.black26 : AppColors.cardShadow, blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(discount, style: GoogleFonts.rubik(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.white)),
                  ),
                  const Spacer(),
                  Text(business, style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary)),
                  const SizedBox(height: 2),
                  Text(expiry, style: GoogleFonts.rubik(fontSize: 11, color: AppColors.grayMeta)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuickAccessGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      ('קהילה', Icons.people_outline, '/community', AppColors.turquoise),
      ('נדל"ן', Icons.apartment_outlined, '/realestate', AppColors.midBlue),
      ('משחקים', Icons.sports_esports_outlined, '/games', AppColors.gold),
      ('צעדים', Icons.directions_walk_outlined, '/steps', AppColors.success),
      ('חניה', Icons.local_parking_outlined, '/parking', AppColors.midBlue),
      ('כניסה', Icons.person_outline, '/login', AppColors.turquoise),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('גישה מהירה', style: GoogleFonts.rubik(fontSize: 18, fontWeight: FontWeight.w700, color: context.textPrimary)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: items.map((item) {
              final (label, icon, route, color) = item;
              return GestureDetector(
                onTap: () => context.push(route),
                child: Container(
                  decoration: BoxDecoration(
                    color: context.surfaceDim,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.borderClr, width: 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: color, size: 26),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        style: GoogleFonts.rubik(fontSize: 12, fontWeight: FontWeight.w500, color: context.textPrimary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _RecommendedBusinesses extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final names = [
            'מסעדת נאיתאי',
            'פיצה פרגו',
            'קפה גרג',
            'בורגרס בר',
            'סושי מודיעין'
          ];
          final categories = ['תאילנדי', 'פיצה', 'בית קפה', 'המבורגרים', 'סושי'];
          return GestureDetector(
            onTap: () => context.push('/business/demo_$index'),
            child: Container(
              width: 160,
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: context.isDark ? Colors.black26 : AppColors.cardShadow, blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: context.surfaceDim,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(14),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.restaurant,
                        size: 36,
                        color: AppColors.midBlue.withValues(alpha: 0.25),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          names[index],
                          style: GoogleFonts.rubik(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          categories[index],
                          style: GoogleFonts.rubik(
                            fontSize: 12,
                            color: AppColors.grayMeta,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'פתוח',
                                style: GoogleFonts.rubik(
                                  fontSize: 11,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.star_rounded, size: 14, color: AppColors.gold),
                            const SizedBox(width: 2),
                            Text(
                              '4.${5 + index % 4}',
                              style: GoogleFonts.rubik(
                                fontSize: 12,
                                color: AppColors.grayMeta,
                              ),
                            ),
                          ],
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
    );
  }
}
