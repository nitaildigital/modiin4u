import '../../../core/theme/app_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/admin_businesses_provider.dart';
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

  /// Where the settings pane sits in [_sections] — the top bar's gear jumps
  /// here rather than doing nothing, which is what it used to do.
  static const _settingsSection = 26;

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
            _AdminTopBar(
              sectionName: _sections[_selectedSection].$1,
              onOpenSettings: () =>
                  setState(() => _selectedSection = _settingsSection),
            ),
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

class _AdminTopBar extends ConsumerWidget {
  final String sectionName;
  final VoidCallback onOpenSettings;
  const _AdminTopBar({
    required this.sectionName,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(authProvider);

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
          // There was a search box here that was a Text, not a field, and a
          // bell carrying a permanent "3". Neither was connected to anything;
          // each section has its own search, which does run.
          _TopBarButton(
            icon: IconsaxPlusLinear.setting_2,
            onTap: onOpenSettings,
          ),
          const SizedBox(width: 16),
          // The signed-in administrator, rather than the initials of the one
          // invented person this panel used to be built around.
          Tooltip(
            message: signedIn?.name ?? 'לא מחובר',
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: signedIn == null
                    ? null
                    : const LinearGradient(
                        colors: [AppColors.midBlue, AppColors.turquoise],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                color: signedIn == null ? AppColors.adminActiveBg : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: signedIn == null
                    ? Icon(
                        IconsaxPlusLinear.profile_circle,
                        size: 18,
                        color: AppColors.adminTextLight,
                      )
                    : Text(
                        signedIn.initials,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
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
  final VoidCallback onTap;
  const _TopBarButton({required this.icon, required this.onTap});

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
        child: Center(
          child: Icon(icon, size: 18, color: AppColors.adminTextMedium),
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

// ─── Users Section ───

/// Residents with an account.
///
/// This listed six invented people and edited them in memory. It reads
/// `profiles` now, and the two controls it offers — editing a profile and
/// banning someone — write to that table.
///
/// The role filter and the "make a business owner" action are gone with the
/// invented rows: `profiles` has no role column. Being an administrator is a
/// row in `admin_users`, which the team section manages, and owning a
/// business is `businesses.owner_id`, which the business editor sets. Nothing
/// here could have set either.
class _UsersSection extends ConsumerStatefulWidget {
  const _UsersSection();
  @override
  ConsumerState<_UsersSection> createState() => _UsersSectionState();
}

class _UsersSectionState extends ConsumerState<_UsersSection> {
  final _searchController = TextEditingController();
  ProfileFilter _filter = ProfileFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncProfiles = ref.watch(adminProfilesProvider);

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
                    controller: _searchController,
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
                    onChanged: (v) => ref
                        .read(adminProfilesProvider.notifier)
                        .setSearch(v.isEmpty ? null : v),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _FilterPill('הכל', _filter == ProfileFilter.all, () {
                _setFilter(ProfileFilter.all);
              }),
              _FilterPill('מאומתים', _filter == ProfileFilter.verified, () {
                _setFilter(ProfileFilter.verified);
              }),
              _FilterPill('חסומים', _filter == ProfileFilter.banned, () {
                _setFilter(ProfileFilter.banned);
              }),
              const SizedBox(width: 12),
              // An account is created when the resident first signs in — that
              // is what puts the row in `auth.users` this table points at. The
              // panel cannot make one, so the button says so rather than
              // opening a form that could not save.
              Tooltip(
                message:
                    'חשבון נוצר כשהתושב נכנס לאפליקציה בפעם הראשונה. '
                    'לא ניתן ליצור משתמש מכאן.',
                child: SizedBox(
                  height: 40,
                  child: FilledButton.icon(
                    onPressed: null,
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
              ),
            ],
          ),
        ),
        // ── User list ──
        Expanded(
          child: asyncProfiles.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _AdminError(
              message: 'לא ניתן לטעון את רשימת המשתמשים',
              detail: '$e',
              onRetry: () => ref.read(adminProfilesProvider.notifier).load(),
            ),
            data: (rows) {
              if (rows.isEmpty) {
                return const _AdminEmpty(
                  icon: IconsaxPlusLinear.profile_2user,
                  message: 'אין משתמשים להצגה',
                );
              }
              return ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: rows.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: AppColors.adminCardBorder),
                itemBuilder: (context, i) => _profileTile(rows[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  void _setFilter(ProfileFilter filter) {
    setState(() => _filter = filter);
    ref.read(adminProfilesProvider.notifier).setFilter(filter);
  }

  Widget _profileTile(Map<String, dynamic> p) {
    final id = p['id'] as String;
    final name = (p['full_name'] as String?)?.trim();
    final isBanned = p['is_banned'] == true;
    final neighborhood = p['neighborhoods'] is Map
        ? (p['neighborhoods'] as Map)['name'] as String?
        : null;

    return Container(
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isBanned
                ? AppColors.error.withValues(alpha: 0.1)
                : AppColors.midBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(
            child: Text(
              _initials(name),
              style: TextStyle(
                fontFamily: AppFonts.inter,
                color: isBanned ? AppColors.error : AppColors.midBlue,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                // A profile can only be created with a name, but an empty
                // string gets through; saying so beats printing nothing.
                name == null || name.isEmpty ? 'ללא שם' : name,
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: AppColors.adminTextDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (p['is_verified'] == true) ...[
              const SizedBox(width: 8),
              _Tag('מאומת', AppColors.success),
            ],
            if (p['is_broker'] == true) ...[
              const SizedBox(width: 6),
              _Tag('מתווך', AppColors.midBlue),
            ],
            if (isBanned) ...[
              const SizedBox(width: 6),
              _Tag('חסום', AppColors.error),
            ],
          ],
        ),
        subtitle: Text(
          [
            if ((p['phone'] as String?)?.isNotEmpty ?? false) p['phone'],
            if ((p['email'] as String?)?.isNotEmpty ?? false) p['email'],
            if (neighborhood != null) neighborhood,
          ].join(' • '),
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 12,
            color: AppColors.adminTextLight,
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) => _handleUserAction(v, id, isBanned),
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
                style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14),
              ),
            ),
            PopupMenuItem(
              value: 'ban',
              child: Text(
                isBanned ? 'בטל חסימה' : 'חסום משתמש',
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  color: isBanned ? null : AppColors.error,
                ),
              ),
            ),
          ],
        ),
        onTap: () => _showProfileDialog(context, ref, profile: p),
      ),
    );
  }

  void _handleUserAction(String action, String id, bool isBanned) {
    switch (action) {
      case 'edit':
        final row = ref
            .read(adminProfilesProvider)
            .valueOrNull
            ?.firstWhere((p) => p['id'] == id, orElse: () => const {});
        if (row != null && row.isNotEmpty) {
          _showProfileDialog(context, ref, profile: row);
        }
      case 'ban':
        _run(
          () => ref
              .read(adminProfilesProvider.notifier)
              .setBanned(id, !isBanned),
          isBanned ? 'החסימה בוטלה' : 'המשתמש נחסם',
        );
    }
  }

  /// Runs a write and says what happened.
  ///
  /// Every action in this panel used to change a list in memory and show
  /// nothing; a failed write has to be visible, or the client goes on
  /// believing he has acted.
  Future<void> _run(Future<void> Function() write, String done) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await write();
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text('הפעולה נכשלה: $e'),
        ),
      );
    }
  }
}

String _initials(String? name) {
  final parts = (name ?? '').trim().split(RegExp(r'\s+'))
    ..removeWhere((p) => p.isEmpty);
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.characters.first;
  return '${parts.first.characters.first}${parts[1].characters.first}';
}

// ─── Reviews Section ───

/// Reviews awaiting moderation.
///
/// This listed three invented reviews and its delete button dropped one from
/// a list in memory. `reviews` has no rows yet, so the honest state of this
/// screen is empty — and approving one, once they arrive, is what moves the
/// business's rating, because migration 00025 counts approved reviews only.
class _ReviewsSection extends ConsumerStatefulWidget {
  const _ReviewsSection();

  @override
  ConsumerState<_ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends ConsumerState<_ReviewsSection> {
  String _statusFilter = '';

  @override
  Widget build(BuildContext context) {
    final asyncReviews = ref.watch(adminReviewsProvider);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: AppColors.adminCardBorder, width: 1),
            ),
          ),
          child: Row(
            children: [
              _FilterPill('הכל', _statusFilter.isEmpty, () => _setStatus('')),
              _FilterPill(
                'ממתין',
                _statusFilter == 'pending',
                () => _setStatus('pending'),
              ),
              _FilterPill(
                'מאושר',
                _statusFilter == 'approved',
                () => _setStatus('approved'),
              ),
              _FilterPill(
                'נדחה',
                _statusFilter == 'rejected',
                () => _setStatus('rejected'),
              ),
              const Spacer(),
              // Nothing is printed while the count is unknown, rather than a
              // zero that reads as "no reviews".
              asyncReviews
                      .whenData(
                        (rows) => Text(
                          rows.isEmpty ? 'אין ביקורות' : '${rows.length} ביקורות',
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 13,
                            color: AppColors.adminTextLight,
                          ),
                        ),
                      )
                      .value ??
                  const SizedBox.shrink(),
            ],
          ),
        ),
        Expanded(
          child: asyncReviews.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _AdminError(
              message: 'לא ניתן לטעון את הביקורות',
              detail: '$e',
              onRetry: () => ref.read(adminReviewsProvider.notifier).load(),
            ),
            data: (rows) {
              if (rows.isEmpty) {
                return const _AdminEmpty(
                  icon: IconsaxPlusLinear.star,
                  message: 'אין ביקורות',
                  detail: 'ביקורות שתושבים יכתבו על עסקים יופיעו כאן לאישור.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: rows.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: AppColors.adminCardBorder),
                itemBuilder: (context, i) => _reviewTile(rows[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  void _setStatus(String status) {
    setState(() => _statusFilter = status);
    ref
        .read(adminReviewsProvider.notifier)
        .setStatusFilter(status.isEmpty ? null : status);
  }

  Widget _reviewTile(Map<String, dynamic> r) {
    final id = r['id'] as String;
    final status = r['status'] as String? ?? 'pending';
    final rating = (r['rating'] as num?)?.toInt();
    final author = r['profiles'] is Map
        ? (r['profiles'] as Map)['full_name'] as String?
        : null;
    final business = r['businesses'] is Map
        ? (r['businesses'] as Map)['name'] as String?
        : null;
    final color = rating == null
        ? AppColors.adminTextLight
        : rating >= 4
        ? AppColors.success
        : rating >= 3
        ? AppColors.gold
        : AppColors.error;

    return Container(
      color: status == 'pending' ? AppColors.gold.withValues(alpha: 0.04) : null,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(
            rating?.toString() ?? '—',
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                // The reviewer's name and the business come from the joins.
                // Where a join is missing the row is broken, and it says that
                // rather than filling the gap with an id.
                [author ?? 'מחבר לא ידוע', business ?? 'עסק לא ידוע'].join(' — '),
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.adminTextDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _Tag(_statusLabel(status), _statusColor(status)),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            (r['body'] as String?)?.trim().isNotEmpty == true
                ? r['body'] as String
                : 'דירוג בלבד, ללא טקסט',
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontSize: 13,
              color: AppColors.grayText,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status != 'approved')
              IconButton(
                tooltip: 'אשר',
                icon: const Icon(Icons.check, color: AppColors.success),
                onPressed: () => _run(
                  () => ref.read(adminReviewsProvider.notifier).approve(id),
                  'הביקורת אושרה',
                ),
              ),
            if (status != 'rejected')
              IconButton(
                tooltip: 'דחה',
                icon: const Icon(Icons.close, color: AppColors.error),
                onPressed: () => _run(
                  () => ref.read(adminReviewsProvider.notifier).reject(id),
                  'הביקורת נדחתה',
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) => switch (status) {
    'approved' => 'מאושר',
    'pending' => 'ממתין',
    'rejected' => 'נדחה',
    'hidden' => 'מוסתר',
    _ => status,
  };

  Color _statusColor(String status) => switch (status) {
    'approved' => AppColors.success,
    'pending' => AppColors.gold,
    'rejected' => AppColors.error,
    _ => AppColors.adminTextLight,
  };

  Future<void> _run(Future<void> Function() write, String done) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await write();
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text('הפעולה נכשלה: $e'),
        ),
      );
    }
  }
}

// ─── Settings Section ───

/// What the panel can say about its own configuration.
///
/// This listed six settings with a pencil beside each: an app version, a push
/// switch, a maintenance switch, a masked maps key and `https://xxx.supabase.co`
/// where the project URL belongs. None of them were read from anywhere and the
/// pencil edited nothing. `app_settings` exists as a table but has no rows and
/// nothing reads it, so the two values below are all this screen can honestly
/// show, and the notice says what is missing.
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
        _SettingsTile(
          'Supabase URL',
          SupabaseConfig.supabaseUrl,
          IconsaxPlusLinear.cloud,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                IconsaxPlusLinear.info_circle,
                size: 20,
                color: AppColors.gold,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'הגדרות הניתנות לעריכה — התראות Push, מצב תחזוקה, מפתחות API — '
                  'אינן מחוברות לטבלה. הן יופיעו כאן כשיהיה להן מקום לשמור אליו '
                  '(app_settings ריקה).',
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.adminTextMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _SettingsTile(this.label, this.value, this.icon);

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
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    color: AppColors.adminTextLight,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared Widgets ───

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag(this.label, this.color);

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
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterPill(this.label, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.adminActiveBg : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected ? AppColors.midBlue : AppColors.adminSearchBorder,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? AppColors.midBlue : AppColors.adminTextMedium,
            ),
          ),
        ),
      ),
    );
  }
}

/// An empty list, said plainly.
///
/// Several of these tables have no rows yet, and an empty panel has to read as
/// "nothing here" rather than as a screen that failed to load.
class _AdminEmpty extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? detail;
  const _AdminEmpty({required this.icon, required this.message, this.detail});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: AppColors.adminTextLight.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontFamily: AppFonts.rubik,
                fontSize: 15,
                color: AppColors.adminTextMedium,
              ),
            ),
            if (detail != null) ...[
              const SizedBox(height: 6),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 13,
                  color: AppColors.adminTextLight,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AdminError extends StatelessWidget {
  final String message;
  final String detail;
  final VoidCallback onRetry;
  const _AdminError({
    required this.message,
    required this.detail,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              IconsaxPlusLinear.danger,
              size: 40,
              color: AppColors.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontFamily: AppFonts.rubik,
                fontSize: 15,
                color: AppColors.adminTextDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 12,
                color: AppColors.adminTextLight,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(
                'נסה שוב',
                style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Dialogs ───

/// Edits one profile.
///
/// It only offers what `profiles` holds and the panel may set. It has no
/// create mode: `profiles.id` references `auth.users`, so a row cannot be
/// invented here — the old dialog built one with a made-up id and put it in a
/// list in memory.
void _showProfileDialog(
  BuildContext context,
  WidgetRef ref, {
  required Map<String, dynamic> profile,
}) {
  final id = profile['id'] as String;
  final nameC = TextEditingController(
    text: profile['full_name'] as String? ?? '',
  );
  final emailC = TextEditingController(text: profile['email'] as String? ?? '');
  final phoneC = TextEditingController(text: profile['phone'] as String? ?? '');
  var neighborhoodId = profile['neighborhood_id'] as String?;
  var isVerified = profile['is_verified'] == true;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDState) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(
            'עריכת משתמש',
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
                  // The neighbourhood is a foreign key, so this is the list of
                  // real neighbourhoods rather than a free-text box that could
                  // not be saved.
                  Consumer(
                    builder: (context, ref, _) {
                      final asyncHoods = ref.watch(neighborhoodsProvider);
                      return asyncHoods.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text(
                          'לא ניתן לטעון שכונות: $e',
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 12,
                            color: AppColors.error,
                          ),
                        ),
                        data: (hoods) => DropdownButtonFormField<String?>(
                          initialValue: neighborhoodId,
                          decoration: const InputDecoration(
                            labelText: 'שכונה',
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('—'),
                            ),
                            for (final h in hoods)
                              DropdownMenuItem(
                                value: h['id'] as String,
                                child: Text(h['name'] as String? ?? ''),
                              ),
                          ],
                          onChanged: (v) =>
                              setDState(() => neighborhoodId = v),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: isVerified,
                    onChanged: (v) => setDState(() => isVerified = v ?? false),
                    title: Text(
                      'תושב מאומת',
                      style: TextStyle(
                        fontFamily: AppFonts.rubik,
                        fontSize: 14,
                      ),
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
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(ctx);
                final navigator = Navigator.of(ctx);
                try {
                  await ref
                      .read(adminProfilesProvider.notifier)
                      .updateProfile(id, {
                        'full_name': nameC.text.trim(),
                        'email': emailC.text.trim(),
                        'phone': phoneC.text.trim(),
                        'neighborhood_id': neighborhoodId,
                        'is_verified': isVerified,
                      });
                  navigator.pop();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('המשתמש נשמר')),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.error,
                      content: Text('השמירה נכשלה: $e'),
                    ),
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.midBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'שמור',
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
