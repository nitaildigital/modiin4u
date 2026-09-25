import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../../favorites/widgets/favorite_button.dart';
import '../../favorites/providers/favorite_providers.dart';
import '../../favorites/repositories/favorite_repository.dart';
import '../models/article.dart';
import '../providers/news_providers.dart';

// ═══════════════════════════════════════════════════════════
// Web Modiin News Detail — full desktop layout from Figma
// (Modiin News Detail — 1920 × 4383)
// ═══════════════════════════════════════════════════════════

const _kBorder = Color(0xFFE7E7E7);
const _kPanelBg = Color(0xFFF8F8F8);
const _kBodyText = Color(0xFF3D3D3D);
const _kGrey = Color(0xFF5F5E5A);
const _kIconGrey = Color(0xFF6D6D6D);
const _kAvatarBg = Color(0xFFEDF3FE);

class WebArticleContent extends ConsumerStatefulWidget {
  final String articleId;
  const WebArticleContent({super.key, required this.articleId});

  @override
  ConsumerState<WebArticleContent> createState() => _WebArticleContentState();
}

class _WebArticleContentState extends ConsumerState<WebArticleContent> {
  bool _isHebrew = false;

  String _t(String en, String he) => _isHebrew ? he : en;

  // ── Nav links ──
  // ═══════════════════════════════════════════════
  // ARTICLE CONTENT
  // ═══════════════════════════════════════════════
  //
  // This page took an `articleId` and never read it. Whatever id it carried,
  // it rendered one story — a municipal programme for women in Modi'in —
  // with its own headline, five paragraphs, a bullet list, an author, four
  // related articles, "359 views", and four comments from named residents
  // ("Zeev Schumacher", "Moran Zelig", "Noam Garcia") with quoted opinions
  // and timestamps. The `comments` table is empty and none of those people
  // had said anything.

  /// The row the route names. Null while it loads, and if it fails.
  Article? get _article =>
      ref.watch(articleByIdProvider(widget.articleId)).valueOrNull;

  String get _title => _article?.title ?? '';

  /// The row's own body, split where the author left a blank line. Nothing
  /// is composed, and a row with no body simply has no paragraphs.
  List<String> get _paragraphs {
    final body = _article?.body.trim() ?? '';
    if (body.isEmpty) return const [];
    return body
        .split(RegExp(r'\n\s*\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
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
              onToggleLanguage: () => setState(() => _isHebrew = !_isHebrew),
            ),
            Expanded(
              child: ref.watch(articleByIdProvider(widget.articleId)).when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, _) => Center(
                  child: Text(
                    _t(
                      'We could not load this article.',
                      'לא הצלחנו לטעון את הכתבה.',
                    ),
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 15,
                      color: _kGrey,
                    ),
                  ),
                ),
                data: (_) => SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 59),
                    _centered(child: _buildHeroCard()),
                    const SizedBox(height: 30),
                    _centered(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 976, child: _buildLeftColumn()),
                          const SizedBox(width: 198),
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

  /// 1600px content column (160px page padding at 1920).
  Widget _centered({required Widget child}) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1600),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: child,
      ),
    );
  }

  // ─────────────────────────────────────────────
  // STICKY NAVBAR
  // ─────────────────────────────────────────────
  // ─────────────────────────────────────────────
  // HERO — 808 image + 792 text panel, 436 tall
  // ─────────────────────────────────────────────
  Widget _buildHeroCard() {
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
                url: _article?.imageUrl,
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
                    // A turquoise "Municipality" badge sat here on every
                    // article. `articles` has no category column and no row
                    // is linked to one, so nothing can fill it.

                    Text(
                      _title,
                      style: TextStyle(fontFamily: AppFonts.nunito, 
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        height: 39 / 32,
                        color: Colors.black,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 38),
                    _buildHeroMeta(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The date and, where the row names one, its author.
  ///
  /// This read "August 5, 2026 | 4:34 p.m." on every article, beside "An
  /// intelligence system for you" — a machine translation of מודיעין, the
  /// city's name, read as the word for intelligence — and "12 Comments",
  /// against an empty comments table.
  Widget _buildHeroMeta() {
    final article = _article;
    if (article == null) return const SizedBox.shrink();

    final author = article.author.trim();

    return Row(
      children: [
        Flexible(
          child: _metaItem(
            icon: IconsaxPlusLinear.calendar_1,
            label: _dateTime(article.publishedAt, _isHebrew),
            iconSize: 18,
          ),
        ),
        if (author.isNotEmpty) ...[
          const SizedBox(width: 31),
          Flexible(
            child: _metaItem(
              icon: IconsaxPlusLinear.user,
              label: author,
            ),
          ),
        ],
      ],
    );
  }

  Widget _metaItem({required IconData icon, required String label, double iconSize = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize, color: _kIconGrey),
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
  // LEFT COLUMN — stats bar, body, comments
  // ─────────────────────────────────────────────
  Widget _buildLeftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 808),
          child: _buildStatsBar(),
        ),
        const SizedBox(height: 114),
        _buildBody(),
        // An advertising slot and a comment thread sat here. The slot was a
        // gradient rectangle with no campaign behind it, and the thread was
        // four comments from named residents — "Zeev Schumacher", "Moran
        // Zelig", "Noam Garcia" — with quoted opinions and timestamps, under
        // a heading reading "12 Comments". The `comments` table is empty and
        // none of those people had written anything.
        //
        // Comments come back when the table has rows and posting is wired;
        // the admin panel already moderates them.
      ],
    );
  }

  Widget _buildStatsBar() {
    final saved = ref.watch(
      isFavoriteProvider((kind: FavoriteKind.article, id: widget.articleId)),
    );

    final link = _article?.canonicalUrl;
    final encodedLink = Uri.encodeComponent(link ?? '');
    final encodedTitle = Uri.encodeComponent(_title);
    final encodedShare = Uri.encodeComponent('$_title\n\n${link ?? ''}');

    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                // "359 views" and "83 shares" were printed for every
                // article. The row keeps its own count, and shares are not
                // recorded anywhere, so only a real count is shown.
                if ((_article?.viewCount ?? 0) > 0)
                  Expanded(
                    child: _statItem(
                      icon: IconsaxPlusLinear.eye,
                      value: '${_article!.viewCount}',
                      label: _t('Views', 'צפיות'),
                      startPadding: 0,
                    ),
                  ),
                Expanded(
                  child: _statItem(
                    // Was a bool held in this widget, so the next page load
                    // forgot it. Writes to `favorites` now.
                    icon: saved
                        ? IconsaxPlusBold.archive
                        : IconsaxPlusLinear.archive,
                    label: _t('Save', 'שמור'),
                    onTap: () => ref
                        .read(favoritesProvider.notifier)
                        .toggle(FavoriteKind.article, widget.articleId),
                  ),
                ),
                Expanded(
                  child: _statItem(
                    icon: IconsaxPlusLinear.share,
                    label: _t('Share', 'שיתוף'),
                    onTap: () => Share.share('$_title\n\nModiin4u'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 9),
          if (link != null && link.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _shareIcon(
                const Color(0xFF1877F2),
                'f',
                url:
                    'https://www.facebook.com/sharer/sharer.php?u=$encodedLink',
              ),
              const SizedBox(width: 19),
              _shareIcon(
                const Color(0xFF4CAF50),
                null,
                icon: IconsaxPlusBold.message,
                url: 'https://wa.me/?text=$encodedShare',
              ),
              const SizedBox(width: 19),
              _shareIcon(
                Colors.black,
                'X',
                url: 'https://twitter.com/intent/tweet?text=$encodedShare',
              ),
              const SizedBox(width: 19),
              _shareIcon(
                const Color(0xFF2196F3),
                null,
                icon: IconsaxPlusBold.sms,
                url: 'mailto:?subject=$encodedTitle&body=$encodedShare',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem({
    required IconData icon,
    String? value,
    required String label,
    double startPadding = 24,
    VoidCallback? onTap,
  }) {
    final content = Container(
      height: 48,
      padding: EdgeInsetsDirectional.only(start: startPadding, end: 24),
      decoration: const BoxDecoration(
        border: BorderDirectional(end: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.black),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (value != null) ...[
                  Text(value,
                      style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, height: 17 / 14, color: Colors.black)),
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
      ),
    );
    if (onTap == null) return content;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: content),
    );
  }

  /// Four coloured circles with no handler before. They open the usual
  /// share dialogs now, and are not drawn for a row with no public link —
  /// the app's own web build is not published yet, so `canonical_url` on the
  /// existing site is the only address a share can point at.
  Widget _shareIcon(
    Color color,
    String? letter, {
    IconData? icon,
    required String url,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => launchUrl(Uri.parse(url)),
        child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Center(
          child: icon != null
              ? Icon(icon, size: 16, color: Colors.white)
              : Text(
                  letter!,
                  style: TextStyle(fontFamily: AppFonts.inter, 
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ARTICLE BODY
  // ─────────────────────────────────────────────
  Widget _buildBody() {
    final blocks = <Widget>[];

    void addParagraph(String text) {
      blocks.add(Text(
        text,
        style: TextStyle(fontFamily: AppFonts.inter, 
          fontSize: 18,
          fontWeight: FontWeight.w400,
          height: 1.6,
          color: _kBodyText,
        ),
      ));
    }

    // The bullet list and the two inline illustrations that used to sit
    // between these paragraphs belonged to the one story this page always
    // told. An article has a body; it does not have a bullet list.
    for (final paragraph in _paragraphs) {
      addParagraph(paragraph);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          if (i > 0) const SizedBox(height: 40),
          blocks[i],
        ],
      ],
    );
  }

  Widget _inlineImage(double width, double height, List<Color> colors) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = width > constraints.maxWidth ? constraints.maxWidth : width;
        return Align(
          alignment: AlignmentDirectional.centerStart,
          child: SizedBox(
            width: w,
            height: height * (w / width),
            child: _imagePlaceholder(colors, glyphSize: 48),
          ),
        );
      },
    );
  }

  /// In-article ad banner (image 37 — 796 × 228).

  // ─────────────────────────────────────────────
  // COMMENTS
  // ─────────────────────────────────────────────



  // ─────────────────────────────────────────────
  // SIDEBAR — related news + ad
  // ─────────────────────────────────────────────
  Widget _buildSidebar() {
    final related =
        (ref.watch(publishedArticlesProvider).valueOrNull ?? const <Article>[])
            .where((a) => a.id != widget.articleId)
            .take(4)
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 7),
        Text(
          _t('More Related News', 'עוד חדשות קשורות'),
          style: TextStyle(fontFamily: AppFonts.inter, 
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 22 / 18,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 40),
        // Four articles written into this file before, each with an invented
        // headline and date. These are the newest published ones, with the
        // article being read left out of its own sidebar.
        ...related.map(
          (a) => _RelatedRow(
            article: a,
            isHebrew: _isHebrew,
            onTap: () => context.push('/article/${a.id}'),
          ),
        ),
        // A 260px advertising panel sat here. There is no ad table and no
        // campaign behind it — it was a gradient rectangle.
      ],
    );
  }

  // ─────────────────────────────────────────────
  // FOOTER
  // ─────────────────────────────────────────────
}

// ═══════════════════════════════════════════════
// SHARED PIECES
// ═══════════════════════════════════════════════

/// Gradient stand-in until real article photography is wired up.
Widget _imagePlaceholder(
  List<Color> colors, {
  double radius = 12,
  double glyphSize = 40,
  double glyphOpacity = 0.12,
}) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ),
    ),
    child: Center(
      child: Icon(
        IconsaxPlusLinear.image,
        size: glyphSize,
        color: Colors.white.withValues(alpha: glyphOpacity),
      ),
    ),
  );
}


class _Comment {
  final String initials, name, date, text;
  const _Comment({required this.initials, required this.name, required this.date, required this.text});
}

/// 426 × 121 related-news row — 110 × 80 thumb, 2-line title, date.
const _enMonths = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
const _heMonths = [
  'ינואר', 'פברואר', 'מרץ', 'אפריל', 'מאי', 'יוני',
  'יולי', 'אוגוסט', 'ספטמבר', 'אוקטובר', 'נובמבר', 'דצמבר',
];

/// "August 5, 2026", or "5 באוגוסט 2026". `published_at` is UTC, so it is
/// moved to the reader's zone first. Matches `web_news_screen.dart`.
String _date(DateTime value, bool isHebrew) {
  final d = value.toLocal();
  return isHebrew
      ? '${d.day} ב${_heMonths[d.month - 1]} ${d.year}'
      : '${_enMonths[d.month - 1]} ${d.day}, ${d.year}';
}

/// The same, with the hour appended.
String _dateTime(DateTime value, bool isHebrew) {
  final d = value.toLocal();
  final time =
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';
  return '${_date(value, isHebrew)} | $time';
}

class _RelatedRow extends StatefulWidget {
  final Article article;
  final bool isHebrew;
  final VoidCallback onTap;
  const _RelatedRow({
    required this.article,
    required this.isHebrew,
    required this.onTap,
  });

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
              SizedBox(
                width: 110,
                height: 80,
                // The row's own photograph, or the brand panel where it has
                // none. Four pastel gradients stood in for these.
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: NetworkPhoto(
                    url: r.imageUrl,
                    fit: BoxFit.cover,
                    icon: IconsaxPlusLinear.document_text,
                    iconSize: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      r.title,
                      style: TextStyle(fontFamily: AppFonts.nunito, 
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        height: 22 / 18,
                        color: _hovered ? AppColors.midBlue : Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(IconsaxPlusLinear.calendar_1, size: 16, color: _kIconGrey),
                        const SizedBox(width: 9),
                        Flexible(
                          child: Text(
                            _date(r.publishedAt, widget.isHebrew),
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
            ],
          ),
        ),
      ),
    );
  }
}

/// 918 × 131 comment row — avatar, name + date, body, reply action.
class _CommentTile extends StatelessWidget {
  final _Comment comment;
  final String replyLabel;
  const _CommentTile({required this.comment, required this.replyLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        border: BorderDirectional(bottom: BorderSide(color: _kBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: AppColors.turquoise, shape: BoxShape.circle),
            child: Center(
              child: Text(
                comment.initials,
                style: TextStyle(fontFamily: AppFonts.inter, 
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 17 / 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.name,
                      style: TextStyle(fontFamily: AppFonts.inter, 
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 19 / 16,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      comment.date,
                      style: TextStyle(fontFamily: AppFonts.inter, fontSize: 12, height: 15 / 12, color: _kIconGrey),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  comment.text,
                  style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, height: 1.4, color: _kBodyText),
                ),
                const SizedBox(height: 12),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(IconsaxPlusLinear.undo, size: 20, color: AppColors.midBlue),
                      const SizedBox(width: 8),
                      Text(
                        replyLabel,
                        style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, height: 17 / 14, color: AppColors.midBlue),
                      ),
                    ],
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
