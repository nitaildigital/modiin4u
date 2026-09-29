import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/banners_provider.dart';
import 'network_photo.dart';
import 'web_chrome.dart';

/// Three banners across the page at the design's 520 × 300, corners of 12,
/// from the campaigns booked for [code] — the promotion cards at the top of
/// the Restaurants and Deals pages ("Best Restaurants · Up to 40% off").
///
/// A round arrow sits on either edge and turns the row by one banner, round
/// and round, so a slot sold to more than three advertisers shows them all.
/// The design draws the arrows over three banners, so they appear from three
/// on; with fewer every banner is already in view.
///
/// They are advertisements: until one is sold for the slot the row is not
/// drawn at all, and [top] with it.
class WebBannerRow extends ConsumerStatefulWidget {
  final String code;
  final double top;
  const WebBannerRow({super.key, required this.code, this.top = 56});

  @override
  ConsumerState<WebBannerRow> createState() => _WebBannerRowState();
}

class _WebBannerRowState extends ConsumerState<WebBannerRow> {
  int _start = 0;

  @override
  Widget build(BuildContext context) {
    final banners = ref.watch(activeBannersProvider(widget.code)).valueOrNull ?? const <SiteBanner>[];
    if (banners.isEmpty) return const SizedBox.shrink();
    final n = banners.length;

    return Padding(
      padding: EdgeInsets.only(top: widget.top),
      child: WebSection(
        child: LayoutBuilder(
          builder: (context, c) {
            const gap = 20.0;
            final w = (c.maxWidth - 2 * gap) / 3;
            final h = w * 300 / 520;
            return SizedBox(
              height: h,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < 3 && i < n; i++) ...[
                        if (i > 0) const SizedBox(width: gap),
                        _Banner(banner: banners[(_start + i) % n], width: w, height: h),
                      ],
                    ],
                  ),
                  if (n >= 3) ...[
                    PositionedDirectional(
                      start: -20,
                      top: h / 2 - 20,
                      child: _EdgeArrow(back: true, onTap: () => setState(() => _start = (_start - 1 + n) % n)),
                    ),
                    PositionedDirectional(
                      end: -20,
                      top: h / 2 - 20,
                      child: _EdgeArrow(back: false, onTap: () => setState(() => _start = (_start + 1) % n)),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final SiteBanner banner;
  final double width, height;
  const _Banner({required this.banner, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    final link = banner.destinationUrl;
    return MouseRegion(
      cursor: link == null ? MouseCursor.defer : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: link == null ? null : () => launchUrl(Uri.parse(link)),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: NetworkPhoto(
            key: ValueKey(banner.id),
            url: banner.imageUrl,
            width: width,
            height: height,
            radius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

/// White, 40 across, a faint ring and shadow — the arrow on a carousel's edge,
/// pointing along the reading direction or against it.
class _EdgeArrow extends StatelessWidget {
  final bool back;
  final VoidCallback onTap;
  const _EdgeArrow({required this.back, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFF6F6F6)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 5, offset: const Offset(0, 1))],
          ),
          child: Center(
            child: Transform.flip(
              flipX: back != (Directionality.of(context) == TextDirection.rtl),
              child: SvgPicture.asset('assets/web/common/arrow20.svg', width: 20, height: 20),
            ),
          ),
        ),
      ),
    );
  }
}
