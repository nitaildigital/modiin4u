import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

/// News feed screen – featured hero article + three horizontal-scroll
/// category sections: Municipality Updates, Urban, Business.
class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  // ── Featured article ──
  static const _featuredTitle =
      'From now on, we can breathe a sigh of relief: The new municipal '
      'initiative that will give women in Modi\'in complete confidence '
      'and tools for success';
  static const _featuredDate = 'August 5, 2026 | 4:36 p.m.';

  // ── Municipality Updates ──
  static const _municipalityArticles = [
    _Article(
      'From now on, we can breathe a sigh of relief: The new municipal '
      'initiative that will give women in Modi\'in complete confidence '
      'and tools for success',
      'August 5, 2026 | 4:36 p.m.',
    ),
    _Article(
      'An end to cycle worries: Modiin is moving to a new and efficient '
      'model that will put your mind at ease',
      'August 5, 2026 | 4:30 p.m.',
    ),
    _Article(
      'No more heart palpitations: The new tool that will help parents '
      'in Modi\'in register for after-school',
      'August 5, 2026 | 4:34 p.m.',
    ),
    _Article(
      'From now on, we can breathe a sigh of relief: The new municipal '
      'initiative that will give women i',
      'August 5, 2026 | 4:34 p.m.',
    ),
  ];

  // ── Urban ──
  static const _urbanArticles = [
    _Article(
      'Parashat Raeh: The Environment as the Basis for the Purpose of Life',
      'August 4, 2026 | 4:36 p.m.',
    ),
    _Article(
      '20 years later: The evening in Modi\'in that left an entire hall '
      'speechless',
      'August 3, 2026 | 1:30 p.m.',
    ),
    _Article(
      'Why must procurement people in large organizations know '
      'negotiation tactics?',
      'August 3, 2026 | 4:34 p.m.',
    ),
    _Article(
      'Yaakov Aviv reveals what makes the final stage the most critical '
      'phase of the project',
      'August 3, 2026 | 4:32 p.m.',
    ),
  ];

  // ── Business ──
  static const _businessArticles = [
    _Article(
      'The agent who succeeded in conquering Modi\'in: This is how a '
      'local empire was built',
      'August 4, 2026 | 4:36 p.m.',
    ),
    _Article(
      'Special vacation ideas for families looking for a real change '
      'from routine',
      'August 3, 2026 | 1:30 p.m.',
    ),
    _Article(
      'Recommended lawyer in Modiin – Yedidia Bleugrund who will fight '
      'for you',
      'August 3, 2026 | 4:34 p.m.',
    ),
    _Article(
      'Fingerprint Time Clocks and Attendance Apps: The Complete Guide '
      'to Smart Employee Control',
      'August 3, 2026 | 4:32 p.m.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              children: [
                // ═══════════════════════════════════
                // Page title
                // ═══════════════════════════════════
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    'News',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),

                // ═══════════════════════════════════
                // Scrollable content
                // ═══════════════════════════════════
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Featured hero article
                        _buildFeatured(context),
                        const SizedBox(height: 24),

                        // Municipality Updates
                        _buildSection(
                          context,
                          title: 'Municipality Updates',
                          articles: _municipalityArticles,
                          sectionKey: 'municipality',
                        ),
                        const SizedBox(height: 40),

                        // Urban
                        _buildSection(
                          context,
                          title: 'Urban',
                          articles: _urbanArticles,
                          sectionKey: 'urban',
                        ),
                        const SizedBox(height: 40),

                        // Business
                        _buildSection(
                          context,
                          title: 'Business',
                          articles: _businessArticles,
                          sectionKey: 'business',
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Featured hero article
  // ═══════════════════════════════════════════════
  Widget _buildFeatured(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/article/featured'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.only(bottom: 20),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFE7E7E7)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0058B5), Color(0xFF010A36)],
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      IconsaxPlusBold.note,
                      size: 48,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  // "Now in Modiin" badge
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      height: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC9F31D),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            IconsaxPlusBold.location,
                            size: 16,
                            color: Color(0xFF0A1230),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Now in Modiin',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF0A1230),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Title
            Text(
              _featuredTitle,
              style: GoogleFonts.rubik(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 25 / 20,
                color: Colors.black,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),

            // Date row
            Row(
              children: [
                const Icon(
                  IconsaxPlusLinear.calendar_1,
                  size: 16,
                  color: Color(0xFF888888),
                ),
                const SizedBox(width: 8),
                Text(
                  _featuredDate,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
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

  // ═══════════════════════════════════════════════
  // Horizontal-scroll category section
  // ═══════════════════════════════════════════════
  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<_Article> articles,
    required String sectionKey,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: title + "See All"
        Padding(
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
              GestureDetector(
                onTap: () {
                  // TODO: navigate to full section list
                },
                child: Text(
                  'See All',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF123A72),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Cards row
        SizedBox(
          height: 228,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16, right: 16),
            itemCount: articles.length,
            separatorBuilder: (_, _) => const SizedBox(width: 20),
            itemBuilder: (context, index) {
              return _ArticleCard(
                article: articles[index],
                onTap: () =>
                    context.push('/article/${sectionKey}_$index'),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// Article data
// ═══════════════════════════════════════════════
class _Article {
  final String title;
  final String date;

  const _Article(this.title, this.date);
}

// ═══════════════════════════════════════════════
// Horizontal-scroll article card (250 × 228)
// ═══════════════════════════════════════════════
class _ArticleCard extends StatelessWidget {
  final _Article article;
  final VoidCallback? onTap;

  const _ArticleCard({required this.article, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 250,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              height: 150,
              width: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0058B5), Color(0xFF010A36)],
                ),
              ),
              child: Center(
                child: Icon(
                  IconsaxPlusBold.note,
                  size: 32,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Title (max 2 lines)
            Text(
              article.title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 19 / 16,
                color: Colors.black,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),

            // Date row
            Row(
              children: [
                const Icon(
                  IconsaxPlusLinear.calendar_1,
                  size: 16,
                  color: Color(0xFF888888),
                ),
                const SizedBox(width: 8),
                Text(
                  article.date,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
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
