import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_table_notifier.dart';

/// Comments awaiting moderation, on the live table.
///
/// The app writes them: replies to reviews on a business page, and comments
/// on articles (00071). Both go up at once unless Settings ask for approval.
final adminCommentsProvider =
    StateNotifierProvider<
      AdminCommentsNotifier,
      AsyncValue<List<Map<String, dynamic>>>
    >((ref) {
      return AdminCommentsNotifier();
    });

class AdminCommentsNotifier extends AdminTableNotifier {
  AdminCommentsNotifier()
    : super(
        table: 'comments',
        searchColumns: const ['body'],
        columns: '*, profiles!comments_author_id_fkey(id, full_name)',
        orderBy: 'created_at',
      );

  /// Article, business or event — where the comment was left.
  void setEntityTypeFilter(String? type) =>
      setColumnFilter('entity_type', type);

  Future<void> approve(String id) => updateStatus(id, 'approved');

  Future<void> reject(String id) => updateStatus(id, 'rejected');

  /// Taken off the site but kept, so a moderator can put it back and the
  /// thread it was replying to keeps its shape. It appears in the trash.
  Future<void> hide(String id) => updateStatus(id, 'hidden');
}
