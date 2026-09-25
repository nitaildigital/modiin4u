import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../../favorites/repositories/favorite_repository.dart';
import '../../favorites/widgets/favorite_button.dart';
import '../models/listing.dart';
import '../providers/listing_providers.dart';
import 'my_apartments_screen.dart' show formatShekels;

// ═══════════════════════════════════════════════════════════
// Web Real Estate — desktop layout for /realestate
//
// Eight flats were written into this file — ₪3,650,000 at 3 Yona Hanavi
// Street, ₪7,500 a month on Weizmann Street — with a "New" badge on most of
// them, a heart that was a drawing, and cards that could not be tapped. Six
// property types each claimed a count (32, 24, 20, 15, 13, 8 properties) and
// selecting one filtered nothing. Six neighbourhoods were listed that are not
// rows in `neighborhoods` at all — HaNahalim, Keremim, The Prophets — each
// subtitled "Neighborhood, Modiin" and none of them a link. Both "View all
// properties" buttons had an empty handler.
// ═══════════════════════════════════════════════════════════

/// Every active listing, in one query.
///
/// This page shows a row for sale and a row to let, counts each property type
/// and counts each neighbourhood, so a single fetch answers all four.
/// [listingsProvider] is keyed to the browse filter the mobile tab drives,
/// which is not this page's filter.
final _allActiveListingsProvider = FutureProvider<List<Listing>>(
  (ref) => ref.watch(listingRepositoryProvider).fetchActive(),
);

class WebRealEstateContent extends ConsumerStatefulWidget {
  const WebRealEstateContent({super.key});

  @override
  ConsumerState<WebRealEstateContent> createState() =>
      _WebRealEstateContentState();
}

class _WebRealEstateContentState extends ConsumerState<WebRealEstateContent> {
  /// Which property type the cards above have narrowed both rows to, or null
  /// for all of them. It used to be an index that changed a border colour and
  /// nothing else.
  PropertyType? _selectedType;

  /// Which kind the neighbourhood counts are for. It used to change nothing.
  ListingKind _neighborhoodKind = ListingKind.rent;

  ListingKind _searchKind = ListingKind.sale;
  bool _isHebrew = false;
  final _locationController = TextEditingController();
  final _locationFocus = FocusNode();

  @override
  void dispose() {
    _locationController.dispose();
    _locationFocus.dispose();
    super.dispose();
  }

  String _t(String en, String he) => _isHebrew ? he : en;

  String _typeLabel(PropertyType t) => switch (t) {
    PropertyType.apartment => _t('Apartment', 'דירה'),
    PropertyType.penthouse => _t('Penthouse', 'פנטהאוז'),
    PropertyType.garden => _t('Garden Apartment', 'דירת גן'),
    PropertyType.duplex => _t('Duplex', 'דופלקס'),
    PropertyType.villa => _t('Villa', 'וילה'),
    PropertyType.studio => _t('Studio', 'סטודיו'),
    PropertyType.other => _t('Other', 'אחר'),
  };

  /// The six types the browse row offers, with the icon each card carries.
  /// `other` is left out: it is what the model falls back to, not something a
  /// reader would pick.
  static const _browseTypes = [
    (PropertyType.apartment, IconsaxPlusBold.building_4),
    (PropertyType.penthouse, IconsaxPlusBold.building_3),
    (PropertyType.garden, IconsaxPlusBold.house),
    (PropertyType.duplex, IconsaxPlusBold.building),
    (PropertyType.villa, IconsaxPlusBold.house_2),
    (PropertyType.studio, IconsaxPlusBold.lamp),
  ];

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
              activeId: 'realestate',
              onToggleLanguage: () => setState(() => _isHebrew = !_isHebrew),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeroSection(),
                    _buildBrowseTypes(),
                    _buildListingsSection(ListingKind.sale),
                    _buildListingsSection(ListingKind.rent),
                    _buildWhatWeProvide(),
                    _buildNeighborhoods(),
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
  // HERO — gradient panel with the search bar
  // ─────────────────────────────────────────────
  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      height: 662,
      color: Colors.white,
      child: Stack(
        children: [
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1200),
              margin: const EdgeInsets.only(top: 48),
              height: 551,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF80B2DF),
                    Color(0xFF4A8BC4),
                    Color(0xFF2D6A9F),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 428,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF80B2DF).withValues(alpha: 0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 112),
                        Text(
                          _t(
                            'Find Your Perfect Home in Modiin',
                            'מצאו את הבית המושלם במודיעין',
                          ),
                          style: TextStyle(
                            fontFamily: AppFonts.nunito,
                            fontSize: 44,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _t(
                            'Discover apartments and homes available for sale and rent.',
                            'גלו דירות ובתים למכירה ולהשכרה.',
                          ),
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),
                        _buildSearchBar(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onSearch() {
    final query = _locationController.text.trim();
    final path = _searchKind == ListingKind.sale
        ? '/apartments-sale'
        : '/apartments-rent';
    context.push(
      Uri(
        path: path,
        queryParameters: query.isEmpty ? null : {'q': query},
      ).toString(),
    );
  }

  Widget _buildSearchBar() {
    final searchModes = [_t('Buy', 'לקנות'), _t('Rent', 'לשכור')];

    return Container(
      constraints: const BoxConstraints(maxWidth: 848),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        children: [
          _SearchDropdown(
            label: _t("I'm looking to", 'אני מחפש'),
            value: searchModes[_searchKind == ListingKind.sale ? 0 : 1],
            items: searchModes,
            onChanged: (idx) => setState(
              () =>
                  _searchKind = idx == 0 ? ListingKind.sale : ListingKind.rent,
            ),
          ),
          const SizedBox(width: 47),
          Container(width: 1, height: 36, color: const Color(0xFFE0E0E0)),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _t('Location / Neighborhood', 'מיקום / שכונה'),
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 14,
                    color: const Color(0xFF5F5E5A),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _locationController,
                  focusNode: _locationFocus,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: _t(
                      'Enter an address, neighborhood or area.',
                      'הזינו כתובת, שכונה או אזור.',
                    ),
                    hintStyle: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 16,
                      color: const Color(0xFF4F4F4F),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                    isCollapsed: true,
                  ),
                  onSubmitted: (_) => _onSearch(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _onSearch,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: AppColors.midBlue,
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      IconsaxPlusLinear.search_normal_1,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _t('Search', 'חיפוש'),
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
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BROWSE BY TYPE
  // ─────────────────────────────────────────────
  /// The six property types, each with the number of listings filed under it.
  ///
  /// The counts were fixed — 32 apartments, 24 penthouses, 8 studios — and
  /// tapping a card only moved a border. A type with nothing under it says so
  /// rather than showing a nought that reads as a figure, and stays tappable
  /// because it is a filter, not a claim.
  Widget _buildBrowseTypes() {
    final listings =
        ref.watch(_allActiveListingsProvider).valueOrNull ?? const <Listing>[];
    final counts = <PropertyType, int>{};
    for (final l in listings) {
      counts[l.propertyType] = (counts[l.propertyType] ?? 0) + 1;
    }

    return _Section(
      maxWidth: 1200,
      child: Column(
        children: [
          const SizedBox(height: 48),
          Text(
            _t('Browse Real Estate', 'חפשו נדל"ן'),
            style: TextStyle(
              fontFamily: AppFonts.nunito,
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppColors.midBlue,
            ),
          ),
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth > 900 ? 6 : 3;
              const gap = 16.0;
              final cardWidth =
                  (constraints.maxWidth - (cols - 1) * gap) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                alignment: WrapAlignment.center,
                children: [
                  for (final (type, icon) in _browseTypes)
                    _TypeCard(
                      width: cardWidth,
                      icon: icon,
                      label: _typeLabel(type),
                      count: counts[type] ?? 0,
                      noneLabel: _t('None listed yet', 'אין נכסים כרגע'),
                      countLabel: (n) => _t('$n Properties', '$n נכסים'),
                      selected: _selectedType == type,
                      onTap: () => setState(
                        () =>
                            _selectedType = _selectedType == type ? null : type,
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // LISTINGS — one row for sale, one to let
  // ─────────────────────────────────────────────
  Widget _buildListingsSection(ListingKind kind) {
    final isRent = kind == ListingKind.rent;
    final async = ref.watch(_allActiveListingsProvider);

    return _Section(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isRent
                          ? _t(
                              'Apartments for Rent in Modiin',
                              'דירות להשכרה במודיעין',
                            )
                          : _t(
                              'Apartments for Sale in Modiin',
                              'דירות למכירה במודיעין',
                            ),
                      style: TextStyle(
                        fontFamily: AppFonts.nunito,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: AppColors.midBlue,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isRent
                          ? _t(
                              'Discover apartments and homes available for rent in the best neighborhoods across Modiin.',
                              'גלו דירות ובתים להשכרה בשכונות הטובות ביותר ברחבי מודיעין.',
                            )
                          : _t(
                              'Explore the latest apartments and homes available for sale across Modiin.',
                              'גלו את הדירות והבתים העדכניים ביותר למכירה ברחבי מודיעין.',
                            ),
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 14,
                        color: const Color(0xFF5F5E5A),
                      ),
                    ),
                  ],
                ),
              ),
              // It had `onTap: () {}`.
              _ViewAllButton(
                label: _t('View all properties', 'ראה את כל הנכסים'),
                onTap: () => context.push(
                  isRent ? '/apartments-rent' : '/apartments-sale',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          async.when(
            loading: () => const SizedBox(
              height: 380,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => _buildNotice(
              icon: IconsaxPlusLinear.wifi_square,
              title: _t(
                'Properties could not be loaded',
                'לא ניתן לטעון את הנכסים',
              ),
              body: _t(
                'Check your connection and try again.',
                'בדקו את החיבור לאינטרנט ונסו שוב.',
              ),
              actionLabel: _t('Try again', 'נסו שוב'),
              onAction: () => ref.invalidate(_allActiveListingsProvider),
            ),
            data: (all) {
              final listings = all
                  .where((l) => l.kind == kind)
                  .where(
                    (l) =>
                        _selectedType == null ||
                        l.propertyType == _selectedType,
                  )
                  .toList();

              if (listings.isEmpty) {
                return _buildNotice(
                  icon: IconsaxPlusLinear.home_2,
                  title: _selectedType != null
                      ? _t(
                          'No ${_typeLabel(_selectedType!)} listed here yet',
                          'אין כרגע ${_typeLabel(_selectedType!)} בקטגוריה הזו',
                        )
                      : isRent
                      ? _t('Nothing to let yet', 'אין כרגע דירות להשכרה')
                      : _t('Nothing for sale yet', 'אין כרגע דירות למכירה'),
                  body: _selectedType != null
                      ? _t(
                          'Clear the property type above to see everything on file.',
                          'הסירו את סוג הנכס שנבחר למעלה כדי לראות את הכל.',
                        )
                      : _t(
                          'Properties will appear here as they are published.',
                          'נכסים יופיעו כאן עם פרסומם.',
                        ),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final cols = constraints.maxWidth > 1200
                      ? 4
                      : (constraints.maxWidth > 800 ? 2 : 1);
                  const gap = 22.0;
                  final cardWidth =
                      (constraints.maxWidth - (cols - 1) * gap) / cols;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final l in listings.take(cols * 2))
                        SizedBox(
                          width: cardWidth,
                          child: _ListingCard(listing: l, isHebrew: _isHebrew),
                        ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 56),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // WHAT WE ARE PROVIDING
  // ─────────────────────────────────────────────
  /// Three cards that read as calls to action and had no handler at all. Each
  /// now opens the page it names.
  Widget _buildWhatWeProvide() {
    return _Section(
      child: Column(
        children: [
          Text(
            _t('What We Are Providing', 'מה אנחנו מציעים'),
            style: TextStyle(
              fontFamily: AppFonts.nunito,
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppColors.midBlue,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth > 900 ? 3 : 1;
              const gap = 21.0;
              final cardWidth =
                  (constraints.maxWidth - (cols - 1) * gap) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  _ServiceCard(
                    width: cardWidth,
                    icon: IconsaxPlusBold.house,
                    title: _t('Find Your Next Rental', 'מצאו את השכירות הבאה'),
                    subtitle: _t(
                      'Browse apartments and homes available for rent across Modiin.',
                      'חפשו דירות ובתים להשכרה ברחבי מודיעין.',
                    ),
                    isHighlighted: true,
                    onTap: () => context.push('/apartments-rent'),
                  ),
                  _ServiceCard(
                    width: cardWidth,
                    icon: IconsaxPlusLinear.document_upload,
                    title: _t('Sell a Property', 'מכרו נכס'),
                    subtitle: _t(
                      'List your property and connect with people looking to buy in Modiin.',
                      'פרסמו את הנכס שלכם והתחברו עם אנשים שמחפשים לקנות במודיעין.',
                    ),
                    onTap: () => context.push('/add-apartment'),
                  ),
                  _ServiceCard(
                    width: cardWidth,
                    icon: IconsaxPlusLinear.chart_2,
                    title: _t('Buy a Property', 'קנו נכס'),
                    subtitle: _t(
                      'Explore apartments and homes for sale in Modiin. Compare properties, neighborhoods, prices.',
                      'גלו דירות ובתים למכירה במודיעין. השוו נכסים, שכונות, מחירים.',
                    ),
                    onTap: () => context.push('/apartments-sale'),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 56),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // APARTMENTS BY NEIGHBOURHOOD
  // ─────────────────────────────────────────────
  /// The city's neighbourhoods, from `neighborhoods`.
  ///
  /// Six were written in that are not rows in that table at all, each one
  /// subtitled "Neighborhood, Modiin" and located in "Modiin, Israel", and
  /// none of them opened anything. The For Rent / For Sale toggle above them
  /// changed nothing; it now chooses which count each card shows.
  Widget _buildNeighborhoods() {
    final hoods = ref.watch(listingNeighborhoodsProvider);
    final listings =
        ref.watch(_allActiveListingsProvider).valueOrNull ?? const <Listing>[];

    final counts = <String, int>{};
    for (final l in listings) {
      if (l.kind != _neighborhoodKind) continue;
      final id = l.neighborhoodId;
      if (id == null) continue;
      counts[id] = (counts[id] ?? 0) + 1;
    }

    return _Section(
      child: Column(
        children: [
          Text(
            _t('Apartments by Neighborhoods', 'דירות לפי שכונות'),
            style: TextStyle(
              fontFamily: AppFonts.nunito,
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppColors.midBlue,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _kindToggle(
                kind: ListingKind.rent,
                icon: IconsaxPlusLinear.key,
                label: _t('For Rent', 'להשכרה'),
                leading: true,
              ),
              _kindToggle(
                kind: ListingKind.sale,
                icon: IconsaxPlusLinear.home_hashtag,
                label: _t('For Sale', 'למכירה'),
                leading: false,
              ),
            ],
          ),
          const SizedBox(height: 40),
          hoods.when(
            loading: () => const SizedBox(
              height: 240,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => _buildNotice(
              icon: IconsaxPlusLinear.wifi_square,
              title: _t(
                'Neighbourhoods could not be loaded',
                'לא ניתן לטעון את השכונות',
              ),
              body: _t(
                'Check your connection and try again.',
                'בדקו את החיבור לאינטרנט ונסו שוב.',
              ),
              actionLabel: _t('Try again', 'נסו שוב'),
              onAction: () => ref.invalidate(listingNeighborhoodsProvider),
            ),
            data: (rows) => LayoutBuilder(
              builder: (context, constraints) {
                final cols = constraints.maxWidth > 1200
                    ? 6
                    : (constraints.maxWidth > 800 ? 4 : 2);
                const gap = 16.0;
                final cardWidth =
                    (constraints.maxWidth - (cols - 1) * gap) / cols;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final row in rows)
                      SizedBox(
                        width: cardWidth,
                        child: _NeighborhoodCard(
                          name: row.name,
                          city: _t(
                            'Modiin Maccabim Reut',
                            'מודיעין מכבים רעות',
                          ),
                          count: counts[row.id] ?? 0,
                          countLabel: _neighborhoodKind == ListingKind.rent
                              ? (n) => _t('$n to let', '$n להשכרה')
                              : (n) => _t('$n for sale', '$n למכירה'),
                          noneLabel: _t('None listed yet', 'אין נכסים כרגע'),
                          onTap: () => context.push('/neighborhood/${row.id}'),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 56),
        ],
      ),
    );
  }

  Widget _kindToggle({
    required ListingKind kind,
    required IconData icon,
    required String label,
    required bool leading,
  }) {
    final selected = _neighborhoodKind == kind;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _neighborhoodKind = kind),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.midBlue : Colors.transparent,
            border: selected
                ? null
                : Border.all(color: AppColors.midBlue, width: 2),
            borderRadius: BorderRadiusDirectional.horizontal(
              start: leading ? const Radius.circular(60) : Radius.zero,
              end: leading ? Radius.zero : const Radius.circular(60),
            ).resolve(Directionality.of(context)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : AppColors.midBlue,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.white : AppColors.midBlue,
                ),
              ),
            ],
          ),
        ),
      ),
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
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 24),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE7E7E7)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 44,
            color: const Color(0xFF6D6D6D).withValues(alpha: 0.5),
          ),
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
              color: const Color(0xFF5F5E5A),
            ),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 24),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onAction,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: AppColors.midBlue,
                    borderRadius: BorderRadius.circular(60),
                  ),
                  alignment: Alignment.center,
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
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// REUSABLE WIDGETS
// ═══════════════════════════════════════════════

class _SearchDropdown extends StatefulWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<int> onChanged;
  const _SearchDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  State<_SearchDropdown> createState() => _SearchDropdownState();
}

class _SearchDropdownState extends State<_SearchDropdown> {
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Tap-away backdrop
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeDropdown,
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
          ),
          // Dropdown menu
          Positioned(
            width: size.width + 24,
            child: CompositedTransformFollower(
              link: _layerLink,
              offset: Offset(-12, size.height + 8),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(widget.items.length, (i) {
                      final selected = widget.items[i] == widget.value;
                      return InkWell(
                        onTap: () {
                          widget.onChanged(i);
                          _closeDropdown();
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          color: selected
                              ? const Color(0xFFF0F4FA)
                              : Colors.transparent,
                          child: Text(
                            widget.items[i],
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 16,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: selected
                                  ? AppColors.midBlue
                                  : Colors.black,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _isOpen = false);
  }

  @override
  void dispose() {
    _closeDropdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _toggleDropdown,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  color: const Color(0xFF5F5E5A),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.value,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: Color(0xFF4F4F4F),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const _Section({required this.child, this.maxWidth = 1600});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

class _ViewAllButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ViewAllButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.midBlue,
            borderRadius: BorderRadius.circular(60),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left
                    : Icons.chevron_right,
                size: 16,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final int count;
  final String noneLabel;
  final String Function(int) countLabel;
  final bool selected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.width,
    required this.icon,
    required this.label,
    required this.count,
    required this.noneLabel,
    required this.countLabel,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: selected ? AppColors.midBlue : const Color(0xFFE7E7E7),
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, size: 32, color: AppColors.midBlue),
              const SizedBox(height: 19),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                count == 0 ? noneLabel : countLabel(count),
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  color: const Color(0xFF6D6D6D),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListingCard extends StatefulWidget {
  final Listing listing;
  final bool isHebrew;
  const _ListingCard({required this.listing, required this.isHebrew});

  @override
  State<_ListingCard> createState() => _ListingCardState();
}

class _ListingCardState extends State<_ListingCard> {
  bool _hovered = false;

  String _t(String en, String he) => widget.isHebrew ? he : en;

  /// Half rooms are normal here, so 3.5 must not print as 3.
  static String _rooms(double rooms) =>
      rooms == rooms.roundToDouble() ? '${rooms.toInt()}' : '$rooms';

  @override
  Widget build(BuildContext context) {
    final l = widget.listing;
    final isRent = l.kind == ListingKind.rent;
    final price = l.effectivePrice;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        // The cards were not tappable at all.
        onTap: () => context.push('/listing/${l.id}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE7E7E7)),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          transform: _hovered
              ? Matrix4.translationValues(0, -2, 0)
              : Matrix4.identity(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: NetworkPhoto(
                      url: l.coverUrl,
                      radius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      icon: IconsaxPlusBold.home_2,
                      iconSize: 48,
                    ),
                  ),
                  // A drawing of a heart with nothing behind it; it saves the
                  // listing now.
                  PositionedDirectional(
                    top: 12,
                    start: 12,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: FavoriteButton(
                          kind: FavoriteKind.listing,
                          id: l.id,
                          iconSize: 20,
                        ),
                      ),
                    ),
                  ),
                  // A "New" badge sat here on six of the eight demo flats.
                  // `listings` records when a row was created but nothing says
                  // what counts as new, so the rule would have been invented
                  // in this widget.
                  if (l.isBroker)
                    PositionedDirectional(
                      bottom: 12,
                      start: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCCD6EE),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          _t('Via Broker', 'דרך מתווך'),
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF0033AC),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // A listing with no price is not a free one.
                        Flexible(
                          child: Text(
                            price == null
                                ? _t('Price on request', 'מחיר לפי בקשה')
                                : isRent
                                ? _t(
                                    '${formatShekels(price)} / month',
                                    '${formatShekels(price)} לחודש',
                                  )
                                : formatShekels(price),
                            style: TextStyle(
                              fontFamily: AppFonts.nunito,
                              fontSize: price == null ? 14 : 20,
                              fontWeight: FontWeight.w600,
                              color: AppColors.navy,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          isRent
                              ? _t('FOR RENT', 'להשכרה')
                              : _t('FOR SALE', 'למכירה'),
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.turquoise,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          IconsaxPlusBold.location,
                          size: 16,
                          color: AppColors.turquoise,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l.address ?? l.neighborhoodName ?? l.title,
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 14,
                              color: const Color(0xFF5F5E5A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Each figure only where the row carries it. The row used
                    // to draw all three whatever was known.
                    Row(
                      children: [
                        if (l.sqm != null) ...[
                          _spec(
                            IconsaxPlusLinear.ruler,
                            _t('${l.sqm} m²', '${l.sqm} מ"ר'),
                          ),
                          const SizedBox(width: 31),
                        ],
                        if (l.rooms != null) ...[
                          _spec(
                            IconsaxPlusLinear.house,
                            _t(
                              '${_rooms(l.rooms!)} Rooms',
                              '${_rooms(l.rooms!)} חדרים',
                            ),
                          ),
                          const SizedBox(width: 31),
                        ],
                        if (l.floor != null)
                          _spec(
                            IconsaxPlusLinear.building_4,
                            _t('Floor ${l.floor}', 'קומה ${l.floor}'),
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

  Widget _spec(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF6D6D6D)),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 12,
            color: const Color(0xFF3D3D3D),
          ),
        ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final String title, subtitle;
  final bool isHighlighted;
  final VoidCallback onTap;
  const _ServiceCard({
    required this.width,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: width,
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(10),
            boxShadow: isHighlighted
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 56,
                color: isHighlighted
                    ? AppColors.midBlue
                    : const Color(0xFF6D6D6D),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: isHighlighted ? AppColors.midBlue : Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 16,
                  color: const Color(0xFF5F5E5A),
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NeighborhoodCard extends StatefulWidget {
  final String name;
  final String city;
  final int count;
  final String Function(int) countLabel;
  final String noneLabel;
  final VoidCallback onTap;

  const _NeighborhoodCard({
    required this.name,
    required this.city,
    required this.count,
    required this.countLabel,
    required this.noneLabel,
    required this.onTap,
  });

  @override
  State<_NeighborhoodCard> createState() => _NeighborhoodCardState();
}

class _NeighborhoodCardState extends State<_NeighborhoodCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        // The cards opened nothing, and /neighborhood/:id had nothing in the
        // app linking to it.
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE7E7E7)),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          transform: _hovered
              ? Matrix4.translationValues(0, -2, 0)
              : Matrix4.identity(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // `neighborhoods` has an `image_url` and none of the ten rows
              // carries one yet, so every card shows the brand panel — at the
              // same size, so nothing shifts once the client uploads photos.
              SizedBox(
                height: 150,
                width: double.infinity,
                child: NetworkPhoto(
                  url: null,
                  radius: const BorderRadius.vertical(top: Radius.circular(12)),
                  icon: IconsaxPlusBold.buildings_2,
                  iconSize: 36,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: TextStyle(
                        fontFamily: AppFonts.nunito,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.count == 0
                          ? widget.noneLabel
                          : widget.countLabel(widget.count),
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 14,
                        color: const Color(0xFF5F5E5A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          IconsaxPlusBold.location,
                          size: 16,
                          color: AppColors.turquoise,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.city,
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 14,
                              color: const Color(0xFF5F5E5A),
                            ),
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
