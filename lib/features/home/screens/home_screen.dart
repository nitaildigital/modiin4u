import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../core/theme/app_colors.dart';
import 'web_home_screen.dart';

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

class _MobileHomeContent extends StatefulWidget {
  const _MobileHomeContent();

  @override
  State<_MobileHomeContent> createState() => _MobileHomeContentState();
}

class _MobileHomeContentState extends State<_MobileHomeContent> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'בוקר טוב';
    if (hour < 17) return 'צהריים טובים';
    return 'ערב טוב';
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

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Gradient header ──
          _buildHeader(topPadding),

          const SizedBox(height: 20),

          // ── Explore Modiin ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'גלו את מודיעין',
              style: GoogleFonts.inter(
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
            title: 'פופולרי בקרבתך',
            onSeeAll: () => context.go('/businesses'),
          ),
          const SizedBox(height: 12),
          _buildPopularCards(),

          const SizedBox(height: 24),

          // ── Deal Near You ──
          _SectionHeader(
            title: 'מבצעים בקרבתך',
            onSeeAll: () => context.go('/deals'),
          ),
          const SizedBox(height: 12),
          _buildDealImages(),

          const SizedBox(height: 24),

          // ── Upcoming Events ──
          _SectionHeader(
            title: 'אירועים קרובים',
            onSeeAll: () => context.go('/events'),
          ),
          const SizedBox(height: 12),
          _buildEventCards(),

          const SizedBox(height: 24),

          // ── Apartment Near You ──
          _SectionHeader(
            title: 'דירות בקרבתך',
            onSeeAll: () => context.go('/realestate'),
          ),
          const SizedBox(height: 12),
          _buildApartmentList(),

          const SizedBox(height: 24),

          // ── Latest News ──
          _SectionHeader(
            title: 'חדשות אחרונות',
            onSeeAll: () => context.go('/news'),
          ),
          const SizedBox(height: 12),
          _buildNewsCards(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Header with gradient + search bar
  // ─────────────────────────────────────────────
  Widget _buildHeader(double topPadding) {
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
                  child: const Icon(IconsaxPlusLinear.menu, color: Colors.white, size: 24),
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
                  _greeting,
                  style: GoogleFonts.rubik(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'מה אתה מחפש היום?',
                  style: GoogleFonts.inter(
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
                  const Icon(IconsaxPlusLinear.search_normal_1, color: Color(0xFF6D6D6D), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: (_) => _onSearch(),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF1F1F1F),
                      ),
                      decoration: InputDecoration(
                        hintText: 'שאל או חפש במודיעין...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF6D6D6D),
                        ),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                  // Ask button
                  GestureDetector(
                    onTap: _onSearch,
                    child: Container(
                      margin: const EdgeInsets.all(5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 7),
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
                          const Icon(IconsaxPlusBold.magic_star,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'שאל',
                            style: GoogleFonts.inter(
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
      ('מסעדות', IconsaxPlusLinear.reserve, '/businesses'),
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
              onTap: () => context.go(route),
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
                    child:
                        Icon(icon, size: 24, color: const Color(0xFF146DDF)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: GoogleFonts.inter(
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
  Widget _buildPopularCards() {
    final businesses = [
      _BusinessData(
        name: 'Premium Noga Café',
        address: '14 Yehuda St, Re\'ut, Israel',
        rating: 4.8,
        reviews: 128,
        type: 'Cafe',
        typeColor: const Color(0xFF006BF6),
        isKosher: true,
        gradientColors: [const Color(0xFF8B6914), const Color(0xFFC49B2C)],
      ),
      _BusinessData(
        name: 'Olive & Fire',
        address: 'HaMaccabim, Modi\'in',
        rating: 4.8,
        reviews: 254,
        type: 'Restaurant',
        typeColor: const Color(0xFF31AC4E),
        isKosher: true,
        gradientColors: [const Color(0xFF2D6A4F), const Color(0xFF40916C)],
      ),
      _BusinessData(
        name: 'Anaba Lounge',
        address: '14 Yehuda St, Modi\'in',
        rating: 4.8,
        reviews: 105,
        type: 'Bar',
        typeColor: const Color(0xFFCC0001),
        isKosher: false,
        gradientColors: [const Color(0xFF6B1D2A), const Color(0xFF9B2335)],
      ),
      _BusinessData(
        name: 'Sea & Spice',
        address: '21 Sderot Modi\'in',
        rating: 4.8,
        reviews: 254,
        type: 'Restaurant',
        typeColor: const Color(0xFF31AC4E),
        isKosher: false,
        gradientColors: [const Color(0xFF1A4B6E), const Color(0xFF2980B9)],
      ),
    ];

    return SizedBox(
      height: 282,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: businesses.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) => _BusinessCard(data: businesses[index]),
      ),
    );
  }

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
        separatorBuilder: (_, __) => const SizedBox(width: 12),
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
                  style: GoogleFonts.rubik(
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
  Widget _buildEventCards() {
    final events = [
      _EventData(
        name: 'Summer Music Night',
        category: 'Music',
        location: 'Modiin Amphitheater',
        time: '8:00 PM',
        price: '₪50',
        priceColor: AppColors.navy,
        month: 'AUG',
        day: '21',
        gradientColors: [const Color(0xFF667EEA), const Color(0xFF764BA2)],
      ),
      _EventData(
        name: 'Modiin Community Festival',
        category: 'Municipal & Community',
        location: 'Modiin City Center',
        time: '10:00 AM',
        price: 'FREE',
        priceColor: AppColors.midBlue,
        month: 'AUG',
        day: '22',
        gradientColors: [const Color(0xFF11998E), const Color(0xFF38EF7D)],
      ),
      _EventData(
        name: 'Family Fun Day',
        category: 'Kids & Family',
        location: 'Anava Park',
        time: '11:00 AM',
        price: '₪20',
        priceColor: AppColors.navy,
        month: 'AUG',
        day: '23',
        gradientColors: [const Color(0xFFF093FB), const Color(0xFFF5576C)],
      ),
    ];

    return SizedBox(
      height: 272,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: events.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) => _EventCard(data: events[index]),
      ),
    );
  }

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
  Widget _buildNewsCards() {
    final news = [
      _NewsData(
        title:
            'From now on, we can breathe a sigh of relief: The new municipal initiative that will give women in Modi\'in complete confidence and tools for success',
        date: 'August 5, 2026 | 4:36 p.m.',
        gradientColors: [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
      ),
      _NewsData(
        title:
            'An end to cycle worries: Modiin is moving to a new and efficient model that will put your mind at ease',
        date: 'August 5, 2026 | 4:30 p.m.',
        gradientColors: [const Color(0xFF43E97B), const Color(0xFF38F9D7)],
      ),
      _NewsData(
        title:
            'No more heart palpitations: The new tool that will help parents in Modi\'in register for after-school',
        date: 'August 5, 2026 | 4:34 p.m.',
        gradientColors: [const Color(0xFFFA709A), const Color(0xFFFEE140)],
      ),
    ];

    return SizedBox(
      height: 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: news.length,
        separatorBuilder: (_, __) => const SizedBox(width: 20),
        itemBuilder: (_, index) => _NewsCard(data: news[index]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Section header
// ═══════════════════════════════════════════════
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
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                'ראה הכל',
                style: GoogleFonts.inter(
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
class _BusinessData {
  final String name;
  final String address;
  final double rating;
  final int reviews;
  final String type;
  final Color typeColor;
  final bool isKosher;
  final List<Color> gradientColors;

  const _BusinessData({
    required this.name,
    required this.address,
    required this.rating,
    required this.reviews,
    required this.type,
    required this.typeColor,
    required this.isKosher,
    required this.gradientColors,
  });
}

class _BusinessCard extends StatelessWidget {
  final _BusinessData data;

  const _BusinessCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Container(
                width: 252,
                height: 140,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: data.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(Icons.restaurant,
                      size: 40, color: Colors.white.withValues(alpha: 0.4)),
                ),
              ),
              // Favorite button
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(IconsaxPlusLinear.heart,
                      size: 16, color: AppColors.midBlue),
                ),
              ),
              // Kosher badge
              if (data.isKosher)
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0033AC),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(IconsaxPlusBold.verify,
                            size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          'Kosher',
                          style: GoogleFonts.inter(
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
            style: GoogleFonts.rubik(
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
              const Icon(IconsaxPlusLinear.location,
                  size: 14, color: Color(0xFF6D6D6D)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  data.address,
                  style: GoogleFonts.inter(
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
                  const Icon(IconsaxPlusBold.star_1, size: 14, color: Color(0xFFFFC107)),
                  const SizedBox(width: 6),
                  Text(
                    data.rating.toString(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${data.reviews})',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF6D6D6D),
                    ),
                  ),
                ],
              ),
              // Business type badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: data.typeColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  data.type,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Event card data + widget
// ═══════════════════════════════════════════════
class _EventData {
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
}

class _EventCard extends StatelessWidget {
  final _EventData data;

  const _EventCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Container(
                width: 252,
                height: 140,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: data.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(Icons.event,
                      size: 40, color: Colors.white.withValues(alpha: 0.4)),
                ),
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
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.midBlue,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.day,
                        style: GoogleFonts.inter(
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
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(IconsaxPlusLinear.heart,
                      size: 16, color: AppColors.midBlue),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Name
          Text(
            data.name,
            style: GoogleFonts.rubik(
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
            style: GoogleFonts.inter(
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
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: Color(0xFF6D6D6D)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            data.location,
                            style: GoogleFonts.inter(
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
                        const Icon(IconsaxPlusLinear.clock,
                            size: 14, color: Color(0xFF6D6D6D)),
                        const SizedBox(width: 6),
                        Text(
                          data.time,
                          style: GoogleFonts.inter(
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
                style: GoogleFonts.rubik(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: data.priceColor,
                ),
              ),
            ],
          ),
        ],
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
        border: Border(
          bottom: BorderSide(color: Color(0xFFE7E7E7)),
        ),
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
              child:
                  Icon(Icons.apartment, size: 28, color: Colors.white),
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
                      style: GoogleFonts.rubik(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                    ),
                    Text(
                      'FOR SALE',
                      style: GoogleFonts.inter(
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
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: Color(0xFF6D6D6D)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        data.address,
                        style: GoogleFonts.inter(
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
                    const Icon(IconsaxPlusLinear.maximize_4,
                        size: 14, color: Color(0xFF6D6D6D)),
                    const SizedBox(width: 8),
                    Text(
                      data.area,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF6D6D6D),
                      ),
                    ),
                    const SizedBox(width: 31),
                    const Icon(IconsaxPlusLinear.house_2,
                        size: 14, color: Color(0xFF6D6D6D)),
                    const SizedBox(width: 8),
                    Text(
                      data.rooms,
                      style: GoogleFonts.inter(
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
  final String title;
  final String date;
  final List<Color> gradientColors;

  const _NewsData({
    required this.title,
    required this.date,
    required this.gradientColors,
  });
}

class _NewsCard extends StatelessWidget {
  final _NewsData data;

  const _NewsCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Container(
            width: 250,
            height: 150,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: data.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(Icons.article,
                  size: 36, color: Colors.white.withValues(alpha: 0.4)),
            ),
          ),

          const SizedBox(height: 12),

          // Title
          Text(
            data.title,
            style: GoogleFonts.inter(
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
              const Icon(IconsaxPlusLinear.calendar_1,
                  size: 16, color: Color(0xFF888888)),
              const SizedBox(width: 8),
              Text(
                data.date,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF6D6D6D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
