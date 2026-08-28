import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Real-Time Stats ───

final adminRealTimeProvider = StateNotifierProvider<AdminRealTimeNotifier, Map<String, dynamic>>((ref) {
  return AdminRealTimeNotifier();
});

class AdminRealTimeNotifier extends StateNotifier<Map<String, dynamic>> {
  AdminRealTimeNotifier() : super(_generateRealTime());

  void refresh() => state = _generateRealTime();
}

Map<String, dynamic> _generateRealTime() {
  final rng = Random();
  return {
    'active_now': 127 + rng.nextInt(60),
    'active_ios': 68 + rng.nextInt(30),
    'active_android': 42 + rng.nextInt(20),
    'active_web': 17 + rng.nextInt(10),
    'sessions_today': 1834 + rng.nextInt(200),
    'page_views_today': 6720 + rng.nextInt(500),
    'avg_session_duration_sec': 185 + rng.nextInt(60),
    'bounce_rate_pct': 22 + rng.nextInt(8),
    'searches_today': 342 + rng.nextInt(50),
    'shares_today': 28 + rng.nextInt(15),
    'new_users_today': 14 + rng.nextInt(8),
    'notifications_sent_today': 3200 + rng.nextInt(300),
    'notifications_opened': 1480 + rng.nextInt(200),
    'errors_today': rng.nextInt(5),
    'api_latency_ms': 45 + rng.nextInt(30),
    // Live user locations (lat/lng near Modi'in)
    'live_users': List.generate(25 + rng.nextInt(20), (i) => {
      'lat': 31.89 + (rng.nextDouble() - 0.5) * 0.06,
      'lng': 35.01 + (rng.nextDouble() - 0.5) * 0.06,
      'neighborhood': ['אבני חן', 'בוכמן', 'מורשת', 'כפר האורנים', 'ישפרו סנטר', 'רמת הדר', 'ליגד סנטר'][rng.nextInt(7)],
    }),
  };
}

// ─── Daily Analytics (DAU/WAU/MAU + engagement) ───

final adminDailyAnalyticsProvider = Provider<Map<String, dynamic>>((ref) {
  return _dailyAnalytics;
});

final _dailyAnalytics = <String, dynamic>{
  // DAU for last 30 days
  'dau': List.generate(30, (i) {
    final date = DateTime(2026, 8, 28).subtract(Duration(days: 29 - i));
    final base = date.weekday == 6 || date.weekday == 7 ? 680 : 1100;
    return {'date': date.toIso8601String().split('T')[0], 'count': base + Random(i).nextInt(300)};
  }),
  // WAU for last 12 weeks
  'wau': [
    {'week': 'W23', 'count': 3200}, {'week': 'W24', 'count': 3450}, {'week': 'W25', 'count': 3680},
    {'week': 'W26', 'count': 3520}, {'week': 'W27', 'count': 3890}, {'week': 'W28', 'count': 4100},
    {'week': 'W29', 'count': 4250}, {'week': 'W30', 'count': 4380}, {'week': 'W31', 'count': 4500},
    {'week': 'W32', 'count': 4680}, {'week': 'W33', 'count': 4820}, {'week': 'W34', 'count': 4950},
  ],
  // MAU for last 6 months
  'mau': [
    {'month': 'מרץ', 'count': 8200}, {'month': 'אפריל', 'count': 9100}, {'month': 'מאי', 'count': 10500},
    {'month': 'יוני', 'count': 11200}, {'month': 'יולי', 'count': 12800}, {'month': 'אוגוסט', 'count': 14200},
  ],
  // Current stats
  'dau_current': 1247,
  'dau_change_pct': 11.3,
  'wau_current': 4950,
  'wau_change_pct': 8.7,
  'mau_current': 14200,
  'mau_change_pct': 10.9,

  // Retention cohorts (% still active after N days)
  'retention': {
    'day1': 72.0, 'day3': 58.0, 'day7': 45.0, 'day14': 38.0, 'day30': 28.0, 'day60': 22.0, 'day90': 18.0,
  },
  // Retention by month (for chart)
  'retention_monthly': [
    {'month': 'מרץ', 'd1': 68, 'd7': 41, 'd30': 24},
    {'month': 'אפריל', 'd1': 70, 'd7': 43, 'd30': 25},
    {'month': 'מאי', 'd1': 71, 'd7': 44, 'd30': 26},
    {'month': 'יוני', 'd1': 72, 'd7': 45, 'd30': 27},
    {'month': 'יולי', 'd1': 73, 'd7': 46, 'd30': 28},
    {'month': 'אוגוסט', 'd1': 75, 'd7': 48, 'd30': 30},
  ],

  // Session analytics
  'avg_session_duration_min': 3.2,
  'avg_sessions_per_user': 2.8,
  'avg_screens_per_session': 6.4,
  'peak_hours': [
    {'hour': 7, 'users': 180}, {'hour': 8, 'users': 420}, {'hour': 9, 'users': 580},
    {'hour': 10, 'users': 620}, {'hour': 11, 'users': 510}, {'hour': 12, 'users': 780},
    {'hour': 13, 'users': 850}, {'hour': 14, 'users': 720}, {'hour': 15, 'users': 650},
    {'hour': 16, 'users': 890}, {'hour': 17, 'users': 1050}, {'hour': 18, 'users': 980},
    {'hour': 19, 'users': 1120}, {'hour': 20, 'users': 1180}, {'hour': 21, 'users': 940},
    {'hour': 22, 'users': 620}, {'hour': 23, 'users': 340},
  ],
};

// ─── Content Performance ───

final adminContentPerformanceProvider = Provider<Map<String, dynamic>>((ref) {
  return _contentPerformance;
});

final _contentPerformance = <String, dynamic>{
  'top_articles': [
    {'title': 'מרכז מסחרי חדש בכניסה לעיר', 'views': 4520, 'shares': 89, 'comments': 34, 'avg_read_time_sec': 142},
    {'title': 'פארק ענבה — שעות פעילות חדשות', 'views': 3890, 'shares': 45, 'comments': 12, 'avg_read_time_sec': 98},
    {'title': 'שוק איכרים חדש בכפר האורנים', 'views': 3210, 'shares': 67, 'comments': 28, 'avg_read_time_sec': 115},
    {'title': 'קבוצת הכדורגל העירונית — עונה חדשה', 'views': 2780, 'shares': 52, 'comments': 41, 'avg_read_time_sec': 134},
    {'title': 'בית ספר חדש ברמת דניאל', 'views': 2450, 'shares': 31, 'comments': 19, 'avg_read_time_sec': 87},
  ],
  'top_businesses': [
    {'name': 'פיצה פרגו', 'views': 8920, 'clicks_to_phone': 234, 'clicks_to_nav': 189, 'saves': 156, 'reviews_this_month': 12},
    {'name': 'סופר פארם מודיעין', 'views': 7340, 'clicks_to_phone': 178, 'clicks_to_nav': 312, 'saves': 89, 'reviews_this_month': 8},
    {'name': 'סטודיו שרה — יוגה ופילאטיס', 'views': 5120, 'clicks_to_phone': 145, 'clicks_to_nav': 98, 'saves': 234, 'reviews_this_month': 15},
    {'name': 'ביסטרו מודיעין', 'views': 4870, 'clicks_to_phone': 167, 'clicks_to_nav': 201, 'saves': 112, 'reviews_this_month': 9},
    {'name': 'קפה ביגה', 'views': 3980, 'clicks_to_phone': 89, 'clicks_to_nav': 145, 'saves': 78, 'reviews_this_month': 6},
  ],
  'top_events': [
    {'title': 'הופעת שלמה ארצי', 'views': 12400, 'ticket_clicks': 3200, 'shares': 456, 'rsvp': 890},
    {'title': 'פסטיבל הבירה מודיעין', 'views': 8900, 'ticket_clicks': 1800, 'shares': 312, 'rsvp': 567},
    {'title': 'ריצת ערב קהילתית', 'views': 3400, 'ticket_clicks': 0, 'shares': 89, 'rsvp': 234},
    {'title': 'שוק אוכל רחוב', 'views': 2900, 'ticket_clicks': 0, 'shares': 67, 'rsvp': 189},
    {'title': 'סדנת בישול איטלקי', 'views': 1800, 'ticket_clicks': 450, 'shares': 34, 'rsvp': 45},
  ],
  'search_queries': [
    {'query': 'פיצה', 'count': 342, 'results_avg': 8},
    {'query': 'מסעדות', 'count': 289, 'results_avg': 24},
    {'query': 'אירועים', 'count': 234, 'results_avg': 15},
    {'query': 'כושר', 'count': 178, 'results_avg': 12},
    {'query': 'משלוח', 'count': 156, 'results_avg': 18},
    {'query': 'קפה', 'count': 145, 'results_avg': 9},
    {'query': 'רופא', 'count': 134, 'results_avg': 6},
    {'query': 'חניה', 'count': 112, 'results_avg': 4},
    {'query': 'בית ספר', 'count': 98, 'results_avg': 7},
    {'query': 'שוק', 'count': 87, 'results_avg': 3},
  ],
  'zero_result_searches': [
    {'query': 'טרמפולינות', 'count': 23},
    {'query': 'כביסה', 'count': 18},
    {'query': 'מוסך', 'count': 15},
    {'query': 'חשמלאי', 'count': 12},
    {'query': 'וטרינר', 'count': 9},
  ],
  // Content by category
  'categories_distribution': [
    {'name': 'מסעדות ובתי קפה', 'businesses': 45, 'views': 34200, 'pct': 28},
    {'name': 'בריאות וכושר', 'businesses': 22, 'views': 18900, 'pct': 15},
    {'name': 'קמעונאות', 'businesses': 38, 'views': 16800, 'pct': 14},
    {'name': 'שירותים מקצועיים', 'businesses': 31, 'views': 14200, 'pct': 12},
    {'name': 'חינוך', 'businesses': 18, 'views': 12400, 'pct': 10},
    {'name': 'פנאי ובידור', 'businesses': 14, 'views': 10800, 'pct': 9},
    {'name': 'יופי וטיפוח', 'businesses': 16, 'views': 8400, 'pct': 7},
    {'name': 'אחר', 'businesses': 12, 'views': 6200, 'pct': 5},
  ],
};

// ─── Ad & Revenue Analytics ───

final adminAdAnalyticsProvider = Provider<Map<String, dynamic>>((ref) {
  return _adAnalytics;
});

final _adAnalytics = <String, dynamic>{
  // Revenue summary
  'revenue_total_year': 284500,
  'revenue_this_month': 38200,
  'revenue_last_month': 34800,
  'revenue_growth_pct': 9.8,
  'mrr': 24500, // monthly recurring revenue
  'arr_estimated': 294000,

  // Revenue by source
  'revenue_by_source': [
    {'source': 'מנויים חודשיים', 'amount': 14200, 'pct': 37},
    {'source': 'באנרים ראשיים', 'amount': 8600, 'pct': 23},
    {'source': 'Push ממומנים', 'amount': 5400, 'pct': 14},
    {'source': 'עסק מומלץ', 'amount': 4200, 'pct': 11},
    {'source': 'תוכן ממומן', 'amount': 3400, 'pct': 9},
    {'source': 'חבילות מיוחדות', 'amount': 2400, 'pct': 6},
  ],

  // Revenue trend (last 6 months)
  'revenue_trend': [
    {'month': 'מרץ', 'amount': 22400}, {'month': 'אפריל', 'amount': 25800},
    {'month': 'מאי', 'amount': 28600}, {'month': 'יוני', 'amount': 31200},
    {'month': 'יולי', 'amount': 34800}, {'month': 'אוגוסט', 'amount': 38200},
  ],

  // Ad performance
  'total_impressions': 1240000,
  'total_clicks': 38900,
  'overall_ctr': 3.14,
  'avg_cpm': 12.5,
  'fill_rate_pct': 87,

  // Top performing placements
  'placement_performance': [
    {'label': 'ראש עמוד הבית', 'impressions': 380000, 'clicks': 15200, 'ctr': 4.0, 'revenue': 12800},
    {'label': 'אמצע עמוד הבית', 'impressions': 290000, 'clicks': 8700, 'ctr': 3.0, 'revenue': 8200},
    {'label': 'בתוך כתבה', 'impressions': 210000, 'clicks': 7560, 'ctr': 3.6, 'revenue': 7600},
    {'label': 'תחתית כתבה', 'impressions': 180000, 'clicks': 3600, 'ctr': 2.0, 'revenue': 4200},
    {'label': 'סייד-בר עסק', 'impressions': 120000, 'clicks': 2640, 'ctr': 2.2, 'revenue': 3400},
    {'label': 'תוצאות חיפוש', 'impressions': 60000, 'clicks': 1200, 'ctr': 2.0, 'revenue': 2000},
  ],

  // Conversion funnel for offers
  'offer_funnel': {
    'views': 45200,
    'clicks': 8900,
    'code_copies': 3400,
    'claims': 1856,
    'conversion_rate_pct': 4.1,
  },

  // Top advertisers (revenue)
  'top_advertisers': [
    {'name': 'סופר פארם מודיעין', 'revenue': 12400, 'campaigns': 4, 'active_since': '2024-01-01'},
    {'name': 'פיצה פרגו', 'revenue': 9800, 'campaigns': 5, 'active_since': '2024-03-15'},
    {'name': 'סטודיו שרה', 'revenue': 6200, 'campaigns': 3, 'active_since': '2024-09-01'},
    {'name': 'ביסטרו מודיעין', 'revenue': 4800, 'campaigns': 2, 'active_since': '2026-08-01'},
    {'name': 'קפה ביגה', 'revenue': 3200, 'campaigns': 1, 'active_since': '2026-06-01'},
  ],
};

// ─── User Demographics & Behavior ───

final adminUserAnalyticsProvider = Provider<Map<String, dynamic>>((ref) {
  return _userAnalytics;
});

final _userAnalytics = <String, dynamic>{
  'total_users': 14200,
  'verified_users': 12800,
  'business_owners': 196,
  'new_users_this_month': 680,
  'churn_this_month': 142,
  'net_growth': 538,

  // User acquisition channels
  'acquisition': [
    {'channel': 'אורגני (Google)', 'users': 4800, 'pct': 34},
    {'channel': 'הפניה מחבר', 'users': 3200, 'pct': 22},
    {'channel': 'פייסבוק', 'users': 2400, 'pct': 17},
    {'channel': 'App Store / Play Store', 'users': 1800, 'pct': 13},
    {'channel': 'קמפיינים', 'users': 1200, 'pct': 8},
    {'channel': 'אחר', 'users': 800, 'pct': 6},
  ],

  // Users by neighborhood
  'by_neighborhood': [
    {'name': 'אבני חן', 'users': 2400, 'pct': 17},
    {'name': 'בוכמן', 'users': 2100, 'pct': 15},
    {'name': 'מורשת', 'users': 1900, 'pct': 13},
    {'name': 'כפר האורנים', 'users': 1700, 'pct': 12},
    {'name': 'רמת הדר', 'users': 1400, 'pct': 10},
    {'name': 'רמת דניאל', 'users': 1200, 'pct': 9},
    {'name': 'שמשון', 'users': 1100, 'pct': 8},
    {'name': 'עמק שילה', 'users': 900, 'pct': 6},
    {'name': 'אזור תעשייה', 'users': 600, 'pct': 4},
    {'name': 'אחר', 'users': 900, 'pct': 6},
  ],

  // Platform distribution
  'by_platform': [
    {'platform': 'iOS', 'users': 6500, 'pct': 46},
    {'platform': 'Android', 'users': 5700, 'pct': 40},
    {'platform': 'Web', 'users': 2000, 'pct': 14},
  ],

  // Age distribution (estimated)
  'by_age': [
    {'range': '18-24', 'pct': 8},
    {'range': '25-34', 'pct': 24},
    {'range': '35-44', 'pct': 32},
    {'range': '45-54', 'pct': 22},
    {'range': '55+', 'pct': 14},
  ],

  // User engagement segments
  'engagement_segments': [
    {'segment': 'פעילים מאוד (5+ ביקורים/שבוע)', 'users': 1800, 'pct': 13, 'color': 'success'},
    {'segment': 'פעילים (2-4 ביקורים/שבוע)', 'users': 4200, 'pct': 30, 'color': 'turquoise'},
    {'segment': 'לפעמים (1 ביקור/שבוע)', 'users': 3800, 'pct': 27, 'color': 'gold'},
    {'segment': 'לא פעילים (< 1/שבוע)', 'users': 2900, 'pct': 20, 'color': 'grayLight'},
    {'segment': 'נטושים (30+ יום)', 'users': 1500, 'pct': 10, 'color': 'error'},
  ],

  // LTV estimate
  'avg_ltv': 42.5, // ILS per user
  'ltv_by_segment': {
    'power': 120.0,
    'active': 65.0,
    'casual': 28.0,
    'inactive': 8.0,
    'churned': 0.0,
  },

  // Push notification performance
  'push_stats': {
    'sent_this_month': 42000,
    'delivered_pct': 94.2,
    'opened_pct': 38.5,
    'clicked_pct': 12.8,
    'opt_out_pct': 2.1,
  },

  // Gamification stats
  'gamification': {
    'total_points_distributed': 2840000,
    'active_players': 4200,
    'avg_daily_points': 45,
    'steps_tracked_today': 18400000,
    'rewards_claimed': 234,
    'leaderboard_views': 890,
  },
};

// ─── Neighborhood Heatmap Data ───

final adminNeighborhoodHeatmapProvider = Provider<List<Map<String, dynamic>>>((ref) {
  return [
    {'name': 'אבני חן', 'lat': 31.9040, 'lng': 35.0090, 'users': 2400, 'businesses': 32, 'events_this_month': 8, 'avg_engagement': 4.2},
    {'name': 'בוכמן', 'lat': 31.8980, 'lng': 35.0150, 'users': 2100, 'businesses': 28, 'events_this_month': 5, 'avg_engagement': 3.8},
    {'name': 'מורשת', 'lat': 31.8920, 'lng': 35.0050, 'users': 1900, 'businesses': 22, 'events_this_month': 12, 'avg_engagement': 4.5},
    {'name': 'כפר האורנים', 'lat': 31.9100, 'lng': 34.9950, 'users': 1700, 'businesses': 18, 'events_this_month': 4, 'avg_engagement': 3.6},
    {'name': 'רמת הדר', 'lat': 31.8860, 'lng': 35.0200, 'users': 1400, 'businesses': 15, 'events_this_month': 3, 'avg_engagement': 3.4},
    {'name': 'רמת דניאל', 'lat': 31.8800, 'lng': 35.0100, 'users': 1200, 'businesses': 12, 'events_this_month': 2, 'avg_engagement': 3.2},
    {'name': 'שמשון', 'lat': 31.9150, 'lng': 35.0180, 'users': 1100, 'businesses': 10, 'events_this_month': 3, 'avg_engagement': 3.0},
    {'name': 'עמק שילה', 'lat': 31.9200, 'lng': 35.0250, 'users': 900, 'businesses': 8, 'events_this_month': 1, 'avg_engagement': 2.8},
  ];
});
