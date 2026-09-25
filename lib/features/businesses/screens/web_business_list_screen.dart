import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../models/business.dart';
import '../providers/business_providers.dart';

// ═══════════════════════════════════════════════════════════
// Web Business List — one category, at desktop width
//
// This is where every category tile on the businesses and restaurants
// pages lands. The phone screen caps itself at 430px, so a category
// holding 54 businesses drew a single-file ribbon down the middle of a
// 1440 window with white on either side of it. Here the same rows fill
// the 1600 column as a 3–4 up grid.
//
// The cards are the directory's cards, deliberately: a category page and
// /businesses are the same listing seen through a different filter, and
// they should look like it.
// ═══════════════════════════════════════════════════════════

const _kBorder = Color(0xFFE7E7E7);
const _kGreyText = Color(0xFF5F5E5A);
const _kHeading = Color(0xFF1C1C1E);
const _kBodyText = Color(0xFF3D3D3D);
const _kIconGrey = Color(0xFF6D6D6D);
const _kPillBorder = Color(0xFFD1D1D1);
const _kKosherBg = Color(0xFFE6F7EE);
const _kKosherText = Color(0xFF12855A);
const _kDeliveryBg = Color(0xFFF0F7FD);

class WebBusinessListContent extends ConsumerStatefulWidget {
  /// The category being listed, or null for the whole directory — the same
  /// two arguments the phone screen takes, and the same provider behind them.
  final String? categoryId;
  final String title;

  const WebBusinessListContent({
    super.key,
    this.categoryId,
    required this.title,
  });

  @override
  ConsumerState<WebBusinessListContent> createState() =>
      _WebBusinessListContentState();
}

class _WebBusinessListContentState
    extends ConsumerState<WebBusinessListContent> {
  bool _isHebrew = false;

  /// -1 = no pill selected.
  int _selectedFilter = -1;

  /// How many cards the grid shows. A category can hold over a hundred rows,
  /// and all of them at once puts the footer out of reach.
  static const _pageSize = 24;
  int _shown = _pageSize;

  String _t(String en, String he) => _isHebrew ? he : en;

  /// Colours behind the cards that carry no photograph. Same sequence the
  /// directory walks, so a business keeps a stable stand-in between the two
  /// pages when its index matches.
  static const _palette = <(Color, Color)>[
    (Color(0xFF1B3A2D), Color(0xFF2E5A47)),
    (Color(0xFF3E2723), Color(0xFF5D4037)),
    (Color(0xFF2D1B4E), Color(0xFF4A2D6E)),
    (Color(0xFF4E1B3A), Color(0xFF6E2D54)),
    (Color(0xFF1A237E), Color(0xFF283593)),
    (Color(0xFF4E342E), Color(0xFF6D4C41)),
    (Color(0xFF263238), Color(0xFF37474F)),
    (Color(0xFF1B5E20), Color(0xFF2E7D32)),
  ];

  /// The only two filters a column can answer. Opening hours live in
  /// `business_hours`, which holds no rows, and `reviews` is empty, so
  /// "Open Now" and "Top Rated" could only ever empty the grid.
  List<String> get _filters => [_t('Kosher', 'כשר'), _t('Delivery', 'משלוחים')];

  bool _matchesFilter(Business b) => switch (_selectedFilter) {
    0 => b.kosherStatus != null,
    1 => b.hasDelivery,
    _ => true,
  };

  List<Business> _visible(List<Business> rows) =>
      rows.where(_matchesFilter).toList();

  /// What the card prints on its category line. The `businesses` table has no
  /// category column — the links live in `entity_categories` — so on a
  /// category page the page's own name is the truest label available, and the
  /// whole-directory page says "Business".
  String get _categoryLabel {
    if (widget.categoryId == null) return _t('Business', 'עסק');
    return widget.title;
  }

  @override
  Widget build(BuildContext context) {
    final provider = businessesByCategoryProvider(widget.categoryId);
    final request = ref.watch(provider);

    return Directionality(
      textDirection: _isHebrew ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            WebNavbar(
              isHebrew: _isHebrew,
              activeId: 'businesses',
              onToggleLanguage: () => setState(() => _isHebrew = !_isHebrew),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeader(request),
                    _buildResults(request, provider),
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
  // HEADER — back, title, live count, filter pills
  // ─────────────────────────────────────────────
  Widget _buildHeader(AsyncValue<List<Business>> request) {
    final count = request.valueOrNull == null
        ? 0
        : _visible(request.value!).length;

    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: WebSection(
        // WebSection centres its column and lets it shrink to its widest
        // child, so a block of nothing but text drifts into the middle of
        // the page. This holds it to the full 1600 so it lines up with the
        // grid below it.
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => context.canPop()
                      ? context.pop()
                      : context.go('/businesses'),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isHebrew
                            ? IconsaxPlusLinear.arrow_right_3
                            : IconsaxPlusLinear.arrow_left,
                        size: 22,
                        color: AppColors.navy,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _t('All Businesses', 'כל העסקים'),
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.title,
                style: TextStyle(
                  fontFamily: AppFonts.nunito,
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                  color: AppColors.midBlue,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              // The count is only true once the rows are in; while the request is
              // in flight it would read "0 businesses found".
              Text(
                switch (request) {
                  AsyncLoading() => _t('Loading…', 'טוען…'),
                  AsyncError() => _t(
                    'These businesses could not be loaded.',
                    'לא ניתן לטעון את העסקים.',
                  ),
                  _ =>
                    count == 1
                        ? _t('1 business found', 'נמצא עסק אחד')
                        : _t('$count businesses found', 'נמצאו $count עסקים'),
                },
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  color: _kGreyText,
                  height: 1.21,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(_filters.length, (i) {
                  return _FilterPill(
                    label: _filters[i],
                    isSelected: _selectedFilter == i,
                    onTap: () => setState(() {
                      _selectedFilter = _selectedFilter == i ? -1 : i;
                      _shown = _pageSize;
                    }),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // RESULTS — the grid, 3 up narrow and 4 up from 1250
  // ─────────────────────────────────────────────
  Widget _buildResults(
    AsyncValue<List<Business>> request,
    ProviderBase<AsyncValue<List<Business>>> provider,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: WebSection(
        child: switch (request) {
          AsyncLoading() => const SizedBox(
            height: 320,
            child: Center(child: CircularProgressIndicator()),
          ),
          AsyncError() => _buildNotice(
            icon: IconsaxPlusLinear.wifi_square,
            title: _t(
              'These businesses could not be loaded',
              'לא ניתן לטעון את העסקים',
            ),
            body: _t(
              'Check your connection and try again.',
              'בדקו את החיבור לאינטרנט ונסו שוב.',
            ),
            actionLabel: _t('Try again', 'נסו שוב'),
            onAction: () => ref.invalidate(provider),
          ),
          _ => _buildGrid(_visible(request.value ?? const [])),
        },
      ),
    );
  }

  Widget _buildGrid(List<Business> rows) {
    if (rows.isEmpty) {
      return _buildNotice(
        icon: IconsaxPlusLinear.shop,
        title: _selectedFilter >= 0
            ? _t(
                'Nothing here matches that filter',
                'אין עסקים שתואמים את הסינון',
              )
            : _t('No businesses to show', 'אין עסקים להצגה'),
        body: _selectedFilter >= 0
            ? _t(
                'Clear the filter to see everything in this category.',
                'נקו את הסינון כדי לראות את כל הקטגוריה.',
              )
            : _t(
                'Businesses will appear here as soon as they are added.',
                'עסקים יופיעו כאן ברגע שיתווספו',
              ),
        actionLabel: _selectedFilter >= 0
            ? _t('Clear filter', 'נקו סינון')
            : null,
        onAction: _selectedFilter >= 0
            ? () => setState(() {
                _selectedFilter = -1;
                _shown = _pageSize;
              })
            : null,
      );
    }

    final visible = rows.take(_shown).toList();

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 20.0;
            // Four across is the directory's grid; below roughly 1300 the
            // fourth card gets narrower than its own contents, so it drops
            // to three.
            final perRow = constraints.maxWidth >= 1250 ? 4 : 3;
            final cardWidth =
                (constraints.maxWidth - gap * (perRow - 1)) / perRow;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: List.generate(visible.length, (i) {
                final b = visible[i];
                return SizedBox(
                  width: cardWidth,
                  height: 372,
                  child: _BusinessCard(
                    business: b,
                    categoryLabel: b.category.isNotEmpty
                        ? b.category
                        : _categoryLabel,
                    imageBg: _palette[i % _palette.length].$1,
                    logoBg: _palette[(i + 3) % _palette.length].$2,
                    reviewsLabel: _t('reviews', 'ביקורות'),
                    // `reviews` holds no rows, so every business here has a
                    // review count of 0 and no score to print.
                    notRatedLabel: _t('Not rated yet', 'אין דירוג עדיין'),
                    kosherLabel: _t('Kosher', 'כשר'),
                    deliveryLabel: _t('Delivery', 'משלוחים'),
                    viewLabel: _t('View Business', 'לעמוד העסק'),
                    onTap: () => context.push('/business/${b.id}'),
                  ),
                );
              }),
            );
          },
        ),
        if (rows.length > _shown) ...[
          const SizedBox(height: 32),
          Center(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => setState(
                  () => _shown = (_shown + _pageSize).clamp(0, rows.length),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.midBlue),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    _t(
                      'Show more (${rows.length - _shown} left)',
                      'הצג עוד (נותרו ${rows.length - _shown})',
                    ),
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.midBlue,
                    ),
                  ),
                ),
              ),
            ),
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
// FILTER PILL
// ─────────────────────────────────────────────
class _FilterPill extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_FilterPill> createState() => _FilterPillState();
}

class _FilterPillState extends State<_FilterPill> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.isSelected;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            color: selected ? AppColors.midBlue : Colors.white,
            border: Border.all(
              color: selected
                  ? AppColors.midBlue
                  : (_hovered ? AppColors.turquoise : _kPillBorder),
            ),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.white : _kBodyText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BUSINESS CARD — the directory's card, 372 tall
// ─────────────────────────────────────────────
class _BusinessCard extends StatefulWidget {
  final Business business;
  final String categoryLabel;
  final Color imageBg, logoBg;
  final String reviewsLabel, notRatedLabel, viewLabel;
  final String kosherLabel, deliveryLabel;
  final VoidCallback onTap;

  const _BusinessCard({
    required this.business,
    required this.categoryLabel,
    required this.imageBg,
    required this.logoBg,
    required this.reviewsLabel,
    required this.notRatedLabel,
    required this.viewLabel,
    required this.kosherLabel,
    required this.deliveryLabel,
    required this.onTap,
  });

  @override
  State<_BusinessCard> createState() => _BusinessCardState();
}

class _BusinessCardState extends State<_BusinessCard> {
  bool _hovered = false;

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppFonts.inter,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.business;
    final kosher = b.kosherLabel;
    // The neighbourhood where the row is filed under one, and the street
    // address otherwise — only 19 of the 219 carry a neighbourhood.
    final area = b.neighborhood.isNotEmpty ? b.neighborhood : b.address;
    final hasRating = b.rating > 0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _hovered ? AppColors.midBlue : _kBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 168,
                child: Stack(
                  // The logo chip hangs 20px below the photo — the Stack's
                  // default hardEdge clip would cut it in half.
                  clipBehavior: Clip.none,
                  children: [
                    _remoteImage(
                      b.imageUrl ?? '',
                      widget.imageBg,
                      width: double.infinity,
                      height: 168,
                      radius: const BorderRadius.vertical(
                        top: Radius.circular(11),
                      ),
                      glyph: 30,
                    ),
                    PositionedDirectional(
                      start: 12,
                      top: 12,
                      child: Row(
                        children: [
                          if (kosher != null)
                            _chip(widget.kosherLabel, _kKosherBg, _kKosherText),
                          if (kosher != null && b.hasDelivery)
                            const SizedBox(width: 6),
                          if (b.hasDelivery)
                            _chip(
                              widget.deliveryLabel,
                              _kDeliveryBg,
                              AppColors.midBlue,
                            ),
                        ],
                      ),
                    ),
                    // No gold star beside a 0.0 — `reviews` is empty, so no
                    // business here has a score yet.
                    if (hasRating)
                      PositionedDirectional(
                        end: 12,
                        top: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                IconsaxPlusBold.star_1,
                                size: 13,
                                color: AppColors.gold,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                b.rating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontFamily: AppFonts.inter,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _kHeading,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    PositionedDirectional(
                      start: 16,
                      bottom: -20,
                      child: Container(
                        width: 56,
                        height: 56,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _remoteImage(
                          b.logoUrl ?? '',
                          widget.logoBg,
                          radius: BorderRadius.circular(9),
                          glyph: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.name,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: _kHeading,
                          height: 1.22,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.categoryLabel,
                              style: TextStyle(
                                fontFamily: AppFonts.inter,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.midBlue,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (area.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            const Text(
                              '•',
                              style: TextStyle(color: _kGreyText, fontSize: 13),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              IconsaxPlusLinear.location,
                              size: 13,
                              color: _kIconGrey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                area,
                                style: TextStyle(
                                  fontFamily: AppFonts.inter,
                                  fontSize: 13,
                                  color: _kGreyText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        b.reviewCount > 0
                            ? '${b.reviewCount} ${widget.reviewsLabel}'
                            : widget.notRatedLabel,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 12,
                          color: _kGreyText,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _hovered
                                    ? AppColors.midBlue
                                    : Colors.white,
                                border: Border.all(color: AppColors.midBlue),
                                borderRadius: BorderRadius.circular(60),
                              ),
                              child: Text(
                                widget.viewLabel,
                                style: TextStyle(
                                  fontFamily: AppFonts.inter,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: _hovered
                                      ? Colors.white
                                      : AppColors.midBlue,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          // 14 of the rows have no phone number, and those
                          // draw no button rather than a dead one.
                          if ((b.phone ?? '').isNotEmpty) ...[
                            const SizedBox(width: 10),
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () => launchUrl(
                                  Uri(scheme: 'tel', path: b.phone),
                                ),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: _kBorder),
                                    borderRadius: BorderRadius.circular(60),
                                  ),
                                  child: const Icon(
                                    IconsaxPlusLinear.call,
                                    size: 18,
                                    color: AppColors.midBlue,
                                  ),
                                ),
                              ),
                            ),
                          ],
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

/// The card's photo, falling back to a gradient stand-in — 90 of the 219
/// businesses have no cover image.
Widget _remoteImage(
  String url,
  Color base, {
  double? width,
  double? height,
  BorderRadius? radius,
  double glyph = 28,
}) {
  final fallback = Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      borderRadius: radius,
      shape: radius == null ? BoxShape.circle : BoxShape.rectangle,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [base, Color.lerp(base, Colors.black, 0.22)!],
      ),
    ),
    child: Center(
      child: Icon(
        IconsaxPlusLinear.image,
        size: glyph,
        color: Colors.white.withValues(alpha: 0.35),
      ),
    ),
  );
  if (url.isEmpty) return fallback;
  return ClipRRect(
    borderRadius: radius ?? BorderRadius.circular(999),
    child: Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      // Rendered by the browser's own <img> element rather than decoded into
      // the CanvasKit surface, which is how these covers load elsewhere.
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      errorBuilder: (_, _, _) => fallback,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : fallback,
    ),
  );
}
