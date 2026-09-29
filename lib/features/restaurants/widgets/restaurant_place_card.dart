import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/network_photo.dart' show sizedPhotoUrl;
import '../providers/restaurant_providers.dart' show FoodKind;
import '../../../shared/widgets/web_contact_menu.dart';

// ═══════════════════════════════════════════════════════════
// Shared restaurant place card (web) — the design's place card, as
// the Restaurants page and its map draw it.
// ═══════════════════════════════════════════════════════════

const kRBorder = Color(0xFFE7E7E7);
const kRGreyText = Color(0xFF5F5E5A);
const kRBadgeBlue = Color(0xFF0033AC);
const kRestaurantGreen = Color(0xFF31AC4E);
const kCafeBlue = Color(0xFF006BF6);
const kBarRed = Color(0xFFCC0001);
const kHeartRed = Color(0xFFF92851);

class RestaurantPlace {
  final String name;

  /// The line under the name: "Restaurant", "Cafe", or "Restaurant · אסייתי"
  /// on the compact card, as drawn.
  final String type;
  final String address;
  final double rating;
  final int reviews;

  /// Decides the round badge on the photograph's edge.
  final FoodKind kind;

  /// The pill in the photograph's top corner — the cuisine the place is filed
  /// under. Null where it has none.
  final String? pill;
  final bool isKosher;

  /// Whether the directory records a delivery service. The design's second
  /// figure is a view count on the large card and a "30–40 min" wait on the
  /// small one; `businesses` holds neither, and this is what it does hold.
  final bool delivers;
  final Color imageBg;

  /// Remote photo; empty on places that have none, which keep the [imageBg]
  /// gradient.
  final String imageUrl;
  final String phone;

  /// The place's WhatsApp number, when it has one.
  final String? whatsapp;
  const RestaurantPlace({
    required this.name,
    required this.type,
    required this.address,
    required this.rating,
    required this.reviews,
    required this.kind,
    this.pill,
    this.isKosher = false,
    this.delivers = false,
    required this.imageBg,
    this.imageUrl = '',
    this.phone = '',
    this.whatsapp,
  });
}

class RestaurantCard extends StatefulWidget {
  final RestaurantPlace place;

  /// The 348-high card without the Contact button ("Most Loved", "Lunch
  /// Nearby"), rather than the 404-high one with it.
  final bool compact;
  final bool isHebrew;

  /// Show "Delivery" as the card's second figure where the place delivers.
  final bool showDelivery;
  final VoidCallback? onTap;
  const RestaurantCard({
    super.key,
    required this.place,
    required this.compact,
    required this.isHebrew,
    this.showDelivery = false,
    this.onTap,
  });

  @override
  State<RestaurantCard> createState() => RestaurantCardState();
}

const _kCardAsset = 'assets/web/home';
final _hebrew = RegExp(r'[֐-׿]');

/// Directory text, in its own direction, lined up with the page: a Hebrew
/// address on the English page reads right to left and still starts at the
/// left edge.
Widget placeText(BuildContext context, String text, TextStyle style) {
  final pageIsRtl = Directionality.of(context) == TextDirection.rtl;
  return Text(
    text,
    style: style,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    textDirection: _hebrew.hasMatch(text) ? TextDirection.rtl : TextDirection.ltr,
    textAlign: pageIsRtl ? TextAlign.right : TextAlign.left,
  );
}

class RestaurantCardState extends State<RestaurantCard> {
  bool _hovered = false;

  String _t(String en, String he) => widget.isHebrew ? he : en;

  /// The design's round badge for the kind of place: green for a
  /// restaurant, blue for a café, red for a bar.
  (String, String) get _badge => switch (widget.place.kind) {
    FoodKind.restaurant => ('card_badge_ring_green.svg', 'card_badge_restaurant.svg'),
    FoodKind.cafe => ('card_badge_ring.svg', 'card_badge_cafe.svg'),
    FoodKind.bar => ('card_badge_ring_red.svg', 'card_badge_bar.svg'),
  };

  @override
  Widget build(BuildContext context) {
    final p = widget.place;
    final badge = _badge;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          // 404 with the Contact button, 348 without, as drawn — so a row
          // of cards lines up whatever each one holds.
          height: widget.compact ? 348 : 404,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: kRBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageBand(p),
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name 25 high, 8 apart, type 17: the design's 50.
                          SizedBox(
                            height: 50,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                placeText(context, p.name, TextStyle(fontFamily: AppFonts.nunito, fontSize: 20, height: 1.25, fontWeight: FontWeight.w600, color: AppColors.navy)),
                                const SizedBox(height: 8),
                                // The page's own words ("Restaurant") with the
                                // cuisine's name after them, so it reads in
                                // the page's direction.
                                Text(p.type, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, height: 17 / 14, color: kRGreyText)),
                              ],
                            ),
                          ),
                          if (p.address.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 17,
                                  child: Center(child: SvgPicture.asset('$_kCardAsset/card_pin.svg', width: 12, height: 16)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: placeText(context, p.address, TextStyle(fontFamily: AppFonts.inter, fontSize: 14, height: 17 / 14, color: kRGreyText))),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),
                          _buildStatsRow(p),
                          if (!widget.compact && p.phone.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _buildContactButton(p),
                          ],
                        ],
                      ),
                    ),
                    // Straddles the photograph's edge: 44 across, half over it.
                    PositionedDirectional(
                      top: -22,
                      end: 15,
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SvgPicture.asset('$_kCardAsset/${badge.$1}', width: 44, height: 44),
                            SvgPicture.asset('$_kCardAsset/${badge.$2}', width: 20, height: 20),
                          ],
                        ),
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

  /// The place's photo, falling back to the gradient while it loads, when it
  /// fails, and on places that have none.
  ///
  /// `webHtmlElementStrategy`: WordPress serves its uploads without CORS
  /// headers, so CanvasKit has to hand the URL to a plain <img>.
  Widget _photo(RestaurantPlace p) {
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [p.imageBg, Color.lerp(p.imageBg, Colors.black, 0.2)!],
        ),
      ),
    );
    if (p.imageUrl.isEmpty) return fallback;
    // The card is about 380 wide; a sharp screen wants twice that.
    return Image.network(
      sizedPhotoUrl(p.imageUrl, 400, 2),
      fit: BoxFit.cover,
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      errorBuilder: (_, _, _) => fallback,
      loadingBuilder: (context, child, progress) => progress == null ? child : fallback,
    );
  }

  /// The photograph, the cuisine in a pill at the top and the kosher
  /// certificate at the bottom. The heart the design draws in the corner is
  /// left off: saving belongs to an account, and accounts are the app's.
  Widget _buildImageBand(RestaurantPlace p) {
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(child: _photo(p)),
          if (p.pill != null && p.pill!.isNotEmpty)
            PositionedDirectional(
              top: 15,
              end: 14,
              child: _pill(p.pill!),
            ),
          if (p.isKosher)
            PositionedDirectional(
              top: 161,
              start: 12,
              child: _pill(
                _t('Kosher', 'כשר'),
                icon: SvgPicture.asset('$_kCardAsset/card_kosher.svg', width: 14, height: 14),
              ),
            ),
        ],
      ),
    );
  }

  Widget _pill(String label, {Widget? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: kRBadgeBlue, borderRadius: BorderRadius.circular(50)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon, const SizedBox(width: 6)],
          Text(label, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 12, height: 15 / 12, fontWeight: FontWeight.w500, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildStatsRow(RestaurantPlace p) {
    const grey = Color(0xFF6D6D6D);
    return SizedBox(
      height: 17,
      child: Row(
        children: [
          // Most listings carry neither a rating nor a review count, and
          // "0 (0)" reads as a score the place earned rather than one nobody
          // gave it.
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 100),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: p.rating > 0 || p.reviews > 0
                  ? [
                      SvgPicture.asset('$_kCardAsset/card_star.svg', width: 16, height: 16),
                      const SizedBox(width: 8),
                      Text(p.rating.toStringAsFixed(1), style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black)),
                      const SizedBox(width: 8),
                      Text('(${p.reviews})', style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: grey)),
                    ]
                  : [
                      Text(_t('Not rated yet', 'אין דירוג עדיין'), style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: grey)),
                    ],
            ),
          ),
          if (widget.showDelivery && p.delivers) ...[
            const SizedBox(width: 40),
            const Icon(IconsaxPlusLinear.truck_fast, size: 16, color: Color(0xFF5D5D5D)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _t('Delivery', 'משלוחים'),
                style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Opens the contact menu — the number, Call, WhatsApp — outlined, and filled under the pointer, as the design
  /// draws both. Absent for a business with no number on record.
  Widget _buildContactButton(RestaurantPlace p) {
    return Builder(builder: (anchor) => GestureDetector(
      onTap: () => showWebContactMenu(anchor, isHebrew: widget.isHebrew, phone: p.phone, whatsapp: p.whatsapp),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: _hovered ? AppColors.midBlue : Colors.transparent,
          border: Border.all(color: AppColors.midBlue),
          borderRadius: BorderRadius.circular(60),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              _hovered ? '$_kCardAsset/card_phone_white.svg' : '$_kCardAsset/card_phone.svg',
              width: 16,
              height: 16,
            ),
            const SizedBox(width: 8),
            Text(
              _t('Contact', 'צור קשר'),
              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, fontWeight: FontWeight.w500, color: _hovered ? Colors.white : AppColors.midBlue),
            ),
          ],
        ),
      ),
    ));
  }
}
