import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/admin_analytics_provider.dart';

/// Enhanced analytics overview — replaces the basic _OverviewSection.
/// Covers: Real-time, DAU/WAU/MAU, retention, content performance,
/// ad revenue, user demographics, search analytics, push stats.
class AdminAnalyticsScreen extends ConsumerStatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  ConsumerState<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends ConsumerState<AdminAnalyticsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        color: AppColors.surfaceLight,
        child: TabBar(
          controller: _tabs,
          isScrollable: true,
          labelStyle: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.rubik(fontSize: 13),
          labelColor: AppColors.turquoise,
          unselectedLabelColor: AppColors.grayText,
          indicatorColor: AppColors.turquoise,
          tabs: const [
            Tab(text: 'זמן אמת'),
            Tab(text: 'משתמשים ומעורבות'),
            Tab(text: 'ביצועי תוכן'),
            Tab(text: 'פרסום והכנסות'),
            Tab(text: 'דמוגרפיה'),
          ],
        ),
      ),
      Expanded(
        child: TabBarView(
          controller: _tabs,
          children: [
            _RealTimeTab(),
            _EngagementTab(),
            _ContentTab(),
            _RevenueTab(),
            _DemographicsTab(),
          ],
        ),
      ),
    ]);
  }
}

// ══════════════════════════════════════════════
// TAB 1 — REAL-TIME
// ══════════════════════════════════════════════

class _RealTimeTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rt = ref.watch(adminRealTimeProvider);
    final isWide = MediaQuery.of(context).size.width > 900;
    final activeNow = rt['active_now'] as int;
    final sessionsToday = rt['sessions_today'] as int;
    final pageViews = rt['page_views_today'] as int;
    final bounceRate = rt['bounce_rate_pct'] as int;
    final searches = rt['searches_today'] as int;
    final shares = rt['shares_today'] as int;
    final newUsers = rt['new_users_today'] as int;
    final errors = rt['errors_today'] as int;
    final apiLatency = rt['api_latency_ms'] as int;
    final liveUsers = rt['live_users'] as List<dynamic>;
    final notiSent = rt['notifications_sent_today'] as int;
    final notiOpened = rt['notifications_opened'] as int;

    return ListView(padding: const EdgeInsets.all(20), children: [
      // Header with refresh
      Row(children: [
        Text('פעילות בזמן אמת', style: GoogleFonts.rubik(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.navy)),
        const Spacer(),
        TextButton.icon(
          onPressed: () => ref.read(adminRealTimeProvider.notifier).refresh(),
          icon: const Icon(Icons.refresh, size: 18),
          label: Text('רענן', style: GoogleFonts.rubik(fontSize: 13)),
        ),
      ]),
      const SizedBox(height: 16),

      // Live stats grid
      Wrap(spacing: 12, runSpacing: 12, children: [
        _LiveStatCard('משתמשים פעילים', '$activeNow', Icons.person, AppColors.turquoise, large: true),
        _LiveStatCard('iOS', '${rt['active_ios']}', Icons.phone_iphone, AppColors.midBlue),
        _LiveStatCard('Android', '${rt['active_android']}', Icons.phone_android, AppColors.success),
        _LiveStatCard('Web', '${rt['active_web']}', Icons.language, AppColors.gold),
        _LiveStatCard('סשנים היום', '$sessionsToday', Icons.login, AppColors.navy),
        _LiveStatCard('צפיות', _fmtK(pageViews), Icons.visibility, AppColors.turquoise),
        _LiveStatCard('Bounce Rate', '$bounceRate%', Icons.keyboard_return, bounceRate > 30 ? AppColors.error : AppColors.success),
        _LiveStatCard('חיפושים', '$searches', Icons.search, AppColors.midBlue),
        _LiveStatCard('שיתופים', '$shares', Icons.share, AppColors.gold),
        _LiveStatCard('משתמשים חדשים', '$newUsers', Icons.person_add, AppColors.success),
        _LiveStatCard('Push נשלחו', _fmtK(notiSent), Icons.notifications, AppColors.navy),
        _LiveStatCard('Push נפתחו', _fmtK(notiOpened), Icons.mark_email_read, AppColors.turquoise),
        _LiveStatCard('שגיאות', '$errors', Icons.error_outline, errors > 0 ? AppColors.error : AppColors.success),
        _LiveStatCard('Latency', '${apiLatency}ms', Icons.speed, apiLatency > 60 ? AppColors.gold : AppColors.success),
      ]),
      const SizedBox(height: 24),

      // Live user map placeholder
      _CardShell(title: 'מפת משתמשים חיים — ${liveUsers.length} פעילים', child: SizedBox(
        height: 320,
        child: _LiveUserMap(users: liveUsers.cast<Map<String, dynamic>>()),
      )),
      const SizedBox(height: 30),
    ]);
  }

  String _fmtK(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : '$n';
}

// ══════════════════════════════════════════════
// TAB 2 — ENGAGEMENT (DAU/WAU/MAU, Retention, Sessions)
// ══════════════════════════════════════════════

class _EngagementTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daily = ref.watch(adminDailyAnalyticsProvider);
    final isWide = MediaQuery.of(context).size.width > 900;
    final dau = daily['dau'] as List;
    final wau = daily['wau'] as List;
    final mau = daily['mau'] as List;
    final retention = daily['retention'] as Map<String, dynamic>;
    final peakHours = daily['peak_hours'] as List;

    return ListView(padding: const EdgeInsets.all(20), children: [
      Text('מעורבות משתמשים', style: GoogleFonts.rubik(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.navy)),
      const SizedBox(height: 16),

      // DAU / WAU / MAU cards
      Wrap(spacing: 12, runSpacing: 12, children: [
        _MetricCard('DAU', '${daily['dau_current']}', '+${daily['dau_change_pct']}%', AppColors.turquoise),
        _MetricCard('WAU', '${daily['wau_current']}', '+${daily['wau_change_pct']}%', AppColors.midBlue),
        _MetricCard('MAU', '${daily['mau_current']}', '+${daily['mau_change_pct']}%', AppColors.success),
        _MetricCard('זמן ממוצע', '${daily['avg_session_duration_min']} דק׳', null, AppColors.gold),
        _MetricCard('סשנים/משתמש', '${daily['avg_sessions_per_user']}', null, AppColors.navy),
        _MetricCard('מסכים/סשן', '${daily['avg_screens_per_session']}', null, const Color(0xFF8B5CF6)),
      ]),
      const SizedBox(height: 24),

      // DAU chart
      _CardShell(title: 'DAU — 30 יום אחרונים', child: SizedBox(
        height: 220,
        child: Padding(
          padding: const EdgeInsets.only(top: 12, right: 8),
          child: LineChart(_buildDauChart(dau)),
        ),
      )),
      const SizedBox(height: 20),

      // WAU + MAU side by side
      if (isWide) Row(children: [
        Expanded(child: _CardShell(title: 'WAU — 12 שבועות', child: SizedBox(height: 200, child: Padding(padding: const EdgeInsets.only(top: 12), child: BarChart(_buildBarChart(wau, 'week', 'count', AppColors.midBlue)))))),
        const SizedBox(width: 16),
        Expanded(child: _CardShell(title: 'MAU — 6 חודשים', child: SizedBox(height: 200, child: Padding(padding: const EdgeInsets.only(top: 12), child: BarChart(_buildBarChart(mau, 'month', 'count', AppColors.success)))))),
      ]) else ...[
        _CardShell(title: 'WAU — 12 שבועות', child: SizedBox(height: 200, child: Padding(padding: const EdgeInsets.only(top: 12), child: BarChart(_buildBarChart(wau, 'week', 'count', AppColors.midBlue))))),
        const SizedBox(height: 16),
        _CardShell(title: 'MAU — 6 חודשים', child: SizedBox(height: 200, child: Padding(padding: const EdgeInsets.only(top: 12), child: BarChart(_buildBarChart(mau, 'month', 'count', AppColors.success))))),
      ],
      const SizedBox(height: 20),

      // Retention
      _CardShell(title: 'שימור משתמשים (Retention)', child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: retention.entries.map((e) {
          final pct = (e.value as num).toDouble();
          return Column(children: [
            Text('${pct.toInt()}%', style: GoogleFonts.rubik(fontSize: 18, fontWeight: FontWeight.w700, color: pct > 40 ? AppColors.success : pct > 20 ? AppColors.gold : AppColors.error)),
            const SizedBox(height: 4),
            Text(e.key.replaceAll('day', 'D'), style: GoogleFonts.rubik(fontSize: 11, color: AppColors.grayText)),
          ]);
        }).toList()),
      )),
      const SizedBox(height: 20),

      // Peak hours
      _CardShell(title: 'שעות שיא', child: SizedBox(
        height: 200,
        child: Padding(
          padding: const EdgeInsets.only(top: 12, right: 8),
          child: BarChart(BarChartData(
            barGroups: peakHours.asMap().entries.map((e) {
              final users = (e.value as Map)['users'] as int;
              return BarChartGroupData(x: e.key, barRods: [BarChartRodData(toY: users.toDouble(), color: AppColors.turquoise, width: 14, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))]);
            }).toList(),
            titlesData: FlTitlesData(
              rightTitles: const AxisTitles(), topTitles: const AxisTitles(),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36, getTitlesWidget: (v, _) => Text(_fmtK(v.toInt()), style: GoogleFonts.rubik(fontSize: 10, color: AppColors.grayLight)))),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24, getTitlesWidget: (v, _) {
                if (v.toInt() < peakHours.length) {
                  return Text('${(peakHours[v.toInt()] as Map)['hour']}', style: GoogleFonts.rubik(fontSize: 10, color: AppColors.grayLight));
                }
                return const Text('');
              })),
            ),
            gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 300),
            borderData: FlBorderData(show: false),
          )),
        ),
      )),
      const SizedBox(height: 30),
    ]);
  }

  LineChartData _buildDauChart(List dau) {
    final spots = dau.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value as Map)['count'].toDouble())).toList();
    return LineChartData(
      minY: 0,
      gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 400),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(), topTitles: const AxisTitles(),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, interval: 400, getTitlesWidget: (v, _) => Text(_fmtK(v.toInt()), style: GoogleFonts.rubik(fontSize: 10, color: AppColors.grayLight)))),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24, interval: 5, getTitlesWidget: (v, _) {
          if (v.toInt() < dau.length) {
            final d = (dau[v.toInt()] as Map)['date'] as String;
            return Text(d.substring(8), style: GoogleFonts.rubik(fontSize: 10, color: AppColors.grayLight));
          }
          return const Text('');
        })),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [LineChartBarData(spots: spots, isCurved: true, curveSmoothness: 0.3, color: AppColors.turquoise, barWidth: 2, dotData: const FlDotData(show: false), belowBarData: BarAreaData(show: true, color: AppColors.turquoise.withValues(alpha: 0.08)))],
      lineTouchData: LineTouchData(touchTooltipData: LineTouchTooltipData(getTooltipItems: (spots) => spots.map((s) => LineTooltipItem('${s.y.toInt()} פעילים', GoogleFonts.rubik(color: Colors.white, fontSize: 12))).toList())),
    );
  }

  BarChartData _buildBarChart(List data, String labelKey, String valueKey, Color color) {
    return BarChartData(
      barGroups: data.asMap().entries.map((e) {
        final v = ((e.value as Map)[valueKey] as num).toDouble();
        return BarChartGroupData(x: e.key, barRods: [BarChartRodData(toY: v, color: color, width: 18, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))]);
      }).toList(),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(), topTitles: const AxisTitles(),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, _) => Text(_fmtK(v.toInt()), style: GoogleFonts.rubik(fontSize: 10, color: AppColors.grayLight)))),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24, getTitlesWidget: (v, _) {
          if (v.toInt() < data.length) return Text((data[v.toInt()] as Map)[labelKey].toString(), style: GoogleFonts.rubik(fontSize: 10, color: AppColors.grayLight));
          return const Text('');
        })),
      ),
      gridData: FlGridData(show: true, drawVerticalLine: false),
      borderData: FlBorderData(show: false),
    );
  }

  String _fmtK(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : '$n';
}

// ══════════════════════════════════════════════
// TAB 3 — CONTENT PERFORMANCE
// ══════════════════════════════════════════════

class _ContentTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cp = ref.watch(adminContentPerformanceProvider);
    final isWide = MediaQuery.of(context).size.width > 900;
    final topArticles = cp['top_articles'] as List;
    final topBusinesses = cp['top_businesses'] as List;
    final topEvents = cp['top_events'] as List;
    final searches = cp['search_queries'] as List;
    final zeroResults = cp['zero_result_searches'] as List;
    final categories = cp['categories_distribution'] as List;

    return ListView(padding: const EdgeInsets.all(20), children: [
      Text('ביצועי תוכן', style: GoogleFonts.rubik(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.navy)),
      const SizedBox(height: 16),

      // Top articles
      _CardShell(title: '📰 כתבות מובילות', child: _RankedTable(
        headers: ['כתבה', 'צפיות', 'שיתופים', 'תגובות', 'זמן קריאה'],
        rows: topArticles.map((a) => [
          a['title'] as String, '${a['views']}', '${a['shares']}', '${a['comments']}',
          '${((a['avg_read_time_sec'] as int) / 60).toStringAsFixed(1)} דק׳',
        ]).toList(),
      )),
      const SizedBox(height: 16),

      // Top businesses
      _CardShell(title: '🏪 עסקים מובילים', child: _RankedTable(
        headers: ['עסק', 'צפיות', 'חיוגים', 'ניווטים', 'שמירות'],
        rows: topBusinesses.map((b) => [
          b['name'] as String, '${b['views']}', '${b['clicks_to_phone']}', '${b['clicks_to_nav']}', '${b['saves']}',
        ]).toList(),
      )),
      const SizedBox(height: 16),

      // Top events
      _CardShell(title: '🎉 אירועים מובילים', child: _RankedTable(
        headers: ['אירוע', 'צפיות', 'כרטיסים', 'שיתופים', 'RSVP'],
        rows: topEvents.map((e) => [
          e['title'] as String, '${e['views']}', '${e['ticket_clicks']}', '${e['shares']}', '${e['rsvp']}',
        ]).toList(),
      )),
      const SizedBox(height: 20),

      // Search analytics + Zero results
      if (isWide) Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(flex: 3, child: _CardShell(title: '🔍 חיפושים מובילים', child: _RankedTable(
          headers: ['שאילתה', 'חיפושים', 'תוצאות ממוצע'],
          rows: searches.map((s) => [s['query'] as String, '${s['count']}', '${s['results_avg']}']).toList(),
        ))),
        const SizedBox(width: 16),
        Expanded(flex: 2, child: _CardShell(title: '⚠️ חיפושים ללא תוצאות', child: Column(
          children: zeroResults.map((z) => ListTile(
            dense: true,
            title: Text(z['query'] as String, style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w600)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Text('${z['count']}', style: GoogleFonts.rubik(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.error)),
            ),
          )).toList(),
        ))),
      ]) else ...[
        _CardShell(title: '🔍 חיפושים מובילים', child: _RankedTable(
          headers: ['שאילתה', 'חיפושים', 'תוצאות'],
          rows: searches.map((s) => [s['query'] as String, '${s['count']}', '${s['results_avg']}']).toList(),
        )),
        const SizedBox(height: 16),
        _CardShell(title: '⚠️ חיפושים ללא תוצאות', child: Column(
          children: zeroResults.map((z) => ListTile(
            dense: true,
            title: Text(z['query'] as String, style: GoogleFonts.rubik(fontSize: 13)),
            trailing: Text('${z['count']}', style: GoogleFonts.rubik(fontSize: 12, color: AppColors.error)),
          )).toList(),
        )),
      ],
      const SizedBox(height: 20),

      // Category distribution
      _CardShell(title: '📊 התפלגות לפי קטגוריה', child: Column(
        children: categories.map((c) {
          final pct = c['pct'] as int;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            child: Row(children: [
              SizedBox(width: 140, child: Text(c['name'] as String, style: GoogleFonts.rubik(fontSize: 12, color: AppColors.navy))),
              Expanded(child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: pct / 100, minHeight: 16, backgroundColor: AppColors.surfaceLight, color: AppColors.turquoise.withValues(alpha: 0.7 + pct / 300)),
              )),
              const SizedBox(width: 8),
              SizedBox(width: 50, child: Text('$pct%', style: GoogleFonts.rubik(fontSize: 12, fontWeight: FontWeight.w600))),
              SizedBox(width: 50, child: Text('${c['businesses']}', style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayText))),
            ]),
          );
        }).toList(),
      )),
      const SizedBox(height: 30),
    ]);
  }
}

// ══════════════════════════════════════════════
// TAB 4 — AD & REVENUE
// ══════════════════════════════════════════════

class _RevenueTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ad = ref.watch(adminAdAnalyticsProvider);
    final isWide = MediaQuery.of(context).size.width > 900;
    final revenueTrend = ad['revenue_trend'] as List;
    final revBySource = ad['revenue_by_source'] as List;
    final placements = ad['placement_performance'] as List;
    final funnel = ad['offer_funnel'] as Map<String, dynamic>;
    final topAdvertisers = ad['top_advertisers'] as List;

    return ListView(padding: const EdgeInsets.all(20), children: [
      Text('פרסום והכנסות', style: GoogleFonts.rubik(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.navy)),
      const SizedBox(height: 16),

      // Revenue headline metrics
      Wrap(spacing: 12, runSpacing: 12, children: [
        _MetricCard('הכנסות החודש', '₪${_fmtK(ad['revenue_this_month'] as int)}', '+${ad['revenue_growth_pct']}%', AppColors.success),
        _MetricCard('MRR', '₪${_fmtK(ad['mrr'] as int)}', null, AppColors.turquoise),
        _MetricCard('ARR (תחזית)', '₪${_fmtK(ad['arr_estimated'] as int)}', null, AppColors.midBlue),
        _MetricCard('סה"כ השנה', '₪${_fmtK(ad['revenue_total_year'] as int)}', null, AppColors.gold),
        _MetricCard('CTR ממוצע', '${ad['overall_ctr']}%', null, AppColors.navy),
        _MetricCard('Fill Rate', '${ad['fill_rate_pct']}%', null, const Color(0xFF8B5CF6)),
      ]),
      const SizedBox(height: 20),

      // Revenue trend chart
      _CardShell(title: '📈 מגמת הכנסות — 6 חודשים', child: SizedBox(
        height: 220,
        child: Padding(
          padding: const EdgeInsets.only(top: 12, right: 8),
          child: BarChart(BarChartData(
            barGroups: revenueTrend.asMap().entries.map((e) {
              final amt = ((e.value as Map)['amount'] as num).toDouble();
              return BarChartGroupData(x: e.key, barRods: [BarChartRodData(toY: amt, color: AppColors.success, width: 28, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))]);
            }).toList(),
            titlesData: FlTitlesData(
              rightTitles: const AxisTitles(), topTitles: const AxisTitles(),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 50, getTitlesWidget: (v, _) => Text('₪${_fmtK(v.toInt())}', style: GoogleFonts.rubik(fontSize: 10, color: AppColors.grayLight)))),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24, getTitlesWidget: (v, _) {
                if (v.toInt() < revenueTrend.length) return Text((revenueTrend[v.toInt()] as Map)['month'].toString(), style: GoogleFonts.rubik(fontSize: 10, color: AppColors.grayLight));
                return const Text('');
              })),
            ),
            gridData: FlGridData(show: true, drawVerticalLine: false),
            borderData: FlBorderData(show: false),
          )),
        ),
      )),
      const SizedBox(height: 20),

      // Revenue by source + Offer funnel
      if (isWide) Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(flex: 3, child: _CardShell(title: '💰 הכנסות לפי מקור', child: Column(
          children: revBySource.map((s) {
            final pct = s['pct'] as int;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              child: Row(children: [
                SizedBox(width: 130, child: Text(s['source'] as String, style: GoogleFonts.rubik(fontSize: 12))),
                Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: pct / 100, minHeight: 14, backgroundColor: AppColors.surfaceLight, color: AppColors.success))),
                const SizedBox(width: 8),
                SizedBox(width: 60, child: Text('₪${_fmtK(s['amount'] as int)}', style: GoogleFonts.rubik(fontSize: 12, fontWeight: FontWeight.w600))),
                SizedBox(width: 40, child: Text('$pct%', style: GoogleFonts.rubik(fontSize: 11, color: AppColors.grayText))),
              ]),
            );
          }).toList(),
        ))),
        const SizedBox(width: 16),
        Expanded(flex: 2, child: _CardShell(title: '🎯 משפך מבצעים', child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            _FunnelStep('צפיות', funnel['views'] as int, funnel['views'] as int),
            _FunnelStep('הקלקות', funnel['clicks'] as int, funnel['views'] as int),
            _FunnelStep('העתקת קוד', funnel['code_copies'] as int, funnel['views'] as int),
            _FunnelStep('מימושים', funnel['claims'] as int, funnel['views'] as int),
            const SizedBox(height: 8),
            Text('Conversion: ${funnel['conversion_rate_pct']}%', style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.success)),
          ]),
        ))),
      ]) else ...[
        _CardShell(title: '💰 הכנסות לפי מקור', child: Column(
          children: revBySource.map((s) => ListTile(
            dense: true,
            title: Text(s['source'] as String, style: GoogleFonts.rubik(fontSize: 13)),
            trailing: Text('₪${_fmtK(s['amount'] as int)}', style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w600)),
          )).toList(),
        )),
        const SizedBox(height: 16),
      ],
      const SizedBox(height: 20),

      // Placement performance
      _CardShell(title: '📍 ביצועי מיקומי פרסום', child: _RankedTable(
        headers: ['מיקום', 'חשיפות', 'הקלקות', 'CTR', 'הכנסה'],
        rows: placements.map((p) => [
          p['label'] as String, _fmtK(p['impressions'] as int), _fmtK(p['clicks'] as int),
          '${p['ctr']}%', '₪${_fmtK(p['revenue'] as int)}',
        ]).toList(),
      )),
      const SizedBox(height: 20),

      // Top advertisers
      _CardShell(title: '🏆 מפרסמים מובילים', child: _RankedTable(
        headers: ['מפרסם', 'הכנסה', 'קמפיינים'],
        rows: topAdvertisers.map((a) => [a['name'] as String, '₪${_fmtK(a['revenue'] as int)}', '${a['campaigns']}']).toList(),
      )),
      const SizedBox(height: 30),
    ]);
  }

  String _fmtK(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : '$n';
}

// ══════════════════════════════════════════════
// TAB 5 — DEMOGRAPHICS
// ══════════════════════════════════════════════

class _DemographicsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ua = ref.watch(adminUserAnalyticsProvider);
    final heatmap = ref.watch(adminNeighborhoodHeatmapProvider);
    final isWide = MediaQuery.of(context).size.width > 900;
    final acquisition = ua['acquisition'] as List;
    final byNeighborhood = ua['by_neighborhood'] as List;
    final byPlatform = ua['by_platform'] as List;
    final byAge = ua['by_age'] as List;
    final engSegments = ua['engagement_segments'] as List;
    final pushStats = ua['push_stats'] as Map<String, dynamic>;
    final gamification = ua['gamification'] as Map<String, dynamic>;

    return ListView(padding: const EdgeInsets.all(20), children: [
      Text('דמוגרפיה ומשתמשים', style: GoogleFonts.rubik(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.navy)),
      const SizedBox(height: 16),

      // User headline
      Wrap(spacing: 12, runSpacing: 12, children: [
        _MetricCard('סה"כ משתמשים', '${ua['total_users']}', null, AppColors.turquoise),
        _MetricCard('מאומתים', '${ua['verified_users']}', null, AppColors.success),
        _MetricCard('בעלי עסקים', '${ua['business_owners']}', null, AppColors.gold),
        _MetricCard('חדשים החודש', '${ua['new_users_this_month']}', null, AppColors.midBlue),
        _MetricCard('נטישה', '${ua['churn_this_month']}', null, AppColors.error),
        _MetricCard('צמיחה נטו', '+${ua['net_growth']}', null, AppColors.success),
      ]),
      const SizedBox(height: 20),

      // Platform + Age side by side
      if (isWide) Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: _CardShell(title: '📱 פלטפורמה', child: SizedBox(
          height: 180,
          child: PieChart(PieChartData(
            sections: byPlatform.asMap().entries.map((e) {
              final p = e.value as Map;
              final colors = [AppColors.navy, AppColors.success, AppColors.turquoise];
              return PieChartSectionData(
                value: (p['pct'] as int).toDouble(), title: '${p['platform']}\n${p['pct']}%',
                color: colors[e.key % colors.length], radius: 55,
                titleStyle: GoogleFonts.rubik(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
              );
            }).toList(),
            sectionsSpace: 2, centerSpaceRadius: 30,
          )),
        ))),
        const SizedBox(width: 16),
        Expanded(child: _CardShell(title: '👤 טווח גיל', child: Column(
          children: byAge.map((a) {
            final pct = a['pct'] as int;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
              child: Row(children: [
                SizedBox(width: 50, child: Text(a['range'] as String, style: GoogleFonts.rubik(fontSize: 12))),
                Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: pct / 100, minHeight: 14, backgroundColor: AppColors.surfaceLight, color: AppColors.midBlue))),
                const SizedBox(width: 8),
                Text('$pct%', style: GoogleFonts.rubik(fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            );
          }).toList(),
        ))),
      ]) else ...[
        _CardShell(title: '📱 פלטפורמה', child: Column(
          children: byPlatform.map((p) => ListTile(
            dense: true,
            title: Text(p['platform'] as String, style: GoogleFonts.rubik(fontSize: 13)),
            trailing: Text('${p['pct']}% (${p['users']})', style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w600)),
          )).toList(),
        )),
        const SizedBox(height: 16),
      ],
      const SizedBox(height: 20),

      // Engagement segments
      _CardShell(title: '🎯 פלחי מעורבות', child: Column(
        children: engSegments.map((s) {
          final colorName = s['color'] as String;
          final color = switch (colorName) {
            'success' => AppColors.success,
            'turquoise' => AppColors.turquoise,
            'gold' => AppColors.gold,
            'error' => AppColors.error,
            _ => AppColors.grayLight,
          };
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
            child: Row(children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(child: Text(s['segment'] as String, style: GoogleFonts.rubik(fontSize: 12))),
              Text('${s['users']}', style: GoogleFonts.rubik(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Text('${s['pct']}%', style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayText)),
            ]),
          );
        }).toList(),
      )),
      const SizedBox(height: 20),

      // Acquisition channels + By neighborhood
      if (isWide) Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: _CardShell(title: '📥 ערוצי רכישה', child: Column(
          children: acquisition.map((a) {
            final pct = a['pct'] as int;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
              child: Row(children: [
                SizedBox(width: 130, child: Text(a['channel'] as String, style: GoogleFonts.rubik(fontSize: 12))),
                Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: pct / 100, minHeight: 14, backgroundColor: AppColors.surfaceLight, color: AppColors.turquoise))),
                const SizedBox(width: 8),
                Text('$pct%', style: GoogleFonts.rubik(fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            );
          }).toList(),
        ))),
        const SizedBox(width: 16),
        Expanded(child: _CardShell(title: '🏘️ לפי שכונה', child: Column(
          children: byNeighborhood.map((n) {
            final pct = n['pct'] as int;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
              child: Row(children: [
                SizedBox(width: 90, child: Text(n['name'] as String, style: GoogleFonts.rubik(fontSize: 12))),
                Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: pct / 100, minHeight: 14, backgroundColor: AppColors.surfaceLight, color: AppColors.midBlue))),
                const SizedBox(width: 8),
                Text('${n['users']}', style: GoogleFonts.rubik(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                Text('($pct%)', style: GoogleFonts.rubik(fontSize: 11, color: AppColors.grayText)),
              ]),
            );
          }).toList(),
        ))),
      ]) else ...[
        _CardShell(title: '📥 ערוצי רכישה', child: Column(
          children: acquisition.map((a) => ListTile(dense: true, title: Text(a['channel'] as String, style: GoogleFonts.rubik(fontSize: 13)), trailing: Text('${a['pct']}%', style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w600)))).toList(),
        )),
        const SizedBox(height: 16),
        _CardShell(title: '🏘️ לפי שכונה', child: Column(
          children: byNeighborhood.map((n) => ListTile(dense: true, title: Text(n['name'] as String, style: GoogleFonts.rubik(fontSize: 13)), trailing: Text('${n['users']}', style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w600)))).toList(),
        )),
      ],
      const SizedBox(height: 20),

      // Push stats + Gamification
      if (isWide) Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: _CardShell(title: '🔔 ביצועי Push', child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            _PushStatRow('נשלחו החודש', '${_fmtK(pushStats['sent_this_month'] as int)}'),
            _PushStatRow('אחוז מסירה', '${pushStats['delivered_pct']}%'),
            _PushStatRow('אחוז פתיחה', '${pushStats['opened_pct']}%'),
            _PushStatRow('אחוז הקלקה', '${pushStats['clicked_pct']}%'),
            _PushStatRow('Opt-out', '${pushStats['opt_out_pct']}%', isWarning: true),
          ]),
        ))),
        const SizedBox(width: 16),
        Expanded(child: _CardShell(title: '🎮 גיימיפיקציה', child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            _PushStatRow('שחקנים פעילים', '${gamification['active_players']}'),
            _PushStatRow('נקודות חולקו', _fmtK(gamification['total_points_distributed'] as int)),
            _PushStatRow('ממוצע יומי', '${gamification['avg_daily_points']}'),
            _PushStatRow('צעדים היום', _fmtK(gamification['steps_tracked_today'] as int)),
            _PushStatRow('פרסים מומשו', '${gamification['rewards_claimed']}'),
          ]),
        ))),
      ]) else ...[
        _CardShell(title: '🔔 ביצועי Push', child: Column(children: [
          _PushStatRow('נשלחו', '${_fmtK(pushStats['sent_this_month'] as int)}'),
          _PushStatRow('פתיחה', '${pushStats['opened_pct']}%'),
          _PushStatRow('Opt-out', '${pushStats['opt_out_pct']}%', isWarning: true),
        ])),
        const SizedBox(height: 16),
      ],

      const SizedBox(height: 20),

      // Neighborhood heatmap grid
      _CardShell(title: '🗺️ מפת חום שכונות', child: _NeighborhoodHeatGrid(data: heatmap)),
      const SizedBox(height: 30),
    ]);
  }

  String _fmtK(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : '$n';
}

// ══════════════════════════════════════════════
// SHARED WIDGETS
// ══════════════════════════════════════════════

class _CardShell extends StatelessWidget {
  final String title;
  final Widget child;
  const _CardShell({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(title, style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy)),
        ),
        Divider(height: 1, color: AppColors.border.withValues(alpha: 0.5)),
        child,
      ]),
    );
  }
}

class _LiveStatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final bool large;
  const _LiveStatCard(this.label, this.value, this.icon, this.color, {this.large = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: large ? 170 : 145,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: large ? color.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: large ? color.withValues(alpha: 0.3) : AppColors.border, width: large ? 1.5 : 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: large ? 22 : 18, color: color),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.rubik(fontSize: large ? 24 : 18, fontWeight: FontWeight.w700, color: AppColors.navy)),
        Text(label, style: GoogleFonts.rubik(fontSize: 11, color: AppColors.grayText)),
      ]),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label, value;
  final String? change;
  final Color color;
  const _MetricCard(this.label, this.value, this.change, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 165,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Expanded(child: Text(label, style: GoogleFonts.rubik(fontSize: 11, color: AppColors.grayText), overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.rubik(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.navy)),
        if (change != null) Text(change!, style: GoogleFonts.rubik(fontSize: 12, fontWeight: FontWeight.w600, color: change!.startsWith('+') ? AppColors.success : AppColors.error)),
      ]),
    );
  }
}

class _RankedTable extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> rows;
  const _RankedTable({required this.headers, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: AppColors.surfaceLight,
        child: Row(children: [
          SizedBox(width: 24, child: Text('#', style: GoogleFonts.rubik(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.grayLight))),
          ...headers.asMap().entries.map((e) => Expanded(flex: e.key == 0 ? 3 : 1, child: Text(e.value, style: GoogleFonts.rubik(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.grayLight)))),
        ]),
      ),
      ...rows.asMap().entries.map((e) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.3)))),
        child: Row(children: [
          SizedBox(width: 24, child: Text('${e.key + 1}', style: GoogleFonts.rubik(fontSize: 12, fontWeight: FontWeight.w700, color: e.key < 3 ? AppColors.gold : AppColors.grayLight))),
          ...e.value.asMap().entries.map((c) => Expanded(flex: c.key == 0 ? 3 : 1, child: Text(c.value, style: GoogleFonts.rubik(fontSize: 12, fontWeight: c.key == 0 ? FontWeight.w600 : FontWeight.w400, color: c.key == 0 ? AppColors.navy : AppColors.grayText), overflow: TextOverflow.ellipsis))),
        ]),
      )),
    ]);
  }
}

class _FunnelStep extends StatelessWidget {
  final String label;
  final int value, max;
  const _FunnelStep(this.label, this.value, this.max);

  @override
  Widget build(BuildContext context) {
    final pct = max > 0 ? value / max : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(width: 80, child: Text(label, style: GoogleFonts.rubik(fontSize: 12))),
        Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: pct, minHeight: 16, backgroundColor: AppColors.surfaceLight, color: AppColors.turquoise))),
        const SizedBox(width: 8),
        SizedBox(width: 50, child: Text(_fmtK(value), style: GoogleFonts.rubik(fontSize: 12, fontWeight: FontWeight.w600))),
      ]),
    );
  }

  String _fmtK(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : '$n';
}

class _PushStatRow extends StatelessWidget {
  final String label, value;
  final bool isWarning;
  const _PushStatRow(this.label, this.value, {this.isWarning = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(child: Text(label, style: GoogleFonts.rubik(fontSize: 13))),
        Text(value, style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w700, color: isWarning ? AppColors.error : AppColors.navy)),
      ]),
    );
  }
}

class _NeighborhoodHeatGrid extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _NeighborhoodHeatGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxUsers = data.fold<int>(0, (m, d) => max(m, d['users'] as int));
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(spacing: 8, runSpacing: 8, children: data.map((d) {
        final users = d['users'] as int;
        final intensity = maxUsers > 0 ? users / maxUsers : 0.0;
        return Container(
          width: 160,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.turquoise.withValues(alpha: 0.05 + intensity * 0.25),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.turquoise.withValues(alpha: 0.2 + intensity * 0.3)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d['name'] as String, style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy)),
            const SizedBox(height: 4),
            Text('$users משתמשים', style: GoogleFonts.rubik(fontSize: 11, color: AppColors.grayText)),
            Text('${d['businesses']} עסקים · ${d['events_this_month']} אירועים', style: GoogleFonts.rubik(fontSize: 10, color: AppColors.grayLight)),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.star, size: 12, color: AppColors.gold),
              const SizedBox(width: 2),
              Text('${d['avg_engagement']}', style: GoogleFonts.rubik(fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ]),
        );
      }).toList()),
    );
  }
}

/// A visual representation of live users scattered around Modi'in.
/// Since we can't use an actual map (no external dependencies), we render
/// a coordinate-space scatter plot with neighborhood labels.
class _LiveUserMap extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  const _LiveUserMap({required this.users});

  @override
  Widget build(BuildContext context) {
    // Bounding box around Modi'in
    const minLat = 31.87, maxLat = 31.93;
    const minLng = 34.98, maxLng = 35.04;

    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;

      return Stack(
        children: [
          // Grid background
          CustomPaint(size: Size(w, h), painter: _GridPainter()),
          // Label "מודיעין" in center
          Positioned(
            left: w * 0.45, top: h * 0.05,
            child: Text('מודיעין', style: GoogleFonts.rubik(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.navy.withValues(alpha: 0.15))),
          ),
          // User dots
          ...users.map((u) {
            final lat = (u['lat'] as num).toDouble();
            final lng = (u['lng'] as num).toDouble();
            final x = ((lng - minLng) / (maxLng - minLng)).clamp(0.05, 0.95) * w;
            final y = (1 - (lat - minLat) / (maxLat - minLat)).clamp(0.05, 0.95) * h;
            return Positioned(
              left: x - 5, top: y - 5,
              child: Tooltip(
                message: u['neighborhood'] as String? ?? '',
                child: Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.turquoise.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppColors.turquoise.withValues(alpha: 0.3), blurRadius: 6)],
                  ),
                ),
              ),
            );
          }),
          // Neighborhood labels
          ..._neighborhoodPositions.entries.map((e) {
            final x = ((e.value.$2 - minLng) / (maxLng - minLng)).clamp(0.05, 0.95) * w;
            final y = (1 - (e.value.$1 - minLat) / (maxLat - minLat)).clamp(0.05, 0.95) * h;
            return Positioned(
              left: x - 30, top: y - 18,
              child: Text(e.key, style: GoogleFonts.rubik(fontSize: 9, color: AppColors.grayLight, fontWeight: FontWeight.w600)),
            );
          }),
        ],
      );
    });
  }

  static const _neighborhoodPositions = {
    'אבני חן': (31.904, 35.009),
    'בוכמן': (31.898, 35.015),
    'מורשת': (31.892, 35.005),
    'כפר האורנים': (31.910, 34.995),
    'רמת הדר': (31.886, 35.020),
    'שמשון': (31.915, 35.018),
    'עמק שילה': (31.920, 35.025),
  };
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.border.withValues(alpha: 0.2)..strokeWidth = 0.5;
    for (var i = 0; i < 8; i++) {
      final y = size.height * i / 7;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      final x = size.width * i / 7;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

String _fmtK(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : '$n';
