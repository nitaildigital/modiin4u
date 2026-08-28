import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminEventListProvider = StateNotifierProvider<AdminEventListNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return AdminEventListNotifier();
});

class AdminEventListNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  List<Map<String, dynamic>> _all = List.from(_mockEvents);
  String? _search;
  String? _status;

  AdminEventListNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      var filtered = List<Map<String, dynamic>>.from(_all);
      if (_status != null && _status!.isNotEmpty) {
        filtered = filtered.where((e) => e['status'] == _status).toList();
      }
      if (_search != null && _search!.isNotEmpty) {
        final q = _search!.toLowerCase();
        filtered = filtered.where((e) {
          final title = (e['title'] as String? ?? '').toLowerCase();
          final location = (e['location'] as String? ?? '').toLowerCase();
          return title.contains(q) || location.contains(q);
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

  Future<void> createEvent(Map<String, dynamic> event) async {
    event['id'] = 'ev_${DateTime.now().millisecondsSinceEpoch}';
    event['created_at'] = DateTime.now().toIso8601String();
    _all = [event, ..._all];
    await load();
  }

  Future<void> updateEvent(String id, Map<String, dynamic> fields) async {
    _all = [
      for (final e in _all)
        if (e['id'] == id) {...e, ...fields} else e,
    ];
    await load();
  }

  Future<void> deleteEvent(String id) async {
    _all = _all.where((e) => e['id'] != id).toList();
    await load();
  }

  Future<void> updateStatus(String id, String status) async {
    await updateEvent(id, {'status': status});
  }
}

// ─── Mock Events ───

final _mockEvents = <Map<String, dynamic>>[
  {
    'id': 'ev1', 'title': 'הופעת שלמה ארצי',
    'date': '2026-09-15', 'time': '21:00', 'location': 'היכל התרבות מודיעין',
    'price': '₪180', 'category': 'מוזיקה',
    'description': 'הופעה חיה של שלמה ארצי עם להקה מלאה. כרטיסים מוגבלים.',
    'organizer': 'עיריית מודיעין', 'max_capacity': 1200, 'registered_count': 890,
    'is_free': false, 'is_featured': true,
    'status': 'published', 'created_at': '2026-07-01T10:00:00Z',
  },
  {
    'id': 'ev2', 'title': 'סיפורייה בספרייה',
    'date': '2026-09-16', 'time': '10:30', 'location': 'ספרייה עירונית',
    'price': 'חינם', 'category': 'ילדים ומשפחה',
    'description': 'שעת סיפור לילדים בגילאי 3-7 עם הסופרת דליה גרינברג.',
    'organizer': 'הספרייה העירונית', 'max_capacity': 40, 'registered_count': 38,
    'is_free': true, 'is_featured': false,
    'status': 'published', 'created_at': '2026-08-01T10:00:00Z',
  },
  {
    'id': 'ev3', 'title': 'ישיבת מועצה פתוחה',
    'date': '2026-09-18', 'time': '19:30', 'location': 'בניין העירייה',
    'price': 'חינם', 'category': 'עירייה וקהילה',
    'description': 'ישיבת מועצת העיר הפתוחה לציבור. נושאים: תקציב, תחבורה ותכנון.',
    'organizer': 'עיריית מודיעין', 'max_capacity': 200, 'registered_count': 128,
    'is_free': true, 'is_featured': false,
    'status': 'published', 'created_at': '2026-08-10T10:00:00Z',
  },
  {
    'id': 'ev4', 'title': 'יוגה בפארק ענבה',
    'date': '2026-09-14', 'time': '07:00', 'location': 'פארק ענבה',
    'price': 'חינם', 'category': 'ספורט',
    'description': 'שיעור יוגה בוקר בחינם לכל הרמות. הביאו מזרן.',
    'organizer': 'סטודיו שרה', 'max_capacity': 60, 'registered_count': 45,
    'is_free': true, 'is_featured': false,
    'status': 'published', 'created_at': '2026-08-05T10:00:00Z',
  },
  {
    'id': 'ev5', 'title': 'פסטיבל בירה מודיעין',
    'date': '2026-09-22', 'time': '18:00', 'location': 'פארק המוזיקה',
    'price': '₪50', 'category': 'קולינריה',
    'description': 'פסטיבל בירה ראשון מסוגו במודיעין. 20+ מבשלות בירה, אוכל רחוב ומוזיקה חיה.',
    'organizer': 'בירה בעיר בע"מ', 'max_capacity': 2000, 'registered_count': 1456,
    'is_free': false, 'is_featured': true,
    'status': 'published', 'created_at': '2026-07-15T10:00:00Z',
  },
  {
    'id': 'ev6', 'title': 'סדנת בישול ילדים',
    'date': '2026-09-17', 'time': '16:00', 'location': 'מתנ"ס אבני חן',
    'price': '₪60', 'category': 'ילדים ומשפחה',
    'description': 'סדנת בישול חווייתית לילדים בגילאי 7-12. כולל חומרי גלם.',
    'organizer': 'שף דניאל', 'max_capacity': 20, 'registered_count': 18,
    'is_free': false, 'is_featured': false,
    'status': 'published', 'created_at': '2026-08-08T10:00:00Z',
  },
  {
    'id': 'ev7', 'title': 'ריצת ערב קהילתית',
    'date': '2026-09-19', 'time': '19:00', 'location': 'אגם ענבה',
    'price': 'חינם', 'category': 'ספורט',
    'description': 'ריצה קהילתית של 5 ק"מ סביב אגם ענבה. לכל הרמות.',
    'organizer': 'קבוצת ריצה מודיעין', 'max_capacity': 300, 'registered_count': 167,
    'is_free': true, 'is_featured': false,
    'status': 'published', 'created_at': '2026-08-12T10:00:00Z',
  },
  {
    'id': 'ev8', 'title': 'שוק אוכל רחוב',
    'date': '2026-09-23', 'time': '12:00', 'location': 'המע"ר',
    'price': '₪20 כניסה', 'category': 'קולינריה',
    'description': 'שוק אוכל רחוב עם 30 דוכנים. אוכל מכל העולם, מוזיקה ואווירה.',
    'organizer': 'פוד טראק ישראל', 'max_capacity': 1500, 'registered_count': 890,
    'is_free': false, 'is_featured': true,
    'status': 'published', 'created_at': '2026-08-15T10:00:00Z',
  },
  {
    'id': 'ev9', 'title': 'סדנת ציור למבוגרים',
    'date': '2026-09-20', 'time': '18:00', 'location': 'גלריית האמנות',
    'price': '₪90', 'category': 'תרבות',
    'description': 'סדנת ציור בצבעי שמן — אין צורך בניסיון קודם. כולל חומרים.',
    'organizer': 'גלריית מודיעין', 'max_capacity': 15, 'registered_count': 12,
    'is_free': false, 'is_featured': false,
    'status': 'published', 'created_at': '2026-08-18T10:00:00Z',
  },
  {
    'id': 'ev10', 'title': 'הרצאה: בינה מלאכותית בחיי היום-יום',
    'date': '2026-10-01', 'time': '20:00', 'location': 'אולם כנסים מרכזי',
    'price': '₪40', 'category': 'חינוך',
    'description': 'הרצאה פופולרית על AI ואיך הוא משנה את חיינו. עם פרופ\' יוסי בניה.',
    'organizer': 'TEDx מודיעין', 'max_capacity': 300, 'registered_count': 245,
    'is_free': false, 'is_featured': true,
    'status': 'published', 'created_at': '2026-08-20T10:00:00Z',
  },
  {
    'id': 'ev11', 'title': 'מרתון מודיעין 2026',
    'date': '2026-11-15', 'time': '06:30', 'location': 'כיכר העירייה',
    'price': '₪120', 'category': 'ספורט',
    'description': 'מרתון מודיעין השנתי. מסלולים של 5, 10, 21 ו-42 ק"מ.',
    'organizer': 'עיריית מודיעין', 'max_capacity': 5000, 'registered_count': 2340,
    'is_free': false, 'is_featured': true,
    'status': 'published', 'created_at': '2026-07-20T10:00:00Z',
  },
  {
    'id': 'ev12', 'title': 'מופע קסמים לילדים',
    'date': '2026-10-05', 'time': '17:00', 'location': 'מתנ"ס מורשת',
    'price': '₪35', 'category': 'ילדים ומשפחה',
    'description': 'מופע קסמים אינטראקטיבי לילדים עם הקוסם גיא.',
    'organizer': 'מתנ"ס מורשת', 'max_capacity': 100, 'registered_count': 78,
    'is_free': false, 'is_featured': false,
    'status': 'draft', 'created_at': '2026-08-22T10:00:00Z',
  },
  {
    'id': 'ev13', 'title': 'ערב שירה בציבור',
    'date': '2026-09-28', 'time': '20:30', 'location': 'גן העירייה',
    'price': 'חינם', 'category': 'מוזיקה',
    'description': 'ערב שירה בציבור עם שירי ארץ ישראל ושירים מזרחיים. הביאו כיסאות.',
    'organizer': 'המחלקה לתרבות', 'max_capacity': 500, 'registered_count': 320,
    'is_free': true, 'is_featured': false,
    'status': 'published', 'created_at': '2026-08-19T10:00:00Z',
  },
  {
    'id': 'ev14', 'title': 'יום פתוח — מתנ"ס בוכמן',
    'date': '2026-09-10', 'time': '10:00', 'location': 'מתנ"ס בוכמן',
    'price': 'חינם', 'category': 'חינוך',
    'description': 'יום פתוח עם חוגים חינם, הדגמות ופעילויות לכל המשפחה. הרשמה לחוגים במקום.',
    'organizer': 'מתנ"ס בוכמן', 'max_capacity': 400, 'registered_count': 210,
    'is_free': true, 'is_featured': false,
    'status': 'published', 'created_at': '2026-08-15T10:00:00Z',
  },
  {
    'id': 'ev15', 'title': 'תחרות טריוויה עירונית',
    'date': '2026-10-08', 'time': '19:30', 'location': 'פאב הבירה, המע"ר',
    'price': '₪30 לקבוצה', 'category': 'עירייה וקהילה',
    'description': 'תחרות טריוויה בין שכונות מודיעין. פרסים ואווירה.',
    'organizer': 'קהילת מודיעין', 'max_capacity': 200, 'registered_count': 156,
    'is_free': false, 'is_featured': false,
    'status': 'draft', 'created_at': '2026-08-24T10:00:00Z',
  },
  {
    'id': 'ev16', 'title': 'סיור ארכיאולוגי — תל גזר',
    'date': '2026-10-12', 'time': '08:00', 'location': 'תל גזר (הסעה מהעירייה)',
    'price': '₪50', 'category': 'תרבות',
    'description': 'סיור מודרך בתל גזר — מהאתרים הארכיאולוגיים החשובים ביותר באזור. כולל הסעה.',
    'organizer': 'רשות העתיקות', 'max_capacity': 40, 'registered_count': 35,
    'is_free': false, 'is_featured': false,
    'status': 'published', 'created_at': '2026-08-21T10:00:00Z',
  },
  {
    'id': 'ev17', 'title': 'סדנת פיתוח אפליקציות לנוער',
    'date': '2026-10-20', 'time': '14:00', 'location': 'מרכז חדשנות מודיעין',
    'price': '₪80', 'category': 'חינוך',
    'description': 'סדנת חצי יום לבני 14-18. לימוד בסיסי של פיתוח אפליקציות.',
    'organizer': 'TechKids', 'max_capacity': 25, 'registered_count': 19,
    'is_free': false, 'is_featured': false,
    'status': 'published', 'created_at': '2026-08-23T10:00:00Z',
  },
];
