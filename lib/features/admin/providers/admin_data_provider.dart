import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';
import 'admin_table_notifier.dart';

/// Which residents the list is narrowed to.
///
/// `profiles` has no `status` column, so the shared status filter does not
/// apply here; these are the two states the table actually records.
enum ProfileFilter { all, banned, verified }

/// Residents with an account, on the live table.
///
/// This file held six invented people, four invented businesses, four
/// invented articles and three invented reviews in memory, and the dashboard
/// edited them: banning someone, approving a business or deleting a review
/// changed a list and wrote nothing, so the client would have believed he had
/// acted when he had not. Businesses and articles already have live
/// providers of their own (`admin_businesses_provider`,
/// `admin_articles_provider`), which is what the panel's own sections use, so
/// only these two were missing.
final adminProfilesProvider =
    StateNotifierProvider<
      AdminProfilesNotifier,
      AsyncValue<List<Map<String, dynamic>>>
    >((ref) {
      return AdminProfilesNotifier();
    });

class AdminProfilesNotifier extends AdminTableNotifier {
  AdminProfilesNotifier()
    : super(
        table: 'profiles',
        searchColumns: const ['full_name', 'email', 'phone'],
        columns: '*, neighborhoods(id, name)',
        orderBy: 'created_at',
        hasStatus: false,
        // Points and level are moved by the gamification triggers, not by
        // anyone editing a profile here.
        readOnlyColumns: const {
          'id',
          'created_at',
          'updated_at',
          'points',
          'level',
        },
      );

  ProfileFilter _filter = ProfileFilter.all;

  void setFilter(ProfileFilter filter) {
    _filter = filter;
    load();
  }

  @override
  Future<void> load() async {
    await super.load();
    if (_filter == ProfileFilter.all) return;

    state.whenData((rows) {
      state = AsyncValue.data(
        rows.where((r) {
          return switch (_filter) {
            ProfileFilter.banned => r['is_banned'] == true,
            ProfileFilter.verified => r['is_verified'] == true,
            ProfileFilter.all => true,
          };
        }).toList(),
      );
    });
  }

  Future<void> updateProfile(String id, Map<String, dynamic> fields) =>
      update(id, fields);

  /// Bans or reinstates someone.
  ///
  /// This is the panel's only way of removing a resident: `profiles.id`
  /// points at `auth.users`, and deleting the row would take their reviews
  /// and comments with it while leaving the account able to sign in again.
  Future<void> setBanned(String id, bool banned) async {
    await SupabaseConfig.client
        .from('profiles')
        .update({
          'is_banned': banned,
          if (!banned) 'ban_reason': null,
        })
        .eq('id', id);
    await load();
  }
}

/// Reviews awaiting moderation, on the live table.
///
/// `reviews` has no rows today, so this list is legitimately empty. Approving
/// one matters more than it looks: migration 00025 recomputes the business's
/// rating and review count from approved reviews only, so the status set here
/// is what moves the stars on the business page.
final adminReviewsProvider =
    StateNotifierProvider<
      AdminReviewsNotifier,
      AsyncValue<List<Map<String, dynamic>>>
    >((ref) {
      return AdminReviewsNotifier();
    });

class AdminReviewsNotifier extends AdminTableNotifier {
  AdminReviewsNotifier()
    : super(
        table: 'reviews',
        searchColumns: const ['title', 'body'],
        // `reviews` references `profiles` twice — the author and whoever
        // answered — so the author join has to name its constraint.
        columns:
            '*, profiles!reviews_author_id_fkey(id, full_name), '
            'businesses!reviews_business_id_fkey(id, name)',
        orderBy: 'created_at',
      );

  Future<void> approve(String id) => updateStatus(id, 'approved');

  Future<void> reject(String id) => updateStatus(id, 'rejected');
}
