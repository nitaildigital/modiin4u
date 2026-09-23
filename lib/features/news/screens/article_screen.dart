import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../../../shared/widgets/error_retry.dart';
import '../../../shared/widgets/skeleton.dart';
import '../models/article.dart';
import '../providers/news_providers.dart';
import 'web_article_screen.dart';

/// News article detail – responsive wrapper.
/// Desktop (> 1100px) renders the Modiin News Detail web layout;
/// mobile keeps the app UI.
class ArticleScreen extends StatelessWidget {
  final String articleId;

  const ArticleScreen({super.key, required this.articleId});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) {
          return WebArticleContent(articleId: articleId);
        }
        return _MobileArticleContent(articleId: articleId);
      },
    );
  }
}

class _MobileArticleContent extends ConsumerWidget {
  final String articleId;

  const _MobileArticleContent({required this.articleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final article = ref.watch(articleByIdProvider(articleId));

    return Scaffold(
      backgroundColor: Colors.white,
      body: article.when(
        loading: () => const _ArticleSkeleton(),
        error: (error, _) => SafeArea(
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: _CircleButton(
                  icon: IconsaxPlusLinear.arrow_right_3,
                  onTap: () => context.pop(),
                ),
              ),
              Expanded(
                child: ErrorRetry(
                  onRetry: () =>
                      ref.invalidate(articleByIdProvider(articleId)),
                ),
              ),
            ],
          ),
        ),
        data: (a) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: _ArticleView(article: a),
          ),
        ),
      ),
    );
  }
}

class _ArticleView extends StatelessWidget {
  final Article article;

  const _ArticleView({required this.article});

  List<String> get _paragraphs => article.body
      .split('\n')
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .toList();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Hero(article: article),
          _Header(article: article),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final paragraph in _paragraphs) ...[
                  Text(
                    paragraph,
                    style: TextStyle(fontFamily: AppFonts.rubik, 
                      fontSize: 16,
                      height: 1.7,
                      color: const Color(0xFF2B2B2B),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
          const _RelatedNews(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Hero image with back and share buttons
// ═══════════════════════════════════════════════
class _Hero extends StatelessWidget {
  final Article article;

  const _Hero({required this.article});

  @override
  Widget build(BuildContext context) {
    final url = article.imageUrl;

    final placeholder = Container(
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
    );

    return SizedBox(
      height: 260,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (url == null || url.isEmpty)
            placeholder
          else
            CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (_, _) => placeholder,
              errorWidget: (_, _, _) => placeholder,
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CircleButton(
                    icon: IconsaxPlusLinear.arrow_right_3,
                    onTap: () => context.pop(),
                  ),
                  _CircleButton(
                    icon: IconsaxPlusLinear.share,
                    onTap: () => Share.share(
                      '${article.title}\n\n${article.excerpt ?? ''}'.trim(),
                      subject: article.title,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
        child: Center(child: Icon(icon, size: 20, color: Colors.black)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Title block
// ═══════════════════════════════════════════════
class _Header extends StatelessWidget {
  final Article article;

  const _Header({required this.article});

  static const _hebrewMonths = [
    'ינואר', 'פברואר', 'מרץ', 'אפריל', 'מאי', 'יוני',
    'יולי', 'אוגוסט', 'ספטמבר', 'אוקטובר', 'נובמבר', 'דצמבר',
  ];

  String get _date {
    final d = article.publishedAt;
    final time = '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
    return '${d.day} ב${_hebrewMonths[d.month - 1]} ${d.year} | $time';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.only(top: 16, bottom: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE7E7E7))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (article.isBreaking)
                Container(
                  height: 33,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE74C3C),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'דחוף',
                      style: TextStyle(fontFamily: AppFonts.rubik, 
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(IconsaxPlusLinear.eye,
                      size: 20, color: Colors.black),
                  const SizedBox(width: 6),
                  Text(
                    '${article.viewCount}',
                    style: TextStyle(fontFamily: AppFonts.rubik, 
                        fontSize: 14, color: Colors.black),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            article.title,
            style: TextStyle(fontFamily: AppFonts.rubik, 
              fontSize: 24,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: Colors.black,
            ),
          ),
          if (article.subtitle != null && article.subtitle!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              article.subtitle!,
              style: TextStyle(fontFamily: AppFonts.rubik, 
                fontSize: 16,
                height: 1.5,
                color: const Color(0xFF6D6D6D),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(IconsaxPlusLinear.calendar_1,
                  size: 16, color: Color(0xFF888888)),
              const SizedBox(width: 8),
              Text(
                _date,
                style: TextStyle(fontFamily: AppFonts.rubik, 
                    fontSize: 14, color: const Color(0xFF6D6D6D)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// More news — the other published articles
// ═══════════════════════════════════════════════
class _RelatedNews extends ConsumerWidget {
  const _RelatedNews();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articles = ref.watch(publishedArticlesProvider);

    return articles.maybeWhen(
      data: (list) {
        final others = list.take(6).toList();
        if (others.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'עוד חדשות',
                style: TextStyle(fontFamily: AppFonts.rubik, 
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 170,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: others.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _RelatedCard(article: others[i]),
              ),
            ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _RelatedCard extends StatelessWidget {
  final Article article;

  const _RelatedCard({required this.article});

  @override
  Widget build(BuildContext context) {
    final url = article.imageUrl;

    final placeholder = Container(
      height: 100,
      width: 200,
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
          size: 24,
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
    );

    return GestureDetector(
      onTap: () => context.pushReplacement('/article/${article.id}'),
      child: SizedBox(
        width: 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: url == null || url.isEmpty
                  ? placeholder
                  : CachedNetworkImage(
                      imageUrl: url,
                      height: 100,
                      width: 200,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => placeholder,
                      errorWidget: (_, _, _) => placeholder,
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              article.title,
              style: TextStyle(fontFamily: AppFonts.rubik, 
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.35,
                color: Colors.black,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder for the article page: the 260px hero, then the header block
/// and the first paragraphs, laid out where the real ones go.
class _ArticleSkeleton extends StatelessWidget {
  const _ArticleSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          const SkeletonBox(height: 260, radius: 0),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonLine(width: 70, fontSize: 14),
                SizedBox(height: 16),
                SkeletonLine(width: 320, fontSize: 24),
                SizedBox(height: 10),
                SkeletonLine(width: 240, fontSize: 24),
                SizedBox(height: 16),
                SkeletonLine(width: 180, fontSize: 14),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: List.generate(
                5,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SkeletonLine(
                    width: i.isEven ? 340 : 280,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
