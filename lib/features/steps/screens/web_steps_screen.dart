import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/step_entry.dart';
import '../providers/steps_providers.dart';

// ═══════════════════════════════════════════════════════════
// Web Step Counter — desktop layout for /steps
//
// The mobile screen is one 430px column: ring, then chart, then a leaderboard
// behind a two-way tab. On a laptop the ring and today's figures run along the
// top, and the chart sits beside both leaderboards at once — the tab exists on
// the phone only because two tables will not fit side by side there.
// ═══════════════════════════════════════════════════════════

const _kBorder = Color(0xFFE7E7E7);
const _kHeading = Color(0xFF1F1F1F);
const _kGreyText = Color(0xFF6D6D6D);
const _kBarBlue = Color(0xFF216AD0);
const _kRingTrack = Color(0xFFF5F2EF);
const _kHighlight = Color(0xFFF1F6FD);

class WebStepsContent extends ConsumerStatefulWidget {
  const WebStepsContent({super.key});

  @override
  ConsumerState<WebStepsContent> createState() => _WebStepsContentState();
}

class _WebStepsContentState extends ConsumerState<WebStepsContent> {
  bool _isHebrew = false;

  /// The daily target the ring fills against — the same figure the mobile
  /// screen uses.
  static const _goal = 10000;

  /// An average stride, for turning a step count into a distance. It is the
  /// usual figure used for this and is stated as an estimate on screen,
  /// because the app does not know anyone's height.
  static const _metresPerStep = 0.762;

  static const _monthsEn = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const _monthsHe = [
    'ינואר',
    'פברואר',
    'מרץ',
    'אפריל',
    'מאי',
    'יוני',
    'יולי',
    'אוגוסט',
    'ספטמבר',
    'אוקטובר',
    'נובמבר',
    'דצמבר',
  ];

  String _t(String en, String he) => _isHebrew ? he : en;

  String _weekdayShort(DateTime d) => switch (d.weekday) {
    DateTime.monday => _t('Mon', 'ב׳'),
    DateTime.tuesday => _t('Tue', 'ג׳'),
    DateTime.wednesday => _t('Wed', 'ד׳'),
    DateTime.thursday => _t('Thu', 'ה׳'),
    DateTime.friday => _t('Fri', 'ו׳'),
    DateTime.saturday => _t('Sat', 'ש׳'),
    _ => _t('Sun', 'א׳'),
  };

  /// 6842 -> "6,842".
  static String _thousands(int n) {
    final digits = n.toString();
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
      out.write(digits[i]);
    }
    return out.toString();
  }

  /// Consecutive days up to today with any steps recorded.
  int _streak(List<StepEntry> week) {
    var n = 0;
    for (final e in week.reversed) {
      if (e.steps <= 0) break;
      n++;
    }
    return n;
  }

  /// Gold, silver, bronze, then the house colour.
  static Color _rankColour(int rank) => switch (rank) {
    1 => const Color(0xFFFFAC27),
    2 => const Color(0xFFB0B0B0),
    3 => const Color(0xFFC59850),
    _ => AppColors.midBlue,
  };

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isHebrew ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            WebNavbar(
              isHebrew: _isHebrew,
              onToggleLanguage: () => setState(() => _isHebrew = !_isHebrew),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 48),
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildTodayBand(),
                    _buildChallengeBand(),
                    const SizedBox(height: 24),
                    _buildColumns(),
                    const SizedBox(height: 100),
                    WebFooter(isHebrew: _isHebrew),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HEADING
  // ─────────────────────────────────────────────
  Widget _buildHeader() {
    // WebSection centres what it is given, so a column of nothing but text
    // would shrink to the text and sit in the middle of the window.
    return WebSection(
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _t('Step Counter', 'מד צעדים'),
              style: TextStyle(
                fontFamily: AppFonts.nunito,
                fontSize: 40,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _t(
                'Every step makes Modiin better',
                'כל צעד עושה את מודיעין טובה יותר',
              ),
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 16,
                color: _kGreyText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TODAY — the ring, then today's figures beside it
  // ─────────────────────────────────────────────
  Widget _buildTodayBand() {
    final counter = ref.watch(stepCounterProvider);
    final week =
        ref.watch(myStepWeekProvider).valueOrNull ?? const <StepEntry>[];
    final now = DateTime.now();

    // Null until the sensor reports; the ring shows nothing rather than a
    // figure the phone has not given us.
    final steps = counter.today;
    final progress = steps == null ? 0.0 : (steps / _goal).clamp(0.0, 1.0);
    final km = steps == null ? null : (steps * _metresPerStep) / 1000;
    final streak = _streak(week);

    final blocked =
        counter.permission == StepPermission.denied ||
        counter.permission == StepPermission.unsupported;

    return WebSection(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _kBorder),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _t("Today's Progress", 'ההתקדמות היום'),
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _kHeading,
                    ),
                  ),
                ),
                Text(
                  _isHebrew
                      ? '${now.day} ב${_monthsHe[now.month - 1]} ${now.year}'
                      : '${now.day} ${_monthsEn[now.month - 1]} ${now.year}',
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 14,
                    color: const Color(0xFF5D5D5D),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // The counter cannot run without permission, and on a machine
            // with no step sensor it cannot run at all — which is every
            // desktop browser. Both are said plainly instead of a number.
            if (blocked)
              Row(
                children: [
                  const Icon(
                    IconsaxPlusLinear.info_circle,
                    size: 22,
                    color: _kGreyText,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      counter.permission == StepPermission.denied
                          ? _t(
                              'Counting steps needs permission to detect activity',
                              'כדי לספור צעדים צריך אישור לזיהוי פעילות',
                            )
                          : _t(
                              'This device cannot count steps',
                              'המכשיר הזה לא תומך בספירת צעדים',
                            ),
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 15,
                        height: 1.4,
                        color: _kGreyText,
                      ),
                    ),
                  ),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 196,
                    height: 196,
                    child: CustomPaint(
                      painter: _ProgressRingPainter(progress),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              steps == null ? '—' : _thousands(steps),
                              style: TextStyle(
                                fontFamily: AppFonts.inter,
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Opacity(
                              opacity: 0.6,
                              child: Text(
                                _t('steps', 'צעדים'),
                                style: TextStyle(
                                  fontFamily: AppFonts.inter,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF454545),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                  // The three figures the phone can actually answer for.
                  // Calories and active hours used to sit here; body weight
                  // is unknown and the pedometer reports no active time.
                  // IntrinsicHeight because the row is stretched: inside a
                  // scroll view the height is unbounded, and a stretched Row
                  // with no ceiling asks its children to be infinitely tall.
                  Expanded(
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _StatTile(
                              icon: IconsaxPlusLinear.chart_2,
                              label: _t('Of the daily goal', 'מתוך היעד היומי'),
                              value: steps == null
                                  ? '—'
                                  : '${(progress * 100).round()}%',
                              note: _t(
                                '${_thousands(_goal)} steps',
                                '${_thousands(_goal)} צעדים',
                              ),
                              accent: AppColors.midBlue,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _StatTile(
                              icon: IconsaxPlusLinear.flash_1,
                              label: _t('Streak', 'רצף'),
                              value: streak == 0 ? '—' : '$streak',
                              note: streak == 0
                                  ? _t('No days recorded yet', 'עדיין אין ימים')
                                  : (streak == 1
                                        ? _t('day in a row', 'יום ברצף')
                                        : _t('days in a row', 'ימים ברצף')),
                              accent: const Color(0xFFFFAC27),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _StatTile(
                              icon: IconsaxPlusLinear.routing,
                              label: _t('Distance', 'מרחק'),
                              value: km == null ? '—' : km.toStringAsFixed(1),
                              note: km == null
                                  ? _t('Waiting for the counter', 'ממתין למונה')
                                  : _t(
                                      'km · Estimated distance',
                                      'ק״מ · מרחק משוער',
                                    ),
                              accent: AppColors.turquoise,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // MONTHLY CHALLENGE — only when one is running
  // ─────────────────────────────────────────────
  //
  // `challenges` has no rows, so this draws nothing today. What it draws when
  // there is a row comes off the row itself; the mobile card still carries a
  // written-in "walk 150,000 steps" with a written-in progress bar, and that
  // is not repeated here.
  Widget _buildChallengeBand() {
    final challenge = ref.watch(activeChallengeProvider).valueOrNull;
    if (challenge == null) return const SizedBox.shrink();

    final name = (challenge['name'] as String?)?.trim();
    if (name == null || name.isEmpty) return const SizedBox.shrink();
    final description = (challenge['description'] as String?)?.trim();
    final goal = (challenge['goal'] as num?)?.toInt();

    // The participant row is this person's own, because row level security
    // only returns theirs.
    final participants = challenge['challenge_participants'];
    final progress = participants is List && participants.isNotEmpty
        ? ((participants.first as Map)['progress'] as num?)?.toInt()
        : null;
    final fraction = (goal == null || goal <= 0 || progress == null)
        ? null
        : (progress / goal).clamp(0.0, 1.0);
    final progressLabel = (goal == null || progress == null)
        ? null
        : _t(
            '${_thousands(progress)} / ${_thousands(goal)} steps',
            '${_thousands(progress)} / ${_thousands(goal)} צעדים',
          );

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: WebSection(
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFFFDF9F5),
            border: Border.all(color: const Color(0xFFFFE8C3)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('🏆', style: TextStyle(fontSize: 38)),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('MODIIN MONTHLY CHALLENGE', 'אתגר חודשי במודיעין'),
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                        color: AppColors.midBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      style: TextStyle(
                        fontFamily: AppFonts.nunito,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    if (description != null && description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 14,
                          height: 1.45,
                          color: const Color(0xFF454545),
                        ),
                      ),
                    ],
                    if (fraction != null && progressLabel != null) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              progressLabel,
                              style: TextStyle(
                                fontFamily: AppFonts.inter,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          Text(
                            '${(fraction * 100).round()}%',
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF3D3D3D),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          height: 6,
                          child: LinearProgressIndicator(
                            value: fraction,
                            backgroundColor: _kBorder,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFFFC107),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // THE WEEK AND THE TABLES, side by side
  // ─────────────────────────────────────────────
  Widget _buildColumns() {
    return WebSection(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final chart = _buildWeeklyChart();
          final neighborhoods = _buildLeaderboardCard(
            title: _t('By neighborhood', 'לפי שכונה'),
            rows: _buildNeighborhoodRows(),
          );
          final city = _buildLeaderboardCard(
            title: _t('Across the city', 'כל העיר'),
            rows: _buildCityRows(),
          );

          // Three across needs roughly 1300 of content column, which a 1440
          // laptop has. Below that the two tables share one column so that
          // neither is squeezed to the point of ellipsising every name.
          if (constraints.maxWidth >= 1250) {
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 5, child: chart),
                  const SizedBox(width: 24),
                  Expanded(flex: 3, child: neighborhoods),
                  const SizedBox(width: 24),
                  Expanded(flex: 3, child: city),
                ],
              ),
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: chart),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [neighborhoods, const SizedBox(height: 24), city],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _cardShell({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _buildWeeklyChart() {
    final week =
        ref.watch(myStepWeekProvider).valueOrNull ?? const <StepEntry>[];

    final data = [
      for (final e in week)
        _BarData(
          _weekdayShort(e.date),
          e.steps,
          e.steps >= 1000
              ? '${(e.steps / 1000).toStringAsFixed(1)}K'
              : '${e.steps}',
        ),
    ];

    if (data.isEmpty) {
      return _cardShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _chartHeading(),
            const SizedBox(height: 40),
            Center(
              child: Text(
                _t('No step data yet', 'עדיין אין נתוני צעדים'),
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  color: _kGreyText,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      );
    }

    // The scale follows the week's own best day, rounded up to a multiple of
    // 6,000 so that each of the seven axis labels lands on a whole thousand.
    final best = data.map((d) => d.steps).reduce((a, b) => a > b ? a : b);
    final ceiling = best < _goal ? _goal : best;
    final maxSteps = ((ceiling / 6000).ceil() * 6000).toDouble();
    const barMaxH = 260.0;

    final axisLabels = [
      for (var i = 6; i >= 0; i--)
        () {
          final v = (maxSteps * i / 6).round();
          return v >= 1000 ? '${v ~/ 1000}K' : '$v';
        }(),
    ];

    return _cardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _chartHeading(),
          const SizedBox(height: 24),
          SizedBox(
            height: barMaxH + 64,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 34,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 26),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final label in axisLabels)
                          Text(
                            label,
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 12,
                              color: const Color(0xFF888888),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                for (final d in data)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          d.label,
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 24,
                          height: (d.steps / maxSteps) * barMaxH,
                          decoration: BoxDecoration(
                            color: _kBarBlue,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          d.day,
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 12,
                            color: _kGreyText,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The same three-line block the leaderboard cards carry, so the three
  /// columns start their content on the same line.
  Widget _chartHeading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t('YOUR WEEK', 'השבוע שלך'),
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
            color: AppColors.midBlue,
          ),
        ),
        const SizedBox(height: 8),
        _cardTitle(_t('This Week', 'השבוע')),
        const SizedBox(height: 4),
        Text(
          _t('Steps recorded each day', 'צעדים שנספרו בכל יום'),
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 13,
            color: _kGreyText,
          ),
        ),
      ],
    );
  }

  Widget _cardTitle(String text) => Text(
    text,
    style: TextStyle(
      fontFamily: AppFonts.inter,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: _kHeading,
    ),
  );

  Widget _buildLeaderboardCard({
    required String title,
    required List<Widget> rows,
  }) {
    return _cardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The two tables are one thing split in two, so the name sits above
          // each as an overline rather than being printed twice as a heading.
          Text(
            _t('MODIIN STEP CHALLENGE', 'אתגר הצעדים של מודיעין'),
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
              color: AppColors.midBlue,
            ),
          ),
          const SizedBox(height: 8),
          _cardTitle(title),
          const SizedBox(height: 4),
          Text(
            _t(
              'Compete with others and climb the ranks',
              'התחרו מול אחרים וטפסו בדירוג',
            ),
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 13,
              color: _kGreyText,
            ),
          ),
          const SizedBox(height: 20),
          ...rows,
        ],
      ),
    );
  }

  /// The neighbourhood table, from `steps_leaderboard_neighborhoods`, which
  /// only counts people who turned the health-data switch on.
  List<Widget> _buildNeighborhoodRows() {
    final user = ref.watch(authProvider);
    if (user == null) {
      return [
        _note(
          _t('Sign in to see the leaderboard', 'התחברו כדי לראות את הטבלה'),
        ),
      ];
    }

    return ref
        .watch(neighborhoodLeaderboardProvider)
        .when(
          loading: () => const [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
          error: (_, _) => [
            _note(
              _t('Nobody is counting steps yet', 'אף אחד עדיין לא מודד צעדים'),
            ),
          ],
          data: (list) {
            if (list.isEmpty) {
              return [
                _note(
                  _t(
                    'Nobody is counting steps yet',
                    'אף אחד עדיין לא מודד צעדים',
                  ),
                ),
              ];
            }
            return [
              for (final e in list)
                _LeaderRow(
                  rank: e.rank,
                  rankColour: _rankColour(e.rank),
                  name: e.name,
                  steps: _thousands(e.totalSteps),
                  stepsLabel: _t('steps', 'צעדים'),
                  highlighted: e.name == user.neighborhood,
                ),
            ];
          },
        );
  }

  /// The city table, from `steps_leaderboard_people`.
  List<Widget> _buildCityRows() {
    final user = ref.watch(authProvider);
    if (user == null) {
      return [
        _note(
          _t('Sign in to see the leaderboard', 'התחברו כדי לראות את הטבלה'),
        ),
      ];
    }

    return ref
        .watch(peopleLeaderboardProvider)
        .when(
          loading: () => const [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
          error: (_, _) => [
            _note(
              _t('Nobody is counting steps yet', 'אף אחד עדיין לא מודד צעדים'),
            ),
          ],
          data: (list) {
            if (list.isEmpty) {
              // Nobody is listed. If this person has the switch off, that is
              // probably why they are not, so say so.
              return [
                _note(
                  user.healthEnabled
                      ? _t(
                          'Nobody is counting steps yet',
                          'אף אחד עדיין לא מודד צעדים',
                        )
                      : _t(
                          'Turn on health data in Settings to appear in the leaderboard',
                          'הפעילו ״נתוני כושר״ בהגדרות כדי להופיע בטבלה',
                        ),
                ),
              ];
            }
            return [
              for (final e in list)
                _LeaderRow(
                  rank: e.rank,
                  rankColour: _rankColour(e.rank),
                  name: e.name,
                  steps: _thousands(e.totalSteps),
                  stepsLabel: _t('steps', 'צעדים'),
                  avatarUrl: e.avatarUrl,
                  highlighted: e.profileId == user.id,
                ),
            ];
          },
        );
  }

  Widget _note(String message) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 32),
    child: Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: AppFonts.inter,
          fontSize: 14,
          height: 1.4,
          color: _kGreyText,
        ),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════
// One of the three figures beside the ring
// ═══════════════════════════════════════════════

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label, value, note;
  final Color accent;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.note,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.05),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _kGreyText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppFonts.nunito,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              height: 1.1,
              color: accent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            note,
            maxLines: 2,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 12,
              height: 1.35,
              color: const Color(0xFF4F4F4F),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// One table row. The mobile screen has two of these, one with an avatar and
// one without; here the avatar is simply optional.
// ═══════════════════════════════════════════════

class _LeaderRow extends StatelessWidget {
  final int rank;
  final Color rankColour;
  final String name, steps, stepsLabel;
  final String? avatarUrl;
  final bool highlighted;

  const _LeaderRow({
    required this.rank,
    required this.rankColour,
    required this.name,
    required this.steps,
    required this.stepsLabel,
    this.avatarUrl,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: highlighted ? _kHighlight : null,
        border: const Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: rankColour,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (hasAvatar) ...[
            NetworkPhoto(
              url: avatarUrl,
              width: 32,
              height: 32,
              radius: BorderRadius.circular(16),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _kHeading,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            steps,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _kHeading,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            stepsLabel,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 12,
              color: _kGreyText,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// The ring, at desktop size
// ═══════════════════════════════════════════════

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  _ProgressRingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 14.0;
    final radius = (size.width - strokeWidth) / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = _kRingTrack
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..color = _kBarBlue
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter old) =>
      old.progress != progress;
}

class _BarData {
  final String day;
  final int steps;
  final String label;
  const _BarData(this.day, this.steps, this.label);
}
