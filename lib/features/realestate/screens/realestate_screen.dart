import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

class RealEstateScreen extends ConsumerStatefulWidget {
  const RealEstateScreen({super.key});

  @override
  ConsumerState<RealEstateScreen> createState() => _RealEstateScreenState();
}

class _RealEstateScreenState extends ConsumerState<RealEstateScreen> {
  int _searchToggle = 0;
  int _recentToggle = 0;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  static const _allRentListings = [
    (id: 'rent_0', price: '5,500 ₪', neighborhood: 'שכונת הנחלים', rooms: 3, sqm: 85, floor: 2, broker: true),
    (id: 'rent_1', price: '7,200 ₪', neighborhood: 'אבני חן', rooms: 4, sqm: 110, floor: 4, broker: false),
    (id: 'rent_2', price: '5,800 ₪', neighborhood: 'מרכז העיר', rooms: 3, sqm: 90, floor: 1, broker: true),
    (id: 'rent_3', price: '9,500 ₪', neighborhood: 'נופים', rooms: 5, sqm: 130, floor: 6, broker: false),
    (id: 'rent_4', price: '6,800 ₪', neighborhood: 'הכרמים', rooms: 4, sqm: 105, floor: 3, broker: true),
    (id: 'rent_5', price: '6,200 ₪', neighborhood: 'מוריה', rooms: 3, sqm: 95, floor: 5, broker: false),
  ];

  static const _allSaleListings = [
    (id: 'sale_0', price: '2,450,000 ₪', neighborhood: 'הפרחים', rooms: 4, sqm: 110, floor: 3, broker: false),
    (id: 'sale_1', price: '3,100,000 ₪', neighborhood: 'אבני חן', rooms: 5, sqm: 140, floor: 7, broker: true),
    (id: 'sale_2', price: '1,950,000 ₪', neighborhood: 'המע"ר', rooms: 3, sqm: 85, floor: 2, broker: false),
    (id: 'sale_3', price: '4,200,000 ₪', neighborhood: 'נופים', rooms: 6, sqm: 180, floor: 0, broker: true),
    (id: 'sale_4', price: '3,800,000 ₪', neighborhood: 'מוריה', rooms: 5, sqm: 160, floor: 12, broker: false),
    (id: 'sale_5', price: '2,700,000 ₪', neighborhood: 'הנחלים', rooms: 4, sqm: 120, floor: 5, broker: true),
  ];

  static const _projects = [
    (name: 'פרוייקט "דמארי"', price: 'החל מ - 1,900,000 ₪'),
    (name: 'אביב מודיעין', price: 'החל מ - 2,200,000 ₪'),
    (name: 'פסגות הפארק', price: 'החל מ - 2,500,000 ₪'),
  ];

  static const _neighborhoods = [
    'הנחלים', 'אבני חן', 'נופים', 'המע"ר', 'הכרמים', 'מוריה', 'הפרחים', 'משואה',
  ];

  static const _placeholderColors = [
    Color(0xFFE8F4FD), Color(0xFFFCE4EC), Color(0xFFE8F5E9), Color(0xFFF3E5F5),
    Color(0xFFFFF8E1), Color(0xFFE0F2F1), Color(0xFFEDE7F6), Color(0xFFFFF3E0),
  ];

  List<({String id, String price, String neighborhood, int rooms, int sqm, int floor, bool broker})> _filter(
    List<({String id, String price, String neighborhood, int rooms, int sqm, int floor, bool broker})> listings,
  ) {
    if (_searchQuery.isEmpty) return listings;
    return listings.where((l) => l.neighborhood.contains(_searchQuery)).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final favoriteIds = user?.favoriteListingIds ?? [];
    final rentFiltered = _filter(_allRentListings);
    final saleFiltered = _filter(_allSaleListings);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.scaffoldBg,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async { await Future.delayed(const Duration(milliseconds: 800)); },
            color: AppColors.turquoise,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildHeroBanner(),
              const SizedBox(height: 16),
              _buildSearchBar(),
              const SizedBox(height: 14),
              _buildCategoryFilters(),
              if (_searchToggle != 0) ...[
                const SizedBox(height: 24),
                _buildSectionHeader('דירות להשכרה במודיעין', 'לכל הדירות'),
                const SizedBox(height: 12),
                rentFiltered.isEmpty
                    ? _buildEmptyState('לא נמצאו דירות להשכרה')
                    : _buildListingCarousel(rentFiltered, true, favoriteIds),
              ],
              if (_searchToggle != 1) ...[
                const SizedBox(height: 24),
                _buildSectionHeader('דירות למכירה במודיעין', 'לכל הדירות'),
                const SizedBox(height: 12),
                saleFiltered.isEmpty
                    ? _buildEmptyState('לא נמצאו דירות למכירה')
                    : _buildListingCarousel(saleFiltered, false, favoriteIds),
              ],
              const SizedBox(height: 28),
              _buildSectionHeader('פרוייקטים חדשים', null),
              const SizedBox(height: 12),
              _buildProjectsCarousel(),
              const SizedBox(height: 28),
              _buildRecentToggle(),
              const SizedBox(height: 14),
              _buildCompactList(favoriteIds),
              const SizedBox(height: 28),
              _buildSectionHeader('באיזו שכונה בא לכם לגור?', null),
              const SizedBox(height: 12),
              _buildNeighborhoodsRow(),
              const SizedBox(height: 28),
              _buildArticlesSection(),
              const SizedBox(height: 100),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: Text(message, style: GoogleFonts.rubik(fontSize: 14, color: AppColors.grayMeta)),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
            decoration: const BoxDecoration(gradient: AppColors.cyanGradient),
            child: Column(
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: const [
                    _FeaturePill('מעלית', Icons.elevator_outlined),
                    _FeaturePill('חניה', Icons.local_parking_outlined),
                    _FeaturePill('ממ"ד', Icons.shield_outlined),
                    _FeaturePill('מחסן', Icons.warehouse_outlined),
                    _FeaturePill('שירותים', Icons.bathroom_outlined),
                    _FeaturePill('קומה', Icons.stairs_outlined),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'מצאו את הנכס המושלם',
                  style: GoogleFonts.rubik(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'דירות, פרוייקטים חדשים ונכסים מסחריים',
                  style: GoogleFonts.rubik(fontSize: 13, color: AppColors.white.withValues(alpha: 0.85)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: 16 / 7,
            child: Image.network(
              'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=800&q=80',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.surfaceLight,
                child: Center(child: Icon(Icons.apartment, size: 48, color: AppColors.midBlue.withValues(alpha: 0.15))),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFEDEDED).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(50),
            ),
            child: TextField(
              controller: _searchController,
              textDirection: TextDirection.rtl,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'חיפוש לפי שכונה',
                hintTextDirection: TextDirection.rtl,
                hintStyle: GoogleFonts.rubik(fontSize: 14, color: AppColors.grayLight),
                prefixIcon: const Icon(Icons.search, color: AppColors.grayLight, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18, color: AppColors.grayMeta),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildTogglePill('למכירה', 0),
              const SizedBox(width: 8),
              _buildTogglePill('להשכרה', 1),
              const SizedBox(width: 8),
              _buildTogglePill('הכל', 2),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTogglePill(String label, int index) {
    final isActive = _searchToggle == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _searchToggle = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: isActive ? AppColors.cyanGradient : null,
            color: isActive ? null : AppColors.inactiveTabBg,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.rubik(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? AppColors.white : AppColors.grayMeta,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    final categories = [
      (label: 'העלאת מודעה', isGradient: true),
      (label: 'פרויקטים חדשים', isGradient: false),
      (label: 'מסחרי להשכרה', isGradient: false),
      (label: 'מסחרי למכירה', isGradient: false),
      (label: 'דירות למכירה', isGradient: false),
      (label: 'דירות להשכרה', isGradient: false),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final cat = categories[index];
          if (cat.isGradient) {
            return GestureDetector(
              onTap: () => context.push('/new-listing'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: AppColors.cyanGradient,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, size: 16, color: AppColors.white),
                    const SizedBox(width: 6),
                    Text(cat.label, style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.white)),
                  ],
                ),
              ),
            );
          }
          return GestureDetector(
            onTap: () {
              if (cat.label.contains('להשכרה')) {
                setState(() => _searchToggle = 1);
              } else if (cat.label.contains('למכירה')) {
                setState(() => _searchToggle = 0);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: AppColors.filterBorderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(cat.label, style: GoogleFonts.rubik(fontSize: 13, color: context.textPrimary)),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.grayMeta),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, String? actionLabel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: GoogleFonts.rubik(fontSize: 18, fontWeight: FontWeight.w700, color: context.textPrimary)),
          ),
          if (actionLabel != null)
            GestureDetector(
              onTap: () {},
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(actionLabel, style: GoogleFonts.rubik(fontSize: 13, color: AppColors.turquoise, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_back, size: 14, color: AppColors.turquoise),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildListingCarousel(
    List<({String id, String price, String neighborhood, int rooms, int sqm, int floor, bool broker})> listings,
    bool isRent,
    List<String> favoriteIds,
  ) {
    return SizedBox(
      height: 270,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: listings.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final listing = listings[index];
          final isFav = favoriteIds.contains(listing.id);
          return GestureDetector(
            onTap: () => context.push('/listing/${listing.id}'),
            child: _PropertyCard(
              listing: listing,
              isRent: isRent,
              isFavorite: isFav,
              onFavoriteTap: () => _toggleFavorite(listing.id),
              color: _placeholderColors[index % _placeholderColors.length],
            ),
          );
        },
      ),
    );
  }

  void _toggleFavorite(String id) {
    final user = ref.read(authProvider);
    if (user == null) {
      context.push('/login');
      return;
    }
    ref.read(authProvider.notifier).toggleFavoriteListing(id);
  }

  Widget _buildProjectsCarousel() {
    const colors = [Color(0xFF2C3E50), Color(0xFF1A237E), Color(0xFF004D40)];
    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _projects.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, index) {
          final project = _projects[index];
          return Container(
            width: 280,
            decoration: BoxDecoration(
              color: colors[index % colors.length],
              borderRadius: BorderRadius.circular(30),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                      ),
                    ),
                  ),
                ),
                Center(child: Icon(Icons.domain, size: 60, color: AppColors.white.withValues(alpha: 0.15))),
                Positioned(
                  bottom: 20, right: 20, left: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(project.name, style: GoogleFonts.rubik(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.white)),
                      const SizedBox(height: 4),
                      Text(project.price, style: GoogleFonts.rubik(fontSize: 16, color: AppColors.white.withValues(alpha: 0.9))),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildRecentToggleButton('החדשים', 0),
          const SizedBox(width: 8),
          _buildRecentToggleButton('נצפים ביותר', 1),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildRecentToggleButton(String label, int index) {
    final isActive = _recentToggle == index;
    return GestureDetector(
      onTap: () => setState(() => _recentToggle = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: isActive ? AppColors.cyanGradient : null,
          color: isActive ? null : AppColors.inactiveTabBg,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          label,
          style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w600, color: isActive ? AppColors.white : AppColors.grayMeta),
        ),
      ),
    );
  }

  Widget _buildCompactList(List<String> favoriteIds) {
    final compactListings = _filter(_recentToggle == 0 ? _allSaleListings : _allRentListings);
    if (compactListings.isEmpty) return _buildEmptyState('לא נמצאו תוצאות');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(
          compactListings.length > 4 ? 4 : compactListings.length,
          (index) {
            final listing = compactListings[index];
            final isFav = favoriteIds.contains(listing.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => context.push('/listing/${listing.id}'),
                child: _CompactCard(
                  listing: listing,
                  isRent: _recentToggle == 1,
                  isFavorite: isFav,
                  onFavoriteTap: () => _toggleFavorite(listing.id),
                  color: _placeholderColors[(index + 2) % _placeholderColors.length],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNeighborhoodsRow() {
    const neighborhoodColors = [
      Color(0xFFE3F2FD), Color(0xFFF3E5F5), Color(0xFFE8F5E9), Color(0xFFFFF3E0),
      Color(0xFFE0F7FA), Color(0xFFFCE4EC), Color(0xFFF1F8E9), Color(0xFFEDE7F6),
    ];
    return SizedBox(
      height: 155,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _neighborhoods.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, index) {
          return GestureDetector(
            onTap: () {
              _searchController.text = _neighborhoods[index];
              setState(() {
                _searchQuery = _neighborhoods[index];
                _searchToggle = 2;
              });
            },
            child: Container(
              width: 140,
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.borderClr),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: neighborhoodColors[index % neighborhoodColors.length],
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                      ),
                      child: Center(child: Icon(Icons.location_city, size: 36, color: AppColors.midBlue.withValues(alpha: 0.25))),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(_neighborhoods[index], style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildArticlesSection() {
    const articles = [
      (id: 'realestate_1', title: 'איך לבחור שכונה במודיעין?', subtitle: 'המדריך המלא לרוכשי דירה ראשונה'),
      (id: 'realestate_2', title: '5 טיפים למשכנתא חכמה', subtitle: 'מה חשוב לדעת לפני שלוקחים הלוואה'),
      (id: 'realestate_3', title: 'פרוייקטים חדשים 2026', subtitle: 'סקירה מקיפה של הפרוייקטים העתידיים'),
    ];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.sectionBg, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('כתבות ומדריכים', style: GoogleFonts.rubik(fontSize: 18, fontWeight: FontWeight.w700, color: context.textPrimary)),
          const SizedBox(height: 14),
          ...articles.map((article) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => context.push('/article/${article.id}'),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: context.cardBg, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.turquoise.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.article_outlined, size: 24, color: AppColors.turquoise.withValues(alpha: 0.5)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(article.title, style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(article.subtitle, style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayMeta), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_back_ios, size: 14, color: AppColors.grayLight),
                  ],
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  final ({String id, String price, String neighborhood, int rooms, int sqm, int floor, bool broker}) listing;
  final bool isRent;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;
  final Color color;

  const _PropertyCard({
    required this.listing,
    required this.isRent,
    required this.isFavorite,
    required this.onFavoriteTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 175,
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.borderClr),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 130,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
                  ),
                  child: Center(child: Icon(Icons.apartment, size: 40, color: AppColors.midBlue.withValues(alpha: 0.15))),
                ),
                Positioned(
                  top: 10, right: 10,
                  child: GestureDetector(
                    onTap: onFavoriteTap,
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6)],
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: isFavorite ? AppColors.error : AppColors.grayMeta,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(listing.price, style: GoogleFonts.rubik(fontSize: 15, fontWeight: FontWeight.w700, color: context.textPrimary)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _Badge(isRent ? 'להשכרה' : 'למכירה', AppColors.rentBadgeBg, AppColors.grayText),
                    const SizedBox(width: 4),
                    if (listing.broker) const _Badge('תיווך', AppColors.brokerBadgeBg, AppColors.turquoise),
                  ],
                ),
                const SizedBox(height: 6),
                Text(listing.neighborhood, style: GoogleFonts.rubik(fontSize: 11, color: AppColors.grayMeta), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _SpecPill(Icons.stairs, listing.floor > 0 ? 'קומה ${listing.floor}' : 'קרקע'),
                    const SizedBox(width: 4),
                    _SpecPill(Icons.square_foot, '${listing.sqm} מ"ר'),
                    const SizedBox(width: 4),
                    _SpecPill(Icons.bed_outlined, '${listing.rooms}'),
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

class _CompactCard extends StatelessWidget {
  final ({String id, String price, String neighborhood, int rooms, int sqm, int floor, bool broker}) listing;
  final bool isRent;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;
  final Color color;

  const _CompactCard({
    required this.listing,
    required this.isRent,
    required this.isFavorite,
    required this.onFavoriteTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 95,
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderClr),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(listing.price, style: GoogleFonts.rubik(fontSize: 15, fontWeight: FontWeight.w700, color: context.textPrimary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _Badge(isRent ? 'להשכרה' : 'למכירה', AppColors.rentBadgeBg, AppColors.grayText),
                      const SizedBox(width: 4),
                      if (listing.broker) const _Badge('תיווך', AppColors.brokerBadgeBg, AppColors.turquoise),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${listing.neighborhood} · ${listing.rooms} חד\' · ${listing.sqm} מ"ר',
                    style: GoogleFonts.rubik(fontSize: 11, color: AppColors.grayMeta),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 110,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadiusDirectional.horizontal(end: Radius.circular(19)),
                  ),
                  child: Center(child: Icon(Icons.apartment, size: 32, color: AppColors.midBlue.withValues(alpha: 0.15))),
                ),
                Positioned(
                  top: 8, left: 8,
                  child: GestureDetector(
                    onTap: onFavoriteTap,
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 14,
                        color: isFavorite ? AppColors.error : AppColors.grayMeta,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final String label;
  final IconData icon;
  const _FeaturePill(this.label, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [BoxShadow(color: const Color(0xFF003742).withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.turquoise),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.rubik(fontSize: 10, fontWeight: FontWeight.w500, color: context.textPrimary)),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color textColor;
  const _Badge(this.label, this.bg, this.textColor);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: GoogleFonts.rubik(fontSize: 9, fontWeight: FontWeight.w500, color: textColor)),
    );
  }
}

class _SpecPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SpecPill(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(6)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: AppColors.grayMeta),
            const SizedBox(width: 2),
            Flexible(
              child: Text(label, style: GoogleFonts.rubik(fontSize: 9, color: AppColors.grayText), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
