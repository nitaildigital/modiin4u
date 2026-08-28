import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminAgreementListProvider =
    StateNotifierProvider<AdminAgreementListNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return AdminAgreementListNotifier();
});

class AdminAgreementListNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  List<Map<String, dynamic>> _all = [];
  String? _search;
  String? _status;
  String? _type;

  AdminAgreementListNotifier() : super(const AsyncValue.loading()) {
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
      list = list.where((a) {
        final name = (a['business_name'] as String? ?? '').toLowerCase();
        final aName = (a['name'] as String? ?? '').toLowerCase();
        return name.contains(q) || aName.contains(q);
      }).toList();
    }
    if (_status != null && _status!.isNotEmpty) {
      list = list.where((a) => a['status'] == _status).toList();
    }
    if (_type != null && _type!.isNotEmpty) {
      list = list.where((a) => a['type'] == _type).toList();
    }
    state = AsyncValue.data(list);
  }

  void setSearch(String? s) { _search = s; _apply(); }
  void setStatusFilter(String? s) { _status = s; _apply(); }
  void setTypeFilter(String? t) { _type = t; _apply(); }

  Future<void> createAgreement(Map<String, dynamic> a) async {
    a['id'] = 'agr_${DateTime.now().millisecondsSinceEpoch}';
    a['created_at'] = DateTime.now().toIso8601String();
    a['updated_at'] = DateTime.now().toIso8601String();
    _all.insert(0, a);
    _apply();
  }

  Future<void> updateAgreement(String id, Map<String, dynamic> fields) async {
    _all = [
      for (final a in _all)
        if (a['id'] == id) {...a, ...fields, 'updated_at': DateTime.now().toIso8601String()} else a
    ];
    _apply();
  }

  Future<void> deleteAgreement(String id) async {
    _all.removeWhere((a) => a['id'] == id);
    _apply();
  }

  Future<void> updateStatus(String id, String status) async {
    await updateAgreement(id, {'status': status});
  }
}

final _mock = <Map<String, dynamic>>[
  {
    'id': 'agr_1', 'business_id': 'b1', 'business_name': 'פיצה פרגו',
    'type': 'subscription', 'name': 'מנוי Premium',
    'description': 'חבילת Premium — עמוד עסקי מורחב, הופעה ראשונה בחיפוש, תג מאומת',
    'price': 299.0, 'vat_included': true, 'discount_pct': 0.0,
    'billing_cycle': 'monthly', 'start_date': '2026-01-01', 'end_date': '2027-01-01',
    'auto_renew': true, 'status': 'active', 'salesperson': 'ניתאי לוי',
    'notes': 'לקוח מרוצה, שוקל לשדרג לבאנר',
    'created_at': '2026-01-01T10:00:00Z', 'updated_at': '2026-08-01T10:00:00Z',
  },
  {
    'id': 'agr_2', 'business_id': 'b2', 'business_name': 'סופר פארם מודיעין',
    'type': 'banner', 'name': 'באנר ראשי — ראש עמוד הבית',
    'description': 'באנר 728x90 בעמוד הבית, חודשיים',
    'price': 1500.0, 'vat_included': true, 'discount_pct': 10.0,
    'billing_cycle': 'monthly', 'start_date': '2026-07-01', 'end_date': '2026-09-01',
    'auto_renew': false, 'status': 'active', 'salesperson': 'ניתאי לוי',
    'created_at': '2026-06-20T10:00:00Z', 'updated_at': '2026-07-01T10:00:00Z',
  },
  {
    'id': 'agr_3', 'business_id': 'b3', 'business_name': 'סטודיו שרה — יוגה ופילאטיס',
    'type': 'subscription', 'name': 'מנוי Basic',
    'description': 'חבילת Basic — עמוד עסקי, הופעה בחיפוש',
    'price': 149.0, 'vat_included': true, 'discount_pct': 0.0,
    'billing_cycle': 'monthly', 'start_date': '2026-03-01', 'end_date': '2027-03-01',
    'auto_renew': true, 'status': 'active', 'salesperson': 'ניתאי לוי',
    'created_at': '2026-03-01T10:00:00Z', 'updated_at': '2026-03-01T10:00:00Z',
  },
  {
    'id': 'agr_4', 'business_id': 'b4', 'business_name': 'ביסטרו מודיעין',
    'type': 'featured', 'name': 'מומלץ — עמוד הבית',
    'description': 'הופעה בסקשן "מומלצים" בעמוד הבית למשך חודש',
    'price': 450.0, 'vat_included': true, 'discount_pct': 0.0,
    'billing_cycle': 'one_time', 'start_date': '2026-08-01', 'end_date': '2026-09-01',
    'auto_renew': false, 'status': 'active', 'salesperson': 'ניתאי לוי',
    'created_at': '2026-07-25T10:00:00Z', 'updated_at': '2026-08-01T10:00:00Z',
  },
  {
    'id': 'agr_5', 'business_id': 'b5', 'business_name': 'מכון כושר FIT מודיעין',
    'type': 'push', 'name': 'Push חודשי — 4 הודעות',
    'description': '4 הודעות Push ממותגות בחודש לכל המשתמשים',
    'price': 350.0, 'vat_included': true, 'discount_pct': 0.0,
    'billing_cycle': 'monthly', 'start_date': '2026-06-01', 'end_date': '2026-12-01',
    'auto_renew': true, 'status': 'active', 'salesperson': 'ניתאי לוי',
    'created_at': '2026-05-20T10:00:00Z', 'updated_at': '2026-06-01T10:00:00Z',
  },
  {
    'id': 'agr_6', 'business_id': 'b6', 'business_name': 'חנות הספרים — מילים',
    'type': 'sponsored', 'name': 'כתבה ממומנת — יריד ספרים',
    'description': 'כתבה ממומנת + push על יריד ספרי ילדים',
    'price': 800.0, 'vat_included': true, 'discount_pct': 0.0,
    'billing_cycle': 'one_time', 'start_date': '2026-08-10', 'end_date': '2026-08-20',
    'auto_renew': false, 'status': 'active', 'salesperson': 'ניתאי לוי',
    'created_at': '2026-08-05T10:00:00Z', 'updated_at': '2026-08-10T10:00:00Z',
  },
  {
    'id': 'agr_7', 'business_id': 'b7', 'business_name': 'אופטיקה הלפרין',
    'type': 'subscription', 'name': 'מנוי Premium',
    'description': 'חבילת Premium — עמוד מורחב, חיפוש, תג מאומת',
    'price': 299.0, 'vat_included': true, 'discount_pct': 15.0,
    'billing_cycle': 'monthly', 'start_date': '2026-02-01', 'end_date': '2027-02-01',
    'auto_renew': true, 'status': 'paused',
    'notes': 'ביקש להשהות בזמן שיפוץ החנות',
    'created_at': '2026-02-01T10:00:00Z', 'updated_at': '2026-07-15T10:00:00Z',
  },
  {
    'id': 'agr_8', 'business_id': 'b8', 'business_name': 'מסעדת דרך הים',
    'type': 'banner', 'name': 'באנר — עמוד מסעדות',
    'description': 'באנר inline בעמוד קטגוריית מסעדות',
    'price': 800.0, 'vat_included': true, 'discount_pct': 0.0,
    'billing_cycle': 'monthly', 'start_date': '2026-04-01', 'end_date': '2026-07-01',
    'auto_renew': false, 'status': 'expired',
    'created_at': '2026-03-20T10:00:00Z', 'updated_at': '2026-07-01T10:00:00Z',
  },
  {
    'id': 'agr_9', 'business_id': 'b9', 'business_name': 'גן ילדים שמש',
    'type': 'subscription', 'name': 'מנוי Basic',
    'description': 'חבילת Basic',
    'price': 149.0, 'vat_included': true, 'discount_pct': 0.0,
    'billing_cycle': 'monthly', 'start_date': '2026-05-01', 'end_date': '2026-08-01',
    'auto_renew': false, 'status': 'cancelled',
    'cancelled_at': '2026-07-15T10:00:00Z', 'cancel_reason': 'לא חידש — עבר לפייסבוק',
    'created_at': '2026-05-01T10:00:00Z', 'updated_at': '2026-07-15T10:00:00Z',
  },
  {
    'id': 'agr_10', 'business_id': 'b10', 'business_name': 'מספרת טיפ טופ',
    'type': 'featured', 'name': 'מומלץ — יופי וטיפוח',
    'description': 'הופעה ראשונה בקטגוריית יופי וטיפוח',
    'price': 250.0, 'vat_included': true, 'discount_pct': 0.0,
    'billing_cycle': 'monthly', 'start_date': '2026-07-01', 'end_date': '2026-10-01',
    'auto_renew': true, 'status': 'active', 'salesperson': 'ניתאי לוי',
    'created_at': '2026-06-25T10:00:00Z', 'updated_at': '2026-07-01T10:00:00Z',
  },
  {
    'id': 'agr_11', 'business_id': 'b11', 'business_name': 'עו"ד רחלי גולן',
    'type': 'subscription', 'name': 'מנוי Premium',
    'description': 'חבילת Premium — עמוד מורחב, תג מאומת',
    'price': 299.0, 'vat_included': true, 'discount_pct': 0.0,
    'billing_cycle': 'yearly', 'start_date': '2026-01-15', 'end_date': '2027-01-15',
    'auto_renew': true, 'status': 'active', 'salesperson': 'ניתאי לוי',
    'created_at': '2026-01-10T10:00:00Z', 'updated_at': '2026-01-15T10:00:00Z',
  },
  {
    'id': 'agr_12', 'business_id': 'b12', 'business_name': 'פלאפל הזהב',
    'type': 'custom', 'name': 'חבילה מותאמת — שיווק מלא',
    'description': 'באנר + push + מומלץ + כתבה ממומנת — חבילה שנתית',
    'price': 3500.0, 'vat_included': true, 'discount_pct': 20.0,
    'billing_cycle': 'yearly', 'start_date': '2026-06-01', 'end_date': '2027-06-01',
    'auto_renew': true, 'status': 'active', 'salesperson': 'ניתאי לוי',
    'notes': 'לקוח VIP, הנחה מיוחדת',
    'created_at': '2026-05-20T10:00:00Z', 'updated_at': '2026-06-01T10:00:00Z',
  },
];
