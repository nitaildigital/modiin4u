import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminFeatureFlagListProvider = StateNotifierProvider<AdminFeatureFlagListNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return AdminFeatureFlagListNotifier();
});

class AdminFeatureFlagListNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  List<Map<String, dynamic>> _allData = [];

  AdminFeatureFlagListNotifier() : super(const AsyncValue.loading()) { load(); }

  Future<void> load() async {
    _allData = List<Map<String, dynamic>>.from(_mockFlags);
    state = AsyncValue.data(List.from(_allData));
  }

  Future<void> toggleFlag(String id) async {
    final idx = _allData.indexWhere((f) => f['id'] == id);
    if (idx >= 0) {
      _allData[idx]['is_enabled'] = !(_allData[idx]['is_enabled'] as bool);
      _allData[idx]['updated_at'] = DateTime.now().toIso8601String();
      state = AsyncValue.data(List.from(_allData));
    }
  }

  Future<void> updateRollout(String id, int pct) async {
    final idx = _allData.indexWhere((f) => f['id'] == id);
    if (idx >= 0) {
      _allData[idx]['rollout_pct'] = pct;
      _allData[idx]['updated_at'] = DateTime.now().toIso8601String();
      state = AsyncValue.data(List.from(_allData));
    }
  }

  Future<void> updateFlag(String id, Map<String, dynamic> fields) async {
    final idx = _allData.indexWhere((f) => f['id'] == id);
    if (idx >= 0) { _allData[idx] = {..._allData[idx], ...fields, 'updated_at': DateTime.now().toIso8601String()}; state = AsyncValue.data(List.from(_allData)); }
  }

  Future<void> createFlag(Map<String, dynamic> flag) async {
    flag['id'] = 'ff_${DateTime.now().millisecondsSinceEpoch}';
    flag['created_at'] = DateTime.now().toIso8601String();
    flag['updated_at'] = flag['created_at'];
    _allData.add(flag);
    state = AsyncValue.data(List.from(_allData));
  }
}

final adminRemoteConfigProvider = StateNotifierProvider<AdminRemoteConfigNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return AdminRemoteConfigNotifier();
});

class AdminRemoteConfigNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  List<Map<String, dynamic>> _allData = [];

  AdminRemoteConfigNotifier() : super(const AsyncValue.loading()) { load(); }

  Future<void> load() async {
    _allData = List<Map<String, dynamic>>.from(_mockRemoteConfig);
    state = AsyncValue.data(List.from(_allData));
  }

  Future<void> updateConfig(String id, Map<String, dynamic> fields) async {
    final idx = _allData.indexWhere((c) => c['id'] == id);
    if (idx >= 0) {
      _allData[idx] = {..._allData[idx], ...fields, 'updated_at': DateTime.now().toIso8601String()};
      state = AsyncValue.data(List.from(_allData));
    }
  }

  Future<void> createConfig(Map<String, dynamic> config) async {
    config['id'] = 'rc_${DateTime.now().millisecondsSinceEpoch}';
    config['created_at'] = DateTime.now().toIso8601String();
    config['updated_at'] = config['created_at'];
    _allData.add(config);
    state = AsyncValue.data(List.from(_allData));
  }

  Future<void> deleteConfig(String id) async {
    _allData.removeWhere((c) => c['id'] == id);
    state = AsyncValue.data(List.from(_allData));
  }
}

final _mockFlags = <Map<String, dynamic>>[
  {'id': 'ff_1', 'key': 'AI_SEARCH', 'label': 'חיפוש AI', 'description': 'חיפוש חכם עם הבנת שפה טבעית', 'is_enabled': true, 'rollout_pct': 50, 'platforms': ['ios', 'android', 'web'], 'config': {}, 'updated_by': 'ניתאי לוי', 'created_at': '2026-06-01T10:00:00Z', 'updated_at': '2026-08-15T10:00:00Z'},
  {'id': 'ff_2', 'key': 'REAL_ESTATE', 'label': 'נדל"ן', 'description': 'מודול דירות להשכרה ומכירה', 'is_enabled': true, 'rollout_pct': 100, 'platforms': ['ios', 'android', 'web'], 'config': {}, 'updated_by': 'ניתאי לוי', 'created_at': '2026-03-01T10:00:00Z', 'updated_at': '2026-07-01T10:00:00Z'},
  {'id': 'ff_3', 'key': 'STEPS_TRACKER', 'label': 'מעקב צעדים', 'description': 'ספירת צעדים יומית עם נקודות', 'is_enabled': true, 'rollout_pct': 100, 'platforms': ['ios', 'android'], 'config': {'daily_goal': 10000}, 'updated_by': 'ניתאי לוי', 'created_at': '2026-04-01T10:00:00Z', 'updated_at': '2026-08-01T10:00:00Z'},
  {'id': 'ff_4', 'key': 'DARK_MODE', 'label': 'מצב חשוך', 'description': 'תמיכה ב-Dark Mode', 'is_enabled': true, 'rollout_pct': 100, 'platforms': ['ios', 'android', 'web'], 'config': {}, 'updated_by': 'ניתאי לוי', 'created_at': '2024-06-01T10:00:00Z', 'updated_at': '2026-01-01T10:00:00Z'},
  {'id': 'ff_5', 'key': 'PUSH_NOTIFICATIONS', 'label': 'התראות Push', 'description': 'שליחת Push Notifications', 'is_enabled': true, 'rollout_pct': 100, 'platforms': ['ios', 'android'], 'config': {'max_per_day': 5}, 'updated_by': 'ניתאי לוי', 'created_at': '2024-09-01T10:00:00Z', 'updated_at': '2026-06-15T10:00:00Z'},
  {'id': 'ff_6', 'key': 'GAMES', 'label': 'משחקים', 'description': 'מודול משחקים עם נקודות', 'is_enabled': true, 'rollout_pct': 80, 'platforms': ['ios', 'android'], 'config': {'max_daily_points': 100}, 'updated_by': 'ניתאי לוי', 'created_at': '2026-05-01T10:00:00Z', 'updated_at': '2026-08-10T10:00:00Z'},
  {'id': 'ff_7', 'key': 'DEALS_V2', 'label': 'מבצעים V2', 'description': 'ממשק מבצעים חדש עם קופונים', 'is_enabled': false, 'rollout_pct': 0, 'platforms': ['ios', 'android', 'web'], 'config': {}, 'updated_by': 'ניתאי לוי', 'created_at': '2026-08-01T10:00:00Z', 'updated_at': '2026-08-01T10:00:00Z'},
  {'id': 'ff_8', 'key': 'SOCIAL_LOGIN', 'label': 'כניסה חברתית', 'description': 'התחברות עם Google / Apple', 'is_enabled': true, 'rollout_pct': 100, 'platforms': ['ios', 'android'], 'config': {'providers': ['google', 'apple']}, 'updated_by': 'ניתאי לוי', 'created_at': '2025-01-01T10:00:00Z', 'updated_at': '2026-03-01T10:00:00Z'},
  {'id': 'ff_9', 'key': 'CHAT', 'label': 'צ\'אט', 'description': 'צ\'אט ישיר עם בעלי עסקים', 'is_enabled': false, 'rollout_pct': 0, 'platforms': ['ios', 'android'], 'config': {}, 'updated_by': 'ניתאי לוי', 'created_at': '2026-07-01T10:00:00Z', 'updated_at': '2026-07-01T10:00:00Z'},
  {'id': 'ff_10', 'key': 'AR_MAP', 'label': 'מפת AR', 'description': 'מציאות רבודה על המפה', 'is_enabled': false, 'rollout_pct': 0, 'platforms': ['ios', 'android'], 'config': {}, 'updated_by': 'ניתאי לוי', 'created_at': '2026-08-15T10:00:00Z', 'updated_at': '2026-08-15T10:00:00Z'},
];

final _mockRemoteConfig = <Map<String, dynamic>>[
  {'id': 'rc_1', 'key': 'HOME_HEADLINE', 'value': 'מודיעין בשבילך — הכל במקום אחד', 'description': 'כותרת ראשית במסך הבית', 'updated_by': 'ניתאי לוי', 'created_at': '2024-01-01T10:00:00Z', 'updated_at': '2026-08-01T10:00:00Z'},
  {'id': 'rc_2', 'key': 'EMPTY_STATE_SEARCH', 'value': 'לא נמצאו תוצאות. נסו מילות חיפוש אחרות.', 'description': 'הודעה כשאין תוצאות חיפוש', 'updated_by': 'ניתאי לוי', 'created_at': '2024-01-01T10:00:00Z', 'updated_at': '2024-06-01T10:00:00Z'},
  {'id': 'rc_3', 'key': 'ONBOARDING_CTA', 'value': 'בואו נתחיל! 🚀', 'description': 'כפתור CTA במסך ה-onboarding', 'updated_by': 'ניתאי לוי', 'created_at': '2024-01-01T10:00:00Z', 'updated_at': '2026-05-01T10:00:00Z'},
  {'id': 'rc_4', 'key': 'MAINTENANCE_MESSAGE', 'value': 'האפליקציה בתחזוקה. נחזור בקרוב!', 'description': 'הודעת תחזוקה (מוצגת רק אם feature flag MAINTENANCE פעיל)', 'updated_by': 'ניתאי לוי', 'created_at': '2024-03-01T10:00:00Z', 'updated_at': '2024-03-01T10:00:00Z'},
  {'id': 'rc_5', 'key': 'MIN_APP_VERSION', 'value': '1.2.0', 'description': 'גרסת אפליקציה מינימלית (מתחתיה = force update)', 'updated_by': 'ניתאי לוי', 'created_at': '2024-01-01T10:00:00Z', 'updated_at': '2026-08-01T10:00:00Z'},
  {'id': 'rc_6', 'key': 'CONTACT_EMAIL', 'value': 'info@modiin4u.co.il', 'description': 'אימייל ליצירת קשר', 'updated_by': 'ניתאי לוי', 'created_at': '2024-01-01T10:00:00Z', 'updated_at': '2024-01-01T10:00:00Z'},
  {'id': 'rc_7', 'key': 'ABOUT_TEXT', 'value': 'מודיעין בשבילך היא אפליקציה קהילתית עירונית שמחברת בין תושבי מודיעין-מכבים-רעות לעסקים, שירותים ואירועים בעיר.', 'description': 'טקסט "אודות" בהגדרות', 'updated_by': 'ניתאי לוי', 'created_at': '2024-01-01T10:00:00Z', 'updated_at': '2026-06-01T10:00:00Z'},
  {'id': 'rc_8', 'key': 'TERMS_URL', 'value': 'https://modiin4u.co.il/terms', 'description': 'קישור לתנאי שימוש', 'updated_by': 'ניתאי לוי', 'created_at': '2024-01-01T10:00:00Z', 'updated_at': '2024-01-01T10:00:00Z'},
];
