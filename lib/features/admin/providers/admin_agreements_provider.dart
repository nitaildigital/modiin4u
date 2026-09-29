import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_table_notifier.dart';

/// What each business has agreed to pay, on `commercial_agreements`.
///
/// The row points at its business and salesperson by id (`business_id`,
/// `salesperson_id` → `admin_users`); the form used to write the names into
/// `business_name` and `salesperson`, which are not columns, so no agreement
/// could be saved. `status` is free text in the table; the panel uses the
/// four words the migration's comment lists: active, paused, cancelled,
/// expired.
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
        // The search also matches the business's name, which is on the
        // join, so it runs over the loaded rows instead — see [load].
        searchColumns: const [],
        columns: '*, businesses(id, name)',
        orderBy: 'start_date',
        softDeleteStatus: 'cancelled',
      );

  String? _query;

  @override
  void setSearch(String? search) {
    _query = search;
    load();
  }

  @override
  Future<void> load() async {
    await super.load();
    final q = _query?.trim().toLowerCase();
    if (q == null || q.isEmpty) return;

    state.whenData((rows) {
      state = AsyncValue.data(
        rows.where((r) {
          final business = (r['businesses'] as Map?)?['name'] as String?;
          return [
            r['name'],
            r['description'],
            business,
          ].any((v) => (v as String? ?? '').toLowerCase().contains(q));
        }).toList(),
      );
    });
  }

  Future<void> createAgreement(Map<String, dynamic> a) => create(a);
  Future<void> updateAgreement(String id, Map<String, dynamic> f) =>
      update(id, f);

  /// Cancelling stamps `cancelled_at`; putting one back clears it, so the
  /// date always belongs to the cancellation that is in force.
  @override
  Future<void> updateStatus(String id, String status) async {
    final before = state.valueOrNull?.firstWhere(
      (r) => r['id'] == id,
      orElse: () => const {},
    );
    final fields = {
      'status': status,
      'cancelled_at': status == 'cancelled'
          ? DateTime.now().toUtc().toIso8601String()
          : null,
    };
    await updateRow('commercial_agreements', id, fields);
    await recordAdminAction(
      action: auditActionFor(fields),
      table: 'commercial_agreements',
      rowId: id,
      fields: fields,
      before: before,
      label: before?['name'] as String?,
    );
    await load();
  }
}
