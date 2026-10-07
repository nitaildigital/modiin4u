import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/app_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../favorites/repositories/favorite_repository.dart';
import '../../favorites/widgets/favorite_button.dart';
import '../models/business.dart';
import '../providers/business_providers.dart';

/// One business on a phone's category page — the mobile "Bars" frame's card.
///
/// A 200px photograph with the heart at its top corner and "Open now" at its
/// foot, then the name, the kind of place, the address and the rating. The
/// frame's "1.2 km" needs the device's location and is left out; "Open now"
/// is drawn only for a business with hours on record.
class MBusinessPlaceCard extends ConsumerWidget {
  final Business business;

  const MBusinessPlaceCard({super.key, required this.business});

  static const _navy = Color(0xFF0A1230);
  static const _grey = Color(0xFF5F5E5A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kind = businessKind(
      business,
      ref.watch(businessPrimaryCategoryProvider).valueOrNull,
    );

    return GestureDetector(
      onTap: () => context.push('/business/${business.id}'),
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                Positioned.fill(
                  child: NetworkPhoto(
                    url: business.imageUrl ?? business.logoUrl,
                    radius: BorderRadius.circular(12),
                    icon: IconsaxPlusBold.shop,
                    iconSize: 40,
                  ),
                ),
                PositionedDirectional(
                  end: 12,
                  top: 12,
                  child: FavoriteButton(
                    kind: FavoriteKind.business,
                    id: business.id,
                    size: 40,
                    iconSize: 23,
                    color: const Color(0xFF123A72),
                  ),
                ),
                if (business.hours.isNotEmpty && business.isOpenNow)
                  PositionedDirectional(
                    start: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDF6E2),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        L.of(context).openNowBadge,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1E9E3E),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            business.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              // "Avenir Next Rounded Pro Demi" in the frame.
              fontFamily: AppFonts.nunito,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _navy,
            ),
          ),
          if (kind.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              kind,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                color: _grey,
              ),
            ),
          ],
          if (business.address.isNotEmpty) ...[
            const SizedBox(height: 12),
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
                    business.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      color: _grey,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          // Nobody has reviewed it: say so, rather than a star beside 0.0.
          if (business.reviewCount == 0)
            Text(
              L.of(context).notRatedYet,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                color: const Color(0xFF6D6D6D),
              ),
            )
          else
            Row(
              children: [
                const Icon(
                  IconsaxPlusBold.star_1,
                  size: 16,
                  color: Color(0xFFFFC107),
                ),
                const SizedBox(width: 8),
                Text(
                  business.rating.toStringAsFixed(1),
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${business.reviewCount})',
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 14,
                    color: const Color(0xFF6D6D6D),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
