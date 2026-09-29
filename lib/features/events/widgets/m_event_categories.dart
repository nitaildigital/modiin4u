import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/network_photo.dart';
import '../models/event.dart';
import '../models/event_category.dart';
import '../models/event_labels.dart';

/// One circle in the phone's "Event Categories" row.
///
/// [filter] is `all`, `free` or a category slug — the same values the
/// website's `?category=` takes.
class MEventCircle {
  final String label;
  final int count;
  final String filter;
  final String? imageUrl;
  final String? asset;
  const MEventCircle({
    required this.label,
    required this.count,
    required this.filter,
    this.imageUrl,
    this.asset,
  });

  /// The design's photographs, the same the website's circles use.
  static const _all = 'assets/web/events/cat_all.webp';
  static const _free = 'assets/web/events/cat_free.webp';
  static const _bySlug = {
    'community': 'assets/web/events/cat_community.webp',
    'municipal-community': 'assets/web/events/cat_community.webp',
    'concerts': 'assets/web/events/cat_music.webp',
    'music': 'assets/web/events/cat_music.webp',
    'kids': 'assets/web/events/cat_kids.webp',
    'kids-family': 'assets/web/events/cat_kids.webp',
    'sports-events': 'assets/web/events/cat_sports.webp',
    'sports': 'assets/web/events/cat_sports.webp',
  };

  /// "All Events", each category with something coming up, then "Free" —
  /// counted from the upcoming events, as on the website. A category with
  /// nothing coming is left out.
  static List<MEventCircle> build({
    required List<Event> upcoming,
    required List<EventCategory> categories,
    required Map<String, List<EventCategory>> byEvent,
    required EventLabels labels,
  }) {
    if (upcoming.isEmpty) return const [];
    final circles = <MEventCircle>[
      MEventCircle(
        label: labels.t('All Events', 'כל האירועים'),
        count: upcoming.length,
        filter: 'all',
        asset: _all,
      ),
    ];
    for (final c in categories) {
      bool inIt(Event e) => (byEvent[e.id] ?? const []).any((x) => x.id == c.id);
      final count = upcoming.where(inIt).length;
      if (count == 0) continue;
      final asset = _bySlug[c.slug];
      var imageUrl = c.imageUrl;
      if ((imageUrl == null || imageUrl.isEmpty) && asset == null) {
        imageUrl = upcoming
            .where((e) => (e.imageUrl ?? '').isNotEmpty && inIt(e))
            .firstOrNull
            ?.imageUrl;
      }
      circles.add(MEventCircle(
        label: labels.category(c),
        count: count,
        filter: c.slug,
        imageUrl: imageUrl,
        asset: asset,
      ));
    }
    final free = upcoming.where((e) => e.isFree).length;
    if (free > 0) {
      circles.add(MEventCircle(
        label: labels.t('Free', 'חינם'),
        count: free,
        filter: 'free',
        asset: _free,
      ));
    }
    return circles;
  }

  /// Whether [e] belongs under this circle.
  bool matches(Event e, Map<String, List<EventCategory>> byEvent) {
    if (filter == 'all') return true;
    if (filter == 'free') return e.isFree;
    return (byEvent[e.id] ?? const []).any((c) => c.slug == filter);
  }
}

/// The horizontal row of 64px category circles (Figma "Events" › 598:5583):
/// 100 wide each, name in Inter Medium 14, count beneath in grey.
class MEventCategoryRow extends StatelessWidget {
  final List<MEventCircle> circles;
  final String selected;
  final ValueChanged<String> onSelect;
  const MEventCategoryRow({
    super.key,
    required this.circles,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 114,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: circles.length,
        itemBuilder: (context, i) {
          final c = circles[i];
          final isOn = c.filter == selected && selected != 'all';
          final url = c.imageUrl;
          final Widget photo = (url != null && url.isNotEmpty)
              ? NetworkPhoto(url: url, width: 64, height: 64, icon: IconsaxPlusBold.calendar_1, iconSize: 22)
              : c.asset != null
              ? Image.asset(c.asset!, width: 64, height: 64, fit: BoxFit.cover)
              : const NetworkPhoto(url: null, width: 64, height: 64, icon: IconsaxPlusBold.calendar_1, iconSize: 22);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onSelect(isOn ? 'all' : c.filter),
            child: SizedBox(
              width: 100,
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: isOn
                          ? Border.all(color: AppColors.midBlue, width: 2)
                          : null,
                    ),
                    child: ClipOval(child: photo),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      c.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isOn ? AppColors.midBlue : Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${c.count}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      color: AppColors.grayText,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
