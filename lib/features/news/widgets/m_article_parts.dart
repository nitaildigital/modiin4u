import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../favorites/providers/favorite_providers.dart';
import '../../favorites/repositories/favorite_repository.dart';
import '../../favorites/widgets/favorite_button.dart' show toggleFavorite;
import '../models/article.dart';
import '../models/article_body.dart';
import '../../../l10n/app_localizations.dart';

// ═══════════════════════════════════════════════════════════
// Pieces of the phone's news pages, from the mobile Figma frames "News" and
// "News Detail" (page 412:6567).
// ═══════════════════════════════════════════════════════════

const kMNewsBorder = Color(0xFFE7E7E7);
const kMNewsBodyText = Color(0xFF3D3D3D);
const kMNewsGrey = Color(0xFF5F5E5A);
const kMNewsGrey500 = Color(0xFF6D6D6D);

final _hebrew = RegExp(r'[֐-׿]');

/// Articles are written in Hebrew whichever language the app is set to, so
/// their own text is laid out by its script.
TextDirection mArticleDirection(String text) =>
    _hebrew.hasMatch(text) ? TextDirection.rtl : TextDirection.ltr;

bool mIsHebrew(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'he';

const _enMonths = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
const _heMonths = [
  'ינואר', 'פברואר', 'מרץ', 'אפריל', 'מאי', 'יוני',
  'יולי', 'אוגוסט', 'ספטמבר', 'אוקטובר', 'נובמבר', 'דצמבר',
];

/// "August 5, 2026 | 4:34 p.m.", as the design writes it, or "5 באוגוסט
/// 2026 | 16:34". `published_at` is UTC, so it is moved to the reader's zone.
String mArticleDate(DateTime value, bool isHebrew) {
  final d = value.toLocal();
  final mm = d.minute.toString().padLeft(2, '0');
  if (isHebrew) {
    return '${d.day} ב${_heMonths[d.month - 1]} ${d.year} | ${d.hour.toString().padLeft(2, '0')}:$mm';
  }
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '${_enMonths[d.month - 1]} ${d.day}, ${d.year} | $h:$mm ${d.hour < 12 ? 'a.m.' : 'p.m.'}';
}

/// Where a share points: the story on the client's site when the row names
/// it, as the website does.
String? mShareLink(Article article) {
  final canonical = article.canonicalUrl?.trim() ?? '';
  return canonical.isEmpty ? null : canonical;
}

/// The turquoise category chip — Inter Medium 14, 12 × 8 padding, radius 8.
class MNewsCategoryChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const MNewsCategoryChip({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.turquoise,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 17 / 14,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// The date line: the calendar-clock icon and the date in Inter.
class MNewsDateLine extends StatelessWidget {
  final DateTime date;
  final double iconSize;
  final double fontSize;
  final double gap;
  final Color color;
  const MNewsDateLine({
    super.key,
    required this.date,
    this.iconSize = 18,
    this.fontSize = 16,
    this.gap = 9,
    this.color = kMNewsGrey,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset('assets/web/news/meta_date.svg', width: iconSize, height: iconSize),
        SizedBox(width: gap),
        Flexible(
          child: Text(
            mArticleDate(date, mIsHebrew(context)),
            style: TextStyle(fontFamily: AppFonts.inter, fontSize: fontSize, height: 1.2, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// BODY — Inter 16 at 1.6 in grey-900, blocks 12 apart, photos full width
// ─────────────────────────────────────────────

/// An article's body, read into paragraphs, sub-headings, list items and
/// photos by the same parser the website uses. The stories imported from the
/// client's WordPress are HTML; printed as text they showed their tags.
class MArticleBody extends StatefulWidget {
  final Article article;
  const MArticleBody({super.key, required this.article});

  @override
  State<MArticleBody> createState() => _MArticleBodyState();
}

class _MArticleBodyState extends State<MArticleBody> {
  String? _parsedBody;
  List<ArticleBlock> _blocks = const [];
  final _recognizers = <TapGestureRecognizer>[];

  List<ArticleBlock> get _currentBlocks {
    if (_parsedBody != widget.article.body) {
      _parsedBody = widget.article.body;
      _blocks = parseArticleBody(widget.article.body);
      for (final r in _recognizers) {
        r.dispose();
      }
      _recognizers.clear();
    }
    return _blocks;
  }

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  /// A link in the story. Links naming a business the way the old site did
  /// (`/business/<slug>/`) open the business here; anything else opens as
  /// written — the website's rule.
  TapGestureRecognizer _linkRecognizer(String href) {
    final r = TapGestureRecognizer()
      ..onTap = () {
        final uri = Uri.tryParse(href.trim());
        if (uri == null) return;
        final ours = uri.host.isEmpty || uri.host == 'modiin4u.co.il' || uri.host.endsWith('.modiin4u.co.il');
        final parts = uri.pathSegments.where((p) => p.isNotEmpty).toList();
        if (ours && parts.length == 2 && parts.first == 'business') {
          context.push('/business/${parts[1]}');
          return;
        }
        launchUrl(uri, mode: LaunchMode.externalApplication);
      };
    _recognizers.add(r);
    return r;
  }

  @override
  Widget build(BuildContext context) {
    final blocks = _currentBlocks;
    if (blocks.isEmpty) return const SizedBox.shrink();

    final article = widget.article;
    final direction = mArticleDirection('${article.title} ${article.body}');
    final base = TextStyle(
      fontFamily: AppFonts.inter,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.6,
      color: kMNewsBodyText,
    );

    Widget text(ArticleBlock block) {
      final heading = block.kind == ArticleBlockKind.heading;
      final listItem = block.kind == ArticleBlockKind.listItem;
      final rich = Text.rich(
        TextSpan(
          children: [
            for (final s in block.spans)
              TextSpan(
                text: s.text,
                style: TextStyle(
                  fontWeight: s.bold ? FontWeight.w600 : null,
                  fontStyle: s.italic ? FontStyle.italic : null,
                  color: s.href != null ? AppColors.midBlue : null,
                  decoration: s.href != null ? TextDecoration.underline : null,
                ),
                recognizer: s.href == null ? null : _linkRecognizer(s.href!),
              ),
          ],
        ),
        style: heading ? base.copyWith(fontSize: 18, height: 1.4, color: Colors.black) : base,
        textDirection: direction,
      );
      if (!listItem) return rich;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 11, end: 10, start: 4),
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(color: kMNewsBodyText, shape: BoxShape.circle),
            ),
          ),
          Expanded(child: rich),
        ],
      );
    }

    final children = <Widget>[];
    for (var i = 0; i < blocks.length; i++) {
      if (i > 0) children.add(const SizedBox(height: 12));
      final block = blocks[i];
      children.add(block.kind == ArticleBlockKind.image ? _MInlinePhoto(block: block) : text(block));
    }

    return Directionality(
      textDirection: direction,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}

/// A photo from the body, the column's width, at its own proportions.
/// WordPress names its resized copies `-300x200.jpg`; the full photo is tried
/// first and the named copy if that fails.
class _MInlinePhoto extends StatelessWidget {
  final ArticleBlock block;
  const _MInlinePhoto({required this.block});

  static final _wpSize = RegExp(r'-\d+x\d+(?=\.[a-zA-Z]+$)');

  @override
  Widget build(BuildContext context) {
    final src = block.src!;
    final full = src.replaceFirst(_wpSize, '');
    final w = block.width;
    final h = block.height;
    final ratio = w != null && h != null && w > 0 && h > 0 ? w / h : null;

    return LayoutBuilder(
      builder: (context, c) {
        final width = c.maxWidth;
        Widget image(String url, {Widget Function()? onError}) => Image.network(
              url,
              width: width,
              height: ratio == null ? null : width / ratio,
              fit: BoxFit.cover,
              webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
              errorBuilder: (_, _, _) => onError?.call() ?? const SizedBox.shrink(),
            );
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: full == src ? image(src) : image(full, onError: () => image(src)),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// MORE RELATED NEWS — 250-wide cards, 20 apart, scrolling sideways
// ─────────────────────────────────────────────

class MRelatedNews extends StatelessWidget {
  final List<Article> articles;
  final VoidCallback onSeeAll;
  final void Function(Article) onOpen;
  const MRelatedNews({super.key, required this.articles, required this.onSeeAll, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    if (articles.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  L.of(context).moreRelatedNews,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 19 / 16,
                    color: const Color(0xFF1F1F1F),
                  ),
                ),
              ),
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
              width: 250,
              onTap: () => onOpen(articles[i]),
            ),
          ),
        ),
      ],
    );
  }
}

/// A story card: photo 150 tall at radius 12, the headline in Inter Medium
/// 16 over two lines, and the date.
class MNewsCard extends StatelessWidget {
  final Article article;
  final double width;
  final double imageHeight;
  final VoidCallback onTap;
  const MNewsCard({
    super.key,
    required this.article,
    required this.onTap,
    this.width = 250,
    this.imageHeight = 150,
  });

  /// How tall a card is, for the horizontal strips that must fix their
  /// height: the photo, two lines of headline, the date and the gaps, with
  /// the text grown by the phone's text-size setting. The strips were a
  /// flat 232, five pixels short of the card even at the normal size, so
  /// every card drew the overflow stripes on iPhone.
  static double heightFor(BuildContext context, {double imageHeight = 150}) {
    final scale = MediaQuery.textScalerOf(context);
    final headline = scale.scale(16) * 1.2 * 2;
    // The date sets no line height of its own, and on iPhone its Hebrew
    // falls back to a system font whose lines run about 1.6 times the size.
    final date = scale.scale(14) * 1.75 > 16 ? scale.scale(14) * 1.75 : 16.0;
    return imageHeight + 12 + headline + 12 + date + 2;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            NetworkPhoto(
              url: article.imageUrl,
              width: width,
              height: imageHeight,
              radius: BorderRadius.circular(12),
              icon: IconsaxPlusLinear.document_text,
            ),
            const SizedBox(height: 12),
            Text(
              article.title,
              textDirection: mArticleDirection(article.title),
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.2,
                color: Colors.black,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
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

// ─────────────────────────────────────────────
// BOTTOM BAR — 69 tall, a rule on top, cells 20 × 12 inside
// ─────────────────────────────────────────────

/// The design's bar holds comments, shares and Save. Articles have no
/// comments in the app and no way to save one, so only Share is drawn; its
/// count shows once a share has been counted.
class MArticleBottomBar extends ConsumerWidget {
  final Article article;
  final VoidCallback onShare;
  const MArticleBottomBar({super.key, required this.article, required this.onShare});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The design's Save cell: the article goes to Favourites → News, whose
    // tab was always empty because nothing could save one. The app only —
    // saving needs an account.
    final saved = ref.watch(
      isFavoriteProvider((kind: FavoriteKind.article, id: article.id)),
    );
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: kMNewsBorder)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onShare,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      SvgPicture.asset('assets/web/news/stat_share.svg', width: 20, height: 20),
                      const SizedBox(width: 12),
                      Text(
                        article.shareCount > 0 ? '${article.shareCount}' : L.of(context).share,
                        style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, height: 17 / 14, color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (!kIsWeb)
              Expanded(
                child: GestureDetector(
                  onTap: () => toggleFavorite(context, ref, FavoriteKind.article, article.id),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          saved ? IconsaxPlusBold.archive_tick : IconsaxPlusLinear.archive_add,
                          size: 20,
                          color: saved ? AppColors.midBlue : Colors.black,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          Localizations.localeOf(context).languageCode == 'he'
                              ? (saved ? 'נשמר' : 'שמירה')
                              : (saved ? 'Saved' : 'Save'),
                          style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, height: 17 / 14, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
