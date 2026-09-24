import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/month_names.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/router/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/error_retry.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../businesses/models/business.dart';
import '../../businesses/providers/business_providers.dart';
import '../../events/models/event.dart';
import '../../events/providers/event_providers.dart';
import '../../news/models/article.dart';
import '../../news/providers/news_providers.dart';
import 'web_home_screen.dart';
import '../../favorites/widgets/favorite_button.dart';
import '../../favorites/repositories/favorite_repository.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) {
          return const WebHomeContent();
        }
        return const _MobileHomeContent();
      },
    );
  }
}

class _MobileHomeContent extends ConsumerStatefulWidget {
  const _MobileHomeContent();

  @override
  ConsumerState<_MobileHomeContent> createState() => _MobileHomeContentState();
}

class _MobileHomeContentState extends ConsumerState<_MobileHomeContent> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _greeting(L l) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l.goodMorning;
    if (hour < 17) return l.goodAfternoon;
    return l.goodEvening;
  }

  void _onSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      context.push('/search?q=${Uri.encodeComponent(query)}');
      _searchController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final l = L.of(context);

    // A ListView rather than a Column in a SingleChildScrollView, so sections
    // below the fold are built as they are reached instead of all at once.
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // ── Gradient header ──
        _buildHeader(topPadding),

        const SizedBox(height: 20),

        // ── Explore Modiin ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            l.discoverModiin,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
        ),

        const SizedBox(height: 16),
        _buildCategoryRow(),

        const SizedBox(height: 24),

        // ── Popular Near You ──
        _SectionHeader(
          title: l.popularNearYou,
          onSeeAll: () => context.go('/businesses'),
        ),
        const SizedBox(height: 12),
        _buildPopularCards(),

        const SizedBox(height: 24),

        // ── Deal Near You ──
        _SectionHeader(
          title: l.dealsNearYou,
          onSeeAll: () => context.goOrPush('/deals'),
        ),
        const SizedBox(height: 12),
        _buildDealImages(),

        const SizedBox(height: 24),

        // ── Upcoming Events ──
        _SectionHeader(
          title: l.upcomingEvents,
          onSeeAll: () => context.goOrPush('/events'),
        ),
        const SizedBox(height: 12),
        _buildEventCards(l),

        const SizedBox(height: 24),

        // ── Apartment Near You ──
        _SectionHeader(
          title: l.apartmentsNearYou,
          onSeeAll: () => context.go('/realestate'),
        ),
        const SizedBox(height: 12),
        _buildApartmentList(),

        const SizedBox(height: 24),

        // ── Latest News ──
        _SectionHeader(
          title: l.latestNews,
          onSeeAll: () => context.go('/news'),
        ),
        const SizedBox(height: 12),
        _buildNewsCards(l),

        const SizedBox(height: 32),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Header with gradient + search bar
  // ─────────────────────────────────────────────
  Widget _buildHeader(double topPadding) {
    final l = L.of(context);
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF010A36), Color(0xFF0058B5)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: topPadding + 6),

          // Top row: hamburger menu (right side)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => context.push('/profile'),
                  child: const Icon(
                    IconsaxPlusLinear.menu,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Greeting text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(l),
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l.whatAreYouLookingFor,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Icon(
                    IconsaxPlusLinear.search_normal_1,
                    color: Color(0xFF6D6D6D),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: (_) => _onSearch(),
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 14,
                        color: const Color(0xFF1F1F1F),
                      ),
                      decoration: InputDecoration(
                        hintText: l.searchPlaceholder,
                        hintStyle: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF6D6D6D),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 13,
                        ),
                      ),
                    ),
                  ),
                  // Ask button
                  GestureDetector(
                    onTap: _onSearch,
                    child: Container(
                      margin: const EdgeInsets.all(5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment(-0.5, -0.5),
                          end: Alignment(0.8, 0.8),
                          colors: [Color(0xFF010928), Color(0xFF00C4DC)],
                        ),
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            IconsaxPlusBold.magic_star,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'שאל',
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Category icons (Restaurants, Events, Real Estate, Deals)
  // ─────────────────────────────────────────────
  Widget _buildCategoryRow() {
    final categories = [
      ('מסעדות', IconsaxPlusLinear.reserve, '/restaurants'),
      ('אירועים', IconsaxPlusLinear.calendar, '/events'),
      ('נדל"ן', IconsaxPlusLinear.house_2, '/realestate'),
      ('חדשות', IconsaxPlusLinear.note, '/news'),
      ('מבצעים', IconsaxPlusLinear.discount_shape, '/deals'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: categories.map((cat) {
          final (label, icon, route) = cat;
          return Expanded(
            child: GestureDetector(
              onTap: () => context.goOrPush(route),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0x26146DDF),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 24, color: const Color(0xFF146DDF)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF3D3D3D),
                      height: 1.0,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Popular Near You — horizontal business cards
  // ─────────────────────────────────────────────

  Widget _buildPopularCards() => _ProviderRow<Business>(
    provider: businessesProvider,
    height: 282,
    gap: 12,
    card: _businessCard,
    skeleton: _businessCardSkeleton,
  );

  // ─────────────────────────────────────────────
  // Deal Near You — horizontal deal banner images
  // ─────────────────────────────────────────────
  Widget _buildDealImages() {
    final dealColors = [
      [const Color(0xFFE92C04), const Color(0xFFFCC311)],
      [const Color(0xFF0058B5), const Color(0xFF17A9D0)],
      [const Color(0xFF31AC4E), const Color(0xFF43E97B)],
    ];
    final dealLabels = [
      '20% Off All Pizzas',
      'Buy 1 Get 1 Free',
      'Summer Special',
    ];

    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, index) {
          return GestureDetector(
            onTap: () => context.push('/deal/demo_$index'),
            child: Container(
              width: 230,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: dealColors[index],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  dealLabels[index],
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Upcoming Events — horizontal event cards
  // ─────────────────────────────────────────────
  Widget _buildEventCards(L l) => _ProviderRow<Event>(
    provider: upcomingEventsProvider,
    height: 272,
    gap: 12,
    card: (e) => _eventCard(e, l),
    skeleton: _eventCardSkeleton,
  );

  // ─────────────────────────────────────────────
  // Apartment Near You — vertical list
  // ─────────────────────────────────────────────
  Widget _buildApartmentList() {
    final apartments = [
      _ApartmentData(
        price: '₪3,650,000',
        address: '3 Yona Hanavi Street, Modiin',
        area: '140 m²',
        rooms: '6 Rooms',
      ),
      _ApartmentData(
        price: '₪3,790,000',
        address: '84 Menachem Begin Road',
        area: '140 m²',
        rooms: '6 Rooms',
      ),
      _ApartmentData(
        price: '₪5,690,000',
        address: '73 Sarah Amano Street',
        area: '140 m²',
        rooms: '6 Rooms',
      ),
      _ApartmentData(
        price: '₪5,690,000',
        address: '73 Sarah Amano Street',
        area: '140 m²',
        rooms: '6 Rooms',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: apartments.asMap().entries.map((entry) {
          return GestureDetector(
            onTap: () => context.push('/listing/demo_${entry.key}'),
            child: _ApartmentRow(data: entry.value),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Latest News — horizontal news cards
  // ─────────────────────────────────────────────
  Widget _buildNewsCards(L l) => _ProviderRow<Article>(
    provider: publishedArticlesProvider,
    height: 240,
    gap: 20,
    card: (a) => _newsCard(a, l),
    skeleton: _newsCardSkeleton,
  );
}

// ═══════════════════════════════════════════════
// Section header
// ═══════════════════════════════════════════════
/// Placeholders built to the exact geometry of the cards below them: same
/// widths, image sizes, gaps and corner radii, so the row does not jump.
Widget _businessCardSkeleton() => const _CardFrame(
      width: 270,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 252, height: 140),
          SizedBox(height: 10),
          SkeletonLine(width: 170, fontSize: 16),
          SizedBox(height: 8),
          SkeletonLine(width: 210, fontSize: 12),
          SizedBox(height: 8),
          Row(
            children: [
              SkeletonBox(width: 54, height: 18, radius: 50),
              Spacer(),
              SkeletonLine(width: 64, fontSize: 12),
            ],
          ),
        ],
      ),
    );

Widget _eventCardSkeleton() => const _CardFrame(
      width: 270,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 252, height: 140),
          SizedBox(height: 10),
          SkeletonLine(width: 180, fontSize: 16),
          SizedBox(height: 10),
          SkeletonLine(width: 130, fontSize: 12),
          SizedBox(height: 8),
          SkeletonLine(width: 96, fontSize: 12),
        ],
      ),
    );

Widget _newsCardSkeleton() => const SizedBox(
      width: 250,
      child: Skeleton(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 250, height: 150, radius: 12),
            SizedBox(height: 12),
            SkeletonLine(width: 250, fontSize: 16),
            SizedBox(height: 7),
            SkeletonLine(width: 190, fontSize: 16),
            SizedBox(height: 12),
            SkeletonLine(width: 150, fontSize: 14),
          ],
        ),
      ),
    );

/// The card chrome stays solid while its contents shimmer — a shimmering
/// border reads as a glitch rather than as loading.
class _CardFrame extends StatelessWidget {
  final double width;
  final Widget child;

  const _CardFrame({required this.width, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE7E7E7)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Skeleton(child: child),
    );
  }
}

Widget _businessCard(Business b) => _BusinessCard(data: _BusinessData.from(b));
// Dates are formatted here rather than inside the data classes: a factory
// has no BuildContext, so a month name written there would stay Hebrew with
// the app set to English.
Widget _eventCard(Event e, L l) => _EventCard(data: _EventData.from(e, l));
Widget _newsCard(Article a, L l) => _NewsCard(data: _NewsData.from(a, l));

/// One horizontal row driven by a single provider.
///
/// This is a widget rather than a method on the page so that a change in one
/// row rebuilds only that row, instead of the whole home screen.
class _ProviderRow<T> extends ConsumerWidget {
  final ProviderListenable<AsyncValue<List<T>>> provider;
  final double height;
  final double gap;
  final Widget Function(T item) card;

  /// The placeholder for one card. Built to the same geometry as [card] so
  /// nothing shifts when the real content arrives.
  final Widget Function() skeleton;

  const _ProviderRow({
    required this.provider,
    required this.height,
    required this.gap,
    required this.card,
    required this.skeleton,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: height,
      child: ref
          .watch(provider)
          .when(
            loading: () => ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              separatorBuilder: (_, _) => SizedBox(width: gap),
              itemBuilder: (_, _) => skeleton(),
            ),
            error: (_, _) => ErrorRetry(
              onRetry: () => ref.invalidate(provider as ProviderOrFamily),
            ),
            data: (items) => items.isEmpty
                ? const SizedBox.shrink()
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => SizedBox(width: gap),
                    itemBuilder: (_, i) => card(items[i]),
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                L.of(context).seeAll,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.midBlue,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Business card data + widget
// ═══════════════════════════════════════════════

/// Cards have no photography of their own yet, so each one takes a stable
/// colour from its id — the same row always looks the same.
const _cardGradients = <List<Color>>[
  [Color(0xFF8B6914), Color(0xFFC49B2C)],
  [Color(0xFF2D6A4F), Color(0xFF40916C)],
  [Color(0xFF1A4B6E), Color(0xFF2980B9)],
  [Color(0xFF5B2C6F), Color(0xFF8E44AD)],
  [Color(0xFF7B341E), Color(0xFFC0563A)],
  [Color(0xFF0F5257), Color(0xFF17A9D0)],
];

List<Color> _gradientFor(String id) =>
    _cardGradients[id.hashCode.abs() % _cardGradients.length];

class _BusinessData {
  final String id;
  final String? imageUrl;
  final String name;
  final String address;
  final double rating;
  final int reviews;
  final String type;
  final Color typeColor;
  final bool isKosher;
  final List<Color> gradientColors;

  const _BusinessData({
    required this.id,
    this.imageUrl,
    required this.name,
    required this.address,
    required this.rating,
    required this.reviews,
    required this.type,
    required this.typeColor,
    required this.isKosher,
    required this.gradientColors,
  });

  factory _BusinessData.from(Business b) => _BusinessData(
    id: b.id,
    imageUrl: b.imageUrl,
    name: b.name,
    address: [b.address, b.neighborhood].where((s) => s.isNotEmpty).join(', '),
    rating: b.rating,
    reviews: b.reviewCount,
    type: b.category.isNotEmpty ? b.category : (b.description ?? ''),
    typeColor: const Color(0xFF006BF6),
    isKosher: b.kosherLabel != null,
    gradientColors: _gradientFor(b.id),
  );
}

class _BusinessCard extends StatelessWidget {
  final _BusinessData data;

  const _BusinessCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/business/${data.id}'),
      child: Container(
        width: 270,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE7E7E7)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            Stack(
              children: [
                NetworkPhoto(
                  url: data.imageUrl,
                  width: 252,
                  height: 140,
                  radius: BorderRadius.circular(8),
                  gradient: data.gradientColors,
                  icon: Icons.storefront_outlined,
                  iconSize: 40,
                ),
                // Favorite button
                Positioned(
                  right: 8,
                  top: 8,
                  child: FavoriteButton(
                    kind: FavoriteKind.business,
                    id: data.id,
                  ),
                ),
                // Kosher badge
                if (data.isKosher)
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0033AC),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            IconsaxPlusBold.verify,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Kosher',
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // Name
            Text(
              data.name,
              style: TextStyle(
                fontFamily: AppFonts.rubik,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 8),

            // Address
            Row(
              children: [
                const Icon(
                  IconsaxPlusLinear.location,
                  size: 14,
                  color: Color(0xFF6D6D6D),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    data.address,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 12,
                      color: const Color(0xFF6D6D6D),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Rating + type badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Rating
                Row(
                  children: [
                    const Icon(
                      IconsaxPlusBold.star_1,
                      size: 14,
                      color: Color(0xFFFFC107),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      data.rating.toString(),
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${data.reviews})',
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 12,
                        color: const Color(0xFF6D6D6D),
                      ),
                    ),
                  ],
                ),
                // Business type badge. The label is the shop's own
                // description, which runs longer than the placeholder did, so
                // it takes what room is left rather than pushing the card.
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: data.typeColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      data.type,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Event card data + widget
// ═══════════════════════════════════════════════
class _EventData {
  final String id;
  final String? imageUrl;
  final String name;
  final String category;
  final String location;
  final String time;
  final String price;
  final Color priceColor;
  final String month;
  final String day;
  final List<Color> gradientColors;

  const _EventData({
    required this.id,
    this.imageUrl,
    required this.name,
    required this.category,
    required this.location,
    required this.time,
    required this.price,
    required this.priceColor,
    required this.month,
    required this.day,
    required this.gradientColors,
  });


  factory _EventData.from(Event e, L l) {
    final start = e.startDate;
    return _EventData(
      id: e.id,
      imageUrl: e.imageUrl,
      name: e.title,
      category: '',
      location: e.venueName ?? e.address,
      time: e.displayTime ?? '',
      price: e.displayPrice ?? '',
      priceColor: e.isFree ? const Color(0xFF31AC4E) : Colors.black,
      month: start == null ? '' : l.monthShort(start.month),
      day: '${start?.day ?? ''}',
      gradientColors: _gradientFor(e.id),
    );
  }
}

class _EventCard extends StatelessWidget {
  final _EventData data;

  const _EventCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/event/${data.id}'),
      child: Container(
        width: 270,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE7E7E7)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area with date badge
            Stack(
              children: [
                NetworkPhoto(
                  url: data.imageUrl,
                  width: 252,
                  height: 140,
                  radius: BorderRadius.circular(8),
                  gradient: data.gradientColors,
                  icon: Icons.event,
                  iconSize: 40,
                ),
                // Date badge
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: Container(
                    width: 57,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          data.month,
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.midBlue,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data.day,
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                // Favorite button
                Positioned(
                  right: 8,
                  top: 8,
                  child: FavoriteButton(
                    kind: FavoriteKind.event,
                    id: data.id,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Name
            Text(
              data.name,
              style: TextStyle(
                fontFamily: AppFonts.rubik,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 4),

            // Category
            Text(
              data.category,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 12,
                color: const Color(0xFF6D6D6D),
              ),
            ),

            const SizedBox(height: 8),

            // Location + time row with price
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Color(0xFF6D6D6D),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              data.location,
                              style: TextStyle(
                                fontFamily: AppFonts.inter,
                                fontSize: 12,
                                color: const Color(0xFF6D6D6D),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            IconsaxPlusLinear.clock,
                            size: 14,
                            color: Color(0xFF6D6D6D),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            data.time,
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 12,
                              color: const Color(0xFF6D6D6D),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Price
                Text(
                  data.price,
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: data.priceColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Apartment data + row widget
// ═══════════════════════════════════════════════
class _ApartmentData {
  final String price;
  final String address;
  final String area;
  final String rooms;

  const _ApartmentData({
    required this.price,
    required this.address,
    required this.area,
    required this.rooms,
  });
}

class _ApartmentRow extends StatelessWidget {
  final _ApartmentData data;

  const _ApartmentRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE7E7E7))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Container(
            width: 95,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFBDC3C7), Color(0xFF95A5A6)],
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Center(
              child: Icon(Icons.apartment, size: 28, color: Colors.white),
            ),
          ),

          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Price + FOR SALE
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      data.price,
                      style: TextStyle(
                        fontFamily: AppFonts.rubik,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                    ),
                    Text(
                      'FOR SALE',
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.turquoise,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 9),

                // Address
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Color(0xFF6D6D6D),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        data.address,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 12,
                          color: const Color(0xFF6D6D6D),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 9),

                // Area + Rooms
                Row(
                  children: [
                    const Icon(
                      IconsaxPlusLinear.maximize_4,
                      size: 14,
                      color: Color(0xFF6D6D6D),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      data.area,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 12,
                        color: const Color(0xFF6D6D6D),
                      ),
                    ),
                    const SizedBox(width: 31),
                    const Icon(
                      IconsaxPlusLinear.house_2,
                      size: 14,
                      color: Color(0xFF6D6D6D),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      data.rooms,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 12,
                        color: const Color(0xFF6D6D6D),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// News card data + widget
// ═══════════════════════════════════════════════
class _NewsData {
  final String id;
  final String? imageUrl;
  final String title;
  final String date;
  final List<Color> gradientColors;

  const _NewsData({
    required this.id,
    this.imageUrl,
    required this.title,
    required this.date,
    required this.gradientColors,
  });


  factory _NewsData.from(Article a, L l) {
    final d = a.publishedAt;
    final time =
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
    return _NewsData(
      id: a.id,
      imageUrl: a.imageUrl,
      title: a.title,
      date: '${d.day} ${l.monthLong(d.month)} ${d.year} | $time',
      gradientColors: _gradientFor(a.id),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final _NewsData data;

  const _NewsCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/article/${data.id}'),
      child: SizedBox(
        width: 250,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            NetworkPhoto(
              url: data.imageUrl,
              width: 250,
              height: 150,
              radius: BorderRadius.circular(12),
              gradient: data.gradientColors,
              icon: Icons.article,
              iconSize: 36,
            ),

            const SizedBox(height: 12),

            // Title
            Text(
              data.title,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
                height: 1.19,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Date
            Row(
              children: [
                const Icon(
                  IconsaxPlusLinear.calendar_1,
                  size: 16,
                  color: Color(0xFF888888),
                ),
                const SizedBox(width: 8),
                Text(
                  data.date,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 14,
                    color: const Color(0xFF6D6D6D),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
