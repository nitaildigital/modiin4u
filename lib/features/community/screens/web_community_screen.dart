import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/web_chrome.dart';

// ═══════════════════════════════════════════════════════════
// Web Community — desktop layout for /community
//
// The feed is empty on purpose and stays empty here. There is no `posts`
// table in the schema, so nothing can fill it; the mobile screen used to open
// with a feed written into its source — named residents, a plumber given as a
// telephone number, a pothole at a real street address — and that was removed.
// This page therefore re-presents a group heading, the category filter and the
// "not open yet" notice at a desktop width. It does not add a composer, and it
// does not carry the "48 posts today" / "12,340 members" counters the mobile
// header still prints, because there is nothing behind those either.
//
// A feed does not want to be 1600px wide, so the column is held at 720 and
// centred, which is the width the posts will want when there are posts.
// ═══════════════════════════════════════════════════════════

const _kBorder = Color(0xFFE7E7E7);
const _kGreyText = Color(0xFF5F5E5A);

/// The filter the mobile screen offers, in the same order. The Hebrew labels
/// are the ones a post's `category` will be matched against, so they are what
/// travels; the English is for display only.
const _kCategories = <(String, String)>[
  ('All', 'הכל'),
  ('General', 'כללי'),
  ('Question', 'שאלה'),
  ('Recommendation', 'המלצה'),
  ('Report', 'דיווח'),
  ('Neighbours', 'שכנים'),
];

class WebCommunityContent extends StatefulWidget {
  const WebCommunityContent({super.key});

  @override
  State<WebCommunityContent> createState() => _WebCommunityContentState();
}

class _WebCommunityContentState extends State<WebCommunityContent> {
  bool _isHebrew = false;

  /// Held as the Hebrew label, which is what a `category` column would carry.
  String _selectedCategory = 'הכל';

  String _t(String en, String he) => _isHebrew ? he : en;

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
                  children: [
                    _buildCover(),
                    const SizedBox(height: 40),
                    _buildFeedColumn(),
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
  // COVER — the group photo, full bleed
  // ─────────────────────────────────────────────
  Widget _buildCover() {
    return SizedBox(
      height: 320,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/community_cover.jpg', fit: BoxFit.cover),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.72),
                ],
                stops: const [0.25, 1.0],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 36,
            // WebSection centres what it is given, so this block would sit in
            // the middle of the photo rather than against the gutter.
            child: WebSection(
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t(
                        'Modiin-Maccabim-Reut Community',
                        'קהילת מודיעין-מכבים-רעות',
                      ),
                      style: TextStyle(
                        fontFamily: AppFonts.nunito,
                        fontSize: 44,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.public,
                          size: 16,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _t('Public group', 'קבוצה ציבורית'),
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 15,
                            color: Colors.white70,
                          ),
                        ),
                      ],
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
  // THE FEED — 720px, centred
  // ─────────────────────────────────────────────
  Widget _buildFeedColumn() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 768), // 720 + 24 each side
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // All six fit across 720, so they wrap rather than scroll
              // sideways the way they have to on a phone.
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final (en, he) in _kCategories)
                    _CategoryChip(
                      label: _t(en, he),
                      selected: he == _selectedCategory,
                      onTap: () => setState(() => _selectedCategory = he),
                    ),
                ],
              ),
              const SizedBox(height: 32),
              _buildEmptyState(),
            ],
          ),
        ),
      ),
    );
  }

  /// What the feed shows while there is nothing to show. Said plainly: a blank
  /// column reads as a page that failed to load, and this one has not
  /// failed — it has nothing yet.
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 72),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.forum_outlined,
            size: 56,
            color: AppColors.grayLight.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 20),
          Text(
            _t('The community has not opened yet', 'הקהילה עוד לא נפתחה'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.nunito,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _t(
              'Soon you will be able to share questions, recommendations and neighbourhood reports here.',
              'בקרוב תוכלו לשתף כאן שאלות, המלצות ודיווחים שכונתיים.',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 15,
              height: 1.5,
              color: _kGreyText,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        // No fixed height and no alignment: a Container that aligns its child
        // takes all the width the Wrap offers it, and all six chips came out
        // 720 wide, one under the other.
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.turquoise : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(50),
            border: selected ? null : Border.all(color: _kBorder),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? Colors.white : AppColors.grayMeta,
            ),
          ),
        ),
      ),
    );
  }
}
