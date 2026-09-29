import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/network_photo.dart';
import '../models/offer.dart';

// ═══════════════════════════════════════════════════════════
// Phone deal cards — Figma mobile "Deals" (631:3902) and the "More Deals
// from …" row of "Deal Details" (806:10899).
//
// Everything printed on them is the offer's own row: the badge is the
// discount its title states (`Offer.badge`), the clock counts down to its
// `end_at`, "Residents Only" is its audience. A card with no end date shows
// no clock, and one whose title states no discount shows no badge.
// ═══════════════════════════════════════════════════════════

const kMDealsIcons = 'assets/web/deals';
const kMDealsNavy = Color(0xFF0A1230);
const kMDealsGrey = Color(0xFF5F5E5A);
const kMDealsMuted = Color(0xFF6D6D6D);
const kMDealsOrange = Color(0xFFFB7901);
const kMDealsLine = Color(0xFFE7E7E7);

TextStyle mDealsInter(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color color = Colors.black,
  double? height,
}) => TextStyle(
  fontFamily: AppFonts.inter,
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: height,
);

/// "Avenir Next Rounded Pro Demi" in the design.
TextStyle mDealsDisplay(double size, {Color color = kMDealsNavy, double? height}) =>
    TextStyle(
      fontFamily: AppFonts.nunito,
      fontSize: size,
      fontWeight: FontWeight.w600,
      color: color,
      height: height,
    );

bool mDealsIsHebrew(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'he';

/// Text the design adds that the app's string tables do not carry yet.
String mDealsT(BuildContext context, String en, String he) =>
    mDealsIsHebrew(context) ? he : en;

/// "2d : 14h" as the design prints it; in Hebrew, the app's own "2 ימים".
/// Null when the offer has no end date.
String? mDealTimeLeft(BuildContext context, Offer offer) {
  if (!mDealsIsHebrew(context)) return offer.timeLeftLabel(isHebrew: false);
  final left = offer.timeLeft;
  if (left == null) return null;
  if (left == Duration.zero) return offer.timeLeftLabel(isHebrew: true);
  final l = L.of(context);
  if (left.inDays >= 1) return l.daysShort(left.inDays);
  if (left.inHours >= 1) return l.hoursShort(left.inHours);
  return l.minutesShort(left.inMinutes);
}

/// The orange label on a deal's photograph.
class MDealBadge extends StatelessWidget {
  final String text;
  final double fontSize;
  const MDealBadge({super.key, required this.text, this.fontSize = 14});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: kMDealsOrange,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: mDealsInter(fontSize, weight: FontWeight.w600, color: Colors.white),
      ),
    );
  }
}

/// One deal in the list, 361 wide: the photograph with its badge and the
/// business's mark, the headline, the business, where it is, the time left,
/// "Residents Only", and the button.
class MDealCard extends StatelessWidget {
  final Offer offer;
  const MDealCard({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final badge = offer.badge;
    final business = offer.businessName;
    final place = offer.businessNeighborhood ?? offer.businessAddress;
    final timeLeft = mDealTimeLeft(context, offer);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/deal/${offer.id}'),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 200,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: NetworkPhoto(
                      url: offer.imageUrl ?? offer.businessCoverUrl,
                      radius: BorderRadius.circular(12),
                      icon: IconsaxPlusBold.discount_shape,
                      iconSize: 40,
                    ),
                  ),
                  if (offer.businessLogoUrl != null)
                    PositionedDirectional(
                      start: 12,
                      top: 141,
                      child: Container(
                        width: 47,
                        height: 47,
                        padding: const EdgeInsets.all(2.34),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: NetworkPhoto(
                          url: offer.businessLogoUrl,
                          radius: BorderRadius.circular(22),
                          icon: IconsaxPlusBold.shop,
                          iconSize: 18,
                        ),
                      ),
                    ),
                  if (badge != null)
                    PositionedDirectional(
                      start: 12,
                      top: 12,
                      child: MDealBadge(text: badge),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(offer.name, style: mDealsDisplay(20)),
            if (business != null) ...[
              const SizedBox(height: 8),
              Text(business, style: mDealsInter(14, color: kMDealsGrey)),
            ],
            if (place != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: Center(
                      child: SvgPicture.asset('assets/icons/m_deals_pin.svg', width: 12, height: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      place,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: mDealsInter(14, color: kMDealsGrey),
                    ),
                  ),
                ],
              ),
            ],
            if (timeLeft != null || offer.isResidentsOnly) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (timeLeft != null) ...[
                    SvgPicture.asset('$kMDealsIcons/card_clock.svg', width: 16, height: 16),
                    const SizedBox(width: 8),
                    Text(timeLeft, style: mDealsInter(14, weight: FontWeight.w500)),
                    const SizedBox(width: 8),
                    Text(l.timeLeft, style: mDealsInter(14, color: kMDealsMuted)),
                  ],
                  const Spacer(),
                  if (offer.isResidentsOnly) ...[
                    SvgPicture.asset('$kMDealsIcons/card_lock.svg', width: 16, height: 16),
                    const SizedBox(width: 8),
                    Text(
                      l.residentsOnly,
                      style: mDealsInter(14, weight: FontWeight.w500, color: kMDealsOrange),
                    ),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 20),
            Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.midBlue,
                borderRadius: BorderRadius.circular(60),
              ),
              child: Text(
                l.viewDeal,
                style: mDealsInter(14, weight: FontWeight.w500, color: Colors.white, height: 24 / 14),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// A 252-wide card in the "More Deals from …" row: photograph with its
/// badge, the headline and the time left.
class MDealMiniCard extends StatelessWidget {
  final Offer offer;
  const MDealMiniCard({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final badge = offer.badge;
    final timeLeft = mDealTimeLeft(context, offer);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/deal/${offer.id}'),
      child: SizedBox(
        width: 252,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 140,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: NetworkPhoto(
                      url: offer.imageUrl ?? offer.businessCoverUrl,
                      radius: BorderRadius.circular(8),
                      icon: IconsaxPlusBold.discount_shape,
                      iconSize: 32,
                    ),
                  ),
                  if (badge != null)
                    PositionedDirectional(
                      start: 10,
                      top: 10,
                      child: MDealBadge(text: badge, fontSize: 12),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              offer.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: mDealsDisplay(16),
            ),
            if (timeLeft != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  SvgPicture.asset('assets/icons/m_deals_clock14.svg', width: 14, height: 14),
                  const SizedBox(width: 6),
                  Text(timeLeft, style: mDealsInter(12)),
                  const SizedBox(width: 6),
                  Text(l.timeLeft, style: mDealsInter(12, color: kMDealsMuted)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
