import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_table_notifier.dart';

/// Money in, on the live table. Read mostly: a transaction is a record of
/// something that happened, so the panel changes its status and nothing else.
final adminRevenueListProvider =
    StateNotifierProvider<
      AdminRevenueListNotifier,
      AsyncValue<List<Map<String, dynamic>>>
    >((ref) {
      return AdminRevenueListNotifier();
    });

class AdminRevenueListNotifier extends AdminTableNotifier {
  AdminRevenueListNotifier()
    : super(
        table: 'revenue_transactions',
        searchColumns: const ['description'],
        columns: '*, businesses(id, name)',
        orderBy: 'created_at',
      );

  String? _type;

  void setTypeFilter(String? type) {
    _type = type;
    load();
  }

  @override
  Future<void> load() async {
    await super.load();
    final type = _type;
    if (type == null || type.isEmpty) return;

    state.whenData((rows) {
      state = AsyncValue.data(
        rows.where((r) => r['revenue_type'] == type).toList(),
      );
    });
  }
}
