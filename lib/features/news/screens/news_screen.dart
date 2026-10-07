import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/providers/nav_categories_provider.dart';
import '../../../shared/widgets/network_photo.dart';

import '../../../shared/widgets/error_retry.dart';
import '../../../shared/widgets/skeleton.dart';
import '../models/article.dart';
import '../providers/news_providers.dart';
import '../widgets/m_article_parts.dart';
import 'web_news_screen.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/router/app_router.dart' show AppNavigation;

/// News feed – responsive wrapper.
/// Desktop (> 1100px) renders the Modiin News web layout; narrower windows
/// get the phone layout from the mobile Figma frame.
class NewsScreen extends StatelessWidget {
  /// Set when the navbar's news menu named a category.
  final String? categoryId;

  const NewsScreen({super.key, this.categoryId});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) {
          return WebNewsContent(categoryId: categoryId);
        }
        return _MobileNewsContent(categoryId: categoryId);
      },
    );
  }
}

/// Figma "News" (556:8719): the featured story, then a row of stories per
/// category, each with "See All". Everything comes from the `articles` table
/// and the categories they are filed under; nothing is hard-coded. With a
/// [categoryId] (a "See All"), the page lists that category's stories.
class _MobileNewsContent extends ConsumerWidget {
  final String? categoryId;

  const _MobileNewsContent({this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catId = categoryId;
    final articles = catId == null
        ? ref.watch(publishedArticlesProvider)
        : ref.watch(articlesByCategoryProvider(catId));
    final title = catId == null
        ? L.of(context).news
        : (ref.watch(categoryNameProvider(catId)).valueOrNull?.name ?? L.of(context).news);

    Future<void> refresh() async {
      if (catId == null) {
        ref.invalidate(publishedArticlesProvider);
        await ref.read(publishedArticlesProvider.future);
      } else {
        ref.invalidate(articlesByCategoryProvider(catId));
        await ref.read(articlesByCategoryProvider(catId).future);
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              children: [
                SizedBox(
                  height: 48,
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      if (catId != null && context.canPop())
                        PositionedDirectional(
                          start: 4,
                          top: 0,
                          bottom: 0,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, size: 22, color: Colors.black),
                            onPressed: () => context.back('/news'),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: articles.when(
                    loading: () => const _NewsSkeleton(),
                    error: (error, _) => ErrorRetry(onRetry: refresh),
                    data: (list) => list.isEmpty
                        ? EmptyState(
                            icon: IconsaxPlusLinear.document_text,
                            title: L.of(context).noStoriesYet,
                            subtitle: L.of(context).newStoriesAppearHere,
                          )
                        : RefreshIndicator(
                            onRefresh: refresh,
                            child: catId == null
                                ? _NewsFront(articles: list)
                                : _CategoryList(articles: list),
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
}

/// The front page: the hero story over a rule, then a section per category.
class _NewsFront extends ConsumerWidget {
  final List<Article> articles;

  const _NewsFront({required this.articles});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hero = pickHeroArticle(articles);
    final categories =
        ref.watch(navCategoriesProvider('article')).valueOrNull ?? const <NavCategory>[];

    // The six newest stories of each category, the hero left out.
    final sections = <({NavCategory category, List<Article> articles})>[];
    for (final c in categories) {
      final list = ref.watch(articlesByCategoryProvider(c.id)).valueOrNull;
      if (list == null) continue;
      final newest = ([...list]..sort((a, b) => b.publishedAt.compareTo(a.publishedAt)))
          .where((a) => a.id != hero.id)
          .take(6)
          .toList();
      if (newest.isNotEmpty) sections.add((category: c, articles: newest));
    }
    // Until the categories arrive, or where no story is filed, the newest
    // stories stand in as one section.
    final rest = articles.where((a) => a.id != hero.id).take(6).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _FeaturedArticle(article: hero),
        ),
        const SizedBox(height: 24),
        if (sections.isNotEmpty)
          for (var i = 0; i < sections.length; i++) ...[
            if (i > 0) const SizedBox(height: 40),
            _Section(
              title: sections[i].category.name,
              articles: sections[i].articles,
              onSeeAll: () => context.push('/news/category/${sections[i].category.id}'),
            ),
          ]
        else if (rest.isNotEmpty)
          _Section(title: L.of(context).latestStories, articles: rest),
      ],
    );
  }
}

/// A category's heading, "See All", and its stories in a sideways row.
class _Section extends StatelessWidget {
  final String title;
  final List<Article> articles;
  final VoidCallback? onSeeAll;

  const _Section({required this.title, required this.articles, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 19 / 16,
                    color: const Color(0xFF1F1F1F),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onSeeAll != null)
                GestureDetector(
                  onTap: onSeeAll,
                  child: Text(
                    L.of(context).newsSeeAll,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 15 / 12,
                      color: AppColors.midBlue,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: MNewsCard.heightFor(context),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: articles.length,
            separatorBuilder: (_, _) => const SizedBox(width: 20),
            itemBuilder: (_, i) => MNewsCard(
              article: articles[i],
              onTap: () => context.push('/article/${articles[i].id}'),
            ),
          ),
        ),
      ],
    );
  }
}

/// A category's stories, newest first, a full-width card each.
class _CategoryList extends StatelessWidget {
  final List<Article> articles;

  const _CategoryList({required this.articles});

  @override
  Widget build(BuildContext context) {
    final sorted = [...articles]..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return LayoutBuilder(
      builder: (context, c) => ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: sorted.length,
        separatorBuilder: (_, _) => const SizedBox(height: 24),
        itemBuilder: (_, i) => MNewsCard(
          article: sorted[i],
          width: c.maxWidth - 32,
          imageHeight: 200,
          onTap: () => context.push('/article/${sorted[i].id}'),
        ),
      ),
    );
  }
}

/// The hero story: the photo 200 tall at radius 12 with "Now in Modiin" on a
/// featured story, the headline in Avenir Demi 20 over two lines, the date,
/// and a rule 20 under.
class _FeaturedArticle extends StatelessWidget {
  final Article article;

  const _FeaturedArticle({required this.article});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/article/${article.id}'),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.only(bottom: 20),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: kMNewsBorder)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 200,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  NetworkPhoto(
                    url: article.imageUrl,
                    height: 200,
                    radius: BorderRadius.circular(12),
                    icon: IconsaxPlusBold.note,
                    iconSize: 40,
                  ),
                  // The design's badge, for a story the newsroom featured.
                  if (article.isFeatured)
                    PositionedDirectional(
                      start: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC9F31D),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset('assets/web/news/now_in_modiin.svg', width: 16, height: 16),
                            const SizedBox(width: 4),
                            Text(
                              L.of(context).nowInModiin,
                              style: TextStyle(
                                fontFamily: AppFonts.inter,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                height: 15 / 12,
                                color: AppColors.navy,
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
            SizedBox(
              width: double.infinity,
              child: Text(
                article.title,
                textDirection: mArticleDirection(article.title),
                style: TextStyle(
                  fontFamily: AppFonts.nunito,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: Colors.black,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 10),
            MNewsDateLine(
              date: article.publishedAt,
              iconSize: 16,
              fontSize: 14,
              gap: 8,
              color: kMNewsGrey500,
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder for the news feed: the hero, then the rows, each matching the
/// widget it stands in for.
class _NewsSkeleton extends StatelessWidget {
  const _NewsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.only(bottom: 20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE7E7E7))),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 200, radius: 12),
                SizedBox(height: 14),
                SkeletonLine(width: 300, fontSize: 20),
                SizedBox(height: 8),
                SkeletonLine(width: 210, fontSize: 20),
                SizedBox(height: 10),
                SkeletonLine(width: 170, fontSize: 14),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: List.generate(
                4,
                (_) => const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 112, height: 88, radius: 10),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonLine(width: 220, fontSize: 15),
                            SizedBox(height: 7),
                            SkeletonLine(width: 160, fontSize: 15),
                            SizedBox(height: 10),
                            SkeletonLine(width: 130, fontSize: 12),
                          ],
                        ),
                      ),
                    ],
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
