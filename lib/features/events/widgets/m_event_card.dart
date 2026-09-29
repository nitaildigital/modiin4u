import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../favorites/repositories/favorite_repository.dart';
import '../../favorites/widgets/favorite_button.dart';
import '../models/event.dart';
import '../models/event_labels.dart';
import '../../../l10n/app_localizations.dart';

/// Whether the app is showing Hebrew, from the l10n locale.
bool mEventsIsHebrew(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'he';

/// The phone event card (Figma "Events" › card, 361 × 348): the 200px photo
/// with its date badge and heart, then title, category, time and place, and
/// price with the interest count.
///
/// Every value is the event's own. The category line is the event's primary
/// category and is left out when it has none; the interest count only shows
/// once somebody has said they are coming.
class MEventCard extends StatelessWidget {
  final Event event;
  final String? category;
  const MEventCard({super.key, required this.event, this.category});

  static const _grey = AppColors.grayText;

  @override
  Widget build(BuildContext context) {
    final labels = EventLabels(mEventsIsHebrew(context));
    final start = event.startDate;
    final time = labels.startTime(event);
    final venue = labels.venue(event);
    final price = labels.price(event);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/event/${event.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                Positioned.fill(
                  child: NetworkPhoto(
                    url: event.imageUrl,
                    radius: BorderRadius.circular(12),
                    icon: IconsaxPlusBold.calendar_1,
                    iconSize: 40,
                  ),
                ),
                if (start != null)
                  PositionedDirectional(
                    start: 12,
                    bottom: 12,
                    child: Container(
                      width: 57,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            labels.shortMonth(start),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.midBlue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${start.day}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                PositionedDirectional(
                  end: 12,
                  top: 12,
                  child: FavoriteButton(
                    kind: FavoriteKind.event,
                    id: event.id,
                    size: 40,
                    iconSize: 23,
                    color: AppColors.midBlue,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppFonts.nunito,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
                if (category != null && category!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    category!,
                    style: const TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      color: _grey,
                    ),
                  ),
                ],
                if (time != null || venue != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (time != null) ...[
                        _icon('assets/web/events/card_clock.svg', 13, 13),
                        const SizedBox(width: 8),
                        Text(time, style: _meta),
                        const SizedBox(width: 12),
                      ],
                      if (venue != null) ...[
                        _icon('assets/web/events/card_pin.svg', 12, 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            venue,
                            style: _meta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                if (price != null || event.rsvpCount > 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (price != null)
                        Text(
                          price,
                          style: TextStyle(
                            fontFamily: AppFonts.nunito,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: event.isFree
                                ? AppColors.midBlue
                                : AppColors.navy,
                          ),
                        ),
                      const Spacer(),
                      if (event.rsvpCount > 0) ...[
                        SvgPicture.asset(
                          'assets/web/events/card_star.svg',
                          width: 16,
                          height: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          L.of(context).eventInterestedCount(event.rsvpCount),
                          style: const TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF3D3D3D),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _meta = TextStyle(
    fontFamily: AppFonts.inter,
    fontSize: 14,
    color: _grey,
  );

  static Widget _icon(String asset, double w, double h) => SizedBox(
    width: 16,
    height: 16,
    child: Center(child: SvgPicture.asset(asset, width: w, height: h)),
  );
}
