import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';

// ═══════════════════════════════════════════════════════════
// Shared restaurant place card (web) — used by the Restaurants
// list page and the Restaurant Detail page.
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

class RestaurantCardState extends State<RestaurantCard> {
  bool _hovered = false;
  bool _favorite = false;

  String _t(String en, String he) => widget.isHebrew ? he : en;

  @override
  Widget build(BuildContext context) {
    final p = widget.place;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _hovered ? AppColors.midBlue : kRBorder),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageBand(p),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: TextStyle(fontFamily: AppFonts.nunito, 
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.navy,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          p.type,
                          style: TextStyle(fontFamily: AppFonts.inter, 
                            fontSize: 14,
                            color: kRGreyText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              IconsaxPlusLinear.location,
                              size: 16,
                              color: AppColors.turquoise,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                p.address,
                                style: TextStyle(fontFamily: AppFonts.inter, 
                                  fontSize: 14,
                                  color: kRGreyText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildStatsRow(p),
                        if (!widget.compact) ...[
                          const SizedBox(height: 16),
                          if (p.phone.isNotEmpty) _buildContactButton(p),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              // Type marker — straddles the image / content edge
              PositionedDirectional(
                top: 180,
                end: 17,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: p.marker,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Icon(
                      _markerIcon(p.marker),
                      size: 20,
                      color: Colors.white,
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

  /// The place's photo, falling back to the gradient while it loads, when it
  /// fails, and on demo places that have none.
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

  Widget _buildImageBand(RestaurantPlace p) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
      child: SizedBox(
        height: 200,
        width: double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: _photo(p)),
            // Favorite
            PositionedDirectional(
              top: 12,
              start: 12,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => setState(() => _favorite = !_favorite),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        _favorite
                            ? IconsaxPlusBold.heart
                            : IconsaxPlusLinear.heart,
                        size: 20,
                        color: _favorite ? kHeartRed : AppColors.midBlue,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Category badge
            if (p.category != null)
              PositionedDirectional(
                top: 15,
                end: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: kRBadgeBlue,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    p.category!,
                    style: TextStyle(fontFamily: AppFonts.inter, 
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            // Kosher badge
            if (p.isKosher)
              PositionedDirectional(
                bottom: 12,
                start: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: kRBadgeBlue,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        IconsaxPlusLinear.verify,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _t('Kosher', 'כשר'),
                        style: TextStyle(fontFamily: AppFonts.inter, 
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _markerIcon(Color marker) {
    if (marker == kCafeBlue) return IconsaxPlusLinear.coffee;
    if (marker == kBarRed) return IconsaxPlusLinear.cup;
    return IconsaxPlusLinear.reserve;
  }

  Widget _buildStatsRow(RestaurantPlace p) {
    return Row(
      children: [
        // Most real listings carry neither a rating nor a review count, and
        // "0 (0)" reads as a score the place earned rather than one nobody
        // gave it. Show each half only when there is a number behind it.
        if (p.rating > 0 || p.reviews > 0)
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  IconsaxPlusBold.star_1,
                  size: 16,
                  color: Color(0xFFFFC107),
                ),
                const SizedBox(width: 6),
                if (p.rating > 0)
                  Text(
                    p.rating.toStringAsFixed(1),
                    style: TextStyle(fontFamily: AppFonts.inter, 
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                if (p.reviews > 0) ...[
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '(${p.reviews})',
                      style: TextStyle(fontFamily: AppFonts.inter, 
                        fontSize: 14,
                        color: const Color(0xFF6D6D6D),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        // A delivery window where the place has one. There is no view-count
        // column on `businesses`, so the "N Views" this used to fall back to
        // had no source at all — and with a null it printed "null Views".
        if (p.deliveryTime != null && p.deliveryTime!.isNotEmpty) ...[
          const SizedBox(width: 12),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  IconsaxPlusLinear.clock,
                  size: 16,
                  color: Color(0xFF5D5D5D),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    p.deliveryTime!,
                    style: TextStyle(fontFamily: AppFonts.inter,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Dials the place. The handler was empty, so a button offering to put
  /// somebody in touch did nothing, and it was drawn even for a business
  /// with no number on record.
  Widget _buildContactButton(RestaurantPlace p) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => launchUrl(Uri(scheme: 'tel', path: p.phone)),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.midBlue),
            borderRadius: BorderRadius.circular(60),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                IconsaxPlusLinear.call,
                size: 16,
                color: AppColors.midBlue,
              ),
              const SizedBox(width: 8),
              Text(
                _t('Contact', 'צור קשר'),
                style: TextStyle(fontFamily: AppFonts.inter, 
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
}
