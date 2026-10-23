import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/error_retry.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../../shared/widgets/skeleton.dart';
import '../models/article.dart';
import '../providers/news_providers.dart';
import '../widgets/m_article_comments.dart';
import '../widgets/m_article_parts.dart';
import 'web_article_screen.dart';
import '../../businesses/repositories/business_stats.dart';
import '../../../core/router/app_router.dart' show AppNavigation;
import '../../../shared/share_text.dart';
import '../../../shared/widgets/report_sheet.dart';

/// News article detail – responsive wrapper.
/// Desktop (> 1100px) renders the Modiin News Detail web layout;
/// narrower windows get the phone layout from the mobile Figma frame.
class ArticleScreen extends StatefulWidget {
  final String articleId;

  /// The comment a reply notification points at. Null reads it from the
  /// address (`/article/<id>?comment=<id>`), which is what the notification
  /// opens.
  final String? focusCommentId;

  const ArticleScreen({
    super.key,
    required this.articleId,
    this.focusCommentId,
  });

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

  /// `?comment=` on the address. The route builds this page from the path
  /// alone, so the query is read here rather than handed in.
  String? _commentFromAddress(BuildContext context) {
    try {
      final id = GoRouterState.of(context).uri.queryParameters['comment'];
      return id == null || id.isEmpty ? null : id;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final focus = widget.focusCommentId ?? _commentFromAddress(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) {
          return WebArticleContent(articleId: articleId);
        }
        return _MobileArticleContent(
          articleId: articleId,
          focusCommentId: focus,
        );
      },
    );
  }
}

class _MobileArticleContent extends ConsumerWidget {
  final String articleId;
  final String? focusCommentId;

  const _MobileArticleContent({required this.articleId, this.focusCommentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final article = ref.watch(articleByIdProvider(articleId));

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: article.maybeWhen(
        data: (a) =>
            MArticleBottomBar(article: a, onShare: () => _share(context, a)),
        orElse: () => null,
      ),
      // The back and report buttons sit in a bar of their own at the top, as
      // the website's header does: the article starts with its card, not a
      // photo under the status bar (the client, 23 Oct: the app's article
      // should look like the website's).
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CircleButton(onTap: () => context.back('/news')),
                  if (article.valueOrNull case final a?)
                    _CircleButton(
                      icon: IconsaxPlusLinear.flag,
                      onTap: () => showReportSheet(
                        context,
                        entityType: 'article',
                        entityId: a.id,
                        onHidden: () {
                          if (context.mounted && context.canPop()) {
                            context.pop();
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: article.when(
                loading: () => const _ArticleSkeleton(),
                error: (error, _) => ErrorRetry(
                  onRetry: () => ref.invalidate(articleByIdProvider(articleId)),
                ),
                data: (a) => Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: _ArticleView(
                      article: a,
                      focusCommentId: focusCommentId,
                      onShare: () => _share(context, a),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _share(BuildContext context, Article a) {
    final link = mShareLink(a);
    shareText(
      context,
      [
        a.title,
        if (link != null)
          link
        else if ((a.excerpt ?? '').isNotEmpty)
          a.excerpt!,
      ].join('\n\n'),
      subject: a.title,
    );
  }
}

// ═══════════════════════════════════════════════
// Figma "News Detail" (556:10027): the 260 photo with the back button, the
// category and views, the headline and date over a rule, the body, the
// comments (00071), then "More Related News". The bar's Comments cell is not
// drawn. Save is (MArticleBottomBar), to Favourites → News.
// ═══════════════════════════════════════════════
class _ArticleView extends ConsumerWidget {
  final Article article;
  final String? focusCommentId;
  final VoidCallback onShare;

  const _ArticleView({
    required this.article,
    this.focusCommentId,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final related =
        ref.watch(relatedArticlesProvider(article.id)).valueOrNull ??
        const <Article>[];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          _HeaderCard(article: article),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ShareBox(article: article, onShare: onShare),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: MArticleBody(article: article),
          ),
          MArticleComments(
            key: ValueKey(article.id),
            articleId: article.id,
            focusCommentId: focusCommentId,
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
// The website's headline card (site/src/app/(site)/news/[slug]/page.tsx):
// the photo at 16:10 with the grey block under it — category, headline,
// date — rounded 16 together, 16 in from the sides.
// ═══════════════════════════════════════════════
class _HeaderCard extends ConsumerWidget {
  final Article article;

  const _HeaderCard({required this.article});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category =
        (ref.watch(articleFilingProvider).valueOrNull ?? const {})[article.id];
    final hasPhoto = (article.imageUrl ?? '').trim().isNotEmpty;
    final he = mIsHebrew(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasPhoto)
              AspectRatio(
                aspectRatio: 16 / 10,
                child: NetworkPhoto(
                  url: article.imageUrl,
                  fit: BoxFit.cover,
                  icon: IconsaxPlusBold.note,
                  iconSize: 56,
                ),
              ),
            Container(
              color: _kSection,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (category != null) ...[
                    MNewsCategoryChip(
                      label: category.name,
                      onTap: () => context.go('/news/category/${category.id}'),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Text(
                    article.title,
                    textDirection: mArticleDirection(article.title),
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      height: 1.375,
                      color: _kInk,
                    ),
                  ),
                  if (article.subtitle != null &&
                      article.subtitle!.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
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
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      SvgPicture.asset(
                        'assets/web/news/meta_date.svg',
                        width: 18,
                        height: 18,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          // "22 באוקטובר 2026 בשעה 16:53", as the website
                          // prints it.
                          mArticleDate(article.publishedAt, he)
                              .replaceFirst(' | ', he ? ' בשעה ' : ' at '),
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 16,
                            height: 1.2,
                            color: _kGrayMeta,
                          ),
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
    );
  }
}

// ═══════════════════════════════════════════════
// The website's share box (site/src/components/ui/ShareBar.tsx): the views
// and Share on one line, the four ways to pass the story on under them.
// ═══════════════════════════════════════════════
class _ShareBox extends StatelessWidget {
  final Article article;
  final VoidCallback onShare;

  const _ShareBox({required this.article, required this.onShare});

  @override
  Widget build(BuildContext context) {
    final he = mIsHebrew(context);
    // The story's page on the site, as the website shares it.
    final link =
        mShareLink(article) ??
        'https://www.modiin4u.co.il/news/${article.slug}/';
    final u = Uri.encodeComponent(link);
    final ti = Uri.encodeComponent(article.title);
    final links = [
      ('assets/web/news/share_facebook.svg', 'https://www.facebook.com/sharer/sharer.php?u=$u'),
      ('assets/web/news/share_whatsapp.svg', 'https://wa.me/?text=$ti%20$u'),
      ('assets/web/news/share_x.svg', 'https://twitter.com/intent/tweet?url=$u&text=$ti'),
      ('assets/web/news/share_mail.svg', 'mailto:?subject=$ti&body=$u'),
    ];
    final label = TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: _kInk);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: _kCardBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // A count only where the row has one, never "0", as on the site.
              if (article.viewCount > 0) ...[
                SvgPicture.asset('assets/web/news/stat_views.svg', width: 24, height: 24),
                const SizedBox(width: 8),
                Text('${article.viewCount}', style: label.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(width: 6),
                Text(he ? 'צפיות' : 'Views', style: label.copyWith(color: _kGrayMeta)),
                const SizedBox(width: 24),
              ],
              GestureDetector(
                onTap: onShare,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset('assets/web/news/stat_share.svg', width: 24, height: 24),
                    const SizedBox(width: 8),
                    Text(he ? 'שיתוף' : 'Share', style: label.copyWith(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsetsDirectional.only(start: 24),
            decoration: const BoxDecoration(
              border: BorderDirectional(start: BorderSide(color: kMNewsBorder)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < links.length; i++) ...[
                  if (i > 0) const SizedBox(width: 20),
                  GestureDetector(
                    onTap: () => launchUrl(
                      Uri.parse(links[i].$2),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: SvgPicture.asset(links[i].$1, width: 28, height: 28),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// The website's colours for this page (site/src/app/globals.css).
const _kSection = Color(0xFFF5F5F5);
const _kInk = Color(0xFF0F161E);
const _kGrayMeta = Color(0xFF6B7280);
const _kCardBorder = Color(0xFFEAEAEA);

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.onTap, this.icon = Icons.arrow_back});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          // On the white bar now, not over a photo: a rim, as the website's
          // round header buttons have.
          border: Border.all(color: kMNewsBorder),
        ),
        child: Center(
          child: Icon(icon, size: 20, color: Colors.black),
        ),
      ),
    );
  }
}

/// Placeholder for the article page: the card's photo, then the header block
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
          // The card's photo: 16:10 on a phone's width, 16 in, rounded.
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SkeletonBox(height: 224, radius: 16),
          ),
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
