import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';

class BusinessDetailScreen extends StatefulWidget {
  final String businessId;

  const BusinessDetailScreen({super.key, required this.businessId});

  @override
  State<BusinessDetailScreen> createState() => _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends State<BusinessDetailScreen> {
  int _selectedTab = 0;

  // Review creation state
  int _userRating = 0;
  bool _showReviewForm = false;
  final _reviewTextController = TextEditingController();
  final List<Map<String, dynamic>> _userReviews = [];

  @override
  void dispose() {
    _reviewTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero image area ──
            _buildHero(topPadding),

            // ── Profile circle + Kosher badge overlap area ──
            _buildProfileAndKosher(),

            const SizedBox(height: 12),

            // ── Name + Subtitle ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shipudey Hatikva',
                    style: GoogleFonts.rubik(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Grill Restaurant · Meat · Kosher',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6D6D6D),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Rating + Open status ──
            _buildRatingRow(),

            const SizedBox(height: 16),

            // ── Address row ──
            _buildAddressRow(),

            const SizedBox(height: 20),

            // ── Action buttons ──
            _buildActionButtons(),

            const SizedBox(height: 20),

            // ── Tab bar ──
            _buildTabBar(),

            // ── Tab content (switches by selected tab) ──
            _buildTabContent(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Hero image with gradient overlay
  // ─────────────────────────────────────────────
  Widget _buildHero(double topPadding) {
    return SizedBox(
      height: 260,
      child: Stack(
        children: [
          // Background gradient (placeholder for image)
          Container(
            width: double.infinity,
            height: 260,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF010A36), Color(0xFF0058B5)],
              ),
            ),
            child: Stack(
              children: [
                // Dark gradient overlay at bottom
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Placeholder icon
                Center(
                  child: Icon(
                    IconsaxPlusLinear.reserve,
                    size: 60,
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
              ],
            ),
          ),

          // Back button
          Positioned(
            left: 12,
            top: topPadding + 7,
            child: _CircleButton(
              icon: IconsaxPlusLinear.arrow_left,
              onTap: () => context.pop(),
            ),
          ),

          // Share button
          Positioned(
            right: 56 + 12,
            top: topPadding + 7,
            child: _CircleButton(
              icon: IconsaxPlusLinear.export_1,
              onTap: () {},
            ),
          ),

          // Favorite button
          Positioned(
            right: 12,
            top: topPadding + 7,
            child: _CircleButton(
              icon: IconsaxPlusLinear.heart,
              onTap: () {},
            ),
          ),

          // "Show all photos" button
          Positioned(
            right: 12,
            bottom: 14,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(IconsaxPlusLinear.camera,
                        size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      'Show all photos',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Profile circle + Kosher badge
  // ─────────────────────────────────────────────
  Widget _buildProfileAndKosher() {
    return Transform.translate(
      offset: const Offset(0, -50),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Profile circle (100x100, 3px white border)
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B6914), Color(0xFFC49B2C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Icon(
                  IconsaxPlusLinear.reserve,
                  size: 36,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ),

            const Spacer(),

            // Kosher badge button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE7E7E7)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(IconsaxPlusLinear.verify,
                      size: 14, color: AppColors.midBlue),
                  const SizedBox(width: 6),
                  Text(
                    'Kosher',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.midBlue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Rating + Open status row
  // ─────────────────────────────────────────────
  Widget _buildRatingRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Star + rating
          const Icon(IconsaxPlusBold.star_1,
              size: 16, color: Color(0xFFFFC107)),
          const SizedBox(width: 6),
          Text(
            '4.8',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '(128)',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6D6D6D),
            ),
          ),

          const SizedBox(width: 16),

          // Open now
          Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
              color: Color(0xFF00BA00),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              size: 10,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Open now',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF00BA00),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Address row
  // ─────────────────────────────────────────────
  Widget _buildAddressRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(IconsaxPlusLinear.location,
              size: 16, color: Color(0xFF888888)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '21 Sderot El Melachot, Modi\'in Maccabim-Re\'ut',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6D6D6D),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '2.1 km away',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Action buttons: Call, Website, Instagram, Navigate, Share
  // ─────────────────────────────────────────────
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Call Now button
          Expanded(
            child: GestureDetector(
              onTap: () => launchUrl(Uri.parse('tel:+972501234567')),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.midBlue,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(IconsaxPlusLinear.call,
                        size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      'Call Now',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Website button
          _OutlineCircleButton(
            icon: IconsaxPlusLinear.global,
            color: AppColors.turquoise,
            onTap: () => launchUrl(Uri.parse('https://example.com')),
          ),

          const SizedBox(width: 8),

          // Instagram button
          _OutlineCircleButton(
            icon: IconsaxPlusLinear.instagram,
            color: AppColors.turquoise,
            onTap: () => launchUrl(Uri.parse('https://instagram.com/shipudeyhatikva')),
          ),

          const SizedBox(width: 8),

          // Navigate button
          _OutlineCircleButton(
            icon: IconsaxPlusLinear.routing,
            color: AppColors.turquoise,
            onTap: () => launchUrl(Uri.parse('https://waze.com/ul?ll=31.8928,34.8713&navigate=yes')),
          ),

          const SizedBox(width: 8),

          // Share button
          _OutlineCircleButton(
            icon: IconsaxPlusLinear.export_1,
            color: AppColors.turquoise,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Tab bar (Overview, Menu, Photos, Reviews)
  // ─────────────────────────────────────────────
  Widget _buildTabBar() {
    final tabs = ['Overview', 'Menu', 'Photos', 'Reviews'];

    return Container(
      height: 48,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE7E7E7)),
        ),
      ),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final isActive = entry.key == _selectedTab;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = entry.key),
              behavior: HitTestBehavior.opaque,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color:
                          isActive ? AppColors.midBlue : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    entry.value,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive
                          ? AppColors.midBlue
                          : const Color(0xFF454545),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Tab content switcher
  // ─────────────────────────────────────────────
  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return Column(
          children: [
            _buildOverviewSection(),
            _buildGallerySection(),
            _buildReviewsSection(),
          ],
        );
      case 1:
        return _buildMenuTab();
      case 2:
        return _buildPhotosTab();
      case 3:
        return _buildReviewsTab();
      default:
        return const SizedBox.shrink();
    }
  }

  // ─────────────────────────────────────────────
  // Menu tab
  // ─────────────────────────────────────────────
  Widget _buildMenuTab() {
    final menuCategories = [
      (
        'Starters',
        [
          ('Hummus Plate', '₪32'),
          ('Tahini with Mushrooms', '₪38'),
          ('Chopped Salad', '₪28'),
          ('Eggplant with Tehina', '₪34'),
        ]
      ),
      (
        'Grilled Meats',
        [
          ('Mixed Grill (500g)', '₪98'),
          ('Chicken Skewers (4 pcs)', '₪68'),
          ('Lamb Chops', '₪112'),
          ('Beef Kebab', '₪78'),
          ('Chicken Wings (8 pcs)', '₪52'),
        ]
      ),
      (
        'Sides',
        [
          ('French Fries', '₪22'),
          ('Rice Pilaf', '₪18'),
          ('Grilled Vegetables', '₪26'),
        ]
      ),
      (
        'Drinks',
        [
          ('Soft Drink', '₪14'),
          ('Fresh Lemonade', '₪22'),
          ('Israeli Beer', '₪28'),
        ]
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: menuCategories.map((cat) {
          final (category, items) = cat;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                category,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F1F1F),
                ),
              ),
              const SizedBox(height: 12),
              ...items.map((item) {
                final (name, price) = item;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF3D3D3D),
                        ),
                      ),
                      Text(
                        price,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const Divider(color: Color(0xFFE7E7E7), height: 24),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Photos tab (with upload button)
  // ─────────────────────────────────────────────
  Widget _buildPhotosTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Upload photo button
          GestureDetector(
            onTap: _pickAndUploadPhoto,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.midBlue,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFFF8FAFF),
              ),
              child: Column(
                children: [
                  const Icon(IconsaxPlusLinear.camera,
                      size: 32, color: AppColors.midBlue),
                  const SizedBox(height: 8),
                  Text(
                    'Upload a Photo',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.midBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Share your experience with the community',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF6D6D6D),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Business Gallery
          Text(
            'Business Gallery',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 16),
          _buildPhotoGrid([
            const Color(0xFF8B6914),
            const Color(0xFF2D6A4F),
            const Color(0xFF6B1D2A),
            const Color(0xFF1A4B6E),
            const Color(0xFF667EEA),
            const Color(0xFF11998E),
          ]),

          const SizedBox(height: 24),

          // User Photos
          Text(
            'Pictures from our Users',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 16),
          _buildPhotoGrid([
            const Color(0xFFF093FB),
            const Color(0xFF4FACFE),
            const Color(0xFF43E97B),
            const Color(0xFFFA709A),
          ]),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid(List<Color> colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colors.map((color) {
        return Container(
          width: (MediaQuery.of(context).size.width - 48) / 3,
          height: (MediaQuery.of(context).size.width - 48) / 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(
              IconsaxPlusLinear.image,
              size: 24,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Photo "${image.name}" selected for upload'),
          backgroundColor: AppColors.midBlue,
        ),
      );
    }
  }

  // ─────────────────────────────────────────────
  // Reviews tab (full reviews with reply)
  // ─────────────────────────────────────────────
  Widget _buildReviewsTab() {
    return Column(
      children: [
        const SizedBox(height: 24),

        // ── Write a Review prompt (Google-style) ──
        _buildWriteReviewPrompt(),

        const SizedBox(height: 16),

        // ── Review form (expanded when tapped) ──
        if (_showReviewForm) _buildReviewForm(),

        const SizedBox(height: 8),

        _buildRatingSummary(),

        const SizedBox(height: 24),

        // ── User-submitted reviews ──
        if (_userReviews.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: _userReviews.map((review) {
                return _ReviewCardWithReply(
                  initials: review['initials'] as String,
                  name: review['name'] as String,
                  date: review['date'] as String,
                  rating: review['rating'] as int,
                  text: review['text'] as String,
                );
              }).toList(),
            ),
          ),

        // ── Existing reviews ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _ReviewCardWithReply(
                initials: 'DC',
                name: 'Daniel Cohen',
                date: 'August 8, 2026',
                rating: 4,
                text:
                    'Great food and generous portions. The grilled meats were fresh and perfectly cooked. The staff was friendly and the atmosphere was relaxed. Definitely coming back.',
              ),
              _ReviewCardWithReply(
                initials: 'ML',
                name: 'Maya Levi',
                date: 'August 8, 2026',
                rating: 4,
                text:
                    'We came for dinner with the family and really enjoyed it. The mixed grill was excellent and the salads were fresh. A great place for a casual family meal.',
              ),
              _ReviewCardWithReply(
                initials: 'AS',
                name: 'Amit Shalev',
                date: 'August 8, 2026',
                rating: 4,
                text:
                    'Good food, nice service and a comfortable outdoor seating area. It can get busy during dinner, but the food is worth the wait.',
              ),
              _ReviewCardWithReply(
                initials: 'YF',
                name: 'Yael Friedman',
                date: 'August 8, 2026',
                rating: 4,
                text:
                    'The chicken skewers were amazing and the hummus is some of the best I\'ve had. Friendly service and fair prices. We\'ll definitely be back!',
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Google-style "Rate & Review" prompt ──
  Widget _buildWriteReviewPrompt() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE7E7E7)),
        ),
        child: Column(
          children: [
            Text(
              'How was your experience?',
              style: GoogleFonts.rubik(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Rate and share your experience',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6D6D6D),
              ),
            ),
            const SizedBox(height: 16),

            // Star selector row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final starIndex = i + 1;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _userRating = starIndex;
                      _showReviewForm = true;
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 4 ? 12 : 0),
                    child: Icon(
                      _userRating >= starIndex
                          ? IconsaxPlusBold.star_1
                          : IconsaxPlusLinear.star,
                      size: 36,
                      color: _userRating >= starIndex
                          ? const Color(0xFFFFC107)
                          : const Color(0xFFBDBDBD),
                    ),
                  ),
                );
              }),
            ),

            if (_userRating > 0) ...[
              const SizedBox(height: 8),
              Text(
                _userRating == 1
                    ? 'Poor'
                    : _userRating == 2
                        ? 'Fair'
                        : _userRating == 3
                            ? 'Good'
                            : _userRating == 4
                                ? 'Very Good'
                                : 'Excellent!',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.midBlue,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Expanded review form ──
  Widget _buildReviewForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE7E7E7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Write your review',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _reviewTextController,
              maxLines: 4,
              style: GoogleFonts.inter(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Share details about your experience at this place...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF9E9E9E),
                ),
                filled: true,
                fillColor: const Color(0xFFF8F9FB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE7E7E7)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE7E7E7)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.midBlue),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                // Cancel button
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _showReviewForm = false;
                          _userRating = 0;
                          _reviewTextController.clear();
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE7E7E7)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6D6D6D),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Submit button
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_userRating > 0) {
                          setState(() {
                            _userReviews.insert(0, {
                              'initials': 'YO',
                              'name': 'You',
                              'date': 'Just now',
                              'rating': _userRating,
                              'text': _reviewTextController.text.trim().isEmpty
                                  ? 'Rated $_userRating stars'
                                  : _reviewTextController.text.trim(),
                            });
                            _showReviewForm = false;
                            _userRating = 0;
                            _reviewTextController.clear();
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Review submitted! Thank you 🎉'),
                              backgroundColor: AppColors.midBlue,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.midBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: Text(
                        'Submit',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
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

  // ─────────────────────────────────────────────
  // Overview section (About + Working Hours)
  // ─────────────────────────────────────────────
  Widget _buildOverviewSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(left: 16, right: 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE7E7E7)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // About section
          Text(
            'About Shipudey Hatikva',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Shipudey Hatikva is a beloved grill restaurant in the heart of Modi\'in, bringing together high-quality grilled meats, fresh ingredients, and warm Israeli hospitality. The restaurant offers a relaxed and welcoming atmosphere where guests can enjoy a casual meal with family, meet friends, or celebrate special occasions... ',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF3D3D3D),
              height: 1.6,
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Text(
              'See More',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.midBlue,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Working Hours
          Text(
            'Working Hours',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 20),

          ..._buildHoursRows(),
        ],
      ),
    );
  }

  List<Widget> _buildHoursRows() {
    final hours = [
      ('Mon', '12:00 PM - 9:30 PM', false),
      ('Tue', '12:00 PM - 9:30 PM', false),
      ('Wed', '12:00 PM - 9:30 PM', false),
      ('Thu', '12:00 PM - 9:30 PM', false),
      ('Fri', '12:00 PM - 9:30 PM', false),
      ('Sat', '12:00 PM - 9:30 PM', false),
      ('Sun', 'Close', true),
    ];

    return hours.asMap().entries.map((entry) {
      final (day, time, isClosed) = entry.value;
      return Padding(
        padding: EdgeInsets.only(bottom: entry.key < 6 ? 20 : 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              day,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF3D3D3D),
              ),
            ),
            Text(
              time,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isClosed
                    ? const Color(0xFFF21C1C)
                    : const Color(0xFF3D3D3D),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  // ─────────────────────────────────────────────
  // Gallery section
  // ─────────────────────────────────────────────
  Widget _buildGallerySection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE7E7E7)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Business Gallery title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Business Gallery',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F1F1F),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Horizontal image scroll
          _buildImageScroll([
            const Color(0xFF8B6914),
            const Color(0xFF2D6A4F),
            const Color(0xFF6B1D2A),
            const Color(0xFF1A4B6E),
            const Color(0xFF667EEA),
          ]),

          const SizedBox(height: 24),

          // Review prompt card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF4FD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Have you visited Shipudey Hatikva?',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Share your recommendation with the Modi\'in community.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF6D6D6D),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Thumbs up/down
                        Row(
                          children: [
                            const Icon(IconsaxPlusLinear.like_1,
                                size: 20, color: AppColors.midBlue),
                            const SizedBox(width: 22),
                            Icon(IconsaxPlusLinear.dislike,
                                size: 20,
                                color: const Color(0xFF888888)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Pictures from our Users
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Pictures from our Users',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F1F1F),
              ),
            ),
          ),
          const SizedBox(height: 16),

          _buildImageScroll([
            const Color(0xFF11998E),
            const Color(0xFFF093FB),
            const Color(0xFF4FACFE),
            const Color(0xFF43E97B),
            const Color(0xFFFA709A),
          ]),
        ],
      ),
    );
  }

  Widget _buildImageScroll(List<Color> colors) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, index) {
          return Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: colors[index],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Icon(
                IconsaxPlusLinear.image,
                size: 24,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Reviews section
  // ─────────────────────────────────────────────
  Widget _buildReviewsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE7E7E7)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Reviews for Shipudey Hatikva',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F1F1F),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Rating summary
          _buildRatingSummary(),

          const SizedBox(height: 24),

          // Review cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _ReviewCard(
                  initials: 'DC',
                  name: 'Daniel Cohen',
                  date: 'August 8, 2026',
                  rating: 4,
                  text:
                      'Great food and generous portions. The grilled meats were fresh and perfectly cooked. The staff was friendly and the atmosphere was relaxed. Definitely coming back.',
                ),
                _ReviewCard(
                  initials: 'ML',
                  name: 'Maya Levi',
                  date: 'August 8, 2026',
                  rating: 4,
                  text:
                      'We came for dinner with the family and really enjoyed it. The mixed grill was excellent and the salads were fresh. A great place for a casual family meal.',
                ),
                _ReviewCard(
                  initials: 'AS',
                  name: 'Amit Shalev',
                  date: 'August 8, 2026',
                  rating: 4,
                  text:
                      'Good food, nice service and a comfortable outdoor seating area. It can get busy during dinner, but the food is worth the wait.',
                ),
                _ReviewCard(
                  initials: 'YF',
                  name: 'Yael Friedman',
                  date: 'August 8, 2026',
                  rating: 4,
                  text:
                      'The chicken skewers were amazing and the hummus is some of the best I\'ve had. Friendly service and fair prices. We\'ll definitely be back!',
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left panel: overall score
          Container(
            width: 153,
            padding: const EdgeInsets.only(right: 16, top: 16, bottom: 16),
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(color: Color(0xFFE7E7E7)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '4.6',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                // 5 stars (4 gold, 1 grey)
                Row(
                  children: List.generate(5, (i) {
                    return Padding(
                      padding: EdgeInsets.only(right: i < 4 ? 5.83 : 0),
                      child: Icon(
                        IconsaxPlusBold.star_1,
                        size: 20,
                        color: i < 4
                            ? const Color(0xFFFFC107)
                            : const Color(0xFFD1D1D1),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                Text(
                  'Based on 128 reviews',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF3D3D3D),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Right panel: rating bars
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 0),
              child: Column(
                children: [
                  _RatingBar(label: '5', percent: 78),
                  const SizedBox(height: 8),
                  _RatingBar(label: '4', percent: 14),
                  const SizedBox(height: 8),
                  _RatingBar(label: '3', percent: 5),
                  const SizedBox(height: 8),
                  _RatingBar(label: '2', percent: 2),
                  const SizedBox(height: 8),
                  _RatingBar(label: '1', percent: 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// White circle button (hero overlay)
// ═══════════════════════════════════════════════
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(icon, size: 20, color: const Color(0xFF3D3D3D)),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Outlined circle button (action row)
// ═══════════════════════════════════════════════
class _OutlineCircleButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _OutlineCircleButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE7E7E7)),
        ),
        child: Center(
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Rating bar row (5-star breakdown)
// ═══════════════════════════════════════════════
class _RatingBar extends StatelessWidget {
  final String label;
  final int percent;

  const _RatingBar({required this.label, required this.percent});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: Row(
        children: [
          // Number
          SizedBox(
            width: 12,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Star icon
          const Icon(IconsaxPlusBold.star_1,
              size: 12, color: Color(0xFFFFC107)),
          const SizedBox(width: 11),
          // Progress bar
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: const Color(0xFFE7E7E7),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percent / 100,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: AppColors.turquoise,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 11),
          // Percentage
          SizedBox(
            width: 38,
            child: Text(
              '$percent%',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6D6D6D),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Review card
// ═══════════════════════════════════════════════
class _ReviewCard extends StatelessWidget {
  final String initials;
  final String name;
  final String date;
  final int rating;
  final String text;
  final bool isLast;

  const _ReviewCard({
    required this.initials,
    required this.name,
    required this.date,
    required this.rating,
    required this.text,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFE7E7E7)),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar circle
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.turquoise,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: GoogleFonts.inter(
                  fontSize: 11.2,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + date
                Row(
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      date,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6D6D6D),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 7),

                // Stars
                Row(
                  children: List.generate(5, (i) {
                    return Padding(
                      padding: EdgeInsets.only(right: i < 4 ? 4.08 : 0),
                      child: Icon(
                        IconsaxPlusBold.star_1,
                        size: 14,
                        color: i < rating
                            ? const Color(0xFFFFC107)
                            : const Color(0xFFD1D1D1),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 7),

                // Review text
                Text(
                  text,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF3D3D3D),
                    height: 1.4,
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

// ═══════════════════════════════════════════════
// Review card with reply functionality
// ═══════════════════════════════════════════════
class _ReviewCardWithReply extends StatefulWidget {
  final String initials;
  final String name;
  final String date;
  final int rating;
  final String text;
  final bool isLast;

  const _ReviewCardWithReply({
    required this.initials,
    required this.name,
    required this.date,
    required this.rating,
    required this.text,
    this.isLast = false,
  });

  @override
  State<_ReviewCardWithReply> createState() => _ReviewCardWithReplyState();
}

class _ReviewCardWithReplyState extends State<_ReviewCardWithReply> {
  bool _showReplyField = false;
  String? _submittedReply;
  final _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: widget.isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFE7E7E7)),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar circle
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.turquoise,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                widget.initials,
                style: GoogleFonts.inter(
                  fontSize: 11.2,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + date
                Row(
                  children: [
                    Text(
                      widget.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.date,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6D6D6D),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 7),

                // Stars
                Row(
                  children: List.generate(5, (i) {
                    return Padding(
                      padding: EdgeInsets.only(right: i < 4 ? 4.08 : 0),
                      child: Icon(
                        IconsaxPlusBold.star_1,
                        size: 14,
                        color: i < widget.rating
                            ? const Color(0xFFFFC107)
                            : const Color(0xFFD1D1D1),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 7),

                // Review text
                Text(
                  widget.text,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF3D3D3D),
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 8),

                // Submitted reply (shown after sending)
                if (_submittedReply != null) ...[
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          IconsaxPlusLinear.message_text,
                          size: 14,
                          color: AppColors.midBlue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your reply',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.midBlue,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _submittedReply!,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF3D3D3D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Reply button
                  GestureDetector(
                    onTap: () =>
                        setState(() => _showReplyField = !_showReplyField),
                    child: Text(
                      _showReplyField ? 'Cancel' : 'Reply',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.midBlue,
                      ),
                    ),
                  ),
                ],

                // Reply field
                if (_showReplyField && _submittedReply == null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE7E7E7)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _replyController,
                            style: GoogleFonts.inter(fontSize: 12),
                            decoration: InputDecoration(
                              hintText: 'Write a reply...',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF6D6D6D),
                              ),
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (_replyController.text.trim().isNotEmpty) {
                              setState(() {
                                _submittedReply = _replyController.text.trim();
                                _showReplyField = false;
                              });
                              _replyController.clear();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Reply sent!'),
                                  backgroundColor: AppColors.midBlue,
                                ),
                              );
                            }
                          },
                          child: const Icon(
                            IconsaxPlusBold.send_1,
                            size: 18,
                            color: AppColors.midBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
