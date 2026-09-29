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

class WebCommunityContent extends StatefulWidget {
  const WebCommunityContent({super.key});

  @override
  State<WebCommunityContent> createState() => _WebCommunityContentState();
}

class _WebCommunityContentState extends State<WebCommunityContent>
    with WebLanguageState<WebCommunityContent> {
  bool get _isHebrew => webIsHebrew.value;

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
              // The mobile screen's six filter chips sat here and filtered
              // nothing: there are no posts to filter yet. They come back
              // with the feed.
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

