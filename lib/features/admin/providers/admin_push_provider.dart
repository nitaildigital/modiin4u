import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminPushListProvider = StateNotifierProvider<AdminPushListNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return AdminPushListNotifier();
});

class AdminPushListNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  List<Map<String, dynamic>> _all = List.from(_mockNotifications);
  String? _search;
  String? _status;

  AdminPushListNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      var filtered = List<Map<String, dynamic>>.from(_all);
      if (_status != null && _status!.isNotEmpty) {
        filtered = filtered.where((n) => n['status'] == _status).toList();
      }
      if (_search != null && _search!.isNotEmpty) {
        final q = _search!.toLowerCase();
        filtered = filtered.where((n) {
          final title = (n['title'] as String? ?? '').toLowerCase();
          final body = (n['body'] as String? ?? '').toLowerCase();
          return title.contains(q) || body.contains(q);
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

  Future<void> createNotification(Map<String, dynamic> notification) async {
    notification['id'] = 'push_${DateTime.now().millisecondsSinceEpoch}';
    notification['created_at'] = DateTime.now().toIso8601String();
    _all = [notification, ..._all];
    await load();
  }

  Future<void> updateNotification(String id, Map<String, dynamic> fields) async {
    _all = [
      for (final n in _all)
        if (n['id'] == id) {...n, ...fields} else n,
    ];
    await load();
  }

  Future<void> deleteNotification(String id) async {
    _all = _all.where((n) => n['id'] != id).toList();
    await load();
  }

  Future<void> sendNotification(String id) async {
    await updateNotification(id, {
      'status': 'sent',
      'sent_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> scheduleNotification(String id, String scheduledAt) async {
    await updateNotification(id, {
      'status': 'scheduled',
      'scheduled_at': scheduledAt,
    });
  }
}

// ─── Mock Notifications ───

final _mockNotifications = <Map<String, dynamic>>[
  {
    'id': 'push1', 'title': '🔥 מבזק: אזהרת חום כבד',
    'body': 'טמפרטורות של מעל 40 מעלות צפויות בימים הקרובים. שתו מים, הימנעו משהייה בשמש.',
    'image_url': 'https://images.unsplash.com/photo-1504701954957-2010ec3bcec1?w=800',
    'type': 'breaking', 'status': 'sent',
    'target_audience': 'all', 'target_value': null,
    'sent_at': '2026-08-22T06:30:00Z', 'scheduled_at': null,
    'read_count': 4200, 'delivered_count': 5100, 'click_count': 1890, 'total_recipients': 5400,
    'created_at': '2026-08-22T06:00:00Z',
  },
  {
    'id': 'push2', 'title': '🎵 הופעת שלמה ארצי — כרטיסים אחרונים!',
    'body': 'נותרו 50 כרטיסים אחרונים להופעה בהיכל התרבות ב-15.9. הזמינו עכשיו!',
    'image_url': 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=800',
    'type': 'event', 'status': 'sent',
    'target_audience': 'all', 'target_value': null,
    'sent_at': '2026-08-25T10:00:00Z', 'scheduled_at': null,
    'read_count': 3100, 'delivered_count': 5050, 'click_count': 1456, 'total_recipients': 5400,
    'created_at': '2026-08-25T09:00:00Z',
  },
  {
    'id': 'push3', 'title': '🏃 מרתון מודיעין — ההרשמה נפתחה',
    'body': 'הרשמו עכשיו למרתון מודיעין 2026! מסלולים של 5, 10, 21 ו-42 ק"מ. הנחה למוקדמים.',
    'image_url': 'https://images.unsplash.com/photo-1552674605-db6ffd4facb5?w=800',
    'type': 'event', 'status': 'sent',
    'target_audience': 'all', 'target_value': null,
    'sent_at': '2026-08-18T08:00:00Z', 'scheduled_at': null,
    'read_count': 2800, 'delivered_count': 5000, 'click_count': 980, 'total_recipients': 5400,
    'created_at': '2026-08-17T15:00:00Z',
  },
  {
    'id': 'push4', 'title': '🏢 חניון חדש ליד הרכבת',
    'body': 'חניון חדש בן 500 מקומות נפתח ליד תחנת הרכבת. חניה חינם בחודש הראשון!',
    'image_url': 'https://images.unsplash.com/photo-1573348722427-f1d6819fdf98?w=800',
    'type': 'municipal', 'status': 'sent',
    'target_audience': 'all', 'target_value': null,
    'sent_at': '2026-08-01T07:00:00Z', 'scheduled_at': null,
    'read_count': 3500, 'delivered_count': 4900, 'click_count': 2100, 'total_recipients': 5200,
    'created_at': '2026-07-31T16:00:00Z',
  },
  {
    'id': 'push5', 'title': '🍕 הנחה 20% בפיצה פרגו!',
    'body': 'השבוע בלבד — 20% הנחה על כל התפריט בפיצה פרגו. הזמינו עכשיו!',
    'image_url': 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800',
    'type': 'deal', 'status': 'sent',
    'target_audience': 'neighborhood', 'target_value': 'מרכז העיר',
    'sent_at': '2026-08-20T12:00:00Z', 'scheduled_at': null,
    'read_count': 890, 'delivered_count': 1200, 'click_count': 345, 'total_recipients': 1350,
    'created_at': '2026-08-20T11:00:00Z',
  },
  {
    'id': 'push6', 'title': '📋 ישיבת מועצה פתוחה — מחר',
    'body': 'ישיבת מועצת העיר הפתוחה לציבור — מחר ב-19:30 בבניין העירייה. נושאים: תקציב ותחבורה.',
    'image_url': null,
    'type': 'municipal', 'status': 'sent',
    'target_audience': 'all', 'target_value': null,
    'sent_at': '2026-09-17T10:00:00Z', 'scheduled_at': null,
    'read_count': 1900, 'delivered_count': 5100, 'click_count': 670, 'total_recipients': 5400,
    'created_at': '2026-09-17T09:00:00Z',
  },
  {
    'id': 'push7', 'title': '🎉 פסטיבל בירה מודיעין — מחר!',
    'body': 'מחר בפארק המוזיקה מ-18:00. 20+ מבשלות בירה, אוכל רחוב ומוזיקה. אל תפספסו!',
    'image_url': 'https://images.unsplash.com/photo-1535958636474-b021ee887b13?w=800',
    'type': 'event', 'status': 'scheduled',
    'target_audience': 'all', 'target_value': null,
    'sent_at': null, 'scheduled_at': '2026-09-21T10:00:00Z',
    'read_count': 0, 'delivered_count': 0, 'click_count': 0, 'total_recipients': 5400,
    'created_at': '2026-08-28T10:00:00Z',
  },
  {
    'id': 'push8', 'title': '🎨 סדנת ציור למבוגרים — מקומות אחרונים',
    'body': 'נותרו 3 מקומות בסדנת הציור בגלריית האמנות ב-20.9. הרשמו!',
    'image_url': 'https://images.unsplash.com/photo-1513364776144-60967b0f800f?w=800',
    'type': 'event', 'status': 'scheduled',
    'target_audience': 'all', 'target_value': null,
    'sent_at': null, 'scheduled_at': '2026-09-18T09:00:00Z',
    'read_count': 0, 'delivered_count': 0, 'click_count': 0, 'total_recipients': 5400,
    'created_at': '2026-08-27T10:00:00Z',
  },
  {
    'id': 'push9', 'title': '🏫 פתיחת שנת הלימודים — תזכורת',
    'body': 'שנת הלימודים מתחילה ב-1 בספטמבר. כל מה שצריך לדעת — בכתבה המלאה.',
    'image_url': 'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=800',
    'type': 'general', 'status': 'draft',
    'target_audience': 'role', 'target_value': 'הורים',
    'sent_at': null, 'scheduled_at': null,
    'read_count': 0, 'delivered_count': 0, 'click_count': 0, 'total_recipients': 3200,
    'created_at': '2026-08-26T10:00:00Z',
  },
  {
    'id': 'push10', 'title': '🚌 שינויים בקווי אוטובוס',
    'body': 'קו 100 מתוגבר ב-50%, קו 101 משנה מסלול. פרטים מלאים באפליקציה.',
    'image_url': null,
    'type': 'municipal', 'status': 'sent',
    'target_audience': 'all', 'target_value': null,
    'sent_at': '2026-07-25T07:00:00Z', 'scheduled_at': null,
    'read_count': 3800, 'delivered_count': 4800, 'click_count': 1567, 'total_recipients': 5100,
    'created_at': '2026-07-24T16:00:00Z',
  },
  {
    'id': 'push11', 'title': '⚽ הקבוצה העירונית עלתה ליגה!',
    'body': 'מזל טוב! הקבוצה העירונית ניצחה 2-0 ועלתה לליגה הארצית. קראו עוד.',
    'image_url': 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800',
    'type': 'breaking', 'status': 'sent',
    'target_audience': 'all', 'target_value': null,
    'sent_at': '2026-08-10T15:00:00Z', 'scheduled_at': null,
    'read_count': 4500, 'delivered_count': 5000, 'click_count': 2100, 'total_recipients': 5300,
    'created_at': '2026-08-10T14:30:00Z',
  },
  {
    'id': 'push12', 'title': '🛍️ שוק אוכל רחוב — סוף השבוע',
    'body': 'שוק אוכל רחוב עם 30 דוכנים במע"ר. יום שישי מ-12:00. כניסה ₪20.',
    'image_url': 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=800',
    'type': 'event', 'status': 'draft',
    'target_audience': 'all', 'target_value': null,
    'sent_at': null, 'scheduled_at': null,
    'read_count': 0, 'delivered_count': 0, 'click_count': 0, 'total_recipients': 5400,
    'created_at': '2026-08-28T08:00:00Z',
  },
];
