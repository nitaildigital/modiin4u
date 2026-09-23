import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/web_chrome.dart';

// ═══════════════════════════════════════════════════════════
// Web Modiin News Detail — full desktop layout from Figma
// (Modiin News Detail — 1920 × 4383)
// ═══════════════════════════════════════════════════════════

const _kBorder = Color(0xFFE7E7E7);
const _kPanelBg = Color(0xFFF8F8F8);
const _kBodyText = Color(0xFF3D3D3D);
const _kGrey = Color(0xFF5F5E5A);
const _kIconGrey = Color(0xFF6D6D6D);
const _kAvatarBg = Color(0xFFEDF3FE);

class WebArticleContent extends StatefulWidget {
  final String articleId;
  const WebArticleContent({super.key, required this.articleId});

  @override
  State<WebArticleContent> createState() => _WebArticleContentState();
}

class _WebArticleContentState extends State<WebArticleContent> {
  bool _isHebrew = false;
  bool _saved = false;
  bool _commentsExpanded = false;

  String _t(String en, String he) => _isHebrew ? he : en;

  // ── Nav links ──
  // ═══════════════════════════════════════════════
  // ARTICLE CONTENT
  // ═══════════════════════════════════════════════

  String get _title => _t(
    "From now on, we can breathe a sigh of relief: The new municipal initiative that will give women in Modi'in complete confidence and tools for success.",
    'מעכשיו אפשר לנשום לרווחה: היוזמה העירונית החדשה שתעניק לנשים במודיעין ביטחון מלא וכלים להצלחה.',
  );

  List<String?> get _body => [
    _t(
      "The women of Modi'in are receiving a new and powerful envelope that will change everything they knew about personal resilience, security and independence. The Municipality of Modi'in Maccabim Re'ut is launching a comprehensive urban plan that will give you all the tools you need to move forward with peace of mind and complete confidence.",
      'הנשים במודיעין מקבלות מעטפת חדשה ועוצמתית שתשנה כל מה שידעו על חוסן אישי, ביטחון ועצמאות. עיריית מודיעין מכבים רעות משיקה תוכנית עירונית מקיפה שתעניק לכן את כל הכלים כדי להתקדם בשקט נפשי ובביטחון מלא.',
    ),
    _t(
      'The new program is being launched under the leadership of the Multidisciplinary Center, managed by Dr. Orna Mager, Advisor to the Mayor for Gender Equality, together with the Education, Learning and Entrepreneurship Division. The important project was built in close collaboration with the Authority for the Advancement of the Status of Women, the Ministry of Welfare and Social Security, the Municipal Health Department, and the Treatment Center for Family Peace and Sexual Trauma in the Social Services Division.',
      'התוכנית החדשה יוצאת לדרך בהובלת המרכז הרב תחומי, בניהולה של ד"ר אורנה מגר, יועצת ראש העיר לשוויון מגדרי, יחד עם אגף החינוך, הלמידה והיזמות. הפרויקט החשוב נבנה בשיתוף פעולה הדוק עם הרשות לקידום מעמד האישה, משרד הרווחה והביטחון החברתי, אגף הבריאות העירוני והמרכז לטיפול בשלום המשפחה ובטראומה מינית באגף השירותים החברתיים.',
    ),
    _t(
      'The first course that has already been launched is a practical self-defense course, designed to directly strengthen the sense of competence and personal security of each and every one of us in the public space.',
      'הקורס הראשון שכבר יצא לדרך הוא קורס מעשי בהגנה עצמית, שנועד לחזק באופן ישיר את תחושת המסוגלות והביטחון האישי של כל אחת מאיתנו במרחב הציבורי.',
    ),
    null, // image 38
    _t(
      'Throughout the coming year, a wide variety of workshops, professional meetings, and events will await you that will touch precisely on the points that are important to us:',
      'במהלך השנה הקרובה יחכו לכן מגוון רחב של סדנאות, מפגשים מקצועיים ואירועים שייגעו בדיוק בנקודות שחשובות לנו:',
    ),
  ];

  List<String> get _bullets => [
    _t(
      'A special package to strengthen the "Recruited Women" Program: resilience of women in reserve and permanent service.',
      'תוכנית "נשים מגויסות": מעטפת מיוחדת לחיזוק החוסן של נשים בשירות מילואים ובשירות קבע.',
    ),
    _t(
      'Trauma-sensitive therapeutic yoga Spaces of healing and growth: and a unique writing workshop used as a tool for healing.',
      'מרחבים של ריפוי וצמיחה: יוגה טיפולית רגישת טראומה וסדנת כתיבה ייחודית ככלי לריפוי.',
    ),
    _t(
      'Events to mark the International Day for Safety and awareness: Elimination of Violence against Women and important training to identify red flags and prevent violence.',
      'בטיחות ומודעות: אירועים לציון היום הבינלאומי למאבק באלימות נגד נשים והדרכות חשובות לזיהוי דגלים אדומים ומניעת אלימות.',
    ),
    _t(
      'A practical workshop for optimal Financial independence: management that will give you complete control.',
      'עצמאות כלכלית: סדנה מעשית לניהול פיננסי מיטבי שתעניק לכן שליטה מלאה.',
    ),
  ];

  List<String?> get _bodyAfter => [
    _t(
      'All of these activities are offered at subsidized prices that are particularly accessible to the public, at a symbolic cost of only 50 shekels per workshop.',
      'כל הפעילויות מוצעות במחירים מסובסדים ונגישים במיוחד לציבור, בעלות סמלית של 50 שקלים בלבד לסדנה.',
    ),
    null, // image 39
    _t(
      'Want to receive all the first updates and secure your spot? All the details and the registration form are waiting for you right here:',
      'רוצות לקבל את כל העדכונים ראשונות ולהבטיח את מקומכן? כל הפרטים וטופס ההרשמה מחכים לכן כאן:',
    ),
  ];

  List<_Related> get _related => [
    _Related(
      id: 'muni_1',
      title: _t(
        'An end to cycle worries: Modiin is moving to a new and efficient model that will put your mind at ease',
        'סוף לדאגות המחזור: מודיעין עוברת למודל חדש ויעיל שירגיע אתכם',
      ),
      date: _t('August 5, 2026 | 4:30 p.m.', '5 באוגוסט 2026 | 16:30'),
      colors: const [Color(0xFF2C6E8F), Color(0xFF0A1A2E)],
    ),
    _Related(
      id: 'muni_0',
      title: _t(
        'An end to cycle worries: Modiin is moving to a new and efficient model that will put your mind at ease',
        'סוף לדאגות המחזור: מודיעין עוברת למודל חדש ויעיל שירגיע אתכם',
      ),
      date: _t('August 5, 2026 | 4:30 p.m.', '5 באוגוסט 2026 | 16:30'),
      colors: const [Color(0xFF4A7A52), Color(0xFF0E1C1A)],
    ),
    _Related(
      id: 'muni_2',
      title: _t(
        "No more heart palpitations: The new tool that will help parents in Modi'in register for after-school",
        'לא עוד דפיקות לב: הכלי החדש שיעזור להורים במודיעין להירשם לצהרונים',
      ),
      date: _t('August 5, 2026 | 4:30 p.m.', '5 באוגוסט 2026 | 16:30'),
      colors: const [Color(0xFF8A5A3B), Color(0xFF241209)],
    ),
    _Related(
      id: 'muni_4',
      title: _t(
        "An engineering degree close to home: The Multidisciplinary Center in Modi'in and ORT College",
        'תואר בהנדסה קרוב לבית: המרכז הרב תחומי במודיעין ומכללת אורט',
      ),
      date: _t('August 5, 2026 | 4:30 p.m.', '5 באוגוסט 2026 | 16:30'),
      colors: const [Color(0xFF26607F), Color(0xFF081428)],
    ),
  ];

  List<_Comment> get _comments => [
    _Comment(
      initials: 'SC',
      name: _t('Zeev Schumacher', 'זאב שומכר'),
      date: _t('August 5, 2026 · 5:12 PM', '5 באוגוסט 2026 · 17:12'),
      text: _t(
        'This is such an important initiative for women in Modiin. It’s great to see practical tools and support being made available locally.',
        'זו יוזמה כל כך חשובה לנשים במודיעין. משמח לראות כלים מעשיים ותמיכה שזמינים כאן בעיר.',
      ),
    ),
    _Comment(
      initials: 'MZ',
      name: _t('Moran Zelig', 'מורן זליג'),
      date: _t('August 5, 2026 · 6:03 PM', '5 באוגוסט 2026 · 18:03'),
      text: _t(
        'I really like the focus on confidence and personal safety. These workshops can make a real difference in everyday life.',
        'אני מאוד אוהבת את הדגש על ביטחון ובטיחות אישית. הסדנאות האלה יכולות לעשות שינוי אמיתי בחיי היומיום.',
      ),
    ),
    _Comment(
      initials: 'YL',
      name: _t('Yael Levi', 'יעל לוי'),
      date: _t('August 5, 2026 · 7:24 PM', '5 באוגוסט 2026 · 19:24'),
      text: _t(
        'The financial independence workshop sounds especially useful. I hope more residents hear about these programs.',
        'סדנת העצמאות הכלכלית נשמעת שימושית במיוחד. אני מקווה שעוד תושבים ישמעו על התוכניות האלה.',
      ),
    ),
    _Comment(
      initials: 'NG',
      name: _t('Noam Garcia', 'נועם גרסיה'),
      date: _t('August 6, 2026 · 9:15 AM', '6 באוגוסט 2026 · 09:15'),
      text: _t(
        'It’s wonderful to have these kinds of activities available in the city at an affordable price. Looking forward to attending one of the workshops.',
        'נפלא שיש פעילויות כאלה בעיר במחיר נגיש. מחכה להגיע לאחת הסדנאות.',
      ),
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
            WebNavbar(
              isHebrew: _isHebrew,
              activeId: 'news',
              onToggleLanguage: () => setState(() => _isHebrew = !_isHebrew),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 59),
                    _centered(child: _buildHeroCard()),
                    const SizedBox(height: 30),
                    _centered(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 976, child: _buildLeftColumn()),
                          const SizedBox(width: 198),
                          SizedBox(width: 426, child: _buildSidebar()),
                        ],
                      ),
                    ),
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
  // HERO — 808 image + 792 text panel, 436 tall
  // ─────────────────────────────────────────────
  Widget _buildHeroCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 436,
        child: Row(
          children: [
            Expanded(
              flex: 808,
              child: _imagePlaceholder(
                const [Color(0xFF1A4E8A), Color(0xFF07112E)],
                radius: 0,
                glyphSize: 64,
              ),
            ),
            Expanded(
              flex: 792,
              child: Container(
                color: _kPanelBg,
                padding: const EdgeInsetsDirectional.only(start: 40, end: 48),
                alignment: AlignmentDirectional.centerStart,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.turquoise,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _t('Municipality', 'עירייה'),
                        style: TextStyle(fontFamily: AppFonts.inter, 
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 24 / 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 21),
                    Text(
                      _title,
                      style: TextStyle(fontFamily: AppFonts.nunito, 
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        height: 39 / 32,
                        color: Colors.black,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 38),
                    _buildHeroMeta(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroMeta() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 241,
              child: _metaItem(
                icon: IconsaxPlusLinear.calendar_1,
                label: _t('August 5, 2026 | 4:34 p.m.', '5 באוגוסט 2026 | 16:34'),
                iconSize: 18,
              ),
            ),
            const SizedBox(width: 31),
            Flexible(
              child: _metaItem(
                icon: IconsaxPlusLinear.category,
                label: _t('An intelligence system for you', 'מערכת מודיעין בשבילך'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _metaItem(
          icon: IconsaxPlusLinear.message_text,
          label: _t('12 Comments', '12 תגובות'),
        ),
      ],
    );
  }

  Widget _metaItem({required IconData icon, required String label, double iconSize = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize, color: _kIconGrey),
        const SizedBox(width: 9),
        Flexible(
          child: Text(
            label,
            style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, height: 19 / 16, color: _kGrey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // LEFT COLUMN — stats bar, body, comments
  // ─────────────────────────────────────────────
  Widget _buildLeftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 808),
          child: _buildStatsBar(),
        ),
        const SizedBox(height: 114),
        _buildBody(),
        const SizedBox(height: 61),
        _buildInlineAd(),
        const SizedBox(height: 82),
        Text(
          _t('12 Comments', '12 תגובות'),
          style: TextStyle(fontFamily: AppFonts.nunito, 
            fontSize: 24,
            fontWeight: FontWeight.w600,
            height: 30 / 24,
            color: AppColors.midBlue,
          ),
        ),
        const SizedBox(height: 24),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 918),
          child: _buildComments(),
        ),
        const SizedBox(height: 40),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 918),
          child: _buildCommentPrompt(),
        ),
      ],
    );
  }

  Widget _buildStatsBar() {
    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _statItem(
                    icon: IconsaxPlusLinear.eye,
                    value: '359',
                    label: _t('Views', 'צפיות'),
                    startPadding: 0,
                  ),
                ),
                Expanded(
                  child: _statItem(
                    icon: _saved ? IconsaxPlusBold.archive : IconsaxPlusLinear.archive,
                    label: _t('Save', 'שמור'),
                    onTap: () => setState(() => _saved = !_saved),
                  ),
                ),
                Expanded(
                  child: _statItem(
                    icon: IconsaxPlusLinear.share,
                    value: '83',
                    label: _t('Share', 'שיתוף'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 9),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _shareIcon(const Color(0xFF1877F2), 'f'),
              const SizedBox(width: 19),
              _shareIcon(const Color(0xFF4CAF50), null, icon: IconsaxPlusBold.message),
              const SizedBox(width: 19),
              _shareIcon(Colors.black, 'X'),
              const SizedBox(width: 19),
              _shareIcon(const Color(0xFF2196F3), null, icon: IconsaxPlusBold.sms),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem({
    required IconData icon,
    String? value,
    required String label,
    double startPadding = 24,
    VoidCallback? onTap,
  }) {
    final content = Container(
      height: 48,
      padding: EdgeInsetsDirectional.only(start: startPadding, end: 24),
      decoration: const BoxDecoration(
        border: BorderDirectional(end: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.black),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (value != null) ...[
                  Text(value,
                      style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, height: 17 / 14, color: Colors.black)),
                  const SizedBox(height: 2),
                ],
                Text(
                  label.toUpperCase(),
                  style: TextStyle(fontFamily: AppFonts.inter, fontSize: 12, height: 15 / 12, color: Colors.black),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return content;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: content),
    );
  }

  Widget _shareIcon(Color color, String? letter, {IconData? icon}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Center(
          child: icon != null
              ? Icon(icon, size: 16, color: Colors.white)
              : Text(
                  letter!,
                  style: TextStyle(fontFamily: AppFonts.inter, 
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ARTICLE BODY
  // ─────────────────────────────────────────────
  Widget _buildBody() {
    final blocks = <Widget>[];

    void addParagraph(String text) {
      blocks.add(Text(
        text,
        style: TextStyle(fontFamily: AppFonts.inter, 
          fontSize: 18,
          fontWeight: FontWeight.w400,
          height: 1.6,
          color: _kBodyText,
        ),
      ));
    }

    for (final block in _body) {
      if (block == null) {
        blocks.add(_inlineImage(516, 344, const [Color(0xFF3E6FA5), Color(0xFF122542)]));
      } else {
        addParagraph(block);
      }
    }

    // Bulleted workshop list — 24px between items, 40px around the group
    blocks.add(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _bullets.length; i++) ...[
          if (i > 0) const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 11, end: 12),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.turquoise,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  _bullets[i],
                  style: TextStyle(fontFamily: AppFonts.inter, 
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    height: 1.6,
                    color: _kBodyText,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    ));

    for (final block in _bodyAfter) {
      if (block == null) {
        blocks.add(_inlineImage(583, 373, const [Color(0xFF4C7A5E), Color(0xFF12241B)]));
      } else {
        addParagraph(block);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          if (i > 0) const SizedBox(height: 40),
          blocks[i],
        ],
      ],
    );
  }

  Widget _inlineImage(double width, double height, List<Color> colors) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = width > constraints.maxWidth ? constraints.maxWidth : width;
        return Align(
          alignment: AlignmentDirectional.centerStart,
          child: SizedBox(
            width: w,
            height: height * (w / width),
            child: _imagePlaceholder(colors, glyphSize: 48),
          ),
        );
      },
    );
  }

  /// In-article ad banner (image 37 — 796 × 228).
  Widget _buildInlineAd() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth < 796 ? constraints.maxWidth : 796.0;
        return Center(
          child: SizedBox(
            width: w,
            height: 228 * (w / 796),
            child: _imagePlaceholder(
              const [Color(0xFFD4E4F7), Color(0xFF9FC0E2)],
              glyphSize: 40,
              glyphOpacity: 0.5,
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // COMMENTS
  // ─────────────────────────────────────────────
  Widget _buildComments() {
    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _comments.map((c) => _CommentTile(comment: c, replyLabel: _t('Reply', 'תגובה'))).toList(),
    );

    if (_commentsExpanded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          list,
          const SizedBox(height: 24),
          Center(child: _loadMoreButton(_t('Show Less', 'הצג פחות'))),
        ],
      );
    }

    return Stack(
      alignment: AlignmentDirectional.bottomCenter,
      children: [
        list,
        // Fade-out over the last stretch of the thread
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 222,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00FFFFFF), Color(0xFFFFFFFF)],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Center(child: _loadMoreButton(_t('Load More', 'טען עוד'))),
        ),
      ],
    );
  }

  Widget _loadMoreButton(String label) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _commentsExpanded = !_commentsExpanded),
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.midBlue),
            borderRadius: BorderRadius.circular(60),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(fontFamily: AppFonts.inter, 
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 24 / 16,
                  color: AppColors.midBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentPrompt() {
    return Container(
      height: 106,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 16),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(color: _kAvatarBg, shape: BoxShape.circle),
            child: const Center(
              child: Icon(IconsaxPlusLinear.user, size: 27, color: AppColors.midBlue),
            ),
          ),
          const SizedBox(width: 17),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('Write a comment', 'כתבו תגובה'),
                  style: TextStyle(fontFamily: AppFonts.inter, 
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    height: 24 / 20,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _t('To post a comment, you must be logged in.', 'כדי לפרסם תגובה יש להתחבר.'),
                  style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, height: 17 / 14, color: _kBodyText),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
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
                    const Icon(IconsaxPlusLinear.login, size: 20, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      _t('Login', 'התחברות'),
                      style: TextStyle(fontFamily: AppFonts.inter, 
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 24 / 16,
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
  // SIDEBAR — related news + ad
  // ─────────────────────────────────────────────
  Widget _buildSidebar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 7),
        Text(
          _t('More Related News', 'עוד חדשות קשורות'),
          style: TextStyle(fontFamily: AppFonts.inter, 
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 22 / 18,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 40),
        ..._related.map((r) => _RelatedRow(
              related: r,
              onTap: () => context.push('/article/${r.id}'),
            )),
        const SizedBox(height: 39),
        SizedBox(
          height: 260,
          child: _imagePlaceholder(
            const [Color(0xFFE0D4C8), Color(0xFFC0A891)],
            glyphSize: 40,
            glyphOpacity: 0.5,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // FOOTER
  // ─────────────────────────────────────────────
}

// ═══════════════════════════════════════════════
// SHARED PIECES
// ═══════════════════════════════════════════════

/// Gradient stand-in until real article photography is wired up.
Widget _imagePlaceholder(
  List<Color> colors, {
  double radius = 12,
  double glyphSize = 40,
  double glyphOpacity = 0.12,
}) {
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
        color: Colors.white.withValues(alpha: glyphOpacity),
      ),
    ),
  );
}

class _Related {
  final String id, title, date;
  final List<Color> colors;
  const _Related({required this.id, required this.title, required this.date, required this.colors});
}

class _Comment {
  final String initials, name, date, text;
  const _Comment({required this.initials, required this.name, required this.date, required this.text});
}

/// 426 × 121 related-news row — 110 × 80 thumb, 2-line title, date.
class _RelatedRow extends StatefulWidget {
  final _Related related;
  final VoidCallback onTap;
  const _RelatedRow({required this.related, required this.onTap});

  @override
  State<_RelatedRow> createState() => _RelatedRowState();
}

class _RelatedRowState extends State<_RelatedRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.related;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 121,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: const BoxDecoration(
            border: BorderDirectional(bottom: BorderSide(color: _kBorder)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 110,
                height: 80,
                child: _imagePlaceholder(r.colors, radius: 6, glyphSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      r.title,
                      style: TextStyle(fontFamily: AppFonts.nunito, 
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        height: 22 / 18,
                        color: _hovered ? AppColors.midBlue : Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(IconsaxPlusLinear.calendar_1, size: 16, color: _kIconGrey),
                        const SizedBox(width: 9),
                        Flexible(
                          child: Text(
                            r.date,
                            style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, height: 17 / 14, color: _kGrey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
      ),
    );
  }
}

/// 918 × 131 comment row — avatar, name + date, body, reply action.
class _CommentTile extends StatelessWidget {
  final _Comment comment;
  final String replyLabel;
  const _CommentTile({required this.comment, required this.replyLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        border: BorderDirectional(bottom: BorderSide(color: _kBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: AppColors.turquoise, shape: BoxShape.circle),
            child: Center(
              child: Text(
                comment.initials,
                style: TextStyle(fontFamily: AppFonts.inter, 
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 17 / 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.name,
                      style: TextStyle(fontFamily: AppFonts.inter, 
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 19 / 16,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      comment.date,
                      style: TextStyle(fontFamily: AppFonts.inter, fontSize: 12, height: 15 / 12, color: _kIconGrey),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  comment.text,
                  style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, height: 1.4, color: _kBodyText),
                ),
                const SizedBox(height: 12),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(IconsaxPlusLinear.undo, size: 20, color: AppColors.midBlue),
                      const SizedBox(width: 8),
                      Text(
                        replyLabel,
                        style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, height: 17 / 14, color: AppColors.midBlue),
                      ),
                    ],
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
