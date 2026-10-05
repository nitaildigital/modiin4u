import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../admin_language.dart';

/// One business page's statistics, for the client (2 Oct): views by day,
/// week or month, and the clicks on each of its buttons.
///
/// Read through `business_stats` and `business_stats_totals` (migration
/// 00048), which only an administrator may call. Counting began when 00048
/// went live; there is nothing from before.
Future<void> showBusinessStats(BuildContext context, String businessId, String name) {
  return showDialog<void>(
    context: context,
    builder: (_) => Directionality(
      textDirection: adminDir,
      child: _BusinessStatsDialog(businessId: businessId, name: name),
    ),
  );
}

enum _Bucket { day, week, month }

/// What the events are called, in the panel's language, in the order shown.
Map<String, String> get _kinds => {
  'view': tr('צפיות', 'Views'),
  'call': tr('חיוג', 'Calls'),
  'website': tr('אתר', 'Website'),
  'whatsapp': 'WhatsApp',
  'directions': tr('ניווט', 'Directions'),
  'share': tr('שיתוף', 'Shares'),
  'instagram': 'Instagram',
};

class _BusinessStatsDialog extends StatefulWidget {
  final String businessId;
  final String name;
  const _BusinessStatsDialog({required this.businessId, required this.name});

  @override
  State<_BusinessStatsDialog> createState() => _BusinessStatsDialogState();
}

class _BusinessStatsDialogState extends State<_BusinessStatsDialog> {
  _Bucket _bucket = _Bucket.day;
  late Future<_Stats> _stats = _load();

  /// The range each view covers: 30 days by day, 12 weeks by week, 12
  /// months by month — enough bars to read, few enough to fit.
  (DateTime, DateTime) get _range {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (_bucket) {
      _Bucket.day => (today.subtract(const Duration(days: 29)), today),
      _Bucket.week => (today.subtract(Duration(days: 7 * 11 + today.weekday % 7)), today),
      _Bucket.month => (DateTime(today.year - 1, today.month + 1), today),
    };
  }

  static String _date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<_Stats> _load() async {
    final (from, to) = _range;
    final client = SupabaseConfig.client;
    final rows = await client.rpc('business_stats', params: {
      'p_business': widget.businessId,
      'p_from': _date(from),
      'p_to': _date(to),
      'p_bucket': _bucket.name,
    });
    final totals = await client.rpc('business_stats_totals', params: {
      'p_business': widget.businessId,
      'p_from': _date(from),
      'p_to': _date(to),
    });
    return _Stats.from(
      List<Map<String, dynamic>>.from(rows as List),
      List<Map<String, dynamic>>.from(totals as List),
    );
  }

  void _setBucket(_Bucket b) => setState(() {
    _bucket = b;
    _stats = _load();
  });

  /// Every period of the range, oldest first — empty ones too, so the chart
  /// keeps its time axis: two busy days a month apart are not drawn side by
  /// side. Weeks start on Sunday and months on the 1st, as the database
  /// groups them.
  List<DateTime> get _allPeriods {
    final (from, to) = _range;
    DateTime start(DateTime d) => switch (_bucket) {
      _Bucket.day => DateTime(d.year, d.month, d.day),
      _Bucket.week => DateTime(d.year, d.month, d.day - d.weekday % 7),
      _Bucket.month => DateTime(d.year, d.month),
    };
    final out = <DateTime>[];
    for (var p = start(from); !p.isAfter(to);) {
      out.add(p);
      p = switch (_bucket) {
        _Bucket.day => DateTime(p.year, p.month, p.day + 1),
        _Bucket.week => DateTime(p.year, p.month, p.day + 7),
        _Bucket.month => DateTime(p.year, p.month + 1),
      };
    }
    return out;
  }

  /// "5.10" for a day or a week's Sunday, "10.2026" for a month.
  String _label(DateTime d) =>
      _bucket == _Bucket.month ? '${d.month}.${d.year}' : '${d.day}.${d.month}';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('סטטיסטיקות', 'Statistics'),
                          style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.adminTextDark),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.name,
                          style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13, color: AppColors.adminTextLight),
                        ),
                      ],
                    ),
                  ),
                  SegmentedButton<_Bucket>(
                    segments: [
                      ButtonSegment(value: _Bucket.day, label: Text(tr('יום', 'Day'))),
                      ButtonSegment(value: _Bucket.week, label: Text(tr('שבוע', 'Week'))),
                      ButtonSegment(value: _Bucket.month, label: Text(tr('חודש', 'Month'))),
                    ],
                    selected: {_bucket},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) => _setBucket(s.first),
                  ),
                  const SizedBox(width: 8),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                switch (_bucket) {
                  _Bucket.day => tr('30 הימים האחרונים', 'The last 30 days'),
                  _Bucket.week => tr('12 השבועות האחרונים (מיום ראשון)', 'The last 12 weeks (from Sunday)'),
                  _Bucket.month => tr('12 החודשים האחרונים', 'The last 12 months'),
                },
                style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 12, color: AppColors.adminTextLight),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<_Stats>(
                  future: _stats,
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) return _Message(_errorText(snap.error));
                    final stats = snap.data!;
                    if (stats.isEmpty) {
                      return _Message(tr(
                        'עוד לא נרשמו ביקורים בתקופה הזו. הספירה החלה עם העדכון של 00048.',
                        'No visits recorded in this period yet. Counting began with update 00048.',
                      ));
                    }
                    return ListView(
                      children: [
                        _totals(stats),
                        const SizedBox(height: 20),
                        SizedBox(height: 200, child: BarChart(_chart(stats))),
                        const SizedBox(height: 20),
                        _table(stats),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Before 00048 runs the functions do not exist; say so rather than show
  /// a database error.
  String _errorText(Object? e) {
    final s = '$e';
    if (s.contains('business_stats') || s.contains('PGRST202') || s.contains('404')) {
      return tr(
        'הסטטיסטיקות יופעלו עם עדכון מסד הנתונים (00048).',
        'Statistics are switched on with the database update (00048).',
      );
    }
    return tr('לא ניתן לטעון את הסטטיסטיקות.', 'The statistics could not be loaded.');
  }

  Widget _totals(_Stats s) {
    final cards = <(String, String)>[
      (tr('צפיות', 'Views'), '${s.total('view')}'),
      (tr('מבקרים ייחודיים', 'Unique visitors'), '${s.visitors('view')}'),
      for (final k in _kinds.keys.skip(1))
        if (s.total(k) > 0) (_kinds[k]!, '${s.total(k)}'),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final (label, value) in cards)
          Container(
            width: 150,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.adminCardBorder),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 12, color: AppColors.adminTextLight)),
                const SizedBox(height: 6),
                Text(value, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.adminTextDark)),
              ],
            ),
          ),
      ],
    );
  }

  BarChartData _chart(_Stats s) {
    final periods = _allPeriods;
    final top = periods.fold<int>(0, (m, p) => s.at(p, 'view') > m ? s.at(p, 'view') : m);
    final step = top <= 10 ? 2.0 : top <= 50 ? 10.0 : top <= 200 ? 50.0 : 100.0;
    return BarChartData(
      maxY: ((top / step).ceil() + 1) * step,
      barGroups: [
        for (final (i, p) in periods.indexed)
          BarChartGroupData(x: i, barRods: [
            BarChartRodData(
              toY: s.at(p, 'view').toDouble(),
              color: AppColors.turquoise,
              width: periods.length > 20 ? 8 : 16,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
            ),
          ]),
      ],
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(),
        topTitles: const AxisTitles(),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            interval: step,
            getTitlesWidget: (v, _) => Text('${v.toInt()}', style: TextStyle(fontFamily: AppFonts.inter, fontSize: 11, color: AppColors.adminTextLight)),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              // Every bar labelled would crowd 30 days; every fifth reads.
              if (i < 0 || i >= periods.length || (periods.length > 14 && i % 5 != 0)) {
                return const SizedBox.shrink();
              }
              return Text(_label(periods[i]), style: TextStyle(fontFamily: AppFonts.inter, fontSize: 10, color: AppColors.adminTextLight));
            },
          ),
        ),
      ),
      gridData: const FlGridData(drawVerticalLine: false),
      borderData: FlBorderData(show: false),
    );
  }

  Widget _table(_Stats s) {
    final kinds = [for (final k in _kinds.keys.skip(1)) if (s.total(k) > 0) k];
    TextStyle head = TextStyle(fontFamily: AppFonts.rubik, fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.adminTextMedium);
    TextStyle cell = TextStyle(fontFamily: AppFonts.inter, fontSize: 12, color: AppColors.adminTextDark);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 36,
        dataRowMinHeight: 32,
        dataRowMaxHeight: 32,
        columns: [
          DataColumn(label: Text(tr('תקופה', 'Period'), style: head)),
          DataColumn(label: Text(tr('צפיות', 'Views'), style: head), numeric: true),
          DataColumn(label: Text(tr('מבקרים', 'Visitors'), style: head), numeric: true),
          for (final k in kinds) DataColumn(label: Text(_kinds[k]!, style: head), numeric: true),
        ],
        rows: [
          for (final p in s.periods.reversed)
            DataRow(cells: [
              DataCell(Text(_label(p), style: cell)),
              DataCell(Text('${s.at(p, 'view')}', style: cell)),
              DataCell(Text('${s.visitorsAt(p)}', style: cell)),
              for (final k in kinds) DataCell(Text('${s.at(p, k)}', style: cell)),
            ]),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  const _Message(this.text);

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(text, textAlign: TextAlign.center, style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14, color: AppColors.adminTextMedium)),
    ),
  );
}

/// The rows the functions return, arranged for the window.
class _Stats {
  /// period → kind → (total, visitors)
  final Map<DateTime, Map<String, (int, int)>> _byPeriod;
  final Map<String, (int, int)> _totals;

  _Stats._(this._byPeriod, this._totals);

  factory _Stats.from(List<Map<String, dynamic>> rows, List<Map<String, dynamic>> totals) {
    final byPeriod = <DateTime, Map<String, (int, int)>>{};
    for (final r in rows) {
      final p = _day(DateTime.parse(r['period'] as String));
      byPeriod.putIfAbsent(p, () => {})[r['kind'] as String] =
          ((r['total'] as num).toInt(), (r['visitors'] as num).toInt());
    }
    return _Stats._(byPeriod, {
      for (final t in totals)
        t['kind'] as String: ((t['total'] as num).toInt(), (t['visitors'] as num).toInt()),
    });
  }

  bool get isEmpty => _totals.isEmpty;

  /// The periods with anything recorded, oldest first.
  List<DateTime> get periods => _byPeriod.keys.toList()..sort();

  int total(String kind) => _totals[kind]?.$1 ?? 0;
  int visitors(String kind) => _totals[kind]?.$2 ?? 0;
  int at(DateTime p, String kind) => _byPeriod[_day(p)]?[kind]?.$1 ?? 0;
  int visitorsAt(DateTime p) => _byPeriod[_day(p)]?['view']?.$2 ?? 0;

  /// The database sends dates without a time; the chart's periods are local
  /// midnights — the same day either way.
  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
}
