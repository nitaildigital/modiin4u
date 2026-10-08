import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../auth/providers/auth_provider.dart';

/// A neighbourhood's average star rating and how many people gave one.
typedef NeighborhoodRating = ({double average, int count});

/// The average and the count, from `neighborhood_rating_summary` (00071).
///
/// Who rated what stays private — row security hands each person only their
/// own row — so the figures come through the function, which anyone may
/// call, the website's visitors included. Null when nobody has rated the
/// neighbourhood: the function then returns no row at all, and a "0.0" would
/// read as a bad score rather than as none.
final neighborhoodRatingProvider =
    FutureProvider.autoDispose.family<NeighborhoodRating?, String>((
      ref,
      neighborhoodId,
    ) async {
      final rows = await SupabaseConfig.client.rpc(
        'neighborhood_rating_summary',
        params: {'p_neighborhood': neighborhoodId},
      );
      final list = List<Map<String, dynamic>>.from(rows as List);
      if (list.isEmpty) return null;
      final count = (list.first['ratings'] as num?)?.toInt() ?? 0;
      if (count == 0) return null;
      return (
        average: (list.first['average'] as num).toDouble(),
        count: count,
      );
    });

/// The signed-in person's own rating of the neighbourhood, 1 to 5, or null
/// when they have not rated it or nobody is signed in.
///
/// Watches the account, so signing in or out on this page shows the right
/// stars without reopening it.
final myNeighborhoodRatingProvider =
    FutureProvider.autoDispose.family<int?, String>((
      ref,
      neighborhoodId,
    ) async {
      final me = ref.watch(authProvider)?.id;
      if (me == null) return null;
      final row = await SupabaseConfig.client
          .from('neighborhood_ratings')
          .select('rating')
          .eq('neighborhood_id', neighborhoodId)
          .eq('profile_id', me)
          .maybeSingle();
      return (row?['rating'] as num?)?.toInt();
    });

/// Sets the signed-in person's rating of the neighbourhood, or clears it
/// when [rating] is null, then has both figures read again so the average
/// takes it in.
///
/// One row per person and neighbourhood, so a second rating replaces the
/// first. Throws what the database throws — a blocked account's write is
/// refused there — for the caller to explain. Returns false, writing
/// nothing, when nobody is signed in.
Future<bool> setMyNeighborhoodRating(
  WidgetRef ref,
  String neighborhoodId,
  int? rating,
) async {
  final me = ref.read(authProvider)?.id;
  if (me == null) return false;

  final table = SupabaseConfig.client.from('neighborhood_ratings');
  try {
    if (rating == null) {
      await table
          .delete()
          .eq('neighborhood_id', neighborhoodId)
          .eq('profile_id', me);
    } else {
      await table.upsert({
        'neighborhood_id': neighborhoodId,
        'profile_id': me,
        'rating': rating,
      }, onConflict: 'neighborhood_id,profile_id');
    }
  } finally {
    // Read back after a refusal too, so the stars show what is really on
    // record rather than what was tried.
    ref.invalidate(myNeighborhoodRatingProvider(neighborhoodId));
    ref.invalidate(neighborhoodRatingProvider(neighborhoodId));
  }
  return true;
}
