import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminOfferListProvider = StateNotifierProvider<AdminOfferListNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return AdminOfferListNotifier();
});

class AdminOfferListNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  List<Map<String, dynamic>> _allData = [];
  String? _search;
  String? _status;

  AdminOfferListNotifier() : super(const AsyncValue.loading()) { load(); }

  Future<void> load() async {
    _allData = List<Map<String, dynamic>>.from(_mockOffers);
    _applyFilters();
  }

  void _applyFilters() {
    var filtered = List<Map<String, dynamic>>.from(_allData);
    if (_search != null && _search!.isNotEmpty) {
      final q = _search!.toLowerCase();
      filtered = filtered.where((o) =>
        (o['title'] as String).toLowerCase().contains(q) ||
        (o['business_name'] as String).toLowerCase().contains(q)).toList();
    }
    if (_status != null && _status!.isNotEmpty) {
      filtered = filtered.where((o) => o['status'] == _status).toList();
    }
    state = AsyncValue.data(filtered);
  }

  void setSearch(String? s) { _search = s; _applyFilters(); }
  void setStatusFilter(String? s) { _status = s; _applyFilters(); }

  Future<void> createOffer(Map<String, dynamic> o) async {
    o['id'] = 'off_${DateTime.now().millisecondsSinceEpoch}';
    o['current_claims'] = 0;
    o['created_at'] = DateTime.now().toIso8601String();
    _allData.add(o);
    _applyFilters();
  }

  Future<void> updateOffer(String id, Map<String, dynamic> fields) async {
    final idx = _allData.indexWhere((o) => o['id'] == id);
    if (idx >= 0) { _allData[idx] = {..._allData[idx], ...fields}; _applyFilters(); }
  }

  Future<void> deleteOffer(String id) async { _allData.removeWhere((o) => o['id'] == id); _applyFilters(); }

  Future<void> updateStatus(String id, String status) async {
    final idx = _allData.indexWhere((o) => o['id'] == id);
    if (idx >= 0) { _allData[idx]['status'] = status; _applyFilters(); }
  }
}

final _mockOffers = <Map<String, dynamic>>[
  {'id': 'off_1', 'business_id': 'b1', 'business_name': 'פיצה פרגו', 'title': '20% הנחה על כל הפיצות', 'description': 'מבצע קיץ — 20% הנחה על כל סוגי הפיצות, כולל תוספות!', 'discount_type': 'percentage', 'discount_value': 20, 'original_price': null, 'discounted_price': null, 'code': 'PIZZA20', 'status': 'active', 'start_at': '2026-08-01T00:00:00Z', 'end_at': '2026-08-31T00:00:00Z', 'max_claims': 200, 'current_claims': 87, 'terms': 'לא כולל משלוח. תקף בסניף מודיעין בלבד.', 'is_featured': true, 'created_at': '2026-07-28T10:00:00Z'},
  {'id': 'off_2', 'business_id': 'b1', 'business_name': 'פיצה פרגו', 'title': 'משלוח חינם מעל ₪100', 'description': 'הזמינו מעל 100 שקל וקבלו משלוח חינם!', 'discount_type': 'gift', 'discount_value': 0, 'original_price': null, 'discounted_price': null, 'code': null, 'status': 'active', 'start_at': '2026-08-01T00:00:00Z', 'end_at': '2026-10-01T00:00:00Z', 'max_claims': null, 'current_claims': 156, 'terms': 'עד 5 ק"מ מהסניף', 'is_featured': false, 'created_at': '2026-07-30T10:00:00Z'},
  {'id': 'off_3', 'business_id': 'b3', 'business_name': 'סטודיו שרה — יוגה ופילאטיס', 'title': 'שיעור ניסיון חינם', 'description': 'בואו לנסות שיעור יוגה או פילאטיס בחינם, בלי התחייבות', 'discount_type': 'gift', 'discount_value': 0, 'original_price': 60, 'discounted_price': 0, 'code': 'TRYFREE', 'status': 'active', 'start_at': '2026-08-01T00:00:00Z', 'end_at': '2026-09-30T00:00:00Z', 'max_claims': 50, 'current_claims': 23, 'terms': 'למצטרפים חדשים בלבד. שיעור אחד לאדם.', 'is_featured': true, 'created_at': '2026-07-25T10:00:00Z'},
  {'id': 'off_4', 'business_id': 'b2', 'business_name': 'סופר פארם מודיעין', 'title': 'קנה 2 קבל 1 חינם — קרם הגנה', 'description': 'מבצע קיץ על קרם הגנה — קנה שניים וקבל את השלישי חינם!', 'discount_type': 'bogo', 'discount_value': 0, 'original_price': 60, 'discounted_price': 40, 'code': null, 'status': 'active', 'start_at': '2026-07-15T00:00:00Z', 'end_at': '2026-08-31T00:00:00Z', 'max_claims': 300, 'current_claims': 189, 'terms': 'מהמותג Neutrogena בלבד', 'is_featured': false, 'created_at': '2026-07-12T10:00:00Z'},
  {'id': 'off_5', 'business_id': 'b3', 'business_name': 'סטודיו שרה — יוגה ופילאטיס', 'title': '₪200 הנחה על מנוי שנתי', 'description': 'הירשמו למנוי שנתי וחסכו 200 ש"ח!', 'discount_type': 'fixed', 'discount_value': 200, 'original_price': 2400, 'discounted_price': 2200, 'code': 'ANNUAL200', 'status': 'active', 'start_at': '2026-08-01T00:00:00Z', 'end_at': '2026-09-15T00:00:00Z', 'max_claims': 30, 'current_claims': 11, 'terms': 'התחייבות ל-12 חודשים. לא ניתן לבטל.', 'is_featured': true, 'created_at': '2026-07-28T10:00:00Z'},
  {'id': 'off_6', 'business_id': 'b4', 'business_name': 'ביסטרו מודיעין', 'title': 'ארוחת זוגית ב-₪199', 'description': 'ארוחת שף זוגית — ראשונה, עיקרית וקינוח', 'discount_type': 'fixed', 'discount_value': 0, 'original_price': 320, 'discounted_price': 199, 'code': 'COUPLE199', 'status': 'scheduled', 'start_at': '2026-09-01T00:00:00Z', 'end_at': '2026-09-30T00:00:00Z', 'max_claims': 100, 'current_claims': 0, 'terms': 'ימים א-ד בלבד, בהזמנה מראש', 'is_featured': true, 'created_at': '2026-08-25T10:00:00Z'},
  {'id': 'off_7', 'business_id': 'b1', 'business_name': 'פיצה פרגו', 'title': 'פיצה XL במחיר רגילה', 'description': 'שדרגו לפיצה XL ושלמו מחיר של פיצה רגילה', 'discount_type': 'percentage', 'discount_value': 30, 'original_price': 65, 'discounted_price': 45, 'code': 'XLFREE', 'status': 'expired', 'start_at': '2026-06-01T00:00:00Z', 'end_at': '2026-07-31T00:00:00Z', 'max_claims': 150, 'current_claims': 142, 'terms': '', 'is_featured': false, 'created_at': '2026-05-28T10:00:00Z'},
  {'id': 'off_8', 'business_id': 'b2', 'business_name': 'סופר פארם מודיעין', 'title': '15% על כל מוצרי הטיפוח', 'description': 'סוף עונה — הנחות על כל מוצרי הטיפוח והקוסמטיקה', 'discount_type': 'percentage', 'discount_value': 15, 'original_price': null, 'discounted_price': null, 'code': null, 'status': 'active', 'start_at': '2026-08-20T00:00:00Z', 'end_at': '2026-09-10T00:00:00Z', 'max_claims': null, 'current_claims': 67, 'terms': 'לא כולל מבצעים נוספים', 'is_featured': false, 'created_at': '2026-08-18T10:00:00Z'},
  {'id': 'off_9', 'business_id': 'b3', 'business_name': 'סטודיו שרה', 'title': 'הביאו חבר/ה — שניכם חינם', 'description': 'מנויים קיימים — הביאו חבר/ה ושניכם מתאמנים חינם באותו שיעור!', 'discount_type': 'gift', 'discount_value': 0, 'original_price': 60, 'discounted_price': 0, 'code': 'FRIEND', 'status': 'active', 'start_at': '2026-08-01T00:00:00Z', 'end_at': '2026-12-31T00:00:00Z', 'max_claims': null, 'current_claims': 34, 'terms': 'חבר/ה שלא היה/הייתה מנוי. פעם אחת בחודש.', 'is_featured': false, 'created_at': '2026-07-28T10:00:00Z'},
  {'id': 'off_10', 'business_id': 'b1', 'business_name': 'פיצה פרגו', 'title': 'Happy Hour — 16:00-18:00', 'description': 'כל יום בין 16:00-18:00 — 25% הנחה על הזמנה במקום', 'discount_type': 'percentage', 'discount_value': 25, 'original_price': null, 'discounted_price': null, 'code': null, 'status': 'active', 'start_at': '2026-01-01T00:00:00Z', 'end_at': '2026-12-31T00:00:00Z', 'max_claims': null, 'current_claims': 445, 'terms': 'בישיבה במקום בלבד. לא כולל שתייה.', 'is_featured': false, 'created_at': '2026-01-01T10:00:00Z'},
  {'id': 'off_11', 'business_id': 'b2', 'business_name': 'סופר פארם', 'title': '₪10 הנחה על הזמנה ראשונה', 'description': 'לקוחות חדשים באפליקציה — ₪10 הנחה', 'discount_type': 'fixed', 'discount_value': 10, 'original_price': null, 'discounted_price': null, 'code': 'WELCOME10', 'status': 'draft', 'start_at': null, 'end_at': null, 'max_claims': 500, 'current_claims': 0, 'terms': 'להזמנה ראשונה בלבד', 'is_featured': false, 'created_at': '2026-08-27T10:00:00Z'},
  {'id': 'off_12', 'business_id': 'b4', 'business_name': 'ביסטרו מודיעין', 'title': 'ארוחת צהריים עסקית ב-₪59', 'description': 'כל יום א-ה, 12:00-15:00 — ארוחה עסקית מלאה', 'discount_type': 'fixed', 'discount_value': 0, 'original_price': 85, 'discounted_price': 59, 'code': null, 'status': 'scheduled', 'start_at': '2026-09-01T00:00:00Z', 'end_at': '2026-12-31T00:00:00Z', 'max_claims': null, 'current_claims': 0, 'terms': 'בישיבה במקום בלבד', 'is_featured': false, 'created_at': '2026-08-26T10:00:00Z'},
  {'id': 'off_13', 'business_id': 'b3', 'business_name': 'סטודיו שרה', 'title': 'כרטיסיית 10 שיעורים ב-₪450', 'description': 'חסכו 150 ש"ח עם כרטיסייה של 10 שיעורים', 'discount_type': 'percentage', 'discount_value': 25, 'original_price': 600, 'discounted_price': 450, 'code': 'CARD10', 'status': 'active', 'start_at': '2026-01-01T00:00:00Z', 'end_at': '2026-12-31T00:00:00Z', 'max_claims': null, 'current_claims': 89, 'terms': 'תוקף הכרטיסייה: 3 חודשים', 'is_featured': false, 'created_at': '2026-01-01T10:00:00Z'},
  {'id': 'off_14', 'business_id': 'b1', 'business_name': 'פיצה פרגו', 'title': 'יום הולדת — פיצה חינם!', 'description': 'חוגגים יום הולדת? הציגו תעודת זהות וקבלו פיצה אישית חינם', 'discount_type': 'gift', 'discount_value': 0, 'original_price': 35, 'discounted_price': 0, 'code': null, 'status': 'active', 'start_at': '2024-01-01T00:00:00Z', 'end_at': '2027-12-31T00:00:00Z', 'max_claims': null, 'current_claims': 312, 'terms': 'ביום ההולדת בלבד ±3 ימים', 'is_featured': false, 'created_at': '2024-01-01T10:00:00Z'},
  {'id': 'off_15', 'business_id': 'b2', 'business_name': 'סופר פארם', 'title': 'מבצע Back to School', 'description': 'הנחות על ציוד לבית הספר', 'discount_type': 'percentage', 'discount_value': 20, 'original_price': null, 'discounted_price': null, 'code': 'BTS20', 'status': 'expired', 'start_at': '2026-08-01T00:00:00Z', 'end_at': '2026-08-20T00:00:00Z', 'max_claims': null, 'current_claims': 234, 'terms': 'על מגוון מוצרים מסומנים', 'is_featured': false, 'created_at': '2026-07-28T10:00:00Z'},
];
