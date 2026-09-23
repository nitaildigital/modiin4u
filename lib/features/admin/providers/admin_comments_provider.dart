import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';
import 'admin_table_notifier.dart';

/// Comments awaiting moderation, on the live table.
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

  String? _entityType;

  /// Article, business or event — where the comment was left.
  void setEntityTypeFilter(String? type) {
    _entityType = type;
    load();
  }

  @override
  Future<void> load() async {
    await super.load();
    final type = _entityType;
    if (type == null || type.isEmpty) return;

    state.whenData((rows) {
      state = AsyncValue.data(
        rows.where((r) => r['entity_type'] == type).toList(),
      );
    });
  }

  /// Hidden rather than removed, so a moderator can put it back and the
  /// thread it was replying to keeps its shape.
  Future<void> deleteComment(String id) => updateStatus(id, 'rejected');

  Future<void> toggleVisibility(String id) async {
    final row = state.valueOrNull?.firstWhere(
      (c) => c['id'] == id,
      orElse: () => const {},
    );
    final approved = row?['status'] == 'approved';
    await updateStatus(id, approved ? 'rejected' : 'approved');
  }

  /// Pinning is not a column yet — the schema has no place to keep it, so
  /// this reports rather than pretending to have saved something.
  Future<void> togglePin(String id) async {
    throw UnimplementedError(
      'comments has no pinned column; add one before offering this',
    );
  }
}
