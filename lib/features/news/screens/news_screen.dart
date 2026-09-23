import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../shared/widgets/error_retry.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../models/article.dart';
import '../providers/news_providers.dart';
import 'web_news_screen.dart';

/// News feed – responsive wrapper.
/// Desktop (> 1100px) renders the Modiin News web layout; mobile keeps the app UI.
class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) {
          return const WebNewsContent();
        }
        return const _MobileNewsContent();
      },
    );
  }
}

/// Mobile news feed — featured hero article followed by the rest of the
/// published articles. Everything on this screen comes from the `articles`
/// table; nothing is hard-coded.
class _MobileNewsContent extends ConsumerWidget {
  const _MobileNewsContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articles = ref.watch(publishedArticlesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    'חדשות',
                    style: GoogleFonts.rubik(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
                Expanded(
                  child: articles.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: ShimmerLoading(itemCount: 3),
                    ),
                    error: (error, _) => ErrorRetry(
                      onRetry: () => ref.invalidate(publishedArticlesProvider),
                    ),
                    data: (list) => list.isEmpty
                        ? const EmptyState(
                            icon: IconsaxPlusLinear.document_text,
                            title: 'אין כתבות להצגה',
                            subtitle: 'כתבות חדשות יופיעו כאן',
                          )
                        : _NewsList(
                            articles: list,
                            onRefresh: () async {
                              ref.invalidate(publishedArticlesProvider);
                              await ref.read(publishedArticlesProvider.future);
                            },
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

class _NewsList extends StatelessWidget {
  final List<Article> articles;
  final Future<void> Function() onRefresh;

  const _NewsList({required this.articles, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final featured =
        articles.firstWhere((a) => a.isFeatured, orElse: () => articles.first);
    final rest = articles.where((a) => a.id != featured.id).toList();

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _FeaturedArticle(article: featured),
          const SizedBox(height: 24),
          if (rest.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'עדכונים אחרונים',
                style: GoogleFonts.rubik(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...rest.map((a) => _ArticleRow(article: a)),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Featured hero article
// ═══════════════════════════════════════════════
class _FeaturedArticle extends StatelessWidget {
  final Article article;

  const _FeaturedArticle({required this.article});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/article/${article.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.only(bottom: 20),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE7E7E7))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  _ArticleImage(
                    url: article.imageUrl,
                    height: 200,
                    width: double.infinity,
                    iconSize: 48,
                  ),
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
                            'עכשיו במודיעין',
                            style: GoogleFonts.rubik(
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
            Text(
              article.title,
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
            _DateRow(date: article.publishedAt),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// One row in the "latest" list
// ═══════════════════════════════════════════════
class _ArticleRow extends StatelessWidget {
  final Article article;

  const _ArticleRow({required this.article});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/article/${article.id}'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _ArticleImage(
                url: article.imageUrl,
                height: 88,
                width: 112,
                iconSize: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: GoogleFonts.rubik(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 20 / 15,
                      color: Colors.black,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  _DateRow(date: article.publishedAt, fontSize: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Shared pieces
// ═══════════════════════════════════════════════

/// The article photo, falling back to the brand gradient when an article
/// has no image — which is the case for most rows today.
class _ArticleImage extends StatelessWidget {
  final String? url;
  final double height;
  final double width;
  final double iconSize;

  const _ArticleImage({
    required this.url,
    required this.height,
    required this.width,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      height: height,
      width: width,
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
          size: iconSize,
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
    );

    if (url == null || url!.isEmpty) return placeholder;

    return CachedNetworkImage(
      imageUrl: url!,
      height: height,
      width: width,
      fit: BoxFit.cover,
      placeholder: (_, _) => placeholder,
      errorWidget: (_, _, _) => placeholder,
    );
  }
}

class _DateRow extends StatelessWidget {
  final DateTime date;
  final double fontSize;

  const _DateRow({required this.date, this.fontSize = 14});

  static const _hebrewMonths = [
    'ינואר', 'פברואר', 'מרץ', 'אפריל', 'מאי', 'יוני',
    'יולי', 'אוגוסט', 'ספטמבר', 'אוקטובר', 'נובמבר', 'דצמבר',
  ];

  String get _formatted {
    final time = '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
    return '${date.day} ב${_hebrewMonths[date.month - 1]} ${date.year} | $time';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          IconsaxPlusLinear.calendar_1,
          size: fontSize + 2,
          color: const Color(0xFF888888),
        ),
        const SizedBox(width: 8),
        Text(
          _formatted,
          style: GoogleFonts.rubik(
            fontSize: fontSize,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6D6D6D),
          ),
        ),
      ],
    );
  }
}
