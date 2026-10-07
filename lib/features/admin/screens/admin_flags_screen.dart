import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/admin_flags_provider.dart';
import '../widgets/admin_form_pickers.dart';
import '../admin_language.dart';
import '../ui/admin_kit.dart';

class AdminFlagsScreen extends ConsumerStatefulWidget {
  const AdminFlagsScreen({super.key});

  @override
  ConsumerState<AdminFlagsScreen> createState() => _AdminFlagsScreenState();
}

class _AdminFlagsScreenState extends ConsumerState<AdminFlagsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ─── Tab Bar ───
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: AppColors.border.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.midBlue,
            unselectedLabelColor: AppColors.grayText,
            indicatorColor: AppColors.midBlue,
            labelStyle: TextStyle(
              fontFamily: AppFonts.rubik,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: TextStyle(
              fontFamily: AppFonts.rubik,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: 'Feature Flags', icon: Icon(Icons.flag, size: 18)),
              Tab(
                text: 'Remote Config',
                icon: Icon(Icons.settings_remote, size: 18),
              ),
            ],
          ),
        ),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_FeatureFlagsTab(), _RemoteConfigTab()],
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Tab 1: Feature Flags
// ══════════════════════════════════════════════════════════════

/// What a flag does today, said out loud.
class _NotYetWiredNote extends StatelessWidget {
  final String? text;
  const _NotYetWiredNote({this.text});

  // The default is a getter so it follows the panel's language.
  String get _text =>
      text ??
      tr('השינויים כאן נשמרים בבסיס הנתונים, אך האפליקציה עדיין אינה '
        'קוראת את הדגלים — כיבוי מודול יירשם ולא ישנה את מה שהמשתמשים '
        'רואים. חיבור האפליקציה לדגלים הוא פיתוח נפרד.', 'Changes here are saved in the database, but the app does not read the flags yet — turning a module off is recorded and does not change what users see. Connecting the app to the flags is separate development.');

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.adminContentBg,
        border: Border.all(color: AppColors.adminCardBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: AppColors.adminTextLight),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _text,
              style: TextStyle(
                fontFamily: AppFonts.rubik,
                fontSize: 12,
                height: 1.5,
                color: AppColors.adminTextLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureFlagsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(adminFeatureFlagListProvider);

    return Column(
      children: [
        // Saying it plainly beats a switch that looks like it does
        // something. Nothing outside this panel reads `feature_flags` yet,
        // so a flag records the decision and the app carries on as before.
        const _NotYetWiredNote(),

        // ─── Stats ───
        if (asyncData.valueOrNull case final list?)
          Builder(
            builder: (_) {
              final enabled = list.where((f) => f['is_enabled'] == true).length;
              final full = list.where((f) => f['rollout_pct'] == 100).length;
              final partial = list
                  .where(
                    (f) =>
                        (f['rollout_pct'] as int? ?? 0) > 0 &&
                        (f['rollout_pct'] as int? ?? 0) < 100,
                  )
                  .length;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
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
                    _StatChip(tr('סה״כ Flags', 'Total flags'), '${list.length}', AppColors.navy),
                    const SizedBox(width: 16),
                    _StatChip(tr('מופעלים', 'Enabled'), '$enabled', AppColors.success),
                    const SizedBox(width: 16),
                    _StatChip('100% Rollout', '$full', AppColors.midBlue),
                    const SizedBox(width: 16),
                    _StatChip('Partial Rollout', '$partial', AppColors.gold),
                  ],
                ),
              );
            },
          ),

        // ─── Toolbar ───
        AdminListToolbar(
          search: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flag, size: 18, color: AppColors.navy),
              const SizedBox(width: 8),
              Text(
                'Feature Flags',
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          actions: [
            AdminToolbarButton(
              label: tr('Flag חדש', 'New flag'),
              onPressed: () => _showFlagEditor(context, ref),
            ),
          ],
        ),

        // ─── List ───
        Expanded(
          child: asyncData.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                tr('שגיאה: $e', 'Error: $e'),
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  color: AppColors.error,
                ),
              ),
            ),
            data: (list) {
              if (list.isEmpty) {
                return Center(
                  child: Text(
                    tr('אין Feature Flags', 'No feature flags'),
                    style: TextStyle(
                      fontFamily: AppFonts.rubik,
                      color: AppColors.grayText,
                    ),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final f = list[i];
                  final isEnabled = f['is_enabled'] as bool? ?? false;
                  final rollout = f['rollout_pct'] as int? ?? 0;
                  final platforms =
                      (f['platforms'] as List?)?.cast<String>() ?? [];

                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isEnabled
                            ? AppColors.success.withValues(alpha: 0.3)
                            : AppColors.border.withValues(alpha: 0.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.navy.withValues(
                                              alpha: 0.06,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            f['key'] as String? ?? '',
                                            style: TextStyle(
                                              fontFamily: AppFonts.rubik,
                                              fontSize: 11,
                                              color: AppColors.navy,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          f['label'] as String? ?? '',
                                          style: TextStyle(
                                            fontFamily: AppFonts.rubik,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.navy,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      f['description'] as String? ?? '',
                                      style: TextStyle(
                                        fontFamily: AppFonts.rubik,
                                        fontSize: 12,
                                        color: AppColors.grayText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: isEnabled,
                                activeThumbColor: AppColors.success,
                                onChanged: (_) async {
                                  try {
                                    await ref
                                        .read(
                                          adminFeatureFlagListProvider.notifier,
                                        )
                                        .toggleFlag(f['id'] as String);
                                  } catch (e) {
                                    if (context.mounted) {
                                      showAdminError(
                                        context,
                                        tr('השמירה נכשלה', 'Saving failed'),
                                        e,
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              // Rollout slider
                              Expanded(
                                child: _RolloutSlider(
                                  id: f['id'] as String,
                                  value: rollout,
                                  enabled: isEnabled,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Platforms
                              ...platforms.map(
                                (p) => Padding(
                                  padding: const EdgeInsetsDirectional.only(end: 4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceLight,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      p,
                                      style: TextStyle(
                                        fontFamily: AppFonts.rubik,
                                        fontSize: 10,
                                        color: AppColors.grayText,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                // `updated_by` is an admin_users id; the
                                // provider resolves it to a name. Null until
                                // somebody edits the flag here.
                                'by ${f['updated_by_name'] ?? '—'}',
                                style: TextStyle(
                                  fontFamily: AppFonts.rubik,
                                  fontSize: 10,
                                  color: AppColors.grayLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showFlagEditor(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _FlagEditorDialog(),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Tab 2: Remote Config
// ══════════════════════════════════════════════════════════════

class _RemoteConfigTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(adminRemoteConfigProvider);

    return Column(
      children: [
        // Only the keys named here are read; the rest are stored and read
        // by nothing, as with the flags.
        _NotYetWiredNote(
          text:
              tr('הגדרות פעילות: community_facebook_url (קישור לקבוצת '
              'הפייסבוק), community_share_url (קישור לטופס "שתפו אותנו"), '
              'community_news_category (קטגוריית החדשות בעמוד הקהילה) '
              'municipal_forms_url (לאן מוביל אריח "טפסים") '
              'ו-site_url (כתובת האתר בקישורי ההזמנה לקבוצות צעדים). שאר '
              'ההגדרות כאן נשמרות, אך האפליקציה והאתר עדיין אינם קוראים אותן.', 'Active settings: community_facebook_url (link to the Facebook group), community_share_url (link to the "Share with us" form), community_news_category (the news category on the Community page), municipal_forms_url (where the "Forms" tile leads) and site_url (the site address in step group invitation links). The other settings here are saved, but the app and the site do not read them yet.'),
        ),
        // ─── Toolbar ───
        AdminListToolbar(
          search: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.settings_remote, size: 18, color: AppColors.navy),
              const SizedBox(width: 8),
              Text(
                'Remote Config',
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          count: switch (asyncData.valueOrNull) {
            final list? => tr('${list.length} הגדרות', '${list.length} settings'),
            null => null,
          },
          actions: [
            AdminToolbarButton(
              label: tr('הגדרה חדשה', 'New setting'),
              onPressed: () => _showConfigEditor(context, ref),
            ),
          ],
        ),

        // ─── Config list ───
        Expanded(
          child: asyncData.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                tr('שגיאה: $e', 'Error: $e'),
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  color: AppColors.error,
                ),
              ),
            ),
            data: (list) {
              if (list.isEmpty) {
                return Center(
                  child: Text(
                    tr('אין הגדרות', 'No settings'),
                    style: TextStyle(
                      fontFamily: AppFonts.rubik,
                      color: AppColors.grayText,
                    ),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final c = list[i];
                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.5),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      title: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.midBlue.withValues(
                                alpha: 0.08,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              c['key'] as String? ?? '',
                              style: TextStyle(
                                fontFamily: AppFonts.rubik,
                                fontSize: 11,
                                color: AppColors.midBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              c['description'] as String? ?? '',
                              style: TextStyle(
                                fontFamily: AppFonts.rubik,
                                fontSize: 13,
                                color: AppColors.grayText,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            c['value'] as String? ?? '',
                            style: TextStyle(
                              fontFamily: AppFonts.rubik,
                              fontSize: 13,
                              color: AppColors.navy,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'by ${c['updated_by_name'] ?? '—'}',
                            style: TextStyle(
                              fontFamily: AppFonts.rubik,
                              fontSize: 10,
                              color: AppColors.grayLight,
                            ),
                          ),
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert,
                              size: 18,
                              color: AppColors.grayLight,
                            ),
                            onSelected: (v) {
                              if (v == 'edit') {
                                _showConfigEditor(context, ref, config: c);
                              }
                              if (v == 'delete') {
                                _confirmDelete(context, ref, c);
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text(
                                  tr('עריכה', 'Edit'),
                                  style: TextStyle(
                                    fontFamily: AppFonts.rubik,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text(
                                  tr('מחיקה', 'Delete'),
                                  style: TextStyle(
                                    fontFamily: AppFonts.rubik,
                                    fontSize: 13,
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// A setting has no hidden state to fall back on, so removing one is for
  /// good; the dialog says so and names it.
  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> c,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: adminDir,
        child: AlertDialog(
          title: Text(
            tr('מחיקת הגדרה', 'Delete setting'),
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            tr('למחוק את "${c['key']}"? ההגדרה תימחק לצמיתות.', 'Delete "${c['key']}"? The setting will be deleted permanently.'),
            style: TextStyle(fontFamily: AppFonts.rubik),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                tr('ביטול', 'Cancel'),
                style: TextStyle(fontFamily: AppFonts.rubik),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                tr('מחק', 'Delete'),
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(adminRemoteConfigProvider.notifier)
          .deleteConfig(c['id'] as String);
    } catch (e) {
      if (context.mounted) showAdminError(context, tr('המחיקה נכשלה', 'Deleting failed'), e);
    }
  }

  void _showConfigEditor(
    BuildContext context,
    WidgetRef ref, {
    Map<String, dynamic>? config,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ConfigEditorDialog(config: config),
    );
  }
}

/// The rollout slider on a flag's card. It moves with the finger and writes
/// once, when let go: writing on every step of a drag sent a request per
/// step and reloaded the list under the finger.
class _RolloutSlider extends ConsumerStatefulWidget {
  final String id;
  final int value;
  final bool enabled;
  const _RolloutSlider({
    required this.id,
    required this.value,
    required this.enabled,
  });

  @override
  ConsumerState<_RolloutSlider> createState() => _RolloutSliderState();
}

class _RolloutSliderState extends ConsumerState<_RolloutSlider> {
  late int _value = widget.value;

  @override
  void didUpdateWidget(_RolloutSlider old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _value = widget.value;
  }

  Future<void> _commit(int pct) async {
    if (pct == widget.value) return;
    try {
      await ref
          .read(adminFeatureFlagListProvider.notifier)
          .updateRollout(widget.id, pct);
    } catch (e) {
      if (!mounted) return;
      setState(() => _value = widget.value);
      showAdminError(context, tr('השמירה נכשלה', 'Saving failed'), e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rollout: $_value%',
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontSize: 11,
            color: AppColors.grayText,
          ),
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.midBlue,
            inactiveTrackColor: AppColors.grayLight.withValues(alpha: 0.3),
            thumbColor: AppColors.midBlue,
            overlayColor: AppColors.midBlue.withValues(alpha: 0.1),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: _value.toDouble(),
            min: 0,
            max: 100,
            divisions: 10,
            label: '$_value%',
            onChanged: widget.enabled
                ? (v) => setState(() => _value = v.round())
                : null,
            onChangeEnd: (v) => _commit(v.round()),
          ),
        ),
      ],
    );
  }
}

// ─── Flag Editor Dialog ───

class _FlagEditorDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_FlagEditorDialog> createState() => _FlagEditorDialogState();
}

class _FlagEditorDialogState extends ConsumerState<_FlagEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  final _key = TextEditingController();
  final _label = TextEditingController();
  final _description = TextEditingController();
  bool _isEnabled = false;
  int _rolloutPct = 0;

  @override
  void dispose() {
    _key.dispose();
    _label.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 520),
        child: Directionality(
          textDirection: adminDir,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        tr('Flag חדש', 'New flag'),
                        style: TextStyle(
                          fontFamily: AppFonts.rubik,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildField(
                          tr('מפתח (Key)', 'Key'),
                          _key,
                          hint: 'MY_FEATURE',
                          required: true,
                        ),
                        const SizedBox(height: 14),
                        _buildField(
                          tr('תווית', 'Label'),
                          _label,
                          hint: tr('פיצ\'ר חדש', 'New feature'),
                          required: true,
                        ),
                        const SizedBox(height: 14),
                        _buildField(
                          tr('תיאור', 'Description'),
                          _description,
                          hint: tr('מה הפיצ\'ר עושה', 'What the feature does'),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 14),
                        SwitchListTile(
                          title: Text(
                            tr('מופעל', 'On'),
                            style: TextStyle(
                              fontFamily: AppFonts.rubik,
                              fontSize: 14,
                            ),
                          ),
                          value: _isEnabled,
                          activeThumbColor: AppColors.success,
                          onChanged: (v) => setState(() => _isEnabled = v),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Rollout: $_rolloutPct%',
                          style: TextStyle(
                            fontFamily: AppFonts.rubik,
                            fontSize: 12,
                            color: AppColors.grayText,
                          ),
                        ),
                        Slider(
                          value: _rolloutPct.toDouble(),
                          min: 0,
                          max: 100,
                          divisions: 10,
                          activeColor: AppColors.midBlue,
                          onChanged: (v) =>
                              setState(() => _rolloutPct = v.round()),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          tr('ביטול', 'Cancel'),
                          style: TextStyle(
                            fontFamily: AppFonts.rubik,
                            fontSize: 13,
                            color: AppColors.grayText,
                          ),
                        ),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.midBlue,
                          minimumSize: const Size(120, 42),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                tr('יצירה', 'Create'),
                                style: TextStyle(
                                  fontFamily: AppFonts.rubik,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl, {
    String? hint,
    int maxLines = 1,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.grayText,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          validator: required
              ? (v) => (v ?? '').trim().isEmpty ? tr('שדה חובה', 'Required field') : null
              : null,
          style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: AppFonts.rubik,
              fontSize: 13,
              color: AppColors.grayLight,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
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
              borderSide: const BorderSide(color: AppColors.midBlue),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(adminFeatureFlagListProvider.notifier).createFlag({
        'key': _key.text.trim(),
        'label': _label.text.trim(),
        'description': _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        'is_enabled': _isEnabled,
        'rollout_pct': _rolloutPct,
        'platforms': ['ios', 'android', 'web'],
        // Who made the change is the signed-in administrator, which the
        // provider fills in. This wrote the client's name into a uuid column
        // whatever anyone did.
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      // A key that already exists is the likely one: `key` is unique.
      if (mounted) showAdminError(context, tr('השמירה נכשלה', 'Saving failed'), e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ─── Config Editor Dialog ───

class _ConfigEditorDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? config;
  const _ConfigEditorDialog({this.config});

  @override
  ConsumerState<_ConfigEditorDialog> createState() =>
      _ConfigEditorDialogState();
}

class _ConfigEditorDialogState extends ConsumerState<_ConfigEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  late final TextEditingController _key;
  late final TextEditingController _value;
  late final TextEditingController _description;

  bool get _isEditing => widget.config != null;

  @override
  void initState() {
    super.initState();
    final c = widget.config;
    _key = TextEditingController(text: c?['key'] as String? ?? '');
    _value = TextEditingController(text: c?['value'] as String? ?? '');
    _description = TextEditingController(
      text: c?['description'] as String? ?? '',
    );
  }

  @override
  void dispose() {
    _key.dispose();
    _value.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 460),
        child: Directionality(
          textDirection: adminDir,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _isEditing ? tr('עריכת הגדרה', 'Edit setting') : tr('הגדרה חדשה', 'New setting'),
                        style: TextStyle(
                          fontFamily: AppFonts.rubik,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildField(
                          tr('מפתח (Key)', 'Key'),
                          _key,
                          hint: 'HOME_HEADLINE',
                          required: true,
                        ),
                        const SizedBox(height: 14),
                        _buildField(
                          tr('ערך', 'Value'),
                          _value,
                          hint: tr('ערך ההגדרה...', 'Setting value...'),
                          maxLines: 3,
                          required: true,
                        ),
                        const SizedBox(height: 14),
                        _buildField(
                          tr('תיאור', 'Description'),
                          _description,
                          hint: tr('למה משמשת ההגדרה הזו', 'What this setting is for'),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          tr('ביטול', 'Cancel'),
                          style: TextStyle(
                            fontFamily: AppFonts.rubik,
                            fontSize: 13,
                            color: AppColors.grayText,
                          ),
                        ),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.midBlue,
                          minimumSize: const Size(120, 42),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isEditing ? tr('עדכון', 'Update') : tr('יצירה', 'Create'),
                                style: TextStyle(
                                  fontFamily: AppFonts.rubik,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl, {
    String? hint,
    int maxLines = 1,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.grayText,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          validator: required
              ? (v) => (v ?? '').trim().isEmpty ? tr('שדה חובה', 'Required field') : null
              : null,
          style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: AppFonts.rubik,
              fontSize: 13,
              color: AppColors.grayLight,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
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
              borderSide: const BorderSide(color: AppColors.midBlue),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final notifier = ref.read(adminRemoteConfigProvider.notifier);
    // Who saved it is filled in by the provider from the signed-in admin.
    // This used to write the client's name into a uuid column.
    final data = {
      'key': _key.text.trim(),
      'value': _value.text.trim(),
      'description': _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
    };
    try {
      if (_isEditing) {
        await notifier.updateConfig(widget.config!['id'] as String, data);
      } else {
        await notifier.createConfig(data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showAdminError(context, tr('השמירה נכשלה', 'Saving failed'), e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ─── Helper Widgets ───

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontSize: 12,
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
