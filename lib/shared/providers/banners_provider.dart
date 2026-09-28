import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_config.dart';

/// One paid banner a page may draw.
class SiteBanner {
  final String id;
  final String imageUrl;
  final String? destinationUrl;
  final String name;

  const SiteBanner({
    required this.id,
    required this.imageUrl,
    required this.destinationUrl,
    required this.name,
  });
}

/// The banners running now in one slot, by its `ad_placements.code`.
///
/// `campaigns` is admin-only — a row carries impressions, clicks and the
/// salesperson — so this goes through `active_banners()` (migration 00028),
/// which answers with the creative and the link and nothing else.
///
/// **A slot with nothing booked draws nothing**, and so does a failed call:
/// a banner is never the point of the page, and a request that failed should
/// not leave a grey box where an advertiser would be. That includes the
/// function not existing yet on a database 00028 has not reached.
final activeBannersProvider =
    FutureProvider.family<List<SiteBanner>, String>((ref, code) async {
      try {
        final rows = await SupabaseConfig.client.rpc(
          'active_banners',
          params: {'p_code': code},
        );
        return [
          for (final r in List<Map<String, dynamic>>.from(rows as List))
            if ((r['image_url'] as String?)?.isNotEmpty ?? false)
              SiteBanner(
                id: r['id'] as String,
                imageUrl: r['image_url'] as String,
                destinationUrl: r['destination_url'] as String?,
                name: (r['name'] as String?) ?? '',
              ),
        ];
      } catch (_) {
        return const [];
      }
    });
