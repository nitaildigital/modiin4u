import '../../../core/theme/app_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/admin_businesses_provider.dart';
import '../providers/admin_data_provider.dart';
import '../providers/admin_permissions_provider.dart';
import 'admin_businesses_screen.dart';
import 'admin_articles_screen.dart';
import 'admin_events_screen.dart';
import 'admin_realestate_screen.dart';
import 'admin_reviews_screen.dart';
import 'admin_categories_screen.dart';
import 'admin_step_groups_screen.dart';
import 'admin_tags_screen.dart';
import 'admin_neighborhoods_screen.dart';
import 'admin_parking_screen.dart';
import 'admin_municipal_places_screen.dart';
import 'admin_media_screen.dart';
import 'admin_offers_screen.dart';
import 'admin_promotions_screen.dart';
import 'admin_photo_submissions_screen.dart';
import 'admin_jobs_screen.dart';
import 'admin_agreements_screen.dart';
import 'admin_revenue_screen.dart';
import 'admin_ad_placements_screen.dart';
import 'admin_campaigns_screen.dart';
import 'admin_comments_screen.dart';
import 'admin_messages_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_push_screen.dart';
import 'admin_team_screen.dart';
import 'admin_audit_screen.dart';
import 'admin_trash_screen.dart';
import 'admin_home_builder_screen.dart';
import 'admin_flags_screen.dart';
import 'admin_agents_screen.dart';
import 'admin_analytics_screen.dart';
import 'admin_site_pages_screen.dart';
import '../admin_language.dart';
import '../../../shared/providers/app_settings_provider.dart';
import '../ui/admin_kit.dart';
import '../../urban_profile/data/urban_profile.dart' show interestOf, urbanProfileLink;

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedSection = 0;

  static List<(String, IconData)> get _sections => [
    // ── ראשי ──
    (tr('סקירה', 'Overview'), IconsaxPlusLinear.element_3),
    (tr('משתמשים', 'Users'), IconsaxPlusLinear.profile_2user),
    // ── תוכן ──
    (tr('עסקים', 'Businesses'), IconsaxPlusLinear.shop),
    (tr('כתבות', 'Articles'), IconsaxPlusLinear.document_text),
    (tr('אירועים', 'Events'), IconsaxPlusLinear.calendar),
    (tr('נדל״ן', 'Real estate'), IconsaxPlusLinear.building_3),
    (tr('חניונים', 'Car parks'), IconsaxPlusLinear.car),
    (tr('מוסדות עירוניים', 'Municipal places'), IconsaxPlusLinear.bank),
    (tr('מתווכים', 'Agents'), IconsaxPlusLinear.profile_circle),
    // ── טקסונומיה ──
    (tr('קטגוריות', 'Categories'), IconsaxPlusLinear.category_2),
    (tr('תגיות', 'Tags'), IconsaxPlusLinear.tag),
    (tr('שכונות', 'Neighbourhoods'), IconsaxPlusLinear.building),
    (tr('מדיה', 'Media'), IconsaxPlusLinear.gallery),
    // ── מסחר ופרסום ──
    (tr('מבצעים', 'Deals'), IconsaxPlusLinear.discount_shape),
    (tr('קידומים', 'Promotions'), IconsaxPlusLinear.ranking_1),
    (tr('תמונות תושבים', 'Resident photos'), IconsaxPlusLinear.gallery_add),
    (tr('משרות', 'Jobs'), IconsaxPlusLinear.briefcase),
    (tr('הסכמים', 'Agreements'), IconsaxPlusLinear.document),
    (tr('הכנסות', 'Revenue'), IconsaxPlusLinear.wallet_3),
    (tr('מיקומי פרסום', 'Ad placements'), IconsaxPlusLinear.monitor_mobbile),
    (tr('קמפיינים', 'Campaigns'), IconsaxPlusLinear.magicpen),
    // ── אינטראקציה ──
    (tr('ביקורות', 'Reviews'), IconsaxPlusLinear.star),
    (tr('תגובות', 'Comments'), IconsaxPlusLinear.message_text),
    (tr('הודעות', 'Messages'), IconsaxPlusLinear.messages_2),
    (tr('דיווחים', 'Reports'), IconsaxPlusLinear.flag),
    ('Push', IconsaxPlusLinear.notification),
    (tr('אתגרים וקבוצות', 'Challenges & groups'), IconsaxPlusLinear.cup),
    // ── מערכת ──
    (tr('צוות ניהול', 'Admin team'), IconsaxPlusLinear.people),
    (tr('יומן פעולות', 'Activity log'), IconsaxPlusLinear.clock),
    (tr('פח מחזור', 'Trash'), IconsaxPlusLinear.trash),
    (tr('בונה דף הבית', 'Home page builder'), IconsaxPlusLinear.element_plus),
    ('Feature Flags', IconsaxPlusLinear.toggle_on_circle),
    (tr('עמודי מידע', 'Info pages'), IconsaxPlusLinear.document_1),
    (tr('הגדרות', 'Settings'), IconsaxPlusLinear.setting_2),
  ];

  /// The permission module ([AdminPermissions]) behind each of [_sections],
  /// in the same order; null for what every administrator has. Sections
  /// with no module of their own go with the nearest one: real estate, car
  /// parks, municipal places and agents with businesses; tags and
  /// neighbourhoods with categories; information pages with articles (the
  /// content editor's "pages"); challenges, the trash, the home page and
  /// flags with settings, which is the main admin's.
  ///
  /// The admin team is 'team', a module no role holds, so only the main
  /// admin sees it. It went with 'users', and support — who has users — saw
  /// every administrator's name and e-mail, with switches and an add button
  /// the database refuses them (the team tables are main-admin-only, 00042).
  static const _sectionModules = <String?>[
    null, 'users', //
    'businesses', 'articles', 'events', 'businesses', 'businesses',
    'businesses', 'businesses', //
    'categories', 'categories', 'categories', 'media', //
    // Promotions, residents' photos and jobs go with businesses: whoever may
    // edit businesses decides on them (00069's admin_decide_promotion and
    // 00071's admin_decide_photo ask the same).
    'offers', 'businesses', 'businesses', 'businesses', 'revenue', 'revenue', 'campaigns',
    'campaigns', //
    // Messages (00078) go with moderation, as its functions ask.
    'moderation', 'moderation', 'moderation', 'moderation', 'push', 'settings', //
    'team', 'audit', 'settings', 'settings', 'settings', 'articles', null,
  ];

  /// Whether the signed-in administrator's role may open section [i].
  bool _canOpen(int i) =>
      AdminPermissions.of(ref.watch(adminPermissionsProvider))
          .canView(_sectionModules[i]);

  /// Where the settings pane sits in [_sections] — the top bar's gear jumps
  /// here rather than doing nothing, which is what it used to do.
  static const _settingsSection = 33;

  /// The index in [_sections] each sidebar heading sits above. They move
  /// whenever a section is added: when חניונים went in at 6 these were left
  /// where they were, and every heading from טקסונומיה down sat one row too
  /// high — מתווכים appeared under טקסונומיה.
  static Map<int, String> get _sectionGroups => {
    0: tr('ראשי', 'Main'),
    2: tr('תוכן', 'Content'),
    9: tr('טקסונומיה', 'Taxonomy'),
    13: tr('מסחר ופרסום', 'Commerce & advertising'),
    21: tr('אינטראקציה', 'Interaction'),
    27: tr('מערכת', 'System'),
  };

  @override
  void initState() {
    super.initState();
    loadAdminLanguage();
  }

  /// The panel in the language chosen in Settings. A switch rebuilds the
  /// whole panel under a new key: the sections are const widgets, which a
  /// plain rebuild would skip, and every text in them is read as it builds.
  /// Dates, pickers and the like follow through the overridden locale.
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: adminEnglish,
      builder: (context, english, _) => Localizations.override(
        context: context,
        locale: adminLocale,
        child: KeyedSubtree(
          key: ValueKey(english),
          child: Builder(builder: _buildPanel),
        ),
      ),
    );
  }

  Widget _buildPanel(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    // The kit's fields, switches, checkboxes and chips for every screen and
    // every dialog opened from one (dialogs capture this theme), not only
    // the two editors that were rebuilt on it.
    return Theme(
      data: AdminKit.of(context).theme(Theme.of(context)),
      child: Directionality(
      textDirection: adminDir,
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
                          visible: _canOpen,
                        ),
                        Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: AppColors.adminContentBg,
                              borderRadius: BorderRadiusDirectional.only(
                                topStart: Radius.circular(12),
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
                            separatorBuilder: (_, index) => _canOpen(index)
                                ? const SizedBox(width: 8)
                                : const SizedBox.shrink(),
                            itemBuilder: (context, index) {
                              if (!_canOpen(index)) return const SizedBox.shrink();
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
    ),
    );
  }

  Widget _buildSection() {
    if (!_canOpen(_selectedSection)) return const _NoAccess();
    return switch (_selectedSection) {
      0 => const AdminAnalyticsScreen(),
      1 => const _UsersSection(),
      2 => const AdminBusinessesScreen(),
      3 => const AdminArticlesScreen(),
      4 => const AdminEventsScreen(),
      5 => const AdminRealEstateScreen(),
      6 => const AdminParkingScreen(),
      7 => const AdminMunicipalPlacesScreen(),
      8 => const AdminAgentsScreen(),
      9 => const AdminCategoriesScreen(),
      10 => const AdminTagsScreen(),
      11 => const AdminNeighborhoodsScreen(),
      12 => const AdminMediaScreen(),
      13 => const AdminOffersScreen(),
      14 => const AdminPromotionsScreen(),
      15 => const AdminPhotoSubmissionsScreen(),
      16 => const AdminJobsScreen(),
      17 => const AdminAgreementsScreen(),
      18 => const AdminRevenueScreen(),
      19 => const AdminAdPlacementsScreen(),
      20 => const AdminCampaignsScreen(),
      21 => const AdminReviewsScreen(),
      22 => const AdminCommentsScreen(),
      23 => const AdminMessagesScreen(),
      24 => const AdminReportsScreen(),
      25 => const AdminPushScreen(),
      26 => const AdminStepsSection(),
      27 => const AdminTeamScreen(),
      28 => const AdminAuditScreen(),
      29 => const AdminTrashScreen(),
      30 => const AdminHomeBuilderScreen(),
      31 => const AdminFlagsScreen(),
      32 => const AdminSitePagesScreen(),
      33 => const _SettingsSection(),
      _ => const SizedBox(),
    };
  }
}

/// A section the administrator's role does not include — reached only by a
/// link that skips the sidebar, since the sidebar leaves it out.
class _NoAccess extends StatelessWidget {
  const _NoAccess();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(IconsaxPlusLinear.lock, size: 40, color: AppColors.adminTextLight),
            const SizedBox(height: 12),
            Text(
              tr('אין לתפקיד שלך גישה לחלק הזה', "Your role doesn't include this section"),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.adminTextMedium,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              tr('מנהל ראשי יכול לשנות זאת בצוות ניהול', 'A main admin can change this under Admin team'),
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 13, color: AppColors.adminTextLight),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Top Bar (CRM-style) ───

class _AdminTopBar extends ConsumerWidget {
  final String sectionName;
  final VoidCallback onOpenSettings;
  const _AdminTopBar({required this.sectionName, required this.onOpenSettings});

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
                tr('ניהול — מודיעין בשבילך', 'Admin — Modiin4U'),
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
          // A menu on it: the panel had no way to sign out, and on the
          // website /profile and /settings lead home, so neither did the site.
          PopupMenuButton<String>(
            tooltip: signedIn?.name ?? tr('לא מחובר', 'Not connected'),
            position: PopupMenuPosition.under,
            onSelected: (v) async {
              if (v != 'out') return;
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            itemBuilder: (_) => [
              if (signedIn != null)
                PopupMenuItem<String>(
                  enabled: false,
                  child: Text(
                    '${signedIn.name}\n${signedIn.email}',
                    style: TextStyle(fontFamily: AppFonts.inter, fontSize: 12, color: AppColors.adminTextMedium),
                  ),
                ),
              PopupMenuItem<String>(
                value: 'out',
                child: Row(
                  children: [
                    const Icon(IconsaxPlusLinear.logout, size: 18, color: AppColors.error),
                    const SizedBox(width: 8),
                    Text(
                      tr('התנתקות', 'Sign out'),
                      style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: AppColors.error),
                    ),
                  ],
                ),
              ),
            ],
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: signedIn == null
                    ? null
                    : const LinearGradient(
                        colors: [AppColors.midBlue, AppColors.midBlue],
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

  /// Whether section i is the role's to open; the others are left out, and
  /// so is a heading with nothing under it.
  final bool Function(int i) visible;

  const _Sidebar({
    required this.sections,
    required this.selected,
    required this.onSelect,
    required this.visible,
    this.sectionGroups = const {},
  });

  @override
  Widget build(BuildContext context) {
    // Build flat list of widgets: group headers + section tiles
    final items = <Widget>[];
    String? heading;
    for (int i = 0; i < sections.length; i++) {
      if (sectionGroups.containsKey(i)) heading = sectionGroups[i];
      if (!visible(i)) continue;
      if (heading != null) {
        if (items.isNotEmpty) items.add(const SizedBox(height: 16));
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              heading,
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
        heading = null;
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
        border: BorderDirectional(
          end: BorderSide(color: AppColors.adminSidebarBorder, width: 1),
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
        AdminListToolbar(
          search: AdminSearchField(
            controller: _searchController,
            hint: tr('חיפוש לפי שם, טלפון, אימייל...', 'Search by name, phone, email...'),
            onChanged: (v) => ref
                .read(adminProfilesProvider.notifier)
                .setSearch(v.isEmpty ? null : v),
          ),
          filters: [
            AdminFilterChip(tr('הכל', 'All'), _filter == ProfileFilter.all, () {
              _setFilter(ProfileFilter.all);
            }),
            AdminFilterChip(tr('מאומתים', 'Verified'), _filter == ProfileFilter.verified, () {
              _setFilter(ProfileFilter.verified);
            }),
            AdminFilterChip(tr('חסומים', 'Blocked'), _filter == ProfileFilter.banned, () {
              _setFilter(ProfileFilter.banned);
            }),
          ],
          actions: [
            // An account is created when the resident first signs in — that
            // is what puts the row in `auth.users` this table points at. The
            // panel cannot make one, so the button says so rather than
            // opening a form that could not save.
            Tooltip(
              message:
                  tr('חשבון נוצר כשהתושב נכנס לאפליקציה בפעם הראשונה. '
                  'לא ניתן ליצור משתמש מכאן.', 'An account is created when a resident first signs in to the app. Users cannot be created from here.'),
              child: AdminToolbarButton(
                label: tr('משתמש חדש', 'New user'),
                onPressed: null,
              ),
            ),
          ],
        ),
        // ── User list ──
        Expanded(
          child: asyncProfiles.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _AdminError(
              message: tr('לא ניתן לטעון את רשימת המשתמשים', 'Could not load the user list'),
              detail: '$e',
              onRetry: () => ref.read(adminProfilesProvider.notifier).load(),
            ),
            data: (rows) {
              if (rows.isEmpty) {
                return _AdminEmpty(
                  icon: IconsaxPlusLinear.profile_2user,
                  message: tr('אין משתמשים להצגה', 'No users to show'),
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
                name == null || name.isEmpty ? tr('ללא שם', 'Untitled') : name,
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
              AdminPill(tr('מאומת', 'Verified'), AdminKit.of(context).success),
            ],
            if (p['is_broker'] == true) ...[
              const SizedBox(width: 6),
              AdminPill(tr('מתווך', 'Agent'), AdminKit.of(context).accent),
            ],
            if (isBanned) ...[
              const SizedBox(width: 6),
              AdminPill(tr('חסום', 'Blocked'), AdminKit.of(context).danger),
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
                tr('עריכה', 'Edit'),
                style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14),
              ),
            ),
            PopupMenuItem(
              value: 'ban',
              child: Text(
                isBanned ? tr('בטל חסימה', 'Unblock') : tr('חסום משתמש', 'Block user'),
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
        if (isBanned) {
          _run(
            () => ref.read(adminProfilesProvider.notifier).setBanned(id, false),
            tr('החסימה בוטלה', 'Unblocked'),
          );
        } else {
          _askBanReason(id);
        }
    }
  }

  /// Blocking asks why, so the reason stays with the account and the log.
  Future<void> _askBanReason(String id) async {
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: adminDir,
        child: AlertDialog(
          title: Text(tr('חסימת משתמש', 'Block user'), style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 17)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('המשתמש לא יוכל לכתוב ביקורות ותגובות, לפרסם, לממש הטבות או להירשם לאירועים.',
                   'They will not be able to review, comment, post, claim deals or RSVP.'),
                style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13, color: AppColors.adminTextMedium),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reason,
                autofocus: true,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: tr('סיבה (לא חובה)', 'Reason (optional)'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('ביטול', 'Cancel'))),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('חסום', 'Block')),
            ),
          ],
        ),
      ),
    );
    final text = reason.text;
    reason.dispose();
    if (ok != true || !mounted) return;
    _run(
      () => ref.read(adminProfilesProvider.notifier).setBanned(id, true, reason: text),
      tr('המשתמש נחסם', 'User blocked'),
    );
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
          content: Text(tr('הפעולה נכשלה: $e', 'The action failed: $e')),
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
          tr('הגדרות אפליקציה', 'App settings'),
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.adminTextDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          tr('ניהול הגדרות כלליות של המערכת', 'Manage the system\'s general settings'),
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 14,
            color: AppColors.adminTextLight,
          ),
        ),
        const SizedBox(height: 20),
        const _LanguageTile(),
        _SettingsTile(
          tr('שם האפליקציה', 'App name'),
          tr('מודיעין בשבילך', 'Modiin4U'),
          IconsaxPlusLinear.mobile,
        ),
        _SettingsTile(
          'Supabase URL',
          SupabaseConfig.supabaseUrl,
          IconsaxPlusLinear.cloud,
        ),
        // Kept in `app_settings`. The store links appear on the website's
        // step-group invitation once they are filled in; until the app is in
        // the stores they stay empty and the page offers none.
        _EditableSetting(
          settingKey: AppSettingKeys.androidStoreUrl,
          label: tr('קישור ל-Google Play', 'Google Play link'),
          hint: 'https://play.google.com/store/apps/details?id=…',
          icon: IconsaxPlusLinear.mobile,
        ),
        _EditableSetting(
          settingKey: AppSettingKeys.iosStoreUrl,
          label: tr('קישור ל-App Store', 'App Store link'),
          hint: 'https://apps.apple.com/app/…',
          icon: IconsaxPlusLinear.mobile,
        ),
        _EditableSetting(
          settingKey: AppSettingKeys.jobApplicationsKeepDays,
          label: tr('ימים לשמירת מועמדויות אחרי סגירת משרה',
              'Days to keep applications after a job closes'),
          hint: '2',
          icon: IconsaxPlusLinear.briefcase,
          number: true,
        ),
        // Whether residents' replies to reviews wait for approval. Off by
        // default since 00063: replies appear at once, and the panel hides
        // one afterwards (Comments) or acts on a report.
        _SwitchSetting(
          settingKey: AppSettingKeys.repliesNeedApproval,
          title: tr('תגובות (לביקורות ולכתבות) ממתינות לאישור',
              'Replies to reviews and article comments wait for approval'),
          onText: tr('כל תגובה חדשה ממתינה בתגובות עד שתאושר.',
              'Each new reply waits in Comments until approved.'),
          offText: tr('תגובות מופיעות מיד; אפשר להסתיר תגובה בתגובות, ותושבים יכולים לדווח עליה.',
              'Replies appear at once; hide one in Comments, and residents can report it.'),
          icon: IconsaxPlusLinear.messages_2,
        ),
        _EditableSetting(
          settingKey: AppSettingKeys.listingsExpireDays,
          label: tr('ימים עד שמודעת נדל״ן פגה (0 = לא פגה)',
              'Days a listing stays up after approval (0 = never expires)'),
          hint: '0',
          icon: IconsaxPlusLinear.calendar_remove,
          number: true,
        ),
        _EditableSetting(
          settingKey: AppSettingKeys.reportsAutoHideAt,
          label: tr('הסתרה אוטומטית אחרי מספר דיווחים (0 = כבוי)',
              'Hide a review or reply after this many reports (0 = off)'),
          hint: '0',
          icon: IconsaxPlusLinear.eye_slash,
          number: true,
          numberMax: 50,
          rangeMessage: tr('מספר בין 0 ל-50', 'A number from 0 to 50'),
        ),
        // App updates: below these builds the app asks for the update —
        // with "Later" unless the switch makes it required
        // (core/update/force_update.dart).
        for (final android in [true, false]) ...[
          _EditableSetting(
            settingKey: android ? AppSettingKeys.minBuildAndroid : AppSettingKeys.minBuildIos,
            label: android
                ? tr('עדכון אפליקציה — מספר הבנייה העדכני ל-Android (0 = כבוי)',
                    'App update — latest Android build (0 = off)')
                : tr('עדכון אפליקציה — מספר הבנייה העדכני ל-iOS (0 = כבוי)',
                    'App update — latest iOS build (0 = off)'),
            hint: '0',
            icon: IconsaxPlusLinear.refresh_circle,
            number: true,
            numberMax: 1000000,
            rangeMessage: tr('מספר בנייה, 0 עד 1,000,000', 'A build number, 0 to 1,000,000'),
          ),
          _SwitchSetting(
            settingKey: android ? AppSettingKeys.forceUpdateAndroid : AppSettingKeys.forceUpdateIos,
            title: android
                ? tr('עדכון חובה ב-Android', 'Android update is required')
                : tr('עדכון חובה ב-iOS', 'iOS update is required'),
            onText: tr('גרסה ישנה יותר לא נפתחת עד שמעדכנים.',
                'An older version does not open until it is updated.'),
            offText: tr('גרסה ישנה יותר מבקשת לעדכן, ואפשר ללחוץ "אחר כך".',
                'An older version asks for the update, and "Later" lets people carry on.'),
            icon: IconsaxPlusLinear.lock_1,
          ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text(
            tr(
              'מספר הבנייה הוא ה-Version code ב-Google Play Console וה-Build ב-App Store Connect (למשל 1.0.1 (7) → 7). '
                  'אפליקציה ישנה מזה מבקשת לעדכן, עם הקישור לחנות שלמעלה. '
                  'להגדיר רק אחרי שהגרסה החדשה זמינה בחנות.',
              'The build number is the version code in Google Play Console and the build in App Store Connect (e.g. 1.0.1 (7) → 7). '
                  'An older app asks for the update, with the store link above. '
                  'Set it only once the new version is live in the store.',
            ),
            style: TextStyle(fontFamily: AppFonts.inter, fontSize: 12, height: 1.5, color: AppColors.adminTextLight),
          ),
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
                  tr('מצב תחזוקה ומפתחות API אינם נקראים מכאן: הם יופיעו כאן '
                  'כשהאפליקציה תקרא אותם.', 'Maintenance mode and API keys are not read from here; they will appear once the app reads them.'),
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

/// The panel's language: Hebrew (the default) or English. Each language is
/// named in itself, so it can be found whichever one the panel is in.
class _LanguageTile extends StatelessWidget {
  const _LanguageTile();

  @override
  Widget build(BuildContext context) {
    final english = adminEnglish.value;
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
            child: Icon(
              IconsaxPlusLinear.language_square,
              size: 20,
              color: AppColors.midBlue,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('שפת ממשק הניהול', 'Admin panel language'),
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: AppColors.adminTextDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tr(
                    'נשמרת בדפדפן הזה. לא משנה את שפת האתר.',
                    'Kept on this browser. It does not change the site\'s language.',
                  ),
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    color: AppColors.adminTextLight,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('עברית')),
              ButtonSegment(value: true, label: Text('English')),
            ],
            selected: {english},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setAdminEnglish(s.first),
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppColors.adminActiveBg,
              selectedForegroundColor: AppColors.midBlue,
              textStyle: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// One `app_settings` value the panel edits: a link, or a whole number.
class _EditableSetting extends ConsumerStatefulWidget {
  final String settingKey;
  final String label;
  final String hint;
  final IconData icon;
  final bool number;

  /// For a number: the largest allowed, and what to say when it is out of
  /// range (the first number setting counted days).
  final int numberMax;
  final String? rangeMessage;
  const _EditableSetting({
    required this.settingKey,
    required this.label,
    required this.hint,
    required this.icon,
    this.number = false,
    this.numberMax = 365,
    this.rangeMessage,
  });

  @override
  ConsumerState<_EditableSetting> createState() => _EditableSettingState();
}

class _EditableSettingState extends ConsumerState<_EditableSetting> {
  final _controller = TextEditingController();
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    final Object? value;
    if (widget.number) {
      final n = int.tryParse(text);
      if (n == null || n < 0 || n > widget.numberMax) {
        _say(widget.rangeMessage ??
            tr('מספר ימים בין 0 ל-365', 'A number of days from 0 to 365'));
        return;
      }
      value = n;
    } else {
      if (text.isNotEmpty && !text.startsWith('https://')) {
        _say(tr('קישור שמתחיל ב-https://', 'A link starting with https://'));
        return;
      }
      value = text;
    }
    setState(() => _saving = true);
    try {
      await SupabaseConfig.client
          .from('app_settings')
          .upsert({'key': widget.settingKey, 'value': value}, onConflict: 'key');
      ref.invalidate(appSettingsProvider);
      _say(tr('נשמר', 'Saved'));
    } catch (_) {
      _say(tr('השמירה נכשלה', 'Could not save'));
    }
    if (mounted) setState(() => _saving = false);
  }

  void _say(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider).valueOrNull;
    if (!_loaded && settings != null) {
      _loaded = true;
      final v = settings[widget.settingKey];
      _controller.text = v == null ? '' : '$v';
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.adminCardBorder, width: 1),
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
            child: Icon(widget.icon, size: 20, color: AppColors.midBlue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: AppColors.adminTextDark,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _controller,
                  enabled: settings != null,
                  keyboardType: widget.number ? TextInputType.number : TextInputType.url,
                  style: TextStyle(fontFamily: AppFonts.inter, fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: widget.hint,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: _saving || settings == null ? null : _save,
            child: Text(tr('שמירה', 'Save')),
          ),
        ],
      ),
    );
  }
}

/// An on/off `app_settings` value the panel edits, with a line under the
/// title saying what the current choice does.
class _SwitchSetting extends ConsumerStatefulWidget {
  final String settingKey;
  final String title;
  final String onText;
  final String offText;
  final IconData icon;
  const _SwitchSetting({
    required this.settingKey,
    required this.title,
    required this.onText,
    required this.offText,
    required this.icon,
  });

  @override
  ConsumerState<_SwitchSetting> createState() => _SwitchSettingState();
}

class _SwitchSettingState extends ConsumerState<_SwitchSetting> {
  bool _saving = false;

  Future<void> _set(bool on) async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await SupabaseConfig.client.from('app_settings').upsert(
        {'key': widget.settingKey, 'value': on},
        onConflict: 'key',
      );
      ref.invalidate(appSettingsProvider);
      messenger.showSnackBar(SnackBar(content: Text(tr('נשמר', 'Saved'))));
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(tr('השמירה נכשלה', 'Could not save'))),
      );
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider).valueOrNull;
    final on = settings?[widget.settingKey] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.adminCardBorder, width: 1),
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
            child: Icon(widget.icon, size: 20, color: AppColors.midBlue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: AppColors.adminTextDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  on ? widget.onText : widget.offText,
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 12,
                    color: AppColors.adminTextLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // The kit's switch colours (AdminSwitchRow): this screen is not
          // under the kit's theme, and the app's switch is black when off.
          Switch(
            value: on,
            onChanged: settings == null || _saving ? null : _set,
            activeTrackColor: AdminKit.of(context).accent,
            activeThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFE5E7EB),
            inactiveThumbColor: Colors.white,
            trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
          ),
        ],
      ),
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

/// An empty list, said plainly.
///
/// Several of these tables have no rows yet, and an empty panel has to read as
/// "nothing here" rather than as a screen that failed to load.
class _AdminEmpty extends StatelessWidget {
  final IconData icon;
  final String message;
  const _AdminEmpty({required this.icon, required this.message});

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
                tr('נסה שוב', 'Try again'),
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
        textDirection: adminDir,
        child: AlertDialog(
          title: Text(
            tr('עריכת משתמש', 'Edit user'),
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
                    decoration: InputDecoration(labelText: tr('שם מלא', 'Full name')),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailC,
                    decoration: InputDecoration(labelText: tr('אימייל', 'Email')),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneC,
                    decoration: InputDecoration(labelText: tr('טלפון', 'Phone')),
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
                          tr('לא ניתן לטעון שכונות: $e', 'Could not load neighbourhoods: $e'),
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 12,
                            color: AppColors.error,
                          ),
                        ),
                        data: (hoods) => DropdownButtonFormField<String?>(
                          initialValue: neighborhoodId,
                          decoration: InputDecoration(labelText: tr('שכונה', 'Neighbourhood')),
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
                          onChanged: (v) => setDState(() => neighborhoodId = v),
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
                      tr('תושב מאומת', 'Verified resident'),
                      style: TextStyle(
                        fontFamily: AppFonts.rubik,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  _UrbanProfileFacts(profile: profile),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                tr('ביטול', 'Cancel'),
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
                    SnackBar(content: Text(tr('המשתמש נשמר', 'User saved'))),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.error,
                      content: Text(tr('השמירה נכשלה: $e', 'Saving failed: $e')),
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
                tr('שמור', 'Save'),
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

/// A resident's Urban Profile (00077), as others would see it, in the user's
/// window. Read-only: what they wrote is theirs. A profile that should not be
/// shown is made private here (reversible — they may share it again; a
/// resident who keeps at it is blocked), and a report on it arrives under
/// Reports as a report on the user.
class _UrbanProfileFacts extends ConsumerStatefulWidget {
  final Map<String, dynamic> profile;
  const _UrbanProfileFacts({required this.profile});

  @override
  ConsumerState<_UrbanProfileFacts> createState() => _UrbanProfileFactsState();
}

class _UrbanProfileFactsState extends ConsumerState<_UrbanProfileFacts> {
  late String _visibility = (widget.profile['profile_visibility'] as String?) ?? 'private';
  late final Future<List<String>> _places = _loadPlaces();
  bool _busy = false;

  Future<List<String>> _loadPlaces() async {
    final rows = await SupabaseConfig.client
        .from('profile_places')
        .select('position, top_pick, businesses(name)')
        .eq('profile_id', widget.profile['id'] as String)
        .order('position');
    return [
      for (final r in List<Map<String, dynamic>>.from(rows))
        if (r['businesses'] is Map) ((r['businesses'] as Map)['name'] as String?) ?? '',
    ];
  }

  Future<void> _makePrivate() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(adminProfilesProvider.notifier).updateProfile(widget.profile['id'] as String, {'profile_visibility': 'private'});
      if (!mounted) return;
      setState(() {
        _visibility = 'private';
        _busy = false;
      });
      messenger.showSnackBar(SnackBar(content: Text(tr('הפרופיל הוסתר', 'Profile made private'))));
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(backgroundColor: AppColors.error, content: Text(tr('הפעולה נכשלה: $e', 'The action failed: $e'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final k = AdminKit.of(context);
    final p = widget.profile;
    final username = (p['username'] as String?) ?? '';
    final bio = ((p['bio'] as String?) ?? '').trim();
    final keys = List<String>.from((p['interests'] as List?) ?? const []);
    final visible = _visibility == 'residents';
    final he = !adminEnglish.value;
    if (username.isEmpty && bio.isEmpty && keys.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(tr('לא מילא/ה פרופיל עירוני.', 'No Urban Profile yet.'), style: k.hint),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: k.subtle, border: Border.all(color: k.border), borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(tr('פרופיל עירוני', 'Urban Profile'), style: k.heading.copyWith(fontSize: 14))),
              AdminPill(visible ? tr('גלוי לתושבים', 'Visible to residents') : tr('פרטי', 'Private'), visible ? k.success : k.muted),
            ],
          ),
          if (username.isNotEmpty) ...[
            const SizedBox(height: 6),
            SelectableText(urbanProfileLink(username).replaceFirst('https://', ''), style: k.hint),
          ],
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('“$bio”', style: k.body.copyWith(fontStyle: FontStyle.italic)),
          ],
          if (keys.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final key in keys)
                  if (interestOf(key) case final i?) AdminPill('${i.emoji} ${i.label(he)}', k.accent),
              ],
            ),
          ],
          FutureBuilder<List<String>>(
            future: _places,
            builder: (context, snap) {
              final names = snap.data ?? const [];
              if (names.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('${tr('מקומות', 'Places')}: ${names.join(' · ')}', style: k.label),
              );
            },
          ),
          if (visible) ...[
            const SizedBox(height: 10),
            AdminButton.secondary(
              label: tr('הסתרת הפרופיל', 'Make profile private'),
              busy: _busy,
              onPressed: _busy ? null : _makePrivate,
            ),
          ],
        ],
      ),
    );
  }
}

