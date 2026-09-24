import 'dart:math';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/models/user_model.dart';
import '../../businesses/models/business.dart';
import '../../businesses/models/review.dart';
import '../../news/models/article.dart';
import '../providers/admin_data_provider.dart';
import 'admin_businesses_screen.dart';
import 'admin_articles_screen.dart';
import 'admin_events_screen.dart';
import 'admin_realestate_screen.dart';
import 'admin_categories_screen.dart';
import 'admin_challenges_screen.dart';
import 'admin_tags_screen.dart';
import 'admin_neighborhoods_screen.dart';
import 'admin_media_screen.dart';
import 'admin_offers_screen.dart';
import 'admin_agreements_screen.dart';
import 'admin_revenue_screen.dart';
import 'admin_ad_placements_screen.dart';
import 'admin_campaigns_screen.dart';
import 'admin_comments_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_push_screen.dart';
import 'admin_team_screen.dart';
import 'admin_audit_screen.dart';
import 'admin_trash_screen.dart';
import 'admin_home_builder_screen.dart';
import 'admin_flags_screen.dart';
import 'admin_agents_screen.dart';
import 'admin_analytics_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedSection = 0;

  static final _sections = [
    // ── ראשי ──
    ('סקירה', IconsaxPlusLinear.element_3),
    ('משתמשים', IconsaxPlusLinear.profile_2user),
    // ── תוכן ──
    ('עסקים', IconsaxPlusLinear.shop),
    ('כתבות', IconsaxPlusLinear.document_text),
    ('אירועים', IconsaxPlusLinear.calendar),
    ('נדל"ן', IconsaxPlusLinear.building_3),
    ('מתווכים', IconsaxPlusLinear.profile_circle),
    // ── טקסונומיה ──
    ('קטגוריות', IconsaxPlusLinear.category_2),
    ('תגיות', IconsaxPlusLinear.tag),
    ('שכונות', IconsaxPlusLinear.building),
    ('מדיה', IconsaxPlusLinear.gallery),
    // ── מסחר ופרסום ──
    ('מבצעים', IconsaxPlusLinear.discount_shape),
    ('הסכמים', IconsaxPlusLinear.document),
    ('הכנסות', IconsaxPlusLinear.wallet_3),
    ('מיקומי פרסום', IconsaxPlusLinear.monitor_mobbile),
    ('קמפיינים', IconsaxPlusLinear.magicpen),
    // ── אינטראקציה ──
    ('ביקורות', IconsaxPlusLinear.star),
    ('תגובות', IconsaxPlusLinear.message_text),
    ('דיווחים', IconsaxPlusLinear.flag),
    ('Push', IconsaxPlusLinear.notification),
    ('אתגרים', IconsaxPlusLinear.cup),
    // ── מערכת ──
    ('צוות ניהול', IconsaxPlusLinear.people),
    ('יומן פעולות', IconsaxPlusLinear.clock),
    ('פח מחזור', IconsaxPlusLinear.trash),
    ('בונה דף הבית', IconsaxPlusLinear.element_plus),
    ('Feature Flags', IconsaxPlusLinear.toggle_on_circle),
    ('הגדרות', IconsaxPlusLinear.setting_2),
  ];

  static const _sectionGroups = {
    0: 'ראשי',
    2: 'תוכן',
    6: 'טקסונומיה',
    10: 'מסחר ופרסום',
    15: 'אינטראקציה',
    19: 'מערכת',
  };

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.adminContentBg,
        body: Column(
          children: [
            // ── CRM-style top bar ──
            _AdminTopBar(sectionName: _sections[_selectedSection].$1),
            Expanded(
              child: isWide
                  ? Row(
                      children: [
                        _Sidebar(
                          sections: _sections,
                          selected: _selectedSection,
                          onSelect: (i) => setState(() => _selectedSection = i),
                          sectionGroups: _sectionGroups,
                        ),
                        Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: AppColors.adminContentBg,
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: _buildSection(),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        // Mobile nav chips
                        Container(
                          height: 52,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              bottom: BorderSide(
                                color: AppColors.adminSidebarBorder,
                                width: 1,
                              ),
                            ),
                          ),
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount: _sections.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final (label, icon) = _sections[index];
                              final sel = index == _selectedSection;
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedSection = index),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: sel
                                        ? AppColors.adminActiveBg
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    border: sel
                                        ? null
                                        : Border.all(
                                            color: AppColors.adminSearchBorder,
                                            width: 1,
                                          ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        icon,
                                        size: 16,
                                        color: sel
                                            ? AppColors.midBlue
                                            : AppColors.adminTextLight,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        label,
                                        style: TextStyle(
                                          fontFamily: AppFonts.inter,
                                          fontSize: 13,
                                          fontWeight: sel
                                              ? FontWeight.w500
                                              : FontWeight.w400,
                                          color: sel
                                              ? AppColors.midBlue
                                              : AppColors.adminTextMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Expanded(child: _buildSection()),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection() {
    return switch (_selectedSection) {
      0 => const AdminAnalyticsScreen(),
      1 => const _UsersSection(),
      2 => const AdminBusinessesScreen(),
      3 => const AdminArticlesScreen(),
      4 => const AdminEventsScreen(),
      5 => const AdminRealEstateScreen(),
      6 => const AdminAgentsScreen(),
      7 => const AdminCategoriesScreen(),
      8 => const AdminTagsScreen(),
      9 => const AdminNeighborhoodsScreen(),
      10 => const AdminMediaScreen(),
      11 => const AdminOffersScreen(),
      12 => const AdminAgreementsScreen(),
      13 => const AdminRevenueScreen(),
      14 => const AdminAdPlacementsScreen(),
      15 => const AdminCampaignsScreen(),
      16 => const _ReviewsSection(),
      17 => const AdminCommentsScreen(),
      18 => const AdminReportsScreen(),
      19 => const AdminPushScreen(),
      20 => const AdminChallengesScreen(),
      21 => const AdminTeamScreen(),
      22 => const AdminAuditScreen(),
      23 => const AdminTrashScreen(),
      24 => const AdminHomeBuilderScreen(),
      25 => const AdminFlagsScreen(),
      26 => const _SettingsSection(),
      _ => const SizedBox(),
    };
  }
}

// ─── Top Bar (CRM-style) ───

class _AdminTopBar extends StatelessWidget {
  final String sectionName;
  const _AdminTopBar({required this.sectionName});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.adminSidebarBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Logo area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.navy, AppColors.midBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'M4U',
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ניהול — מודיעין בשבילך',
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.adminTextDark,
                ),
              ),
              Text(
                sectionName,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.adminTextLight,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Search input
          Container(
            width: 260,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.adminSearchBorder, width: 1),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(
                  IconsaxPlusLinear.search_normal,
                  size: 18,
                  color: AppColors.adminTextLight,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'חיפוש...',
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      color: AppColors.adminTextLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Notification bell
          _TopBarButton(
            icon: IconsaxPlusLinear.notification,
            badgeCount: 3,
            onTap: () {},
          ),
          const SizedBox(width: 8),
          // Settings
          _TopBarButton(icon: IconsaxPlusLinear.setting_2, onTap: () {}),
          const SizedBox(width: 16),
          // User avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.midBlue, AppColors.turquoise],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'NL',
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBarButton extends StatelessWidget {
  final IconData icon;
  final int? badgeCount;
  final VoidCallback onTap;
  const _TopBarButton({
    required this.icon,
    this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: AppColors.adminSidebarBorder, width: 1),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(icon, size: 18, color: AppColors.adminTextMedium),
            ),
            if (badgeCount != null)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      '$badgeCount',
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Sidebar (CRM-style) ───

class _Sidebar extends StatelessWidget {
  final List<(String, IconData)> sections;
  final int selected;
  final ValueChanged<int> onSelect;
  final Map<int, String> sectionGroups;

  const _Sidebar({
    required this.sections,
    required this.selected,
    required this.onSelect,
    this.sectionGroups = const {},
  });

  @override
  Widget build(BuildContext context) {
    // Build flat list of widgets: group headers + section tiles
    final items = <Widget>[];
    for (int i = 0; i < sections.length; i++) {
      if (sectionGroups.containsKey(i)) {
        if (i > 0) items.add(const SizedBox(height: 16));
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              sectionGroups[i]!,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.adminTextMedium,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
        items.add(const SizedBox(height: 4));
      }
      final (label, icon) = sections[i];
      final sel = i == selected;
      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelect(i),
              borderRadius: BorderRadius.circular(6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: sel ? AppColors.adminActiveBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      sel ? _getFilledIcon(icon) : icon,
                      size: 18,
                      color: sel ? AppColors.midBlue : AppColors.adminTextLight,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontFamily: AppFonts.rubik,
                          fontSize: 14,
                          fontWeight: sel ? FontWeight.w500 : FontWeight.w400,
                          color: sel
                              ? AppColors.adminTextDark
                              : AppColors.adminTextMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: AppColors.adminSidebarBorder, width: 1),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: items,
      ),
    );
  }

  /// Map linear icons to their bold (filled) counterparts for selected state
  IconData _getFilledIcon(IconData linear) {
    // Common mappings
    final map = <IconData, IconData>{
      IconsaxPlusLinear.element_3: IconsaxPlusBold.element_3,
      IconsaxPlusLinear.profile_2user: IconsaxPlusBold.profile_2user,
      IconsaxPlusLinear.shop: IconsaxPlusBold.shop,
      IconsaxPlusLinear.document_text: IconsaxPlusBold.document_text,
      IconsaxPlusLinear.calendar: IconsaxPlusBold.calendar,
      IconsaxPlusLinear.building_3: IconsaxPlusBold.building_3,
      IconsaxPlusLinear.category_2: IconsaxPlusBold.category_2,
      IconsaxPlusLinear.tag: IconsaxPlusBold.tag,
      IconsaxPlusLinear.building: IconsaxPlusBold.building,
      IconsaxPlusLinear.gallery: IconsaxPlusBold.gallery,
      IconsaxPlusLinear.discount_shape: IconsaxPlusBold.discount_shape,
      IconsaxPlusLinear.document: IconsaxPlusBold.document,
      IconsaxPlusLinear.wallet_3: IconsaxPlusBold.wallet_3,
      IconsaxPlusLinear.monitor_mobbile: IconsaxPlusBold.monitor_mobbile,
      IconsaxPlusLinear.magicpen: IconsaxPlusBold.magicpen,
      IconsaxPlusLinear.star: IconsaxPlusBold.star,
      IconsaxPlusLinear.message_text: IconsaxPlusBold.message_text,
      IconsaxPlusLinear.flag: IconsaxPlusBold.flag,
      IconsaxPlusLinear.notification: IconsaxPlusBold.notification,
      IconsaxPlusLinear.people: IconsaxPlusBold.people,
      IconsaxPlusLinear.clock: IconsaxPlusBold.clock,
      IconsaxPlusLinear.trash: IconsaxPlusBold.trash,
      IconsaxPlusLinear.element_plus: IconsaxPlusBold.element_plus,
      IconsaxPlusLinear.toggle_on_circle: IconsaxPlusBold.toggle_on_circle,
      IconsaxPlusLinear.setting_2: IconsaxPlusBold.setting_2,
    };
    return map[linear] ?? linear;
  }
}

// ─── Overview ───

class _OverviewSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(adminUsersProvider);
    final businesses = ref.watch(adminBusinessesProvider);
    final articles = ref.watch(adminArticlesProvider);
    final reviews = ref.watch(adminReviewsProvider);
    final pending = businesses
        .where((b) => b.status == BusinessStatus.pending)
        .length;
    final isWide = MediaQuery.of(context).size.width > 900;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Header — CRM style
        Text(
          'סקירה כללית',
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppColors.adminTextDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'נתונים בזמן אמת על כל הפעילות באפליקציה',
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 14,
            color: AppColors.adminTextLight,
          ),
        ),
        const SizedBox(height: 24),

        // Top metrics row — scrollable
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _TopMetric(
                'סה"כ משתמשים',
                '${users.length}',
                'רשומים',
                Icons.people,
                AppColors.turquoise,
                null,
              ),
              _TopMetric(
                'החודש',
                '${users.where((u) => u.createdAt.isAfter(DateTime(2026, 8, 1))).length}',
                '↑ 11%',
                Icons.calendar_month,
                AppColors.success,
                '+11%',
              ),
              _TopMetric(
                'השבוע',
                '${reviews.length}',
                'ביקורות',
                Icons.rate_review,
                AppColors.midBlue,
                null,
              ),
              _TopMetric(
                'הכנסות',
                '₪24,500',
                'סה"כ',
                Icons.payments,
                AppColors.gold,
                null,
              ),
              _TopMetric(
                'פעילות החודש',
                '${articles.length + reviews.length + businesses.length}',
                '↑ 32%',
                Icons.trending_up,
                const Color(0xFF8B5CF6),
                '+32%',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Charts row
        if (isWide)
          SizedBox(
            height: 300,
            child: Row(
              children: [
                Expanded(flex: 3, child: _UsersChartCard()),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: _TaskFunnelCard(
                    users: users,
                    businesses: businesses,
                    articles: articles,
                    pending: pending,
                  ),
                ),
              ],
            ),
          )
        else ...[
          SizedBox(height: 280, child: _UsersChartCard()),
          const SizedBox(height: 16),
          SizedBox(
            height: 280,
            child: _TaskFunnelCard(
              users: users,
              businesses: businesses,
              articles: articles,
              pending: pending,
            ),
          ),
        ],
        const SizedBox(height: 24),

        // Bottom row: donut + activity + pending
        if (isWide)
          SizedBox(
            height: 300,
            child: Row(
              children: [
                Expanded(child: _UsersByRoleCard(users: users)),
                const SizedBox(width: 16),
                Expanded(
                  child: _ActivityBreakdownCard(
                    users: users,
                    businesses: businesses,
                    articles: articles,
                    reviews: reviews,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _PendingCard(businesses: businesses, ref: ref),
                ),
              ],
            ),
          )
        else ...[
          SizedBox(height: 280, child: _UsersByRoleCard(users: users)),
          const SizedBox(height: 16),
          SizedBox(
            height: 280,
            child: _ActivityBreakdownCard(
              users: users,
              businesses: businesses,
              articles: articles,
              reviews: reviews,
            ),
          ),
          const SizedBox(height: 16),
          _PendingCard(businesses: businesses, ref: ref),
        ],
        const SizedBox(height: 24),

        // Recent activity
        _RecentActivityCard(reviews: reviews, businesses: businesses),
        const SizedBox(height: 30),
      ],
    );
  }
}

// ─── Top Metric Chip ───

class _TopMetric extends StatelessWidget {
  final String label, value, sub;
  final IconData icon;
  final Color color;
  final String? change;
  const _TopMetric(
    this.label,
    this.value,
    this.sub,
    this.icon,
    this.color,
    this.change,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(left: 15),
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const Spacer(),
              if (change != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (change!.startsWith('+')
                                ? AppColors.success
                                : AppColors.error)
                            .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    change!,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: change!.startsWith('+')
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: AppColors.adminTextDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 12,
              color: AppColors.adminTextLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Line Chart Card ───

class _UsersChartCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _CardShell(
      title: 'רישומים חדשים — 30 יום אחרונים',
      child: Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: 8, top: 12),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 5,
                getDrawingHorizontalLine: (_) => const FlLine(
                  color: AppColors.adminCardBorder,
                  strokeWidth: 0.5,
                ),
              ),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(),
                topTitles: const AxisTitles(),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 5,
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
                    reservedSize: 24,
                    interval: 5,
                    getTitlesWidget: (v, _) {
                      final day = v.toInt() + 1;
                      return Text(
                        '$day/8',
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 10,
                          color: AppColors.adminTextLight,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minY: 0,
              maxY: 25,
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    30,
                    (i) => FlSpot(
                      i.toDouble(),
                      (5 + sin(i * 0.4) * 4 + (i / 6)).clamp(1, 22).toDouble(),
                    ),
                  ),
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: AppColors.midBlue,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.midBlue.withValues(alpha: 0.15),
                        AppColors.midBlue.withValues(alpha: 0.02),
                      ],
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => AppColors.navy,
                  getTooltipItems: (spots) => spots
                      .map(
                        (s) => LineTooltipItem(
                          '${s.y.toInt()} רישומים',
                          TextStyle(
                            fontFamily: AppFonts.inter,
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Task Funnel Card ───

class _TaskFunnelCard extends StatelessWidget {
  final List<UserModel> users;
  final List<Business> businesses;
  final List<Article> articles;
  final int pending;
  const _TaskFunnelCard({
    required this.users,
    required this.businesses,
    required this.articles,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    final published = articles
        .where((a) => a.status == ArticleStatus.published)
        .length;
    final drafts = articles
        .where((a) => a.status == ArticleStatus.draft)
        .length;
    final active = businesses
        .where((b) => b.status == BusinessStatus.active)
        .length;
    final total = pending + drafts + published + active;

    return _CardShell(
      title: 'סטטוס משימות',
      child: Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _FunnelRow('ממתין לטיפול', pending, total, const Color(0xFF8B5CF6)),
            const SizedBox(height: 14),
            _FunnelRow('טיוטות כתבות', drafts, total, AppColors.gold),
            const SizedBox(height: 14),
            _FunnelRow('כתבות מפורסמות', published, total, AppColors.success),
            const SizedBox(height: 14),
            _FunnelRow('עסקים פעילים', active, total, AppColors.turquoise),
            const Spacer(),
            Divider(color: AppColors.border.withValues(alpha: 0.5)),
            Row(
              children: [
                _FunnelStat('$total', 'סה"כ'),
                _FunnelStat(
                  '${total > 0 ? ((published + active) / total * 100).toInt() : 0}%',
                  'אישור',
                ),
                _FunnelStat('+12%', 'מהשבוע שעבר'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FunnelRow extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  const _FunnelRow(this.label, this.count, this.total, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '$count',
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  fontSize: 13,
                  color: AppColors.adminTextDark,
                ),
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: total > 0 ? count / total : 0,
                  backgroundColor: AppColors.adminProgressBg,
                  color: color,
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FunnelStat extends StatelessWidget {
  final String value, label;
  const _FunnelStat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.adminTextDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 12,
              color: AppColors.adminTextLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Donut Chart — Users by Role ───

class _UsersByRoleCard extends StatelessWidget {
  final List<UserModel> users;
  const _UsersByRoleCard({required this.users});

  @override
  Widget build(BuildContext context) {
    final admins = users.where((u) => u.role == UserRole.admin).length;
    final owners = users.where((u) => u.role == UserRole.businessOwner).length;
    final regulars = users.where((u) => u.role == UserRole.user).length;

    return _CardShell(
      title: 'לפי תפקיד',
      subtitle: 'חלוקת המשתמשים',
      child: Expanded(
        child: Row(
          children: [
            Expanded(
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 36,
                  sectionsSpace: 2,
                  sections: [
                    PieChartSectionData(
                      value: regulars.toDouble(),
                      color: AppColors.turquoise,
                      title: '',
                      radius: 28,
                    ),
                    PieChartSectionData(
                      value: owners.toDouble(),
                      color: AppColors.gold,
                      title: '',
                      radius: 28,
                    ),
                    PieChartSectionData(
                      value: admins.toDouble(),
                      color: const Color(0xFF8B5CF6),
                      title: '',
                      radius: 28,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LegendDot(
                  AppColors.turquoise,
                  'תושבים',
                  '$regulars',
                  '${users.isNotEmpty ? (regulars / users.length * 100).toInt() : 0}%',
                ),
                const SizedBox(height: 10),
                _LegendDot(
                  AppColors.gold,
                  'בעלי עסקים',
                  '$owners',
                  '${users.isNotEmpty ? (owners / users.length * 100).toInt() : 0}%',
                ),
                const SizedBox(height: 10),
                _LegendDot(
                  const Color(0xFF8B5CF6),
                  'מנהלים',
                  '$admins',
                  '${users.isNotEmpty ? (admins / users.length * 100).toInt() : 0}%',
                ),
                const SizedBox(height: 14),
                Text(
                  '${users.length}',
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                Text(
                  'סה"כ',
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 11,
                    color: AppColors.grayText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label, count, pct;
  const _LegendDot(this.color, this.label, this.count, this.pct);

  @override
  Widget build(BuildContext context) {
    return Row(
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
        Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontSize: 13,
            color: AppColors.adminTextDark,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$pct ($count)',
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 12,
            color: AppColors.adminTextLight,
          ),
        ),
      ],
    );
  }
}

// ─── Activity Breakdown ───

class _ActivityBreakdownCard extends StatelessWidget {
  final List<UserModel> users;
  final List<Business> businesses;
  final List<Article> articles;
  final List<Review> reviews;
  const _ActivityBreakdownCard({
    required this.users,
    required this.businesses,
    required this.articles,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    final total =
        users.length + businesses.length + articles.length + reviews.length;
    return _CardShell(
      title: 'סוגי פעילות',
      subtitle: 'חלוקה לפי מודולים',
      child: Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ActivityRow('משתמשים', users.length, total, AppColors.turquoise),
            const SizedBox(height: 12),
            _ActivityRow('עסקים', businesses.length, total, AppColors.midBlue),
            const SizedBox(height: 12),
            _ActivityRow('כתבות', articles.length, total, AppColors.success),
            const SizedBox(height: 12),
            _ActivityRow('ביקורות', reviews.length, total, AppColors.gold),
          ],
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final String label;
  final int count, total;
  final Color color;
  const _ActivityRow(this.label, this.count, this.total, this.color);

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (count / total * 100).toInt() : 0;
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontSize: 13,
              color: AppColors.adminTextDark,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: total > 0 ? count / total : 0,
              backgroundColor: AppColors.adminProgressBg,
              color: color,
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$count',
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.adminTextDark,
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 36,
          child: Text(
            '$pct%',
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 12,
              color: AppColors.adminTextLight,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Pending Card ───

class _PendingCard extends StatelessWidget {
  final List<Business> businesses;
  final WidgetRef ref;
  const _PendingCard({required this.businesses, required this.ref});

  @override
  Widget build(BuildContext context) {
    final pending = businesses
        .where((b) => b.status == BusinessStatus.pending)
        .toList();
    return _CardShell(
      title: 'ממתינים לאישור',
      subtitle: '${pending.length} פריטים',
      child: Expanded(
        child: pending.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        IconsaxPlusBold.tick_circle,
                        size: 24,
                        color: AppColors.success.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'אין פריטים ממתינים',
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        color: AppColors.adminTextLight,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                itemCount: pending.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppColors.adminCardBorder),
                itemBuilder: (_, i) {
                  final b = pending[i];
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: const BoxDecoration(
                      border: Border(
                        right: BorderSide(color: AppColors.gold, width: 3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(
                            IconsaxPlusBold.shop,
                            size: 18,
                            color: AppColors.gold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.name,
                                style: TextStyle(
                                  fontFamily: AppFonts.rubik,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.adminTextDark,
                                ),
                              ),
                              Text(
                                b.category,
                                style: TextStyle(
                                  fontFamily: AppFonts.inter,
                                  fontSize: 12,
                                  color: AppColors.adminTextLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => ref
                              .read(adminBusinessesProvider.notifier)
                              .setStatus(b.id, BusinessStatus.active),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 16,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () => ref
                              .read(adminBusinessesProvider.notifier)
                              .setStatus(b.id, BusinessStatus.rejected),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

// ─── Recent Activity Card ───

class _RecentActivityCard extends StatelessWidget {
  final List<Review> reviews;
  final List<Business> businesses;
  const _RecentActivityCard({required this.reviews, required this.businesses});

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      title: 'פעילות אחרונה',
      subtitle: 'ביקורות ורישומים',
      child: Column(
        children: [
          const SizedBox(height: 8),
          ...reviews.take(4).map((r) {
            final bizName =
                businesses
                    .where((b) => b.id == r.businessId)
                    .firstOrNull
                    ?.name ??
                '';
            final accentColor = r.rating >= 4
                ? AppColors.success
                : r.rating >= 3
                ? AppColors.gold
                : AppColors.error;
            return Container(
              margin: const EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: accentColor, width: 3),
                  bottom: const BorderSide(
                    color: AppColors.adminDashBorder,
                    width: 0.5,
                    strokeAlign: BorderSide.strokeAlignCenter,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  // CRM-style: icon square with rounded corners
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Center(
                      child: Icon(
                        IconsaxPlusBold.star,
                        size: 18,
                        color: accentColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${r.userName} העיר על $bizName',
                          style: TextStyle(
                            fontFamily: AppFonts.rubik,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.adminTextDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          r.text ?? '',
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 12,
                            color: AppColors.adminTextLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          IconsaxPlusBold.star_1,
                          size: 12,
                          color: accentColor,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${r.rating}',
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Card Shell ───

class _CardShell extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  const _CardShell({required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.adminCardBorder, width: 1),
        boxShadow: const [BoxShadow(color: Color(0x0DB8B8B8), blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.adminTextDark,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 12,
                color: AppColors.adminTextLight,
              ),
            ),
          ],
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

// ─── Users Section ───

class _UsersSection extends ConsumerStatefulWidget {
  const _UsersSection();
  @override
  ConsumerState<_UsersSection> createState() => _UsersSectionState();
}

class _UsersSectionState extends ConsumerState<_UsersSection> {
  String _search = '';
  UserRole? _roleFilter;

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(adminUsersProvider);
    var filtered = users.where((u) {
      if (_search.isNotEmpty &&
          !u.name.contains(_search) &&
          !u.phone.contains(_search) &&
          !u.email.contains(_search))
        return false;
      if (_roleFilter != null && u.role != _roleFilter) return false;
      return true;
    }).toList();

    return Column(
      children: [
        // ── CRM-style header bar ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: AppColors.adminCardBorder, width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.adminSearchBorder,
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'חיפוש לפי שם, טלפון, אימייל...',
                      hintStyle: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 14,
                        color: AppColors.adminTextLight,
                      ),
                      prefixIcon: Icon(
                        IconsaxPlusLinear.search_normal,
                        size: 18,
                        color: AppColors.adminTextLight,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.adminSearchBorder,
                    width: 1,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<UserRole?>(
                    value: _roleFilter,
                    hint: Text(
                      'תפקיד',
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 14,
                        color: AppColors.adminTextMedium,
                      ),
                    ),
                    icon: Icon(
                      IconsaxPlusLinear.arrow_down_1,
                      size: 16,
                      color: AppColors.adminTextLight,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text(
                          'הכל',
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      ...UserRole.values.map(
                        (r) => DropdownMenuItem(
                          value: r,
                          child: Text(
                            switch (r) {
                              UserRole.admin => 'מנהל',
                              UserRole.businessOwner => 'בעל עסק',
                              UserRole.user => 'תושב',
                            },
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _roleFilter = v),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 40,
                child: FilledButton.icon(
                  onPressed: () => _showUserDialog(context, ref),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(
                    'משתמש חדש',
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.midBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // ── User list ──
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(0),
            itemCount: filtered.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppColors.adminCardBorder),
            itemBuilder: (context, i) {
              final u = filtered[i];
              return Container(
                color: Colors.white,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 4,
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: u.isBanned
                          ? AppColors.error.withValues(alpha: 0.1)
                          : AppColors.midBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Center(
                      child: Text(
                        u.initials,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          color: u.isBanned
                              ? AppColors.error
                              : AppColors.midBlue,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(
                        u.name,
                        style: TextStyle(
                          fontFamily: AppFonts.rubik,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: AppColors.adminTextDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _RoleBadge(u.role),
                      if (u.isBanned) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'חסום',
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 11,
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    '${u.phone} • ${u.email} • ${u.neighborhood ?? "—"}',
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 12,
                      color: AppColors.adminTextLight,
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) => _handleUserAction(v, u),
                    icon: Icon(
                      IconsaxPlusLinear.more,
                      size: 20,
                      color: AppColors.adminTextLight,
                    ),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(
                          'עריכה',
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'ban',
                        child: Text(
                          u.isBanned ? 'בטל חסימה' : 'חסום משתמש',
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'makeBusinessOwner',
                        child: Text(
                          'הפוך לבעל עסק',
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'מחק',
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 14,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                  onTap: () => _showUserDialog(context, ref, user: u),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _handleUserAction(String action, UserModel user) {
    final notifier = ref.read(adminUsersProvider.notifier);
    switch (action) {
      case 'ban':
        notifier.toggleBan(user.id);
      case 'makeBusinessOwner':
        notifier.setRole(user.id, UserRole.businessOwner);
      case 'delete':
        notifier.remove(user.id);
    }
  }
}

// ─── Businesses Section ───

class _BusinessesSection extends ConsumerStatefulWidget {
  const _BusinessesSection();
  @override
  ConsumerState<_BusinessesSection> createState() => _BusinessesSectionState();
}

class _BusinessesSectionState extends ConsumerState<_BusinessesSection> {
  String _search = '';
  BusinessStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final businesses = ref.watch(adminBusinessesProvider);
    var filtered = businesses.where((b) {
      if (_search.isNotEmpty &&
          !b.name.contains(_search) &&
          !b.category.contains(_search))
        return false;
      if (_statusFilter != null && b.status != _statusFilter) return false;
      return true;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'חיפוש עסק...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<BusinessStatus?>(
                value: _statusFilter,
                hint: Text(
                  'סטטוס',
                  style: TextStyle(fontFamily: AppFonts.rubik),
                ),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(
                      'הכל',
                      style: TextStyle(fontFamily: AppFonts.rubik),
                    ),
                  ),
                  ...BusinessStatus.values.map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(switch (s) {
                        BusinessStatus.active => 'פעיל',
                        BusinessStatus.pending => 'ממתין',
                        BusinessStatus.suspended => 'מושהה',
                        BusinessStatus.rejected => 'נדחה',
                      }, style: TextStyle(fontFamily: AppFonts.rubik)),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _statusFilter = v),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () => _showBusinessDialog(context, ref),
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  'עסק חדש',
                  style: TextStyle(fontFamily: AppFonts.rubik),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.turquoise,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final b = filtered[i];
              return ListTile(
                leading: Icon(Icons.store, color: _statusColor(b.status)),
                title: Row(
                  children: [
                    Flexible(
                      child: Text(
                        b.name,
                        style: TextStyle(
                          fontFamily: AppFonts.rubik,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(b.statusLabel, _statusColor(b.status)),
                  ],
                ),
                subtitle: Text(
                  '${b.category} • ${b.address} • slug: ${b.slug.isEmpty ? "—" : b.slug}',
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 12,
                    color: AppColors.grayText,
                  ),
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) => _handleBusinessAction(v, b),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('עריכה')),
                    if (b.status != BusinessStatus.active)
                      const PopupMenuItem(
                        value: 'activate',
                        child: Text('אשר'),
                      ),
                    if (b.status != BusinessStatus.suspended)
                      const PopupMenuItem(
                        value: 'suspend',
                        child: Text('השהה'),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'מחק',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
                onTap: () => _showBusinessDialog(context, ref, business: b),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _statusColor(BusinessStatus s) => switch (s) {
    BusinessStatus.active => AppColors.success,
    BusinessStatus.pending => AppColors.gold,
    BusinessStatus.suspended => AppColors.error,
    BusinessStatus.rejected => AppColors.grayLight,
  };

  void _handleBusinessAction(String action, Business biz) {
    final notifier = ref.read(adminBusinessesProvider.notifier);
    switch (action) {
      case 'edit':
        _showBusinessDialog(context, ref, business: biz);
      case 'activate':
        notifier.setStatus(biz.id, BusinessStatus.active);
      case 'suspend':
        notifier.setStatus(biz.id, BusinessStatus.suspended);
      case 'delete':
        notifier.remove(biz.id);
    }
  }
}

// ─── Articles Section ───

class _ArticlesSection extends ConsumerStatefulWidget {
  const _ArticlesSection();
  @override
  ConsumerState<_ArticlesSection> createState() => _ArticlesSectionState();
}

class _ArticlesSectionState extends ConsumerState<_ArticlesSection> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final articles = ref.watch(adminArticlesProvider);
    var filtered = articles
        .where(
          (a) =>
              _search.isEmpty ||
              a.title.contains(_search) ||
              a.slug.contains(_search),
        )
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'חיפוש כתבה...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () => _showArticleDialog(context, ref),
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  'כתבה חדשה',
                  style: TextStyle(fontFamily: AppFonts.rubik),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.turquoise,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final a = filtered[i];
              return ListTile(
                leading: Icon(
                  a.status == ArticleStatus.published
                      ? Icons.public
                      : a.status == ArticleStatus.draft
                      ? Icons.edit_note
                      : Icons.archive,
                  color: a.status == ArticleStatus.published
                      ? AppColors.success
                      : a.status == ArticleStatus.draft
                      ? AppColors.gold
                      : AppColors.grayLight,
                ),
                title: Row(
                  children: [
                    Flexible(
                      child: Text(
                        a.title,
                        style: TextStyle(
                          fontFamily: AppFonts.rubik,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(
                      a.status == ArticleStatus.published
                          ? 'פורסם'
                          : a.status == ArticleStatus.draft
                          ? 'טיוטה'
                          : 'ארכיון',
                      a.status == ArticleStatus.published
                          ? AppColors.success
                          : a.status == ArticleStatus.draft
                          ? AppColors.gold
                          : AppColors.grayLight,
                    ),
                    if (a.isFeatured) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.star, size: 16, color: AppColors.gold),
                    ],
                  ],
                ),
                subtitle: Text(
                  'slug: ${a.slug.isEmpty ? "—" : a.slug} • ${a.category.label} • ${a.viewCount} צפיות • meta: ${a.metaDescription?.isNotEmpty == true ? "✓" : "✗"}',
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 12,
                    color: AppColors.grayText,
                  ),
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) => _handleArticleAction(v, a),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('עריכה')),
                    if (a.status != ArticleStatus.published)
                      const PopupMenuItem(
                        value: 'publish',
                        child: Text('פרסם'),
                      ),
                    if (a.status != ArticleStatus.draft)
                      const PopupMenuItem(
                        value: 'draft',
                        child: Text('החזר לטיוטה'),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'מחק',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
                onTap: () => _showArticleDialog(context, ref, article: a),
              );
            },
          ),
        ),
      ],
    );
  }

  void _handleArticleAction(String action, Article a) {
    final notifier = ref.read(adminArticlesProvider.notifier);
    switch (action) {
      case 'edit':
        _showArticleDialog(context, ref, article: a);
      case 'publish':
        notifier.setStatus(a.id, ArticleStatus.published);
      case 'draft':
        notifier.setStatus(a.id, ArticleStatus.draft);
      case 'delete':
        notifier.remove(a.id);
    }
  }
}

// ─── Reviews Section ───

class _ReviewsSection extends ConsumerWidget {
  const _ReviewsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(adminReviewsProvider);
    final businesses = ref.watch(adminBusinessesProvider);

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: reviews.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final r = reviews[i];
        final bizName =
            businesses.where((b) => b.id == r.businessId).firstOrNull?.name ??
            r.businessId;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: r.rating >= 4
                ? AppColors.success.withValues(alpha: 0.15)
                : r.rating >= 3
                ? AppColors.gold.withValues(alpha: 0.15)
                : AppColors.error.withValues(alpha: 0.15),
            child: Text(
              '${r.rating.toInt()}',
              style: TextStyle(
                fontFamily: AppFonts.rubik,
                fontWeight: FontWeight.w700,
                color: r.rating >= 4
                    ? AppColors.success
                    : r.rating >= 3
                    ? AppColors.gold
                    : AppColors.error,
              ),
            ),
          ),
          title: Text(
            '${r.userName} — $bizName',
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            r.text ?? '',
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontSize: 13,
              color: AppColors.grayText,
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () =>
                ref.read(adminReviewsProvider.notifier).remove(r.id),
          ),
        );
      },
    );
  }
}

// ─── Settings Section ───

class _SettingsSection extends StatelessWidget {
  const _SettingsSection();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'הגדרות אפליקציה',
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.adminTextDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'ניהול הגדרות כלליות של המערכת',
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 14,
            color: AppColors.adminTextLight,
          ),
        ),
        const SizedBox(height: 20),
        _SettingsTile(
          'שם האפליקציה',
          'מודיעין בשבילך',
          IconsaxPlusLinear.mobile,
        ),
        _SettingsTile('גרסה', '1.0.0', IconsaxPlusLinear.info_circle),
        _SettingsTile(
          'התראות Push',
          'פעיל',
          IconsaxPlusLinear.notification,
          statusColor: AppColors.success,
        ),
        _SettingsTile(
          'תחזוקה',
          'כבוי',
          IconsaxPlusLinear.setting_3,
          statusColor: AppColors.adminTextLight,
        ),
        _SettingsTile('מפתח API — מפות', '••••••••', IconsaxPlusLinear.map),
        _SettingsTile(
          'Supabase URL',
          'https://xxx.supabase.co',
          IconsaxPlusLinear.cloud,
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? statusColor;
  const _SettingsTile(this.label, this.value, this.icon, {this.statusColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.adminCardBorder, width: 1),
        boxShadow: const [BoxShadow(color: Color(0x0DB8B8B8), blurRadius: 4)],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.midBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.midBlue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: AppColors.adminTextDark,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (statusColor != null) ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        value,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          color: AppColors.adminTextLight,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            IconsaxPlusLinear.edit_2,
            size: 18,
            color: AppColors.adminTextLight,
          ),
        ],
      ),
    );
  }
}

// ─── Shared Widgets ───

class _MetricCard extends StatelessWidget {
  final String title, value, subtitle;
  final IconData icon;
  final Color color;

  const _MetricCard(
    this.title,
    this.value,
    this.icon,
    this.color,
    this.subtitle,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: AppColors.adminTextDark,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              color: AppColors.adminTextLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final UserRole role;
  const _RoleBadge(this.role);

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (role) {
      UserRole.admin => ('מנהל', AppColors.error),
      UserRole.businessOwner => ('בעל עסק', AppColors.midBlue),
      UserRole.user => ('תושב', AppColors.adminTextLight),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppFonts.inter,
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppFonts.inter,
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ─── Dialogs ───

void _showUserDialog(BuildContext context, WidgetRef ref, {UserModel? user}) {
  final isEdit = user != null;
  final nameC = TextEditingController(text: user?.name ?? '');
  final emailC = TextEditingController(text: user?.email ?? '');
  final phoneC = TextEditingController(text: user?.phone ?? '');
  final neighborhoodC = TextEditingController(text: user?.neighborhood ?? '');
  var role = user?.role ?? UserRole.user;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDState) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(
            isEdit ? 'עריכת משתמש' : 'משתמש חדש',
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameC,
                    decoration: const InputDecoration(labelText: 'שם מלא'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailC,
                    decoration: const InputDecoration(labelText: 'אימייל'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneC,
                    decoration: const InputDecoration(labelText: 'טלפון'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: neighborhoodC,
                    decoration: const InputDecoration(labelText: 'שכונה'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<UserRole>(
                    value: role,
                    decoration: const InputDecoration(labelText: 'תפקיד'),
                    items: UserRole.values
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(switch (r) {
                              UserRole.admin => 'מנהל',
                              UserRole.businessOwner => 'בעל עסק',
                              UserRole.user => 'תושב',
                            }),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setDState(() => role = v!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'ביטול',
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  color: AppColors.adminTextMedium,
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                final notifier = ref.read(adminUsersProvider.notifier);
                if (isEdit) {
                  notifier.update(
                    user!.copyWith(
                      name: nameC.text,
                      email: emailC.text,
                      phone: phoneC.text,
                      neighborhood: neighborhoodC.text,
                      role: role,
                    ),
                  );
                } else {
                  notifier.add(
                    UserModel(
                      id: 'u_${DateTime.now().millisecondsSinceEpoch}',
                      name: nameC.text,
                      email: emailC.text,
                      phone: phoneC.text,
                      neighborhood: neighborhoodC.text,
                      role: role,
                      createdAt: DateTime.now(),
                    ),
                  );
                }
                Navigator.pop(ctx);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.midBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                isEdit ? 'שמור' : 'צור',
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showBusinessDialog(
  BuildContext context,
  WidgetRef ref, {
  Business? business,
}) {
  final isEdit = business != null;
  final nameC = TextEditingController(text: business?.name ?? '');
  final slugC = TextEditingController(text: business?.slug ?? '');
  final categoryC = TextEditingController(text: business?.category ?? '');
  final descC = TextEditingController(text: business?.description ?? '');
  final metaC = TextEditingController(text: business?.metaDescription ?? '');
  final phoneC = TextEditingController(text: business?.phone ?? '');
  final emailC = TextEditingController(text: business?.email ?? '');
  final websiteC = TextEditingController(text: business?.website ?? '');
  final addressC = TextEditingController(text: business?.address ?? '');
  final neighborhoodC = TextEditingController(
    text: business?.neighborhood ?? '',
  );
  final tagsC = TextEditingController(text: business?.tags.join(', ') ?? '');

  showDialog(
    context: context,
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(
          isEdit ? 'עריכת עסק' : 'עסק חדש',
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameC,
                  decoration: const InputDecoration(labelText: 'שם העסק'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: slugC,
                  decoration: const InputDecoration(
                    labelText: 'Slug (URL)',
                    hintText: 'pizza-frago',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: categoryC,
                  decoration: const InputDecoration(labelText: 'קטגוריה'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descC,
                  decoration: const InputDecoration(labelText: 'תיאור'),
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: metaC,
                  decoration: const InputDecoration(
                    labelText: 'Meta Description',
                    hintText: 'תיאור ל-SEO (עד 160 תווים)',
                  ),
                  maxLength: 160,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: phoneC,
                        decoration: const InputDecoration(labelText: 'טלפון'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: emailC,
                        decoration: const InputDecoration(labelText: 'אימייל'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: websiteC,
                  decoration: const InputDecoration(labelText: 'אתר'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: addressC,
                        decoration: const InputDecoration(labelText: 'כתובת'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: neighborhoodC,
                        decoration: const InputDecoration(labelText: 'שכונה'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: tagsC,
                  decoration: const InputDecoration(
                    labelText: 'תגיות (מופרדות בפסיק)',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'ביטול',
              style: TextStyle(
                fontFamily: AppFonts.inter,
                color: AppColors.adminTextMedium,
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              final notifier = ref.read(adminBusinessesProvider.notifier);
              final tags = tagsC.text
                  .split(',')
                  .map((t) => t.trim())
                  .where((t) => t.isNotEmpty)
                  .toList();
              if (isEdit) {
                notifier.update(
                  business!.copyWith(
                    name: nameC.text,
                    slug: slugC.text,
                    category: categoryC.text,
                    description: descC.text,
                    metaDescription: metaC.text,
                    phone: phoneC.text,
                    email: emailC.text,
                    website: websiteC.text,
                    address: addressC.text,
                    neighborhood: neighborhoodC.text,
                    tags: tags,
                  ),
                );
              } else {
                notifier.add(
                  Business(
                    id: 'b_${DateTime.now().millisecondsSinceEpoch}',
                    name: nameC.text,
                    slug: slugC.text,
                    category: categoryC.text,
                    description: descC.text,
                    metaDescription: metaC.text,
                    phone: phoneC.text,
                    email: emailC.text,
                    website: websiteC.text,
                    address: addressC.text,
                    neighborhood: neighborhoodC.text,
                    latitude: 31.897,
                    longitude: 35.010,
                    tags: tags,
                    status: BusinessStatus.active,
                    createdAt: DateTime.now(),
                  ),
                );
              }
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.midBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              isEdit ? 'שמור' : 'צור',
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

void _showArticleDialog(
  BuildContext context,
  WidgetRef ref, {
  Article? article,
}) {
  final isEdit = article != null;
  final titleC = TextEditingController(text: article?.title ?? '');
  final subtitleC = TextEditingController(text: article?.subtitle ?? '');
  final slugC = TextEditingController(text: article?.slug ?? '');
  final bodyC = TextEditingController(text: article?.body ?? '');
  final authorC = TextEditingController(text: article?.author ?? '');
  final metaDescC = TextEditingController(text: article?.metaDescription ?? '');
  final metaKeywordsC = TextEditingController(
    text: article?.metaKeywords ?? '',
  );
  final tagsC = TextEditingController(text: article?.tags.join(', ') ?? '');
  var category = article?.category ?? NewsCategory.municipal;
  var status = article?.status ?? ArticleStatus.draft;
  var isBreaking = article?.isBreaking ?? false;
  var isFeatured = article?.isFeatured ?? false;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDState) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(
            isEdit ? 'עריכת כתבה' : 'כתבה חדשה',
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SizedBox(
            width: 550,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleC,
                    decoration: const InputDecoration(labelText: 'כותרת'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: subtitleC,
                    decoration: const InputDecoration(labelText: 'כותרת משנה'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: slugC,
                    decoration: const InputDecoration(
                      labelText: 'Slug (URL)',
                      hintText: 'my-article-title',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: authorC,
                    decoration: const InputDecoration(labelText: 'כותב'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<NewsCategory>(
                          value: category,
                          decoration: const InputDecoration(
                            labelText: 'קטגוריה',
                          ),
                          items: NewsCategory.values
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c.label),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setDState(() => category = v!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<ArticleStatus>(
                          value: status,
                          decoration: const InputDecoration(labelText: 'סטטוס'),
                          items: [
                            DropdownMenuItem(
                              value: ArticleStatus.draft,
                              child: Text(
                                'טיוטה',
                                style: TextStyle(fontFamily: AppFonts.rubik),
                              ),
                            ),
                            DropdownMenuItem(
                              value: ArticleStatus.published,
                              child: Text(
                                'פורסם',
                                style: TextStyle(fontFamily: AppFonts.rubik),
                              ),
                            ),
                            DropdownMenuItem(
                              value: ArticleStatus.archived,
                              child: Text(
                                'ארכיון',
                                style: TextStyle(fontFamily: AppFonts.rubik),
                              ),
                            ),
                          ],
                          onChanged: (v) => setDState(() => status = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: bodyC,
                    decoration: const InputDecoration(
                      labelText: 'תוכן',
                      alignLabelWithHint: true,
                    ),
                    maxLines: 6,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'SEO',
                    style: TextStyle(
                      fontFamily: AppFonts.rubik,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: metaDescC,
                    decoration: const InputDecoration(
                      labelText: 'Meta Description',
                      hintText: 'תיאור ל-SEO (עד 160 תווים)',
                    ),
                    maxLength: 160,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: metaKeywordsC,
                    decoration: const InputDecoration(
                      labelText: 'Meta Keywords',
                      hintText: 'מופרדות בפסיק',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: tagsC,
                    decoration: const InputDecoration(
                      labelText: 'תגיות (מופרדות בפסיק)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Checkbox(
                        value: isBreaking,
                        onChanged: (v) => setDState(() => isBreaking = v!),
                      ),
                      Text(
                        'מבזק',
                        style: TextStyle(fontFamily: AppFonts.rubik),
                      ),
                      const SizedBox(width: 20),
                      Checkbox(
                        value: isFeatured,
                        onChanged: (v) => setDState(() => isFeatured = v!),
                      ),
                      Text(
                        'מומלץ',
                        style: TextStyle(fontFamily: AppFonts.rubik),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'ביטול',
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  color: AppColors.adminTextMedium,
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                final notifier = ref.read(adminArticlesProvider.notifier);
                final tags = tagsC.text
                    .split(',')
                    .map((t) => t.trim())
                    .where((t) => t.isNotEmpty)
                    .toList();
                if (isEdit) {
                  notifier.update(
                    article!.copyWith(
                      title: titleC.text,
                      subtitle: subtitleC.text,
                      slug: slugC.text,
                      body: bodyC.text,
                      author: authorC.text,
                      category: category,
                      status: status,
                      metaDescription: metaDescC.text,
                      metaKeywords: metaKeywordsC.text,
                      tags: tags,
                      isBreaking: isBreaking,
                      isFeatured: isFeatured,
                      updatedAt: DateTime.now(),
                    ),
                  );
                } else {
                  notifier.add(
                    Article(
                      id: 'a_${DateTime.now().millisecondsSinceEpoch}',
                      title: titleC.text,
                      subtitle: subtitleC.text,
                      slug: slugC.text,
                      body: bodyC.text,
                      author: authorC.text,
                      category: category,
                      publishedAt: DateTime.now(),
                      status: status,
                      metaDescription: metaDescC.text,
                      metaKeywords: metaKeywordsC.text,
                      tags: tags,
                      isBreaking: isBreaking,
                      isFeatured: isFeatured,
                    ),
                  );
                }
                Navigator.pop(ctx);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.midBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                isEdit ? 'שמור' : 'צור',
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
