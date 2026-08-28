import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Admin Users ───

final adminTeamProvider = StateNotifierProvider<AdminTeamNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return AdminTeamNotifier();
});

class AdminTeamNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  List<Map<String, dynamic>> _all = [];
  String? _search;

  AdminTeamNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    _all = List<Map<String, dynamic>>.from(_mockAdmins);
    _applyFilters();
  }

  void _applyFilters() {
    var filtered = List<Map<String, dynamic>>.from(_all);
    if (_search != null && _search!.isNotEmpty) {
      final q = _search!.toLowerCase();
      filtered = filtered.where((u) {
        final name = (u['name'] as String? ?? '').toLowerCase();
        final email = (u['email'] as String? ?? '').toLowerCase();
        return name.contains(q) || email.contains(q);
      }).toList();
    }
    state = AsyncValue.data(filtered);
  }

  void setSearch(String? search) { _search = search; _applyFilters(); }

  Future<void> createUser(Map<String, dynamic> user) async {
    _all.add({...user, 'id': 'adm_${DateTime.now().millisecondsSinceEpoch}', 'created_at': DateTime.now().toIso8601String()});
    _applyFilters();
  }

  Future<void> updateUser(String id, Map<String, dynamic> fields) async {
    _all = [for (final u in _all) u['id'] == id ? {...u, ...fields} : u];
    _applyFilters();
  }

  Future<void> deleteUser(String id) async {
    _all.removeWhere((u) => u['id'] == id);
    _applyFilters();
  }

  Future<void> toggleActive(String id) async {
    _all = [for (final u in _all) u['id'] == id ? {...u, 'is_active': !(u['is_active'] as bool? ?? true)} : u];
    _applyFilters();
  }
}

// ─── Roles ───

final adminRolesProvider = StateNotifierProvider<AdminRolesNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return AdminRolesNotifier();
});

class AdminRolesNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  List<Map<String, dynamic>> _all = [];

  AdminRolesNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    _all = List<Map<String, dynamic>>.from(_mockRoles);
    state = AsyncValue.data(_all);
  }

  Future<void> createRole(Map<String, dynamic> role) async {
    _all.add({...role, 'id': 'role_${DateTime.now().millisecondsSinceEpoch}', 'created_at': DateTime.now().toIso8601String()});
    state = AsyncValue.data(List.from(_all));
  }

  Future<void> updateRole(String id, Map<String, dynamic> fields) async {
    _all = [for (final r in _all) r['id'] == id ? {...r, ...fields} : r];
    state = AsyncValue.data(List.from(_all));
  }

  Future<void> deleteRole(String id) async {
    _all.removeWhere((r) => r['id'] == id);
    state = AsyncValue.data(List.from(_all));
  }
}

// ─── Mock Data ───

final _mockRoles = <Map<String, dynamic>>[
  {
    'id': 'role_1',
    'name': 'סופר אדמין',
    'description': 'גישה מלאה לכל המודולים',
    'permissions': [
      {'module': 'משתמשים', 'actions': ['צפייה', 'יצירה', 'עריכה', 'מחיקה']},
      {'module': 'עסקים', 'actions': ['צפייה', 'יצירה', 'עריכה', 'מחיקה']},
      {'module': 'כתבות', 'actions': ['צפייה', 'יצירה', 'עריכה', 'מחיקה']},
      {'module': 'אירועים', 'actions': ['צפייה', 'יצירה', 'עריכה', 'מחיקה']},
      {'module': 'הכנסות', 'actions': ['צפייה', 'יצירה', 'עריכה', 'מחיקה']},
      {'module': 'קמפיינים', 'actions': ['צפייה', 'יצירה', 'עריכה', 'מחיקה']},
      {'module': 'הגדרות', 'actions': ['צפייה', 'יצירה', 'עריכה', 'מחיקה']},
      {'module': 'מערכת', 'actions': ['צפייה', 'יצירה', 'עריכה', 'מחיקה']},
    ],
    'user_count': 1,
    'created_at': '2024-01-01T00:00:00Z',
  },
  {
    'id': 'role_2',
    'name': 'עורך תוכן',
    'description': 'ניהול כתבות, אירועים ומדיה',
    'permissions': [
      {'module': 'כתבות', 'actions': ['צפייה', 'יצירה', 'עריכה', 'מחיקה']},
      {'module': 'אירועים', 'actions': ['צפייה', 'יצירה', 'עריכה', 'מחיקה']},
      {'module': 'עסקים', 'actions': ['צפייה']},
      {'module': 'משתמשים', 'actions': ['צפייה']},
    ],
    'user_count': 1,
    'created_at': '2024-01-15T00:00:00Z',
  },
  {
    'id': 'role_3',
    'name': 'מנהל מכירות',
    'description': 'ניהול עסקים, הסכמים, קמפיינים והכנסות',
    'permissions': [
      {'module': 'עסקים', 'actions': ['צפייה', 'יצירה', 'עריכה']},
      {'module': 'הכנסות', 'actions': ['צפייה', 'יצירה', 'עריכה']},
      {'module': 'קמפיינים', 'actions': ['צפייה', 'יצירה', 'עריכה', 'מחיקה']},
      {'module': 'משתמשים', 'actions': ['צפייה']},
    ],
    'user_count': 1,
    'created_at': '2024-02-01T00:00:00Z',
  },
  {
    'id': 'role_4',
    'name': 'תמיכה',
    'description': 'ניהול משתמשים, ביקורות, תגובות ודיווחים',
    'permissions': [
      {'module': 'משתמשים', 'actions': ['צפייה', 'עריכה']},
      {'module': 'עסקים', 'actions': ['צפייה']},
      {'module': 'כתבות', 'actions': ['צפייה']},
    ],
    'user_count': 2,
    'created_at': '2024-02-15T00:00:00Z',
  },
];

final _mockAdmins = <Map<String, dynamic>>[
  {
    'id': 'adm_1',
    'name': 'ניתאי לוי',
    'email': 'nitaildigital@gmail.com',
    'phone': '050-1234567',
    'role_id': 'role_1',
    'role_name': 'סופר אדמין',
    'avatar_initial': 'נ',
    'is_active': true,
    'last_login_at': '2026-08-28T08:30:00Z',
    'created_at': '2024-01-01T00:00:00Z',
  },
  {
    'id': 'adm_2',
    'name': 'יוסי כהן',
    'email': 'yossi@modiin4u.co.il',
    'phone': '052-9876543',
    'role_id': 'role_2',
    'role_name': 'עורך תוכן',
    'avatar_initial': 'י',
    'is_active': true,
    'last_login_at': '2026-08-27T14:22:00Z',
    'created_at': '2024-03-15T00:00:00Z',
  },
  {
    'id': 'adm_3',
    'name': 'שרה אברהם',
    'email': 'sara@modiin4u.co.il',
    'phone': '053-5556666',
    'role_id': 'role_3',
    'role_name': 'מנהלת מכירות',
    'avatar_initial': 'ש',
    'is_active': true,
    'last_login_at': '2026-08-28T07:45:00Z',
    'created_at': '2024-05-01T00:00:00Z',
  },
  {
    'id': 'adm_4',
    'name': 'דנה מזרחי',
    'email': 'dana@modiin4u.co.il',
    'phone': '054-7778888',
    'role_id': 'role_4',
    'role_name': 'תמיכה',
    'avatar_initial': 'ד',
    'is_active': true,
    'last_login_at': '2026-08-26T16:10:00Z',
    'created_at': '2024-06-20T00:00:00Z',
  },
  {
    'id': 'adm_5',
    'name': 'אלון ברק',
    'email': 'alon@modiin4u.co.il',
    'phone': '058-9990000',
    'role_id': 'role_4',
    'role_name': 'תמיכה',
    'avatar_initial': 'א',
    'is_active': false,
    'last_login_at': '2026-07-15T09:00:00Z',
    'created_at': '2025-01-10T00:00:00Z',
  },
];
