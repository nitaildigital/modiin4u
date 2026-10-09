import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// The address to load a photo from our Supabase storage at.
///
/// It was Supabase's resizing address (`/render/image`, an 800-pixel WebP
/// for a 380-wide card): each different photo resized there counts against
/// the plan's 100 a month, and on 9 Oct the whole project was restricted at
/// 862 — the database included. So the original is loaded, as stored: an
/// ordinary download, cached by the phone and the browser, against an egress
/// quota then at 1%. [NetworkPhoto] decodes it at the size it is drawn, so a
/// phone's memory holds no more than before. The parameters stay for when
/// small copies are stored at upload (PLAN.md, 9 Oct).
String sizedPhotoUrl(String url, double logicalWidth, double devicePixelRatio) => url;

/// The pixel width to decode a photo drawn [logicalWidth] wide at, rounded
/// up to a few steps; null where the width is not known.
int? decodeWidth(double logicalWidth, double devicePixelRatio) {
  if (!logicalWidth.isFinite || logicalWidth <= 0) return null;
  final px = logicalWidth * devicePixelRatio;
  const steps = [200, 400, 600, 800, 1200, 1600, 2000, 2500];
  return steps.firstWhere((s) => s >= px, orElse: () => 2500);
}

/// The width to ask for, for a photo covering a box of [width] × [height]:
/// the box's width, or more when a wide photo scaled to a tall box's height
/// needs it. 800 when neither is known.
double photoTargetWidth(double? width, double? height) {
  final w = width != null && width.isFinite ? width : 0.0;
  final h = height != null && height.isFinite ? height * 16 / 9 : 0.0;
  final best = w > h ? w : h;
  return best > 0 ? best : 800;
}

/// A photo from the directory.
///
/// Fades the image in once it arrives, and falls back to a tint with an icon
/// when a record carries no picture — 71 of the 200 businesses in the export
/// do not, and events carry none at all yet. The fallback is drawn at the same
/// size as the photo, so nothing shifts either way.
class NetworkPhoto extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BorderRadius? radius;

  /// The two colours behind the fallback icon. Defaults to the brand navy.
  final List<Color> gradient;
  /// Null draws the gradient on its own. A glyph reads as "picture missing",
  /// which is right on a thumbnail and wrong across a hero the size of the
  /// page — there it looks broken rather than deliberate.
  final IconData? icon;
  final double iconSize;

  /// The fallback icon's colour. Defaults to white at low opacity, which suits
  /// the dark brand gradient; pass a tint when the gradient is a light one.
  final Color? iconColor;
  final BoxFit fit;

  const NetworkPhoto({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.radius,
    this.gradient = const [Color(0xFF0058B5), Color(0xFF010A36)],
    this.icon = Icons.storefront_outlined,
    this.iconSize = 32,
    this.iconColor,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
      child: icon == null
          ? null
          : Center(
              child: Icon(
                icon,
                size: iconSize,
                color: iconColor ?? Colors.white.withValues(alpha: 0.28),
              ),
            ),
    );

    final src = url;
    if (src == null || src.isEmpty) {
      return radius == null ? fallback : ClipRRect(borderRadius: radius!, child: fallback);
    }

    Widget photo(double logicalWidth, double logicalHeight) {
      // A photo covering a box may be scaled to its height, and a wide photo
      // in a tall box then needs more width than the box has.
      final needed = fit == BoxFit.cover && logicalHeight.isFinite
          ? (logicalWidth.isFinite ? logicalWidth : 0).clamp(logicalHeight * 16 / 9, double.infinity).toDouble()
          : logicalWidth;
      return CachedNetworkImage(
        imageUrl: sizedPhotoUrl(src, needed, MediaQuery.devicePixelRatioOf(context)),
        // Decoded at the size it is drawn: a 4 MB original in a card takes
        // the memory of a card-sized picture.
        memCacheWidth: decodeWidth(needed, MediaQuery.devicePixelRatioOf(context)),
        width: width,
        height: height,
        fit: fit,
        fadeInDuration: const Duration(milliseconds: 250),
        placeholder: (_, _) => fallback,
        errorWidget: (_, _, _) => fallback,
      );
    }

    final w = width;
    final Widget child = w != null && w.isFinite
        ? photo(w, height ?? double.infinity)
        : LayoutBuilder(builder: (context, c) => photo(c.maxWidth, height ?? c.maxHeight));

    return radius == null
        ? child
        : ClipRRect(borderRadius: radius!, child: child);
  }
}
