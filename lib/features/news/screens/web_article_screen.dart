import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/providers/banners_provider.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../models/article.dart';
import '../models/article_body.dart';
import '../providers/news_providers.dart';
import '../../../shared/widgets/web_share_menu.dart';

// ═══════════════════════════════════════════════════════════
// Web Modiin News Detail — full desktop layout from Figma
// ("Modiin News Detail" 194:9549, 1920 × 4383, and 245:2653, 1920 × 4520)
//
// The two frames are the same page for a reader who is signed out and one
// who is signed in: they differ only at the foot, where the first asks the
// reader to log in to comment and the second gives them a box to write in.
// Accounts are the app's alone, so neither is drawn here, and nor is the
// comment thread above them, its "12 Comments" count in the header, or the
// Save button in the bar under the photo.
// ═══════════════════════════════════════════════════════════

const _kBorder = Color(0xFFE7E7E7);
const _kPanelBg = Color(0xFFF8F8F8);
const _kBodyText = Color(0xFF3D3D3D);
const _kGrey = Color(0xFF5F5E5A);

final _hebrew = RegExp(r'[֐-׿]');

/// Articles are written in Hebrew whichever way the page toggle is set, so
/// their own text is laid out by its script, not by the chrome's language.
TextDirection _directionOf(String text) =>
    _hebrew.hasMatch(text) ? TextDirection.rtl : TextDirection.ltr;

class WebArticleContent extends ConsumerStatefulWidget {
  final String articleId;
  const WebArticleContent({super.key, required this.articleId});

  @override
  ConsumerState<WebArticleContent> createState() => _WebArticleContentState();
}

class _WebArticleContentState extends ConsumerState<WebArticleContent>
    with WebLanguageState<WebArticleContent> {
  bool get _isHebrew => webIsHebrew.value;

  String _t(String en, String he) => _isHebrew ? he : en;

  // This page took an `articleId` and never read it. Whatever id it carried,
  // it rendered one story — a municipal programme for women in Modi'in —
  // with its own headline, five paragraphs, a bullet list, an author, four
  // related articles, "359 views", and four comments from named residents
  // ("Zeev Schumacher", "Moran Zelig", "Noam Garcia") with quoted opinions
  // and timestamps. The `comments` table is empty and none of those people
  // had said anything.

  /// The body read into blocks, kept for the article it was read from. Links
  /// in it carry tap recognizers, which have to be disposed of.
  String? _parsedBody;
  List<ArticleBlock> _blocks = const [];
  final _recognizers = <TapGestureRecognizer>[];

  List<ArticleBlock> _blocksOf(Article article) {
    if (_parsedBody != article.body) {
      _parsedBody = article.body;
      _blocks = parseArticleBody(article.body);
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

  // ═══════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════

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
              activeId: 'news',
            ),
            Expanded(
              child: ref.watch(articleByIdProvider(widget.articleId)).when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Center(
                  child: Text(
                    _t('We could not load this article.', 'לא הצלחנו לטעון את הכתבה.'),
                    style: TextStyle(fontFamily: AppFonts.inter, fontSize: 15, color: _kGrey),
                  ),
                ),
                data: (article) => SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 59),
                      WebSection(child: _buildHero(article)),
                      const SizedBox(height: 30),
                      WebSection(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 976, child: _buildMainColumn(article)),
                            // 198 at 1920; it gives way first as the window
                            // narrows, so the text keeps its measure.
                            const Spacer(flex: 198),
                            SizedBox(width: 426, child: _buildSidebar()),
                          ],
                        ),
                      ),
                      const SizedBox(height: 103),
                      WebFooter(isHebrew: _isHebrew),
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

  // ─────────────────────────────────────────────
  // HERO — 808 photo + 792 panel, 436 tall
  // ─────────────────────────────────────────────
  Widget _buildHero(Article article) {
    final category =
        (ref.watch(articleFilingProvider).valueOrNull ?? const {})[article.id];

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 436,
        child: Row(
          children: [
            Expanded(
              flex: 808,
              // The article's own photograph — 642 of the 669 rows carry
              // one — and the brand panel where it has none.
              child: NetworkPhoto(
                url: article.imageUrl,
                fit: BoxFit.cover,
                icon: IconsaxPlusLinear.document_text,
                iconSize: 64,
              ),
            ),
            Expanded(
              flex: 792,
              child: Container(
                color: _kPanelBg,
                padding: const EdgeInsetsDirectional.only(start: 40, end: 48),
                alignment: AlignmentDirectional.centerStart,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // The category the story is filed under, which leads to
                    // the rest of that category. It read "Municipality" on
                    // every article before, whatever the article was.
                    if (category != null) ...[
                      _CategoryChip(
                        label: category.name,
                        onTap: () => context.go('/news/category/${category.id}'),
                      ),
                      const SizedBox(height: 21),
                    ],
                    Text(
                      article.title,
                      textDirection: _directionOf(article.title),
                      style: TextStyle(
                        fontFamily: AppFonts.nunito,
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        height: 39 / 32,
                        color: Colors.black,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 38),
                    _buildHeroMeta(article),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The date and, where the row names one, its byline — the design's two
  /// columns, 241 wide and 31 apart.
  ///
  /// This read "August 5, 2026 | 4:34 p.m." on every article, beside "An
  /// intelligence system for you" — a machine translation of מודיעין, the
  /// city's name, read as the word for intelligence — and "12 Comments",
  /// against an empty comments table.
  Widget _buildHeroMeta(Article article) {
    final author = article.author.trim();
    return Row(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 241),
          child: _metaItem(
            icon: 'assets/web/news/meta_date.svg',
            iconSize: 18,
            label: _dateTime(article.publishedAt, _isHebrew),
          ),
        ),
        if (author.isNotEmpty) ...[
          const SizedBox(width: 31),
          Flexible(child: _metaItem(icon: 'assets/web/news/meta_author.svg', label: author)),
        ],
      ],
    );
  }

  Widget _metaItem({required String icon, required String label, double iconSize = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(icon, width: iconSize, height: iconSize),
        const SizedBox(width: 9),
        Flexible(
          child: Text(
            label,
            style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, height: 19 / 16, color: _kGrey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // MAIN COLUMN — the bar under the photo, the body, the inline banner
  // ─────────────────────────────────────────────
  Widget _buildMainColumn(Article article) {
    final inline = ref.watch(activeBannersProvider('ARTICLE_INLINE')).valueOrNull ?? const <SiteBanner>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 808),
            child: _buildStatsBar(article),
          ),
        ),
        const SizedBox(height: 32),
        _buildBody(article),
        // The advertisement the design sets under the story, 796 × 228 and
        // 122 in from the column's edge. It was a gradient rectangle with no
        // campaign behind it; it is the campaign booked for the slot now,
        // and nothing when none is.
        if (inline.isNotEmpty) ...[
          const SizedBox(height: 61),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 122),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: _Banner(banner: inline.first, width: 796),
            ),
          ),
        ],
      ],
    );
  }

  /// Views, share, and the four ways to pass the story on.
  Widget _buildStatsBar(Article article) {
    final link = _shareLink(article);
    final text = Uri.encodeComponent('${article.title}\n\n$link');

    // "359 views" and "83 shares" were printed for every article. The row
    // keeps its own counts, and only a count there is shown — a row nobody
    // has counted says nothing rather than "0". Save was here too; saving
    // needs an account, which is the app's.
    final stats = <Widget>[
      if (article.viewCount > 0)
        _statItem(
          icon: 'assets/web/news/stat_views.svg',
          value: '${article.viewCount}',
          label: _t('Views', 'צפיות'),
        ),
      // The browser's own share sheet needs https, and without it this
      // opened an e-mail; the site's menu works on any page.
      Builder(
        builder: (anchor) => _statItem(
          icon: 'assets/web/news/stat_share.svg',
          value: article.shareCount > 0 ? '${article.shareCount}' : null,
          label: _t('Share', 'שיתוף'),
          onTap: () => showWebShareMenu(anchor, title: article.title, link: link, isHebrew: _isHebrew),
        ),
      ),
    ];

    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (var i = 0; i < stats.length; i++)
            Expanded(
              child: Container(
                height: 48,
                // The first sits against the bar's own padding; the others
                // are 24 in from the rule before them.
                padding: EdgeInsetsDirectional.only(start: i == 0 ? 0 : 24, end: 24),
                decoration: const BoxDecoration(
                  border: BorderDirectional(end: BorderSide(color: _kBorder)),
                ),
                child: stats[i],
              ),
            ),
          const SizedBox(width: 9),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _shareIcon(
                // Only the "f" is drawn, centred in the 32 box.
                SvgPicture.asset('assets/web/news/share_facebook.svg', width: 13.792, height: 25.568),
                tooltip: 'Facebook',
                url: 'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(link)}',
              ),
              const SizedBox(width: 19),
              _shareIcon(
                SvgPicture.asset('assets/web/news/share_whatsapp.svg', width: 32, height: 32),
                tooltip: 'WhatsApp',
                url: 'https://wa.me/?text=$text',
              ),
              const SizedBox(width: 19),
              _shareIcon(
                SvgPicture.asset('assets/web/news/share_x.svg', width: 32, height: 32),
                tooltip: 'X',
                url: 'https://twitter.com/intent/tweet?text=$text',
              ),
              const SizedBox(width: 19),
              _shareIcon(
                SvgPicture.asset('assets/web/news/share_mail.svg', width: 28, height: 28),
                tooltip: _t('Email', 'דוא"ל'),
                url: 'mailto:?subject=${Uri.encodeComponent(article.title)}&body=$text',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Where a share points: the story on the client's site, which 659 of the
  /// rows name, or else this page.
  String _shareLink(Article article) {
    final canonical = article.canonicalUrl?.trim() ?? '';
    return canonical.isNotEmpty ? canonical : Uri.base.toString();
  }

  Widget _statItem({required String icon, String? value, required String label, VoidCallback? onTap}) {
    final content = Row(
      children: [
        SvgPicture.asset(icon, width: 24, height: 24),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (value != null) ...[
                Text(value, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, height: 17 / 14, color: Colors.black)),
                const SizedBox(height: 2),
              ],
              Text(
                label.toUpperCase(),
                style: TextStyle(fontFamily: AppFonts.inter, fontSize: 12, height: 15 / 12, color: Colors.black),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
    if (onTap == null) return content;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: content),
    );
  }

  Widget _shareIcon(Widget icon, {required String tooltip, required String url}) {
    return Tooltip(
      message: tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => launchUrl(Uri.parse(url)),
          child: SizedBox(width: 32, height: 32, child: Center(child: icon)),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BODY — Inter 18 at 1.6, paragraphs 40 apart, list items 24 apart,
  // photos between them
  // ─────────────────────────────────────────────
  Widget _buildBody(Article article) {
    final blocks = _blocksOf(article);
    if (blocks.isEmpty) return const SizedBox.shrink();

    final direction = _directionOf('${article.title} ${article.body}');
    final base = TextStyle(
      fontFamily: AppFonts.inter,
      fontSize: 18,
      fontWeight: FontWeight.w400,
      height: 1.6,
      color: _kBodyText,
    );

    Widget text(ArticleBlock block) {
      return Text.rich(
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
                mouseCursor: s.href == null ? null : SystemMouseCursors.click,
              ),
          ],
        ),
        style: base,
        textDirection: direction,
      );
    }

    final children = <Widget>[];
    for (var i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      if (i > 0) {
        final listRun = block.kind == ArticleBlockKind.listItem &&
            blocks[i - 1].kind == ArticleBlockKind.listItem;
        children.add(SizedBox(height: listRun ? 24 : 40));
      }
      children.add(
        block.kind == ArticleBlockKind.image
            ? _InlinePhoto(block: block, direction: direction)
            : text(block),
      );
    }

    return Directionality(
      textDirection: direction,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  /// A link in the story. The stories came from the client's WordPress, and
  /// about 140 of their links name a business the way that site did —
  /// `modiin4u.co.il/business/<slug>/`, or just `/business/<slug>/` — which
  /// would open the old site, or, relative, an address this site did not
  /// understand. Those open the business here; the business page reads a
  /// slug as well as an id. Anything else opens as written.
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
        launchUrl(uri);
      };
    _recognizers.add(r);
    return r;
  }

  // ─────────────────────────────────────────────
  // SIDEBAR — related news, then the banner
  // ─────────────────────────────────────────────
  Widget _buildSidebar() {
    final related = ref.watch(relatedArticlesProvider(widget.articleId)).valueOrNull ?? const <Article>[];
    final banners = ref.watch(activeBannersProvider('NEWS_SIDEBAR')).valueOrNull ?? const <SiteBanner>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 7),
        Text(
          _t('More Related News', 'עוד חדשות קשורות'),
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 22 / 18,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 18),
        // Four articles written into this file before, each with an invented
        // headline and date. These are the newest others in the story's own
        // category, with the newest of all making up the four.
        for (final a in related)
          _RelatedRow(
            article: a,
            date: _dateTime(a.publishedAt, _isHebrew),
            onTap: () => context.push('/article/${a.id}'),
          ),
        // A 260px advertising panel sat here with no campaign behind it. It
        // is the news pages' banner slot now, and nothing when none is booked.
        if (banners.isNotEmpty) ...[
          const SizedBox(height: 39),
          _SidebarBanner(banners: banners),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// SHARED PIECES
// ═══════════════════════════════════════════════

const _enMonths = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
const _heMonths = [
  'ינואר', 'פברואר', 'מרץ', 'אפריל', 'מאי', 'יוני',
  'יולי', 'אוגוסט', 'ספטמבר', 'אוקטובר', 'נובמבר', 'דצמבר',
];

/// "August 5, 2026 | 4:34 p.m.", as the design writes it, or "5 באוגוסט
/// 2026 | 16:34". `published_at` is UTC, so it is moved to the reader's zone
/// first.
String _dateTime(DateTime value, bool isHebrew) {
  final d = value.toLocal();
  final mm = d.minute.toString().padLeft(2, '0');
  if (isHebrew) {
    return '${d.day} ב${_heMonths[d.month - 1]} ${d.year} | ${d.hour.toString().padLeft(2, '0')}:$mm';
  }
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '${_enMonths[d.month - 1]} ${d.day}, ${d.year} | $h:$mm ${d.hour < 12 ? 'a.m.' : 'p.m.'}';
}

/// The turquoise category chip, 36 tall.
class _CategoryChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _CategoryChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              height: 24 / 14,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// A photograph inside the story, 516 wide as the design draws the first,
/// at its own proportions and against the text's leading edge.
///
/// The imported stories keep their photos on the client's WordPress site,
/// linked at WordPress's 300-wide copy. The full-size file sits beside it
/// under the same name without the size, so that is asked for first. That
/// site sends no CORS headers, so the browser draws the photo itself rather
/// than handing its bytes to Flutter.
class _InlinePhoto extends StatelessWidget {
  final ArticleBlock block;
  final TextDirection direction;
  const _InlinePhoto({required this.block, required this.direction});

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
        final width = c.maxWidth < 516 ? c.maxWidth : 516.0;
        Widget image(String url, {Widget Function()? onError}) => Image.network(
          url,
          width: width,
          height: ratio == null ? null : width / ratio,
          fit: BoxFit.cover,
          webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
          errorBuilder: (_, _, _) => onError?.call() ?? const SizedBox.shrink(),
        );
        return Align(
          alignment: AlignmentDirectional.centerStart,
          child: full == src ? image(src) : image(full, onError: () => image(src)),
        );
      },
    );
  }
}

/// A booked banner at [width] and its own height, linking where the
/// campaign says.
class _Banner extends StatelessWidget {
  final SiteBanner banner;
  final double width;
  const _Banner({required this.banner, required this.width});

  @override
  Widget build(BuildContext context) {
    final link = banner.destinationUrl;
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth < width ? c.maxWidth : width;
        return MouseRegion(
          cursor: link == null ? MouseCursor.defer : SystemMouseCursors.click,
          child: GestureDetector(
            onTap: link == null ? null : () => launchUrl(Uri.parse(link)),
            child: Image.network(
              sizedPhotoUrl(banner.imageUrl, w, MediaQuery.devicePixelRatioOf(context)),
              width: w,
              fit: BoxFit.fitWidth,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}

/// The banner under "More Related News". The design draws a landscape
/// creative there, 426 × 260, while the same slot on the news page runs tall
/// ones 630 high down its side — at 426 wide one of those would stand 725
/// tall beside the story. So the slot's creatives are measured as they load
/// and the first wider than tall is shown; the first of all when none is.
class _SidebarBanner extends StatefulWidget {
  final List<SiteBanner> banners;
  const _SidebarBanner({required this.banners});

  @override
  State<_SidebarBanner> createState() => _SidebarBannerState();
}

class _SidebarBannerState extends State<_SidebarBanner> {
  static const _width = 426.0;

  /// Width over height of each creative, by id, as each arrives; 0 for one
  /// that would not load.
  final _ratios = <String, double>{};
  final _requested = <String>{};
  final _listeners = <(ImageStream, ImageStreamListener)>[];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _measure();
  }

  @override
  void didUpdateWidget(_SidebarBanner old) {
    super.didUpdateWidget(old);
    _measure();
  }

  void _measure() {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    for (final b in widget.banners) {
      if (!_requested.add(b.id)) continue;
      // The same address the banner is then drawn from, so the image cache
      // hands it straight back.
      final stream = NetworkImage(sizedPhotoUrl(b.imageUrl, _width, dpr))
          .resolve(createLocalImageConfiguration(context));
      final listener = ImageStreamListener(
        (info, _) {
          if (mounted) setState(() => _ratios[b.id] = info.image.width / info.image.height);
        },
        onError: (_, _) {
          if (mounted) setState(() => _ratios[b.id] = 0);
        },
      );
      stream.addListener(listener);
      _listeners.add((stream, listener));
    }
  }

  @override
  void dispose() {
    for (final (stream, listener) in _listeners) {
      stream.removeListener(listener);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banners = widget.banners;
    // Until every creative has been measured the choice could still change,
    // so nothing is drawn rather than one banner and then another.
    if (banners.any((b) => !_ratios.containsKey(b.id))) return const SizedBox.shrink();
    final landscape = banners.where((b) => (_ratios[b.id] ?? 0) > 1);
    final pick = landscape.isNotEmpty
        ? landscape.first
        : banners.firstWhere((b) => (_ratios[b.id] ?? 0) > 0, orElse: () => banners.first);
    return _Banner(banner: pick, width: _width);
  }
}

/// 426 × 121 related-news row — 110 × 80 photo, two-line title, date.
class _RelatedRow extends StatefulWidget {
  final Article article;
  final String date;
  final VoidCallback onTap;
  const _RelatedRow({required this.article, required this.date, required this.onTap});

  @override
  State<_RelatedRow> createState() => _RelatedRowState();
}

class _RelatedRowState extends State<_RelatedRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.article;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 121,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: const BoxDecoration(
            border: BorderDirectional(bottom: BorderSide(color: _kBorder)),
          ),
          child: Row(
            children: [
              // The row's own photograph, or the brand panel where it has
              // none. Four pastel gradients stood in for these.
              NetworkPhoto(
                url: r.imageUrl,
                width: 110,
                height: 80,
                radius: BorderRadius.circular(6),
                icon: IconsaxPlusLinear.document_text,
                iconSize: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  // The text column is 288 of the 304 beside the photo.
                  padding: const EdgeInsetsDirectional.only(end: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 50,
                        width: double.infinity,
                        child: Text(
                          r.title,
                          textDirection: _directionOf(r.title),
                          style: TextStyle(
                            fontFamily: AppFonts.nunito,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            height: 25 / 18,
                            color: _hovered ? AppColors.midBlue : Colors.black,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          SvgPicture.asset('assets/web/home/date.svg', width: 16, height: 16),
                          const SizedBox(width: 9),
                          Flexible(
                            child: Text(
                              widget.date,
                              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, height: 17 / 14, color: _kGrey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
