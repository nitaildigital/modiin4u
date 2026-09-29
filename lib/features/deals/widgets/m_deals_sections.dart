import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/banners_provider.dart';
import '../../../shared/widgets/network_photo.dart';
import '../models/offer.dart';
import 'm_deal_card.dart';

// ═══════════════════════════════════════════════════════════
// Sections of the phone Deals page — Figma mobile "Deals" (631:3902).
// ═══════════════════════════════════════════════════════════

/// The 361 × 200 promotion under the heading, with the design's page bars
/// under it. These are the campaigns booked for the `DEALS_TOP` slot — the
/// same ones the desktop page shows — and until one is sold there is no box
/// at all rather than an empty one.
class MDealsBanner extends ConsumerStatefulWidget {
  const MDealsBanner({super.key});

  @override
  ConsumerState<MDealsBanner> createState() => _MDealsBannerState();
}

class _MDealsBannerState extends ConsumerState<MDealsBanner> {
  final _pages = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banners =
        ref.watch(activeBannersProvider('DEALS_TOP')).valueOrNull ??
        const <SiteBanner>[];
    if (banners.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 200,
              child: PageView.builder(
                controller: _pages,
                itemCount: banners.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) {
                  final b = banners[i];
                  final link = b.destinationUrl;
                  return GestureDetector(
                    onTap: link == null ? null : () => launchUrl(Uri.parse(link)),
                    child: NetworkPhoto(
                      url: b.imageUrl,
                      radius: BorderRadius.circular(12),
                    ),
                  );
                },
              ),
            ),
          ),
          // One bar per banner; a single banner has nothing to page to.
          if (banners.length > 1) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < banners.length; i++)
                  Container(
                    width: 20,
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                      color: i == _page
                          ? AppColors.midBlue
                          : const Color(0xFFD9D9D9),
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// The white fade over the last card shown, with "View All" on it.
class MDealsViewAll extends StatelessWidget {
  final Widget child;
  final String label;
  final VoidCallback onTap;
  const MDealsViewAll({
    super.key,
    required this.child,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 222,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.topCenter,
                maxHeight: double.infinity,
                child: IgnorePointer(child: child),
              ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00FFFFFF), Colors.white],
                  stops: [0, 0.98],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 18,
            child: Center(
              child: GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.midBlue),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Text(
                    label,
                    style: mDealsInter(
                      14,
                      weight: FontWeight.w500,
                      color: AppColors.midBlue,
                      height: 24 / 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A business behind the deals, 173.5 × 174: the pink strip with the best
/// discount its deals' titles state, its logo, and the button.
///
/// The design's button reads "Upto 5% Rewards"; nothing in the database
/// holds a reward rate, so it says what tapping it does instead, as the
/// desktop tile does.
class MBrandTile extends StatelessWidget {
  final List<Offer> offers;
  final bool isSelected;
  final VoidCallback onTap;
  const MBrandTile({
    super.key,
    required this.offers,
    required this.isSelected,
    required this.onTap,
  });

  String _strip(BuildContext context) {
    final pcts = offers.map((o) => o.percentOff).whereType<int>().toList();
    if (pcts.length > 1) {
      final best = pcts.reduce((a, b) => a > b ? a : b);
      return mDealsT(context, 'Upto $best% Off', 'עד $best% הנחה');
    }
    for (final o in offers) {
      final b = o.badge;
      if (b != null) return b;
    }
    final n = offers.length;
    return n == 1
        ? mDealsT(context, '1 Deal', 'מבצע אחד')
        : mDealsT(context, '$n Deals', '$n מבצעים');
  }

  @override
  Widget build(BuildContext context) {
    final first = offers.first;
    final name = first.businessName ?? '';
    final logo = first.businessLogo;
    final n = offers.length;
    final wordmark = Text(
      name,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: mDealsDisplay(18, height: 1.2),
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.midBlue : kMDealsLine,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: const Color(0xFFFFE6E6),
              padding: const EdgeInsets.all(8),
              alignment: Alignment.center,
              child: Text(
                _strip(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: mDealsInter(
                  14,
                  weight: FontWeight.w500,
                  color: const Color(0xFFE90052),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: logo != null
                            ? ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 120,
                                  maxHeight: 56,
                                ),
                                child: Image.network(
                                  sizedPhotoUrl(
                                    logo,
                                    120,
                                    MediaQuery.devicePixelRatioOf(context),
                                  ),
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) => wordmark,
                                ),
                              )
                            // No logo on file: the name stands in for one.
                            : wordmark,
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.midBlue,
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: Text(
                        n == 1
                            ? mDealsT(context, 'View Deal', 'צפו במבצע')
                            : mDealsT(context, 'View $n Deals', 'צפו ב־$n מבצעים'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: mDealsInter(
                          12,
                          weight: FontWeight.w500,
                          color: Colors.white,
                          height: 24 / 12,
                        ),
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
}
