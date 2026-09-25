import 'dart:math';
import '../../../core/theme/app_fonts.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/month_names.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/step_entry.dart';
import '../providers/steps_providers.dart';
import 'web_steps_screen.dart';

/// Step Counter screen – circular progress ring with daily stats,
/// weekly bar chart, monthly challenge card with progress bar,
/// neighborhood/city leaderboard, and recommended walking routes.
class StepsScreen extends ConsumerStatefulWidget {
  const StepsScreen({super.key});

  @override
  ConsumerState<StepsScreen> createState() => _StepsScreenState();
}

class _StepsScreenState extends ConsumerState<StepsScreen> {
  int _leaderboardTab = 0; // 0 = Neighborhood, 1 = City

  /// The daily target the ring fills against.
  static const _goal = 10000;

  /// An average stride, for turning a step count into a distance. It is the
  /// usual figure used for this and is stated as an estimate on screen,
  /// because the app does not know anyone's height.
  static const _metresPerStep = 0.762;

  /// Consecutive days up to today with any steps recorded.
  ///
  /// The card said "5 Streak" to everybody. This counts.
  int _streak(List<StepEntry> week) {
    var n = 0;
    for (final e in week.reversed) {
      if (e.steps <= 0) break;
      n++;
    }
    return n;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) return const WebStepsContent();
        return _buildMobile();
      },
    );
  }

  Widget _buildMobile() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // ═══════════════════════════════════
                // Back button (left-aligned)
                // ═══════════════════════════════════
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => context.pop(),
                      child: const SizedBox(
                        width: 24,
                        height: 24,
                        child: Icon(
                          IconsaxPlusLinear.arrow_left,
                          size: 24,
                          color: Color(0xFF3D3D3D),
                        ),
                      ),
                    ),
                  ),
                ),

                // ═══════════════════════════════════
                // Scrollable content
                // ═══════════════════════════════════
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),

                        // ── Title + subtitle ──
                        Text(
                          L.of(context).stepCounter,
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          L.of(context).everyStepBetter,
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF6D6D6D),
                          ),
                        ),
                        const SizedBox(height: 20),

                        _buildTodayProgress(),
                        const SizedBox(height: 16),

                        _buildWeeklyChart(),
                        const SizedBox(height: 16),

                        if (ref.watch(activeChallengeProvider).valueOrNull !=
                            null) ...[
                          _buildMonthlyChallenge(),
                          const SizedBox(height: 16),
                        ],

                        _buildLeaderboard(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Card 1 — Today's Progress
  // ═══════════════════════════════════════════════
  Widget _buildTodayProgress() {
    final l = L.of(context);
    final counter = ref.watch(stepCounterProvider);
    final week =
        ref.watch(myStepWeekProvider).valueOrNull ?? const <StepEntry>[];
    final now = DateTime.now();

    // Null until the sensor reports; the ring shows nothing rather than a
    // figure the phone has not given us.
    final steps = counter.today;
    final progress = steps == null ? 0.0 : (steps / _goal).clamp(0.0, 1.0);
    final km = steps == null ? null : (steps * _metresPerStep) / 1000;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE7E7E7)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l.todaysProgress,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F1F1F),
                ),
              ),
              Text(
                '${now.day} ${l.monthLong(now.month)} ${now.year}',
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  color: const Color(0xFF5D5D5D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 23),

          // The counter cannot run without permission, and on a phone with
          // no step sensor it cannot run at all. Both are said plainly
          // instead of showing a number.
          if (counter.permission == StepPermission.denied ||
              counter.permission == StepPermission.unsupported)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                children: [
                  const Icon(
                    IconsaxPlusLinear.info_circle,
                    size: 20,
                    color: Color(0xFF6D6D6D),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      counter.permission == StepPermission.denied
                          ? l.stepsPermissionNeeded
                          : l.stepsUnsupported,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 13,
                        color: const Color(0xFF6D6D6D),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Row(
              children: [
                SizedBox(
                  width: 137,
                  height: 137,
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
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Opacity(
                            opacity: 0.6,
                            child: Text(
                              l.stepsUnit,
                              style: TextStyle(
                                fontFamily: AppFonts.inter,
                                fontSize: 12.6,
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
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Builder(
                        builder: (_) {
                          final streak = _streak(week);
                          if (streak == 0) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: Center(
                                    child: Text(
                                      '🔥',
                                      style: TextStyle(fontSize: 24),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  l.streakDays(streak),
                                  style: TextStyle(
                                    fontFamily: AppFonts.inter,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      if (steps != null)
                        Text(
                          l.percentOfGoal(
                            (progress * 100).round(),
                            _thousands(_goal),
                          ),
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF123A72),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            // Distance only. The card also claimed calories and active
            // hours; calories depend on body weight, which the app does not
            // know, and the pedometer reports no active time at all.
            if (km != null) ...[
              const SizedBox(height: 16),
              _StatColumn(
                value: km.toStringAsFixed(1),
                label: '${l.kmUnit} · ${l.distanceEstimate}',
                valueColor: const Color(0xFF17A9D0),
              ),
            ],
          ],
        ],
      ),
    );
  }

  /// 1 = Monday, as DateTime.weekday numbers them.
  static String _weekdayShort(L l, DateTime d) => switch (d.weekday) {
    DateTime.monday => l.weekdayMon,
    DateTime.tuesday => l.weekdayTue,
    DateTime.wednesday => l.weekdayWed,
    DateTime.thursday => l.weekdayThu,
    DateTime.friday => l.weekdayFri,
    DateTime.saturday => l.weekdaySat,
    _ => l.weekdaySun,
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

  // ═══════════════════════════════════════════════
  // Card 2 — This Week (bar chart)
  // ═══════════════════════════════════════════════
  Widget _buildWeeklyChart() {
    final l = L.of(context);
    final week =
        ref.watch(myStepWeekProvider).valueOrNull ?? const <StepEntry>[];

    // Seven fixed bars — 8.2K, 6.4K, 10.1K and so on — used to be written
    // into this method. These are the rows, with a bar at zero for a day
    // with nothing recorded rather than a gap.
    final data = [
      for (final e in week)
        _BarData(
          _weekdayShort(l, e.date),
          e.steps,
          e.steps >= 1000
              ? '${(e.steps / 1000).toStringAsFixed(1)}K'
              : '${e.steps}',
        ),
    ];

    if (data.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE7E7E7)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            l.noStepsYet,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 13,
              color: const Color(0xFF6D6D6D),
            ),
          ),
        ),
      );
    }

    // The scale follows the week's own best day, so a quiet week is not all
    // stubs against a fixed 12,000 ceiling. The axis used to be a fixed
    // 12K–0 list while the bars scaled, so a bar did not line up with its
    // own gridline.
    //
    // The ceiling rounds up to a multiple of 6,000 because the axis draws
    // seven labels — six gaps — so every label lands on a whole thousand.
    // A week under the 10,000 goal therefore tops out at 12K, which is the
    // scale the design drew.
    final best = data.map((d) => d.steps).reduce((a, b) => a > b ? a : b);
    final ceiling = best < _goal ? _goal : best;
    final maxSteps = ((ceiling / 6000).ceil() * 6000).toDouble();
    const double barMaxH = 170;

    final axisLabels = [
      for (var i = 6; i >= 0; i--)
        () {
          final v = (maxSteps * i / 6).round();
          return v >= 1000 ? '${v ~/ 1000}K' : '$v';
        }(),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE7E7E7)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            l.thisWeek,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 16),

          // Chart area
          SizedBox(
            height: barMaxH + 60,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Y-axis labels
                SizedBox(
                  width: 28,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 15, bottom: 23),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: axisLabels
                          .map(
                            (l) => Text(
                              l,
                              style: TextStyle(
                                fontFamily: AppFonts.inter,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF888888),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Bars
                ...data.map((d) {
                  final barH = (d.steps / maxSteps) * barMaxH;
                  return Expanded(
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
                          width: 15,
                          height: barH,
                          decoration: BoxDecoration(
                            color: const Color(0xFF216AD0),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          d.day,
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF6D6D6D),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Card 3 — Monthly Challenge
  // ═══════════════════════════════════════════════
  /// Reads the challenge row, not a figure written into this file.
  ///
  /// The card was gated on there being an active challenge, so it draws
  /// nothing today — `challenges` has no rows. But its contents were
  /// "Walk 150,000 steps", "82,450 / 150,000", "55%" and "Prize: ₪500
  /// Shopping Voucher", all written in. The moment the client added a
  /// challenge of their own, the card would have carried its name above
  /// somebody else's numbers.
  Widget _buildMonthlyChallenge() {
    final l = L.of(context);
    final challenge = ref.watch(activeChallengeProvider).valueOrNull;
    if (challenge == null) return const SizedBox.shrink();

    final name = (challenge['name'] as String?)?.trim() ?? '';
    final description = (challenge['description'] as String?)?.trim() ?? '';
    final goal = (challenge['goal'] as num?)?.toInt();

    // Row level security returns only this person's participation row.
    final participants = challenge['challenge_participants'];
    final progress = participants is List && participants.isNotEmpty
        ? ((participants.first as Map)['progress'] as num?)?.toInt()
        : null;
    final fraction = (goal == null || goal <= 0 || progress == null)
        ? null
        : (progress / goal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF9F5),
        border: Border.all(color: const Color(0xFFFFE8C3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Top row: icon + info
          Row(
            children: [
              // Trophy / illustration placeholder
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('🏆', style: TextStyle(fontSize: 40)),
                ),
              ),
              const SizedBox(width: 17),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.monthlyChallenge,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                        color: const Color(0xFF123A72),
                      ),
                    ),
                    const SizedBox(height: 11),
                    Text(
                      name,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF454545),
                      ),
                    ),
                    const SizedBox(height: 11),
                    // Prize row
                    Row(
                      children: [
                        // A "Prize: ₪500 Shopping Voucher" line sat beside
                        // this. `challenges` records no prize.
                        const Text('🏅', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Text(
                          name,
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF454545),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Progress bar section
          Column(
            children: [
              // Steps count + percentage
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          progress == null ? '—' : '$progress',
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          goal == null ? '' : '/ $goal',
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF454545),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    fraction == null
                        ? ''
                        : '${(fraction * 100).round()}%',
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF3D3D3D),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 5,
                  child: LinearProgressIndicator(
                    value: fraction,
                    backgroundColor: const Color(0xFFE7E7E7),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFFFC107),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // View Challenge button
          Container(
            width: double.infinity,
            height: 42,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF123A72)),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l.viewChallenge,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF123A72),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  IconsaxPlusLinear.arrow_right_3,
                  size: 16,
                  color: Color(0xFF123A72),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Card 4 — Modiin Step Challenge (Leaderboard)
  // ═══════════════════════════════════════════════
  Widget _buildLeaderboard() {
    final l = L.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE7E7E7)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            l.stepChallengeTitle,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l.stepChallengeSub,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6D6D6D),
            ),
          ),
          const SizedBox(height: 16),

          // Tab toggle
          Row(
            children: [
              _buildTabButton(l.byNeighborhood, 0, isLeft: true),
              _buildTabButton(l.byCity, 1, isLeft: false),
            ],
          ),
          const SizedBox(height: 16),

          // Rows
          if (_leaderboardTab == 0) ..._buildNeighborhoodRows(),
          if (_leaderboardTab == 1) ..._buildCityRows(),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index, {required bool isLeft}) {
    final active = _leaderboardTab == index;
    return GestureDetector(
      onTap: () => setState(() => _leaderboardTab = index),
      child: Container(
        width: 120,
        height: 36,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF123A72) : Colors.white,
          border: active ? null : Border.all(color: const Color(0xFFE7E7E7)),
          borderRadius: isLeft
              ? const BorderRadius.horizontal(left: Radius.circular(8))
              : const BorderRadius.horizontal(right: Radius.circular(8)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: active ? Colors.white : const Color(0xFF6D6D6D),
            ),
          ),
        ),
      ),
    );
  }

  /// The neighbourhood table.
  ///
  /// Three neighbourhoods with fixed totals used to be written in here, with
  /// a highlighted "You (Modiin Center) — 48,620" row underneath that was the
  /// same for everyone. These come from
  /// `steps_leaderboard_neighborhoods`, which only counts people who turned
  /// the health-data switch on.
  List<Widget> _buildNeighborhoodRows() {
    final l = L.of(context);
    final user = ref.watch(authProvider);
    if (user == null) return [_leaderboardNote(l.leaderboardSignIn)];

    final rows = ref.watch(neighborhoodLeaderboardProvider);
    return rows.when(
      loading: () => const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
      error: (_, _) => [_leaderboardNote(l.leaderboardEmpty)],
      data: (list) {
        if (list.isEmpty) return [_leaderboardNote(l.leaderboardEmpty)];
        return [
          for (final e in list)
            _NeighborhoodRow(
              entry: _LeaderboardEntry(
                rank: e.rank,
                name: e.name,
                steps: _thousands(e.totalSteps),
                color: _rankColour(e.rank),
              ),
              highlighted: e.name == user.neighborhood,
            ),
        ];
      },
    );
  }

  /// The city table.
  ///
  /// This one named three people who do not exist — "Daniel Cohen", "Maya
  /// Levi", "Amit May" — each with a step count beside their name.
  List<Widget> _buildCityRows() {
    final l = L.of(context);
    final user = ref.watch(authProvider);
    if (user == null) return [_leaderboardNote(l.leaderboardSignIn)];

    final rows = ref.watch(peopleLeaderboardProvider);
    return rows.when(
      loading: () => const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
      error: (_, _) => [_leaderboardNote(l.leaderboardEmpty)],
      data: (list) {
        if (list.isEmpty) {
          // Nobody is listed. If this person has the switch off, that is
          // probably why they are not, so say so.
          return [
            _leaderboardNote(
              user.healthEnabled ? l.leaderboardEmpty : l.enableHealthToJoin,
            ),
          ];
        }
        return [
          for (final e in list)
            _CityRow(
              entry: _CityLeaderboardEntry(
                rank: e.rank,
                name: e.name,
                steps: _thousands(e.totalSteps),
                color: _rankColour(e.rank),
                avatarUrl: e.avatarUrl,
              ),
              highlighted: e.profileId == user.id,
            ),
        ];
      },
    );
  }

  /// Gold, silver, bronze, then the house colour.
  static Color _rankColour(int rank) => switch (rank) {
    1 => const Color(0xFFFFAC27),
    2 => const Color(0xFFB0B0B0),
    3 => const Color(0xFFC59850),
    _ => const Color(0xFF123A72),
  };

  Widget _leaderboardNote(String message) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 28),
    child: Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: AppFonts.inter,
          fontSize: 13,
          color: const Color(0xFF6D6D6D),
        ),
      ),
    ),
  );

  // ═══════════════════════════════════════════════
  // Card 5 — Walk Modiin (walking routes)
  // ═══════════════════════════════════════════════
}

// ═══════════════════════════════════════════════════
// Circular progress ring painter
// ═══════════════════════════════════════════════════

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  _ProgressRingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 11.0;
    final radius = (size.width - strokeWidth) / 2;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFF5F2EF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..color = const Color(0xFF216AD0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter old) =>
      old.progress != progress;
}

// ═══════════════════════════════════════════════════
// Stat column (kcal / km / hours)
// ═══════════════════════════════════════════════════

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const _StatColumn({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 4),
        Opacity(
          opacity: 0.6,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF4F4F4F),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════
// Bar chart data model
// ═══════════════════════════════════════════════════

class _BarData {
  final String day;
  final int steps;
  final String label;
  const _BarData(this.day, this.steps, this.label);
}

// ═══════════════════════════════════════════════════
// Leaderboard data models
// ═══════════════════════════════════════════════════

class _LeaderboardEntry {
  final int rank;
  final String name;
  final String steps;
  final Color color;
  const _LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.steps,
    required this.color,
  });
}

class _CityLeaderboardEntry {
  final int rank;
  final String name;
  final String steps;
  final Color color;
  final String? avatarUrl;
  const _CityLeaderboardEntry({
    required this.rank,
    required this.name,
    required this.steps,
    required this.color,
    this.avatarUrl,
  });
}

// ═══════════════════════════════════════════════════
// Rank badge (circular number indicator)
// ═══════════════════════════════════════════════════

class _RankBadge extends StatelessWidget {
  final int rank;
  final Color color;
  const _RankBadge({required this.rank, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(
        child: Text(
          '$rank',
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Neighborhood leaderboard row
// ═══════════════════════════════════════════════════

class _NeighborhoodRow extends StatelessWidget {
  final _LeaderboardEntry entry;
  final bool highlighted;
  const _NeighborhoodRow({required this.entry, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFF1F6FD) : null,
        border: const Border(bottom: BorderSide(color: Color(0xFFE7E7E7))),
      ),
      child: Row(
        children: [
          _RankBadge(rank: entry.rank, color: entry.color),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              entry.name,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1F1F1F),
              ),
            ),
          ),
          Text(
            entry.steps,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'steps',
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6D6D6D),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// City leaderboard row (with avatar)
// ═══════════════════════════════════════════════════

class _CityRow extends StatelessWidget {
  final _CityLeaderboardEntry entry;
  final bool highlighted;
  const _CityRow({required this.entry, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFF1F6FD) : null,
        border: const Border(bottom: BorderSide(color: Color(0xFFE7E7E7))),
      ),
      child: Row(
        children: [
          _RankBadge(rank: entry.rank, color: entry.color),
          const SizedBox(width: 11),
          if (entry.avatarUrl != null && entry.avatarUrl!.isNotEmpty)
            NetworkPhoto(
              url: entry.avatarUrl,
              width: 32,
              height: 32,
              radius: BorderRadius.circular(16),
            )
          else
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFD9D9D9),
              ),
              child: Center(
                child: Text(
                  // A one-word name has one initial; splitting and taking the
                  // first letter of each word crashed on an empty name.
                  entry.name.isEmpty ? '?' : entry.name[0],
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              entry.name,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1F1F1F),
              ),
            ),
          ),
          Text(
            entry.steps,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'steps',
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6D6D6D),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Walking route card
// ═══════════════════════════════════════════════════
