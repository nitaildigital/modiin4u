import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../providers/admin_analytics_provider.dart';
import '../admin_language.dart';

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
            tabs: [
              Tab(text: tr('נתוני מערכת', 'System data')),
              Tab(text: tr('ביצועי תוכן', 'Content performance')),
              Tab(text: tr('פרסום והכנסות', 'Advertising & revenue')),
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
          title: tr('נתוני מערכת', 'System data'),
          subtitle: tr('כל מספר כאן הוא ספירת שורות בטבלה, בזמן הטעינה.', 'Every number here is a count of rows in a table, at load time.'),
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
              _GroupHeading(tr('תוכן במערכת', 'Content in the system')),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatCard(
                    label: tr('כתבות', 'Articles'),
                    value: _int(c['articles']),
                    source: 'articles',
                    color: AppColors.turquoise,
                  ),
                  _StatCard(
                    label: tr('כתבות שפורסמו', 'Articles published'),
                    value: _int(c['articles_published']),
                    source: "articles · status = 'published'",
                    color: AppColors.success,
                  ),
                  _StatCard(
                    label: tr('טיוטות', 'Drafts'),
                    value: _int(c['articles_draft']),
                    source: "articles · status = 'draft'",
                    color: AppColors.gold,
                  ),
                  _StatCard(
                    label: tr('עסקים', 'Businesses'),
                    value: _int(c['businesses']),
                    source: 'businesses',
                    color: AppColors.midBlue,
                  ),
                  _StatCard(
                    label: tr('עסקים פעילים', 'Active businesses'),
                    value: _int(c['businesses_active']),
                    source: "businesses · status = 'active'",
                    color: AppColors.success,
                  ),
                  _StatCard(
                    label: tr('עסקים ממתינים', 'Pending businesses'),
                    value: _int(c['businesses_pending']),
                    source: "businesses · status = 'pending'",
                    color: AppColors.gold,
                  ),
                  _StatCard(
                    label: tr('אירועים', 'Events'),
                    value: _int(c['events']),
                    source: 'events',
                    color: AppColors.turquoise,
                  ),
                  _StatCard(
                    label: tr('אירועים עתידיים', 'Upcoming events'),
                    value: _int(c['events_upcoming']),
                    source: tr('events · start_date ≥ היום', 'events · start_date ≥ today'),
                    color: AppColors.midBlue,
                  ),
                  _StatCard(
                    label: tr('מודעות נדל״ן', 'Real estate listings'),
                    value: _int(c['listings']),
                    source: 'listings',
                    color: AppColors.navy,
                  ),
                  _StatCard(
                    label: tr('שכונות', 'Neighbourhoods'),
                    value: _int(c['neighborhoods']),
                    source: 'neighborhoods',
                    color: AppColors.navy,
                  ),
                  _StatCard(
                    label: tr('קטגוריות', 'Categories'),
                    value: _int(c['categories']),
                    source: 'categories',
                    color: AppColors.navy,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _GroupHeading(tr('תושבים רשומים', 'Registered residents')),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatCard(
                    label: tr('תושבים רשומים', 'Registered residents'),
                    value: _int(c['residents']),
                    source: 'profiles',
                    color: AppColors.turquoise,
                  ),
                  _StatCard(
                    label: tr('מאומתים', 'Verified'),
                    value: _int(c['residents_verified']),
                    source: 'profiles · is_verified',
                    color: AppColors.success,
                  ),
                  _StatCard(
                    label: tr('אישרו התראות', 'Allowed notifications'),
                    value: _int(c['residents_push_on']),
                    source: 'profiles · push_enabled',
                    color: AppColors.midBlue,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _GroupHeading(tr('מה שהתושבים הוסיפו', 'What residents added')),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatCard(
                    label: tr('ביקורות', 'Reviews'),
                    value: _int(c['reviews']),
                    source: 'reviews',
                    color: AppColors.gold,
                  ),
                  _StatCard(
                    label: tr('תגובות', 'Comments'),
                    value: _int(c['comments']),
                    source: 'comments',
                    color: AppColors.gold,
                  ),
                  _StatCard(
                    label: tr('שמירות למועדפים', 'Saves to favourites'),
                    value: _int(c['favorites']),
                    source: 'favorites',
                    color: AppColors.turquoise,
                  ),
                  _StatCard(
                    label: tr('מבצעים', 'Deals'),
                    value: _int(c['offers']),
                    source: 'offers',
                    color: AppColors.midBlue,
                  ),
                  _StatCard(
                    label: tr('מימושי מבצע', 'Deal redemptions'),
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
              ? _NoteCard(
                  title: tr('קצב פרסום', 'Publishing rate'),
                  lines: [
                    tr('אין כתבות עם תאריך פרסום, ולכן אין ממה לבנות את הגרף.', 'No articles with a publication date, so there is nothing to build the chart from.'),
                  ],
                )
              : _CardShell(
                  title:
                      tr('כתבות שפורסמו לחודש — ${months.length} החודשים האחרונים', 'Articles published per month — the last ${months.length} months'),
                  footnote:
                      tr('נספר מ-articles.published_at. זהו קצב הפרסום של '
                      'המערכת, ולא מדד לצפיות או למעורבות.', 'Counted from articles.published_at. This is the system\'s publishing rate, not a measure of views or engagement.'),
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

        _NoteCard(
          title: tr('מה עוד לא נמדד', 'What is not measured yet'),
          lines: [
            tr('הנתונים בעמוד זה נקראים ישירות מהטבלאות. למדידת התנהגות — סשנים, '
                'צפיות בעמודים, זמן שהייה ושימור — נדרשת שכבת מדידה שאינה '
                'קיימת: אין טבלת אנליטיקה במסד הנתונים, ואף מסך באפליקציה '
                'אינו כותב אירועי שימוש.', 'The data on this page is read directly from the tables. Measuring behaviour — sessions, page views, time on site and retention — needs a measurement layer that does not exist: there is no analytics table in the database, and no screen in the app writes usage events.'),
            tr('משתמשים פעילים כרגע, סשנים וצפיות בעמודים — דורשים טבלת אירועי '
                'שימוש, או חיבור ל-Google Analytics / Firebase.', 'Users active right now, sessions and page views — need a usage-events table, or a connection to Google Analytics / Firebase.'),
            tr('זמן שהייה ממוצע, Bounce Rate, מסכים לסשן ושימור (Retention) — '
                'נגזרים מאותם אירועים, ולכן תלויים באותו חיבור.', 'Average time on site, bounce rate, screens per session and retention — derived from the same events, so they depend on the same connection.'),
            tr('פילוח לפי מכשיר וגרסת אפליקציה — העמודות device_os ו-app_version '
                'קיימות ב-profiles אך ריקות; יתמלאו כשהאפליקציה תדווח עליהן '
                'בהתחברות.', 'Breakdown by device and app version — the device_os and app_version columns exist in profiles but are empty; they fill once the app reports them at sign-in.'),
            tr('מסירה ופתיחה של התראות Push — דורשות שליחה בפועל דרך Firebase '
                'ו-APNs ורישום מסירה. כרגע קמפיין נשמר ונכנס לתור אך אינו '
                'נשלח, ואין יומן שליחות.', 'Delivering and opening push notifications — needs actual sending through Firebase and APNs, and delivery logging. Right now a campaign is saved and queued but not sent, and there is no send log.'),
            tr('ערוצי רכישה, גיל ופילוח דמוגרפי — אין עמודות כאלה במסד הנתונים.', 'Acquisition channels, age and demographic breakdown — there are no such columns in the database.'),
            tr('הקלקות לטלפון, לוואטסאפ ולניווט בעמוד עסק, וכן חיפושים ושאילתות '
                'ללא תוצאות — דורשים רישום הקלקה וחיפוש; אין טבלאות כאלה.', 'Taps on phone, WhatsApp and navigation on a business page, and searches with no results — need click and search logging; there are no such tables.'),
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
            tr('${months[group.x]['month']}\n${rod.toY.toInt()} כתבות', '${months[group.x]['month']}\n${rod.toY.toInt()} articles'),
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
          title: tr('ביצועי תוכן', 'Content performance'),
          subtitle:
              tr('צפיות, שיתופים ושמירות הן העמודות שהטבלאות נושאות. '
              'הן מצטברות מאז הפרסום — אין בהן חלוקה לפי תאריך.', 'Views, shares and saves are the columns the tables carry. They accumulate since publication — there is no breakdown by date.'),
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
                    label: tr('צפיות בכתבות', 'Article views'),
                    value: r.articleViews,
                    source: tr('סכום articles.view_count', 'Sum of articles.view_count'),
                    color: AppColors.turquoise,
                  ),
                  _StatCard(
                    label: tr('שיתופי כתבות', 'Article shares'),
                    value: r.articleShares,
                    source: tr('סכום articles.share_count', 'Sum of articles.share_count'),
                    color: AppColors.gold,
                  ),
                  _StatCard(
                    label: tr('שמירות כתבות', 'Article saves'),
                    value: r.articleSaves,
                    source: tr('סכום articles.save_count', 'Sum of articles.save_count'),
                    color: AppColors.midBlue,
                  ),
                  _StatCard(
                    label: tr('צפיות באירועים', 'Event views'),
                    value: r.eventViews,
                    source: tr('סכום events.view_count', 'Sum of events.view_count'),
                    color: AppColors.turquoise,
                  ),
                  _StatCard(
                    label: tr('הרשמות לאירועים', 'Event registrations'),
                    value: r.eventRsvps,
                    source: tr('סכום events.rsvp_count', 'Sum of events.rsvp_count'),
                    color: AppColors.success,
                  ),
                  _StatCard(
                    label: tr('הוספות ליומן', 'Calendar adds'),
                    value: r.eventCalendarAdds,
                    source: tr('סכום events.calendar_adds', 'Sum of events.calendar_adds'),
                    color: AppColors.navy,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _CardShell(
                title: tr('הכתבות הנצפות ביותר', 'Most viewed articles'),
                footnote:
                    tr('${_fmtInt(r.articlesWithViews)} מתוך '
                    '${_fmtInt(r.articleTotal)} כתבות נושאות ספירת צפיות '
                    'שאינה אפס, ולכן זהו הדירוג של אותן כתבות בלבד.', '${_fmtInt(r.articlesWithViews)} of ${_fmtInt(r.articleTotal)} articles have a non-zero view count, so this ranks those articles only.'),
                child: r.articlesWithViews == 0
                    ? _InlineEmpty(
                        tr('אף כתבה לא נצפתה עדיין — כל הערכים בעמודה '
                        'view_count הם אפס.', 'No article has been viewed yet — every value in the view_count column is zero.'),
                      )
                    : _RankedTable(
                        headers: [tr('כתבה', 'Article'), tr('צפיות', 'Views'), tr('שיתופים', 'Shares'), tr('שמירות', 'Saves')],
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
                title: tr('האירועים הנצפים ביותר', 'Most viewed events'),
                footnote:
                    tr('${_fmtInt(r.eventsWithViews)} מתוך '
                    '${_fmtInt(r.eventTotal)} אירועים נושאים ספירת צפיות '
                    'שאינה אפס.', '${_fmtInt(r.eventsWithViews)} of ${_fmtInt(r.eventTotal)} events have a non-zero view count.'),
                child: r.eventsWithViews == 0
                    ? _InlineEmpty(
                        tr('אף אירוע לא נצפה עדיין — כל הערכים בעמודה '
                        'view_count הם אפס.', 'No event has been viewed yet — every value in the view_count column is zero.'),
                      )
                    : _RankedTable(
                        headers: [
                          tr('אירוע', 'Event'),
                          tr('צפיות', 'Views'),
                          tr('הרשמות', 'Registrations'),
                          tr('שיתופים', 'Shares'),
                          tr('יומן', 'Log'),
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
              title: tr('עסקים לפי קטגוריה', 'Businesses by category'),
              footnote:
                  tr('נספר מקישורי entity_categories עבור entity_type = '
                  "'business'. עסק יכול להיות משויך ליותר מקטגוריה אחת.", 'Counted from entity_categories links where entity_type = \'business\'. A business can be assigned to more than one category.'),
              child: b.byCategory.isEmpty
                  ? _InlineEmpty(tr('אין שיוכי קטגוריה לעסקים.', 'No businesses are assigned to categories.'))
                  : _BarList(
                      rows: b.byCategory,
                      largest: _largest(b.byCategory),
                      color: AppColors.turquoise,
                    ),
            );
            final neighborhoods = _CardShell(
              title: tr('עסקים לפי שכונה', 'Businesses by neighbourhood'),
              footnote:
                  tr('נספר מ-businesses.neighborhood_id. '
                  '${_fmtInt(b.withoutNeighborhood)} מתוך '
                  '${_fmtInt(b.businessTotal)} עסקים ללא שכונה, ולכן אינם '
                  'מופיעים בפילוח.', 'Counted from businesses.neighborhood_id. ${_fmtInt(b.withoutNeighborhood)} of ${_fmtInt(b.businessTotal)} businesses have no neighbourhood, so they do not appear in the breakdown.'),
              child: b.byNeighborhood.isEmpty
                  ? _InlineEmpty(tr('אף עסק אינו משויך לשכונה.', 'No business is assigned to a neighbourhood.'))
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
  static Map<String, String> get _revenueTypes => {
    'subscription': tr('מנויים', 'Subscriptions'),
    'banner': tr('באנרים', 'Banners'),
    'push': tr('התראות ממומנות', 'Sponsored notifications'),
    'featured': tr('עסק מקודם', 'Promoted business'),
    'sponsored': tr('תוכן ממומן', 'Sponsored content'),
    'custom': tr('אחר', 'Other'),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaigns = ref.watch(adminCampaignPerformanceProvider);
    final revenue = ref.watch(adminRevenueSummaryProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _TabHeader(
          title: tr('פרסום והכנסות', 'Advertising & revenue'),
          subtitle:
              tr('סכומי העמודות בטבלאות campaigns ו-revenue_transactions, '
              'כפי שהן כרגע.', 'Column totals in the campaigns and revenue_transactions tables, as they are now.'),
          onRefresh: () {
            ref.invalidate(adminCampaignPerformanceProvider);
            ref.invalidate(adminRevenueSummaryProvider);
          },
        ),
        const SizedBox(height: 20),

        _GroupHeading(tr('קמפיינים', 'Campaigns')),
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
                    label: tr('קמפיינים', 'Campaigns'),
                    value: c.campaigns,
                    source: 'campaigns',
                    color: AppColors.midBlue,
                  ),
                  _StatCard(
                    label: tr('קמפיינים פעילים', 'Active campaigns'),
                    value: c.byStatus['active'] ?? 0,
                    source: "campaigns · status = 'active'",
                    color: AppColors.success,
                  ),
                  _StatCard(
                    label: tr('חשיפות', 'Impressions'),
                    value: c.impressions,
                    source: tr('סכום impressions', 'Sum of impressions'),
                    color: AppColors.turquoise,
                  ),
                  _StatCard(
                    label: tr('חשיפות ייחודיות', 'Unique impressions'),
                    value: c.uniqueImpressions,
                    source: tr('סכום unique_impressions', 'Sum of unique_impressions'),
                    color: AppColors.turquoise,
                  ),
                  _StatCard(
                    label: tr('הקלקות', 'Clicks'),
                    value: c.clicks,
                    source: tr('סכום clicks', 'Sum of clicks'),
                    color: AppColors.gold,
                  ),
                  _StatCard(
                    label: tr('המרות', 'Conversions'),
                    value: c.conversions,
                    source: tr('סכום conversions', 'Sum of conversions'),
                    color: AppColors.success,
                  ),
                  // A rate over zero impressions is unknown, not zero per
                  // cent, so it is shown as a dash.
                  _StatCard.text(
                    label: 'CTR',
                    text: c.ctr == null ? '—' : '${c.ctr!.toStringAsFixed(2)}%',
                    source: c.ctr == null
                        ? tr('אין חשיפות, ולכן אין יחס להציג', 'No impressions, so there is no ratio to show')
                        : 'clicks ÷ impressions',
                    color: AppColors.navy,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _CardShell(
                title: tr('קמפיינים לפי מיקום פרסום', 'Campaigns by ad placement'),
                footnote: c.impressions == 0
                    ? tr('עמודות impressions ו-clicks בטבלת campaigns מתעדכנות '
                          'רק על ידי מערכת הגשה שמדווחת חשיפה והקלקה. אין '
                          'כרגע מי שיכתוב אליהן, ולכן הן אפס — אלה אינם '
                          'ביצועים חלשים אלא מדידה שטרם חוברה.', 'The impressions and clicks columns in the campaigns table are updated only by an ad server that reports impressions and clicks. Nothing writes to them yet, so they are zero — this is not weak performance but measurement that is not connected yet.')
                    : tr('נספר מ-campaigns.placement_id מול ad_placements.', 'Counted from campaigns.placement_id against ad_placements.'),
                child: c.placements.isEmpty
                    ? _InlineEmpty(tr('אין מיקומי פרסום מוגדרים.', 'No ad placements defined.'))
                    : _RankedTable(
                        headers: [tr('מיקום', 'Location'), tr('קמפיינים', 'Campaigns')],
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

        _GroupHeading(tr('הכנסות', 'Revenue')),
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
                    label: tr('סך הכל רשום', 'Total registered'),
                    text: _fmtMoney(r.total),
                    source: tr('סכום revenue_transactions · amount', 'Sum of revenue_transactions · amount'),
                    color: AppColors.navy,
                  ),
                  _StatCard.text(
                    label: tr('שולם', 'Paid'),
                    text: _fmtMoney(r.paid),
                    source: "payment_status = 'paid'",
                    color: AppColors.success,
                  ),
                  _StatCard.text(
                    label: tr('לתשלום', 'Payable'),
                    text: _fmtMoney(r.outstanding),
                    source: 'pending · partial · overdue',
                    color: AppColors.gold,
                  ),
                  _StatCard.text(
                    label: tr('נרשם החודש', 'Registered this month'),
                    text: _fmtMoney(r.thisMonth),
                    source: tr('created_at בחודש הנוכחי', 'created_at in the current month'),
                    color: AppColors.turquoise,
                  ),
                  _StatCard(
                    label: tr('תנועות', 'Transactions'),
                    value: r.transactions,
                    source: 'revenue_transactions',
                    color: AppColors.midBlue,
                  ),
                  _StatCard(
                    label: tr('מנויים פעילים', 'Active subscriptions'),
                    value: r.activeSubscriptions,
                    source: "subscriptions · status = 'active'",
                    color: AppColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _CardShell(
                title: tr('הכנסות לפי סוג', 'Revenue by type'),
                footnote: r.transactions == 0
                    ? tr('אין תנועות הכנסה במסד הנתונים. הן נוצרות במדור '
                          '"הכנסות" בתפריט הצד, ומשם יתמלא הפילוח הזה.', 'No revenue entries in the database. They are created in the "Revenue" section of the side menu, and this breakdown fills from there.')
                    : tr('נספר מ-revenue_transactions.revenue_type.', 'Counted from revenue_transactions.revenue_type.'),
                child: r.byType.isEmpty
                    ? _InlineEmpty(
                        tr('טרם נרשמה תנועת הכנסה אחת — הסכום הוא אפס, ולא '
                        'אומדן.', 'No revenue entry has been recorded yet — the total is zero, not an estimate.'),
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
            tr('רענן', 'Refresh'),
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
            tr('לא הצלחנו לקרוא את הנתונים', 'We could not read the data'),
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
