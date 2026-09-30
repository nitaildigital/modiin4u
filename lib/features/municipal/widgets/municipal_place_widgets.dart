import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../models/municipal_place.dart';

const _kGrey = Color(0xFF6D6D6D);
const _kText = Color(0xFF1F1F1F);
const _kLine = Color(0xFFE7E7E7);

Uri _tel(String phone) => Uri.parse('tel:${phone.replaceAll(RegExp(r'[^\d+*#]'), '')}');

/// Waze to the place's point, or to its address when it has no point —
/// the same app the business page's Navigate opens.
Uri? _navigate(MunicipalPlace p) {
  if (p.hasLocation) {
    return Uri.parse(
      'https://waze.com/ul?ll=${p.latitude},${p.longitude}&navigate=yes',
    );
  }
  final address = p.address;
  if (address == null) return null;
  return Uri.parse(
    'https://waze.com/ul?q=${Uri.encodeComponent('$address, מודיעין')}&navigate=yes',
  );
}

/// One place: its name, address and notes, and Call / Navigate where it has
/// a phone or a location.
class MunicipalPlaceTile extends StatelessWidget {
  final MunicipalPlace place;
  final L l;
  final bool hebrew;
  final bool large;

  const MunicipalPlaceTile({
    super.key,
    required this.place,
    required this.l,
    required this.hebrew,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final nav = _navigate(place);
    final phone = place.phone;
    final body = large ? 15.0 : 13.0;
    return Container(
      padding: EdgeInsets.symmetric(vertical: large ? 16 : 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kLine)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.nameIn(hebrew),
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: large ? 17 : 15,
                    fontWeight: FontWeight.w600,
                    color: _kText,
                  ),
                ),
                if (place.address != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    place.address!,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: body,
                      color: _kGrey,
                    ),
                  ),
                ],
                if (place.notes != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    place.notes!,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: body,
                      color: _kGrey,
                      height: 1.35,
                    ),
                  ),
                ],
                if (phone != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    phone,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: body,
                      color: _kGrey,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (phone != null)
            _RoundAction(
              icon: IconsaxPlusLinear.call,
              tooltip: l.callAction,
              onTap: () => launchUrl(_tel(phone)),
            ),
          if (phone != null && nav != null) const SizedBox(width: 8),
          if (nav != null)
            _RoundAction(
              icon: IconsaxPlusLinear.routing_2,
              tooltip: l.getDirections,
              onTap: () => launchUrl(nav, mode: LaunchMode.externalApplication),
            ),
        ],
      ),
    );
  }
}

/// An emergency number: the service's name and the number large, and Call.
class EmergencyNumberTile extends StatelessWidget {
  final MunicipalPlace place;
  final L l;
  final bool hebrew;

  const EmergencyNumberTile({
    super.key,
    required this.place,
    required this.l,
    required this.hebrew,
  });

  @override
  Widget build(BuildContext context) {
    final phone = place.phone;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        border: Border.all(color: const Color(0xFFF5C2C2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.nameIn(hebrew),
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _kText,
                  ),
                ),
                if (place.notes != null)
                  Text(
                    place.notes!,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 12,
                      color: _kGrey,
                    ),
                  ),
              ],
            ),
          ),
          if (phone != null) ...[
            Text(
              phone,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFC62828),
              ),
            ),
            const SizedBox(width: 12),
            _RoundAction(
              icon: IconsaxPlusBold.call,
              tooltip: l.callAction,
              color: const Color(0xFFC62828),
              filled: true,
              onTap: () => launchUrl(_tel(phone)),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color color;
  final bool filled;

  const _RoundAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color = AppColors.turquoise,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: filled ? color : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: filled ? color : _kLine),
          ),
          child: Icon(icon, size: 18, color: filled ? Colors.white : color),
        ),
      ),
    );
  }
}

/// The places grouped under their category headings, in the pages' order.
List<Widget> municipalPlaceGroups({
  required List<MunicipalPlace> places,
  required L l,
  required bool hebrew,
  bool large = false,
}) {
  final out = <Widget>[];
  final multiple = places.map((p) => p.category).toSet().length > 1;
  for (final category in kMunicipalCategories.keys) {
    final inIt = places.where((p) => p.category == category).toList();
    if (inIt.isEmpty) continue;
    if (multiple) {
      final names = kMunicipalCategories[category]!;
      out.add(
        Padding(
          padding: EdgeInsets.only(top: out.isEmpty ? 0 : 24, bottom: 4),
          child: Text(
            '${hebrew ? names.he : names.en} (${inIt.length})',
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: large ? 20 : 16,
              fontWeight: FontWeight.w600,
              color: AppColors.midBlue,
            ),
          ),
        ),
      );
    }
    for (final p in inIt) {
      out.add(
        category == 'emergency'
            ? EmergencyNumberTile(place: p, l: l, hebrew: hebrew)
            : MunicipalPlaceTile(place: p, l: l, hebrew: hebrew, large: large),
      );
    }
  }
  return out;
}
