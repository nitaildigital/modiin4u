import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_map.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../../auth/widgets/m_account_widgets.dart' show MBackArrow;
import '../providers/parking_providers.dart';
import '../services/google_place.dart';
import '../widgets/parking_widgets.dart' show showNavigationChoice;

const _kPin = 'assets/web/map/pin_parking.svg';
const _kBorder = Color(0xFFE7E7E7);
const _kGrey = Color(0xFF5F5E5A);
const _kHeading = Color(0xFF1C1C1E);

/// One car park: what Google Maps knows about it, what the client entered,
/// a small map, and the way there.
///
/// The client (1 Oct) asked for whatever Google has, and left what a tap
/// does to us. For a car park linked to Google (`google_place_id`), the page
/// fetches Google's name, address, opening hours, rating, photos, payment
/// methods, phone and website when it opens, and says they are from Google
/// Maps. Anything the client entered in the panel — hours, price, spaces,
/// notes — is shown beside it. A car park Google does not list shows what we
/// have. Navigation offers Waze or Google Maps.
class ParkingDetailScreen extends ConsumerWidget {
  final String lotId;
  const ParkingDetailScreen({super.key, required this.lotId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, c) => kIsWeb && c.maxWidth > 1100
          ? _WebParkingDetail(lotId: lotId)
          : _PhoneParkingDetail(lotId: lotId),
    );
  }
}

class _PhoneParkingDetail extends ConsumerWidget {
  final String lotId;
  const _PhoneParkingDetail({required this.lotId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final english = Localizations.localeOf(context).languageCode == 'en';
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        foregroundColor: _kHeading,
        // Opened from a link there is nothing to go back to; the arrow then
        // leads to the car parks.
        leading: Center(
          child: MBackArrow(
            color: _kHeading,
            onTap: () => context.canPop() ? context.pop() : context.go('/parking'),
          ),
        ),
        leadingWidth: 56,
        title: Text(
          l.parkingInModiin,
          style: TextStyle(fontFamily: AppFonts.nunito, fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      // Top, not centre: a short page sat in the middle of the screen.
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            child: _ParkingDetailBody(lotId: lotId, l: l, english: english),
          ),
        ),
      ),
    );
  }
}

class _WebParkingDetail extends ConsumerStatefulWidget {
  final String lotId;
  const _WebParkingDetail({required this.lotId});

  @override
  ConsumerState<_WebParkingDetail> createState() => _WebParkingDetailState();
}

class _WebParkingDetailState extends ConsumerState<_WebParkingDetail>
    with WebLanguageState<_WebParkingDetail> {
  static final _en = lookupL(const Locale('en'));
  static final _he = lookupL(const Locale('he'));

  @override
  Widget build(BuildContext context) {
    final hebrew = webIsHebrew.value;
    return Directionality(
      textDirection: hebrew ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            WebNavbar(isHebrew: hebrew, activeId: null),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 48),
                    Center(
                      child: SizedBox(
                        width: 760,
                        child: _ParkingDetailBody(
                          lotId: widget.lotId,
                          l: hebrew ? _he : _en,
                          english: !hebrew,
                          showBack: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 100),
                    WebFooter(isHebrew: hebrew),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParkingDetailBody extends ConsumerWidget {
  final String lotId;
  final L l;
  final bool english;
  final bool showBack;
  const _ParkingDetailBody({
    required this.lotId,
    required this.l,
    required this.english,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lots = ref.watch(parkingLotsProvider);
    if (lots.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final lot = (lots.valueOrNull ?? const <ParkingLot>[]).where((p) => p.id == lotId).firstOrNull;
    if (lot == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Center(child: Text(l.parkingNotFound, style: _text(15, color: _kGrey))),
      );
    }
    final placeId = lot.googlePlaceId;
    final googleAsync = placeId == null
        ? const AsyncValue<GooglePlaceDetails?>.data(null)
        : ref.watch(googleParkingDetailsProvider((placeId: placeId, language: english ? 'en' : 'he')));
    final g = googleAsync.valueOrNull;

    final title = g?.name ?? lot.displayName(english: english);
    final address = g?.address ?? lot.address;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showBack) ...[
          TextButton.icon(
            onPressed: () => context.canPop() ? context.pop() : context.go('/parking'),
            icon: Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? IconsaxPlusLinear.arrow_right_3
                  : IconsaxPlusLinear.arrow_left_2,
              size: 18,
            ),
            label: Text(l.parkingInModiin),
            style: TextButton.styleFrom(foregroundColor: AppColors.midBlue),
          ),
          const SizedBox(height: 12),
        ],
        if (g != null && g.photos.isNotEmpty) ...[
          _Photos(photos: g.photos, l: l),
          const SizedBox(height: 16),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(title, style: _text(22, weight: FontWeight.w700, color: _kHeading)),
            ),
            if (lot.isFree != null) ...[
              const SizedBox(width: 8),
              _Tag(free: lot.isFree!, l: l),
            ],
          ],
        ),
        if (address != null) ...[
          const SizedBox(height: 6),
          Text(address, style: _text(14, color: _kGrey)),
        ],
        if (g?.rating != null && g!.ratingCount > 0) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 18, color: Color(0xFFFAB005)),
              const SizedBox(width: 4),
              Text(
                l.parkingGoogleRating(g.rating!.toStringAsFixed(1), g.ratingCount),
                style: _text(13, color: _kGrey),
              ),
            ],
          ),
        ],
        if (placeId != null && googleAsync.isLoading) ...[
          const SizedBox(height: 16),
          const LinearProgressIndicator(minHeight: 2),
        ],
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => showNavigationChoice(context, lot, l),
                icon: const Icon(IconsaxPlusLinear.routing_2, size: 18),
                label: Text(l.getDirections),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.midBlue,
                  minimumSize: const Size(0, 46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            if (g?.phone != null) ...[
              const SizedBox(width: 8),
              _IconButton(IconsaxPlusLinear.call, () => launchUrl(Uri.parse('tel:${g!.phone}'))),
            ],
            if (g?.website != null) ...[
              const SizedBox(width: 8),
              _IconButton(
                IconsaxPlusLinear.global,
                () => launchUrl(Uri.parse(g!.website!), mode: LaunchMode.externalApplication),
              ),
            ],
          ],
        ),
        const SizedBox(height: 20),
        if ((g?.hours ?? const []).isNotEmpty)
          _Section(
            icon: IconsaxPlusLinear.clock,
            title: l.openingHours,
            children: [for (final h in g!.hours) Text(h, style: _text(13, color: _kGrey))],
          )
        else if (lot.hours != null)
          _Section(
            icon: IconsaxPlusLinear.clock,
            title: l.openingHours,
            children: [Text(lot.hours!, style: _text(13, color: _kGrey))],
          ),
        if (g != null && g.hasPayment)
          _Section(
            icon: IconsaxPlusLinear.card,
            title: l.parkingPayment,
            children: [
              Text(
                [
                  if (g.cashOnly == true) l.parkingPayCash,
                  if (g.acceptsCards == true) l.parkingPayCards,
                  if (g.acceptsDebit == true) l.parkingPayDebit,
                  if (g.acceptsNfc == true) l.parkingPayNfc,
                ].join(' · '),
                style: _text(13, color: _kGrey),
              ),
            ],
          ),
        if (lot.priceNote != null)
          _Section(
            icon: IconsaxPlusLinear.ticket,
            title: l.parkingPayment,
            children: [Text(lot.priceNote!, style: _text(13, color: _kGrey))],
          ),
        if (lot.capacity != null)
          _Section(
            icon: IconsaxPlusLinear.car,
            title: l.parkingSpaces(lot.capacity!),
            children: const [],
          ),
        if (lot.notes != null)
          _Section(
            icon: IconsaxPlusLinear.note_1,
            title: lot.notes!,
            children: const [],
          ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 200,
            child: IgnorePointer(
              child: AppMap(
                center: lot.position,
                zoom: 16,
                interactive: false,
                pins: [AppMapPin(id: lot.id, position: lot.position, asset: _kPin)],
              ),
            ),
          ),
        ),
        if (placeId != null) ...[
          const SizedBox(height: 14),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 6,
            children: [
              // Google's terms: data from Places is shown with Google's mark.
              Image.asset('assets/web/common/google_logo.png', height: 18),
              Text(l.parkingFromGoogle, style: _text(12, color: _kGrey)),
              if (g?.mapsUri != null)
                InkWell(
                  onTap: () => launchUrl(Uri.parse(g!.mapsUri!), mode: LaunchMode.externalApplication),
                  child: Text(
                    l.parkingViewOnGoogle,
                    style: _text(12, color: AppColors.midBlue, weight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

TextStyle _text(double size, {FontWeight weight = FontWeight.w400, Color color = _kHeading}) =>
    TextStyle(fontFamily: AppFonts.inter, fontSize: size, fontWeight: weight, color: color, height: 1.4);

class _Photos extends StatelessWidget {
  final List<GooglePhoto> photos;
  final L l;
  const _Photos({required this.photos, required this.l});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final p = photos[i];
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: photos.length == 1 ? 398 : 300,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    googlePhotoUri(p).toString(),
                    headers: kIsWeb ? null : googlePlacesHeaders,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(color: const Color(0xFFF0F2F5)),
                  ),
                  // Who took it, as Google requires for its photos.
                  if (p.authors.isNotEmpty)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        color: Colors.black.withValues(alpha: 0.45),
                        child: Text(
                          l.parkingPhotoBy(p.authors.join(', ')),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _text(11, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final bool free;
  final L l;
  const _Tag({required this.free, required this.l});

  @override
  Widget build(BuildContext context) {
    final color = free ? AppColors.success : const Color(0xFFB26A00);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(free ? l.free : l.parkingPaid, style: _text(12, weight: FontWeight.w600, color: color)),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconButton(this.icon, this.onTap);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 46,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: AppColors.midBlue,
          side: const BorderSide(color: AppColors.midBlue),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;
  const _Section({required this.icon, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(border: Border.all(color: _kBorder), borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.turquoise),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _text(14, weight: FontWeight.w600)),
                if (children.isNotEmpty) ...[const SizedBox(height: 6), ...children],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
