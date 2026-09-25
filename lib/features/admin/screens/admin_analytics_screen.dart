import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../providers/admin_analytics_provider.dart';

/// The Analytics section, on what the database can actually be asked.
///
/// This screen had five tabs and roughly a hundred figures, and every one of
/// them was invented — see the note at the top of `admin_analytics_provider`
/// for the list. It had a Refresh button wired to a random generator, so the
/// numbers moved when it was pressed and read as live, and a map of
/// twenty-five dots labelled as the people using the app right now.
///
/// Three tabs remain. Each figure on them is a row count, a sum of a column
/// the schema actually carries, or nothing at all: where there is no source,
/// the panel says which source it would need instead of estimating. Every
/// card carries the table and column it came from underneath it, so the client
/// can check any number against the data.
class AdminAnalyticsScreen extends ConsumerStatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  ConsumerState<AdminAnalyticsScreen> createState() =>
      _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends ConsumerState<AdminAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: AppColors.adminCardBorder, width: 1),
            ),
          ),
          child: TabBar(
            controller: _tabs,
            isScrollable: true,
            labelStyle: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            unselectedLabelStyle: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            labelColor: AppColors.midBlue,
            unselectedLabelColor: AppColors.adminTextLight,
            indicatorColor: AppColors.midBlue,
            indicatorWeight: 2.5,
            labelPadding: const EdgeInsets.symmetric(horizontal: 20),
            tabs: const [
              Tab(text: 'נתוני מערכת'),
              Tab(text: 'ביצועי תוכן'),
              Tab(text: 'פרסום והכנסות'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: const [
              _SystemDataTab(),
              _ContentTab(),
              _AdvertisingTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════
// TAB 1 — WHAT THE DATABASE HOLDS
// ══════════════════════════════════════════════

class _SystemDataTab extends ConsumerWidget {
  const _SystemDataTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(adminRowCountsProvider);
    final cadence = ref.watch(adminPublishingCadenceProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _TabHeader(
          title: 'נתוני מערכת',
          subtitle: 'כל מספר כאן הוא ספירת שורות בטבלה, בזמן הטעינה.',
          onRefresh: () {
            ref.invalidate(adminRowCountsProvider);
            ref.invalidate(adminPublishingCadenceProvider);
          },
        ),
        const SizedBox(height: 20),

        counts.when(
          loading: () => const _LoadingPanel(),
          error: (e, _) => _ErrorPanel(error: e),
          data: (c) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _GroupHeading('תוכן במערכת'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatCard(
                    label: 'כתבות',
                    value: _int(c['articles']),
                    source: 'articles',
                    color: AppColors.turquoise,
                  ),
                  _StatCard(
                    label: 'כתבות שפורסמו',
                    value: _int(c['articles_published']),
                    source: "articles · status = 'published'",
                    color: AppColors.success,
                  ),
                  _StatCard(
                    label: 'טיוטות',
                    value: _int(c['articles_draft']),
                    source: "articles · status = 'draft'",
                    color: AppColors.gold,
                  ),
                  _StatCard(
                    label: 'עסקים',
                    value: _int(c['businesses']),
                    source: 'businesses',
                    color: AppColors.midBlue,
                  ),
                  _StatCard(
                    label: 'עסקים פעילים',
                    value: _int(c['businesses_active']),
                    source: "businesses · status = 'active'",
                    color: AppColors.success,
                  ),
                  _StatCard(
                    label: 'עסקים ממתינים',
                    value: _int(c['businesses_pending']),
                    source: "businesses · status = 'pending'",
                    color: AppColors.gold,
                  ),
                  _StatCard(
                    label: 'אירועים',
                    value: _int(c['events']),
                    source: 'events',
                    color: AppColors.turquoise,
                  ),
                  _StatCard(
                    label: 'אירועים עתידיים',
                    value: _int(c['events_upcoming']),
                    source: 'events · start_date ≥ היום',
                    color: AppColors.midBlue,
                  ),
                  _StatCard(
                    label: 'מודעות נדל״ן',
                    value: _int(c['listings']),
                    source: 'listings',
                    color: AppColors.navy,
                  ),
                  _StatCard(
                    label: 'שכונות',
                    value: _int(c['neighborhoods']),
                    source: 'neighborhoods',
                    color: AppColors.navy,
                  ),
                  _StatCard(
                    label: 'קטגוריות',
                    value: _int(c['categories']),
                    source: 'categories',
                    color: AppColors.navy,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const _GroupHeading('תושבים רשומים'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatCard(
                    label: 'תושבים רשומים',
                    value: _int(c['residents']),
                    source: 'profiles',
                    color: AppColors.turquoise,
                  ),
                  _StatCard(
                    label: 'מאומתים',
                    value: _int(c['residents_verified']),
                    source: 'profiles · is_verified',
                    color: AppColors.success,
                  ),
                  _StatCard(
                    label: 'אישרו התראות',
                    value: _int(c['residents_push_on']),
                    source: 'profiles · push_enabled',
                    color: AppColors.midBlue,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const _GroupHeading('מה שהתושבים הוסיפו'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatCard(
                    label: 'ביקורות',
                    value: _int(c['reviews']),
                    source: 'reviews',
                    color: AppColors.gold,
                  ),
                  _StatCard(
                    label: 'תגובות',
                    value: _int(c['comments']),
                    source: 'comments',
                    color: AppColors.gold,
                  ),
                  _StatCard(
                    label: 'שמירות למועדפים',
                    value: _int(c['favorites']),
                    source: 'favorites',
                    color: AppColors.turquoise,
                  ),
                  _StatCard(
                    label: 'מבצעים',
                    value: _int(c['offers']),
                    source: 'offers',
                    color: AppColors.midBlue,
                  ),
                  _StatCard(
                    label: 'מימושי מבצע',
                    value: _int(c['offer_claims']),
                    source: 'offer_claims',
                    color: AppColors.midBlue,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        cadence.when(
          loading: () => const _LoadingPanel(),
          error: (e, _) => _ErrorPanel(error: e),
          data: (months) => months.isEmpty
              ? const _NoteCard(
                  title: 'קצב פרסום',
                  lines: [
                    'אין כתבות עם תאריך פרסום, ולכן אין ממה לבנות את הגרף.',
                  ],
                )
              : _CardShell(
                  title:
                      'כתבות שפורסמו לחודש — ${months.length} החודשים האחרונים',
                  footnote:
                      'נספר מ-articles.published_at. זהו קצב הפרסום של '
                      'המערכת, ולא מדד לצפיות או למעורבות.',
                  child: SizedBox(
                    height: 240,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(
                        top: 16,
                        end: 16,
                        start: 8,
                        bottom: 4,
                      ),
                      child: BarChart(_cadenceChart(months)),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 24),

        const _NoteCard(
          title: 'מה עוד לא נמדד',
          lines: [
            'הנתונים בעמוד זה נקראים ישירות מהטבלאות. למדידת התנהגות — סשנים, '
                'צפיות בעמודים, זמן שהייה ושימור — נדרשת שכבת מדידה שאינה '
                'קיימת: אין טבלת אנליטיקה במסד הנתונים, ואף מסך באפליקציה '
                'אינו כותב אירועי שימוש.',
            'משתמשים פעילים כרגע, סשנים וצפיות בעמודים — דורשים טבלת אירועי '
                'שימוש, או חיבור ל-Google Analytics / Firebase.',
            'זמן שהייה ממוצע, Bounce Rate, מסכים לסשן ושימור (Retention) — '
                'נגזרים מאותם אירועים, ולכן תלויים באותו חיבור.',
            'פילוח לפי מכשיר וגרסת אפליקציה — העמודות device_os ו-app_version '
                'קיימות ב-profiles אך ריקות; יתמלאו כשהאפליקציה תדווח עליהן '
                'בהתחברות.',
            'מסירה ופתיחה של התראות Push — דורשות שליחה בפועל דרך Firebase '
                'ו-APNs ורישום מסירה. כרגע קמפיין נשמר ונכנס לתור אך אינו '
                'נשלח, ואין יומן שליחות.',
            'ערוצי רכישה, גיל ופילוח דמוגרפי — אין עמודות כאלה במסד הנתונים.',
            'הקלקות לטלפון, לוואטסאפ ולניווט בעמוד עסק, וכן חיפושים ושאילתות '
                'ללא תוצאות — דורשים רישום הקלקה וחיפוש; אין טבלאות כאלה.',
          ],
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  BarChartData _cadenceChart(List<Map<String, dynamic>> months) {
    final maxCount = months.fold<int>(
      0,
      (m, r) => (r['count'] as int) > m ? r['count'] as int : m,
    );
    // A round step keeps the grid lines and the left labels on the same
    // values whatever the tallest month happens to be.
    final step = maxCount <= 10
        ? 2.0
        : maxCount <= 30
        ? 10.0
        : 20.0;

    return BarChartData(
      maxY: ((maxCount / step).ceil() + 1) * step,
      barGroups: [
        for (final e in months.asMap().entries)
          BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: (e.value['count'] as int).toDouble(),
                color: AppColors.turquoise,
                width: 22,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          ),
      ],
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(),
        topTitles: const AxisTitles(),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            interval: step,
            getTitlesWidget: (v, _) => Text(
              '${v.toInt()}',
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 10,
                color: AppColors.adminTextLight,
              ),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 26,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= months.length) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  months[i]['month'] as String,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 10,
                    color: AppColors.adminTextLight,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: step,
        getDrawingHorizontalLine: (_) =>
            const FlLine(color: AppColors.adminCardBorder, strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
            '${months[group.x]['month']}\n${rod.toY.toInt()} כתבות',
            TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 12,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// TAB 2 — CONTENT REACH
// ══════════════════════════════════════════════

class _ContentTab extends ConsumerWidget {
  const _ContentTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reach = ref.watch(adminContentReachProvider);
    final catalogue = ref.watch(adminCatalogueBreakdownProvider);
    final isWide = MediaQuery.of(context).size.width > 1100;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _TabHeader(
          title: 'ביצועי תוכן',
          subtitle:
              'צפיות, שיתופים ושמירות הן העמודות שהטבלאות נושאות. '
              'הן מצטברות מאז הפרסום — אין בהן חלוקה לפי תאריך.',
          onRefresh: () {
            ref.invalidate(adminContentReachProvider);
            ref.invalidate(adminCatalogueBreakdownProvider);
          },
        ),
        const SizedBox(height: 20),

        reach.when(
          loading: () => const _LoadingPanel(),
          error: (e, _) => _ErrorPanel(error: e),
          data: (r) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatCard(
                    label: 'צפיות בכתבות',
                    value: r.articleViews,
                    source: 'סכום articles.view_count',
                    color: AppColors.turquoise,
                  ),
                  _StatCard(
                    label: 'שיתופי כתבות',
                    value: r.articleShares,
                    source: 'סכום articles.share_count',
                    color: AppColors.gold,
                  ),
                  _StatCard(
                    label: 'שמירות כתבות',
                    value: r.articleSaves,
                    source: 'סכום articles.save_count',
                    color: AppColors.midBlue,
                  ),
                  _StatCard(
                    label: 'צפיות באירועים',
                    value: r.eventViews,
                    source: 'סכום events.view_count',
                    color: AppColors.turquoise,
                  ),
                  _StatCard(
                    label: 'הרשמות לאירועים',
                    value: r.eventRsvps,
                    source: 'סכום events.rsvp_count',
                    color: AppColors.success,
                  ),
                  _StatCard(
                    label: 'הוספות ליומן',
                    value: r.eventCalendarAdds,
                    source: 'סכום events.calendar_adds',
                    color: AppColors.navy,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _CardShell(
                title: 'הכתבות הנצפות ביותר',
                footnote:
                    '${_fmtInt(r.articlesWithViews)} מתוך '
                    '${_fmtInt(r.articleTotal)} כתבות נושאות ספירת צפיות '
                    'שאינה אפס, ולכן זהו הדירוג של אותן כתבות בלבד.',
                child: r.articlesWithViews == 0
                    ? const _InlineEmpty(
                        'אף כתבה לא נצפתה עדיין — כל הערכים בעמודה '
                        'view_count הם אפס.',
                      )
                    : _RankedTable(
                        headers: const ['כתבה', 'צפיות', 'שיתופים', 'שמירות'],
                        rows: [
                          for (final a in r.topArticles)
                            if (((a['view_count'] as num?) ?? 0) > 0)
                              [
                                a['title'] as String? ?? '',
                                _fmtInt(_int(a['view_count'])),
                                _fmtInt(_int(a['share_count'])),
                                _fmtInt(_int(a['save_count'])),
                              ],
                        ],
                      ),
              ),
              const SizedBox(height: 16),

              _CardShell(
                title: 'האירועים הנצפים ביותר',
                footnote:
                    '${_fmtInt(r.eventsWithViews)} מתוך '
                    '${_fmtInt(r.eventTotal)} אירועים נושאים ספירת צפיות '
                    'שאינה אפס.',
                child: r.eventsWithViews == 0
                    ? const _InlineEmpty(
                        'אף אירוע לא נצפה עדיין — כל הערכים בעמודה '
                        'view_count הם אפס.',
                      )
                    : _RankedTable(
                        headers: const [
                          'אירוע',
                          'צפיות',
                          'הרשמות',
                          'שיתופים',
                          'יומן',
                        ],
                        rows: [
                          for (final e in r.topEvents)
                            if (((e['view_count'] as num?) ?? 0) > 0)
                              [
                                e['title'] as String? ?? '',
                                _fmtInt(_int(e['view_count'])),
                                _fmtInt(_int(e['rsvp_count'])),
                                _fmtInt(_int(e['share_count'])),
                                _fmtInt(_int(e['calendar_adds'])),
                              ],
                        ],
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        catalogue.when(
          loading: () => const _LoadingPanel(),
          error: (e, _) => _ErrorPanel(error: e),
          data: (b) {
            final categories = _CardShell(
              title: 'עסקים לפי קטגוריה',
              footnote:
                  'נספר מקישורי entity_categories עבור entity_type = '
                  "'business'. עסק יכול להיות משויך ליותר מקטגוריה אחת.",
              child: b.byCategory.isEmpty
                  ? const _InlineEmpty('אין שיוכי קטגוריה לעסקים.')
                  : _BarList(
                      rows: b.byCategory,
                      largest: _largest(b.byCategory),
                      color: AppColors.turquoise,
                    ),
            );
            final neighborhoods = _CardShell(
              title: 'עסקים לפי שכונה',
              footnote:
                  'נספר מ-businesses.neighborhood_id. '
                  '${_fmtInt(b.withoutNeighborhood)} מתוך '
                  '${_fmtInt(b.businessTotal)} עסקים ללא שכונה, ולכן אינם '
                  'מופיעים בפילוח.',
              child: b.byNeighborhood.isEmpty
                  ? const _InlineEmpty('אף עסק אינו משויך לשכונה.')
                  : _BarList(
                      rows: b.byNeighborhood,
                      largest: _largest(b.byNeighborhood),
                      color: AppColors.midBlue,
                    ),
            );

            if (!isWide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  categories,
                  const SizedBox(height: 16),
                  neighborhoods,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: categories),
                const SizedBox(width: 16),
                Expanded(child: neighborhoods),
              ],
            );
          },
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}

// ══════════════════════════════════════════════
// TAB 3 — ADVERTISING & REVENUE
// ══════════════════════════════════════════════

class _AdvertisingTab extends ConsumerWidget {
  const _AdvertisingTab();

  /// The `revenue_type` values the commerce migration defines, in Hebrew.
  static const _revenueTypes = {
    'subscription': 'מנויים',
    'banner': 'באנרים',
    'push': 'התראות ממומנות',
    'featured': 'עסק מקודם',
    'sponsored': 'תוכן ממומן',
    'custom': 'אחר',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaigns = ref.watch(adminCampaignPerformanceProvider);
    final revenue = ref.watch(adminRevenueSummaryProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _TabHeader(
          title: 'פרסום והכנסות',
          subtitle:
              'סכומי העמודות בטבלאות campaigns ו-revenue_transactions, '
              'כפי שהן כרגע.',
          onRefresh: () {
            ref.invalidate(adminCampaignPerformanceProvider);
            ref.invalidate(adminRevenueSummaryProvider);
          },
        ),
        const SizedBox(height: 20),

        const _GroupHeading('קמפיינים'),
        const SizedBox(height: 10),
        campaigns.when(
          loading: () => const _LoadingPanel(),
          error: (e, _) => _ErrorPanel(error: e),
          data: (c) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatCard(
                    label: 'קמפיינים',
                    value: c.campaigns,
                    source: 'campaigns',
                    color: AppColors.midBlue,
                  ),
                  _StatCard(
                    label: 'קמפיינים פעילים',
                    value: c.byStatus['active'] ?? 0,
                    source: "campaigns · status = 'active'",
                    color: AppColors.success,
                  ),
                  _StatCard(
                    label: 'חשיפות',
                    value: c.impressions,
                    source: 'סכום impressions',
                    color: AppColors.turquoise,
                  ),
                  _StatCard(
                    label: 'חשיפות ייחודיות',
                    value: c.uniqueImpressions,
                    source: 'סכום unique_impressions',
                    color: AppColors.turquoise,
                  ),
                  _StatCard(
                    label: 'הקלקות',
                    value: c.clicks,
                    source: 'סכום clicks',
                    color: AppColors.gold,
                  ),
                  _StatCard(
                    label: 'המרות',
                    value: c.conversions,
                    source: 'סכום conversions',
                    color: AppColors.success,
                  ),
                  // A rate over zero impressions is unknown, not zero per
                  // cent, so it is shown as a dash.
                  _StatCard.text(
                    label: 'CTR',
                    text: c.ctr == null ? '—' : '${c.ctr!.toStringAsFixed(2)}%',
                    source: c.ctr == null
                        ? 'אין חשיפות, ולכן אין יחס להציג'
                        : 'clicks ÷ impressions',
                    color: AppColors.navy,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _CardShell(
                title: 'קמפיינים לפי מיקום פרסום',
                footnote: c.impressions == 0
                    ? 'עמודות impressions ו-clicks בטבלת campaigns מתעדכנות '
                          'רק על ידי מערכת הגשה שמדווחת חשיפה והקלקה. אין '
                          'כרגע מי שיכתוב אליהן, ולכן הן אפס — אלה אינם '
                          'ביצועים חלשים אלא מדידה שטרם חוברה.'
                    : 'נספר מ-campaigns.placement_id מול ad_placements.',
                child: c.placements.isEmpty
                    ? const _InlineEmpty('אין מיקומי פרסום מוגדרים.')
                    : _RankedTable(
                        headers: const ['מיקום', 'קמפיינים'],
                        rows: [
                          for (final p in c.placements)
                            [
                              p['label'] as String,
                              _fmtInt(_int(p['campaigns'])),
                            ],
                        ],
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        const _GroupHeading('הכנסות'),
        const SizedBox(height: 10),
        revenue.when(
          loading: () => const _LoadingPanel(),
          error: (e, _) => _ErrorPanel(error: e),
          data: (r) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatCard.text(
                    label: 'סך הכל רשום',
                    text: _fmtMoney(r.total),
                    source: 'סכום revenue_transactions · amount',
                    color: AppColors.navy,
                  ),
                  _StatCard.text(
                    label: 'שולם',
                    text: _fmtMoney(r.paid),
                    source: "payment_status = 'paid'",
                    color: AppColors.success,
                  ),
                  _StatCard.text(
                    label: 'לתשלום',
                    text: _fmtMoney(r.outstanding),
                    source: 'pending · partial · overdue',
                    color: AppColors.gold,
                  ),
                  _StatCard.text(
                    label: 'נרשם החודש',
                    text: _fmtMoney(r.thisMonth),
                    source: 'created_at בחודש הנוכחי',
                    color: AppColors.turquoise,
                  ),
                  _StatCard(
                    label: 'תנועות',
                    value: r.transactions,
                    source: 'revenue_transactions',
                    color: AppColors.midBlue,
                  ),
                  _StatCard(
                    label: 'מנויים פעילים',
                    value: r.activeSubscriptions,
                    source: "subscriptions · status = 'active'",
                    color: AppColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _CardShell(
                title: 'הכנסות לפי סוג',
                footnote: r.transactions == 0
                    ? 'אין תנועות הכנסה במסד הנתונים. הן נוצרות במדור '
                          '"הכנסות" בתפריט הצד, ומשם יתמלא הפילוח הזה.'
                    : 'נספר מ-revenue_transactions.revenue_type.',
                child: r.byType.isEmpty
                    ? const _InlineEmpty(
                        'טרם נרשמה תנועת הכנסה אחת — הסכום הוא אפס, ולא '
                        'אומדן.',
                      )
                    : Column(
                        children: [
                          for (final t in r.byType)
                            _StatRow(
                              label:
                                  _revenueTypes[t['type'] as String] ??
                                  t['type'] as String,
                              value: _fmtMoney(t['amount'] as double),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}

// ══════════════════════════════════════════════
// SHARED WIDGETS
// ══════════════════════════════════════════════

/// A tab's title, the one line that says where its numbers come from, and the
/// Refresh button.
///
/// Refresh used to regenerate random figures. It now invalidates the tab's
/// providers, so pressing it re-reads the tables.
class _TabHeader extends StatelessWidget {
  final String title, subtitle;
  final VoidCallback onRefresh;
  const _TabHeader({
    required this.title,
    required this.subtitle,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.adminTextLight,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        TextButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh, size: 18),
          label: Text(
            'רענן',
            style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _GroupHeading extends StatelessWidget {
  final String text;
  const _GroupHeading(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppFonts.rubik,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.adminTextMedium,
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  final String title;
  final Widget child;

  /// The line under the card that names the column the figures came from, or
  /// explains why they are what they are. Every panel on this screen carries
  /// one: it is what lets the client check a number rather than trust it.
  final String? footnote;

  const _CardShell({required this.title, required this.child, this.footnote});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.adminCardBorder, width: 1),
        boxShadow: const [BoxShadow(color: Color(0x0DB8B8B8), blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Text(
              title,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.adminTextDark,
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.adminCardBorder),
          child,
          if (footnote != null) ...[
            const Divider(height: 1, color: AppColors.adminCardBorder),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                footnote!,
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  fontSize: 12,
                  height: 1.6,
                  color: AppColors.adminTextLight,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One counted figure, with the table and column it was counted from.
class _StatCard extends StatelessWidget {
  final String label, source;
  final String text;
  final Color color;

  _StatCard({
    required this.label,
    required int value,
    required this.source,
    required this.color,
  }) : text = _fmtInt(value);

  /// For a figure that is not a plain count — a sum of money, a rate, or a
  /// dash where there is nothing to divide.
  const _StatCard.text({
    required this.label,
    required this.text,
    required this.source,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      // Fixed, so that a source line long enough to take two lines does not
      // make its card taller than the ones beside it in the same row.
      height: 136,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.adminCardBorder, width: 1),
        boxShadow: const [BoxShadow(color: Color(0x0DB8B8B8), blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 12,
                    color: AppColors.adminTextLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.adminTextDark,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              source,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 11,
                height: 1.4,
                color: AppColors.adminTextLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankedTable extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> rows;
  const _RankedTable({required this.headers, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: AppColors.surfaceLight,
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  '#',
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grayLight,
                  ),
                ),
              ),
              ...headers.asMap().entries.map(
                (e) => Expanded(
                  flex: e.key == 0 ? 3 : 1,
                  child: Text(
                    e.value,
                    style: TextStyle(
                      fontFamily: AppFonts.rubik,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grayLight,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        ...rows.asMap().entries.map(
          (e) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    '${e.key + 1}',
                    style: TextStyle(
                      fontFamily: AppFonts.rubik,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: e.key < 3 ? AppColors.gold : AppColors.grayLight,
                    ),
                  ),
                ),
                ...e.value.asMap().entries.map(
                  (c) => Expanded(
                    flex: c.key == 0 ? 3 : 1,
                    child: Text(
                      c.value,
                      style: TextStyle(
                        fontFamily: AppFonts.rubik,
                        fontSize: 12,
                        fontWeight: c.key == 0
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: c.key == 0 ? AppColors.navy : AppColors.grayText,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A ranked list of `name` / `count` rows, drawn as bars against the largest.
///
/// The bars are proportions of the biggest row, not percentages of a whole:
/// a business can sit in more than one category, so the counts do not add up
/// to the catalogue and a percentage would be wrong.
class _BarList extends StatelessWidget {
  final List<Map<String, dynamic>> rows;

  /// The largest count in [rows], which every bar is drawn against.
  final int largest;

  final Color color;
  const _BarList({
    required this.rows,
    required this.largest,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child: Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      r['name'] as String,
                      style: TextStyle(
                        fontFamily: AppFonts.rubik,
                        fontSize: 12,
                        color: AppColors.navy,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: largest == 0 ? 0 : (r['count'] as int) / largest,
                        minHeight: 14,
                        backgroundColor: AppColors.surfaceLight,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 44,
                    child: Text(
                      _fmtInt(_int(r['count'])),
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.adminTextDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label, value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }
}

/// A calm panel for a figure the app has no source for.
///
/// It exists so that a section with nothing to draw reads as "this needs
/// connecting" rather than as broken, and so that nobody is tempted to fill
/// the space back in.
class _NoteCard extends StatelessWidget {
  final String title;
  final List<String> lines;
  const _NoteCard({required this.title, required this.lines});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.adminCardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color: AppColors.adminTextMedium,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.adminTextDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                line,
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  fontSize: 13,
                  height: 1.7,
                  color: AppColors.adminTextMedium,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The body of a panel whose table is empty, in place of an empty frame.
class _InlineEmpty extends StatelessWidget {
  final String message;
  const _InlineEmpty(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Text(
        message,
        style: TextStyle(
          fontFamily: AppFonts.rubik,
          fontSize: 13,
          height: 1.6,
          color: AppColors.adminTextLight,
        ),
      ),
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  final Object error;
  const _ErrorPanel({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'לא הצלחנו לקרוא את הנתונים',
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$error',
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontSize: 12,
              height: 1.6,
              color: AppColors.adminTextMedium,
            ),
          ),
        ],
      ),
    );
  }
}

int _int(Object? value) => (value as num?)?.toInt() ?? 0;

/// The biggest `count` in a ranked list, which the bars are drawn against.
int _largest(List<Map<String, dynamic>> rows) =>
    rows.fold<int>(0, (m, r) => _int(r['count']) > m ? _int(r['count']) : m);

/// Grouped by thousands rather than shortened to "0.7K": the point of this
/// screen is that a figure can be checked against the table, and 669 reads
/// as a count in a way that 0.7K does not.
String _fmtInt(int n) {
  final digits = n.abs().toString();
  final out = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}

String _fmtMoney(double amount) => '₪${_fmtInt(amount.round())}';
