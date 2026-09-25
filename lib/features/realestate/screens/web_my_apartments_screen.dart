import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../models/listing.dart';
import '../providers/listing_providers.dart';
import 'my_apartments_screen.dart' show formatShekels;

// ═══════════════════════════════════════════════════════════
// Web My Apartments — desktop layout for /my-apartments
//
// The mobile screen is one column of 430px cards with the "Add Apartment"
// button pinned to the bottom of the viewport. On a laptop the same rows
// become a three-up grid and the button moves beside the page heading, where
// it is visible without scrolling to the end of the list.
//
// `listings` has no rows, and `myListingsProvider` returns an empty list for
// anyone signed out, so the page most people see today is the empty state.
// That is the correct outcome and it is not filled with sample cards.
// ═══════════════════════════════════════════════════════════

const _kBorder = Color(0xFFE7E7E7);
const _kGreyText = Color(0xFF5F5E5A);
const _kIconGrey = Color(0xFF6D6D6D);

class WebMyApartmentsContent extends ConsumerStatefulWidget {
  const WebMyApartmentsContent({super.key});

  @override
  ConsumerState<WebMyApartmentsContent> createState() =>
      _WebMyApartmentsContentState();
}

class _WebMyApartmentsContentState
    extends ConsumerState<WebMyApartmentsContent> {
  bool _isHebrew = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _t(String en, String he) => _isHebrew ? he : en;

  /// The same in-memory filter the mobile screen uses: this is one person's
  /// own listings, so the list is short and a query per keystroke would cost
  /// more than it saved.
  List<Listing> _filter(List<Listing> all) {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where(
          (l) =>
              l.title.toLowerCase().contains(q) ||
              (l.address ?? '').toLowerCase().contains(q) ||
              (l.neighborhoodName ?? '').toLowerCase().contains(q),
        )
        .toList();
  }

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
    'ינו׳',
    'פבר׳',
    'מרץ',
    'אפר׳',
    'מאי',
    'יונ׳',
    'יול׳',
    'אוג׳',
    'ספט׳',
    'אוק׳',
    'נוב׳',
    'דצמ׳',
  ];

  String _submittedOn(DateTime d) {
    final month = (_isHebrew ? _monthsHe : _monthsEn)[d.month - 1];
    return _isHebrew
        ? 'נשלח ב-${d.day} $month ${d.year}'
        : 'Submitted on ${d.day} $month ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final mine = ref.watch(myListingsProvider);

    return Directionality(
      textDirection: _isHebrew ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            WebNavbar(
              isHebrew: _isHebrew,
              activeId: 'realestate',
              onToggleLanguage: () => setState(() => _isHebrew = !_isHebrew),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 48),
                    _buildHeader(),
                    const SizedBox(height: 32),
                    mine.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 120),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, _) => _buildNotice(
                        icon: IconsaxPlusLinear.wifi_square,
                        title: _t(
                          'Your listings could not be loaded',
                          'לא ניתן לטעון את המודעות שלכם',
                        ),
                        body: _t(
                          'Check your connection and try again.',
                          'בדקו את החיבור לאינטרנט ונסו שוב.',
                        ),
                        actionLabel: _t('Try again', 'נסו שוב'),
                        onAction: () => ref.invalidate(myListingsProvider),
                      ),
                      data: _buildListings,
                    ),
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
  // HEADING — title, count, and the Add Apartment button
  // ─────────────────────────────────────────────
  Widget _buildHeader() {
    final all = ref.watch(myListingsProvider).valueOrNull;

    return WebSection(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('My Apartments', 'הדירות שלי'),
                  style: TextStyle(
                    fontFamily: AppFonts.nunito,
                    fontSize: 40,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  all == null || all.isEmpty
                      ? _t(
                          'Everything you have posted, and where it stands.',
                          'כל מה שפרסמתם, והסטטוס של כל מודעה.',
                        )
                      : (all.length == 1
                            ? _t('1 listing', 'מודעה אחת')
                            : _t(
                                '${all.length} listings',
                                '${all.length} מודעות',
                              )),
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 16,
                    color: _kIconGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 32),
          _addApartmentButton(),
        ],
      ),
    );
  }

  Widget _addApartmentButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.push('/add-apartment'),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            color: AppColors.midBlue,
            borderRadius: BorderRadius.circular(60),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(IconsaxPlusLinear.add, size: 20, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                _t('Add Apartment', 'הוספת דירה'),
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // THE LISTINGS — search, then a three-up grid
  // ─────────────────────────────────────────────
  Widget _buildListings(List<Listing> all) {
    if (all.isEmpty) return _buildEmptyState();
    final listings = _filter(all);

    return WebSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: _buildSearchField(),
          ),
          const SizedBox(height: 28),
          if (listings.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 72),
              decoration: BoxDecoration(
                border: Border.all(color: _kBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  _t(
                    'No apartments match your search',
                    'לא נמצאו דירות מתאימות',
                  ),
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 16,
                    color: _kGreyText,
                  ),
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                // Three across at 1600, and still three on a 1440 laptop,
                // where the content column is about 1390 wide.
                const gap = 24.0;
                final perRow = constraints.maxWidth > 1040 ? 3 : 2;
                final cardWidth =
                    (constraints.maxWidth - gap * (perRow - 1)) / perRow;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: listings
                      .map(
                        (l) => SizedBox(
                          width: cardWidth,
                          child: _ListingCard(
                            listing: l,
                            statusLabel: _statusLabel(l.status),
                            priceLabel: _priceLabel(l),
                            submittedLabel: _submittedOn(l.createdAt),
                            noPriceLabel: _t(
                              'Price on request',
                              'מחיר לפי בקשה',
                            ),
                            onTap: () => context.push('/listing/${l.id}'),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: [
          const Icon(
            IconsaxPlusLinear.search_normal_1,
            size: 18,
            color: _kIconGrey,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 15,
                color: const Color(0xFF1F1F1F),
              ),
              decoration: InputDecoration(
                hintText: _t('Search apartments', 'חיפוש דירות'),
                hintStyle: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 15,
                  color: _kIconGrey,
                ),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _searchController.clear,
                child: const Icon(
                  IconsaxPlusLinear.close_circle,
                  size: 18,
                  color: _kIconGrey,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Only three of the seven statuses can appear on a listing someone posted;
  /// anything else reads as still being looked at rather than being given a
  /// colour that would claim something untrue.
  ({String text, Color fg, Color bg}) _statusLabel(ListingStatus status) =>
      switch (status) {
        ListingStatus.active => (
          text: _t('Approved', 'מאושר'),
          fg: const Color(0xFF0E7E4B),
          bg: const Color(0xFFE3F6EB),
        ),
        ListingStatus.removed || ListingStatus.expired => (
          text: _t('Rejected', 'נדחה'),
          fg: const Color(0xFFCB3E3C),
          bg: const Color(0xFFFCE9E9),
        ),
        _ => (
          text: _t('Pending', 'ממתין לאישור'),
          fg: const Color(0xFFDC7600),
          bg: const Color(0xFFFFF9EF),
        ),
      };

  String? _priceLabel(Listing l) {
    final price = l.effectivePrice;
    if (price == null) return null;
    return l.kind == ListingKind.rent
        ? _t('${formatShekels(price)} / month', '${formatShekels(price)} לחודש')
        : formatShekels(price);
  }

  // ─────────────────────────────────────────────
  // EMPTY STATE — the mobile one, at desktop scale
  // ─────────────────────────────────────────────
  Widget _buildEmptyState() {
    return WebSection(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
        decoration: BoxDecoration(
          border: Border.all(color: _kBorder),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              width: 205,
              height: 153,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(
                  IconsaxPlusLinear.building_3,
                  size: 64,
                  color: _kIconGrey,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              _t('No apartments listed yet', 'עדיין אין דירות'),
              style: TextStyle(
                fontFamily: AppFonts.nunito,
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F1F1F),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _t(
                'Add your first apartment to get started.',
                'הוסיפו את הדירה הראשונה שלכם כדי להתחיל.',
              ),
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 16,
                color: _kGreyText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _addApartmentButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildNotice({
    required IconData icon,
    required String title,
    required String body,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return WebSection(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 24),
        decoration: BoxDecoration(
          border: Border.all(color: _kBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 44, color: _kIconGrey.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontFamily: AppFonts.nunito,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
              textAlign: TextAlign.center,
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
            const SizedBox(height: 24),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onAction,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.midBlue,
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Text(
                    actionLabel,
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
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// ONE LISTING — photograph, status, price, date
// ═══════════════════════════════════════════════

class _ListingCard extends StatefulWidget {
  final Listing listing;
  final ({String text, Color fg, Color bg}) statusLabel;

  /// Null when the listing carries no price, which reads as "on request"
  /// rather than as a zero.
  final String? priceLabel;
  final String noPriceLabel;
  final String submittedLabel;
  final VoidCallback onTap;

  const _ListingCard({
    required this.listing,
    required this.statusLabel,
    required this.priceLabel,
    required this.noPriceLabel,
    required this.submittedLabel,
    required this.onTap,
  });

  @override
  State<_ListingCard> createState() => _ListingCardState();
}

class _ListingCardState extends State<_ListingCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final l = widget.listing;
    final where = l.address ?? l.neighborhoodName;
    final status = widget.statusLabel;

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
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(11),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      NetworkPhoto(
                        url: l.coverUrl,
                        icon: IconsaxPlusBold.building_3,
                        iconSize: 48,
                      ),
                      PositionedDirectional(
                        start: 12,
                        top: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: status.bg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            status.text,
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: status.fg,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Two lines' worth of room whether the title needs them or
                    // not, so every card in a row ends at the same height.
                    SizedBox(
                      height: 52,
                      child: Text(
                        l.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navy,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 22,
                      child: where == null
                          ? null
                          : Row(
                              children: [
                                const Icon(
                                  IconsaxPlusLinear.location,
                                  size: 16,
                                  color: _kIconGrey,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    where,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: AppFonts.inter,
                                      fontSize: 14,
                                      color: _kGreyText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.priceLabel ?? widget.noPriceLabel,
                      style: TextStyle(
                        fontFamily: AppFonts.nunito,
                        fontSize: widget.priceLabel == null ? 16 : 22,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.submittedLabel,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 13,
                        color: _kIconGrey,
                      ),
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
