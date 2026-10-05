import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show CountOption;

import '../../../core/supabase/supabase_config.dart';

/// What the Analytics section can actually count.
///
/// Every provider in this file used to invent its figures. A random number
/// generator filled in "127 active users now", "1,834 sessions today",
/// "6,720 page views", "3,200 push notifications sent", a 22–30% bounce rate
/// and a 45–75ms API latency, and a Refresh button regenerated them all — so
/// the numbers moved when you pressed it and read as live. The rest of the file was a fixed
/// table of invented figures: ₪284,500 of revenue, 1.24M ad impressions, a
/// 14,200-user base with retention cohorts, acquisition channels and an age
/// distribution, and twenty-five lat/lng points drawn on a map as the people
/// using the app right now. The database holds two profiles.
///
/// There is no analytics, sessions, page-views or push-delivery table in this
/// schema, and nothing in the app writes one, so sessions, bounce rate,
/// session duration, DAU/WAU/MAU, retention, peak hours, device breakdown,
/// acquisition channel, age, API latency and notification delivery have no
/// source at all and cannot get one from these tables. They are gone.
///
/// What remains is counted: row counts, the `view_count` / `share_count` /
/// `save_count` columns that `articles` and `events` carry, the
/// `entity_categories` links, and the `impressions` / `clicks` / `conversions`
/// columns on `campaigns` with the `amount` on `revenue_transactions`. Several
/// of those totals are zero today. A counted nought is knowledge; it is shown
/// as nought rather than filled in.

/// Rows in each table the first tab reports on, keyed as below.
///
/// Read with `.count(CountOption.exact)` against a one-row window, so the
/// count is the table's and not the page's. Advertising and revenue are
/// counted by their own providers further down, next to the sums they go
/// with.
final adminRowCountsProvider = FutureProvider<Map<String, int>>((ref) async {
  final today = DateTime.now().toIso8601String().split('T')[0];

  final results = await Future.wait([
    _countRows('profiles'),
    _countRows('profiles', column: 'is_verified', equals: true),
    // Phones and browsers that can be sent a notification now — devices,
    // not accounts, since notifications need none (migration 00045). The
    // profile's `push_enabled` it used to count is no longer written.
    _countPushDevices(),
    _countRows('businesses'),
    _countRows('businesses', column: 'status', equals: 'active'),
    _countRows('businesses', column: 'status', equals: 'pending'),
    _countRows('articles'),
    _countRows('articles', column: 'status', equals: 'published'),
    _countRows('articles', column: 'status', equals: 'draft'),
    _countRows('events'),
    _countRows('events', column: 'start_date', gte: today),
    _countRows('neighborhoods'),
    _countRows('categories'),
    _countRows('reviews'),
    _countRows('comments'),
    _countRows('offers'),
    _countRows('offer_claims'),
    _countRows('favorites'),
    _countRows('listings'),
  ]);

  return {
    'residents': results[0],
    'residents_verified': results[1],
    'residents_push_on': results[2],
    'businesses': results[3],
    'businesses_active': results[4],
    'businesses_pending': results[5],
    'articles': results[6],
    'articles_published': results[7],
    'articles_draft': results[8],
    'events': results[9],
    'events_upcoming': results[10],
    'neighborhoods': results[11],
    'categories': results[12],
    'reviews': results[13],
    'comments': results[14],
    'offers': results[15],
    'offer_claims': results[16],
    'favorites': results[17],
    'listings': results[18],
  };
});

/// How many rows a table holds, optionally narrowed to one column's value.
///
/// `gte` is separate from `equals` because the only range this file asks for
/// is "events that have not happened yet".
Future<int> _countPushDevices() async {
  final res = await SupabaseConfig.client
      .from('push_devices')
      .select('id')
      .eq('enabled', true)
      .eq('is_active', true)
      .limit(1)
      .count(CountOption.exact);
  return res.count;
}

Future<int> _countRows(
  String table, {
  String? column,
  Object? equals,
  String? gte,
}) async {
  var query = SupabaseConfig.client.from(table).select('id');
  if (column != null && equals != null) query = query.eq(column, equals);
  if (column != null && gte != null) query = query.gte(column, gte);
  final res = await query.limit(1).count(CountOption.exact);
  return res.count;
}

// ─── Content reach ───

/// The reach columns `articles` and `events` carry.
///
/// `view_count` is incremented by the app when an item is opened. It is the
/// only reach figure in the schema: there is no per-view row, so there is no
/// date on a view and no way to say how many views happened today, this week
/// or in any other window. These are lifetime totals, which is how they are
/// labelled on the screen.
class AdminContentReach {
  /// The ten most-viewed articles: `title`, `view_count`, `share_count`,
  /// `save_count`.
  final List<Map<String, dynamic>> topArticles;

  /// Every event, most-viewed first: `title`, `view_count`, `rsvp_count`,
  /// `share_count`, `calendar_adds`.
  final List<Map<String, dynamic>> topEvents;

  final int articleViews, articleShares, articleSaves;
  final int eventViews, eventRsvps, eventShares, eventCalendarAdds;

  /// How many rows carry a non-zero `view_count`, against how many there are.
  /// Eight of 669 articles do, which is worth saying next to the table: the
  /// ranking is real but it is a ranking of eight.
  final int articlesWithViews, articleTotal;
  final int eventsWithViews, eventTotal;

  const AdminContentReach({
    required this.topArticles,
    required this.topEvents,
    required this.articleViews,
    required this.articleShares,
    required this.articleSaves,
    required this.eventViews,
    required this.eventRsvps,
    required this.eventShares,
    required this.eventCalendarAdds,
    required this.articlesWithViews,
    required this.articleTotal,
    required this.eventsWithViews,
    required this.eventTotal,
  });
}

final adminContentReachProvider = FutureProvider<AdminContentReach>((
  ref,
) async {
  final client = SupabaseConfig.client;

  final articleRows = List<Map<String, dynamic>>.from(
    await client
        .from('articles')
        .select('title, view_count, share_count, save_count')
        .order('view_count', ascending: false),
  );
  final eventRows = List<Map<String, dynamic>>.from(
    await client
        .from('events')
        .select('title, view_count, rsvp_count, share_count, calendar_adds')
        .order('view_count', ascending: false),
  );

  int sum(List<Map<String, dynamic>> rows, String column) =>
      rows.fold(0, (t, r) => t + ((r[column] as num?)?.toInt() ?? 0));

  return AdminContentReach(
    topArticles: articleRows.take(10).toList(),
    topEvents: eventRows.take(10).toList(),
    articleViews: sum(articleRows, 'view_count'),
    articleShares: sum(articleRows, 'share_count'),
    articleSaves: sum(articleRows, 'save_count'),
    eventViews: sum(eventRows, 'view_count'),
    eventRsvps: sum(eventRows, 'rsvp_count'),
    eventShares: sum(eventRows, 'share_count'),
    eventCalendarAdds: sum(eventRows, 'calendar_adds'),
    articlesWithViews: articleRows
        .where((r) => ((r['view_count'] as num?) ?? 0) > 0)
        .length,
    articleTotal: articleRows.length,
    eventsWithViews: eventRows
        .where((r) => ((r['view_count'] as num?) ?? 0) > 0)
        .length,
    eventTotal: eventRows.length,
  );
});

// ─── Publishing cadence ───

/// Articles published per calendar month, oldest first: `month` as `MM/YY`
/// and `count`.
///
/// This is the one real time series the schema supports. It measures the
/// newsroom's output rather than anyone's behaviour, which the chart says.
final adminPublishingCadenceProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
      final rows = List<Map<String, dynamic>>.from(
        await SupabaseConfig.client
            .from('articles')
            .select('published_at')
            .eq('status', 'published')
            .not('published_at', 'is', null)
            .order('published_at', ascending: true),
      );

      final buckets = <String, int>{};
      for (final r in rows) {
        final at = DateTime.tryParse(r['published_at'] as String? ?? '');
        if (at == null) continue;
        final key = '${at.year}-${at.month.toString().padLeft(2, '0')}';
        buckets[key] = (buckets[key] ?? 0) + 1;
      }

      final keys = buckets.keys.toList()..sort();
      // Twelve months is what fits the chart's width without the labels
      // colliding; the table holds twenty-three months of articles.
      final recent = keys.length > 12 ? keys.sublist(keys.length - 12) : keys;

      return [
        for (final k in recent)
          {
            'month': '${k.substring(5)}/${k.substring(2, 4)}',
            'count': buckets[k]!,
          },
      ];
    });

// ─── Catalogue breakdown ───

/// How the business catalogue divides up, by the columns that record it.
class AdminCatalogueBreakdown {
  /// `name` and `count` per category, largest first, from
  /// `entity_categories` where `entity_type = 'business'`.
  final List<Map<String, dynamic>> byCategory;

  /// `name` and `count` per neighbourhood, largest first, from
  /// `businesses.neighborhood_id`.
  final List<Map<String, dynamic>> byNeighborhood;

  /// Businesses with no neighbourhood set. Two hundred of the 220 imported
  /// businesses have none, so a neighbourhood breakdown that did not say so
  /// would be describing 9% of the catalogue as though it were all of it.
  final int withoutNeighborhood;

  final int businessTotal;

  const AdminCatalogueBreakdown({
    required this.byCategory,
    required this.byNeighborhood,
    required this.withoutNeighborhood,
    required this.businessTotal,
  });
}

final adminCatalogueBreakdownProvider = FutureProvider<AdminCatalogueBreakdown>(
  (ref) async {
    final client = SupabaseConfig.client;

    final categoryLinks = List<Map<String, dynamic>>.from(
      await client
          .from('entity_categories')
          .select('category_id, categories(name)')
          .eq('entity_type', 'business'),
    );
    final businessRows = List<Map<String, dynamic>>.from(
      await client.from('businesses').select('neighborhood_id'),
    );
    final neighborhoods = List<Map<String, dynamic>>.from(
      await client.from('neighborhoods').select('id, name'),
    );

    final perCategory = <String, int>{};
    for (final link in categoryLinks) {
      final name = (link['categories'] as Map?)?['name'] as String?;
      if (name == null) continue;
      perCategory[name] = (perCategory[name] ?? 0) + 1;
    }

    final names = {
      for (final n in neighborhoods) n['id'] as String: n['name'] as String,
    };
    final perNeighborhood = <String, int>{};
    var withoutNeighborhood = 0;
    for (final b in businessRows) {
      final id = b['neighborhood_id'] as String?;
      final name = id == null ? null : names[id];
      if (name == null) {
        withoutNeighborhood++;
        continue;
      }
      perNeighborhood[name] = (perNeighborhood[name] ?? 0) + 1;
    }

    List<Map<String, dynamic>> ranked(Map<String, int> counts) {
      final entries = counts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return [
        for (final e in entries) {'name': e.key, 'count': e.value},
      ];
    }

    return AdminCatalogueBreakdown(
      byCategory: ranked(perCategory),
      byNeighborhood: ranked(perNeighborhood),
      withoutNeighborhood: withoutNeighborhood,
      businessTotal: businessRows.length,
    );
  },
);

// ─── Campaign performance ───

/// The counters `campaigns` carries, summed.
///
/// `impressions`, `unique_impressions`, `clicks` and `conversions` are real
/// columns with a default of zero. Nothing in the app increments them yet, so
/// they are zero until a banner is served through something that does — which
/// the screen says rather than showing a made-up CTR.
class AdminCampaignPerformance {
  final int campaigns;
  final int impressions, uniqueImpressions, clicks, conversions;

  /// Campaigns per `status`, from the `campaign_status` enum.
  final Map<String, int> byStatus;

  /// `label` and `campaigns` per slot, from `ad_placements`.
  final List<Map<String, dynamic>> placements;

  const AdminCampaignPerformance({
    required this.campaigns,
    required this.impressions,
    required this.uniqueImpressions,
    required this.clicks,
    required this.conversions,
    required this.byStatus,
    required this.placements,
  });

  /// Click-through rate, or null when nothing has been served — a rate over
  /// zero impressions is not zero per cent, it is unknown.
  double? get ctr => impressions == 0 ? null : clicks / impressions * 100;
}

final adminCampaignPerformanceProvider =
    FutureProvider<AdminCampaignPerformance>((ref) async {
      final client = SupabaseConfig.client;

      final campaigns = List<Map<String, dynamic>>.from(
        await client
            .from('campaigns')
            .select(
              'status, placement_id, impressions, unique_impressions, '
              'clicks, conversions',
            ),
      );
      final placements = List<Map<String, dynamic>>.from(
        await client
            .from('ad_placements')
            .select('id, label')
            .order('sort_order', ascending: true),
      );

      int sum(String column) =>
          campaigns.fold(0, (t, r) => t + ((r[column] as num?)?.toInt() ?? 0));

      final byStatus = <String, int>{};
      final perPlacement = <String, int>{};
      for (final c in campaigns) {
        final status = c['status'] as String? ?? 'draft';
        byStatus[status] = (byStatus[status] ?? 0) + 1;
        final slot = c['placement_id'] as String?;
        if (slot != null) perPlacement[slot] = (perPlacement[slot] ?? 0) + 1;
      }

      return AdminCampaignPerformance(
        campaigns: campaigns.length,
        impressions: sum('impressions'),
        uniqueImpressions: sum('unique_impressions'),
        clicks: sum('clicks'),
        conversions: sum('conversions'),
        byStatus: byStatus,
        placements: [
          for (final p in placements)
            {
              'label': p['label'] as String? ?? '',
              'campaigns': perPlacement[p['id'] as String] ?? 0,
            },
        ],
      );
    });

// ─── Revenue ───

/// Money the panel has a record of, from `revenue_transactions`.
///
/// Every figure here is a sum of the `amount` column over rows that exist.
/// The section used to report ₪284,500 for the year, an MRR and an ARR
/// forecast against an empty table.
class AdminRevenueSummary {
  final int transactions;

  /// Sums of `amount`, in shekels.
  final double total, paid, outstanding, thisMonth;

  /// `type` and `amount` per `revenue_type`, largest first.
  final List<Map<String, dynamic>> byType;

  /// Subscriptions with `status = 'active'`. Their value per month is not
  /// derived here: `billing_cycle` spreads a price over a period the client
  /// has not told us how to apportion, and an MRR is a claim, not a count.
  final int activeSubscriptions;

  const AdminRevenueSummary({
    required this.transactions,
    required this.total,
    required this.paid,
    required this.outstanding,
    required this.thisMonth,
    required this.byType,
    required this.activeSubscriptions,
  });
}

final adminRevenueSummaryProvider = FutureProvider<AdminRevenueSummary>((
  ref,
) async {
  final client = SupabaseConfig.client;

  final rows = List<Map<String, dynamic>>.from(
    await client
        .from('revenue_transactions')
        .select('amount, revenue_type, payment_status, created_at'),
  );
  final subscriptions = await _countRows(
    'subscriptions',
    column: 'status',
    equals: 'active',
  );

  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month);

  double total = 0, paid = 0, outstanding = 0, thisMonth = 0;
  final perType = <String, double>{};
  for (final r in rows) {
    // A cancelled or refunded charge is money that is not coming, so it is
    // left out of every figure here rather than swelling the total.
    if (r['payment_status'] == 'cancelled' ||
        r['payment_status'] == 'refunded') {
      continue;
    }
    final amount = (r['amount'] as num?)?.toDouble() ?? 0;
    total += amount;
    if (r['payment_status'] == 'paid') {
      paid += amount;
    } else if (r['payment_status'] == 'pending' ||
        r['payment_status'] == 'overdue' ||
        r['payment_status'] == 'partial') {
      outstanding += amount;
    }
    final at = DateTime.tryParse(r['created_at'] as String? ?? '');
    if (at != null && !at.isBefore(monthStart)) thisMonth += amount;
    final type = r['revenue_type'] as String? ?? 'custom';
    perType[type] = (perType[type] ?? 0) + amount;
  }

  final typeEntries = perType.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return AdminRevenueSummary(
    transactions: rows.length,
    total: total,
    paid: paid,
    outstanding: outstanding,
    thisMonth: thisMonth,
    byType: [
      for (final e in typeEntries) {'type': e.key, 'amount': e.value},
    ],
    activeSubscriptions: subscriptions,
  );
});
