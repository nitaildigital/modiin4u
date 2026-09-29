import 'package:flutter/material.dart';

/// One of the site's own photographs across a page's hero.
///
/// These are preloaded when the app starts and held in memory (see
/// web_asset_precache.dart), so normally they are simply there. When one is
/// not yet in — a visitor clicks through in the first second or two — the
/// card shows the photograph's own average colour rather than white, and the
/// photograph fades in over it, instead of a blank card that suddenly fills.
class WebHeroPhoto extends StatelessWidget {
  final String asset;

  /// The photograph's average colour.
  final Color placeholder;

  const WebHeroPhoto({super.key, required this.asset, required this.placeholder});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: placeholder,
      child: Image.asset(
        asset,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: child,
          );
        },
      ),
    );
  }
}
