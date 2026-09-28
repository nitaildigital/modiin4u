import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';

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
  final String name, type, address;
  final double rating;
  final int reviews;
  final String? deliveryTime;
  final String? category;
  final bool isKosher;
  final Color marker, imageBg;
  /// Remote photo from the WordPress export; empty on demo places, which
  /// keep falling back to the [imageBg] gradient.
  final String imageUrl;
  final String phone;
  const RestaurantPlace({
    required this.name,
    required this.type,
    required this.address,
    required this.rating,
    required this.reviews,
    this.deliveryTime,
    this.category,
    this.isKosher = false,
    required this.marker,
    required this.imageBg,
    this.imageUrl = '',
    this.phone = '',
  });
}

class RestaurantCard extends StatefulWidget {
  final RestaurantPlace place;
  final bool compact;
  final bool isHebrew;
  final VoidCallback? onTap;
  const RestaurantCard({
    super.key,
    required this.place,
    required this.compact,
    required this.isHebrew,
    this.onTap,
  });

  @override
  State<RestaurantCard> createState() => RestaurantCardState();
}

const _kCardAsset = 'assets/web/home';
final _hebrew = RegExp(r'[֐-׿]');

/// Directory text, in its own direction, lined up with the card.
Widget _dataText(BuildContext context, String text, TextStyle style) {
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
  /// restaurant, blue for a café, red for a bar. A section drawn in another
  /// colour has no badge of its own in the design, so it gets none.
  (String, String)? get _badge => switch (widget.place.marker) {
    kRestaurantGreen => ('card_badge_ring_green.svg', 'card_badge_restaurant.svg'),
    kCafeBlue => ('card_badge_ring.svg', 'card_badge_cafe.svg'),
    kBarRed => ('card_badge_ring_red.svg', 'card_badge_bar.svg'),
    _ => null,
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
                          SizedBox(
                            height: 50,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _dataText(context, p.name, TextStyle(fontFamily: AppFonts.nunito, fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.navy)),
                                _dataText(context, p.type, TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: kRGreyText)),
                              ],
                            ),
                          ),
                          if (p.address.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: Center(child: SvgPicture.asset('$_kCardAsset/card_pin.svg', width: 12, height: 16)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: _dataText(context, p.address, TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: kRGreyText))),
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
                    if (badge != null)
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
    return Image.network(
      p.imageUrl,
      fit: BoxFit.cover,
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      errorBuilder: (_, _, _) => fallback,
      loadingBuilder: (context, child, progress) => progress == null ? child : fallback,
    );
  }

  /// The photograph, the category in a pill at the top and the kosher
  /// certificate at the bottom. The heart the design draws in the corner is
  /// left off: it saved nothing — a local switch that reset on the next
  /// page — and saving belongs to an account, which is the app's.
  Widget _buildImageBand(RestaurantPlace p) {
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(child: _photo(p)),
          if (p.category != null)
            PositionedDirectional(
              top: 15,
              end: 14,
              child: _pill(p.category!),
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
          Text(label, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildStatsRow(RestaurantPlace p) {
    return Row(
      children: [
        // Most real listings carry neither a rating nor a review count, and
        // "0 (0)" reads as a score the place earned rather than one nobody
        // gave it.
        if (p.rating > 0 || p.reviews > 0) ...[
          SvgPicture.asset('$_kCardAsset/card_star.svg', width: 16, height: 16),
          const SizedBox(width: 8),
          Text(p.rating.toStringAsFixed(1), style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black)),
          const SizedBox(width: 8),
          Text('(${p.reviews})', style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: const Color(0xFF6D6D6D))),
        ] else
          Text(_t('Not rated yet', 'אין דירוג עדיין'), style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: const Color(0xFF6D6D6D))),
        // Delivery where the directory records it. There is no view-count
        // column on `businesses`, so the design's "N Views" has no source.
        if (p.deliveryTime != null && p.deliveryTime!.isNotEmpty) ...[
          const SizedBox(width: 24),
          Flexible(
            child: Text(
              p.deliveryTime!,
              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  /// Dials the place — outlined, and filled under the pointer, as the design
  /// draws both. Absent for a business with no number on record.
  Widget _buildContactButton(RestaurantPlace p) {
    return GestureDetector(
      onTap: () => launchUrl(Uri(scheme: 'tel', path: p.phone)),
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
    );
  }
}
