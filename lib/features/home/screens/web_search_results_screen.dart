import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../providers/search_providers.dart';

// ═══════════════════════════════════════════════════════════
// Web Search Results — desktop results page
//
// The phone screen draws one 430px column of 44px rows. The same hits are
// laid out here as wide cards, two or three across, and split under a
// heading per kind: the search runs over businesses, events and articles
// at once, and on a laptop there is room to say which is which rather
// than relying on the order they happen to arrive in.
// ═══════════════════════════════════════════════════════════

const _kBorder = Color(0xFFE7E7E7);
const _kGreyText = Color(0xFF5F5E5A);
const _kHeading = Color(0xFF1C1C1E);
const _kIconGrey = Color(0xFF6D6D6D);

class WebSearchResultsContent extends ConsumerStatefulWidget {
  final String query;

  const WebSearchResultsContent({super.key, required this.query});

  @override
  ConsumerState<WebSearchResultsContent> createState() =>
      _WebSearchResultsContentState();
}

class _WebSearchResultsContentState
    extends ConsumerState<WebSearchResultsContent> {
  bool _isHebrew = false;

  /// The term the page is showing. It starts as the one the route carried and
  /// changes when the bar below is submitted, so a second search does not have
  /// to go back through the route and rebuild the whole page.
  late String _query = widget.query;
  late final TextEditingController _searchCtrl = TextEditingController(
    text: widget.query,
  );

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _t(String en, String he) => _isHebrew ? he : en;

  void _submit() {
    final next = _searchCtrl.text.trim();
    if (next == _query) return;
    setState(() => _query = next);
  }

  /// `SearchHit.category` is the Hebrew word the provider files each kind
  /// under. The page is drawn in both languages, so the heading reads from
  /// that rather than printing Hebrew into an English layout.
  String _kindLabel(String category, {required bool plural}) =>
      switch (category) {
        'עסק' => plural ? _t('Businesses', 'עסקים') : _t('Business', 'עסק'),
        'אירוע' => plural ? _t('Events', 'אירועים') : _t('Event', 'אירוע'),
        'חדשות' => _t('News', 'חדשות'),
        _ => category,
      };

  /// The hits split by kind, in the order the provider returns them —
  /// businesses, then events, then articles.
  List<(String, List<SearchHit>)> _grouped(List<SearchHit> hits) {
    final order = <String>[];
    final byKind = <String, List<SearchHit>>{};
    for (final hit in hits) {
      if (!byKind.containsKey(hit.category)) order.add(hit.category);
      byKind.putIfAbsent(hit.category, () => []).add(hit);
    }
    return [for (final kind in order) (kind, byKind[kind]!)];
  }

  @override
  Widget build(BuildContext context) {
    final provider = searchResultsProvider(_query);
    final request = ref.watch(provider);

    return Directionality(
      textDirection: _isHebrew ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            WebNavbar(
              isHebrew: _isHebrew,
              onToggleLanguage: () => setState(() => _isHebrew = !_isHebrew),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeader(request),
                    _buildBody(request, provider),
                    const SizedBox(height: 100),
                    WebFooter(isHebrew: _isHebrew),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HEADER — heading, search bar, live count
  // ─────────────────────────────────────────────
  Widget _buildHeader(AsyncValue<List<SearchHit>> request) {
    final count = request.valueOrNull?.length ?? 0;

    return Padding(
      padding: const EdgeInsets.only(top: 56),
      child: WebSection(
        // WebSection centres its column and lets it shrink to its widest
        // child, so a heading, a line of text and an 820px search bar would
        // sit in the middle of the page rather than over the results.
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t('Search Results', 'תוצאות חיפוש'),
                style: TextStyle(
                  fontFamily: AppFonts.nunito,
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                  color: AppColors.midBlue,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                switch (request) {
                  _ when _query.isEmpty => _t(
                    'Search businesses, events and news across Modiin.',
                    'חפשו עסקים, אירועים וחדשות במודיעין.',
                  ),
                  AsyncLoading() => _t('Searching…', 'מחפשים…'),
                  AsyncError() => _t(
                    'The search could not be run.',
                    'לא ניתן לבצע את החיפוש.',
                  ),
                  _ =>
                    count == 1
                        ? _t(
                            '1 result for "$_query"',
                            'תוצאה אחת עבור "$_query"',
                          )
                        : _t(
                            '$count results for "$_query"',
                            '$count תוצאות עבור "$_query"',
                          ),
                },
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  color: _kGreyText,
                  height: 1.21,
                ),
              ),
              const SizedBox(height: 28),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: _buildSearchBar(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 24),
          const Icon(
            IconsaxPlusLinear.search_normal_1,
            size: 20,
            color: _kIconGrey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: (_) => _submit(),
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 16,
                color: _kHeading,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: _t(
                  'Search businesses, events, news...',
                  'חפשו עסקים, אירועים, חדשות...',
                ),
                hintStyle: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 16,
                  color: _kIconGrey,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _submit,
              child: Container(
                height: 48,
                margin: const EdgeInsetsDirectional.only(end: 8),
                padding: const EdgeInsets.symmetric(horizontal: 32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.midBlue,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  _t('Search', 'חיפוש'),
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // RESULTS — a section per kind, each a wide grid
  // ─────────────────────────────────────────────
  Widget _buildBody(
    AsyncValue<List<SearchHit>> request,
    ProviderBase<AsyncValue<List<SearchHit>>> provider,
  ) {
    if (_query.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 40),
        child: WebSection(
          child: _buildNotice(
            icon: IconsaxPlusLinear.search_normal_1,
            title: _t('Nothing searched yet', 'עדיין לא חיפשתם'),
            body: _t(
              'Type a name, a place or a word above.',
              'הקלידו שם, מקום או מילה בשורה שלמעלה.',
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: WebSection(
        child: switch (request) {
          AsyncLoading() => const SizedBox(
            height: 320,
            child: Center(child: CircularProgressIndicator()),
          ),
          AsyncError() => _buildNotice(
            icon: IconsaxPlusLinear.wifi_square,
            title: _t('The search could not be run', 'לא ניתן לבצע את החיפוש'),
            body: _t(
              'Check your connection and try again.',
              'בדקו את החיבור לאינטרנט ונסו שוב.',
            ),
            actionLabel: _t('Try again', 'נסו שוב'),
            onAction: () => ref.invalidate(provider),
          ),
          _ => _buildGroups(request.value ?? const []),
        },
      ),
    );
  }

  Widget _buildGroups(List<SearchHit> hits) {
    if (hits.isEmpty) {
      return _buildNotice(
        icon: IconsaxPlusLinear.search_status,
        title: _t('No results found', 'לא נמצאו תוצאות'),
        body: _t(
          'Nothing in the directory, the events or the news matches "$_query".',
          'לא נמצא דבר במדריך, באירועים או בחדשות שתואם ל"$_query".',
        ),
      );
    }

    final groups = _grouped(hits);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, (kind, rows)) in groups.indexed) ...[
          if (i > 0) const SizedBox(height: 56),
          Row(
            children: [
              Text(
                _kindLabel(kind, plural: rows.length != 1),
                style: TextStyle(
                  fontFamily: AppFonts.nunito,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.midBlue,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.midBlue.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${rows.length}',
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.midBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 20.0;
              // Three across once there is room for a photo, a title and a
              // two-line blurb in each; two below that.
              final perRow = constraints.maxWidth >= 1350 ? 3 : 2;
              final cardWidth =
                  (constraints.maxWidth - gap * (perRow - 1)) / perRow;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final hit in rows)
                    SizedBox(
                      width: cardWidth,
                      height: 132,
                      child: _ResultCard(
                        hit: hit,
                        kindLabel: _kindLabel(hit.category, plural: false),
                        onTap: () => context.push(hit.route),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildNotice({
    required IconData icon,
    required String title,
    required String body,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      height: 320,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 44, color: _kGreyText.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _kHeading,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              color: _kGreyText,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onAction,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.midBlue,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    actionLabel,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// RESULT CARD — photo, title, blurb, kind chip
// ─────────────────────────────────────────────
class _ResultCard extends StatefulWidget {
  final SearchHit hit;
  final String kindLabel;
  final VoidCallback onTap;

  const _ResultCard({
    required this.hit,
    required this.kindLabel,
    required this.onTap,
  });

  @override
  State<_ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<_ResultCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final hit = widget.hit;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _hovered ? AppColors.midBlue : _kBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _hitImage(hit),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.midBlue.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.kindLabel,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.midBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hit.title,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: _kHeading,
                        height: 1.22,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hit.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        hit.subtitle,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 13,
                          color: _kGreyText,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: _hovered ? AppColors.midBlue : _kIconGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The hit's photo, at the size the card reserves for it.
///
/// Drawn with the browser's own <img> element rather than decoded into the
/// CanvasKit surface, which is how the covers load on the other web pages.
/// A record with no picture — and events carry none at all yet — gets the
/// tinted square with its own glyph instead, at the same size, so nothing
/// shifts either way.
Widget _hitImage(SearchHit hit) {
  final fallback = Container(
    width: 96,
    height: 96,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.turquoise.withValues(alpha: 0.10),
          AppColors.turquoise.withValues(alpha: 0.06),
        ],
      ),
    ),
    child: Center(child: Icon(hit.icon, size: 32, color: AppColors.turquoise)),
  );

  final url = hit.imageUrl ?? '';
  if (url.isEmpty) return fallback;

  return ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: Image.network(
      url,
      width: 96,
      height: 96,
      fit: BoxFit.cover,
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      errorBuilder: (_, _, _) => fallback,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : fallback,
    ),
  );
}
