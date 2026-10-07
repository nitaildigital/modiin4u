import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/error_retry.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../../shared/widgets/skeleton.dart';
import '../models/article.dart';
import '../providers/news_providers.dart';
import '../widgets/m_article_parts.dart';
import 'web_article_screen.dart';
import '../../businesses/repositories/business_stats.dart';
import '../../../core/router/app_router.dart' show AppNavigation;

/// News article detail – responsive wrapper.
/// Desktop (> 1100px) renders the Modiin News Detail web layout;
/// narrower windows get the phone layout from the mobile Figma frame.
class ArticleScreen extends StatefulWidget {
  final String articleId;

  const ArticleScreen({super.key, required this.articleId});

  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  String get articleId => widget.articleId;

  // Views were never counted, so "most viewed" ranked WordPress's numbers
  // (00066). Once per page opened, on either layout.
  @override
  void initState() {
    super.initState();
    BusinessStats.recordArticleView(articleId);
  }

  @override
  void didUpdateWidget(ArticleScreen old) {
    super.didUpdateWidget(old);
    if (old.articleId != articleId) BusinessStats.recordArticleView(articleId);
  }

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
      bottomNavigationBar: article.maybeWhen(
        data: (a) => MArticleBottomBar(article: a, onShare: () => _share(a)),
        orElse: () => null,
      ),
      body: article.when(
        loading: () => const _ArticleSkeleton(),
        error: (error, _) => SafeArea(
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _CircleButton(onTap: () => context.back('/news')),
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

  void _share(Article a) {
    final link = mShareLink(a);
    Share.share(
      [a.title, if (link != null) link else if ((a.excerpt ?? '').isNotEmpty) a.excerpt!].join('\n\n'),
      subject: a.title,
    );
  }
}

// ═══════════════════════════════════════════════
// Figma "News Detail" (556:10027): the 260 photo with the back button, the
// category and views, the headline and date over a rule, the body, then
// "More Related News". The design's "12 Comments" thread and the bar's
// Comments cell are not drawn: articles have no comments in the app. Save is
// (MArticleBottomBar), to Favourites → News.
// ═══════════════════════════════════════════════
class _ArticleView extends ConsumerWidget {
  final Article article;

  const _ArticleView({required this.article});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final related =
        ref.watch(relatedArticlesProvider(article.id)).valueOrNull ?? const <Article>[];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Hero(article: article),
          const SizedBox(height: 16),
          _Header(article: article),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: MArticleBody(article: article),
          ),
          if (related.isNotEmpty) ...[
            const SizedBox(height: 41),
            MRelatedNews(
              articles: related,
              onSeeAll: () => context.go('/news'),
              onOpen: (a) => context.pushReplacement('/article/${a.id}'),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Photo, 260 tall, with the white back button 12 in
// ═══════════════════════════════════════════════
class _Hero extends StatelessWidget {
  final Article article;

  const _Hero({required this.article});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          NetworkPhoto(
            url: article.imageUrl,
            fit: BoxFit.cover,
            icon: IconsaxPlusBold.note,
            iconSize: 56,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 7, 12, 12),
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: _CircleButton(onTap: () => context.back('/news')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CircleButton({required this.onTap});

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
        // Material's back arrow turns to face the reading direction.
        child: const Center(child: Icon(Icons.arrow_back, size: 20, color: Colors.black)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Category and views, headline, date — 16 apart, a rule 20 under
// ═══════════════════════════════════════════════
class _Header extends ConsumerWidget {
  final Article article;

  const _Header({required this.article});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category =
        (ref.watch(articleFilingProvider).valueOrNull ?? const {})[article.id];
    final hasTopRow = category != null || article.viewCount > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.only(bottom: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kMNewsBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasTopRow) ...[
            Row(
              children: [
                if (category != null)
                  MNewsCategoryChip(
                    label: category.name,
                    onTap: () => context.go('/news/category/${category.id}'),
                  ),
                const Spacer(),
                // Only a counted row shows its views, as on the website.
                if (article.viewCount > 0) ...[
                  SvgPicture.asset('assets/web/news/stat_views.svg', width: 20, height: 20),
                  const SizedBox(width: 6),
                  Text(
                    '${article.viewCount}',
                    style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, height: 17 / 14, color: Colors.black),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
          ],
          Text(
            article.title,
            textDirection: mArticleDirection(article.title),
            style: TextStyle(
              fontFamily: AppFonts.nunito,
              fontSize: 24,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: Colors.black,
            ),
          ),
          if (article.subtitle != null && article.subtitle!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              article.subtitle!,
              textDirection: mArticleDirection(article.subtitle!),
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 16,
                height: 1.5,
                color: kMNewsGrey500,
              ),
            ),
          ],
          const SizedBox(height: 16),
          MNewsDateLine(date: article.publishedAt),
        ],
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
