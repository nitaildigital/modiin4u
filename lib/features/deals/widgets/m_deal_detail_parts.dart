import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/network_photo.dart';
import 'm_deal_card.dart';

// ═══════════════════════════════════════════════════════════
// Pieces of the phone deal page — Figma mobile "Deal Details" (806:10899).
// ═══════════════════════════════════════════════════════════

const kMDealIcon = 'assets/icons';

/// A 38 tinted circle with its icon, a title, and what is under it.
class MDealFactRow extends StatelessWidget {
  final String icon;
  final String title;
  final Widget body;
  const MDealFactRow({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset('$kMDealIcon/$icon', width: 38, height: 38),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: mDealsInter(14, weight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                body,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The value line under a fact's title.
class MDealFactText extends StatelessWidget {
  final String text;
  const MDealFactText(this.text, {super.key});

  @override
  Widget build(BuildContext context) =>
      Text(text, style: mDealsInter(14, color: kMDealsGrey, height: 1.4));
}

/// The design's bullet list under "Restrictions".
class MDealBullets extends StatelessWidget {
  final List<String> items;
  const MDealBullets(this.items, {super.key});

  @override
  Widget build(BuildContext context) {
    final style = mDealsInter(14, color: kMDealsGrey, height: 1.4);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 21,
                child: Text('•', textAlign: TextAlign.center, style: style),
              ),
              Expanded(child: Text(item, style: style)),
            ],
          ),
      ],
    );
  }
}

/// A 44-high pill: filled for the main action, outlined for the others.
class MDealActionButton extends StatelessWidget {
  final String icon;
  final String label;
  final bool filled;
  final bool enabled;
  final VoidCallback? onTap;
  const MDealActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : AppColors.midBlue;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: filled
              ? (enabled ? AppColors.midBlue : const Color(0xFFB9C0CE))
              : Colors.white,
          border: filled ? null : Border.all(color: AppColors.midBlue),
          borderRadius: BorderRadius.circular(60),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset('$kMDealIcon/$icon', width: 20, height: 20),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: mDealsInter(
                  14,
                  weight: FontWeight.w500,
                  color: fg,
                  height: 24 / 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Show all photos": the business's gallery, one photograph at a time.
Future<void> showMDealPhotos(BuildContext context, List<String> photos) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black,
    useSafeArea: false,
    builder: (ctx) => _PhotoViewer(photos: photos),
  );
}

class _PhotoViewer extends StatefulWidget {
  final List<String> photos;
  const _PhotoViewer({required this.photos});

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Material(
      color: Colors.black,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: widget.photos.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => InteractiveViewer(
              child: SizedBox.expand(
                child: NetworkPhoto(
                  url: widget.photos[i],
                  fit: BoxFit.contain,
                  gradient: const [Colors.black, Colors.black],
                ),
              ),
            ),
          ),
          PositionedDirectional(
            end: 12,
            top: top + 7,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 20, color: Color(0xFF3D3D3D)),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.paddingOf(context).bottom + 16,
            child: Text(
              '${_page + 1} / ${widget.photos.length}',
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              style: mDealsInter(14, weight: FontWeight.w500, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
