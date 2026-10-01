import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../../shared/widgets/app_map.dart';
import '../../map/data/map_pois.dart' show modiinCenter;
import '../providers/parking_providers.dart';

// The pieces the phone and desktop parking screens share: the map of the
// lots and a lot's card. Each screen lays them out its own way.

const _kBorder = Color(0xFFE7E7E7);
const _kGreyText = Color(0xFF5F5E5A);
const _kHeading = Color(0xFF1C1C1E);
const _kIconGrey = Color(0xFF6D6D6D);

/// The city map's parking pin, so a lot looks the same here as on /map.
const _kPin = 'assets/web/map/pin_parking.svg';

/// The lots as pins, the chosen one lifted — on Google's map (AppMap), in
/// the app and on the website alike.
class ParkingMap extends StatelessWidget {
  final List<ParkingLot> lots;
  final String? selectedId;
  final ValueChanged<ParkingLot?> onSelect;
  final AppMapController? controller;

  /// The website's page, which scrolls: the wheel moves the page, not the
  /// map, as on the listing page.
  final bool websiteTiles;

  const ParkingMap({
    super.key,
    required this.lots,
    required this.onSelect,
    this.selectedId,
    this.controller,
    this.websiteTiles = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppMap(
      controller: controller,
      center: lots.length == 1 ? lots.first.position : modiinCenter,
      zoom: lots.length == 1 ? 16 : 14,
      fitPins: true,
      minZoom: 11,
      maxZoom: 18,
      scrollWheelZoom: !websiteTiles,
      selectedId: selectedId,
      onSelect: (id) => onSelect(
        id == null ? null : lots.where((l) => l.id == id).firstOrNull,
      ),
      pins: [
        for (final lot in lots)
          AppMapPin(id: lot.id, position: lot.position, asset: _kPin),
      ],
    );
  }
}

/// One lot: its name, where it is, and whatever else the client entered —
/// hours, price, spaces, his note — each line only when he filled it in.
class ParkingLotCard extends StatelessWidget {
  final ParkingLot lot;
  final L l;
  final bool english;
  final bool selected;
  final VoidCallback? onTap;

  const ParkingLotCard({
    super.key,
    required this.lot,
    required this.l,
    required this.english,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final small = TextStyle(
      fontFamily: AppFonts.inter,
      fontSize: 13,
      color: _kGreyText,
      height: 1.35,
    );

    return MouseRegion(
      cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.midBlue : _kBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NetworkPhoto(
                    url: lot.imageUrl,
                    width: 48,
                    height: 48,
                    radius: BorderRadius.circular(12),
                    gradient: [
                      AppColors.midBlue.withValues(alpha: 0.08),
                      AppColors.midBlue.withValues(alpha: 0.04),
                    ],
                    icon: IconsaxPlusLinear.car,
                    iconSize: 22,
                    iconColor: AppColors.midBlue,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ClientText(
                          lot.displayName(english: english),
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _kHeading,
                            height: 1.3,
                          ),
                        ),
                        if (lot.address != null) ...[
                          const SizedBox(height: 4),
                          _ClientText(lot.address!, style: small),
                        ],
                      ],
                    ),
                  ),
                  // Only when the client said so; a lot he said nothing
                  // about is not marked either way.
                  if (lot.isFree == true) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        l.free,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (lot.hours != null ||
                  lot.priceNote != null ||
                  lot.capacity != null) ...[
                const SizedBox(height: 12),
                if (lot.hours != null)
                  _InfoLine(IconsaxPlusLinear.clock, lot.hours!, small),
                if (lot.priceNote != null)
                  _InfoLine(IconsaxPlusLinear.ticket, lot.priceNote!, small),
                if (lot.capacity != null)
                  _InfoLine(
                    IconsaxPlusLinear.car,
                    l.parkingSpaces(lot.capacity!),
                    small,
                  ),
              ],
              if (lot.notes != null) ...[
                const SizedBox(height: 8),
                _ClientText(lot.notes!, style: small),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton.icon(
                  onPressed: () => launchUrl(lot.wazeUri),
                  icon: const Icon(IconsaxPlusLinear.routing_2, size: 16),
                  label: Text(
                    l.getDirections,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.midBlue,
                    side: const BorderSide(color: AppColors.midBlue),
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(60),
                    ),
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

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final TextStyle style;
  const _InfoLine(this.icon, this.text, this.style);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 15, color: _kIconGrey),
          ),
          const SizedBox(width: 8),
          Expanded(child: _ClientText(text, style: style)),
        ],
      ),
    );
  }
}

/// Text the client typed, set in its own direction but on the screen's side.
///
/// He writes in Hebrew, and the English app shows it as he wrote it; laid
/// out left to right, "הערה: כניסה מהצד" came out with its colon at the
/// wrong end. And "08:00–19:00" has no letters to take a direction from, so
/// in Hebrew it read back to front as "19:00–08:00". Each line takes the
/// direction of its first letter, as a browser's dir="auto" does, and
/// left to right when it has none.
class _ClientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  const _ClientText(this.text, {required this.style});

  static final _firstLetter = RegExp(r'[A-Za-z\u0590-\u05FF]');

  @override
  Widget build(BuildContext context) {
    final first = _firstLetter.firstMatch(text)?.group(0);
    final hebrew = first != null && first.codeUnitAt(0) >= 0x0590;
    final screenRtl = Directionality.of(context) == TextDirection.rtl;
    return Text(
      text,
      style: style,
      textDirection: hebrew ? TextDirection.rtl : TextDirection.ltr,
      // Start of the screen's reading direction, whatever the text's own.
      textAlign: screenRtl ? TextAlign.right : TextAlign.left,
    );
  }
}

/// What the screens show instead of the list: nothing entered yet, or the
/// read failed.
class ParkingMessage extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? action;
  const ParkingMessage({
    super.key,
    required this.icon,
    required this.text,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: AppColors.midBlue.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _kHeading,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    );
  }
}

/// The credit for the car parks' data, under the list.
class ParkingDataCredit extends StatelessWidget {
  final String text;
  const ParkingDataCredit({super.key, required this.text});

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(fontFamily: AppFonts.inter, fontSize: 12, color: _kGreyText),
  );
}
