import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminRevenueListProvider =
    StateNotifierProvider<AdminRevenueListNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return AdminRevenueListNotifier();
});

class AdminRevenueListNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  List<Map<String, dynamic>> _all = [];
  String? _search;
  String? _status;
  String? _type;

  AdminRevenueListNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    _all = List<Map<String, dynamic>>.from(_mock);
    _apply();
  }

  void _apply() {
    var list = List<Map<String, dynamic>>.from(_all);
    if (_search != null && _search!.isNotEmpty) {
      final q = _search!.toLowerCase();
      list = list.where((t) {
        final biz = (t['business_name'] as String? ?? '').toLowerCase();
        final inv = (t['invoice_number'] as String? ?? '').toLowerCase();
        return biz.contains(q) || inv.contains(q);
      }).toList();
    }
    if (_status != null && _status!.isNotEmpty) {
      list = list.where((t) => t['payment_status'] == _status).toList();
    }
    if (_type != null && _type!.isNotEmpty) {
      list = list.where((t) => t['type'] == _type).toList();
    }
    state = AsyncValue.data(list);
  }

  void setSearch(String? s) { _search = s; _apply(); }
  void setStatusFilter(String? s) { _status = s; _apply(); }
  void setTypeFilter(String? t) { _type = t; _apply(); }

  Future<void> updateStatus(String id, String status) async {
    _all = [
      for (final t in _all)
        if (t['id'] == id) {...t, 'payment_status': status, if (status == 'paid') 'paid_at': DateTime.now().toIso8601String()} else t
    ];
    _apply();
  }
}

final _mock = <Map<String, dynamic>>[
  // ── Aug 2026 ──
  {'id': 'rev_1', 'agreement_id': 'agr_1', 'business_id': 'b1', 'business_name': 'פיצה פרגו', 'amount': 299.0, 'type': 'subscription', 'description': 'מנוי Premium — אוגוסט', 'payment_method': 'credit_card', 'payment_status': 'paid', 'invoice_number': 'INV-2026-0032', 'due_date': '2026-08-01', 'paid_at': '2026-08-01T09:00:00Z', 'created_at': '2026-08-01T09:00:00Z'},
  {'id': 'rev_2', 'agreement_id': 'agr_2', 'business_id': 'b2', 'business_name': 'סופר פארם מודיעין', 'amount': 1350.0, 'type': 'banner', 'description': 'באנר ראשי — אוגוסט (10% הנחה)', 'payment_method': 'bank_transfer', 'payment_status': 'paid', 'invoice_number': 'INV-2026-0033', 'due_date': '2026-08-01', 'paid_at': '2026-08-03T10:00:00Z', 'created_at': '2026-08-01T10:00:00Z'},
  {'id': 'rev_3', 'agreement_id': 'agr_3', 'business_id': 'b3', 'business_name': 'סטודיו שרה', 'amount': 149.0, 'type': 'subscription', 'description': 'מנוי Basic — אוגוסט', 'payment_method': 'credit_card', 'payment_status': 'paid', 'invoice_number': 'INV-2026-0034', 'due_date': '2026-08-01', 'paid_at': '2026-08-01T08:00:00Z', 'created_at': '2026-08-01T08:00:00Z'},
  {'id': 'rev_4', 'agreement_id': 'agr_4', 'business_id': 'b4', 'business_name': 'ביסטרו מודיעין', 'amount': 450.0, 'type': 'featured', 'description': 'מומלץ — עמוד הבית', 'payment_method': 'credit_card', 'payment_status': 'pending', 'invoice_number': 'INV-2026-0035', 'due_date': '2026-08-15', 'created_at': '2026-08-01T10:00:00Z'},
  {'id': 'rev_5', 'agreement_id': 'agr_5', 'business_id': 'b5', 'business_name': 'FIT מודיעין', 'amount': 350.0, 'type': 'push', 'description': 'Push חודשי — אוגוסט', 'payment_method': 'credit_card', 'payment_status': 'paid', 'invoice_number': 'INV-2026-0036', 'due_date': '2026-08-01', 'paid_at': '2026-08-02T10:00:00Z', 'created_at': '2026-08-01T10:00:00Z'},
  {'id': 'rev_6', 'agreement_id': 'agr_6', 'business_id': 'b6', 'business_name': 'חנות הספרים — מילים', 'amount': 800.0, 'type': 'sponsored', 'description': 'כתבה ממומנת — יריד ספרים', 'payment_method': 'bank_transfer', 'payment_status': 'paid', 'invoice_number': 'INV-2026-0037', 'due_date': '2026-08-10', 'paid_at': '2026-08-10T09:00:00Z', 'created_at': '2026-08-05T10:00:00Z'},
  {'id': 'rev_7', 'agreement_id': 'agr_10', 'business_id': 'b10', 'business_name': 'מספרת טיפ טופ', 'amount': 250.0, 'type': 'featured', 'description': 'מומלץ — יופי וטיפוח — אוגוסט', 'payment_method': 'credit_card', 'payment_status': 'paid', 'invoice_number': 'INV-2026-0038', 'due_date': '2026-08-01', 'paid_at': '2026-08-01T10:00:00Z', 'created_at': '2026-08-01T10:00:00Z'},
  {'id': 'rev_8', 'agreement_id': 'agr_11', 'business_id': 'b11', 'business_name': 'עו"ד רחלי גולן', 'amount': 299.0, 'type': 'subscription', 'description': 'מנוי Premium — אוגוסט (שנתי)', 'payment_method': 'bank_transfer', 'payment_status': 'overdue', 'invoice_number': 'INV-2026-0039', 'due_date': '2026-08-01', 'created_at': '2026-08-01T10:00:00Z'},
  // ── Jul 2026 ──
  {'id': 'rev_9', 'agreement_id': 'agr_1', 'business_id': 'b1', 'business_name': 'פיצה פרגו', 'amount': 299.0, 'type': 'subscription', 'description': 'מנוי Premium — יולי', 'payment_method': 'credit_card', 'payment_status': 'paid', 'invoice_number': 'INV-2026-0025', 'due_date': '2026-07-01', 'paid_at': '2026-07-01T09:00:00Z', 'created_at': '2026-07-01T09:00:00Z'},
  {'id': 'rev_10', 'agreement_id': 'agr_2', 'business_id': 'b2', 'business_name': 'סופר פארם מודיעין', 'amount': 1350.0, 'type': 'banner', 'description': 'באנר ראשי — יולי', 'payment_method': 'bank_transfer', 'payment_status': 'paid', 'invoice_number': 'INV-2026-0026', 'due_date': '2026-07-01', 'paid_at': '2026-07-02T10:00:00Z', 'created_at': '2026-07-01T10:00:00Z'},
  {'id': 'rev_11', 'agreement_id': 'agr_3', 'business_id': 'b3', 'business_name': 'סטודיו שרה', 'amount': 149.0, 'type': 'subscription', 'description': 'מנוי Basic — יולי', 'payment_method': 'credit_card', 'payment_status': 'paid', 'invoice_number': 'INV-2026-0027', 'due_date': '2026-07-01', 'paid_at': '2026-07-01T08:00:00Z', 'created_at': '2026-07-01T08:00:00Z'},
  {'id': 'rev_12', 'agreement_id': 'agr_5', 'business_id': 'b5', 'business_name': 'FIT מודיעין', 'amount': 350.0, 'type': 'push', 'description': 'Push חודשי — יולי', 'payment_method': 'credit_card', 'payment_status': 'paid', 'invoice_number': 'INV-2026-0028', 'due_date': '2026-07-01', 'paid_at': '2026-07-01T10:00:00Z', 'created_at': '2026-07-01T10:00:00Z'},
  {'id': 'rev_13', 'agreement_id': 'agr_7', 'business_id': 'b7', 'business_name': 'אופטיקה הלפרין', 'amount': 254.15, 'type': 'subscription', 'description': 'מנוי Premium — יולי (15% הנחה)', 'payment_method': 'credit_card', 'payment_status': 'paid', 'invoice_number': 'INV-2026-0029', 'due_date': '2026-07-01', 'paid_at': '2026-07-01T10:00:00Z', 'created_at': '2026-07-01T10:00:00Z'},
  {'id': 'rev_14', 'agreement_id': 'agr_8', 'business_id': 'b8', 'business_name': 'מסעדת דרך הים', 'amount': 800.0, 'type': 'banner', 'description': 'באנר — מסעדות — יולי (אחרון)', 'payment_method': 'credit_card', 'payment_status': 'paid', 'invoice_number': 'INV-2026-0030', 'due_date': '2026-07-01', 'paid_at': '2026-07-03T10:00:00Z', 'created_at': '2026-07-01T10:00:00Z'},
  {'id': 'rev_15', 'agreement_id': 'agr_10', 'business_id': 'b10', 'business_name': 'מספרת טיפ טופ', 'amount': 250.0, 'type': 'featured', 'description': 'מומלץ — יופי — יולי', 'payment_method': 'credit_card', 'payment_status': 'paid', 'invoice_number': 'INV-2026-0031', 'due_date': '2026-07-01', 'paid_at': '2026-07-01T10:00:00Z', 'created_at': '2026-07-01T10:00:00Z'},
  // ── Jun 2026 ──
  {'id': 'rev_16', 'agreement_id': 'agr_1', 'business_id': 'b1', 'business_name': 'פיצה פרגו', 'amount': 299.0, 'type': 'subscription', 'description': 'מנוי Premium — יוני', 'payment_method': 'credit_card', 'payment_status': 'paid', 'invoice_number': 'INV-2026-0018', 'due_date': '2026-06-01', 'paid_at': '2026-06-01T09:00:00Z', 'created_at': '2026-06-01T09:00:00Z'},
  {'id': 'rev_17', 'agreement_id': 'agr_12', 'business_id': 'b12', 'business_name': 'פלאפל הזהב', 'amount': 2800.0, 'type': 'custom', 'description': 'חבילה מותאמת שנתית (20% הנחה)', 'payment_method': 'bank_transfer', 'payment_status': 'paid', 'invoice_number': 'INV-2026-0019', 'due_date': '2026-06-01', 'paid_at': '2026-06-04T10:00:00Z', 'created_at': '2026-06-01T10:00:00Z'},
  {'id': 'rev_18', 'agreement_id': 'agr_3', 'business_id': 'b3', 'business_name': 'סטודיו שרה', 'amount': 149.0, 'type': 'subscription', 'description': 'מנוי Basic — יוני', 'payment_method': 'credit_card', 'payment_status': 'paid', 'invoice_number': 'INV-2026-0020', 'due_date': '2026-06-01', 'paid_at': '2026-06-01T08:00:00Z', 'created_at': '2026-06-01T08:00:00Z'},
  {'id': 'rev_19', 'agreement_id': 'agr_5', 'business_id': 'b5', 'business_name': 'FIT מודיעין', 'amount': 350.0, 'type': 'push', 'description': 'Push חודשי — יוני', 'payment_method': 'credit_card', 'payment_status': 'paid', 'invoice_number': 'INV-2026-0021', 'due_date': '2026-06-01', 'paid_at': '2026-06-01T10:00:00Z', 'created_at': '2026-06-01T10:00:00Z'},
  {'id': 'rev_20', 'agreement_id': 'agr_8', 'business_id': 'b8', 'business_name': 'מסעדת דרך הים', 'amount': 800.0, 'type': 'banner', 'description': 'באנר — מסעדות — יוני', 'payment_method': 'credit_card', 'payment_status': 'paid', 'invoice_number': 'INV-2026-0022', 'due_date': '2026-06-01', 'paid_at': '2026-06-02T10:00:00Z', 'created_at': '2026-06-01T10:00:00Z'},
  // ── May 2026 ──
  {'id': 'rev_21', 'agreement_id': 'agr_1', 'business_id': 'b1', 'business_name': 'פיצה פרגו', 'amount': 299.0, 'type': 'subscription', 'description': 'מנוי Premium — מאי', 'payment_method': 'credit_card', 'payment_status': 'paid', 'invoice_number': 'INV-2026-0012', 'due_date': '2026-05-01', 'paid_at': '2026-05-01T09:00:00Z', 'created_at': '2026-05-01T09:00:00Z'},
  {'id': 'rev_22', 'agreement_id': 'agr_9', 'business_id': 'b9', 'business_name': 'גן ילדים שמש', 'amount': 149.0, 'type': 'subscription', 'description': 'מנוי Basic — מאי', 'payment_method': 'credit_card', 'payment_status': 'paid', 'invoice_number': 'INV-2026-0013', 'due_date': '2026-05-01', 'paid_at': '2026-05-01T10:00:00Z', 'created_at': '2026-05-01T10:00:00Z'},
  {'id': 'rev_23', 'agreement_id': 'agr_3', 'business_id': 'b3', 'business_name': 'סטודיו שרה', 'amount': 149.0, 'type': 'subscription', 'description': 'מנוי Basic — מאי', 'payment_method': 'credit_card', 'payment_status': 'paid', 'invoice_number': 'INV-2026-0014', 'due_date': '2026-05-01', 'paid_at': '2026-05-01T08:00:00Z', 'created_at': '2026-05-01T08:00:00Z'},
  // ── Apr 2026 ──
  {'id': 'rev_24', 'agreement_id': 'agr_1', 'business_id': 'b1', 'business_name': 'פיצה פרגו', 'amount': 299.0, 'type': 'subscription', 'description': 'מנוי Premium — אפריל', 'payment_method': 'credit_card', 'payment_status': 'paid', 'invoice_number': 'INV-2026-0006', 'due_date': '2026-04-01', 'paid_at': '2026-04-01T09:00:00Z', 'created_at': '2026-04-01T09:00:00Z'},
  {'id': 'rev_25', 'agreement_id': 'agr_8', 'business_id': 'b8', 'business_name': 'מסעדת דרך הים', 'amount': 800.0, 'type': 'banner', 'description': 'באנר — מסעדות — אפריל', 'payment_method': 'credit_card', 'payment_status': 'paid', 'invoice_number': 'INV-2026-0007', 'due_date': '2026-04-01', 'paid_at': '2026-04-02T10:00:00Z', 'created_at': '2026-04-01T10:00:00Z'},
  {'id': 'rev_26', 'agreement_id': 'agr_3', 'business_id': 'b3', 'business_name': 'סטודיו שרה', 'amount': 149.0, 'type': 'subscription', 'description': 'מנוי Basic — אפריל', 'payment_method': 'credit_card', 'payment_status': 'paid', 'invoice_number': 'INV-2026-0008', 'due_date': '2026-04-01', 'paid_at': '2026-04-01T08:00:00Z', 'created_at': '2026-04-01T08:00:00Z'},
  // ── Mar 2026 ──
  {'id': 'rev_27', 'agreement_id': 'agr_1', 'business_id': 'b1', 'business_name': 'פיצה פרגו', 'amount': 299.0, 'type': 'subscription', 'description': 'מנוי Premium — מרץ', 'payment_method': 'credit_card', 'payment_status': 'paid', 'invoice_number': 'INV-2026-0001', 'due_date': '2026-03-01', 'paid_at': '2026-03-01T09:00:00Z', 'created_at': '2026-03-01T09:00:00Z'},
  {'id': 'rev_28', 'agreement_id': 'agr_11', 'business_id': 'b11', 'business_name': 'עו"ד רחלי גולן', 'amount': 3588.0, 'type': 'subscription', 'description': 'מנוי Premium — תשלום שנתי', 'payment_method': 'bank_transfer', 'payment_status': 'paid', 'invoice_number': 'INV-2026-0002', 'due_date': '2026-01-15', 'paid_at': '2026-01-17T10:00:00Z', 'created_at': '2026-01-15T10:00:00Z'},
  // Refund
  {'id': 'rev_29', 'agreement_id': 'agr_9', 'business_id': 'b9', 'business_name': 'גן ילדים שמש', 'amount': -74.5, 'type': 'subscription', 'description': 'זיכוי — ביטול באמצע יולי', 'payment_method': 'credit_card', 'payment_status': 'refunded', 'invoice_number': 'CR-2026-0001', 'due_date': '2026-07-15', 'paid_at': '2026-07-20T10:00:00Z', 'created_at': '2026-07-15T10:00:00Z'},
];
