import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../../../core/data/wp_content.dart';

// ═══════════════════════════════════════════════════════════
// Web Modiin News — full desktop layout from Figma
// (Modiin News — 1920 × 4341)
// ═══════════════════════════════════════════════════════════

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

  /// Real articles exported from the WordPress site. Empty until the asset
  /// loads, and empty forever if it fails — both cases fall through to the
  /// demo content below, so the page always renders.
  List<WpItem> _wp = const [];

  @override
  void initState() {
    super.initState();
    loadWpItems('wp_news').then((items) {
      if (mounted) setState(() => _wp = items);
    });
  }

  String _t(String en, String he) => _isHebrew ? he : en;

  /// Every category the site publishes under, in the order it uses most.
  /// The page used to hard-code the first three and drop the other six.
  static const _sections = [
    ('עדכוני עירייה', 'Municipality Updates'),
    ('עירוני', 'Urban'),
    ('עסקים', 'Business'),
    ('אנשים', 'People'),
    ('קולינריה', 'Food & Drink'),
    ('אטרקציות וטיולים במודיעין', 'Attractions & Trips'),
    ('ספורט וכושר', 'Sport & Fitness'),
    ('נדל״ן', 'Real Estate'),
    ('חדשות מודיעין', 'Modiin News'),
  ];

  /// Content is published in Hebrew only, so both languages show the
  /// original title; only the date format follows the toggle.
  _Article _toArticle(WpItem item, List<Color> colors) => _Article(
    id: item.id.toString(),
    title: item.title,
    excerpt: item.excerpt,
    date: item.formatDate(isHebrew: _isHebrew),
    imageUrl: item.image,
    rtlText: true,
    colors: colors,
  );

  /// The [count] most recent real articles in [term], or null when the
  /// export hasn't loaded or doesn't cover that section.
  List<_Article>? _wpSection(String term, int count, List<List<Color>> palette) {
    final matches = _wp.where((i) => i.hasTerm(term)).take(count).toList();
    if (matches.isEmpty) return null;
    return [
      for (var i = 0; i < matches.length; i++)
        _toArticle(matches[i], palette[i % palette.length]),
    ];
  }

  // ── Nav links ──
  // ═══════════════════════════════════════════════
  // DEMO CONTENT
  // ═══════════════════════════════════════════════

  _Article get _featuredDemo => _Article(
    id: 'featured',
    title: _t(
      "From now on, we can breathe a sigh of relief: The new municipal initiative that will give women in Modi'in complete confidence and tools for success",
      'מעכשיו אפשר לנשום לרווחה: היוזמה העירונית החדשה שתעניק לנשים במודיעין ביטחון מלא וכלים להצלחה',
    ),
    date: _t('August 5, 2026 | 4:36 p.m.', '5 באוגוסט 2026 | 16:36'),
    colors: const [Color(0xFF1A4E8A), Color(0xFF07112E)],
  );

  List<_Article> get _heroSideDemo => [
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

  List<_Article> get _municipalityDemo => [
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

  List<_Article> get _urbanDemo => [
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

  List<_Article> get _businessDemo => [
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
  // LIVE CONTENT — WordPress export first, demo as the fallback
  // ═══════════════════════════════════════════════

  static const _heroPalette = [
    [Color(0xFF1A4E8A), Color(0xFF07112E)],
    [Color(0xFF26607F), Color(0xFF081428)],
    [Color(0xFF3B5A7A), Color(0xFF0A1428)],
  ];
  static const _cardPalette = [
    [Color(0xFF2E5C8A), Color(0xFF0C1A33)],
    [Color(0xFF7A3B4A), Color(0xFF1E0A10)],
    [Color(0xFF3F6B4F), Color(0xFF0E1C14)],
    [Color(0xFF6B5A3B), Color(0xFF1C160C)],
    [Color(0xFF4A3B7A), Color(0xFF120E22)],
    [Color(0xFF2F6B6B), Color(0xFF0B1C1C)],
  ];

  _Article get _featured =>
      _wp.isEmpty ? _featuredDemo : _toArticle(_wp.first, _heroPalette[0]);

  List<_Article> get _heroSide {
    if (_wp.length < 3) return _heroSideDemo;
    return [
      _toArticle(_wp[1], _heroPalette[1]),
      _toArticle(_wp[2], _heroPalette[2]),
    ];
  }

  /// Sections that actually have articles behind them, so a category the
  /// site has not published to lately leaves no empty heading on the page.
  List<(String, List<_Article>)> get _liveSections {
    if (_wp.isEmpty) {
      return [
        (_t('Municipality Updates', 'עדכוני עירייה'), _municipalityDemo),
        (_t('Urban', 'עירוני'), _urbanDemo),
        (_t('Business', 'עסקים'), _businessDemo),
      ];
    }
    final out = <(String, List<_Article>)>[];
    for (final (he, en) in _sections) {
      final articles = _wpSection(he, 6, _cardPalette);
      if (articles != null) out.add((_t(en, he), articles));
    }
    return out;
  }

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
            WebNavbar(
              isHebrew: _isHebrew,
              activeId: 'news',
              onToggleLanguage: () => setState(() => _isHebrew = !_isHebrew),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 48),
                    _centered(child: _buildHero()),
                    const SizedBox(height: 64),
                    _centered(child: _buildMainRow()),
                    const SizedBox(height: 103),
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
            _articleImage(article, radius: 0, glyphSize: 72),
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
                    textDirection: article.textDirection,
                    textAlign: article.textAlign,
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
            _articleImage(article, radius: 0, glyphSize: 48),
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
                    textDirection: article.textDirection,
                    textAlign: article.textAlign,
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
              for (final (title, articles) in _liveSections) ...[
                _buildSection(title: title, articles: articles),
                const SizedBox(height: 72),
              ],
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
}

// ═══════════════════════════════════════════════
// SHARED PIECES
// ═══════════════════════════════════════════════

/// Article photo, falling back to the gradient stand-in while it loads,
/// when it fails, or on demo articles that have no photo at all.
///
/// `webHtmlElementStrategy` matters here: the WordPress uploads are served
/// without CORS headers, so CanvasKit cannot decode them itself and has to
/// hand the URL to a plain <img> element.
Widget _articleImage(_Article article, {double radius = 12, double glyphSize = 40}) {
  final fallback = _imagePlaceholder(article.colors, radius: radius, glyphSize: glyphSize);
  if (article.imageUrl.isEmpty) return fallback;
  return ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: Image.network(
      article.imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      errorBuilder: (_, _, _) => fallback,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : fallback,
    ),
  );
}

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
  /// Remote photo from the WordPress export; empty on demo articles, which
  /// keep falling back to the [colors] gradient.
  final String imageUrl;
  /// Real articles are published in Hebrew whichever way the page toggle is
  /// set, so their text lays out RTL even while the chrome is in English.
  final bool rtlText;
  final List<Color> colors;
  const _Article({
    required this.id,
    required this.title,
    required this.date,
    required this.colors,
    this.excerpt = '',
    this.imageUrl = '',
    this.rtlText = false,
  });

  TextDirection? get textDirection => rtlText ? TextDirection.rtl : null;
  TextAlign? get textAlign => rtlText ? TextAlign.right : null;
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
                  child: _articleImage(a, glyphSize: 40),
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
                  textDirection: a.textDirection,
                  textAlign: a.textAlign,
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
                  textDirection: a.textDirection,
                  textAlign: a.textAlign,
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
