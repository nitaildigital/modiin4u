import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_table_notifier.dart';

/// What each business has agreed to pay, on the live table.
final adminAgreementListProvider =
    StateNotifierProvider<
      AdminAgreementListNotifier,
      AsyncValue<List<Map<String, dynamic>>>
    >((ref) {
      return AdminAgreementListNotifier();
    });

class AdminAgreementListNotifier extends AdminTableNotifier {
  AdminAgreementListNotifier()
    : super(
        table: 'commercial_agreements',
        searchColumns: const ['name', 'description'],
        columns: '*, businesses(id, name)',
        orderBy: 'start_date',
        softDeleteStatus: 'cancelled',
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
      state = AsyncValue.data(rows.where((r) => r['type'] == type).toList());
    });
  }

  Future<void> createAgreement(Map<String, dynamic> a) => create(a);
  Future<void> updateAgreement(String id, Map<String, dynamic> f) =>
      update(id, f);
  Future<void> deleteAgreement(String id) => remove(id);
}
