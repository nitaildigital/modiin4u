import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../../../shared/widgets/web_dotted_band.dart';
import '../models/listing.dart';
import '../providers/listing_providers.dart';
import '../providers/neighborhood_providers.dart';
import 'my_apartments_screen.dart' show formatShekels;
import '../../../shared/widgets/web_hero_photo.dart';

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
//
// Everything below is drawn to the Figma frame "Real Estate in Modiin"
// (1920 wide) and filled from `listings` and `neighborhoods`.
// ═══════════════════════════════════════════════════════════

const _kBorder = Color(0xFFE7E7E7);
const _kGrey = Color(0xFF5F5E5A);
const _kSpecText = Color(0xFF3D3D3D);
const _kAssets = 'assets/web/realestate';

class WebRealEstateContent extends ConsumerStatefulWidget {
  const WebRealEstateContent({super.key});

  @override
  ConsumerState<WebRealEstateContent> createState() =>
      _WebRealEstateContentState();
}

class _WebRealEstateContentState extends ConsumerState<WebRealEstateContent>
    with WebLanguageState<WebRealEstateContent> {
  /// Which property type the cards above have narrowed both rows to, or null
  /// for all of them. It used to be an index that changed a border colour and
  /// nothing else.
  PropertyType? _selectedType;

  /// Which kind the neighbourhood cards lead to. It used to change nothing.
  ListingKind _neighborhoodKind = ListingKind.rent;

  /// The "What We Are Providing" card under the pointer. The design draws the
  /// first one lit, with the pointer over it; with no pointer over any of
  /// them, that is the one that stays lit.
  int? _hoveredService;

  final _hoodScroll = ScrollController();

  ListingKind _searchKind = ListingKind.sale;
  bool get _isHebrew => webIsHebrew.value;
  final _locationController = TextEditingController();
  final _locationFocus = FocusNode();

  @override
  void dispose() {
    _locationController.dispose();
    _locationFocus.dispose();
    _hoodScroll.dispose();
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

  /// The six types the browse row offers, with the design's line drawing for
  /// each. `other` is left out: it is what the model falls back to, not
  /// something a reader would pick.
  static const _browseTypes = [
    (PropertyType.apartment, 'type_apartment.svg'),
    (PropertyType.penthouse, 'type_penthouse.svg'),
    (PropertyType.garden, 'type_garden.svg'),
    (PropertyType.duplex, 'type_duplex.svg'),
    (PropertyType.villa, 'type_villa.svg'),
    (PropertyType.studio, 'type_studio.svg'),
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
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // The gaps between sections are the design's, measured
                    // off the 1920 frame.
                    _buildHeroSection(),
                    const SizedBox(height: 48),
                    _buildBrowseTypes(),
                    const SizedBox(height: 72),
                    _buildListingsSection(ListingKind.sale),
                    const SizedBox(height: 80),
                    _buildListingsSection(ListingKind.rent),
                    const SizedBox(height: 80),
                    _buildWhatWeProvide(),
                    const SizedBox(height: 80),
                    _buildNeighborhoods(),
                    const SizedBox(height: 146),
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
  // HERO — the design's band and photograph, with the search across it
  // ─────────────────────────────────────────────
  Widget _buildHeroSection() {
    return SizedBox(
      width: double.infinity,
      height: 662,
      child: Stack(
        children: [
          const Positioned.fill(child: WebDottedBand()),
          Positioned(
            top: 48,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1200),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                height: 551,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: const WebHeroPhoto(
                          asset: 'assets/web/realestate/hero.webp',
                          placeholder: Color(0xFF6F7476),
                        ),
                      ),
                      // A fifth of black over the whole photograph, and the
                      // sky washed blue from the top, as drawn.
                      Positioned.fill(
                        child: ColoredBox(
                          color: Colors.black.withValues(alpha: 0.2),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 428,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color(0xFF80B2DF).withValues(alpha: 0.55),
                                const Color(0xFF80B2DF).withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 112,
                        left: 0,
                        right: 0,
                        child: Column(
                          children: [
                            Text(
                              _t(
                                'Find Your Perfect Home in Modiin',
                                'מצאו את הבית המושלם במודיעין',
                              ),
                              style: TextStyle(
                                fontFamily: AppFonts.nunito,
                                fontSize: 44,
                                height: 54 / 44,
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
                                height: 19 / 16,
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
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8),
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
          // The design leaves 47 of air between the two fields, and no rule.
          const SizedBox(width: 47),
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
                    height: 17 / 14,
                    color: const Color(0xFF5F5E5A),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _locationController,
                  focusNode: _locationFocus,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 16,
                    height: 19 / 16,
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
                      height: 19 / 16,
                      color: const Color(0xFF4F4F4F),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    filled: false,
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
                    SvgPicture.asset(
                      'assets/web/common/search_white.svg',
                      width: 18,
                      height: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _t('Search', 'חיפוש'),
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 16,
                        height: 24 / 16,
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

  Widget _sectionTitle(String text, {bool center = false}) => Text(
    text,
    style: TextStyle(
      fontFamily: AppFonts.nunito,
      fontSize: 28,
      height: 34 / 28,
      fontWeight: FontWeight.w600,
      color: AppColors.midBlue,
    ),
    textAlign: center ? TextAlign.center : TextAlign.start,
  );

  // ─────────────────────────────────────────────
  // BROWSE BY TYPE — 1200 wide, six cards
  // ─────────────────────────────────────────────
  /// The six property types, each with the number of listings filed under it.
  ///
  /// The counts were fixed — 32 apartments, 24 penthouses, 8 studios — and
  /// tapping a card only moved a border. A type with nothing under it says so
  /// rather than showing a nought that reads as a figure, and stays tappable
  /// because it is a filter, not a claim.
  Widget _buildBrowseTypes() {
    final listings =
        ref.watch(allActiveListingsProvider).valueOrNull ?? const <Listing>[];
    final counts = <PropertyType, int>{};
    for (final l in listings) {
      counts[l.propertyType] = (counts[l.propertyType] ?? 0) + 1;
    }

    return WebSection(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              _sectionTitle(
                _t('Browse Real Estate', 'חפשו נדל״ן'),
                center: true,
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
                            () => _selectedType = _selectedType == type
                                ? null
                                : type,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // LISTINGS — one row for sale, one to let
  // ─────────────────────────────────────────────
  Widget _buildListingsSection(ListingKind kind) {
    final isRent = kind == ListingKind.rent;
    final async = ref.watch(allActiveListingsProvider);

    return WebSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(
                      isRent
                          ? _t(
                              'Apartments for Rent in Modiin',
                              'דירות להשכרה במודיעין',
                            )
                          : _t(
                              'Apartments for Sale in Modiin',
                              'דירות למכירה במודיעין',
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
                        height: 17 / 14,
                        color: _kGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // It had `onTap: () {}`. The property type picked under
              // "Browse Real Estate" narrows the rows above, so it goes along.
              _ViewAllButton(
                label: _t('View all properties', 'לכל הנכסים'),
                onTap: () => context.push(Uri(
                  path: isRent ? '/apartments-rent' : '/apartments-sale',
                  queryParameters: _selectedType == null ? null : {'type': _selectedType!.name},
                ).toString()),
              ),
            ],
          ),
          const SizedBox(height: 32),
          async.when(
            loading: () => const SizedBox(
              height: 321,
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
              onAction: () => ref.invalidate(allActiveListingsProvider),
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

              // One row, as drawn: four cards across the 1600 column, three
              // on a laptop where four would squeeze the price line.
              return LayoutBuilder(
                builder: (context, constraints) {
                  final cols = constraints.maxWidth >= 1200 ? 4 : 3;
                  const gap = 24.0;
                  final cardWidth =
                      (constraints.maxWidth - (cols - 1) * gap) / cols;
                  final shown = listings.take(cols).toList();
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < shown.length; i++) ...[
                          if (i > 0) const SizedBox(width: gap),
                          SizedBox(
                            width: cardWidth,
                            child: _ListingCard(
                              listing: shown[i],
                              isHebrew: _isHebrew,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // WHAT WE ARE PROVIDING
  // ─────────────────────────────────────────────
  /// Three cards that read as calls to action and had no handler at all.
  ///
  /// "Sell A Property" used to open the form for posting a listing, which
  /// belongs to the app — the client decided the website is for reading — so
  /// it was dropped. The design draws it, and a listing does not need an
  /// account behind it: the client enters ones that arrive by telephone or
  /// e-mail himself. So the card is back, and it writes to him.
  Widget _buildWhatWeProvide() {
    final cards = [
      (
        icon: 'svc_rent',
        title: _t('Find Your Next Rental', 'מצאו את השכירות הבאה'),
        body: _t(
          'Browse apartments and homes available for rent across Modiin.',
          'חפשו דירות ובתים להשכרה ברחבי מודיעין.',
        ),
        onTap: () => context.push('/apartments-rent'),
      ),
      (
        icon: 'svc_sell',
        title: _t('Sell A Property', 'מכרו נכס'),
        body: _t(
          'List your property and connect with people looking to buy in Modiin.',
          'פרסמו את הנכס שלכם והתחברו לאנשים שמחפשים לקנות במודיעין.',
        ),
        onTap: () => launchUrl(Uri(scheme: 'mailto', path: kContactEmail)),
      ),
      (
        icon: 'svc_buy',
        title: _t('Buy A Property', 'קנו נכס'),
        body: _t(
          'Explore apartments and homes for sale in Modiin. Compare properties, neighborhoods, prices.',
          'גלו דירות ובתים למכירה במודיעין. השוו נכסים, שכונות, מחירים.',
        ),
        onTap: () => context.push('/apartments-sale'),
      ),
    ];
    final lit = _hoveredService ?? 0;

    return WebSection(
      child: Column(
        children: [
          _sectionTitle(
            _t('What We Are Providing', 'מה אנחנו מציעים'),
            center: true,
          ),
          const SizedBox(height: 32),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(width: 21),
                  Expanded(
                    child: _ServiceCard(
                      icon: cards[i].icon,
                      title: cards[i].title,
                      subtitle: cards[i].body,
                      isHighlighted: lit == i,
                      onHover: (on) => setState(
                        () => _hoveredService = on
                            ? i
                            : (_hoveredService == i ? null : _hoveredService),
                      ),
                      onTap: cards[i].onTap,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // APARTMENTS BY NEIGHBOURHOOD — a carousel of six
  // ─────────────────────────────────────────────
  /// The city's neighbourhoods, from `neighborhoods`.
  ///
  /// Six were written in that are not rows in that table at all, and none of
  /// them opened anything. The For Rent / For Sale toggle above them changed
  /// nothing; it now decides what a card opens — that neighbourhood's flats to
  /// let, or its flats for sale.
  Widget _buildNeighborhoods() {
    final hoods = ref.watch(activeNeighborhoodsProvider);

    return WebSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle(
            _t('Apartments by Neighborhoods', 'דירות לפי שכונות'),
            center: true,
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _kindToggle(
                kind: ListingKind.rent,
                icon: 'tab_rent.svg',
                label: _t('For Rent', 'להשכרה'),
                leading: true,
              ),
              _kindToggle(
                kind: ListingKind.sale,
                icon: 'tab_sale.svg',
                label: _t('For Sale', 'למכירה'),
                leading: false,
              ),
            ],
          ),
          const SizedBox(height: 41),
          hoods.when(
            loading: () => const SizedBox(
              height: 248,
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
              onAction: () => ref.invalidate(activeNeighborhoodsProvider),
            ),
            data: (all) => LayoutBuilder(
              builder: (context, constraints) {
                // The design's cards are photographs. The table's order is
                // kept, but those with a photograph come first, so the six in
                // view are not six blue panels while the pictured ones wait
                // behind the arrow.
                final rows = [
                  ...all.where((h) => h.imageUrl != null && h.imageUrl!.isNotEmpty),
                  ...all.where((h) => h.imageUrl == null || h.imageUrl!.isEmpty),
                ];
                final visible = constraints.maxWidth >= 1400
                    ? 6
                    : (constraints.maxWidth >= 1000 ? 5 : 4);
                const gap = 16.0;
                final cardWidth =
                    (constraints.maxWidth - (visible - 1) * gap) / visible;
                final step = cardWidth + gap;
                final kindPath = _neighborhoodKind == ListingKind.rent
                    ? '/apartments-rent'
                    : '/apartments-sale';

                return SizedBox(
                  height: 248,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ListView.separated(
                        controller: _hoodScroll,
                        scrollDirection: Axis.horizontal,
                        itemCount: rows.length,
                        separatorBuilder: (_, _) => const SizedBox(width: gap),
                        itemBuilder: (context, i) => SizedBox(
                          width: cardWidth,
                          child: _NeighborhoodCard(
                            name: rows[i].name,
                            imageUrl: rows[i].imageUrl,
                            subtitle: _t(
                              'Neighborhood, Modiin',
                              'שכונה, מודיעין',
                            ),
                            city: _t('Modiin, Israel', 'מודיעין, ישראל'),
                            onTap: () => context.push(
                              Uri(
                                path: kindPath,
                                queryParameters: {'neighborhood': rows[i].id},
                              ).toString(),
                            ),
                          ),
                        ),
                      ),
                      // Only when there is somewhere to scroll to.
                      if (rows.length > visible) ...[
                        PositionedDirectional(
                          start: -20,
                          top: 106,
                          child: _CarouselArrow(
                            back: true,
                            onTap: () => _scrollHoods(-step),
                          ),
                        ),
                        PositionedDirectional(
                          end: -20,
                          top: 106,
                          child: _CarouselArrow(
                            back: false,
                            onTap: () => _scrollHoods(step),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _scrollHoods(double by) {
    if (!_hoodScroll.hasClients) return;
    final p = _hoodScroll.position;
    _hoodScroll.animateTo(
      (p.pixels + by).clamp(p.minScrollExtent, p.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Widget _kindToggle({
    required ListingKind kind,
    required String icon,
    required String label,
    required bool leading,
  }) {
    final selected = _neighborhoodKind == kind;
    final fg = selected ? Colors.white : AppColors.midBlue;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _neighborhoodKind = kind),
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: selected ? AppColors.midBlue : Colors.white,
            border: Border.all(color: AppColors.midBlue, width: 2),
            borderRadius: BorderRadiusDirectional.horizontal(
              start: leading ? const Radius.circular(60) : Radius.zero,
              end: leading ? Radius.zero : const Radius.circular(60),
            ).resolve(Directionality.of(context)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                '$_kAssets/$icon',
                width: 18,
                height: 18,
                colorFilter: ColorFilter.mode(fg, BlendMode.srcIn),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 24 / 16,
                  color: fg,
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
        border: Border.all(color: _kBorder),
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
              height: 25 / 20,
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
              height: 17 / 14,
              color: _kGrey,
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
                      height: 19 / 16,
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
                              height: 19 / 16,
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
                  height: 17 / 14,
                  color: const Color(0xFF5F5E5A),
                ),
              ),
              const SizedBox(height: 8),
              // 134 wide as drawn, the chevron at its far end.
              SizedBox(
                width: 134,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.value,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 16,
                        height: 19 / 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isOpen ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: SvgPicture.asset(
                        '$_kAssets/chevron16.svg',
                        width: 16,
                        height: 16,
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

class _TypeCard extends StatelessWidget {
  final double width;
  final String icon;
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
              SvgPicture.asset(
                'assets/web/realestate/$icon',
                width: 32,
                height: 32,
              ),
              const SizedBox(height: 19),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 16,
                  height: 19 / 16,
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
                  height: 17 / 14,
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
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  height: 24 / 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              Transform.flip(
                flipX: Directionality.of(context) == TextDirection.rtl,
                child: SvgPicture.asset(
                  '$_kAssets/chevron_right_white.svg',
                  width: 16,
                  height: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A rounded label over a photograph: "New" in the top corner, "Via Broker"
/// in the bottom one.
class _PhotoBadge extends StatelessWidget {
  final String label;
  final Color background, foreground;
  final double horizontalPadding;
  const _PhotoBadge({
    required this.label,
    required this.background,
    required this.foreground,
    required this.horizontalPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppFonts.inter,
          fontSize: 12,
          height: 15 / 12,
          fontWeight: FontWeight.w500,
          color: foreground,
        ),
      ),
    );
  }
}

/// One listing, as the design's card draws it: 200 of photograph, then the
/// price, the address and the three figures.
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
    final place = l.address ?? l.neighborhoodName;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        // The cards were not tappable at all.
        onTap: () => context.push('/listing/${l.id}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _kBorder),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : const [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 200,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    NetworkPhoto(
                      url: l.coverUrl,
                      icon: IconsaxPlusBold.home_2,
                      iconSize: 48,
                    ),
                    // The heart the design draws saves a listing to an
                    // account, and accounts are the app's alone.
                    if (l.isNew)
                      PositionedDirectional(
                        top: 15,
                        end: 14,
                        child: _PhotoBadge(
                          label: _t('New', 'חדש'),
                          background: AppColors.turquoise,
                          foreground: Colors.white,
                          horizontalPadding: 8,
                        ),
                      ),
                    if (l.isBroker)
                      PositionedDirectional(
                        bottom: 12,
                        start: 12,
                        child: _PhotoBadge(
                          label: _t('Via Broker', 'דרך מתווך'),
                          background: const Color(0xFFCCD6EE),
                          foreground: const Color(0xFF0033AC),
                          horizontalPadding: 16,
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // A listing with no price is not a free one.
                        Expanded(
                          child: price == null
                              ? Text(
                                  _t('Price on request', 'מחיר לפי בקשה'),
                                  style: TextStyle(
                                    fontFamily: AppFonts.nunito,
                                    fontSize: 16,
                                    height: 20 / 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.navy,
                                  ),
                                )
                              : Row(
                                  children: [
                                    Text(
                                      formatShekels(price),
                                      style: TextStyle(
                                        fontFamily: AppFonts.nunito,
                                        fontSize: 20,
                                        height: 25 / 20,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.navy,
                                      ),
                                    ),
                                    if (isRent) ...[
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          _t('/ month', '/ לחודש'),
                                          style: TextStyle(
                                            fontFamily: AppFonts.inter,
                                            fontSize: 14,
                                            height: 17 / 14,
                                            color: _kGrey,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isRent
                              ? _t('FOR RENT', 'להשכרה')
                              : _t('FOR SALE', 'למכירה'),
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 12,
                            height: 15 / 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.turquoise,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: Center(
                            child: SvgPicture.asset(
                              '$_kAssets/card_pin.svg',
                              width: 12,
                              height: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            place ?? l.title,
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 14,
                              height: 17 / 14,
                              color: _kGrey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Each figure only where the row carries it. The row used
                    // to draw all three whatever was known. The design's 31
                    // between them on its 382 card; closer on a laptop's
                    // narrower one, so "Ground Floor" stays on the line.
                    LayoutBuilder(
                      builder: (context, c) => Wrap(
                        spacing: c.maxWidth >= 330 ? 31 : 16,
                        runSpacing: 8,
                        children: [
                          if (l.sqm != null)
                            _spec(
                              'spec_sqm.svg',
                              _t('${l.sqm} m²', '${l.sqm} מ״ר'),
                            ),
                          if (l.rooms != null)
                            _spec(
                              'spec_rooms.svg',
                              l.rooms == 1
                                  ? _t('1 Room', 'חדר 1')
                                  : _t(
                                      '${_rooms(l.rooms!)} Rooms',
                                      '${_rooms(l.rooms!)} חדרים',
                                    ),
                            ),
                          if (l.floor != null)
                            _spec(
                              'spec_floor.svg',
                              (l.floor == 0
                                  ? _t('Ground Floor', 'קומת קרקע')
                                  : _t('Floor ${l.floor}', 'קומה ${l.floor}')),
                            ),
                        ],
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

  Widget _spec(String icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset('$_kAssets/$icon', width: 14, height: 14),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 12,
            height: 15 / 12,
            color: _kSpecText,
          ),
        ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String icon, title, subtitle;
  final bool isHighlighted;
  final ValueChanged<bool> onHover;
  final VoidCallback onTap;
  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isHighlighted,
    required this.onHover,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // The lit card's drawing turns the brand blue. The rental one is drawn in
    // blue with a white door cut into it, so it has a grey twin rather than a
    // tint, which would fill the door in.
    final Widget art = icon == 'svc_rent'
        ? SvgPicture.asset(
            '$_kAssets/${isHighlighted ? 'svc_rent' : 'svc_rent_grey'}.svg',
            width: 56,
            height: 56,
          )
        : SvgPicture.asset(
            '$_kAssets/$icon.svg',
            width: 56,
            height: 56,
            colorFilter: isHighlighted
                ? const ColorFilter.mode(AppColors.midBlue, BlendMode.srcIn)
                : null,
          );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(10),
            boxShadow: isHighlighted
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : const [],
          ),
          // From the top, so the three drawings line up when one card's
          // text runs to more lines than its neighbours' (Hebrew does).
          child: Column(
            children: [
              art,
              const SizedBox(height: 20),
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 22,
                  height: 27 / 22,
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
                  color: _kGrey,
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

class _NeighborhoodCard extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final String subtitle;
  final String city;
  final VoidCallback onTap;

  const _NeighborhoodCard({
    required this.name,
    required this.imageUrl,
    required this.subtitle,
    required this.city,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        // The cards opened nothing.
        onTap: onTap,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _kBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // `neighborhoods.image_url`, where the client has uploaded one;
              // the brand panel at the same size where he has not, so nothing
              // shifts when he does.
              SizedBox(
                height: 150,
                child: NetworkPhoto(
                  url: imageUrl,
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
                      name,
                      style: TextStyle(
                        fontFamily: AppFonts.nunito,
                        fontSize: 18,
                        height: 22 / 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 14,
                        height: 17 / 14,
                        color: _kGrey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: Center(
                            child: SvgPicture.asset(
                              '$_kAssets/card_pin.svg',
                              width: 12,
                              height: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            city,
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 14,
                              height: 17 / 14,
                              color: _kGrey,
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

/// The white round button either side of the neighbourhood carousel.
class _CarouselArrow extends StatelessWidget {
  final bool back;
  final VoidCallback onTap;
  const _CarouselArrow({required this.back, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // The drawing points forward; in Hebrew forward is to the left.
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFF6F6F6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 5,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Transform.flip(
            flipX: back != rtl,
            child: SvgPicture.asset(
              '$_kAssets/carousel_arrow.svg',
              width: 20,
              height: 20,
            ),
          ),
        ),
      ),
    );
  }
}
