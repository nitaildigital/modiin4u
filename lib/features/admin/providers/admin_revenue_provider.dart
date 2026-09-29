import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_table_notifier.dart';

/// Money in, on `revenue_transactions`.
///
/// A transaction is a record of something billed: a business, a
/// description, an amount, when it is due and whether it has been paid.
/// Nothing else writes this table — no payment provider is connected — so
/// the panel is where the client records them.
///
/// The screen used to filter and write `status`, `type`, `invoice_number`
/// and `payment_method`; the columns are `payment_status` (the
/// `payment_status` enum), `revenue_type` and `invoice_ref`, and the method
/// of payment lives on `payments`, not here. Every filter chip failed.
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
        // Search and the status filter run over the loaded rows — see
        // [load] — because the search also matches the business's name,
        // which is on the join, and the status column is not `status`.
        searchColumns: const [],
        columns: '*, businesses(id, name)',
        orderBy: 'created_at',
        hasStatus: false,
      );

  String? _query;
  String? _paymentStatus;

  @override
  void setSearch(String? search) {
    _query = search;
    load();
  }

  @override
  void setStatusFilter(String? status) {
    _paymentStatus = status;
    load();
  }

  @override
  Future<void> load() async {
    await super.load();
    final q = _query?.trim().toLowerCase();
    final status = _paymentStatus;
    if ((q == null || q.isEmpty) && (status == null || status.isEmpty)) {
      return;
    }

    state.whenData((rows) {
      state = AsyncValue.data(
        rows.where((r) {
          if (status != null &&
              status.isNotEmpty &&
              r['payment_status'] != status) {
            return false;
          }
          if (q == null || q.isEmpty) return true;
          final business = (r['businesses'] as Map?)?['name'] as String?;
          return [
            r['description'],
            r['invoice_ref'],
            business,
          ].any((v) => (v as String? ?? '').toLowerCase().contains(q));
        }).toList(),
      );
    });
  }

  Future<void> createTransaction(Map<String, dynamic> t) => create(t);
  Future<void> updateTransaction(String id, Map<String, dynamic> f) =>
      update(id, f);

  /// Sets the payment status. Paid stamps `paid_at` (keeping an earlier
  /// stamp if there is one); anything else clears it, so the date always
  /// belongs to a payment that stands.
  Future<void> setPaymentStatus(Map<String, dynamic> row, String status) async {
    final id = row['id'] as String;
    await updateRow('revenue_transactions', id, {
      'payment_status': status,
      'paid_at': status == 'paid'
          ? (row['paid_at'] ?? DateTime.now().toUtc().toIso8601String())
          : null,
    });
    await recordAdminAction(
      action: 'update',
      table: 'revenue_transactions',
      rowId: id,
      // `payment_status` is not one of the columns the log keeps a value
      // for, so the new state goes in the label.
      fields: const {'payment_status': null},
      label: '${row['description'] ?? ''} → $status',
    );
    await load();
  }
}
