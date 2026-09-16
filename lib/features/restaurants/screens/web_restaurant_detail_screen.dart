import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/restaurant_place_card.dart';
import '../../../shared/widgets/web_chrome.dart';

// ═══════════════════════════════════════════════════════════
// Web Restaurant Detail — full desktop layout from Figma
// (Restaurant Detail — 1920 × 4292)
// ═══════════════════════════════════════════════════════════

const _kTextDark = Color(0xFF3D3D3D);
const _kTextGrey = Color(0xFF6D6D6D);
const _kGold = Color(0xFFFFC107);
const _kStarEmpty = Color(0xFFD1D1D1);
const _kOpenGreen = Color(0xFF00BA00);
const _kClosedRed = Color(0xFFF21C1C);
const _kBannerBg = Color(0xFFF4F7FE);
const _kBannerCircle = Color(0xFFEDF3FE);

class WebRestaurantDetailContent extends StatefulWidget {
  final String restaurantId;
  const WebRestaurantDetailContent({super.key, required this.restaurantId});

  @override
  State<WebRestaurantDetailContent> createState() => _WebRestaurantDetailContentState();
}

class _WebRestaurantDetailContentState extends State<WebRestaurantDetailContent> {
  bool _isHebrew = false;
  bool _saved = false;
  bool _reviewsExpanded = false;
  int? _recommends; // 0 = yes, 1 = no
  final _galleryController = ScrollController();
  final _userPicsController = ScrollController();

  @override
  void dispose() {
    _galleryController.dispose();
    _userPicsController.dispose();
    super.dispose();
  }

  String _t(String en, String he) => _isHebrew ? he : en;

  String get _name => _t('Shipudey Hatikva', 'שיפודי התקווה');

  // ── Nav links (no active item on the detail page) ──
  // ── Highlights ──
  List<String> get _highlights => [
    _t('High quality meats', 'בשרים באיכות גבוהה'),
    _t('Fresh daily ingredients', 'חומרי גלם טריים מדי יום'),
    _t('Family friendly', 'ידידותי למשפחות'),
    _t('Large events & groups', 'אירועים גדולים וקבוצות'),
  ];

  // ── Opening hours ──
  List<_Hours> get _hours => [
    _Hours(day: _t('Monday', 'שני'), value: '12:00 PM - 9:30 PM'),
    _Hours(day: _t('Tuesday', 'שלישי'), value: '12:00 PM - 9:30 PM'),
    _Hours(day: _t('Wednesday', 'רביעי'), value: '12:00 PM - 9:30 PM'),
    _Hours(day: _t('Thursday', 'חמישי'), value: '12:00 PM - 9:30 PM'),
    _Hours(day: _t('Friday', 'שישי'), value: '12:00 PM - 9:30 PM'),
    _Hours(day: _t('Saturday', 'שבת'), value: '12:00 PM - 9:30 PM'),
    _Hours(day: _t('Sunday', 'ראשון'), value: _t('Close', 'סגור'), closed: true),
  ];

  // ── Rating breakdown (stars → percent) ──
  List<_RatingBar> get _ratingBars => const [
    _RatingBar(stars: 5, percent: 78, bar: 78),
    _RatingBar(stars: 4, percent: 14, bar: 14),
    _RatingBar(stars: 3, percent: 5, bar: 5),
    _RatingBar(stars: 2, percent: 2, bar: 3),
    _RatingBar(stars: 1, percent: 1, bar: 2),
  ];

  // ── Reviews ──
  List<_Review> get _reviews => [
    _Review(
      initials: 'DC',
      name: _t('Daniel Cohen', 'דניאל כהן'),
      date: _t('August 8, 2026', '8 באוגוסט 2026'),
      stars: 4,
      body: _t(
        'Great food and generous portions. The grilled meats were fresh and perfectly cooked. The staff was friendly and the atmosphere was relaxed. Definitely coming back.',
        'אוכל מעולה ומנות נדיבות. הבשרים על הגריל היו טריים ומדויקים. הצוות אדיב והאווירה נינוחה. בהחלט נחזור.',
      ),
    ),
    _Review(
      initials: 'ML',
      name: _t('Maya Levi', 'מאיה לוי'),
      date: _t('August 8, 2026', '8 באוגוסט 2026'),
      stars: 4,
      body: _t(
        'We came for dinner with the family and really enjoyed it. The mixed grill was excellent and the salads were fresh. A great place for a casual family meal.',
        'הגענו לארוחת ערב משפחתית ונהנינו מאוד. המעורב היה מצוין והסלטים טריים. מקום נהדר לארוחה משפחתית.',
      ),
    ),
    _Review(
      initials: 'AS',
      name: _t('Amit Shalev', 'עמית שלו'),
      date: _t('August 8, 2026', '8 באוגוסט 2026'),
      stars: 4,
      body: _t(
        'Good food, nice service and a comfortable outdoor seating area. It can get busy during dinner, but the food is worth the wait.',
        'אוכל טוב, שירות נחמד ואזור ישיבה חיצוני נוח. יכול להיות עמוס בערב, אבל האוכל שווה את ההמתנה.',
      ),
    ),
    _Review(
      initials: 'YF',
      name: _t('Yael Friedman', 'יעל פרידמן'),
      date: _t('August 8, 2026', '8 באוגוסט 2026'),
      stars: 4,
      body: _t(
        'The chicken skewers were amazing and the hummus is some of the best I\'ve had. Friendly service and fair prices. We\'ll definitely be back!',
        'שיפודי הפרגית היו מדהימים והחומוס מהטובים שאכלתי. שירות אדיב ומחירים הוגנים. בהחלט נחזור!',
      ),
    ),
    _Review(
      initials: 'YF',
      name: _t('Yael Friedman', 'יעל פרידמן'),
      date: _t('August 8, 2026', '8 באוגוסט 2026'),
      stars: 4,
      body: _t(
        'The chicken skewers were amazing and the hummus is some of the best I\'ve had. Friendly service and fair prices. We\'ll definitely be back!',
        'שיפודי הפרגית היו מדהימים והחומוס מהטובים שאכלתי. שירות אדיב ומחירים הוגנים. בהחלט נחזור!',
      ),
    ),
  ];

  // ── More businesses in the neighborhood ──
  List<RestaurantPlace> get _moreBusinesses => [
    RestaurantPlace(
      name: _t('Japan Japan Modiin', 'ג\'פן ג\'פן מודיעין'),
      type: _t('Restaurant', 'מסעדה'),
      address: _t('HaNahalim St 8, Modiin', 'הנחלים 8, מודיעין'),
      rating: 4.8, reviews: 128, views: 187,
      marker: kRestaurantGreen, imageBg: const Color(0xFF8C7B6B),
    ),
    RestaurantPlace(
      name: _t('Café Greg Modiin', 'קפה גרג מודיעין'),
      type: _t('Coffee Shop', 'בית קפה'),
      address: _t('HaOmanut St 3, Modiin', 'האומנות 3, מודיעין'),
      rating: 4.8, reviews: 128, views: 187,
      marker: kCafeBlue, imageBg: const Color(0xFF6B7F8C),
    ),
    RestaurantPlace(
      name: _t('The Red Sea Star', 'רד סי סטאר'),
      type: _t('Bar', 'בר'),
      address: _t('Derech Maccabim 6, Modiin', 'דרך המכבים 6, מודיעין'),
      rating: 4.8, reviews: 128, views: 187,
      marker: kBarRed, imageBg: const Color(0xFF8C6B6B),
    ),
    RestaurantPlace(
      name: _t('The Red Sea Star', 'רד סי סטאר'),
      type: _t('Restaurant', 'מסעדה'),
      address: _t('HaNahalim St 8, Modiin', 'הנחלים 8, מודיעין'),
      rating: 4.8, reviews: 128, views: 187,
      marker: kRestaurantGreen, imageBg: const Color(0xFF7B8C6B),
    ),
    RestaurantPlace(
      name: _t('Biga Modiin', 'ביגה מודיעין'),
      type: _t('Bar', 'בר'),
      address: _t('Derech Modiin 6, Modiin', 'דרך מודיעין 6, מודיעין'),
      rating: 4.8, reviews: 128, views: 187,
      marker: kBarRed, imageBg: const Color(0xFF6B6B8C),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isHebrew ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            WebNavbar(
              isHebrew: _isHebrew,
              onToggleLanguage: () => setState(() => _isHebrew = !_isHebrew),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHero(),
                    const SizedBox(height: 56),
                    _Section(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildMainColumn()),
                          const SizedBox(width: 136),
                          SizedBox(
                            width: 376,
                            child: Column(
                              children: [
                                _buildLocationHoursCard(),
                                const SizedBox(height: 20),
                                _buildMoreInfoCard(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 64),
                    _buildMoreBusinesses(),
                    const SizedBox(height: 100),
                    WebFooter(isHebrew: _isHebrew),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // NAVBAR
  // ─────────────────────────────────────────────
  // ─────────────────────────────────────────────
  // HERO
  // ─────────────────────────────────────────────
  Widget _buildHero() {
    return SizedBox(
      height: 550,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF3E2C21), Color(0xFF8C6B4F)],
                ),
              ),
            ),
          ),
          // Left scrim — covers half the hero
          Positioned.fill(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: AlignmentDirectional.centerStart,
                      end: AlignmentDirectional.centerEnd,
                      stops: const [0.012, 0.5229, 1.0],
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.black.withValues(alpha: 0.8),
                        Colors.black.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: _Section(
              child: Stack(
                children: [
                  PositionedDirectional(top: 158, start: 0, child: _buildHeroInfo()),
                  PositionedDirectional(top: 486, end: 0, child: _buildHeroButtons()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroInfo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFB4884F), Color(0xFF6B4A2B)],
            ),
          ),
          child: const Center(child: Icon(IconsaxPlusBold.reserve, size: 48, color: Colors.white70)),
        ),
        const SizedBox(width: 33),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_name,
                style: GoogleFonts.nunito(fontSize: 48, fontWeight: FontWeight.w600, color: Colors.white, height: 1.23)),
            const SizedBox(height: 14),
            Text(_t('Grill Restaurant · Meat · Kosher', 'מסעדת גריל · בשרים · כשר'),
                style: GoogleFonts.inter(fontSize: 16, color: Colors.white)),
            const SizedBox(height: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _glassPill(
                  icon: const Icon(IconsaxPlusBold.star_1, size: 14, color: _kGold),
                  label: _t('4.6 · 128 reviews', '4.6 · 128 ביקורות'),
                ),
                const SizedBox(width: 16),
                _glassPill(
                  icon: const Icon(IconsaxPlusLinear.verify, size: 14, color: Colors.white),
                  label: _t('Kosher', 'כשר'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(IconsaxPlusLinear.clock, size: 16, color: _kOpenGreen),
                const SizedBox(width: 8),
                Text(_t('Open now', 'פתוח עכשיו'),
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: _kOpenGreen)),
                const SizedBox(width: 12),
                Text(_t('Closes 11:00 PM · See all hours', 'נסגר ב-23:00 · כל שעות הפעילות'),
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(IconsaxPlusLinear.location, size: 16, color: AppColors.turquoise),
                const SizedBox(width: 8),
                Text(_t('21 Sderot El Melachot, Modi\'in Maccabim-Re\'ut', 'שדרות אל המלאכות 21, מודיעין מכבים-רעות'),
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _glassPill({required Widget icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 7),
          Text(label, style: GoogleFonts.inter(fontSize: 14, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildHeroButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _heroButton(
          icon: IconsaxPlusLinear.gallery,
          label: _t('Show all photos', 'כל התמונות'),
          onTap: () {},
        ),
        const SizedBox(width: 12),
        _heroButton(
          icon: _saved ? IconsaxPlusBold.heart : IconsaxPlusLinear.heart,
          label: _t('Save', 'שמירה'),
          iconColor: _saved ? kHeartRed : AppColors.midBlue,
          onTap: () => setState(() => _saved = !_saved),
        ),
      ],
    );
  }

  Widget _heroButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color iconColor = AppColors.midBlue,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(60),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 8),
              Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.navy)),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // MAIN (LEFT) COLUMN
  // ─────────────────────────────────────────────
  Widget _buildMainColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAbout(),
        const SizedBox(height: 40),
        _buildHighlights(),
        const SizedBox(height: 48),
        _buildGallery(),
        const SizedBox(height: 56),
        _buildRecommendBanner(),
        const SizedBox(height: 56),
        _buildUserPictures(),
        const SizedBox(height: 56),
        _buildReviews(),
        const SizedBox(height: 40),
        _buildWriteReviewBanner(),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text,
        style: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.midBlue, height: 1.25));
  }

  Widget _buildAbout() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 896),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(_t('About $_name', 'אודות $_name')),
          const SizedBox(height: 24),
          Text(
            _t(
              'Shipudey Hatikva is a beloved grill restaurant in the heart of Modi\'in, serving the local community for years with warm hospitality and a relaxed family atmosphere. The place is known for its generous portions, its open charcoal grill and the kind of service that makes regulars out of first-time guests.',
              'שיפודי התקווה היא מסעדת גריל אהובה בלב מודיעין, שמשרתת את הקהילה המקומית כבר שנים עם אירוח חם ואווירה משפחתית ונינוחה. המקום מוכר במנות הנדיבות שלו, בגריל הפחמים הפתוח ובשירות שהופך אורחים מזדמנים ללקוחות קבועים.',
            ),
            style: GoogleFonts.inter(fontSize: 16, color: _kTextDark, height: 1.6),
          ),
          const SizedBox(height: 24),
          Text(
            _t(
              'Our menu focuses on freshly prepared grilled dishes — skewers, mixed grill, steaks and chicken — alongside a wide selection of Israeli salads, homemade sides and fresh pita straight from the oven. Everything is made daily from quality ingredients, and the kitchen is fully kosher.',
              'התפריט שלנו מתמקד במנות גריל טריות — שיפודים, מעורב, סטייקים ופרגיות — לצד מבחר רחב של סלטים ישראליים, תוספות ביתיות ופיתות חמות מהטאבון. הכול מוכן מדי יום מחומרי גלם איכותיים, והמטבח כשר לחלוטין.',
            ),
            style: GoogleFonts.inter(fontSize: 16, color: _kTextDark, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlights() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 896),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(_t('Highlights', 'נקודות בולטות')),
          const SizedBox(height: 24),
          SizedBox(
            width: 465,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _highlights.map((h) {
                return Padding(
                  padding: EdgeInsets.only(bottom: h == _highlights.last ? 0 : 16),
                  child: Row(
                    children: [
                      const Icon(IconsaxPlusLinear.tick_circle, size: 20, color: AppColors.midBlue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(h, style: GoogleFonts.inter(fontSize: 16, color: _kTextDark)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Business gallery ──
  Widget _buildGallery() {
    const colors = [
      Color(0xFF8C6B4F), Color(0xFF6B7F8C), Color(0xFF8C7B6B),
      Color(0xFF7B8C6B), Color(0xFF6B6B8C),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(_t('Business Gallery', 'גלריית העסק')),
        const SizedBox(height: 24),
        _buildCarousel(
          controller: _galleryController,
          itemWidth: 200,
          itemHeight: 202,
          gap: 22,
          colors: [...colors, ...colors],
        ),
      ],
    );
  }

  // ── Pictures from our users ──
  Widget _buildUserPictures() {
    const colors = [
      Color(0xFF7A6A5A), Color(0xFF5A6A7A), Color(0xFF6A7A5A),
      Color(0xFF7A5A6A), Color(0xFF5A7A7A), Color(0xFF7A7A5A),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sectionTitle(_t('Pictures from our users', 'תמונות מהמשתמשים שלנו')),
            const Spacer(),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.midBlue),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Center(
                    child: Text(_t('Upload', 'העלאה'),
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.midBlue)),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildCarousel(
          controller: _userPicsController,
          itemWidth: 163.5,
          itemHeight: 170,
          gap: 20,
          colors: [...colors, ...colors],
        ),
      ],
    );
  }

  Widget _buildCarousel({
    required ScrollController controller,
    required double itemWidth,
    required double itemHeight,
    required double gap,
    required List<Color> colors,
  }) {
    void scroll(int direction) {
      final target = (controller.offset + direction * (itemWidth + gap) * 3)
          .clamp(0.0, controller.position.maxScrollExtent);
      controller.animateTo(target, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
    }

    return SizedBox(
      height: itemHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ListView.separated(
            controller: controller,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: colors.length,
            separatorBuilder: (_, _) => SizedBox(width: gap),
            itemBuilder: (context, i) => _imageBox(colors[i], width: itemWidth, height: itemHeight, radius: 8),
          ),
          PositionedDirectional(
            start: -20,
            top: (itemHeight - 40) / 2,
            child: _CarouselArrow(icon: IconsaxPlusLinear.arrow_left_3, onTap: () => scroll(-1)),
          ),
          PositionedDirectional(
            end: -20,
            top: (itemHeight - 40) / 2,
            child: _CarouselArrow(icon: IconsaxPlusLinear.arrow_right_3, onTap: () => scroll(1)),
          ),
        ],
      ),
    );
  }

  Widget _imageBox(Color base, {required double width, required double height, double radius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base, Color.lerp(base, Colors.black, 0.25)!],
        ),
      ),
    );
  }

  // ── "Have you visited …?" banner ──
  Widget _buildRecommendBanner() {
    return Container(
      height: 104,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kBannerBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 64, height: 64,
            decoration: const BoxDecoration(color: _kBannerCircle, shape: BoxShape.circle),
            child: const Center(child: Icon(IconsaxPlusLinear.like_1, size: 24, color: AppColors.midBlue)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_t('Have you visited $_name?', 'ביקרתם ב$_name?'),
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black)),
                const SizedBox(height: 6),
                Text(_t('Share your recommendation with the Modi\'in community.', 'שתפו את ההמלצה שלכם עם קהילת מודיעין.'),
                    style: GoogleFonts.inter(fontSize: 14, color: _kTextDark)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _PillButton(
            label: _t('Yes, I recommend it', 'כן, אני ממליץ'),
            icon: IconsaxPlusLinear.like_1,
            filled: true,
            selected: _recommends == 0,
            onTap: () => setState(() => _recommends = _recommends == 0 ? null : 0),
          ),
          const SizedBox(width: 12),
          _PillButton(
            label: _t('No', 'לא'),
            filled: false,
            selected: _recommends == 1,
            onTap: () => setState(() => _recommends = _recommends == 1 ? null : 1),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // REVIEWS
  // ─────────────────────────────────────────────
  Widget _buildReviews() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 918),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(_t('Reviews for $_name', 'ביקורות על $_name')),
          const SizedBox(height: 40),
          _buildRatingSummary(),
          const SizedBox(height: 32),
          Row(
            children: [
              _FilterBox(label: _t('Sort By: Most Recent', 'מיון: החדשות ביותר')),
              const SizedBox(width: 12),
              _FilterBox(label: _t('Rating: All', 'דירוג: הכל')),
            ],
          ),
          const SizedBox(height: 32),
          _buildReviewsList(),
        ],
      ),
    );
  }

  Widget _buildRatingSummary() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 240,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: const BoxDecoration(
            border: BorderDirectional(end: BorderSide(color: kRBorder)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('4.6',
                  style: GoogleFonts.inter(fontSize: 48, fontWeight: FontWeight.w600, color: Colors.black, height: 1.2)),
              const SizedBox(height: 16),
              _stars(4, size: 24, gap: 7),
              const SizedBox(height: 16),
              Text(_t('Based on 128 reviews', 'מבוסס על 128 ביקורות'),
                  style: GoogleFonts.inter(fontSize: 16, color: _kTextDark)),
            ],
          ),
        ),
        const SizedBox(width: 81),
        SizedBox(
          width: 393,
          child: Column(
            children: _ratingBars.map((r) {
              return Padding(
                padding: EdgeInsets.only(bottom: r == _ratingBars.last ? 0 : 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 42,
                      child: Row(
                        children: [
                          Text('${r.stars}',
                              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black)),
                          const SizedBox(width: 4),
                          const Icon(IconsaxPlusBold.star_1, size: 16, color: _kGold),
                        ],
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: kRBorder,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: FractionallySizedBox(
                          alignment: AlignmentDirectional.centerStart,
                          widthFactor: r.bar / 100,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.turquoise,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 11),
                    SizedBox(
                      width: 40,
                      child: Text('${r.percent}%',
                          textAlign: TextAlign.end,
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: _kTextGrey)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _stars(int filled, {double size = 14, double gap = 4}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Padding(
          padding: EdgeInsetsDirectional.only(end: i == 4 ? 0 : gap),
          child: Icon(IconsaxPlusBold.star_1, size: size, color: i < filled ? _kGold : _kStarEmpty),
        );
      }),
    );
  }

  Widget _buildReviewsList() {
    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _reviews.map(_buildReviewRow).toList(),
    );

    if (_reviewsExpanded) return list;

    return SizedBox(
      height: 580,
      child: Stack(
        children: [
          ClipRect(
            child: OverflowBox(
              alignment: Alignment.topCenter,
              maxHeight: double.infinity,
              child: list,
            ),
          ),
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: IgnorePointer(
              child: Container(
                height: 222,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white.withValues(alpha: 0), Colors.white],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0, right: 0, bottom: 2,
            child: Center(
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => setState(() => _reviewsExpanded = true),
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.midBlue),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: Center(
                      child: Text(_t('Load More', 'טען עוד'),
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.midBlue)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewRow(_Review r) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kRBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: const BoxDecoration(color: AppColors.turquoise, shape: BoxShape.circle),
            child: Center(
              child: Text(r.initials,
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(r.name,
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black)),
                    const SizedBox(width: 12),
                    Text(r.date, style: GoogleFonts.inter(fontSize: 12, color: _kTextGrey)),
                  ],
                ),
                const SizedBox(height: 7),
                _stars(r.stars, size: 14, gap: 4.08),
                const SizedBox(height: 7),
                Text(r.body, style: GoogleFonts.inter(fontSize: 14, color: _kTextDark, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWriteReviewBanner() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 918),
      child: Container(
        height: 106,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: kRBorder),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 16)],
        ),
        child: Row(
          children: [
            Container(
              width: 64, height: 64,
              decoration: const BoxDecoration(color: _kBannerCircle, shape: BoxShape.circle),
              child: const Center(child: Icon(IconsaxPlusLinear.edit_2, size: 27, color: AppColors.midBlue)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_t('Have you been to $_name?', 'הייתם ב$_name?'),
                      style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black)),
                  const SizedBox(height: 6),
                  Text(_t('Share your experience with the Modi\'in community.', 'שתפו את החוויה שלכם עם קהילת מודיעין.'),
                      style: GoogleFonts.inter(fontSize: 14, color: _kTextDark)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: AppColors.midBlue,
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(IconsaxPlusLinear.edit_2, size: 20, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(_t('Write a Review', 'כתיבת ביקורת'),
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SIDEBAR CARDS
  // ─────────────────────────────────────────────
  Widget _buildLocationHoursCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: kRBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_t('Location & Hours', 'מיקום ושעות'),
                    style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.midBlue)),
                const SizedBox(height: 6),
                Text(_t('21 Sderot El Melachot, Modi\'in Maccabim-Re\'ut', 'שדרות אל המלאכות 21, מודיעין מכבים-רעות'),
                    style: GoogleFonts.inter(fontSize: 14, color: _kTextGrey)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 231,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFE9EEF3), Color(0xFFDCE5EC)],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 163,
                  top: 80,
                  child: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 2.74,
                          offset: const Offset(0, 2.74),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 32, height: 32,
                        decoration: const BoxDecoration(color: kCafeBlue, shape: BoxShape.circle),
                        child: const Center(child: Icon(IconsaxPlusBold.location, size: 16, color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: _hours.map((h) {
                return Padding(
                  padding: EdgeInsets.only(bottom: h == _hours.last ? 0 : 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(h.day,
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: _kTextDark)),
                      Text(h.value,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: h.closed ? _kClosedRed : _kTextDark,
                          )),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: kRBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_t('More Info', 'מידע נוסף'),
              style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.midBlue)),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(IconsaxPlusLinear.global, size: 20, color: _kTextGrey),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_t('Website', 'אתר'),
                        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF5D5D5D))),
                    const SizedBox(height: 6),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => launchUrl(Uri.parse('https://shipudeyhatikva.co.il')),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('shipudeyhatikva.co.il',
                                style: GoogleFonts.inter(
                                    fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.midBlue)),
                            const SizedBox(width: 6),
                            const Icon(Icons.open_in_new, size: 16, color: AppColors.midBlue),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(IconsaxPlusLinear.call, size: 20, color: _kTextGrey),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_t('Call', 'טלפון'),
                        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF5D5D5D))),
                    const SizedBox(height: 6),
                    Text('08-975-2533',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // MORE BUSINESSES
  // ─────────────────────────────────────────────
  Widget _buildMoreBusinesses() {
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(_t('More Businesses in Moriah', 'עסקים נוספים במוריה')),
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 24.0;
              final cols = constraints.maxWidth > 1400 ? 5 : (constraints.maxWidth > 1000 ? 3 : 2);
              final cardWidth = (constraints.maxWidth - (cols - 1) * gap) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: _moreBusinesses
                    .map((p) => SizedBox(
                          width: cardWidth,
                          child: RestaurantCard(
                            place: p,
                            compact: true,
                            isHebrew: _isHebrew,
                            onTap: () => context.push('/restaurant/1'),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // FOOTER
  // ─────────────────────────────────────────────
}

// ═══════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════

class _Hours {
  final String day, value;
  final bool closed;
  const _Hours({required this.day, required this.value, this.closed = false});
}

class _RatingBar {
  final int stars, percent, bar;
  const _RatingBar({required this.stars, required this.percent, required this.bar});
}

class _Review {
  final String initials, name, date, body;
  final int stars;
  const _Review({
    required this.initials,
    required this.name,
    required this.date,
    required this.stars,
    required this.body,
  });
}

// ═══════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════

class _Section extends StatelessWidget {
  final Widget child;
  const _Section({required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1648), // 1600 content + 24 padding each side
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: child,
        ),
      ),
    );
  }
}

class _CarouselArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CarouselArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFF6F6F6)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 1))],
          ),
          child: Center(child: Icon(icon, size: 20, color: AppColors.midBlue)),
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool filled, selected;
  final VoidCallback onTap;
  const _PillButton({
    required this.label,
    this.icon,
    required this.filled,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final solid = filled || selected;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 41,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: solid ? AppColors.midBlue : Colors.white,
            border: Border.all(color: AppColors.midBlue),
            borderRadius: BorderRadius.circular(60),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: solid ? Colors.white : AppColors.midBlue),
                const SizedBox(width: 8),
              ],
              Text(label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: solid ? Colors.white : AppColors.midBlue,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterBox extends StatelessWidget {
  final String label;
  const _FilterBox({required this.label});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {},
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: kRBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: _kTextDark)),
              const SizedBox(width: 8),
              const Icon(Icons.keyboard_arrow_down, size: 16, color: _kTextDark),
            ],
          ),
        ),
      ),
    );
  }
}
