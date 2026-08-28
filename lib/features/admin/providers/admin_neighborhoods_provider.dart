import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminNeighborhoodListProvider = StateNotifierProvider<
    AdminNeighborhoodListNotifier,
    AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return AdminNeighborhoodListNotifier();
});

class AdminNeighborhoodListNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  List<Map<String, dynamic>> _all = [];
  String? _search;
  String? _activeFilter; // 'active', 'inactive', or null

  AdminNeighborhoodListNotifier()
      : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    _all = List<Map<String, dynamic>>.from(_mockNeighborhoods);
    _applyFilters();
  }

  void _applyFilters() {
    var filtered = List<Map<String, dynamic>>.from(_all);
    if (_search != null && _search!.isNotEmpty) {
      final q = _search!.toLowerCase();
      filtered = filtered
          .where((n) =>
              (n['name'] as String).toLowerCase().contains(q) ||
              (n['slug'] as String).toLowerCase().contains(q))
          .toList();
    }
    if (_activeFilter == 'active') {
      filtered = filtered.where((n) => n['is_active'] == true).toList();
    } else if (_activeFilter == 'inactive') {
      filtered = filtered.where((n) => n['is_active'] != true).toList();
    }
    filtered.sort((a, b) =>
        (a['sort_order'] as int).compareTo(b['sort_order'] as int));
    state = AsyncValue.data(filtered);
  }

  void setSearch(String? search) {
    _search = search;
    _applyFilters();
  }

  void setActiveFilter(String? filter) {
    _activeFilter = filter;
    _applyFilters();
  }

  void toggleActive(String id) {
    _all = [
      for (final n in _all)
        if (n['id'] == id)
          {...n, 'is_active': !(n['is_active'] as bool? ?? true)}
        else
          n
    ];
    _applyFilters();
  }

  Future<void> createNeighborhood(Map<String, dynamic> data) async {
    _all.add({
      'id': 'n_${DateTime.now().millisecondsSinceEpoch}',
      'created_at': DateTime.now().toIso8601String(),
      'resident_count': 0,
      'business_count': 0,
      ...data,
    });
    _applyFilters();
  }

  Future<void> updateNeighborhood(
      String id, Map<String, dynamic> fields) async {
    _all = [
      for (final n in _all)
        if (n['id'] == id) {...n, ...fields} else n
    ];
    _applyFilters();
  }

  Future<void> deleteNeighborhood(String id) async {
    _all.removeWhere((n) => n['id'] == id);
    _applyFilters();
  }
}

final _mockNeighborhoods = <Map<String, dynamic>>[
  {
    'id': 'n1',
    'name': 'אבני חן',
    'slug': 'avnei-hen',
    'description': 'שכונת מגורים ותיקה עם אופי קהילתי חזק',
    'sort_order': 1,
    'is_active': true,
    'resident_count': 8200,
    'business_count': 45,
    'latitude': 31.9010,
    'longitude': 35.0050,
    'created_at': '2024-01-01T00:00:00Z',
  },
  {
    'id': 'n2',
    'name': 'בוכמן',
    'slug': 'buchman',
    'description': 'שכונה צעירה עם מגוון שירותים',
    'sort_order': 2,
    'is_active': true,
    'resident_count': 6800,
    'business_count': 32,
    'latitude': 31.8950,
    'longitude': 35.0100,
    'created_at': '2024-01-01T00:00:00Z',
  },
  {
    'id': 'n3',
    'name': 'מורשת',
    'slug': 'moreshet',
    'description': 'שכונת מגורים שקטה עם פארקים ירוקים',
    'sort_order': 3,
    'is_active': true,
    'resident_count': 5500,
    'business_count': 18,
    'latitude': 31.8990,
    'longitude': 35.0080,
    'created_at': '2024-01-01T00:00:00Z',
  },
  {
    'id': 'n4',
    'name': 'הנחלים',
    'slug': 'hanehalim',
    'description': 'שכונה חדשה יחסית עם בנייה מודרנית',
    'sort_order': 4,
    'is_active': true,
    'resident_count': 7100,
    'business_count': 28,
    'latitude': 31.8920,
    'longitude': 35.0040,
    'created_at': '2024-01-01T00:00:00Z',
  },
  {
    'id': 'n5',
    'name': 'נופים',
    'slug': 'nofim',
    'description': 'שכונה עם נוף פתוח לעמק איילון',
    'sort_order': 5,
    'is_active': true,
    'resident_count': 4300,
    'business_count': 15,
    'latitude': 31.9050,
    'longitude': 35.0120,
    'created_at': '2024-01-01T00:00:00Z',
  },
  {
    'id': 'n6',
    'name': 'הכרמים',
    'slug': 'hakramim',
    'description': 'שכונה ירוקה עם גנים קהילתיים',
    'sort_order': 6,
    'is_active': true,
    'resident_count': 3900,
    'business_count': 12,
    'latitude': 31.8880,
    'longitude': 35.0060,
    'created_at': '2024-01-01T00:00:00Z',
  },
  {
    'id': 'n7',
    'name': 'מוריה',
    'slug': 'moriah',
    'description': 'שכונת מגורים עם מתנ"ס פעיל',
    'sort_order': 7,
    'is_active': true,
    'resident_count': 5100,
    'business_count': 22,
    'latitude': 31.8970,
    'longitude': 35.0150,
    'created_at': '2024-01-01T00:00:00Z',
  },
  {
    'id': 'n8',
    'name': 'הפרחים',
    'slug': 'haprahim',
    'description': 'שכונה חדשה עם דירות גן',
    'sort_order': 8,
    'is_active': true,
    'resident_count': 3200,
    'business_count': 8,
    'latitude': 31.9030,
    'longitude': 35.0020,
    'created_at': '2024-01-01T00:00:00Z',
  },
  {
    'id': 'n9',
    'name': 'משואה',
    'slug': 'masua',
    'description': 'שכונה בגבעה הגבוהה של מודיעין',
    'sort_order': 9,
    'is_active': true,
    'resident_count': 2800,
    'business_count': 6,
    'latitude': 31.9070,
    'longitude': 35.0090,
    'created_at': '2024-01-01T00:00:00Z',
  },
  {
    'id': 'n10',
    'name': 'כפר הנוער',
    'slug': 'kfar-hanoar',
    'description': 'אזור כפר הנוער ההיסטורי',
    'sort_order': 10,
    'is_active': true,
    'resident_count': 1800,
    'business_count': 4,
    'latitude': 31.8940,
    'longitude': 35.0030,
    'created_at': '2024-01-01T00:00:00Z',
  },
  {
    'id': 'n11',
    'name': 'רמת מודיעין',
    'slug': 'ramat-modiin',
    'description': 'יישוב קהילתי חרדי סמוך למודיעין',
    'sort_order': 11,
    'is_active': true,
    'resident_count': 4600,
    'business_count': 20,
    'latitude': 31.9100,
    'longitude': 35.0200,
    'created_at': '2024-01-01T00:00:00Z',
  },
  {
    'id': 'n12',
    'name': 'חשמונאים',
    'slug': 'hashmonaim',
    'description': 'יישוב קהילתי דתי-לאומי',
    'sort_order': 12,
    'is_active': true,
    'resident_count': 3500,
    'business_count': 10,
    'latitude': 31.9150,
    'longitude': 35.0250,
    'created_at': '2024-01-01T00:00:00Z',
  },
  {
    'id': 'n13',
    'name': 'מע"ר (מרכז העיר)',
    'slug': 'maar',
    'description': 'מרכז עסקי ומסחרי, עזריאלי מודיעין',
    'sort_order': 13,
    'is_active': true,
    'resident_count': 1200,
    'business_count': 95,
    'latitude': 31.8960,
    'longitude': 35.0120,
    'created_at': '2024-01-01T00:00:00Z',
  },
  {
    'id': 'n14',
    'name': 'גבעת התיתורה',
    'slug': 'givat-hatitora',
    'description': 'שכונה חדשה בבנייה',
    'sort_order': 14,
    'is_active': true,
    'resident_count': 1500,
    'business_count': 3,
    'latitude': 31.8850,
    'longitude': 35.0000,
    'created_at': '2024-05-01T00:00:00Z',
  },
  {
    'id': 'n15',
    'name': 'שילת',
    'slug': 'shilat',
    'description': 'אזור תעשייה ומסחר, כניסה למודיעין',
    'sort_order': 15,
    'is_active': true,
    'resident_count': 400,
    'business_count': 55,
    'latitude': 31.9200,
    'longitude': 35.0300,
    'created_at': '2024-01-01T00:00:00Z',
  },
  {
    'id': 'n16',
    'name': 'עמק שילה',
    'slug': 'emek-shilo',
    'description': 'שכונה חדשה בפיתוח',
    'sort_order': 16,
    'is_active': false,
    'resident_count': 0,
    'business_count': 0,
    'latitude': 31.8830,
    'longitude': 34.9980,
    'created_at': '2026-06-01T00:00:00Z',
  },
];
