import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/supabase/supabase_config.dart';
import '../providers/admin_permissions_provider.dart';
import '../providers/admin_team_provider.dart';
import '../widgets/admin_form_pickers.dart';
import '../admin_language.dart';
import '../ui/admin_kit.dart';

class AdminTeamScreen extends ConsumerStatefulWidget {
  const AdminTeamScreen({super.key});
  @override
  ConsumerState<AdminTeamScreen> createState() => _AdminTeamScreenState();
}

class _AdminTeamScreenState extends ConsumerState<AdminTeamScreen> {
  final _searchController = TextEditingController();

  /// Typing fired a search per keystroke, and the answers can arrive out of
  /// order — an early, broader one landing last showed rows that did not
  /// match. Waiting for a pause sends one.
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(adminTeamProvider);
    final count = asyncData.valueOrNull?.length;
    final isWide = MediaQuery.of(context).size.width > 900;

    return Column(
      children: [
        // ─── Toolbar ───
        AdminListToolbar(
          search: AdminSearchField(
            controller: _searchController,
            width: isWide ? 280 : 180,
            hint: tr('חיפוש לפי שם או אימייל...', 'Search by name or email...'),
            onChanged: (v) {
              _searchDebounce?.cancel();
              _searchDebounce = Timer(
                const Duration(milliseconds: 400),
                () => ref
                    .read(adminTeamProvider.notifier)
                    .setSearch(v.isEmpty ? null : v),
              );
            },
          ),
          count: count == null ? null : tr('$count חברי צוות', '$count team members'),
          actions: [
            // What each role may do: the main admin's alone (00066).
            if (AdminPermissions.of(ref.watch(adminPermissionsProvider)).isMainAdmin)
              AdminToolbarButton(
                primary: false,
                icon: Icons.admin_panel_settings_outlined,
                label: tr('תפקידים והרשאות', 'Roles & rights'),
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const _RoleRightsDialog(),
                ),
              ),
            AdminToolbarButton(
              icon: Icons.person_add,
              label: tr('הוספת חבר צוות', 'Add team member'),
              onPressed: () => _showGrant(context),
            ),
          ],
        ),

        // ─── Cards Grid ───
        Expanded(
          child: asyncData.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                tr('שגיאה בטעינת הצוות: ${adminErrorText(e)}', 'Error loading the team: ${adminErrorText(e)}'),
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  color: AppColors.error,
                ),
              ),
            ),
            data: (list) {
              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.group_outlined,
                        size: 48,
                        color: AppColors.grayLight.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        tr('אין חברי צוות', 'No team members'),
                        style: TextStyle(
                          fontFamily: AppFonts.rubik,
                          color: AppColors.grayText,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWide ? 3 : 1,
                  childAspectRatio: isWide ? 2.2 : 3.5,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: list.length,
                itemBuilder: (_, i) => _TeamCard(
                  member: list[i],
                  isSelf:
                      list[i]['profile_id'] ==
                      AdminTeamNotifier.currentProfileId,
                  onEdit: () => _showRoleEditor(context, list[i]),
                  onToggle: (active) => _setActive(list[i], active),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _setActive(Map<String, dynamic> member, bool active) async {
    try {
      await ref
          .read(adminTeamProvider.notifier)
          .setMemberActive(member, active);
    } catch (e) {
      if (mounted) showAdminError(context, tr('לא בוצע', 'Not done'), e);
    }
  }

  /// Granting access: pick a person who already has an account, and a role.
  void _showGrant(BuildContext context) {
    showDialog(context: context, builder: (_) => const _GrantDialog());
  }

  /// Editing a member is choosing their role. Their name and address are
  /// their own, on their profile, and are not the panel's to rewrite.
  void _showRoleEditor(BuildContext context, Map<String, dynamic> member) {
    showDialog(
      context: context,
      builder: (_) => _RoleDialog(member: member),
    );
  }
}

InputDecoration _fieldDecoration(String label) => InputDecoration(
  labelText: label,
  labelStyle: TextStyle(
    fontFamily: AppFonts.rubik,
    fontSize: 13,
    color: AppColors.grayText,
  ),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
);

/// The role picker, filled from `admin_roles`.
class _RolePicker extends ConsumerWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  const _RolePicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roles = ref.watch(adminRolesProvider);
    return roles.when(
      loading: () => const LinearProgressIndicator(minHeight: 2),
      error: (e, _) => Text(
        tr('לא ניתן לטעון תפקידים: ${adminErrorText(e)}', 'Could not load roles: ${adminErrorText(e)}'),
        style: TextStyle(fontFamily: AppFonts.rubik, color: AppColors.error),
      ),
      data: (list) => DropdownButtonFormField<String>(
        initialValue: value,
        style: TextStyle(
          fontFamily: AppFonts.rubik,
          fontSize: 14,
          color: AppColors.navy,
        ),
        decoration: _fieldDecoration(tr('תפקיד', 'Role')),
        items: [
          for (final r in list)
            DropdownMenuItem(
              value: r['id'] as String,
              child: Text(
                _roleLabel(r),
                style: TextStyle(fontFamily: AppFonts.rubik),
              ),
            ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _GrantDialog extends ConsumerStatefulWidget {
  const _GrantDialog();
  @override
  ConsumerState<_GrantDialog> createState() => _GrantDialogState();
}

class _GrantDialogState extends ConsumerState<_GrantDialog> {
  String? _profileId;
  String? _roleId;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final profiles = ref.watch(adminCandidateProfilesProvider);
    final members = ref.watch(adminTeamProvider).valueOrNull ?? const [];
    final activeIds = {
      for (final m in members)
        if (m['is_active'] == true) m['profile_id'],
    };

    return Directionality(
      textDirection: adminDir,
      child: AlertDialog(
        title: Text(
          tr('הוספת חבר צוות', 'Add team member'),
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('אפשר להוסיף רק מי שכבר נרשם לאפליקציה. מי שעוד לא נרשם — '
                'יירשם קודם, ואז יופיע כאן.', 'Only people already registered in the app can be added. Anyone not registered yet signs up first, then appears here.'),
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  fontSize: 12,
                  height: 1.5,
                  color: AppColors.grayText,
                ),
              ),
              const SizedBox(height: 14),
              profiles.when(
                loading: () => const LinearProgressIndicator(minHeight: 2),
                error: (e, _) => Text(
                  tr('לא ניתן לטעון משתמשים: ${adminErrorText(e)}', 'Could not load users: ${adminErrorText(e)}'),
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    color: AppColors.error,
                  ),
                ),
                data: (list) {
                  final options = [
                    for (final p in list)
                      if (!activeIds.contains(p['id'])) p,
                  ];
                  if (options.isEmpty) {
                    return Text(
                      tr('כל המשתמשים הרשומים כבר בצוות.', 'Every registered user is already on the team.'),
                      style: TextStyle(
                        fontFamily: AppFonts.rubik,
                        color: AppColors.grayText,
                      ),
                    );
                  }
                  return DropdownButtonFormField<String>(
                    initialValue: _profileId,
                    isExpanded: true,
                    decoration: _fieldDecoration(tr('משתמש', 'User')),
                    items: [
                      for (final p in options)
                        DropdownMenuItem(
                          value: p['id'] as String,
                          child: Text(
                            [
                              p['full_name'] as String? ?? '',
                              if ((p['email'] as String?)?.isNotEmpty ?? false)
                                p['email'] as String,
                            ].where((s) => s.isNotEmpty).join(' · '),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontFamily: AppFonts.rubik),
                          ),
                        ),
                    ],
                    onChanged: (v) => setState(() => _profileId = v),
                  );
                },
              ),
              const SizedBox(height: 14),
              _RolePicker(
                value: _roleId,
                onChanged: (v) => setState(() => _roleId = v),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              tr('ביטול', 'Cancel'),
              style: TextStyle(
                fontFamily: AppFonts.rubik,
                color: AppColors.grayText,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _saving || _profileId == null || _roleId == null
                ? null
                : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.midBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(tr('הוסף', 'Add'), style: TextStyle(fontFamily: AppFonts.rubik)),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(adminTeamProvider.notifier)
          .grant(profileId: _profileId!, roleId: _roleId!);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showAdminError(context, tr('ההוספה נכשלה', 'Adding failed'), e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _RoleDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> member;
  const _RoleDialog({required this.member});
  @override
  ConsumerState<_RoleDialog> createState() => _RoleDialogState();
}

class _RoleDialogState extends ConsumerState<_RoleDialog> {
  late String? _roleId = widget.member['role_id'] as String?;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.member['profiles'] as Map?;
    final isSelf =
        widget.member['profile_id'] == AdminTeamNotifier.currentProfileId;
    return Directionality(
      textDirection: adminDir,
      child: AlertDialog(
        title: Text(
          tr('עריכת חבר צוות', 'Edit team member'),
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p?['full_name'] as String? ?? '',
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                ),
              ),
              Text(
                p?['email'] as String? ?? '',
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  fontSize: 12,
                  color: AppColors.grayText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                tr('השם והאימייל שייכים לחשבון של המשתמש, והוא מעדכן אותם '
                'באפליקציה.', 'The name and email belong to the user\'s account, and they update them in the app.'),
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  fontSize: 11,
                  color: AppColors.grayLight,
                ),
              ),
              const SizedBox(height: 14),
              if (isSelf)
                Text(
                  tr('זה החשבון שלך — את התפקיד שלך יכול לשנות רק מנהל ראשי אחר.', 'This is your account — only another super admin can change your role.'),
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 12,
                    color: AppColors.grayText,
                  ),
                )
              else
                _RolePicker(
                  value: _roleId,
                  onChanged: (v) => setState(() => _roleId = v),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              isSelf ? tr('סגירה', 'Close') : tr('ביטול', 'Cancel'),
              style: TextStyle(
                fontFamily: AppFonts.rubik,
                color: AppColors.grayText,
              ),
            ),
          ),
          if (!isSelf)
            ElevatedButton(
              onPressed: _saving || _roleId == null ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.midBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(tr('שמור', 'Save'), style: TextStyle(fontFamily: AppFonts.rubik)),
            ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(adminTeamProvider.notifier)
          .changeRole(widget.member, _roleId!);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showAdminError(context, tr('השמירה נכשלה', 'Saving failed'), e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _TeamCard extends StatelessWidget {
  final Map<String, dynamic> member;
  final bool isSelf;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggle;
  const _TeamCard({
    required this.member,
    required this.isSelf,
    required this.onEdit,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = member['is_active'] as bool? ?? true;
    final role = member['admin_roles'] as Map?;
    final roleName = role?['name'] as String? ?? '';
    final roleLabel = role == null ? roleName : _roleLabel(role);
    final profile = member['profiles'] as Map?;
    final name = (profile?['full_name'] as String? ?? '').trim();
    final email = profile?['email'] as String? ?? '';
    final color = _roleColor(roleName);

    return Material(
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      elevation: 1,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: isActive ? 1 : 0.5,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Text(
                    name.isNotEmpty ? name.characters.first : '?',
                    style: TextStyle(
                      fontFamily: AppFonts.rubik,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isSelf ? tr('$name (את/ה)', '$name (you)') : name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppFonts.rubik,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppFonts.rubik,
                          fontSize: 12,
                          color: AppColors.grayText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      AdminPill(
                        isActive ? roleLabel : tr('$roleLabel · מושבת', '$roleLabel · disabled'),
                        color,
                      ),
                    ],
                  ),
                ),
                // Your own access has no switch: turning it off would shut
                // you out of the panel with nobody signed in to undo it. A
                // greyed switch read as "off", so it says so in words.
                if (isSelf)
                  Tooltip(
                    message: tr('אי אפשר להשבית את עצמך', 'You cannot disable yourself'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lock_outline,
                          size: 14,
                          color: AppColors.grayText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          tr('פעיל', 'Active'),
                          style: TextStyle(
                            fontFamily: AppFonts.rubik,
                            fontSize: 12,
                            color: AppColors.grayText,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Tooltip(
                    message: isActive ? tr('השבתת גישה', 'Disable access') : tr('החזרת גישה', 'Restore access'),
                    child: Switch(
                      value: isActive,
                      onChanged: onToggle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Colour by role, for telling the cards apart at a glance; a role the
  /// client adds later gets the neutral one.
  Color _roleColor(String r) => switch (r) {
    'super_admin' => AppColors.error,
    'content_editor' => AppColors.midBlue,
    'moderator' => AppColors.gold,
    'sales' || 'business_mgr' => AppColors.success,
    'finance' => AppColors.midBlue,
    _ => AppColors.grayLight,
  };
}

/// The roles' names in English. `admin_roles` holds them in Hebrew only, and
/// the eight roles are the system's own, so the panel names them by code.
const _roleNamesEn = {
  'super_admin': 'Super admin',
  'content_editor': 'Content editor',
  'business_mgr': 'Business manager',
  'sales': 'Sales',
  'moderator': 'Moderator',
  'finance': 'Finance',
  'support': 'Support',
  'analyst': 'Analyst',
};

String _roleLabel(Map role) {
  final name = role['name'] as String? ?? '';
  final he = role['label'] as String? ?? name;
  return tr(he, _roleNamesEn[name] ?? name);
}

/// Roles & rights: what each role may do, section by section.
///
/// The client asked to limit roles (2 Oct). The rights were rows in
/// `admin_role_permissions` that only the database could change; since 00050
/// the database enforces them and the panel shows each administrator only
/// the sections their role may view. This is where the main admin changes
/// them. The main admin's own role is not here: it may do everything,
/// whatever the rows say, so it can never be locked out.
class _RoleRightsDialog extends ConsumerStatefulWidget {
  const _RoleRightsDialog();

  @override
  ConsumerState<_RoleRightsDialog> createState() => _RoleRightsDialogState();
}

class _RoleRightsDialogState extends ConsumerState<_RoleRightsDialog> {
  /// The panel's sections by module — the same modules the sidebar and
  /// 00050's rules use.
  static List<(String, String)> get _modules => [
    ('articles', tr('כתבות ועמודי מידע', 'Articles and info pages')),
    ('events', tr('אירועים', 'Events')),
    ('businesses', tr('עסקים, נדל״ן, חניונים ומוסדות', 'Businesses, real estate, car parks, places')),
    ('categories', tr('קטגוריות, תגיות ושכונות', 'Categories, tags, neighbourhoods')),
    ('media', tr('מדיה', 'Media')),
    ('offers', tr('מבצעים', 'Deals')),
    ('campaigns', tr('קמפיינים ומיקומי פרסום', 'Campaigns and ad slots')),
    ('revenue', tr('הסכמים והכנסות', 'Agreements and revenue')),
    ('moderation', tr('ביקורות, תגובות ודיווחים', 'Reviews, comments, reports')),
    ('push', tr('התראות Push', 'Push notifications')),
    ('users', tr('משתמשים', 'Users')),
    ('audit', tr('יומן פעולות', 'Activity log')),
    ('settings', tr('הגדרות, אתגרים ובונה דף הבית', 'Settings, challenges, home builder')),
  ];

  static List<(String, String)> get _actions => [
    ('view', tr('צפייה', 'View')),
    ('create', tr('יצירה', 'Create')),
    ('edit', tr('עריכה', 'Edit')),
    ('delete', tr('מחיקה', 'Delete')),
  ];

  String? _roleId;

  /// module → action → allowed, as loaded and as changed.
  Map<String, Map<String, bool>> _saved = {};
  Map<String, Map<String, bool>> _rights = {};
  bool _loading = false;
  bool _saving = false;
  String? _error;

  Future<void> _load(String roleId) async {
    setState(() {
      _roleId = roleId;
      _loading = true;
      _error = null;
    });
    try {
      final rows = await SupabaseConfig.client
          .from('admin_role_permissions')
          .select('module, action, allowed')
          .eq('role_id', roleId);
      final rights = <String, Map<String, bool>>{};
      for (final r in List<Map<String, dynamic>>.from(rows)) {
        rights.putIfAbsent(r['module'] as String, () => {})[r['action'] as String] =
            r['allowed'] == true;
      }
      if (!mounted) return;
      setState(() {
        _saved = {for (final e in rights.entries) e.key: {...e.value}};
        _rights = rights;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = adminErrorText(e);
      });
    }
  }

  bool _allowed(String module, String action) => _rights[module]?[action] ?? false;

  void _set(String module, String action, bool on) {
    setState(() {
      final m = _rights.putIfAbsent(module, () => {});
      m[action] = on;
      // Creating, editing or deleting in a section the role cannot open
      // means nothing; opening one is implied by any of them.
      if (on && action != 'view') m['view'] = true;
      if (!on && action == 'view') {
        for (final a in ['create', 'edit', 'delete']) {
          if (m.containsKey(a)) m[a] = false;
        }
      }
    });
  }

  bool get _changed {
    for (final (module, _) in _modules) {
      for (final (action, _) in _actions) {
        if ((_saved[module]?[action] ?? false) != _allowed(module, action)) return true;
      }
    }
    return false;
  }

  Future<void> _save() async {
    final roleId = _roleId;
    if (roleId == null) return;
    setState(() => _saving = true);
    try {
      final rows = [
        for (final (module, _) in _modules)
          for (final (action, _) in _actions)
            if ((_saved[module]?[action] ?? false) != _allowed(module, action))
              {
                'role_id': roleId,
                'module': module,
                'action': action,
                'allowed': _allowed(module, action),
              },
      ];
      if (rows.isNotEmpty) {
        await SupabaseConfig.client
            .from('admin_role_permissions')
            .upsert(rows, onConflict: 'role_id,module,action');
      }
      if (!mounted) return;
      setState(() {
        _saved = {for (final e in _rights.entries) e.key: {...e.value}};
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('ההרשאות נשמרו', 'Rights saved'))),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAdminError(context, tr('השמירה נכשלה', 'Could not save'), e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roles = (ref.watch(adminRolesProvider).valueOrNull ?? const [])
        .where((r) => r['name'] != 'super_admin')
        .toList();

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tr('תפקידים והרשאות', 'Roles & rights'),
                style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.navy),
              ),
              const SizedBox(height: 4),
              Text(
                tr('מה כל תפקיד רשאי לעשות. המנהל הראשי רשאי הכול תמיד. שינוי חל בכניסה הבאה של חבר הצוות לניהול.',
                    'What each role may do. The super admin may always do everything. A change applies the next time the team member opens the panel.'),
                style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 12, color: AppColors.grayText),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _roleId,
                decoration: InputDecoration(labelText: tr('תפקיד', 'Role')),
                items: [
                  for (final r in roles)
                    DropdownMenuItem(
                      value: r['id'] as String,
                      child: Text(_roleLabel(r), style: TextStyle(fontFamily: AppFonts.rubik)),
                    ),
                ],
                onChanged: _saving
                    ? null
                    : (v) {
                        if (v != null) _load(v);
                      },
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _roleId == null
                    ? Center(
                        child: Text(
                          tr('בחרו תפקיד', 'Choose a role'),
                          style: TextStyle(fontFamily: AppFonts.rubik, color: AppColors.grayText),
                        ),
                      )
                    : _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(child: Text(_error!, style: TextStyle(fontFamily: AppFonts.rubik, color: AppColors.error)))
                    : SingleChildScrollView(
                        child: Table(
                          columnWidths: const {0: FlexColumnWidth(3)},
                          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                          children: [
                            TableRow(
                              decoration: BoxDecoration(
                                border: Border(bottom: BorderSide(color: AppColors.border)),
                              ),
                              children: [
                                const SizedBox(),
                                for (final (_, label) in _actions)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Text(
                                      label,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                              ],
                            ),
                            for (final (module, label) in _modules)
                              TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Text(label, style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13)),
                                  ),
                                  for (final (action, _) in _actions)
                                    Center(
                                      child: Checkbox(
                                        value: _allowed(module, action),
                                        onChanged: _saving ? null : (v) => _set(module, action, v ?? false),
                                      ),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(tr('סגירה', 'Close')),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saving || !_changed ? null : _save,
                    child: Text(tr('שמירה', 'Save')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

