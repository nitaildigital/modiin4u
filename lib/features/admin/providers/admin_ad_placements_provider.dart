import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_table_notifier.dart';

/// The slots a banner can occupy, on the live table.
///
/// Each row comes with its campaigns, so the list can say how many are on the
/// site in that slot right now. It used to read `active_campaigns_count`, a
/// column the table does not have, so every slot said 0.
final adminAdPlacementListProvider =
    StateNotifierProvider<
      AdminAdPlacementListNotifier,
      AsyncValue<List<Map<String, dynamic>>>
    >((ref) {
      return AdminAdPlacementListNotifier();
    });

class AdminAdPlacementListNotifier extends AdminTableNotifier {
  AdminAdPlacementListNotifier()
    : super(
        table: 'ad_placements',
        searchColumns: const ['code', 'label'],
        columns: '*, campaigns(id, status, start_at, end_at, desktop_image)',
        orderBy: 'sort_order',
        ascending: true,
        hasStatus: false,
      );

  Future<void> createPlacement(Map<String, dynamic> p) => create(p);
  Future<void> updatePlacement(String id, Map<String, dynamic> f) =>
      update(id, f);

  /// Hidden rather than removed: campaigns point at it, and `placement_id`
  /// cascades, so removing a slot would take its campaigns with it.
  Future<void> deletePlacement(String id) => setActive(id, false);

  Future<void> toggleActive(String id) async {
    final row = state.valueOrNull?.firstWhere(
      (p) => p['id'] == id,
      orElse: () => const {},
    );
    await setActive(id, !((row?['is_active'] as bool?) ?? true));
  }
}

/// What the website draws in each slot, in pixels, read off the pages that
/// draw them — so whoever uploads a banner makes it the right shape.
///
/// `ad_placements.allowed_sizes` is where this belongs, and it is shown first
/// when it is filled in; on every slot today it is empty. A code missing here
/// is a slot no page of the website draws yet: a campaign booked there is
/// saved but shown nowhere, and the panel says so rather than taking the
/// booking silently.
const placementSiteSizes = <String, String>{
  'HOME_TOP': '728×90 · עמוד הבית, מתחת לכרטיסים · מוצג באנר אחד',
  'HOME_MAP_SIDE': 'ליד המפה בעמוד הבית: הראשון 460×281, השני והשלישי 220×220',
  'ARTICLE_INLINE': 'רוחב 796 (בעיצוב 796×228) · מתחת לכתבה · מוצג באנר אחד',
  'NEWS_SIDEBAR':
      'עמוד החדשות: רוחב 370, גובה חופשי · עמוד כתבה: 426×260 לרוחב',
  'RESTAURANTS_TOP': '520×300 · שלושה בשורה בראש עמוד המסעדות',
  'DEALS_TOP': '520×300 · שלושה בשורה בראש עמוד המבצעים',
  'MENU_BUSINESSES': '276×308 · בתוך תפריט "עסקים"',
  'MENU_PROFESSIONALS': '276×308 · בתוך תפריט "בעלי מקצוע"',
};

/// The shape to upload for [placement]: its own `allowed_sizes` when set,
/// else what the website draws there, else a plain statement that nothing
/// draws it.
String placementSizeText(Map<String, dynamic>? placement) {
  if (placement == null) return '';
  final sizes = formatAllowedSizes(placement['allowed_sizes']);
  if (sizes.isNotEmpty) return sizes;
  return placementSiteSizes[placement['code']] ?? 'לא מוצג באתר כרגע';
}

/// Whether any page of the website draws the slot [code].
bool placementIsDrawn(String? code) => placementSiteSizes.containsKey(code);

/// `[{"w":728,"h":90}, …]` as "728×90, …"; empty for anything else.
String formatAllowedSizes(Object? value) {
  if (value is! List) return '';
  return [
    for (final s in value)
      if (s is Map && s['w'] != null && s['h'] != null) '${s['w']}×${s['h']}',
  ].join(', ');
}

/// "728x90, 320×100" as `[{"w":728,"h":90}, {"w":320,"h":100}]`; null when
/// empty. Throws [FormatException] on anything it cannot read, so the form
/// can say so instead of storing a string the column was not meant to hold.
List<Map<String, int>>? parseAllowedSizes(String text) {
  final parts = text
      .split(RegExp(r'[,\n]'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  if (parts.isEmpty) return null;
  return [
    for (final p in parts)
      () {
        final m = RegExp(r'^(\d+)\s*[x×X*]\s*(\d+)$').firstMatch(p);
        if (m == null) throw FormatException(p);
        return {'w': int.parse(m.group(1)!), 'h': int.parse(m.group(2)!)};
      }(),
  ];
}

/// Whether [campaign] is on the website now, by the same rules as the
/// `active_banners()` function the site calls (migration 00028): its slot is
/// active, its status is `active`, it has a picture, and today falls inside
/// its dates. (The function lets an empty picture through; the page then
/// skips it, so it counts as not shown here.)
bool campaignIsLive(
  Map<String, dynamic> campaign, {
  bool placementActive = true,
  DateTime? now,
}) {
  final at = (now ?? DateTime.now()).toUtc();
  if (!placementActive) return false;
  if (campaign['status'] != 'active') return false;
  final image = campaign['desktop_image'] as String?;
  if (image == null || image.isEmpty) return false;
  final start = DateTime.tryParse(campaign['start_at'] as String? ?? '');
  final end = DateTime.tryParse(campaign['end_at'] as String? ?? '');
  if (start != null && start.isAfter(at)) return false;
  if (end != null && !end.isAfter(at)) return false;
  return true;
}
