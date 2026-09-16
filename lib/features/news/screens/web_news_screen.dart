import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';

// ═══════════════════════════════════════════════════════════
// Web Modiin News — full desktop layout from Figma
// (Modiin News — 1920 × 4341)
// ═══════════════════════════════════════════════════════════

const _kBorder = Color(0xFFE7E7E7);
const _kLime = Color(0xFFC9F31D);
const _kBodyGrey = Color(0xFF5F5E5A);
const _kIconGrey = Color(0xFF6D6D6D);

class WebNewsContent extends StatefulWidget {
  const WebNewsContent({super.key});

  @override
  State<WebNewsContent> createState() => _WebNewsContentState();
}

class _WebNewsContentState extends State<WebNewsContent> {
  bool _isHebrew = false;

  String _t(String en, String he) => _isHebrew ? he : en;

  // ── Nav links ──
  List<_NavItem> get _navItems => [
    _NavItem(label: _t('Professionals', 'בעלי מקצוע'), route: '/businesses', hasDropdown: true),
    _NavItem(label: _t('Modiin News', 'חדשות מודיעין'), route: '/news', hasDropdown: true, isActive: true),
    _NavItem(label: _t('Events', 'אירועים'), route: '/events'),
    _NavItem(label: _t('Deals', 'מבצעים'), route: '/deals'),
    _NavItem(label: _t('Real Estate in Modiin', 'נדל"ן במודיעין'), route: '/realestate'),
    _NavItem(label: _t('Restaurants in Modiin', 'מסעדות במודיעין'), route: '/restaurants'),
    _NavItem(label: _t('Businesses in Modiin', 'עסקים במודיעין'), route: '/businesses', hasDropdown: true),
  ];

  // ═══════════════════════════════════════════════
  // DEMO CONTENT
  // ═══════════════════════════════════════════════

  _Article get _featured => _Article(
    id: 'featured',
    title: _t(
      "From now on, we can breathe a sigh of relief: The new municipal initiative that will give women in Modi'in complete confidence and tools for success",
      'מעכשיו אפשר לנשום לרווחה: היוזמה העירונית החדשה שתעניק לנשים במודיעין ביטחון מלא וכלים להצלחה',
    ),
    date: _t('August 5, 2026 | 4:36 p.m.', '5 באוגוסט 2026 | 16:36'),
    colors: const [Color(0xFF1A4E8A), Color(0xFF07112E)],
  );

  List<_Article> get _heroSide => [
    _Article(
      id: 'hero_1',
      title: _t(
        "An engineering degree close to home: The Multidisciplinary Center in Modi'in and ORT College Jerusalem open new tracks",
        'תואר בהנדסה קרוב לבית: המרכז הרב תחומי במודיעין ומכללת אורט ירושלים פותחים מסלולים חדשים',
      ),
      date: _t('August 4, 2026 | 2:25 p.m.', '4 באוגוסט 2026 | 14:25'),
      colors: const [Color(0xFF26607F), Color(0xFF081428)],
    ),
    _Article(
      id: 'hero_2',
      title: _t(
        'Parashat Raeh: The Environment as the Basis for the Purpose of Life',
        'פרשת ראה: הסביבה כבסיס לתכלית החיים',
      ),
      date: _t('August 7, 2026 | 9:36 am', '7 באוגוסט 2026 | 09:36'),
      colors: const [Color(0xFF3B5B3A), Color(0xFF0B1A16)],
    ),
  ];

  List<_Article> get _municipality => [
    _Article(
      id: 'muni_0',
      title: _t(
        'An end to cycle worries: Modiin is moving to a new and efficient model that will put your mind at ease',
        'סוף לדאגות המחזור: מודיעין עוברת למודל חדש ויעיל שירגיע אתכם',
      ),
      excerpt: _t(
        'Our city became a pilgrimage center for fans of Brazilian rhythm and energy this weekend. The 2026 Israel Capoeira Championship was held in',
        'העיר שלנו הפכה בסוף השבוע למרכז עלייה לרגל עבור חובבי הקצב והאנרגיה הברזילאית. אליפות ישראל בקפוארה 2026 נערכה ב',
      ),
      date: _t('August 5, 2026 | 4:36 p.m.', '5 באוגוסט 2026 | 16:36'),
      colors: const [Color(0xFF2C6E8F), Color(0xFF0A1A2E)],
    ),
    _Article(
      id: 'muni_1',
      title: _t(
        'An end to cycle worries: Modiin is moving to a new and efficient model that will put your mind at ease',
        'סוף לדאגות המחזור: מודיעין עוברת למודל חדש ויעיל שירגיע אתכם',
      ),
      excerpt: _t(
        "The Municipality of Modi'in Maccabim Re'ut is taking a new step and upgrading the city's paper recycling system, in order to adapt the service to",
        'עיריית מודיעין מכבים רעות עושה צעד חדש ומשדרגת את מערך מיחזור הנייר בעיר, כדי להתאים את השירות ל',
      ),
      date: _t('August 5, 2026 | 4:30 p.m.', '5 באוגוסט 2026 | 16:30'),
      colors: const [Color(0xFF4A7A52), Color(0xFF0E1C1A)],
    ),
    _Article(
      id: 'muni_2',
      title: _t(
        "No more heart palpitations: The new tool that will help parents in Modi'in register for after-school",
        'לא עוד דפיקות לב: הכלי החדש שיעזור להורים במודיעין להירשם לצהרונים',
      ),
      excerpt: _t(
        "Parents in Modi'in can breathe a sigh of relief ahead of the start of the 2017 school year. The Orchids Association is launching a revolutionary",
        'הורים במודיעין יכולים לנשום לרווחה לקראת פתיחת שנת הלימודים. עמותת הסחלבים משיקה מהלך מהפכני',
      ),
      date: _t('August 5, 2026 | 4:34 p.m.', '5 באוגוסט 2026 | 16:34'),
      colors: const [Color(0xFF8A5A3B), Color(0xFF241209)],
    ),
    _Article(
      id: 'muni_3',
      title: _t(
        'From now on, we can breathe a sigh of relief: The new municipal initiative that will give women i',
        'מעכשיו אפשר לנשום לרווחה: היוזמה העירונית החדשה שתעניק לנשים',
      ),
      excerpt: _t(
        "The women in Modi'in are receiving a new and powerful envelope that will change everything they knew about personal resilience, security and",
        'הנשים במודיעין מקבלות מעטפת חדשה ועוצמתית שתשנה כל מה שידעו על חוסן אישי, ביטחון ו',
      ),
      date: _t('August 5, 2026 | 4:34 p.m.', '5 באוגוסט 2026 | 16:34'),
      colors: const [Color(0xFF6C4F8A), Color(0xFF150E24)],
    ),
    _Article(
      id: 'muni_4',
      title: _t(
        "An engineering degree close to home: The Multidisciplinary Center in Modi'in and ORT College",
        'תואר בהנדסה קרוב לבית: המרכז הרב תחומי במודיעין ומכללת אורט',
      ),
      excerpt: _t(
        "Residents of Modi'in can now breathe a sigh of relief and study a sought-after profession without wasting time on long trips to distant educational",
        'תושבי מודיעין יכולים סוף סוף ללמוד מקצוע מבוקש בלי לבזבז זמן על נסיעות ארוכות למוסדות לימוד רחוקים',
      ),
      date: _t('August 5, 2026 | 4:34 p.m.', '5 באוגוסט 2026 | 16:34'),
      colors: const [Color(0xFF26607F), Color(0xFF081428)],
    ),
    _Article(
      id: 'muni_5',
      title: _t(
        'Good news for Modiin residents: A thorough cleaning of the city center is beginning',
        'בשורה לתושבי מודיעין: מתחיל ניקיון יסודי של מרכז העיר',
      ),
      excerpt: _t(
        'The municipality is launching a large-scale campaign to upgrade the cleanliness of the city center. The new move will restore the shine to the boulevard and significantly improve the entertainment experience',
        'העירייה יוצאת במבצע רחב היקף לשדרוג הניקיון במרכז העיר. המהלך החדש יחזיר את הברק לשדרה וישפר משמעותית את חוויית הבילוי',
      ),
      date: _t('August 5, 2026 | 4:34 p.m.', '5 באוגוסט 2026 | 16:34'),
      colors: const [Color(0xFF3F7D6E), Color(0xFF0B1D1A)],
    ),
  ];

  List<_Article> get _urban => [
    _Article(
      id: 'urban_0',
      title: _t(
        'Parashat Raeh: The Environment as the Basis for the Purpose of Life',
        'פרשת ראה: הסביבה כבסיס לתכלית החיים',
      ),
      excerpt: _t(
        'In this week\'s Torah, there are several verses that command us to care for and be attentive to our surroundings. "And the Levite who is within you',
        'בפרשת השבוע מופיעים כמה פסוקים המצווים אותנו לדאוג ולהיות קשובים לסביבה שלנו. "והלוי אשר בשעריך',
      ),
      date: _t('August 4, 2026 | 4:36 p.m.', '4 באוגוסט 2026 | 16:36'),
      colors: const [Color(0xFF3B5B3A), Color(0xFF0B1A16)],
    ),
    _Article(
      id: 'urban_1',
      title: _t(
        "20 years later: The evening in Modi'in that left an entire hall speechless",
        '20 שנה אחרי: הערב במודיעין שהשאיר אולם שלם ללא מילים',
      ),
      excerpt: _t(
        'It was one evening when time seemed to stand still. Bereaved families, senior commanders and residents of the city gathered at the Yad Labanim',
        'זה היה ערב אחד שבו נדמה היה שהזמן עוצר מלכת. משפחות שכולות, מפקדים בכירים ותושבי העיר נאספו ביד לבנים',
      ),
      date: _t('August 3, 2026 | 1:30 p.m.', '3 באוגוסט 2026 | 13:30'),
      colors: const [Color(0xFF2B3A55), Color(0xFF070C18)],
    ),
    _Article(
      id: 'urban_2',
      title: _t(
        'Why must procurement people in large organizations know negotiation tactics?',
        'למה אנשי רכש בארגונים גדולים חייבים להכיר טקטיקות משא ומתן?',
      ),
      excerpt: _t(
        'In the world of corporate procurement, negotiation is not just a moment when you try to lower the price. It is one of the most sensitive, complex and influential business arenas',
        'בעולם הרכש הארגוני, משא ומתן הוא לא רק רגע שבו מנסים להוריד מחיר. זו אחת הזירות העסקיות הרגישות, המורכבות והמשפיעות ביותר',
      ),
      date: _t('August 3, 2026 | 4:34 p.m.', '3 באוגוסט 2026 | 16:34'),
      colors: const [Color(0xFF7A5C2E), Color(0xFF1D1206)],
    ),
    _Article(
      id: 'urban_3',
      title: _t(
        'Yaakov Aviv reveals what makes the final stage the most critical phase of the project',
        'יעקב אביב חושף מה הופך את השלב האחרון לקריטי ביותר בפרויקט',
      ),
      excerpt: _t(
        "The women in Modi'in are receiving a new and powerful envelope that will change everything they knew about personal resilience, security and",
        'הנשים במודיעין מקבלות מעטפת חדשה ועוצמתית שתשנה כל מה שידעו על חוסן אישי, ביטחון ו',
      ),
      date: _t('August 3, 2026 | 4:32 p.m.', '3 באוגוסט 2026 | 16:32'),
      colors: const [Color(0xFF55606E), Color(0xFF10151C)],
    ),
  ];

  List<_Article> get _business => [
    _Article(
      id: 'biz_0',
      title: _t(
        "The agent who succeeded in conquering Modi'in: This is how a local empire was built",
        'המתווך שהצליח לכבוש את מודיעין: כך נבנתה אימפריה מקומית',
      ),
      excerpt: _t(
        'Over the past decade, the world of online poker in Israel has undergone a quiet revolution. International brands, new platforms, and young players',
        'בעשור האחרון עבר עולם הפוקר המקוון בישראל מהפכה שקטה. מותגים בינלאומיים, פלטפורמות חדשות ושחקנים צעירים',
      ),
      date: _t('August 4, 2026 | 4:36 p.m.', '4 באוגוסט 2026 | 16:36'),
      colors: const [Color(0xFF1F5E6E), Color(0xFF06161C)],
    ),
    _Article(
      id: 'biz_1',
      title: _t(
        'Special vacation ideas for families looking for a real change from routine',
        'רעיונות חופשה מיוחדים למשפחות שמחפשות שינוי אמיתי מהשגרה',
      ),
      excerpt: _t(
        'More and more families are looking for a vacation that is much more than "just another" week at a hotel with a pool. The desire to combine a deep',
        'יותר ויותר משפחות מחפשות חופשה שהיא הרבה מעבר לעוד שבוע במלון עם בריכה. הרצון לשלב חוויה עמוקה',
      ),
      date: _t('August 3, 2026 | 1:30 p.m.', '3 באוגוסט 2026 | 13:30'),
      colors: const [Color(0xFF8A6A3B), Color(0xFF221709)],
    ),
    _Article(
      id: 'biz_2',
      title: _t(
        'Recommended lawyer in Modiin – Yedidia Bleugrund who will fight for you',
        'עורך דין מומלץ במודיעין – ידידיה בלוגרונד שילחם עבורכם',
      ),
      excerpt: _t(
        "We all know the sense of local pride that accompanies us as residents of Modi'in Maccabim Re'ut. Our city is clean, well-kept, the community here i",
        'כולנו מכירים את תחושת הגאווה המקומית שמלווה אותנו כתושבי מודיעין מכבים רעות. העיר שלנו נקייה, מטופחת, הקהילה כאן',
      ),
      date: _t('August 3, 2026 | 4:34 p.m.', '3 באוגוסט 2026 | 16:34'),
      colors: const [Color(0xFF334E7A), Color(0xFF090F22)],
    ),
    _Article(
      id: 'biz_3',
      title: _t(
        'Fingerprint Time Clocks and Attendance Apps: The Complete Guide to Smart Employee Control',
        'שעוני נוכחות טביעת אצבע ואפליקציות נוכחות: המדריך המלא לבקרת עובדים חכמה',
      ),
      excerpt: _t(
        'Employee attendance management has transformed in recent years from a manual and cumbersome process to a smart digital system, based on',
        'ניהול נוכחות עובדים הפך בשנים האחרונות מתהליך ידני ומסורבל למערכת דיגיטלית חכמה, המבוססת על',
      ),
      date: _t('August 3, 2026 | 4:32 p.m.', '3 באוגוסט 2026 | 16:32'),
      colors: const [Color(0xFF4C4F63), Color(0xFF101120)],
    ),
    _Article(
      id: 'biz_4',
      title: _t(
        'The Complete Guide to Choosing Tefillin for a Bar Mitzvah: Everything You Need to Know',
        'המדריך המלא לבחירת תפילין לבר מצווה: כל מה שצריך לדעת',
      ),
      excerpt: _t(
        'The Complete Guide to Choosing Tefillin for a Bar Mitzvah: Everything You Need to Know Reaching the age of mitzvah is a significant milestone in',
        'הגעה לגיל מצוות היא ציון דרך משמעותי בחיי הנער ובני המשפחה, והבחירה בתפילין היא חלק מרכזי ממנו',
      ),
      date: _t('August 3, 2026 | 4:32 p.m.', '3 באוגוסט 2026 | 16:32'),
      colors: const [Color(0xFF6B4A2E), Color(0xFF1A0F07)],
    ),
    _Article(
      id: 'biz_5',
      title: _t(
        'The complete and updated guide: Recommended restaurants in central Israel for 2026',
        'המדריך המלא והמעודכן: מסעדות מומלצות במרכז הארץ לשנת 2026',
      ),
      excerpt: _t(
        'The Israeli culinary world has come a long way, but the year 2026 marks a new peak in which the center becomes the beating heart of innovation',
        'עולם הקולינריה הישראלי עשה כברת דרך, אך שנת 2026 מסמנת שיא חדש שבו המרכז הופך ללב הפועם של החדשנות',
      ),
      date: _t('August 3, 2026 | 4:32 p.m.', '3 באוגוסט 2026 | 16:32'),
      colors: const [Color(0xFF7A3B4A), Color(0xFF1E0A10)],
    ),
  ];

  // ═══════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isHebrew ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            _buildStickyNavbar(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 48),
                    _centered(child: _buildHero()),
                    const SizedBox(height: 64),
                    _centered(child: _buildMainRow()),
                    const SizedBox(height: 103),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 1600px content column (160px page padding at 1920).
  Widget _centered({required Widget child}) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1600),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: child,
      ),
    );
  }

  // ─────────────────────────────────────────────
  // STICKY NAVBAR
  // ─────────────────────────────────────────────
  Widget _buildStickyNavbar() {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 160),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/'),
            child: SvgPicture.asset(
              'assets/images/logo_white.svg',
              width: 90,
              height: 48,
              colorFilter: const ColorFilter.mode(AppColors.midBlue, BlendMode.srcIn),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Row(
              children: _navItems.map((item) {
                return Expanded(
                  child: _NavLinkButton(
                    label: item.label,
                    isActive: item.isActive,
                    hasDropdown: item.hasDropdown,
                    onTap: () => context.go(item.route),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: 20),
          // Language toggle
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => setState(() => _isHebrew = !_isHebrew),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsetsDirectional.only(end: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(IconsaxPlusLinear.global, size: 18, color: AppColors.midBlue),
                    const SizedBox(width: 6),
                    Text(_isHebrew ? 'עב | EN' : 'EN | עב',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.midBlue)),
                  ],
                ),
              ),
            ),
          ),
          // CTA
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                decoration: BoxDecoration(
                  color: AppColors.midBlue,
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Text(_t('Contact Us', 'צור קשר'),
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HERO — 1014 featured card + two 576 stacked cards
  // ─────────────────────────────────────────────
  Widget _buildHero() {
    return SizedBox(
      height: 552,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 1014, child: _buildFeaturedCard()),
          const SizedBox(width: 10),
          Expanded(
            flex: 576,
            child: Column(
              children: [
                Expanded(
                  child: _buildHeroSideCard(
                    _heroSide[0],
                    badge: _t('Municipality', 'עירייה'),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _buildHeroSideCard(
                    _heroSide[1],
                    badge: _t('Urban', 'עירוני'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCard() {
    final article = _featured;
    return _HoverCard(
      onTap: () => context.push('/article/${article.id}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _imagePlaceholder(article.colors, radius: 0, glyphSize: 72),
            // Bottom scrim — starts 39px below the top of the card
            Positioned(
              left: 0,
              right: 0,
              top: 39,
              bottom: 0,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0xFF000000)],
                    stops: [0.5543, 1.0],
                  ),
                ),
              ),
            ),
            // Badges
            PositionedDirectional(
              start: 16,
              top: 16,
              child: Row(
                children: [
                  _badge(
                    label: _t('Now in Modiin', 'עכשיו במודיעין'),
                    background: _kLime,
                    foreground: AppColors.navy,
                    icon: IconsaxPlusLinear.location,
                  ),
                  const SizedBox(width: 12),
                  _badge(
                    label: _t('Municipality', 'עירייה'),
                    background: AppColors.turquoise,
                    foreground: Colors.white,
                  ),
                ],
              ),
            ),
            // Headline
            PositionedDirectional(
              start: 28,
              bottom: 29,
              end: 34,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    article.title,
                    style: GoogleFonts.nunito(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      height: 34 / 28,
                      color: Colors.white,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 11),
                  _dateRow(article.date, color: Colors.white, iconColor: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSideCard(_Article article, {required String badge}) {
    return _HoverCard(
      onTap: () => context.push('/article/${article.id}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _imagePlaceholder(article.colors, radius: 0, glyphSize: 48),
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0xFF000000)],
                    stops: [0.3137, 1.0],
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              start: 16,
              top: 16,
              child: _badge(
                label: badge,
                background: AppColors.turquoise,
                foreground: Colors.white,
              ),
            ),
            PositionedDirectional(
              start: 18,
              bottom: 27,
              end: 23,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    article.title,
                    style: GoogleFonts.nunito(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      height: 30 / 24,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 11),
                  _dateRow(article.date, color: Colors.white, iconColor: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge({
    required String label,
    required Color background,
    required Color foreground,
    IconData? icon,
  }) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: foreground),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 24 / 14,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateRow(String date, {required Color color, required Color iconColor}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(IconsaxPlusLinear.calendar_1, size: 16, color: iconColor),
        const SizedBox(width: 9),
        Text(
          date,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 17 / 14,
            color: color,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // MAIN ROW — ad column + article sections
  // ─────────────────────────────────────────────
  Widget _buildMainRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 370, child: _buildAdColumn()),
        const SizedBox(width: 48),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                title: _t('Municipality Updates', 'עדכוני עירייה'),
                articles: _municipality,
              ),
              const SizedBox(height: 72),
              _buildSection(
                title: _t('Urban', 'עירוני'),
                articles: _urban,
              ),
              const SizedBox(height: 72),
              _buildSection(
                title: _t('Business', 'עסקים'),
                articles: _business,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdColumn() {
    return Column(
      children: [
        _adSlot(630, const [Color(0xFFD4E4F7), Color(0xFF9FC0E2)]),
        const SizedBox(height: 365),
        _adSlot(225, const [Color(0xFFE0D4C8), Color(0xFFC0A891)]),
        const SizedBox(height: 32),
        _adSlot(370, const [Color(0xFFD8E8D4), Color(0xFFA8C9A2)]),
        const SizedBox(height: 32),
        _adSlot(630, const [Color(0xFFE4D8F0), Color(0xFFBCA6D6)]),
      ],
    );
  }

  Widget _adSlot(double height, List<Color> colors) {
    return Container(
      width: 370,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Center(
        child: Icon(
          IconsaxPlusLinear.image,
          size: 40,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<_Article> articles}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.nunito(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            height: 34 / 28,
            color: AppColors.midBlue,
          ),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 64) / 3;
            return Column(
              children: [
                _cardRow(articles, 0, cardWidth),
                const SizedBox(height: 40),
                _cardRow(articles, 3, cardWidth),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _cardRow(List<_Article> articles, int start, double cardWidth) {
    final children = <Widget>[];
    for (var i = 0; i < 3; i++) {
      if (i > 0) children.add(const SizedBox(width: 32));
      final index = start + i;
      if (index < articles.length) {
        children.add(_ArticleCard(
          article: articles[index],
          width: cardWidth,
          onTap: () => context.push('/article/${articles[index].id}'),
        ));
      } else {
        // Figma keeps the empty slots in place (opacity 0)
        children.add(SizedBox(width: cardWidth, height: 404));
      }
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  // ─────────────────────────────────────────────
  // FOOTER
  // ─────────────────────────────────────────────
  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      color: AppColors.midBlue,
      padding: const EdgeInsets.only(top: 64),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1600),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 900) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildFooterContact()),
                        const SizedBox(width: 40),
                        Expanded(flex: 2, child: _buildFooterLinks(_t('Modiin4u', 'מודיעין4u'), [_t('Home', 'בית'), _t('About Us', 'אודותינו'), _t('Contact Us', 'צור קשר'), _t('Privacy Policy', 'מדיניות פרטיות'), _t('Terms of Use', 'תנאי שימוש'), _t('Accessibility Statement', 'הצהרת נגישות')])),
                        const SizedBox(width: 40),
                        Expanded(flex: 2, child: _buildFooterLinks(_t('Explore Modiin', 'גלו את מודיעין'), [_t('News', 'חדשות'), _t('Events', 'אירועים'), _t('Businesses', 'עסקים'), _t('Professionals', 'בעלי מקצוע'), _t('Real Estate', 'נדל"ן'), _t('Map', 'מפה'), _t('Restaurants', 'מסעדות'), _t('Deals', 'מבצעים')])),
                        const SizedBox(width: 40),
                        Expanded(flex: 2, child: _buildFooterLinks(_t('Popular Categories', 'קטגוריות פופולריות'), [_t('Restaurants', 'מסעדות'), _t('Coffee Shops', 'בתי קפה'), _t('Bars', 'ברים'), _t('Professionals', 'בעלי מקצוע'), _t('Real Estate', 'נדל"ן'), _t('Local Businesses', 'עסקים מקומיים'), _t('Events', 'אירועים'), _t('News', 'חדשות')])),
                        const SizedBox(width: 40),
                        Expanded(flex: 3, child: _buildFooterAbout()),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFooterContact(),
                      const SizedBox(height: 40),
                      _buildFooterAbout(),
                    ],
                  );
                },
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white24))),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_t('All Rights Reserved to modiin4u.co.il, 2026', 'כל הזכויות שמורות ל-modiin4u.co.il, 2026'),
                            style: GoogleFonts.inter(fontSize: 14, color: _kBorder)),
                        Row(
                          children: [
                            Text(_t('Terms of Use', 'תנאי שימוש'), style: GoogleFonts.inter(fontSize: 14, color: _kBorder)),
                            const SizedBox(width: 4),
                            const Text('|', style: TextStyle(color: _kBorder)),
                            const SizedBox(width: 4),
                            Text(_t('Privacy Policy', 'מדיניות פרטיות'), style: GoogleFonts.inter(fontSize: 14, color: _kBorder)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => launchUrl(Uri.parse('https://personaai.me/')),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Powered by ', style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.6))),
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
                                ).createShader(bounds),
                                child: Text('PersonaAI', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterContact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_t('We are here for\nany questions.', 'אנחנו כאן\nלכל שאלה.'),
            style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w500, color: Colors.white, height: 1.22)),
        const SizedBox(height: 40),
        _FooterContactRow(icon: IconsaxPlusLinear.call, label: _t('Phone', 'טלפון'), value: '058-4770195'),
        _FooterContactRow(icon: IconsaxPlusLinear.sms, label: _t('Email', 'אימייל'), value: 'modiin4uoffice@gmail.com'),
        _FooterContactRow(icon: IconsaxPlusLinear.message, label: _t('WhatsApp', 'וואטסאפ'), value: '058-4770195'),
        const SizedBox(height: 16),
        Text(_t('Our Socials', 'הרשתות שלנו'), style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 19),
        Row(
          children: [
            _socialIcon(child: Text('f', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white))),
            _socialIcon(child: Text('X', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white))),
            _socialIcon(child: Text('in', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white))),
            _socialIcon(child: const Icon(IconsaxPlusLinear.instagram, size: 18, color: Colors.white)),
            _socialIcon(child: const Icon(IconsaxPlusLinear.music, size: 18, color: Colors.white)),
          ],
        ),
      ],
    );
  }

  Widget _socialIcon({required Widget child}) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 9),
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white38)),
        child: Center(child: child),
      ),
    );
  }

  Widget _buildFooterLinks(String title, List<String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 24),
        ...links.map((link) => Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Text(link, style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withValues(alpha: 0.9))),
        )),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_t('View all', 'הצג הכל'),
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.turquoise)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.turquoise),
          ],
        ),
      ],
    );
  }

  Widget _buildFooterAbout() {
    final alignment = _isHebrew ? CrossAxisAlignment.start : CrossAxisAlignment.end;
    final textAlign = _isHebrew ? TextAlign.start : TextAlign.end;
    return Column(
      crossAxisAlignment: alignment,
      children: [
        SvgPicture.asset('assets/images/logo_white.svg', width: 164, height: 88),
        const SizedBox(height: 24),
        Text(_t('Modiin for You', 'מודיעין בשבילך'), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white), textAlign: textAlign),
        const SizedBox(height: 16),
        Text(
          _t('We are not just a news site – we are the beating heart of Modiin! A local media and public relations organization that lives and breathes our city.',
             'אנחנו לא סתם אתר חדשות – אנחנו הלב הפועם של מודיעין! ארגון מדיה ויחסי ציבור מקומי שחי ונושם את העיר שלנו.'),
          style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.85), height: 1.4),
          textAlign: textAlign,
        ),
        const SizedBox(height: 24),
        Text(_t('Download Our App', 'הורידו את האפליקציה'), style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white), textAlign: textAlign),
        const SizedBox(height: 16),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Wrap(
            spacing: 12, runSpacing: 8, alignment: WrapAlignment.end,
            children: [
              _AppStoreBtn(store: 'App Store', label: 'Download on the', svgAsset: 'assets/images/apple_logo.svg', isApple: true),
              _AppStoreBtn(store: 'Google Play', label: 'GET IT ON', svgAsset: 'assets/images/google_play.svg'),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// SHARED PIECES
// ═══════════════════════════════════════════════

/// Gradient stand-in until real article photography is wired up.
Widget _imagePlaceholder(List<Color> colors, {double radius = 12, double glyphSize = 40}) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ),
    ),
    child: Center(
      child: Icon(
        IconsaxPlusLinear.image,
        size: glyphSize,
        color: Colors.white.withValues(alpha: 0.12),
      ),
    ),
  );
}

class _Article {
  final String id, title, date, excerpt;
  final List<Color> colors;
  const _Article({
    required this.id,
    required this.title,
    required this.date,
    required this.colors,
    this.excerpt = '',
  });
}

class _NavItem {
  final String label, route;
  final bool hasDropdown, isActive;
  const _NavItem({required this.label, required this.route, this.hasDropdown = false, this.isActive = false});
}

/// 372.67 × 404 article card — image, 2-line title, 1-line excerpt, date.
class _ArticleCard extends StatefulWidget {
  final _Article article;
  final double width;
  final VoidCallback onTap;
  const _ArticleCard({required this.article, required this.width, required this.onTap});

  @override
  State<_ArticleCard> createState() => _ArticleCardState();
}

class _ArticleCardState extends State<_ArticleCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.article;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          width: widget.width,
          height: 404,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedScale(
                scale: _hovered ? 1.015 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: SizedBox(
                  width: widget.width,
                  height: 270,
                  child: _imagePlaceholder(a.colors, glyphSize: 40),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 50,
                child: Text(
                  a.title,
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    height: 25 / 20,
                    color: _hovered ? AppColors.midBlue : Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 21,
                child: Text(
                  a.excerpt,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                    color: _kBodyGrey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(IconsaxPlusLinear.calendar_1, size: 16, color: _kIconGrey),
                  const SizedBox(width: 9),
                  Text(
                    a.date,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 17 / 14,
                      color: _kBodyGrey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Subtle lift on hover for the hero cards.
class _HoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _HoverCard({required this.child, required this.onTap});

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.008 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: widget.child,
        ),
      ),
    );
  }
}

class _NavLinkButton extends StatefulWidget {
  final String label;
  final bool isActive, hasDropdown;
  final VoidCallback onTap;
  const _NavLinkButton({required this.label, this.isActive = false, this.hasDropdown = false, required this.onTap});

  @override
  State<_NavLinkButton> createState() => _NavLinkButtonState();
}

class _NavLinkButtonState extends State<_NavLinkButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(
              color: widget.isActive ? AppColors.midBlue : Colors.transparent,
              width: 3,
            )),
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              decoration: BoxDecoration(
                color: _hovered && !widget.isActive ? Colors.black.withValues(alpha: 0.04) : Colors.transparent,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      widget.label,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w500,
                        color: widget.isActive ? AppColors.midBlue : const Color(0xFF0F161E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.hasDropdown) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF21272A)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterContactRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _FooterContactRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 34),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white38)),
            child: Center(child: Icon(icon, size: 16, color: Colors.white)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.9))),
                const SizedBox(height: 4),
                Text(value,
                    style: GoogleFonts.inter(fontSize: 16, color: Colors.white),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppStoreBtn extends StatelessWidget {
  final String store, label, svgAsset;
  final bool isApple;
  const _AppStoreBtn({required this.store, required this.label, required this.svgAsset, this.isApple = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(svgAsset, width: 24, height: 24,
              colorFilter: isApple ? const ColorFilter.mode(Colors.white, BlendMode.srcIn) : null),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w400, color: Colors.white.withValues(alpha: 0.8))),
              const SizedBox(height: 1),
              Text(store, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }
}
