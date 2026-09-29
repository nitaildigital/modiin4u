import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/admin_team_provider.dart';
import '../widgets/admin_form_pickers.dart';

class AdminTeamScreen extends ConsumerStatefulWidget {
  const AdminTeamScreen({super.key});
  @override
  ConsumerState<AdminTeamScreen> createState() => _AdminTeamScreenState();
}

class _AdminTeamScreenState extends ConsumerState<AdminTeamScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: AppColors.border.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: isWide ? 280 : 180,
                height: 40,
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'חיפוש לפי שם או אימייל...',
                    hintStyle: TextStyle(
                      fontFamily: AppFonts.rubik,
                      fontSize: 13,
                      color: AppColors.grayLight,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 18,
                      color: AppColors.grayLight,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.turquoise),
                    ),
                  ),
                  onChanged: (v) => ref
                      .read(adminTeamProvider.notifier)
                      .setSearch(v.isEmpty ? null : v),
                ),
              ),
              const Spacer(),
              if (count != null)
                Text(
                  '$count חברי צוות',
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 13,
                    color: AppColors.grayText,
                  ),
                ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showGrant(context),
                icon: const Icon(Icons.person_add, size: 18),
                label: Text(
                  'הוספת חבר צוות',
                  style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.turquoise,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ─── Cards Grid ───
        Expanded(
          child: asyncData.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                'שגיאה בטעינת הצוות: ${adminErrorText(e)}',
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
                        'אין חברי צוות',
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
      if (mounted) showAdminError(context, 'לא בוצע', e);
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
        'לא ניתן לטעון תפקידים: ${adminErrorText(e)}',
        style: TextStyle(fontFamily: AppFonts.rubik, color: AppColors.error),
      ),
      data: (list) => DropdownButtonFormField<String>(
        initialValue: value,
        style: TextStyle(
          fontFamily: AppFonts.rubik,
          fontSize: 14,
          color: AppColors.navy,
        ),
        decoration: _fieldDecoration('תפקיד'),
        items: [
          for (final r in list)
            DropdownMenuItem(
              value: r['id'] as String,
              child: Text(
                r['label'] as String? ?? r['name'] as String,
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
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(
          'הוספת חבר צוות',
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
                'אפשר להוסיף רק מי שכבר נרשם לאפליקציה. מי שעוד לא נרשם — '
                'יירשם קודם, ואז יופיע כאן.',
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
                  'לא ניתן לטעון משתמשים: ${adminErrorText(e)}',
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
                      'כל המשתמשים הרשומים כבר בצוות.',
                      style: TextStyle(
                        fontFamily: AppFonts.rubik,
                        color: AppColors.grayText,
                      ),
                    );
                  }
                  return DropdownButtonFormField<String>(
                    initialValue: _profileId,
                    isExpanded: true,
                    decoration: _fieldDecoration('משתמש'),
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
              'ביטול',
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
              backgroundColor: AppColors.turquoise,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('הוסף', style: TextStyle(fontFamily: AppFonts.rubik)),
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
      if (mounted) showAdminError(context, 'ההוספה נכשלה', e);
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
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(
          'עריכת חבר צוות',
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
                'השם והאימייל שייכים לחשבון של המשתמש, והוא מעדכן אותם '
                'באפליקציה.',
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  fontSize: 11,
                  color: AppColors.grayLight,
                ),
              ),
              const SizedBox(height: 14),
              if (isSelf)
                Text(
                  'זה החשבון שלך — את התפקיד שלך יכול לשנות רק מנהל ראשי אחר.',
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
              isSelf ? 'סגירה' : 'ביטול',
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
                backgroundColor: AppColors.turquoise,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('שמור', style: TextStyle(fontFamily: AppFonts.rubik)),
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
      if (mounted) showAdminError(context, 'השמירה נכשלה', e);
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
    final roleLabel = role?['label'] as String? ?? roleName;
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
                        isSelf ? '$name (את/ה)' : name,
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isActive ? roleLabel : '$roleLabel · מושבת',
                          style: TextStyle(
                            fontFamily: AppFonts.rubik,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Your own access has no switch: turning it off would shut
                // you out of the panel with nobody signed in to undo it. A
                // greyed switch read as "off", so it says so in words.
                if (isSelf)
                  Tooltip(
                    message: 'אי אפשר להשבית את עצמך',
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
                          'פעיל',
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
                    message: isActive ? 'השבתת גישה' : 'החזרת גישה',
                    child: Switch(
                      value: isActive,
                      onChanged: onToggle,
                      activeThumbColor: AppColors.turquoise,
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
    'finance' => AppColors.turquoise,
    _ => AppColors.grayLight,
  };
}
