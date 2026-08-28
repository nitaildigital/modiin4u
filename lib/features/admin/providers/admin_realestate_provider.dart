import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminListingListProvider = StateNotifierProvider<AdminListingListNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return AdminListingListNotifier();
});

class AdminListingListNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  List<Map<String, dynamic>> _all = List.from(_mockListings);
  String? _search;
  String? _status;
  String? _type;

  AdminListingListNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      var filtered = List<Map<String, dynamic>>.from(_all);
      if (_type != null && _type!.isNotEmpty) {
        filtered = filtered.where((l) => l['type'] == _type).toList();
      }
      if (_status != null && _status!.isNotEmpty) {
        filtered = filtered.where((l) => l['status'] == _status).toList();
      }
      if (_search != null && _search!.isNotEmpty) {
        final q = _search!.toLowerCase();
        filtered = filtered.where((l) {
          final address = (l['address'] as String? ?? '').toLowerCase();
          final neighborhood = (l['neighborhood'] as String? ?? '').toLowerCase();
          return address.contains(q) || neighborhood.contains(q);
        }).toList();
      }
      state = AsyncValue.data(filtered);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void setSearch(String? search) {
    _search = search;
    load();
  }

  void setStatusFilter(String? status) {
    _status = status;
    load();
  }

  void setTypeFilter(String? type) {
    _type = type;
    load();
  }

  Future<void> createListing(Map<String, dynamic> listing) async {
    listing['id'] = 'lst_${DateTime.now().millisecondsSinceEpoch}';
    listing['created_at'] = DateTime.now().toIso8601String();
    _all = [listing, ..._all];
    await load();
  }

  Future<void> updateListing(String id, Map<String, dynamic> fields) async {
    _all = [
      for (final l in _all)
        if (l['id'] == id) {...l, ...fields} else l,
    ];
    await load();
  }

  Future<void> deleteListing(String id) async {
    _all = _all.where((l) => l['id'] != id).toList();
    await load();
  }

  Future<void> updateStatus(String id, String status) async {
    await updateListing(id, {'status': status});
  }
}

// ─── Mock Listings ───

final _mockListings = <Map<String, dynamic>>[
  // ─── Rentals ───
  {
    'id': 'lst1', 'type': 'rent', 'price': 5500, 'neighborhood': 'הנחלים',
    'rooms': 3, 'sqm': 85, 'floor': 2, 'total_floors': 5,
    'address': 'רח׳ הנחל 14, הנחלים',
    'description': 'דירת 3 חדרים מרווחת עם מרפסת שמש. קרובה לגן ילדים ופארק.',
    'status': 'active', 'contact_name': 'יוסי כהן', 'contact_phone': '050-1112233',
    'is_broker': true, 'has_parking': true, 'has_elevator': true,
    'has_balcony': true, 'has_storage': true, 'has_mamad': true,
    'is_furnished': false, 'is_featured': false,
    'view_count': 234, 'created_at': '2026-08-10T10:00:00Z',
  },
  {
    'id': 'lst2', 'type': 'rent', 'price': 7200, 'neighborhood': 'אבני חן',
    'rooms': 4, 'sqm': 110, 'floor': 4, 'total_floors': 6,
    'address': 'רח׳ הדקל 22, אבני חן',
    'description': 'דירת 4 חדרים מושקעת. מטבח חדש, שתי מרפסות.',
    'status': 'active', 'contact_name': 'מיכל לוי', 'contact_phone': '054-4445566',
    'is_broker': false, 'has_parking': true, 'has_elevator': true,
    'has_balcony': true, 'has_storage': true, 'has_mamad': true,
    'is_furnished': false, 'is_featured': true,
    'view_count': 456, 'created_at': '2026-08-08T10:00:00Z',
  },
  {
    'id': 'lst3', 'type': 'rent', 'price': 5800, 'neighborhood': 'מרכז העיר',
    'rooms': 3, 'sqm': 90, 'floor': 1, 'total_floors': 4,
    'address': 'רח׳ לב העיר 8, מרכז העיר',
    'description': 'דירת 3 חדרים במרכז העיר. נגישה, ליד תחבורה ציבורית.',
    'status': 'active', 'contact_name': 'דני שמעון', 'contact_phone': '052-7778899',
    'is_broker': true, 'has_parking': false, 'has_elevator': false,
    'has_balcony': true, 'has_storage': false, 'has_mamad': true,
    'is_furnished': false, 'is_featured': false,
    'view_count': 189, 'created_at': '2026-08-15T10:00:00Z',
  },
  {
    'id': 'lst4', 'type': 'rent', 'price': 9500, 'neighborhood': 'נופים',
    'rooms': 5, 'sqm': 130, 'floor': 6, 'total_floors': 8,
    'address': 'רח׳ הנוף 3, נופים',
    'description': 'פנטהאוז 5 חדרים עם נוף פנורמי. מרפסת ענקית, חניה כפולה.',
    'status': 'active', 'contact_name': 'אברהם גולד', 'contact_phone': '050-9990001',
    'is_broker': false, 'has_parking': true, 'has_elevator': true,
    'has_balcony': true, 'has_storage': true, 'has_mamad': true,
    'is_furnished': true, 'is_featured': true,
    'view_count': 678, 'created_at': '2026-08-05T10:00:00Z',
  },
  {
    'id': 'lst5', 'type': 'rent', 'price': 6800, 'neighborhood': 'הכרמים',
    'rooms': 4, 'sqm': 105, 'floor': 3, 'total_floors': 5,
    'address': 'רח׳ הגפן 17, הכרמים',
    'description': '4 חדרים, שיפוץ חדש, מטבח מודרני. שכונה שקטה.',
    'status': 'active', 'contact_name': 'שרה אברהם', 'contact_phone': '053-2223344',
    'is_broker': true, 'has_parking': true, 'has_elevator': true,
    'has_balcony': true, 'has_storage': true, 'has_mamad': true,
    'is_furnished': false, 'is_featured': false,
    'view_count': 312, 'created_at': '2026-08-12T10:00:00Z',
  },
  {
    'id': 'lst6', 'type': 'rent', 'price': 6200, 'neighborhood': 'מוריה',
    'rooms': 3, 'sqm': 95, 'floor': 5, 'total_floors': 7,
    'address': 'רח׳ ההר 11, מוריה',
    'description': 'דירה בקומה גבוהה עם נוף. 3 חדרים, מרווחת ושקטה.',
    'status': 'rented', 'contact_name': 'רונית פרידמן', 'contact_phone': '054-5556677',
    'is_broker': false, 'has_parking': true, 'has_elevator': true,
    'has_balcony': true, 'has_storage': false, 'has_mamad': true,
    'is_furnished': false, 'is_featured': false,
    'view_count': 145, 'created_at': '2026-07-20T10:00:00Z',
  },
  {
    'id': 'lst7', 'type': 'rent', 'price': 4800, 'neighborhood': 'בוכמן',
    'rooms': 2.5, 'sqm': 70, 'floor': 1, 'total_floors': 4,
    'address': 'רח׳ האלה 5, בוכמן',
    'description': 'דירת 2.5 חדרים מתאימה לזוג צעיר או סטודנט. מחיר נוח.',
    'status': 'active', 'contact_name': 'עמית רז', 'contact_phone': '058-8889900',
    'is_broker': false, 'has_parking': false, 'has_elevator': false,
    'has_balcony': true, 'has_storage': false, 'has_mamad': true,
    'is_furnished': true, 'is_featured': false,
    'view_count': 98, 'created_at': '2026-08-18T10:00:00Z',
  },
  {
    'id': 'lst8', 'type': 'rent', 'price': 8200, 'neighborhood': 'הפרחים',
    'rooms': 4.5, 'sqm': 120, 'floor': 3, 'total_floors': 5,
    'address': 'רח׳ הנרקיס 9, הפרחים',
    'description': 'דירת 4.5 חדרים חדשה. שני חדרי רחצה, מטבח פתוח.',
    'status': 'pending', 'contact_name': 'נועם ביטון', 'contact_phone': '050-3334455',
    'is_broker': true, 'has_parking': true, 'has_elevator': true,
    'has_balcony': true, 'has_storage': true, 'has_mamad': true,
    'is_furnished': false, 'is_featured': false,
    'view_count': 0, 'created_at': '2026-08-25T10:00:00Z',
  },

  // ─── Sales ───
  {
    'id': 'lst9', 'type': 'sale', 'price': 2450000, 'neighborhood': 'הפרחים',
    'rooms': 4, 'sqm': 110, 'floor': 3, 'total_floors': 6,
    'address': 'רח׳ הכלנית 7, הפרחים',
    'description': '4 חדרים, שמורה ומטופחת. ליד פארק ובית ספר.',
    'status': 'active', 'contact_name': 'גלית שלום', 'contact_phone': '052-1113344',
    'is_broker': false, 'has_parking': true, 'has_elevator': true,
    'has_balcony': true, 'has_storage': true, 'has_mamad': true,
    'is_furnished': false, 'is_featured': false,
    'view_count': 567, 'created_at': '2026-08-01T10:00:00Z',
  },
  {
    'id': 'lst10', 'type': 'sale', 'price': 3100000, 'neighborhood': 'אבני חן',
    'rooms': 5, 'sqm': 140, 'floor': 7, 'total_floors': 9,
    'address': 'שד׳ הדקלים 30, אבני חן',
    'description': '5 חדרים בשכונה המבוקשת ביותר. מרפסת נוף, חניה כפולה.',
    'status': 'active', 'contact_name': 'מתווך — אלי נדל"ן', 'contact_phone': '08-9717777',
    'is_broker': true, 'has_parking': true, 'has_elevator': true,
    'has_balcony': true, 'has_storage': true, 'has_mamad': true,
    'is_furnished': false, 'is_featured': true,
    'view_count': 1234, 'created_at': '2026-07-15T10:00:00Z',
  },
  {
    'id': 'lst11', 'type': 'sale', 'price': 1950000, 'neighborhood': 'המע"ר',
    'rooms': 3, 'sqm': 85, 'floor': 2, 'total_floors': 5,
    'address': 'רח׳ התעשייה 4, המע"ר',
    'description': '3 חדרים ליד הרכבת. מתאים להשקעה.',
    'status': 'active', 'contact_name': 'יואב כהן', 'contact_phone': '050-2225566',
    'is_broker': false, 'has_parking': true, 'has_elevator': true,
    'has_balcony': false, 'has_storage': true, 'has_mamad': true,
    'is_furnished': false, 'is_featured': false,
    'view_count': 389, 'created_at': '2026-08-05T10:00:00Z',
  },
  {
    'id': 'lst12', 'type': 'sale', 'price': 4200000, 'neighborhood': 'נופים',
    'rooms': 6, 'sqm': 180, 'floor': 0, 'total_floors': 2,
    'address': 'רח׳ הגבעה 1, נופים',
    'description': 'קוטג׳ 6 חדרים עם גינה ובריכה פרטית. בית חלומות.',
    'status': 'active', 'contact_name': 'מתווך — נדלן מודיעין', 'contact_phone': '08-9718888',
    'is_broker': true, 'has_parking': true, 'has_elevator': false,
    'has_balcony': true, 'has_storage': true, 'has_mamad': true,
    'is_furnished': false, 'is_featured': true,
    'view_count': 2100, 'created_at': '2026-07-10T10:00:00Z',
  },
  {
    'id': 'lst13', 'type': 'sale', 'price': 3800000, 'neighborhood': 'מוריה',
    'rooms': 5, 'sqm': 160, 'floor': 12, 'total_floors': 14,
    'address': 'מגדלי מוריה, מוריה',
    'description': 'פנטהאוז 5 חדרים בקומה 12. נוף חסר תקדים. 3 כיווני אוויר.',
    'status': 'active', 'contact_name': 'שרית גבע', 'contact_phone': '054-6667788',
    'is_broker': false, 'has_parking': true, 'has_elevator': true,
    'has_balcony': true, 'has_storage': true, 'has_mamad': true,
    'is_furnished': false, 'is_featured': true,
    'view_count': 1890, 'created_at': '2026-07-20T10:00:00Z',
  },
  {
    'id': 'lst14', 'type': 'sale', 'price': 2700000, 'neighborhood': 'הנחלים',
    'rooms': 4, 'sqm': 120, 'floor': 5, 'total_floors': 7,
    'address': 'רח׳ הנחל 25, הנחלים',
    'description': '4 חדרים, שיפוץ מלא 2025, מטבח מעוצב. שכונה משפחתית.',
    'status': 'active', 'contact_name': 'מתווך — בית ובית', 'contact_phone': '08-9716666',
    'is_broker': true, 'has_parking': true, 'has_elevator': true,
    'has_balcony': true, 'has_storage': true, 'has_mamad': true,
    'is_furnished': false, 'is_featured': false,
    'view_count': 456, 'created_at': '2026-08-10T10:00:00Z',
  },
  {
    'id': 'lst15', 'type': 'sale', 'price': 2200000, 'neighborhood': 'בוכמן',
    'rooms': 4, 'sqm': 100, 'floor': 3, 'total_floors': 5,
    'address': 'רח׳ התאנה 12, בוכמן',
    'description': '4 חדרים, מחיר אטרקטיבי. דורשת שיפוץ קל.',
    'status': 'active', 'contact_name': 'דוד חיים', 'contact_phone': '050-4447788',
    'is_broker': false, 'has_parking': true, 'has_elevator': true,
    'has_balcony': true, 'has_storage': false, 'has_mamad': true,
    'is_furnished': false, 'is_featured': false,
    'view_count': 223, 'created_at': '2026-08-15T10:00:00Z',
  },
  {
    'id': 'lst16', 'type': 'sale', 'price': 1750000, 'neighborhood': 'רמת מודיעין',
    'rooms': 3, 'sqm': 80, 'floor': 2, 'total_floors': 4,
    'address': 'רח׳ הרימון 6, רמת מודיעין',
    'description': '3 חדרים, דירת כניסה מעולה. קהילה חמה.',
    'status': 'sold', 'contact_name': 'חיים בן דוד', 'contact_phone': '050-5559900',
    'is_broker': false, 'has_parking': false, 'has_elevator': false,
    'has_balcony': true, 'has_storage': false, 'has_mamad': true,
    'is_furnished': false, 'is_featured': false,
    'view_count': 890, 'created_at': '2026-06-01T10:00:00Z',
  },
  {
    'id': 'lst17', 'type': 'rent', 'price': 11000, 'neighborhood': 'אבני חן',
    'rooms': 5, 'sqm': 150, 'floor': 0, 'total_floors': 2,
    'address': 'רח׳ הברוש 8, אבני חן',
    'description': 'וילה דו-משפחתית, 5 חדרים עם גינה. ריהוט מלא.',
    'status': 'active', 'contact_name': 'רותי אביב', 'contact_phone': '054-1119900',
    'is_broker': false, 'has_parking': true, 'has_elevator': false,
    'has_balcony': true, 'has_storage': true, 'has_mamad': true,
    'is_furnished': true, 'is_featured': true,
    'view_count': 567, 'created_at': '2026-08-20T10:00:00Z',
  },
  {
    'id': 'lst18', 'type': 'sale', 'price': 5500000, 'neighborhood': 'אבני חן',
    'rooms': 7, 'sqm': 220, 'floor': 0, 'total_floors': 2,
    'address': 'רח׳ הארז 2, אבני חן',
    'description': 'וילה פרטית 7 חדרים. בריכה, גינה מטופחת, חניה ל-3 רכבים.',
    'status': 'active', 'contact_name': 'אלי נדל"ן', 'contact_phone': '08-9717777',
    'is_broker': true, 'has_parking': true, 'has_elevator': false,
    'has_balcony': true, 'has_storage': true, 'has_mamad': true,
    'is_furnished': false, 'is_featured': true,
    'view_count': 3450, 'created_at': '2026-07-05T10:00:00Z',
  },
  {
    'id': 'lst19', 'type': 'rent', 'price': 3800, 'neighborhood': 'משואה',
    'rooms': 2, 'sqm': 55, 'floor': 1, 'total_floors': 3,
    'address': 'רח׳ המשואה 15, משואה',
    'description': 'דירת 2 חדרים קומפקטית. מתאימה לסטודנט או עובד.',
    'status': 'active', 'contact_name': 'אורית מלכה', 'contact_phone': '052-8889900',
    'is_broker': false, 'has_parking': false, 'has_elevator': false,
    'has_balcony': false, 'has_storage': false, 'has_mamad': true,
    'is_furnished': true, 'is_featured': false,
    'view_count': 67, 'created_at': '2026-08-22T10:00:00Z',
  },
  {
    'id': 'lst20', 'type': 'sale', 'price': 2950000, 'neighborhood': 'הכרמים',
    'rooms': 5, 'sqm': 130, 'floor': 4, 'total_floors': 6,
    'address': 'רח׳ הגפן 21, הכרמים',
    'description': '5 חדרים, קומה גבוהה, נוף ירוק. שכונה חדשה ומבוקשת.',
    'status': 'pending', 'contact_name': 'בית ובית נדל"ן', 'contact_phone': '08-9716666',
    'is_broker': true, 'has_parking': true, 'has_elevator': true,
    'has_balcony': true, 'has_storage': true, 'has_mamad': true,
    'is_furnished': false, 'is_featured': false,
    'view_count': 0, 'created_at': '2026-08-26T10:00:00Z',
  },
  {
    'id': 'lst21', 'type': 'rent', 'price': 7500, 'neighborhood': 'מורשת',
    'rooms': 4, 'sqm': 115, 'floor': 2, 'total_floors': 4,
    'address': 'רח׳ התמר 19, מורשת',
    'description': '4 חדרים מרווחת עם מרפסת ענקית. שכונה שקטה, ליד פארק.',
    'status': 'active', 'contact_name': 'אפרת כהן', 'contact_phone': '053-7778899',
    'is_broker': false, 'has_parking': true, 'has_elevator': true,
    'has_balcony': true, 'has_storage': true, 'has_mamad': true,
    'is_furnished': false, 'is_featured': false,
    'view_count': 234, 'created_at': '2026-08-14T10:00:00Z',
  },
];
