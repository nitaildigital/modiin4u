import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/banners_provider.dart';
import 'network_photo.dart';
import 'web_chrome.dart';

/// Three banners across the page at the design's 520 × 300, from the
/// campaigns booked for [code] — the promotion cards at the top of the
/// Restaurants and Deals pages ("Best Restaurants · Up to 40% off"). They are
/// advertisements; until one is sold for the slot the row is not drawn at
/// all, and [top] with it.
class WebBannerRow extends ConsumerWidget {
  final String code;
  final double top;
  const WebBannerRow({super.key, required this.code, this.top = 56});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banners = ref.watch(activeBannersProvider(code)).valueOrNull ?? const <SiteBanner>[];
    if (banners.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: top),
      child: WebSection(
        child: LayoutBuilder(
          builder: (context, c) {
            const gap = 20.0;
            final w = (c.maxWidth - 2 * gap) / 3;
            return Row(
              children: [
                for (var i = 0; i < 3 && i < banners.length; i++) ...[
                  if (i > 0) const SizedBox(width: gap),
                  MouseRegion(
                    cursor: banners[i].destinationUrl == null ? MouseCursor.defer : SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: banners[i].destinationUrl == null
                          ? null
                          : () => launchUrl(Uri.parse(banners[i].destinationUrl!)),
                      child: NetworkPhoto(
                        url: banners[i].imageUrl,
                        width: w,
                        height: w * 300 / 520,
                        radius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
