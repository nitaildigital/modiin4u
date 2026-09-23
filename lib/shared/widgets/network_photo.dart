import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

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
  final IconData icon;
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
      child: Center(
        child: Icon(
          icon,
          size: iconSize,
          color: iconColor ?? Colors.white.withValues(alpha: 0.28),
        ),
      ),
    );

    final src = url;
    final child = src == null || src.isEmpty
        ? fallback
        : CachedNetworkImage(
            imageUrl: src,
            width: width,
            height: height,
            fit: fit,
            fadeInDuration: const Duration(milliseconds: 250),
            placeholder: (_, _) => fallback,
            errorWidget: (_, _, _) => fallback,
          );

    return radius == null
        ? child
        : ClipRRect(borderRadius: radius!, child: child);
  }
}
