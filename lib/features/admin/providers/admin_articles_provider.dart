import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminArticleListProvider = StateNotifierProvider<AdminArticleListNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return AdminArticleListNotifier();
});

final articleCategoriesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return _mockArticleCategories;
});

class AdminArticleListNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  List<Map<String, dynamic>> _all = List.from(_mockArticles);
  String? _search;
  String? _status;

  AdminArticleListNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      var filtered = List<Map<String, dynamic>>.from(_all);
      if (_status != null && _status!.isNotEmpty) {
        filtered = filtered.where((a) => a['status'] == _status).toList();
      }
      if (_search != null && _search!.isNotEmpty) {
        final q = _search!.toLowerCase();
        filtered = filtered.where((a) {
          final title = (a['title'] as String? ?? '').toLowerCase();
          final slug = (a['slug'] as String? ?? '').toLowerCase();
          return title.contains(q) || slug.contains(q);
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

  Future<void> createArticle(Map<String, dynamic> article) async {
    article['id'] = 'a_${DateTime.now().millisecondsSinceEpoch}';
    article['created_at'] = DateTime.now().toIso8601String();
    _all = [article, ..._all];
    await load();
  }

  Future<void> updateArticle(String id, Map<String, dynamic> fields) async {
    _all = [
      for (final a in _all)
        if (a['id'] == id) {...a, ...fields} else a,
    ];
    await load();
  }

  Future<void> deleteArticle(String id) async {
    _all = _all.where((a) => a['id'] != id).toList();
    await load();
  }

  Future<void> updateStatus(String id, String status) async {
    final updates = <String, dynamic>{'status': status};
    if (status == 'published') {
      updates['published_at'] = DateTime.now().toIso8601String();
    }
    await updateArticle(id, updates);
  }
}

// ─── Mock Categories ───

final _mockArticleCategories = <Map<String, dynamic>>[
  {'id': 'ac1', 'name': 'עירייה ומוניציפלי', 'slug': 'municipal', 'scope': 'article', 'is_active': true, 'sort_order': 1},
  {'id': 'ac2', 'name': 'עסקים', 'slug': 'business', 'scope': 'article', 'is_active': true, 'sort_order': 2},
  {'id': 'ac3', 'name': 'ספורט', 'slug': 'sports', 'scope': 'article', 'is_active': true, 'sort_order': 3},
  {'id': 'ac4', 'name': 'חינוך', 'slug': 'education', 'scope': 'article', 'is_active': true, 'sort_order': 4},
  {'id': 'ac5', 'name': 'קהילה', 'slug': 'community', 'scope': 'article', 'is_active': true, 'sort_order': 5},
  {'id': 'ac6', 'name': 'בטיחות', 'slug': 'safety', 'scope': 'article', 'is_active': true, 'sort_order': 6},
  {'id': 'ac7', 'name': 'תרבות ובילוי', 'slug': 'culture', 'scope': 'article', 'is_active': true, 'sort_order': 7},
  {'id': 'ac8', 'name': 'נדל"ן', 'slug': 'realestate', 'scope': 'article', 'is_active': true, 'sort_order': 8},
];

// ─── Mock Articles ───

final _mockArticles = <Map<String, dynamic>>[
  {
    'id': 'a1', 'title': 'פארק ענבה — שדרוג חדש לתושבים',
    'subtitle': 'פארק ענבה עובר מתיחת פנים', 'slug': 'anaba-park-upgrade',
    'body': 'עיריית מודיעין מכבים רעות השיקה היום את תוכנית השדרוג של פארק ענבה. התוכנית כוללת מגרשי משחקים חדשים, שבילי אופניים משודרגים, תאורה חדשה ושטחי דשא מורחבים.',
    'excerpt': 'פארק ענבה עובר מתיחת פנים עם מגרשי משחקים חדשים ושבילים משודרגים.',
    'status': 'published', 'published_at': '2026-08-15T08:00:00Z',
    'is_featured': true, 'is_breaking': false, 'is_pinned': false, 'is_sponsored': false,
    'is_members_only': false, 'push_worthy': true,
    'view_count': 1240,
    'meta_description': 'פארק ענבה במודיעין עובר שדרוג — מגרשי משחקים חדשים, שבילים ותאורה.',
    'meta_keywords': 'פארק ענבה, מודיעין, שדרוג',
    'focus_keyword': 'פארק ענבה',
    'created_at': '2026-08-14T10:00:00Z',
  },
  {
    'id': 'a2', 'title': 'פתיחת מרכז מסחרי חדש במע"ר',
    'subtitle': 'מרכז בן 3 קומות צפוי להיפתח בקרוב', 'slug': 'new-commercial-center-maar',
    'body': 'מרכז מסחרי חדש בן 3 קומות צפוי להיפתח בחודשים הקרובים במע"ר מודיעין. המרכז יכלול חנויות אופנה, מסעדות, קולנוע ושטחי בילוי.',
    'status': 'published', 'published_at': '2026-08-12T09:00:00Z',
    'view_count': 890,
    'meta_description': 'מרכז מסחרי חדש במע"ר מודיעין — חנויות, מסעדות ובילוי.',
    'created_at': '2026-08-11T10:00:00Z',
  },
  {
    'id': 'a3', 'title': 'קבוצת הכדורגל העירונית עלתה ליגה',
    'subtitle': 'ניצחון 2-0 אתמול', 'slug': 'modiin-fc-promotion',
    'body': 'הקבוצה העירונית ניצחה אתמול 2-0 ועלתה לליגה הארצית. זהו הישג היסטורי לקבוצה שהוקמה לפני 5 שנים בלבד.',
    'status': 'published', 'published_at': '2026-08-10T14:00:00Z',
    'is_breaking': true, 'push_worthy': true,
    'view_count': 2100,
    'created_at': '2026-08-10T13:00:00Z',
  },
  {
    'id': 'a4', 'title': 'טיפים לקיץ בטוח — מדריך הורים',
    'subtitle': 'כללי בטיחות חשובים לימי הקיץ', 'slug': 'summer-safety-tips',
    'body': 'עם הגעת הקיץ חשוב לשמור על כללי בטיחות בבריכה, בים ובפארקים. מדריך מקיף להורים.',
    'status': 'draft',
    'meta_description': 'מדריך בטיחות קיץ להורים — טיפים, הנחיות ומידע.',
    'view_count': 0,
    'created_at': '2026-08-08T10:00:00Z',
  },
  {
    'id': 'a5', 'title': 'שנת הלימודים החדשה: כל מה שצריך לדעת',
    'subtitle': 'פתיחת שנת הלימודים תשפ"ז', 'slug': 'school-year-2027-guide',
    'body': 'מדריך מקיף להורים לקראת פתיחת שנת הלימודים. מועדי רישום, רשימות ציוד, ותחבורה.',
    'status': 'published', 'published_at': '2026-08-05T07:00:00Z',
    'is_featured': true, 'is_pinned': true,
    'view_count': 3450,
    'meta_description': 'מדריך הורים לפתיחת שנת הלימודים במודיעין — רישום, ציוד ותחבורה.',
    'created_at': '2026-08-04T10:00:00Z',
  },
  {
    'id': 'a6', 'title': 'חניון חדש ייפתח ליד הרכבת',
    'subtitle': 'פתרון החניה לנוסעי הרכבת', 'slug': 'new-parking-train-station',
    'body': 'העירייה הודיעה על פתיחת חניון חדש בן 500 מקומות ליד תחנת הרכבת מודיעין מרכז.',
    'status': 'published', 'published_at': '2026-08-01T10:00:00Z',
    'view_count': 1567,
    'meta_description': 'חניון חדש ליד תחנת הרכבת מודיעין — 500 מקומות חניה.',
    'created_at': '2026-07-31T10:00:00Z',
  },
  {
    'id': 'a7', 'title': 'פסטיבל הבירה הראשון של מודיעין',
    'subtitle': 'אירוע ראשון מסוגו בעיר', 'slug': 'modiin-beer-festival',
    'body': 'פסטיבל בירה ראשון מסוגו יתקיים בפארק ענבה בסוף אוגוסט. יותר מ-20 מבשלות בירה ישתתפו.',
    'status': 'published', 'published_at': '2026-07-28T10:00:00Z',
    'view_count': 2890,
    'is_featured': true,
    'created_at': '2026-07-27T10:00:00Z',
  },
  {
    'id': 'a8', 'title': 'עדכון: קווי אוטובוס חדשים למודיעין',
    'subtitle': 'קווים 100 ו-101 ישתנו', 'slug': 'bus-routes-update',
    'body': 'משרד התחבורה הודיע על שינויים בקווי האוטובוס המשרתים את מודיעין. קו 100 יתוגבר ב-50% וקו 101 ישנה מסלול.',
    'status': 'published', 'published_at': '2026-07-25T10:00:00Z',
    'view_count': 1890,
    'push_worthy': true,
    'meta_description': 'שינויים בקווי אוטובוס מודיעין — קו 100 מתוגבר, קו 101 משנה מסלול.',
    'created_at': '2026-07-24T10:00:00Z',
  },
  {
    'id': 'a9', 'title': 'סקירה: 5 המסעדות החדשות הטובות ביותר',
    'subtitle': 'פתחו בחודשים האחרונים', 'slug': 'top-5-new-restaurants',
    'body': 'סוקרים את 5 המסעדות החדשות שנפתחו לאחרונה במודיעין ומדרגים אותן. מאסייתי ועד איטלקי.',
    'status': 'published', 'published_at': '2026-07-20T10:00:00Z',
    'is_sponsored': true,
    'view_count': 4200,
    'created_at': '2026-07-19T10:00:00Z',
  },
  {
    'id': 'a10', 'title': 'תוכנית עירונית: גינות קהילתיות בכל שכונה',
    'subtitle': 'פרויקט ירוק חדש של העירייה', 'slug': 'community-gardens-project',
    'body': 'העירייה משיקה תוכנית להקמת גינות קהילתיות בכל שכונה. תושבים יוכלו לגדל ירקות ופרחים.',
    'status': 'draft',
    'view_count': 0,
    'created_at': '2026-08-20T10:00:00Z',
  },
  {
    'id': 'a11', 'title': 'מרתון מודיעין 2026 — ההרשמה נפתחה',
    'subtitle': 'מסלולים של 5, 10 ו-42 ק"מ', 'slug': 'modiin-marathon-2026',
    'body': 'ההרשמה למרתון מודיעין 2026 נפתחה. השנה עם מסלולים חדשים ופרסים מוגדלים. מועד האירוע: 15 בנובמבר.',
    'status': 'published', 'published_at': '2026-08-18T10:00:00Z',
    'is_featured': true,
    'view_count': 1650,
    'meta_description': 'מרתון מודיעין 2026 — הרשמה, מסלולים ופרטים.',
    'created_at': '2026-08-17T10:00:00Z',
  },
  {
    'id': 'a12', 'title': 'בית ספר חדש ייפתח בשכונת נופים',
    'subtitle': 'תלמידי כיתות א-ו', 'slug': 'new-school-nofim',
    'body': 'בית ספר יסודי חדש ייפתח בשכונת נופים בשנת הלימודים הבאה. בית הספר יכיל 24 כיתות ויכלול מעבדות מדע ואולם ספורט.',
    'status': 'published', 'published_at': '2026-07-15T10:00:00Z',
    'view_count': 2340,
    'created_at': '2026-07-14T10:00:00Z',
  },
  {
    'id': 'a13', 'title': 'מחירי הנדל"ן במודיעין — סיכום רבעון 2',
    'subtitle': 'עלייה של 3% ברבעון', 'slug': 'realestate-q2-summary',
    'body': 'מחירי הדירות במודיעין עלו ב-3% ברבעון השני. הדירות היקרות ביותר באבני חן, הנגישות ביותר ברמת מודיעין.',
    'status': 'archived',
    'view_count': 5670,
    'created_at': '2026-07-01T10:00:00Z',
  },
  {
    'id': 'a14', 'title': 'מזג אוויר קיצוני: אזהרת חום כבד',
    'subtitle': 'טמפרטורות של מעל 40 מעלות', 'slug': 'extreme-heat-warning',
    'body': 'השירות המטאורולוגי מזהיר מפני חום כבד צפוי בימים הקרובים. טיפים להתמודדות ומקומות מוצללים.',
    'status': 'published', 'published_at': '2026-08-22T06:00:00Z',
    'is_breaking': true, 'push_worthy': true,
    'view_count': 3200,
    'created_at': '2026-08-22T05:30:00Z',
  },
  {
    'id': 'a15', 'title': 'רשת מכבי שפתחה סניף חדש במודיעין',
    'subtitle': 'שירותים רפואיים מורחבים', 'slug': 'maccabi-new-branch',
    'body': 'רשת מכבי שירותי בריאות פתחה סניף חדש במרכז העיר עם שעות פעילות מורחבות ומרפאת ילדים.',
    'status': 'draft',
    'view_count': 0,
    'created_at': '2026-08-25T10:00:00Z',
  },
];
