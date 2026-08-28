import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminBusinessListProvider = StateNotifierProvider<AdminBusinessListNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return AdminBusinessListNotifier();
});

final neighborhoodsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return _mockNeighborhoods;
});

final businessCategoriesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return _mockCategories;
});

class AdminBusinessListNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  List<Map<String, dynamic>> _all = List.from(_mockBusinesses);
  String? _search;
  String? _status;

  AdminBusinessListNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      var filtered = List<Map<String, dynamic>>.from(_all);
      if (_status != null && _status!.isNotEmpty) {
        filtered = filtered.where((b) => b['status'] == _status).toList();
      }
      if (_search != null && _search!.isNotEmpty) {
        final q = _search!.toLowerCase();
        filtered = filtered.where((b) {
          final name = (b['name'] as String? ?? '').toLowerCase();
          final desc = (b['short_description'] as String? ?? '').toLowerCase();
          return name.contains(q) || desc.contains(q);
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

  Future<void> createBusiness(Map<String, dynamic> business) async {
    business['id'] = 'b_${DateTime.now().millisecondsSinceEpoch}';
    business['created_at'] = DateTime.now().toIso8601String();
    _all = [business, ..._all];
    await load();
  }

  Future<void> updateBusiness(String id, Map<String, dynamic> fields) async {
    _all = [
      for (final b in _all)
        if (b['id'] == id) {...b, ...fields} else b,
    ];
    await load();
  }

  Future<void> deleteBusiness(String id) async {
    _all = _all.where((b) => b['id'] != id).toList();
    await load();
  }

  Future<void> updateStatus(String id, String status) async {
    await updateBusiness(id, {'status': status});
  }
}

// ─── Mock Neighborhoods ───

final _mockNeighborhoods = <Map<String, dynamic>>[
  {'id': 'n1', 'name': 'אבני חן', 'slug': 'avnei-hen', 'is_active': true, 'sort_order': 1},
  {'id': 'n2', 'name': 'מורשת', 'slug': 'moreshet', 'is_active': true, 'sort_order': 2},
  {'id': 'n3', 'name': 'בוכמן', 'slug': 'buchman', 'is_active': true, 'sort_order': 3},
  {'id': 'n4', 'name': 'מרכז העיר', 'slug': 'city-center', 'is_active': true, 'sort_order': 4},
  {'id': 'n5', 'name': 'רמת מודיעין', 'slug': 'ramat-modiin', 'is_active': true, 'sort_order': 5},
  {'id': 'n6', 'name': 'כפר הנוער', 'slug': 'kfar-hanoar', 'is_active': true, 'sort_order': 6},
  {'id': 'n7', 'name': 'נופים', 'slug': 'nofim', 'is_active': true, 'sort_order': 7},
  {'id': 'n8', 'name': 'הכרמים', 'slug': 'hakramim', 'is_active': true, 'sort_order': 8},
  {'id': 'n9', 'name': 'מוריה', 'slug': 'moriah', 'is_active': true, 'sort_order': 9},
  {'id': 'n10', 'name': 'הנחלים', 'slug': 'hanhalim', 'is_active': true, 'sort_order': 10},
  {'id': 'n11', 'name': 'הפרחים', 'slug': 'haprahim', 'is_active': true, 'sort_order': 11},
  {'id': 'n12', 'name': 'משואה', 'slug': 'masua', 'is_active': true, 'sort_order': 12},
  {'id': 'n13', 'name': 'המע"ר', 'slug': 'maar', 'is_active': true, 'sort_order': 13},
];

// ─── Mock Categories ───

final _mockCategories = <Map<String, dynamic>>[
  {'id': 'c1', 'name': 'מסעדות', 'slug': 'restaurants', 'scope': 'business', 'is_active': true, 'sort_order': 1},
  {'id': 'c2', 'name': 'בריאות', 'slug': 'health', 'scope': 'business', 'is_active': true, 'sort_order': 2},
  {'id': 'c3', 'name': 'ספורט', 'slug': 'sport', 'scope': 'business', 'is_active': true, 'sort_order': 3},
  {'id': 'c4', 'name': 'חינוך', 'slug': 'education', 'scope': 'business', 'is_active': true, 'sort_order': 4},
  {'id': 'c5', 'name': 'שירותים', 'slug': 'services', 'scope': 'business', 'is_active': true, 'sort_order': 5},
  {'id': 'c6', 'name': 'קמעונאות', 'slug': 'retail', 'scope': 'business', 'is_active': true, 'sort_order': 6},
  {'id': 'c7', 'name': 'בילוי ופנאי', 'slug': 'entertainment', 'scope': 'business', 'is_active': true, 'sort_order': 7},
  {'id': 'c8', 'name': 'יופי וטיפוח', 'slug': 'beauty', 'scope': 'business', 'is_active': true, 'sort_order': 8},
];

// ─── Mock Businesses ───

final _mockBusinesses = <Map<String, dynamic>>[
  {
    'id': 'b1', 'name': 'פיצה פרגו', 'slug': 'pizza-frago',
    'short_description': 'פיצריה איטלקית אותנטית במרכז מודיעין',
    'full_description': 'פיצריה איטלקית אותנטית עם תנור אבן. מגוון פיצות, פסטות ומנות איטלקיות. משלוחים לכל רחבי מודיעין.',
    'phone': '08-9712345', 'email': 'info@pizzafrago.co.il', 'website': 'https://pizzafrago.co.il',
    'whatsapp': '0509712345', 'instagram': '@pizzafrago',
    'address': 'רח׳ המעיין 12', 'neighborhood_id': 'n4',
    'neighborhoods': {'id': 'n4', 'name': 'מרכז העיר', 'slug': 'city-center'},
    'latitude': 31.8975, 'longitude': 35.0104,
    'rating': 4.5, 'review_count': 87,
    'status': 'active', 'kosher_level': 'rabbanut', 'price_level': '₪₪',
    'has_delivery': true, 'is_accessible': true, 'has_takeaway': true, 'has_parking': false,
    'pet_friendly': false, 'kid_friendly': true, 'has_wifi': true, 'open_on_shabbat': false,
    'is_featured': true, 'is_verified': true, 'noindex': false,
    'meta_title': 'פיצה פרגו — פיצריה איטלקית במודיעין',
    'meta_description': 'פיצה פרגו — פיצריה איטלקית במודיעין. משלוחים, ישיבה במקום, כשר רבנות.',
    'created_at': '2024-03-15T10:00:00Z',
  },
  {
    'id': 'b2', 'name': 'סופר פארם מודיעין', 'slug': 'super-pharm-modiin',
    'short_description': 'תרופות, קוסמטיקה ומוצרי טיפוח',
    'phone': '08-9714567', 'address': 'מרכז עזריאלי מודיעין', 'neighborhood_id': 'n4',
    'neighborhoods': {'id': 'n4', 'name': 'מרכז העיר', 'slug': 'city-center'},
    'latitude': 31.8960, 'longitude': 35.0120, 'rating': 4.1, 'review_count': 42,
    'status': 'active', 'is_verified': true, 'created_at': '2024-05-01T10:00:00Z',
  },
  {
    'id': 'b3', 'name': 'סטודיו שרה — יוגה ופילאטיס', 'slug': 'studio-sara-yoga',
    'short_description': 'שיעורי יוגה ופילאטיס לכל הרמות',
    'phone': '053-5556666', 'address': 'רח׳ האלון 8', 'neighborhood_id': 'n1',
    'neighborhoods': {'id': 'n1', 'name': 'אבני חן', 'slug': 'avnei-hen'},
    'latitude': 31.9010, 'longitude': 35.0050, 'rating': 4.8, 'review_count': 63,
    'status': 'active', 'is_featured': true, 'created_at': '2024-09-05T10:00:00Z',
  },
  {
    'id': 'b4', 'name': 'ביסטרו מודיעין', 'slug': 'bistro-modiin',
    'short_description': 'מסעדת שף חדשה — מטבח ים תיכוני',
    'phone': '08-9719999', 'address': 'רח׳ הנרקיס 3', 'neighborhood_id': 'n2',
    'neighborhoods': {'id': 'n2', 'name': 'מורשת', 'slug': 'moreshet'},
    'latitude': 31.8990, 'longitude': 35.0080,
    'status': 'pending', 'created_at': '2026-08-10T10:00:00Z',
  },
  {
    'id': 'b5', 'name': 'קפה לנדוור', 'slug': 'cafe-landwer',
    'short_description': 'בית קפה עם ארוחות בוקר ועוגות',
    'phone': '08-9715678', 'address': 'רח׳ לב העיר 5', 'neighborhood_id': 'n4',
    'neighborhoods': {'id': 'n4', 'name': 'מרכז העיר', 'slug': 'city-center'},
    'rating': 4.3, 'review_count': 112,
    'status': 'active', 'kosher_level': 'rabbanut', 'price_level': '₪₪',
    'has_delivery': false, 'has_wifi': true, 'kid_friendly': true,
    'is_verified': true, 'created_at': '2024-01-10T10:00:00Z',
  },
  {
    'id': 'b6', 'name': 'ד"ר אבי כהן — רפואת שיניים', 'slug': 'dr-avi-cohen-dental',
    'short_description': 'מרפאת שיניים מתקדמת — כל הטיפולים',
    'phone': '08-9713456', 'email': 'clinic@dravidental.co.il',
    'address': 'רח׳ הדקל 18', 'neighborhood_id': 'n1',
    'neighborhoods': {'id': 'n1', 'name': 'אבני חן', 'slug': 'avnei-hen'},
    'rating': 4.7, 'review_count': 58,
    'status': 'active', 'is_accessible': true, 'has_parking': true,
    'is_verified': true, 'created_at': '2023-11-20T10:00:00Z',
  },
  {
    'id': 'b7', 'name': 'חנות הספרים של רונית', 'slug': 'ronit-bookstore',
    'short_description': 'ספרים בעברית ובאנגלית לכל הגילאים',
    'phone': '08-9716789', 'address': 'מרכז מסחרי מורשת', 'neighborhood_id': 'n2',
    'neighborhoods': {'id': 'n2', 'name': 'מורשת', 'slug': 'moreshet'},
    'rating': 4.9, 'review_count': 34,
    'status': 'active', 'kid_friendly': true,
    'created_at': '2024-06-15T10:00:00Z',
  },
  {
    'id': 'b8', 'name': 'קרוספיט מודיעין', 'slug': 'crossfit-modiin',
    'short_description': 'מועדון קרוספיט עם מאמנים מוסמכים',
    'phone': '050-8889999', 'website': 'https://crossfitmodiin.co.il',
    'address': 'אזור תעשייה מודיעין', 'neighborhood_id': 'n13',
    'neighborhoods': {'id': 'n13', 'name': 'המע"ר', 'slug': 'maar'},
    'rating': 4.6, 'review_count': 76,
    'status': 'active', 'has_parking': true, 'is_accessible': true,
    'is_featured': true, 'created_at': '2024-02-28T10:00:00Z',
  },
  {
    'id': 'b9', 'name': 'מספרת טיפ-טופ', 'slug': 'tip-top-hair',
    'short_description': 'מספרה לנשים וגברים — תספורות, צבע, החלקות',
    'phone': '08-9718765', 'address': 'רח׳ השקמה 22', 'neighborhood_id': 'n3',
    'neighborhoods': {'id': 'n3', 'name': 'בוכמן', 'slug': 'buchman'},
    'rating': 4.2, 'review_count': 45,
    'status': 'active', 'is_accessible': true,
    'created_at': '2024-04-10T10:00:00Z',
  },
  {
    'id': 'b10', 'name': 'גן ילדים שמש', 'slug': 'gan-shemesh',
    'short_description': 'גן ילדים פרטי גילאי 3-6 — גישה חינוכית מתקדמת',
    'phone': '054-2223333', 'email': 'gan@shemesh.co.il',
    'address': 'רח׳ הזית 7', 'neighborhood_id': 'n7',
    'neighborhoods': {'id': 'n7', 'name': 'נופים', 'slug': 'nofim'},
    'rating': 4.4, 'review_count': 29,
    'status': 'active', 'is_accessible': true, 'has_parking': true, 'kid_friendly': true,
    'created_at': '2023-09-01T10:00:00Z',
  },
  {
    'id': 'b11', 'name': 'אופטיקה ראיית עיניים', 'slug': 'optika-modiin',
    'short_description': 'משקפיים, עדשות מגע ובדיקות ראייה',
    'phone': '08-9711111', 'address': 'קניון עזריאלי, קומה 1', 'neighborhood_id': 'n4',
    'neighborhoods': {'id': 'n4', 'name': 'מרכז העיר', 'slug': 'city-center'},
    'rating': 4.0, 'review_count': 18,
    'status': 'active', 'created_at': '2024-07-20T10:00:00Z',
  },
  {
    'id': 'b12', 'name': 'שיפוצניק מודיעין — ארז', 'slug': 'shipuznik-erez',
    'short_description': 'שיפוצים, צביעה, חשמל ואינסטלציה',
    'phone': '052-4445555', 'whatsapp': '0524445555',
    'address': 'שירות ניידת — כל מודיעין', 'neighborhood_id': 'n4',
    'neighborhoods': {'id': 'n4', 'name': 'מרכז העיר', 'slug': 'city-center'},
    'rating': 4.3, 'review_count': 31,
    'status': 'active', 'created_at': '2025-01-15T10:00:00Z',
  },
  {
    'id': 'b13', 'name': 'סושי מודיעין', 'slug': 'sushi-modiin',
    'short_description': 'סושי טרי — מגוון מנות יפניות ואסייתיות',
    'phone': '08-9714321', 'address': 'רח׳ הגפן 14', 'neighborhood_id': 'n8',
    'neighborhoods': {'id': 'n8', 'name': 'הכרמים', 'slug': 'hakramim'},
    'rating': 4.6, 'review_count': 55,
    'status': 'active', 'kosher_level': 'rabbanut', 'price_level': '₪₪₪',
    'has_delivery': true, 'has_takeaway': true,
    'is_featured': true, 'created_at': '2025-03-01T10:00:00Z',
  },
  {
    'id': 'b14', 'name': 'חוגי רובוטיקה — TechKids', 'slug': 'techkids-robotics',
    'short_description': 'חוגי רובוטיקה ותכנות לילדים גילאי 6-16',
    'phone': '050-6667777', 'website': 'https://techkids.co.il',
    'address': 'מתנ"ס בוכמן', 'neighborhood_id': 'n3',
    'neighborhoods': {'id': 'n3', 'name': 'בוכמן', 'slug': 'buchman'},
    'rating': 4.8, 'review_count': 41,
    'status': 'active', 'kid_friendly': true,
    'created_at': '2024-08-20T10:00:00Z',
  },
  {
    'id': 'b15', 'name': 'מאפייה הירושלמית', 'slug': 'jerusalem-bakery',
    'short_description': 'לחם טרי, בורקסים ומאפים מסורתיים',
    'phone': '08-9717654', 'address': 'רח׳ הזיתים 3', 'neighborhood_id': 'n5',
    'neighborhoods': {'id': 'n5', 'name': 'רמת מודיעין', 'slug': 'ramat-modiin'},
    'rating': 4.7, 'review_count': 92,
    'status': 'active', 'kosher_level': 'mehadrin',
    'has_takeaway': true, 'open_on_shabbat': false,
    'created_at': '2023-06-10T10:00:00Z',
  },
  {
    'id': 'b16', 'name': 'עורכת דין — מיכל רוזנברג', 'slug': 'adv-michal-rosenberg',
    'short_description': 'דיני משפחה, נדל"ן וצוואות',
    'phone': '08-9719876', 'email': 'michal@rosenberg-law.co.il',
    'address': 'מגדלי העיר, קומה 7', 'neighborhood_id': 'n4',
    'neighborhoods': {'id': 'n4', 'name': 'מרכז העיר', 'slug': 'city-center'},
    'rating': 4.9, 'review_count': 22,
    'status': 'active', 'is_accessible': true, 'has_parking': true,
    'is_verified': true, 'created_at': '2024-10-01T10:00:00Z',
  },
  {
    'id': 'b17', 'name': 'בורגר סטיישן', 'slug': 'burger-station',
    'short_description': 'המבורגרים גורמה ונקניקיות ביתיות',
    'phone': '08-9712222', 'address': 'רח׳ הדס 9', 'neighborhood_id': 'n2',
    'neighborhoods': {'id': 'n2', 'name': 'מורשת', 'slug': 'moreshet'},
    'rating': 4.4, 'review_count': 67,
    'status': 'suspended', 'kosher_level': 'rabbanut', 'price_level': '₪₪',
    'has_delivery': true, 'has_takeaway': true,
    'created_at': '2024-11-15T10:00:00Z',
  },
  {
    'id': 'b18', 'name': 'מכון כושר HolmES', 'slug': 'holmes-gym',
    'short_description': 'מכון כושר מתקדם עם שיעורי סטודיו',
    'phone': '08-9713333', 'website': 'https://holmesgym.co.il',
    'address': 'מרכז ספורט מודיעין', 'neighborhood_id': 'n13',
    'neighborhoods': {'id': 'n13', 'name': 'המע"ר', 'slug': 'maar'},
    'rating': 4.1, 'review_count': 89,
    'status': 'active', 'has_parking': true, 'is_accessible': true,
    'created_at': '2023-03-01T10:00:00Z',
  },
  {
    'id': 'b19', 'name': 'פרחי נועם', 'slug': 'pirchei-noam',
    'short_description': 'חנות פרחים ועיצוב אירועים',
    'phone': '054-8889999', 'instagram': '@pirchei_noam',
    'address': 'רח׳ הכלנית 2', 'neighborhood_id': 'n7',
    'neighborhoods': {'id': 'n7', 'name': 'נופים', 'slug': 'nofim'},
    'rating': 4.6, 'review_count': 28,
    'status': 'pending', 'has_delivery': true,
    'created_at': '2026-08-20T10:00:00Z',
  },
  {
    'id': 'b20', 'name': 'טכנאי מחשבים — דני', 'slug': 'dani-tech',
    'short_description': 'תיקון מחשבים, טלפונים ומכשירים חכמים',
    'phone': '050-1112222', 'whatsapp': '0501112222',
    'address': 'שירות עד הבית', 'neighborhood_id': 'n4',
    'neighborhoods': {'id': 'n4', 'name': 'מרכז העיר', 'slug': 'city-center'},
    'rating': 4.5, 'review_count': 39,
    'status': 'active', 'created_at': '2025-05-10T10:00:00Z',
  },
];
