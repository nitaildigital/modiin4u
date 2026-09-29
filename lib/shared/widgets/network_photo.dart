import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// A photo from our Supabase storage, at the size it is drawn.
///
/// The directory's photos are stored as they were uploaded: the median cover
/// is 270 KB, the largest 4.3 MB, and forty of them came to 16 MB — a
/// restaurants page asks for twenty. Storage can resize on the way out, so a
/// card 380 wide asks for an 800-pixel copy (for a sharp screen), which the
/// browser receives as WebP: that 4.3 MB photo arrives as 82 KB.
///
/// Widths are rounded up to a few steps so one copy serves many boxes and
/// stays in Supabase's cache. Anything not a stored JPEG, PNG or WebP — a
/// logo in SVG, a picture on another site — is left as it is.
String sizedPhotoUrl(String url, double logicalWidth, double devicePixelRatio) {
  const stored = '/storage/v1/object/public/';
  if (!url.contains('.supabase.co$stored')) return url;
  final path = url.split('?').first.toLowerCase();
  if (!(path.endsWith('.jpg') || path.endsWith('.jpeg') || path.endsWith('.png') || path.endsWith('.webp'))) {
    return url;
  }
  final px = (logicalWidth.isFinite && logicalWidth > 0 ? logicalWidth : 1600) * devicePixelRatio;
  const steps = [200, 400, 600, 800, 1200, 1600, 2000, 2500];
  final width = steps.firstWhere((s) => s >= px, orElse: () => 2500);
  final sep = url.contains('?') ? '&' : '?';
  // `contain` inside a box as tall as storage allows, so only the width
  // binds. Given a width alone, storage keeps the original height and crops
  // the photo to a narrow strip — which a card then enlarged to fill itself,
  // and every photo on the businesses page looked stretched.
  return '${url.replaceFirst(stored, '/storage/v1/render/image/public/')}${sep}width=$width&height=2500&resize=contain&quality=75';
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
      final sized = sizedPhotoUrl(src, needed, MediaQuery.devicePixelRatioOf(context));
      return CachedNetworkImage(
        imageUrl: sized,
        width: width,
        height: height,
        fit: fit,
        fadeInDuration: const Duration(milliseconds: 250),
        placeholder: (_, _) => fallback,
        // Should the resized copy fail, the original is still there.
        errorWidget: (_, _, _) => sized == src
            ? fallback
            : CachedNetworkImage(
                imageUrl: src,
                width: width,
                height: height,
                fit: fit,
                placeholder: (_, _) => fallback,
                errorWidget: (_, _, _) => fallback,
              ),
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
