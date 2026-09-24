import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../favorites/widgets/favorite_button.dart';
import '../../favorites/repositories/favorite_repository.dart';
import '../models/listing.dart';
import '../providers/listing_providers.dart';
import 'my_apartments_screen.dart' show formatShekels;
import 'web_listing_detail_screen.dart';

/// One apartment listing.
///
/// The whole page used to be a single invented flat: a fixed ₪3,650,000, a
/// fixed address, an agent called Zeev Schumacher, and a paragraph about the
/// Moriah neighbourhood — shown for every listing id the route was given,
/// because the id was never read. It loads the row now, and a section with
/// nothing behind it is left out rather than filled with a placeholder.
class ListingDetailScreen extends StatelessWidget {
  final String listingId;
  const ListingDetailScreen({super.key, required this.listingId});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) {
          return WebListingDetailContent(listingId: listingId);
        }
        return _MobileListingDetailContent(listingId: listingId);
      },
    );
  }
}

class _MobileListingDetailContent extends ConsumerStatefulWidget {
  final String listingId;
  const _MobileListingDetailContent({required this.listingId});

  @override
  ConsumerState<_MobileListingDetailContent> createState() =>
      _MobileListingDetailContentState();
}

class _MobileListingDetailContentState
    extends ConsumerState<_MobileListingDetailContent> {
  int _selectedThumb = 0;
  bool _aboutExpanded = false;

  /// The hero shows whichever thumbnail is chosen, so the cover and the
  /// gallery are one list.
  List<String> _photos(Listing l) => [
    if (l.coverUrl != null && l.coverUrl!.isNotEmpty) l.coverUrl!,
    ...l.gallery,
  ];

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final async = ref.watch(listingByIdProvider(widget.listingId));

    return Scaffold(
      backgroundColor: Colors.white,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _notFound(l),
        data: (listing) {
          if (listing == null) return _notFound(l);
          return _content(l, listing);
        },
      ),
    );
  }

  Widget _notFound(L l) => Stack(
    children: [
      Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l.listingNotFound,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 15,
              color: const Color(0xFF6D6D6D),
            ),
          ),
        ),
      ),
      Positioned(
        left: 12,
        top: 51,
        child: _CircleButton(
          icon: IconsaxPlusLinear.arrow_left,
          onTap: () => context.pop(),
        ),
      ),
    ],
  );

  Widget _content(L l, Listing listing) {
    final photos = _photos(listing);
    final price = listing.effectivePrice;
    final hood = listing.neighborhoodName;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroImage(listing, photos),

              if (photos.length > 1) ...[
                const SizedBox(height: 16),
                _buildThumbnailRow(photos),
              ],

              // ── Price ──
              if (price != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: Text(
                    listing.kind == ListingKind.rent
                        ? l.pricePerMonthValue(formatShekels(price))
                        : formatShekels(price),
                    style: TextStyle(
                      fontFamily: AppFonts.rubik,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),

              // ── Title ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  listing.title,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),

              // ── Address ──
              //
              // The mock also showed "2.1 km away". Nothing measures that, so
              // it is gone rather than made up.
              if ((listing.address ?? hood) != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      const Icon(
                        IconsaxPlusLinear.location,
                        size: 16,
                        color: Color(0xFF888888),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          listing.address ?? hood!,
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 14,
                            color: const Color(0xFF6D6D6D),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Area / rooms / bathrooms ──
              //
              // Only the ones the listing actually carries.
              if (listing.sqm != null ||
                  listing.rooms != null ||
                  listing.bathrooms != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Row(
                    children: [
                      if (listing.sqm != null) ...[
                        _StatCard(
                          icon: IconsaxPlusLinear.maximize_3,
                          value: '${listing.sqm}',
                          unit: l.sqmUnit,
                        ),
                        const SizedBox(width: 10),
                      ],
                      if (listing.rooms != null) ...[
                        _StatCard(
                          icon: IconsaxPlusLinear.building_3,
                          value:
                              listing.rooms! == listing.rooms!.roundToDouble()
                              ? '${listing.rooms!.toInt()}'
                              : '${listing.rooms}',
                          unit: l.roomsLabel,
                        ),
                        const SizedBox(width: 10),
                      ],
                      if (listing.bathrooms != null)
                        _StatCard(
                          icon: IconsaxPlusLinear.courthouse,
                          value: '${listing.bathrooms}',
                          unit: l.bathroomsUnit,
                        ),
                    ],
                  ),
                ),

              _buildAgentSection(l, listing),

              if ((listing.description ?? '').trim().isNotEmpty)
                _buildSection(l.aboutThisProperty, listing.description!),

              _buildSpecsGrid(l, listing),

              if (listing.latitude != null && listing.longitude != null)
                _buildMapSection(listing),

              if (hood != null &&
                  (listing.neighborhoodDescription ?? '').trim().isNotEmpty)
                _buildNeighborhoodSection(
                  l,
                  hood,
                  listing.neighborhoodDescription!,
                ),

              _buildNearbyProperties(l, hood),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroImage(Listing listing, List<String> photos) {
    return SizedBox(
      height: 260,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // The photograph, or the same gradient as a fallback when the
          // listing has none.
          Stack(
            fit: StackFit.expand,
            children: [
              NetworkPhoto(
                url: photos.isEmpty
                    ? null
                    : photos[_selectedThumb.clamp(0, photos.length - 1)],
                icon: IconsaxPlusBold.home_2,
                iconSize: 80,
              ),
              Stack(
                children: [
                  // Dark bottom gradient
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 1.0],
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.4),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Back button (top-left)
          Positioned(
            left: 12,
            top: 51,
            child: _CircleButton(
              icon: IconsaxPlusLinear.arrow_left,
              onTap: () => context.pop(),
            ),
          ),

          // Heart button (top-right) — it was a drawing of a heart that did
          // nothing; it saves the listing now.
          Positioned(
            right: 12,
            top: 51,
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
                  id: listing.id,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────
  // Image thumbnail row
  // ───────────────────────────────────────────────
  Widget _buildThumbnailRow(List<String> photos) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(photos.length, (index) {
          final isSelected = _selectedThumb == index;
          return Padding(
            padding: EdgeInsets.only(right: index < photos.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () => setState(() => _selectedThumb = index),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: isSelected
                      ? Border.all(color: const Color(0xFF123A72), width: 2)
                      : null,
                ),
                child: NetworkPhoto(
                  url: photos[index],
                  width: 66,
                  height: 44,
                  radius: BorderRadius.circular(4),
                  icon: IconsaxPlusBold.image,
                  iconSize: 18,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ───────────────────────────────────────────────
  // Agent section
  // ───────────────────────────────────────────────
  /// Whoever to call about the listing.
  ///
  /// A listing can arrive with no agent and no contact at all — the client
  /// enters ones that come in by telephone — so this is nothing at all rather
  /// than an invented name.
  Widget _buildAgentSection(L l, Listing listing) {
    final name = listing.contactDisplayName;
    final phone = listing.contactDisplayPhone;
    if (name == null && phone == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.agent,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                NetworkPhoto(
                  url: listing.agentPhotoUrl,
                  width: 40,
                  height: 40,
                  radius: BorderRadius.circular(20),
                  icon: IconsaxPlusBold.user,
                  iconSize: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name ?? phone!,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      if (listing.agentAgency != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          listing.agentAgency!,
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 12,
                            color: const Color(0xFF6D6D6D),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (phone != null)
                  GestureDetector(
                    onTap: () => launchPhone(phone),
                    child: Container(
                      height: 37,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF123A72),
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: Center(
                        child: Text(
                          l.contact,
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
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────
  // Generic section: title + body text
  // ───────────────────────────────────────────────
  Widget _buildSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF3D3D3D),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────
  // Property Specifications 2×2 grid
  // ───────────────────────────────────────────────
  /// Only the features the listing actually has.
  ///
  /// The mock listed Balcony / Parking / Lift / Protected room and answered
  /// "Yes" to all four on every property. These are the booleans from the
  /// row, and a listing with none of them shows no section.
  Widget _buildSpecsGrid(L l, Listing listing) {
    final specs = <_Spec>[
      if (listing.hasBalcony)
        _Spec(l.amenityBalcony, IconsaxPlusBold.element_3),
      if (listing.hasParking) _Spec(l.amenityParking, IconsaxPlusBold.car),
      if (listing.hasElevator)
        _Spec(l.amenityElevator, IconsaxPlusBold.arrow_3),
      if (listing.hasStorage) _Spec(l.amenityStorage, IconsaxPlusBold.box_1),
      if (listing.hasMamad) _Spec(l.amenityMamad, IconsaxPlusBold.shield_tick),
    ];
    if (specs.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.propertySpecs,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 12),
          // Two to a row, however many there are — the fixed 2×2 grid broke
          // as soon as the count was not exactly four.
          for (var i = 0; i < specs.length; i += 2)
            Padding(
              padding: EdgeInsets.only(bottom: i + 2 < specs.length ? 12 : 0),
              child: Row(
                children: [
                  Expanded(child: _SpecCard(spec: specs[i])),
                  const SizedBox(width: 12),
                  if (i + 1 < specs.length)
                    Expanded(child: _SpecCard(spec: specs[i + 1]))
                  else
                    const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────
  // Where You'll Be (map preview)
  // ───────────────────────────────────────────────
  /// Opens the listing's coordinates in the phone's maps app.
  static Future<void> _openInMaps(Listing listing) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query='
      '${listing.latitude},${listing.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildMapSection(Listing listing) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            L.of(context).whereYoullBe,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 230,
              width: double.infinity,
              child: Stack(
                children: [
                  // The real map. A flat pastel box with a faint glyph
                  // stood here, while `flutter_map` was already used
                  // elsewhere in this same feature and this section only
                  // renders when the listing has coordinates.
                  IgnorePointer(
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(
                          listing.latitude!,
                          listing.longitude!,
                        ),
                        initialZoom: 15.5,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.modiin4u.app',
                        ),
                      ],
                    ),
                  ),

                  // Pin marker
                  Center(
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 2.74,
                            offset: const Offset(0, 2.74),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            color: Color(0xFF006BF6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            IconsaxPlusBold.home_2,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Opens the address in the phone's maps app. It had no
                  // handler at all, and the map behind it is wrapped in
                  // IgnorePointer, so the location could not be opened.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 17,
                    child: Center(
                      child: GestureDetector(
                        onTap: () => _openInMaps(listing),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                IconsaxPlusLinear.map_1,
                                size: 16,
                                color: Color(0xFF0A1230),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                L.of(context).viewOnMap,
                                style: TextStyle(
                                  fontFamily: AppFonts.inter,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF0A1230),
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
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────
  // About Moriah (neighborhood) with fade + Read More
  // ───────────────────────────────────────────────
  Widget _buildNeighborhoodSection(L l, String name, String about) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.aboutNeighborhood(name),
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    about,
                    maxLines: _aboutExpanded ? null : 5,
                    overflow: _aboutExpanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      color: const Color(0xFF3D3D3D),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
              if (!_aboutExpanded)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 60,
                  child: IgnorePointer(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x00FFFFFF), Color(0xFFFFFFFF)],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Only worth offering when there is more to show.
          if (about.length > 240)
            Center(
              child: GestureDetector(
                onTap: () => setState(() => _aboutExpanded = !_aboutExpanded),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFF123A72)),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Text(
                    _aboutExpanded ? l.showLess : l.readMore,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF123A72),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────
  // Properties in Moriah
  // ───────────────────────────────────────────────
  /// Other listings in the same neighbourhood. Three invented ones used to
  /// sit here; the strip is left out entirely when there are none.
  Widget _buildNearbyProperties(L l, String? hood) {
    final nearby = ref
        .watch(nearbyListingsProvider(widget.listingId))
        .valueOrNull;
    if (nearby == null || nearby.isEmpty || hood == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.propertiesIn(hood),
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < nearby.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i < nearby.length - 1 ? 16 : 0),
              child: _NearbyListingCard(
                listing: nearby[i],
                onTap: () => context.push('/listing/${nearby[i].id}'),
              ),
            ),
        ],
      ),
    );
  }
}

/// The white circle behind the back arrow.
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF3D3D3D)),
      ),
    );
  }
}

/// Opens the dialler. A number that cannot be dialled is left alone rather
/// than reported, because there is nothing the reader could do about it.
Future<void> launchPhone(String phone) async {
  final uri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
  if (await canLaunchUrl(uri)) await launchUrl(uri);
}

// ═══════════════════════════════════════════════
// Stat card (area / bedrooms / bathrooms)
// ═══════════════════════════════════════════════
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 77,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE7E7E7)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 20, color: const Color(0xFF4F4F4F)),
            Row(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF3D3D3D),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Spec data model
// ═══════════════════════════════════════════════
class _Spec {
  final String name;
  final IconData icon;

  /// There is no value beside the name any more. The card used to read
  /// "Balcony / Yes", and it read "Yes" whether or not the flat had one.
  const _Spec(this.name, this.icon);
}

// ═══════════════════════════════════════════════
// Spec card (Balcony/Parking/Elevator/Protected Space)
// ═══════════════════════════════════════════════
class _SpecCard extends StatelessWidget {
  final _Spec spec;
  const _SpecCard({required this.spec});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 124,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE7E7E7)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(spec.icon, size: 32, color: const Color(0xFF123A72)),
          const SizedBox(height: 12),
          Text(
            spec.name,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Nearby listing card
// ═══════════════════════════════════════════════
class _NearbyListingCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback? onTap;
  const _NearbyListingCard({required this.listing, this.onTap});

  /// 3.5 reads as "3.5"; 4.0 reads as "4" — the card printed "4.0 Rooms".
  static String _roomsText(double v) =>
      v == v.roundToDouble() ? '${v.toInt()}' : '$v';

  String _priceText(L l) {
    final p = listing.effectivePrice;
    if (p == null) return '';
    return listing.kind == ListingKind.rent
        ? l.pricePerMonthValue(formatShekels(p))
        : formatShekels(p);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          SizedBox(
            height: 200,
            width: double.infinity,
            child: Stack(
              children: [
                NetworkPhoto(
                  url: listing.coverUrl,
                  width: double.infinity,
                  height: 200,
                  radius: BorderRadius.circular(12),
                  icon: IconsaxPlusBold.home_2,
                  iconSize: 40,
                ),

                // Heart button
                Positioned(
                  right: 12,
                  top: 12,
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
                        id: listing.id,
                        color: const Color(0xFF123A72),
                      ),
                    ),
                  ),
                ),

                // New badge — anything posted in the last fortnight.
                if (DateTime.now().difference(listing.createdAt).inDays < 14)
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF17A9D0),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        l.newBadge,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                // Via Broker badge
                if (listing.isBroker)
                  Positioned(
                    left: 12,
                    bottom: 12,
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
                        l.viaBroker,
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
          ),

          // Details
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Price + FOR SALE
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _priceText(l),
                      style: TextStyle(
                        fontFamily: AppFonts.rubik,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0A1230),
                      ),
                    ),
                    Text(
                      listing.kind == ListingKind.rent
                          ? l.forRentBadge
                          : l.forSaleBadge,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF17A9D0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Address
                Row(
                  children: [
                    const Icon(
                      IconsaxPlusBold.location,
                      size: 16,
                      color: Color(0xFF17A9D0),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        listing.address ?? listing.neighborhoodName ?? '',
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF5F5E5A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Area / rooms / floor — only the ones this listing has.
                Row(
                  children: [
                    if (listing.sqm != null) ...[
                      _DetailChip(
                        icon: IconsaxPlusLinear.maximize_3,
                        text: '${listing.sqm} ${l.sqmUnit}',
                      ),
                      const SizedBox(width: 31),
                    ],
                    if (listing.rooms != null) ...[
                      _DetailChip(
                        icon: IconsaxPlusLinear.building_3,
                        text: '${_roomsText(listing.rooms!)} ${l.roomsLabel}',
                      ),
                      const SizedBox(width: 31),
                    ],
                    if (listing.floor != null)
                      _DetailChip(
                        icon: IconsaxPlusLinear.building_4,
                        text: l.floorLabel('${listing.floor}'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Detail chip (area / rooms / floor) for nearby cards
// ═══════════════════════════════════════════════
class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
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
            fontWeight: FontWeight.w400,
            color: const Color(0xFF3D3D3D),
          ),
        ),
      ],
    );
  }
}
