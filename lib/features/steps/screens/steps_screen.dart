import 'dart:math';
import '../../../core/theme/app_fonts.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

/// Step Counter screen – circular progress ring with daily stats,
/// weekly bar chart, monthly challenge card with progress bar,
/// neighborhood/city leaderboard, and recommended walking routes.
class StepsScreen extends StatefulWidget {
  const StepsScreen({super.key});

  @override
  State<StepsScreen> createState() => _StepsScreenState();
}

class _StepsScreenState extends State<StepsScreen> {
  int _leaderboardTab = 0; // 0 = Neighborhood, 1 = City

  @override
  Widget build(BuildContext context) {
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
                          'Step Counter',
                          style: TextStyle(fontFamily: AppFonts.inter, 
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Every step makes Modiin better',
                          style: TextStyle(fontFamily: AppFonts.inter, 
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

                        _buildMonthlyChallenge(),
                        const SizedBox(height: 16),

                        _buildLeaderboard(),
                        const SizedBox(height: 16),

                        _buildWalkRoutes(),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE7E7E7)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Progress",
                style: TextStyle(fontFamily: AppFonts.inter, 
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F1F1F),
                ),
              ),
              Text(
                'May 13, 2026',
                style: TextStyle(fontFamily: AppFonts.inter, 
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF5D5D5D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 23),

          // Ring + right-side stats
          Row(
            children: [
              // Circular progress ring
              SizedBox(
                width: 137,
                height: 137,
                child: CustomPaint(
                  painter: _ProgressRingPainter(0.6842),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '6,842',
                          style: TextStyle(fontFamily: AppFonts.inter, 
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Opacity(
                          opacity: 0.6,
                          child: Text(
                            'steps',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontFamily: AppFonts.inter, 
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

              // Right stats column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Streak
                    Row(
                      children: [
                        const SizedBox(
                          width: 32,
                          height: 32,
                          child: Center(
                            child: Text('🔥', style: TextStyle(fontSize: 24)),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '5 Streak',
                          style: TextStyle(fontFamily: AppFonts.inter, 
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Percentage of goal
                    Text(
                      '68% of 10,000',
                      style: TextStyle(fontFamily: AppFonts.inter, 
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
          const SizedBox(height: 16),

          // Stats row: kcal | km | hours
          Row(
            children: [
              Expanded(
                child: _StatColumn(
                  value: '862',
                  label: 'kcal',
                  valueColor: const Color(0xFF5630DF),
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: const Color(0xFFD1D1D1).withValues(alpha: 0.7),
              ),
              Expanded(
                child: _StatColumn(
                  value: '7.2',
                  label: 'km',
                  valueColor: const Color(0xFFE57F03),
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: const Color(0xFFD1D1D1).withValues(alpha: 0.7),
              ),
              Expanded(
                child: _StatColumn(
                  value: '2:19',
                  label: 'hours',
                  valueColor: const Color(0xFF286EFD),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Card 2 — This Week (bar chart)
  // ═══════════════════════════════════════════════
  Widget _buildWeeklyChart() {
    const data = <_BarData>[
      _BarData('Mon', 8200, '8.2K'),
      _BarData('Tue', 6400, '6.4K'),
      _BarData('Wed', 8200, '8.2K'),
      _BarData('Thu', 10100, '10.1K'),
      _BarData('Fri', 7800, '7.8K'),
      _BarData('Sat', 6800, '6.8K'),
      _BarData('Sun', 9200, '9.2K'),
    ];
    const double maxSteps = 12000;
    const double barMaxH = 170;

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
            'This Week',
            style: TextStyle(fontFamily: AppFonts.inter, 
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
                      children: ['12K', '10K', '8K', '6K', '4K', '2K', '0']
                          .map((l) => Text(
                                l,
                                style: TextStyle(fontFamily: AppFonts.inter, 
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF888888),
                                ),
                              ))
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
                          style: TextStyle(fontFamily: AppFonts.inter, 
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
                          style: TextStyle(fontFamily: AppFonts.inter, 
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
  Widget _buildMonthlyChallenge() {
    const progress = 82450;
    const goal = 150000;
    final fraction = progress / goal; // ~55%

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
                      'MODIIN MONTHLY CHALLENGE',
                      style: TextStyle(fontFamily: AppFonts.inter, 
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                        color: const Color(0xFF123A72),
                      ),
                    ),
                    const SizedBox(height: 11),
                    Text(
                      'Walk 150,000 steps',
                      style: TextStyle(fontFamily: AppFonts.inter, 
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'this month',
                      style: TextStyle(fontFamily: AppFonts.inter, 
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF454545),
                      ),
                    ),
                    const SizedBox(height: 11),
                    // Prize row
                    Row(
                      children: [
                        const Text('🏅', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Text(
                          'Prize: ₪500 Shopping Voucher',
                          style: TextStyle(fontFamily: AppFonts.inter, 
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
                          '82,450',
                          style: TextStyle(fontFamily: AppFonts.inter, 
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '/ 150,000 steps',
                          style: TextStyle(fontFamily: AppFonts.inter, 
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF454545),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '55%',
                    style: TextStyle(fontFamily: AppFonts.inter, 
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
                  'View Challenge',
                  style: TextStyle(fontFamily: AppFonts.inter, 
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
            'Modiin Step Challenge',
            style: TextStyle(fontFamily: AppFonts.inter, 
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Compete with others and climb the ranks',
            style: TextStyle(fontFamily: AppFonts.inter, 
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6D6D6D),
            ),
          ),
          const SizedBox(height: 16),

          // Tab toggle
          Row(
            children: [
              _buildTabButton('Neighborhood', 0, isLeft: true),
              _buildTabButton('City', 1, isLeft: false),
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
          border: active
              ? null
              : Border.all(color: const Color(0xFFE7E7E7)),
          borderRadius: isLeft
              ? const BorderRadius.horizontal(left: Radius.circular(8))
              : const BorderRadius.horizontal(right: Radius.circular(8)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(fontFamily: AppFonts.inter, 
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: active ? Colors.white : const Color(0xFF6D6D6D),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildNeighborhoodRows() {
    const entries = <_LeaderboardEntry>[
      _LeaderboardEntry(rank: 1, name: 'Moriah', steps: '102,450', color: Color(0xFFFFAC27)),
      _LeaderboardEntry(rank: 2, name: 'Avnei Chen', steps: '98,210', color: Color(0xFFB0B0B0)),
      _LeaderboardEntry(rank: 3, name: 'The Birds', steps: '94,840', color: Color(0xFFC59850)),
    ];

    return [
      ...entries.map((e) => _NeighborhoodRow(entry: e)),
      // User's row (highlighted)
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: const BoxDecoration(
          color: Color(0xFFF1F6FD),
        ),
        child: Row(
          children: [
            _RankBadge(rank: 12, color: const Color(0xFF123A72)),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                'You (Modiin Center)',
                style: TextStyle(fontFamily: AppFonts.inter, 
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF123A72),
                ),
              ),
            ),
            Text(
              '48,620',
              style: TextStyle(fontFamily: AppFonts.inter, 
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F1F1F),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'steps',
              style: TextStyle(fontFamily: AppFonts.inter, 
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6D6D6D),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildCityRows() {
    const entries = <_CityLeaderboardEntry>[
      _CityLeaderboardEntry(rank: 1, name: 'Daniel Cohen', steps: '82,478', color: Color(0xFFFFAC27)),
      _CityLeaderboardEntry(rank: 2, name: 'Maya Levi', steps: '75,105', color: Color(0xFFB0B0B0)),
      _CityLeaderboardEntry(rank: 3, name: 'Amit May', steps: '71,589', color: Color(0xFFC59850)),
    ];

    return [
      ...entries.map((e) => _CityRow(entry: e)),
      // User's row (highlighted)
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: const BoxDecoration(
          color: Color(0xFFF1F6FD),
        ),
        child: Row(
          children: [
            _RankBadge(rank: 12, color: const Color(0xFF123A72)),
            const SizedBox(width: 11),
            // Avatar placeholder
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0058B5), Color(0xFF010A36)],
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                'You (Modiin Center)',
                style: TextStyle(fontFamily: AppFonts.inter, 
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF123A72),
                ),
              ),
            ),
            Text(
              '48,620',
              style: TextStyle(fontFamily: AppFonts.inter, 
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F1F1F),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'steps',
              style: TextStyle(fontFamily: AppFonts.inter, 
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6D6D6D),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  // ═══════════════════════════════════════════════
  // Card 5 — Walk Modiin (walking routes)
  // ═══════════════════════════════════════════════
  Widget _buildWalkRoutes() {
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
          Text(
            'Walk Modiin',
            style: TextStyle(fontFamily: AppFonts.inter, 
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Recommended walking routes',
            style: TextStyle(fontFamily: AppFonts.inter, 
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6D6D6D),
            ),
          ),
          const SizedBox(height: 8),

          // Route 1
          _RouteCard(
            title: 'Modiin Park → City Center',
            distance: '4.2 km',
            duration: '50 min',
            steps: '+4,800 steps',
          ),

          // Route 2
          _RouteCard(
            title: 'Anava Lake Loop',
            distance: '3.6 km',
            duration: '40 min',
            steps: '+4,200 steps',
            showBorder: false,
          ),
        ],
      ),
    );
  }
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
          style: TextStyle(fontFamily: AppFonts.inter, 
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
            style: TextStyle(fontFamily: AppFonts.inter, 
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
  final double steps;
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
  const _CityLeaderboardEntry({
    required this.rank,
    required this.name,
    required this.steps,
    required this.color,
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
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$rank',
          style: TextStyle(fontFamily: AppFonts.inter, 
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
  const _NeighborhoodRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE7E7E7))),
      ),
      child: Row(
        children: [
          _RankBadge(rank: entry.rank, color: entry.color),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              entry.name,
              style: TextStyle(fontFamily: AppFonts.inter, 
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1F1F1F),
              ),
            ),
          ),
          Text(
            entry.steps,
            style: TextStyle(fontFamily: AppFonts.inter, 
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'steps',
            style: TextStyle(fontFamily: AppFonts.inter, 
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
  const _CityRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE7E7E7))),
      ),
      child: Row(
        children: [
          _RankBadge(rank: entry.rank, color: entry.color),
          const SizedBox(width: 11),
          // Avatar placeholder
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFD9D9D9),
            ),
            child: Center(
              child: Text(
                entry.name.split(' ').map((w) => w[0]).join(),
                style: TextStyle(fontFamily: AppFonts.inter, 
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
              style: TextStyle(fontFamily: AppFonts.inter, 
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1F1F1F),
              ),
            ),
          ),
          Text(
            entry.steps,
            style: TextStyle(fontFamily: AppFonts.inter, 
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'steps',
            style: TextStyle(fontFamily: AppFonts.inter, 
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

class _RouteCard extends StatelessWidget {
  final String title;
  final String distance;
  final String duration;
  final String steps;
  final bool showBorder;

  const _RouteCard({
    required this.title,
    required this.distance,
    required this.duration,
    required this.steps,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: showBorder
            ? const Border(bottom: BorderSide(color: Color(0xFFE7E7E7)))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Container(
            width: 95,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0058B5), Color(0xFF010A36)],
              ),
            ),
            child: const Center(
              child: Icon(
                IconsaxPlusLinear.map_1,
                size: 28,
                color: Colors.white54,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontFamily: AppFonts.inter, 
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0A1230),
                  ),
                ),
                const SizedBox(height: 9),
                // Detail rows
                Row(
                  children: [
                    // Distance
                    const Icon(
                      IconsaxPlusLinear.location,
                      size: 14,
                      color: Color(0xFF6D6D6D),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      distance,
                      style: TextStyle(fontFamily: AppFonts.inter, 
                        fontSize: 12,
                        color: const Color(0xFF6D6D6D),
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Duration
                    const Icon(
                      IconsaxPlusLinear.clock,
                      size: 14,
                      color: Color(0xFF6D6D6D),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      duration,
                      style: TextStyle(fontFamily: AppFonts.inter, 
                        fontSize: 12,
                        color: const Color(0xFF6D6D6D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                // Steps
                Row(
                  children: [
                    const Icon(
                      IconsaxPlusLinear.activity,
                      size: 14,
                      color: Color(0xFF6D6D6D),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      steps,
                      style: TextStyle(fontFamily: AppFonts.inter, 
                        fontSize: 12,
                        color: const Color(0xFF6D6D6D),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
