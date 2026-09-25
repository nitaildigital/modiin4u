import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../models/listing.dart';
import '../providers/listing_providers.dart';
import 'my_apartments_screen.dart' show formatShekels;

// ═══════════════════════════════════════════════════════════
// Web Real Estate Map — desktop layout for /realestate-map
//
// The mobile screen is a 430px map with the selected property in a card
// floating over it, so only one property can be read at a time. On a laptop
// the properties move into a panel of their own beside a full-height map,
// which is what web_restaurants_map_screen.dart already does with places.
//
// `listings` has no rows today, so what most people see is the empty panel
// and the map's "nothing has a location yet" notice. That is the correct
// outcome; the map is not seeded with pins to look busy.
// ═══════════════════════════════════════════════════════════

const _kBorder = Color(0xFFE7E7E7);
const _kSubtitle = Color(0xFF5F5E5A);
const _kTextGrey = Color(0xFF6D6D6D);
const _kPinBlue = Color(0xFF006BF6);

class WebRealEstateMapContent extends ConsumerStatefulWidget {
  const WebRealEstateMapContent({super.key});

  @override
  ConsumerState<WebRealEstateMapContent> createState() =>
      _WebRealEstateMapContentState();
}

class _WebRealEstateMapContentState
    extends ConsumerState<WebRealEstateMapContent> {
  bool _isHebrew = false;
  String? _selectedId;

  final _searchController = TextEditingController();
  final _listController = ScrollController();
  final _mapController = MapController();
  Timer? _debounce;

  static const _center = LatLng(31.8928, 35.0104);

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(listingFilterProvider).search ?? '';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _listController.dispose();
    super.dispose();
  }

  String _t(String en, String he) => _isHebrew ? he : en;

  /// The same debounce the mobile screen uses — the filter is a provider, so
  /// a keystroke without it would refetch on every letter.
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final f = ref.read(listingFilterProvider);
      ref.read(listingFilterProvider.notifier).state = f.copyWith(
        search: value.trim(),
      );
    });
  }

  /// 3.5 reads as "3.5"; 4.0 reads as "4".
  static String _rooms(double v) =>
      v == v.roundToDouble() ? '${v.toInt()}' : '$v';

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
            // The panel takes a share of the window rather than a fixed
            // width: held at 560 it would leave a 1101px laptop with a map
            // barely wider than the list beside it.
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final panelWidth = (constraints.maxWidth * 0.38).clamp(
                    360.0,
                    560.0,
                  );
                  return Row(
                    children: [
                      SizedBox(width: panelWidth, child: _buildListPanel()),
                      Expanded(child: _buildMapPanel()),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // LIST PANEL — the properties, scrolling on their own
  // ─────────────────────────────────────────────
  Widget _buildListPanel() {
    final listings = ref.watch(listingsProvider);
    final rows = listings.valueOrNull ?? const <Listing>[];

    return Container(
      decoration: const BoxDecoration(
        border: BorderDirectional(end: BorderSide(color: _kBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: _buildPanelHeader(rows),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: listings.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => _buildNotice(
                icon: IconsaxPlusLinear.wifi_square,
                title: _t(
                  'Properties could not be loaded',
                  'לא ניתן לטעון את המודעות',
                ),
                body: _t(
                  'Check your connection and try again.',
                  'בדקו את החיבור לאינטרנט ונסו שוב.',
                ),
              ),
              data: (all) => all.isEmpty
                  ? _buildNotice(
                      icon: IconsaxPlusLinear.home_2,
                      title: _t(
                        'No properties are listed yet',
                        'עדיין לא פורסמו מודעות',
                      ),
                      body: _t(
                        'Properties will appear here, and on the map, as soon as they are posted.',
                        'מודעות יופיעו כאן ועל המפה ברגע שיפורסמו.',
                      ),
                    )
                  : Scrollbar(
                      controller: _listController,
                      child: ListView.builder(
                        controller: _listController,
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        itemCount: all.length,
                        itemBuilder: (context, i) {
                          final row = all[i];
                          return _PropertyRow(
                            listing: row,
                            isHebrew: _isHebrew,
                            selected: _selectedId == row.id,
                            roomsLabel: row.rooms == null
                                ? null
                                : '${_rooms(row.rooms!)} ${_t('Rooms', 'חדרים')}',
                            sqmLabel: row.sqm == null
                                ? null
                                : '${row.sqm} ${_t('m²', 'מ״ר')}',
                            floorLabel: row.floor == null
                                ? null
                                : _t('Floor ${row.floor}', 'קומה ${row.floor}'),
                            onTap: () => context.push('/listing/${row.id}'),
                            onHover: (hovering) => _hover(row, hovering),
                          );
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Hovering a row lights its pin, and moves the map to it when it has one,
  /// which is the only way to tell on a desktop which pin a row belongs to.
  void _hover(Listing listing, bool hovering) {
    setState(() {
      if (hovering) {
        _selectedId = listing.id;
      } else if (_selectedId == listing.id) {
        _selectedId = null;
      }
    });
    if (hovering && listing.latitude != null && listing.longitude != null) {
      _mapController.move(
        LatLng(listing.latitude!, listing.longitude!),
        _mapController.camera.zoom,
      );
    }
  }

  Widget _buildPanelHeader(List<Listing> rows) {
    final pinned = rows
        .where((l) => l.latitude != null && l.longitude != null)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                rows.length == 1
                    ? _t('1 Property', 'מודעה אחת')
                    : _t('${rows.length} Properties', '${rows.length} מודעות'),
                style: TextStyle(
                  fontFamily: AppFonts.nunito,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  height: 34 / 28,
                  color: AppColors.midBlue,
                ),
              ),
            ),
            const SizedBox(width: 12),
            _listViewButton(),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          // A listing without coordinates is in this panel but not on the
          // map, so the two counts can differ. Said once, here.
          pinned == rows.length
              ? _t('in Modiin Maccabim Reut', 'במודיעין מכבים רעות')
              : _t(
                  'in Modiin Maccabim Reut · $pinned on the map',
                  'במודיעין מכבים רעות · $pinned על המפה',
                ),
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 14,
            color: _kSubtitle,
          ),
        ),
        const SizedBox(height: 20),
        _buildSearchField(),
      ],
    );
  }

  /// The mobile screen's "List View" pill, which leads to the full Real
  /// Estate page rather than simply closing the map.
  Widget _listViewButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/realestate'),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            border: Border.all(color: _kBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                IconsaxPlusLinear.menu,
                size: 16,
                color: AppColors.midBlue,
              ),
              const SizedBox(width: 6),
              Text(
                _t('List View', 'תצוגת רשימה'),
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.midBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            IconsaxPlusLinear.search_normal_1,
            size: 18,
            color: _kTextGrey,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                // The app theme fills every field with a grey pill, which
                // would draw a second, rounder box inside this one.
                filled: false,
                hintText: _t(
                  'Search by location, neighborhood...',
                  'חיפוש לפי מיקום, שכונה...',
                ),
                hintStyle: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  color: _kTextGrey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotice({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: _kTextGrey.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.nunito,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                height: 1.4,
                color: _kSubtitle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // MAP PANEL — full height, with its own zoom controls
  // ─────────────────────────────────────────────
  Widget _buildMapPanel() {
    final pinned =
        (ref.watch(listingsProvider).valueOrNull ?? const <Listing>[])
            .where((l) => l.latitude != null && l.longitude != null)
            .toList();

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _center,
            initialZoom: 14.2,
            onTap: (_, _) => setState(() => _selectedId = null),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.modiin4u.app',
            ),
            MarkerLayer(
              markers: [
                for (final l in pinned)
                  Marker(
                    point: LatLng(l.latitude!, l.longitude!),
                    width: 40,
                    height: 40,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      onEnter: (_) => setState(() => _selectedId = l.id),
                      onExit: (_) => setState(() {
                        if (_selectedId == l.id) _selectedId = null;
                      }),
                      child: GestureDetector(
                        onTap: () => context.push('/listing/${l.id}'),
                        child: _PropertyPin(selected: _selectedId == l.id),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),

        // Nothing to pin at all — said plainly rather than leaving an empty
        // map that reads as a map that failed to load.
        if (pinned.isEmpty)
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Text(
                  _t(
                    'No listings have a location on the map yet',
                    'אין מודעות עם מיקום על המפה',
                  ),
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 14,
                    color: _kSubtitle,
                  ),
                ),
              ),
            ),
          ),

        PositionedDirectional(
          end: 16,
          bottom: 24,
          child: Column(
            children: [
              _MapFab(
                icon: IconsaxPlusLinear.gps,
                onTap: () => _mapController.move(_center, 14.2),
              ),
              const SizedBox(height: 12),
              _MapFab(
                icon: IconsaxPlusLinear.add,
                onTap: () => _mapController.move(
                  _mapController.camera.center,
                  _mapController.camera.zoom + 1,
                ),
              ),
              const SizedBox(height: 12),
              _MapFab(
                icon: IconsaxPlusLinear.minus,
                onTap: () => _mapController.move(
                  _mapController.camera.center,
                  _mapController.camera.zoom - 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// PROPERTY ROW — one listing in the panel
// ═══════════════════════════════════════════════

class _PropertyRow extends StatelessWidget {
  final Listing listing;
  final bool isHebrew, selected;
  final String? roomsLabel, sqmLabel, floorLabel;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;

  const _PropertyRow({
    required this.listing,
    required this.isHebrew,
    required this.selected,
    required this.roomsLabel,
    required this.sqmLabel,
    required this.floorLabel,
    required this.onTap,
    required this.onHover,
  });

  String _t(String en, String he) => isHebrew ? he : en;

  @override
  Widget build(BuildContext context) {
    final l = listing;
    final price = l.effectivePrice;
    final address = l.address ?? l.neighborhoodName;
    final chips = [
      sqmLabel,
      roomsLabel,
      floorLabel,
    ].whereType<String>().toList();

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: selected ? AppColors.midBlue : _kBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NetworkPhoto(
                url: l.coverUrl,
                width: 96,
                height: 96,
                radius: BorderRadius.circular(10),
                icon: IconsaxPlusLinear.home_2,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (price != null)
                          Expanded(
                            child: Text(
                              l.kind == ListingKind.rent
                                  ? _t(
                                      '${formatShekels(price)} / month',
                                      '${formatShekels(price)} לחודש',
                                    )
                                  : formatShekels(price),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppFonts.rubik,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.navy,
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: Text(
                              _t('Price on request', 'מחיר לפי בקשה'),
                              style: TextStyle(
                                fontFamily: AppFonts.inter,
                                fontSize: 14,
                                color: _kSubtitle,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Text(
                          l.kind == ListingKind.rent
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
                    const SizedBox(height: 6),
                    Text(
                      l.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                    ),
                    if (address != null && address.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            IconsaxPlusLinear.location,
                            size: 15,
                            color: AppColors.turquoise,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppFonts.inter,
                                fontSize: 13,
                                color: _kSubtitle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    // Only the figures the listing carries.
                    if (chips.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 16,
                        runSpacing: 4,
                        children: [
                          for (final chip in chips)
                            Text(
                              chip,
                              style: TextStyle(
                                fontFamily: AppFonts.inter,
                                fontSize: 13,
                                color: _kTextGrey,
                              ),
                            ),
                        ],
                      ),
                    ],
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

// ═══════════════════════════════════════════════
// MAP PIN — the mobile screen's pin, at the same size
// ═══════════════════════════════════════════════

class _PropertyPin extends StatelessWidget {
  final bool selected;
  const _PropertyPin({this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 2.28,
            offset: const Offset(0, 2.28),
          ),
        ],
        border: selected
            ? Border.all(color: AppColors.midBlue, width: 2)
            : null,
      ),
      child: Center(
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: selected ? AppColors.turquoise : _kPinBlue,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            IconsaxPlusBold.home_2,
            size: 12,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _MapFab extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MapFab({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(child: Icon(icon, size: 20, color: AppColors.navy)),
        ),
      ),
    );
  }
}
