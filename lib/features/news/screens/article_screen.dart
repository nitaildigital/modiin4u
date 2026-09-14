import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

/// News article detail screen – hero image, header with category badge +
/// views, long-form body with inline images, "More Related News" horizontal
/// scroll, comments section, and a fixed bottom action bar.
class ArticleScreen extends StatelessWidget {
  final String articleId;

  const ArticleScreen({super.key, required this.articleId});

  // ── Body paragraphs ──
  static const _paragraphs = [
    'The women of Modi\'in are receiving a new and powerful envelope that '
        'will change everything they knew about personal resilience, security '
        'and independence. The Municipality of Modi\'in Maccabim Re\'ut is '
        'launching a comprehensive urban plan that will give you all the tools '
        'you need to move forward with peace of mind and complete confidence.',
    'The new program is being launched under the leadership of the '
        'Multidisciplinary Center, managed by Dr. Orna Mager, Advisor to the '
        'Mayor for Gender Equality, together with the Education, Learning and '
        'Entrepreneurship Division. The important project was built in close '
        'collaboration with the Authority for the Advancement of the Status of '
        'Women, the Ministry of Welfare and Social Security, the Municipal '
        'Health Department, and the Treatment Center for Family Peace and '
        'Sexual Trauma in the Social Services Division.',
    'The first course that has already been launched is a practical '
        'self-defense course, designed to directly strengthen the sense of '
        'competence and personal security of each and every one of us in '
        'the public space.',
    null, // inline image placeholder 1
    'Throughout the coming year, a wide variety of workshops, professional '
        'meetings, and events will await you that will touch precisely on the '
        'points that are important to us:',
    'A special package to strengthen the "Recruited Women" Program: '
        'resilience of women in reserve and permanent service.',
    null, // inline image placeholder 2
    'Want to receive all the first updates and secure your spot? All the '
        'details and the registration form are waiting for you right here:',
  ];

  // ── Related articles ──
  static const _relatedArticles = [
    _RelatedData(
      'From now on, we can breathe a sigh of relief: The new municipal '
      'initiative that will give women in Modi\'in complete confidence '
      'and tools for success',
      'August 5, 2026 | 4:36 p.m.',
    ),
    _RelatedData(
      'An end to cycle worries: Modiin is moving to a new and efficient '
      'model that will put your mind at ease',
      'August 5, 2026 | 4:30 p.m.',
    ),
    _RelatedData(
      'No more heart palpitations: The new tool that will help parents '
      'in Modi\'in register for after-school',
      'August 5, 2026 | 4:34 p.m.',
    ),
    _RelatedData(
      'From now on, we can breathe a sigh of relief: The new municipal '
      'initiative that will give women i',
      'August 5, 2026 | 4:34 p.m.',
    ),
  ];

  // ── Comments ──
  static const _comments = [
    _CommentData(
      'SC',
      'Zeev Schumacher',
      'August 5, 2026 · 5:12 PM',
      'This is such an important initiative for women in Modiin. It\'s '
          'great to see practical tools and support being made available '
          'locally.',
    ),
    _CommentData(
      'MZ',
      'Moran Zelig',
      'August 5, 2026 · 6:03 PM',
      'I really like the focus on confidence and personal safety. These '
          'workshops can make a real difference in everyday life.',
    ),
    _CommentData(
      'YL',
      'Yael Levi',
      'August 5, 2026 · 7:24 PM',
      'The financial independence workshop sounds especially useful. I '
          'hope more residents hear about these programs.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Stack(
            children: [
              // ═══════════════════════════════════
              // Scrollable content
              // ═══════════════════════════════════
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroImage(context),
                    _buildHeader(),
                    _buildBody(),
                    const SizedBox(height: 32),
                    _buildRelatedNews(context),
                    const SizedBox(height: 32),
                    _buildCommentsSection(),
                    const SizedBox(height: 90),
                  ],
                ),
              ),

              // ═══════════════════════════════════
              // Fixed bottom action bar
              // ═══════════════════════════════════
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomBar(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Hero image (260px) with back button
  // ═══════════════════════════════════════════════
  Widget _buildHeroImage(BuildContext context) {
    return SizedBox(
      height: 260,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image placeholder
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0058B5), Color(0xFF010A36)],
              ),
            ),
            child: Center(
              child: Icon(
                IconsaxPlusBold.note,
                size: 56,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),

          // Back button
          Positioned(
            left: 12,
            top: 51,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    IconsaxPlusLinear.arrow_left,
                    size: 20,
                    color: Color(0xFF3D3D3D),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Article header: category badge, views, title, date
  // ═══════════════════════════════════════════════
  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.only(top: 16, bottom: 20),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE7E7E7)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category badge + views row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // "Municipality" badge
              Container(
                height: 33,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF17A9D0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Municipality',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // Views
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    IconsaxPlusLinear.eye,
                    size: 20,
                    color: Colors.black,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '359',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            'From now on, we can breathe a sigh of relief: The new '
            'municipal initiative that will give women in Modi\'in '
            'complete confidence and tools for success.',
            style: GoogleFonts.rubik(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),

          // Date row
          Row(
            children: [
              const Icon(
                IconsaxPlusLinear.calendar_1,
                size: 18,
                color: Color(0xFF6D6D6D),
              ),
              const SizedBox(width: 9),
              Text(
                'August 5, 2026 | 4:34 p.m.',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF5F5E5A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Article body: paragraphs + inline images
  // ═══════════════════════════════════════════════
  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          for (final item in _paragraphs) ...[
            if (item != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  item,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 1.6,
                    color: const Color(0xFF3D3D3D),
                  ),
                ),
              )
            else
              // Inline image placeholder
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  height: 240,
                  width: double.infinity,
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
                      IconsaxPlusBold.gallery,
                      size: 40,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // "More Related News" horizontal scroll section
  // ═══════════════════════════════════════════════
  Widget _buildRelatedNews(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'More Related News',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F1F1F),
                ),
              ),
              GestureDetector(
                onTap: () {},
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
            itemCount: _relatedArticles.length,
            separatorBuilder: (_, _) => const SizedBox(width: 20),
            itemBuilder: (context, index) {
              final a = _relatedArticles[index];
              return _RelatedCard(
                article: a,
                onTap: () =>
                    context.push('/article/related_$index'),
              );
            },
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  // Comments section
  // ═══════════════════════════════════════════════
  Widget _buildCommentsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '12 Comments',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 16),
          for (final c in _comments) _CommentTile(comment: c),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Fixed bottom action bar
  // ═══════════════════════════════════════════════
  Widget _buildBottomBar() {
    return Container(
      height: 69,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE7E7E7)),
        ),
      ),
      child: Row(
        children: [
          // Comments
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: Color(0xFFE7E7E7)),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 20),
                  const Icon(
                    IconsaxPlusLinear.message,
                    size: 20,
                    color: Colors.black,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '12',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Share / Views
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: Color(0xFFE7E7E7)),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 20),
                  const Icon(
                    IconsaxPlusLinear.share,
                    size: 20,
                    color: Colors.black,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '359',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Save
          Expanded(
            child: Row(
              children: [
                const SizedBox(width: 20),
                const Icon(
                  IconsaxPlusLinear.bookmark,
                  size: 20,
                  color: Colors.black,
                ),
                const SizedBox(width: 12),
                Text(
                  'Save',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
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
// Related article data
// ═══════════════════════════════════════════════
class _RelatedData {
  final String title;
  final String date;

  const _RelatedData(this.title, this.date);
}

// ═══════════════════════════════════════════════
// Related article horizontal card (250 × 228)
// ═══════════════════════════════════════════════
class _RelatedCard extends StatelessWidget {
  final _RelatedData article;
  final VoidCallback? onTap;

  const _RelatedCard({required this.article, this.onTap});

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

            // Title
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

            // Date
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

// ═══════════════════════════════════════════════
// Comment data
// ═══════════════════════════════════════════════
class _CommentData {
  final String initials;
  final String name;
  final String date;
  final String text;

  const _CommentData(this.initials, this.name, this.date, this.text);
}

// ═══════════════════════════════════════════════
// Comment tile widget
// ═══════════════════════════════════════════════
class _CommentTile extends StatelessWidget {
  final _CommentData comment;

  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE7E7E7)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF17A9D0),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                comment.initials,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  comment.name,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),

                // Date
                Text(
                  comment.date,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6D6D6D),
                  ),
                ),
                const SizedBox(height: 7),

                // Comment text
                Text(
                  comment.text,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                    color: const Color(0xFF3D3D3D),
                  ),
                ),
                const SizedBox(height: 12),

                // Reply button
                Row(
                  children: [
                    const Icon(
                      IconsaxPlusLinear.undo,
                      size: 20,
                      color: Color(0xFF123A72),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Reply',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF123A72),
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
