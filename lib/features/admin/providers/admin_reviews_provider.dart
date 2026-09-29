import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';
import 'admin_table_notifier.dart';

/// Business reviews, for moderation.
///
/// The panel's first version of this joined each review to its author's
/// profile for the name. Profiles are private since migration 00027, and
/// 00029 copied the name and avatar onto the review itself for exactly that
/// reason — the website prints `author_name`, not the profile. This reads the
/// review's own columns, so the panel shows the name the website shows.
final adminReviewListProvider =
    StateNotifierProvider<
      AdminReviewListNotifier,
      AsyncValue<List<Map<String, dynamic>>>
    >((ref) {
      return AdminReviewListNotifier();
    });

class AdminReviewListNotifier extends AdminTableNotifier {
  AdminReviewListNotifier()
    : super(
        table: 'reviews',
        searchColumns: const ['author_name', 'title', 'body'],
        // `reviews` references `profiles` twice (the author and whoever
        // replied) but `businesses` once; the hint keeps the embed exact.
        columns: '*, businesses!reviews_business_id_fkey(id, name, slug)',
        orderBy: 'created_at',
      );

  /// Approved reviews are the only ones that count towards a business's
  /// rating (migration 00025), and the only ones the website shows.
  Future<void> approve(String id) => updateStatus(id, 'approved');
  Future<void> reject(String id) => updateStatus(id, 'rejected');

  /// Off the website without passing judgement on it — for a review that is
  /// fine but, say, about a business that has since changed hands.
  Future<void> hide(String id) => updateStatus(id, 'hidden');

  /// Writes, replaces or — given nothing — removes the reply on a review.
  ///
  /// `responded_by` and `responded_at` are set with it so the reply is
  /// attributable and dated; the time is sent in UTC with its zone, since a
  /// zoneless time would be stored three hours out.
  Future<void> reply(String id, String? text) async {
    final body = text?.trim() ?? '';
    await SupabaseConfig.client
        .from('reviews')
        .update(
          body.isEmpty
              ? {
                  'admin_response': null,
                  'responded_by': null,
                  'responded_at': null,
                }
              : {
                  'admin_response': body,
                  'responded_by': SupabaseConfig.client.auth.currentUser?.id,
                  'responded_at': DateTime.now().toUtc().toIso8601String(),
                },
        )
        .eq('id', id);
    await load();
  }
}
