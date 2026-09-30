import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../models/business.dart';
import '../providers/business_providers.dart';
import 'web_businesses_screen.dart' show WebBusinessGrid;

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
const _kPillBorder = Color(0xFFD1D1D1);

class WebBusinessListContent extends ConsumerStatefulWidget {
  /// The category being listed, or null for the whole directory — the same
  /// two arguments the phone screen takes, and the same provider behind them.
  final String? categoryId;
  final String title;

  /// The city's parks (the Municipal page's Parks tile) instead of a
  /// category. The Kosher and Delivery pills are left out for them.
  final bool parks;

  const WebBusinessListContent({
    super.key,
    this.categoryId,
    required this.title,
    this.parks = false,
  });

  @override
  ConsumerState<WebBusinessListContent> createState() =>
      _WebBusinessListContentState();
}

class _WebBusinessListContentState extends ConsumerState<WebBusinessListContent>
    with WebLanguageState<WebBusinessListContent> {
  bool get _isHebrew => webIsHebrew.value;

  /// -1 = no pill selected.
  int _selectedFilter = -1;

  /// How many cards the grid shows. A category can hold over a hundred rows,
  /// and all of them at once puts the footer out of reach.
  static const _pageSize = 24;
  int _shown = _pageSize;

  String _t(String en, String he) => _isHebrew ? he : en;

  /// The only two filters a column can answer. Opening hours live in
  /// `business_hours`, which holds no rows, and `reviews` is empty, so
  /// "Open Now" and "Top Rated" could only ever empty the grid.
  List<String> get _filters => widget.parks
      ? const []
      : [_t('Kosher', 'כשר'), _t('Delivery', 'משלוחים')];

  bool _matchesFilter(Business b) => switch (_selectedFilter) {
    0 => b.kosherStatus != null,
    1 => b.hasDelivery,
    _ => true,
  };

  List<Business> _visible(List<Business> rows) =>
      rows.where(_matchesFilter).toList();

  @override
  Widget build(BuildContext context) {
    final ProviderBase<AsyncValue<List<Business>>> provider = widget.parks
        ? parksProvider
        : businessesByCategoryProvider(widget.categoryId);
    final request = ref.watch(provider);

    return Directionality(
      textDirection: _isHebrew ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            WebNavbar(
              isHebrew: _isHebrew,
              activeId: widget.parks
                  ? null
                  : widget.categoryId == 'services'
                  ? 'professionals'
                  : 'businesses',
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
                      : context.go(widget.parks ? '/municipal' : '/businesses'),
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
                        widget.parks
                            ? _t('Municipal Services', 'שירותי עירייה')
                            : _t('All Businesses', 'כל העסקים'),
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
              // The Restaurants frame's section heading: 28 on a 34 line,
              // 10, then the line under it.
              // A category's name is the table's, Hebrew only; the whole
              // directory's heading is the site's own words, in its language.
              Text(
                widget.parks
                    ? _t('Parks in Modiin', 'פארקים במודיעין')
                    : widget.categoryId == null
                    ? _t('All Businesses', 'כל העסקים')
                    // The site's Professionals are the Services category.
                    : widget.categoryId == 'services'
                        ? _t('Professionals', 'בעלי מקצוע')
                        : widget.title,
                style: TextStyle(
                  fontFamily: AppFonts.nunito,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: AppColors.midBlue,
                  height: 34 / 28,
                ),
              ),
              const SizedBox(height: 10),
              // The count is only true once the rows are in; while the request is
              // in flight it would read "0 businesses found".
              Text(
                switch (request) {
                  AsyncLoading() => _t('Loading…', 'טוען…'),
                  AsyncError() => _t(
                    'These businesses could not be loaded.',
                    'לא ניתן לטעון את העסקים.',
                  ),
                  _ when widget.parks =>
                    count == 1
                        ? _t('1 park', 'פארק אחד')
                        : _t('$count parks', '$count פארקים'),
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
        icon: widget.parks ? IconsaxPlusLinear.tree : IconsaxPlusLinear.shop,
        title: _selectedFilter >= 0
            ? _t(
                'Nothing here matches that filter',
                'אין עסקים שתואמים את הסינון',
              )
            : widget.parks
            ? _t('No parks listed yet', 'עדיין לא נוספו פארקים')
            : _t('No businesses to show', 'אין עסקים להצגה'),
        body: _selectedFilter >= 0
            ? _t(
                'Clear the filter to see everything in this category.',
                'נקו את הסינון כדי לראות את כל הקטגוריה.',
              )
            : widget.parks
            ? _t(
                'Parks will appear here as soon as they are added.',
                'פארקים יופיעו כאן ברגע שיתווספו',
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
        // The design's business card, as the directory and the home page
        // draw it, so a business looks the same wherever it is listed.
        WebBusinessGrid(businesses: visible, isHebrew: _isHebrew),
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

