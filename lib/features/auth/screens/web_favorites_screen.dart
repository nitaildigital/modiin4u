import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/error_retry.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../../favorites/providers/favorite_providers.dart';
import '../../favorites/repositories/favorite_repository.dart';
import '../../favorites/widgets/favorite_button.dart';
import '../providers/auth_provider.dart';

// ═══════════════════════════════════════════════════════════
// Web Favourites — desktop saved items
//
// The phone lists one saved thing per row with a 120×100 thumbnail. Twenty
// of those in a 1600px window is a ribbon of white either side, so the same
// entries become cards four across, with the filter chips along the top.
// ═══════════════════════════════════════════════════════════

const _kBorder = Color(0xFFE7E7E7);
const _kGreyText = Color(0xFF5F5E5A);
const _kHeading = Color(0xFF1C1C1E);
const _kIconGrey = Color(0xFF6D6D6D);

const _kCardGap = 20.0;
const _kImageHeight = 180.0;
const _kCardHeight = 372.0;

class WebFavoritesContent extends ConsumerStatefulWidget {
  const WebFavoritesContent({super.key});

  @override
  ConsumerState<WebFavoritesContent> createState() =>
      _WebFavoritesContentState();
}

class _WebFavoritesContentState extends ConsumerState<WebFavoritesContent> {
  bool _isHebrew = false;
  int _activeFilter = 0;

  String _t(String en, String he) => _isHebrew ? he : en;

  /// The same five the phone offers, in the same order.
  List<_FilterDef> get _filters => [
    _FilterDef(_t('All', 'הכל'), IconsaxPlusLinear.element_3, null),
    _FilterDef(
      _t('Businesses', 'עסקים'),
      IconsaxPlusLinear.shop,
      FavoriteKind.business,
    ),
    _FilterDef(
      _t('Events', 'אירועים'),
      IconsaxPlusLinear.calendar_1,
      FavoriteKind.event,
    ),
    _FilterDef(
      _t('News', 'חדשות'),
      IconsaxPlusLinear.document_text,
      FavoriteKind.article,
    ),
    _FilterDef(
      _t('Property', 'נכסים'),
      IconsaxPlusLinear.home_2,
      FavoriteKind.listing,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final signedIn = ref.watch(isLoggedInProvider);
    final entries = ref.watch(favoriteEntriesProvider);

    return Directionality(
      textDirection: _isHebrew ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            WebNavbar(
              isHebrew: _isHebrew,
              activeId: null,
              onToggleLanguage: () => setState(() => _isHebrew = !_isHebrew),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 56),
                    WebSection(child: _buildBody(signedIn, entries)),
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

  Widget _buildBody(bool signedIn, AsyncValue<List<FavoriteEntry>> entries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t('Favorites', 'מועדפים'),
          style: TextStyle(
            fontFamily: AppFonts.nunito,
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: _kHeading,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _t(
            'The places, events and articles you saved.',
            'המקומות, האירועים והכתבות ששמרתם.',
          ),
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 14,
            color: _kGreyText,
          ),
        ),
        const SizedBox(height: 28),
        // Signed out there is nothing to filter, so the chips stay out of the
        // way of the one thing there is to say.
        if (signedIn) ...[_buildFilterChips(), const SizedBox(height: 28)],
        if (!signedIn)
          _buildSignedOutState()
        else
          entries.when(
            loading: _buildSkeletonGrid,
            error: (_, _) => SizedBox(
              height: 320,
              child: ErrorRetry(
                onRetry: () => ref.invalidate(favoriteEntriesProvider),
              ),
            ),
            data: (all) {
              final kind = _filters[_activeFilter].kind;
              final items = kind == null
                  ? all
                  : all.where((e) => e.kind == kind).toList();
              if (items.isEmpty) return _buildEmptyState();
              return _buildGrid(items);
            },
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // FILTER CHIPS — across the top
  // ─────────────────────────────────────────────
  Widget _buildFilterChips() {
    final filters = _filters;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(filters.length, (i) {
        final f = filters[i];
        final active = i == _activeFilter;
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => setState(() => _activeFilter = i),
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: active ? const Color(0xFFEEF4FD) : Colors.white,
                border: Border.all(
                  color: active
                      ? AppColors.midBlue.withValues(alpha: 0.8)
                      : _kBorder,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    f.icon,
                    size: 16,
                    color: active ? AppColors.midBlue : _kIconGrey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    f.label,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      color: active ? AppColors.midBlue : _kIconGrey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  // ─────────────────────────────────────────────
  // GRID
  // ─────────────────────────────────────────────
  /// Four across on a 1440 laptop as well as at 1920, three just above the
  /// breakpoint, which keeps a card between roughly 330 and 390 wide at every
  /// window the page is drawn in.
  int _perRow(double width) => width >= 1240 ? 4 : 3;

  Widget _buildGrid(List<FavoriteEntry> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final perRow = _perRow(constraints.maxWidth);
        final cardWidth =
            (constraints.maxWidth - _kCardGap * (perRow - 1)) / perRow;
        return Wrap(
          spacing: _kCardGap,
          runSpacing: _kCardGap,
          children: items
              .map(
                (entry) => SizedBox(
                  width: cardWidth,
                  height: _kCardHeight,
                  child: _FavoriteCard(entry: entry, isHebrew: _isHebrew),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildSkeletonGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final perRow = _perRow(constraints.maxWidth);
        final cardWidth =
            (constraints.maxWidth - _kCardGap * (perRow - 1)) / perRow;
        return Skeleton(
          child: Wrap(
            spacing: _kCardGap,
            runSpacing: _kCardGap,
            children: List.generate(
              perRow * 2,
              (_) => SizedBox(
                width: cardWidth,
                height: _kCardHeight,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: _kBorder),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(
                        width: double.infinity,
                        height: _kImageHeight,
                        radius: 12,
                      ),
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonLine(width: 200, fontSize: 16),
                            SizedBox(height: 14),
                            SkeletonLine(width: 150, fontSize: 13),
                            SizedBox(height: 14),
                            SkeletonLine(width: 110, fontSize: 13),
                            SizedBox(height: 18),
                            SkeletonBox(width: 64, height: 20, radius: 4),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // EMPTY STATES
  // ─────────────────────────────────────────────
  Widget _buildStateBox({
    required String title,
    required String blurb,
    Widget? action,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 72),
      decoration: BoxDecoration(
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              IconsaxPlusLinear.heart,
              size: 32,
              color: _kIconGrey,
            ),
          ),
          const SizedBox(height: 20),
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
            blurb,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              color: _kGreyText,
            ),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[const SizedBox(height: 24), action],
        ],
      ),
    );
  }

  /// Signed out there is nothing to show and nothing to fetch, so the page
  /// says what to do rather than looking like an account with nothing saved.
  Widget _buildSignedOutState() {
    return _buildStateBox(
      title: _t(
        'Sign in to see your favourites',
        'התחברו כדי לראות את המועדפים',
      ),
      blurb: _t(
        'Saved places and articles follow your account.',
        'המקומות והכתבות ששמרתם נשמרים בחשבון שלכם.',
      ),
      action: SizedBox(
        height: 48,
        child: ElevatedButton(
          onPressed: () => context.push('/login'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.midBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 36),
          ),
          child: Text(
            _t('Sign In', 'התחברות'),
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return _buildStateBox(
      title: _t('Nothing saved yet', 'עוד לא שמרתם כלום'),
      blurb: _t(
        'Tap the heart on anything you want to find again.',
        'לחצו על הלב בכל דבר שתרצו למצוא שוב.',
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// DATA MODEL
// ═══════════════════════════════════════════════

class _FilterDef {
  final String label;
  final IconData icon;

  /// Null on "All".
  final FavoriteKind? kind;

  const _FilterDef(this.label, this.icon, this.kind);
}

// ═══════════════════════════════════════════════
// CARD — photo on top, details under it
// ═══════════════════════════════════════════════

class _FavoriteCard extends StatefulWidget {
  final FavoriteEntry entry;
  final bool isHebrew;
  const _FavoriteCard({required this.entry, required this.isHebrew});

  @override
  State<_FavoriteCard> createState() => _FavoriteCardState();
}

class _FavoriteCardState extends State<_FavoriteCard> {
  bool _hovered = false;

  static const _monthsEn = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const _monthsHe = [
    'ינו',
    'פבר',
    'מרץ',
    'אפר',
    'מאי',
    'יונ',
    'יול',
    'אוג',
    'ספט',
    'אוק',
    'נוב',
    'דצמ',
  ];

  String _t(String en, String he) => widget.isHebrew ? he : en;

  String _typeName() => switch (widget.entry.kind) {
    FavoriteKind.business => _t('Business', 'עסק'),
    FavoriteKind.event => _t('Event', 'אירוע'),
    FavoriteKind.article => _t('News', 'חדשות'),
    FavoriteKind.listing => _t('Property', 'נכס'),
  };

  Color get _typeColor => switch (widget.entry.kind) {
    FavoriteKind.business => const Color(0xFF31AC4E),
    FavoriteKind.event => const Color(0xFF7247ED),
    FavoriteKind.article => const Color(0xFF1E40B5),
    FavoriteKind.listing => const Color(0xFFD47D00),
  };

  IconData get _fallbackIcon => switch (widget.entry.kind) {
    FavoriteKind.business => IconsaxPlusBold.shop,
    FavoriteKind.event => IconsaxPlusBold.calendar_1,
    FavoriteKind.article => IconsaxPlusBold.document_text,
    FavoriteKind.listing => IconsaxPlusBold.home_2,
  };

  String _formatDate(DateTime date) {
    final month = (widget.isHebrew ? _monthsHe : _monthsEn)[date.month - 1];
    return widget.isHebrew
        ? '${date.day} ב$month ${date.year}'
        : '${date.day} $month ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final date = entry.date;
    final rating = entry.rating;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.push(entry.route),
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
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(11),
                    ),
                    child: NetworkPhoto(
                      url: entry.imageUrl,
                      width: double.infinity,
                      height: _kImageHeight,
                      icon: _fallbackIcon,
                      iconSize: 36,
                    ),
                  ),
                  // Clicking it here removes the card from this very grid.
                  PositionedDirectional(
                    top: 12,
                    end: 12,
                    child: FavoriteButton(
                      kind: entry.kind,
                      id: entry.id,
                      size: 36,
                      iconSize: 20,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navy,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (entry.subtitle != null)
                        _detailRow(IconsaxPlusLinear.location, entry.subtitle!),
                      if (date != null)
                        _detailRow(
                          IconsaxPlusLinear.calendar_1,
                          _formatDate(date),
                        ),
                      // Hidden at zero rather than shown as 0.0, since no
                      // review has been written yet.
                      if (rating != null && rating > 0) _buildRating(entry),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _typeColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _typeName(),
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
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

  Widget _detailRow(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: _kIconGrey),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 13,
                color: _kGreyText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRating(FavoriteEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(
            IconsaxPlusBold.star_1,
            size: 15,
            color: Color(0xFFFFC107),
          ),
          const SizedBox(width: 6),
          Text(
            entry.rating!.toStringAsFixed(1),
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '(${entry.reviewCount ?? 0})',
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 13,
              color: _kGreyText,
            ),
          ),
        ],
      ),
    );
  }
}
