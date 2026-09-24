import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/network_photo.dart';
import '../providers/admin_agents_provider.dart';
import '../widgets/image_upload_field.dart';

/// Estate agents.
///
/// A listing can be credited to one, and the listing page shows the agent's
/// name, agency, photograph and telephone number. Nothing could create an
/// agent, so `listings.agent_id` could never be set and that block never
/// appeared.
class AdminAgentsScreen extends ConsumerStatefulWidget {
  const AdminAgentsScreen({super.key});

  @override
  ConsumerState<AdminAgentsScreen> createState() => _AdminAgentsScreenState();
}

class _AdminAgentsScreenState extends ConsumerState<AdminAgentsScreen> {
  final _searchController = TextEditingController();
  String _activeFilter = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminAgentListProvider);
    final counts =
        ref.watch(agentListingCountsProvider).valueOrNull ?? const {};
    final isWide = MediaQuery.of(context).size.width > 900;

    return Column(
      children: [
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
                  onChanged: (v) =>
                      ref.read(adminAgentListProvider.notifier).setSearch(v),
                  decoration: InputDecoration(
                    hintText: 'חיפוש מתווך / סוכנות...',
                    hintStyle: TextStyle(
                      fontFamily: AppFonts.rubik,
                      fontSize: 13,
                      color: AppColors.grayLight,
                    ),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _chip('הכל', _activeFilter.isEmpty, () => _setFilter('')),
              _chip(
                'פעילים',
                _activeFilter == 'active',
                () => _setFilter('active'),
              ),
              _chip(
                'לא פעילים',
                _activeFilter == 'inactive',
                () => _setFilter('inactive'),
              ),
              const Spacer(),
              async
                      .whenData(
                        (l) => Text(
                          '${l.length} מתווכים',
                          style: TextStyle(
                            fontFamily: AppFonts.rubik,
                            fontSize: 13,
                            color: AppColors.grayText,
                          ),
                        ),
                      )
                      .value ??
                  const SizedBox.shrink(),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: () => _showEditor(),
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  'מתווך חדש',
                  style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text('$e', style: TextStyle(fontFamily: AppFonts.rubik)),
            ),
            data: (rows) {
              if (rows.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'אין מתווכים עדיין. מתווך שנוסיף כאן יוכל להיות משויך למודעת נדל\u05f4ן.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppFonts.rubik,
                        fontSize: 13,
                        color: AppColors.grayText,
                      ),
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: rows.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  color: AppColors.border.withValues(alpha: 0.3),
                ),
                itemBuilder: (_, i) => _row(rows[i], counts, isWide),
              );
            },
          ),
        ),
      ],
    );
  }

  void _setFilter(String f) {
    setState(() => _activeFilter = f);
    ref
        .read(adminAgentListProvider.notifier)
        .setActiveFilter(f.isEmpty ? null : f);
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(left: 6),
    child: FilterChip(
      label: Text(
        label,
        style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 12),
      ),
      selected: selected,
      onSelected: (_) => onTap(),
    ),
  );

  Widget _row(Map<String, dynamic> a, Map<String, int> counts, bool isWide) {
    final active = a['is_active'] as bool? ?? true;
    final listings = counts[a['id']] ?? 0;

    return InkWell(
      onTap: () => _showEditor(agent: a),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            NetworkPhoto(
              url: a['photo_url'] as String?,
              width: 40,
              height: 40,
              radius: BorderRadius.circular(20),
              icon: Icons.person_outline,
              iconSize: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (a['name'] as String?) ?? '',
                    style: TextStyle(
                      fontFamily: AppFonts.rubik,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
                    ),
                  ),
                  if ((a['agency'] as String?)?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 2),
                    Text(
                      a['agency'] as String,
                      style: TextStyle(
                        fontFamily: AppFonts.rubik,
                        fontSize: 12,
                        color: AppColors.grayText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isWide)
              Expanded(
                child: Text(
                  (a['phone'] as String?) ?? '—',
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 13,
                    color: AppColors.grayText,
                  ),
                ),
              ),
            Expanded(
              child: Text(
                '$listings מודעות',
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  fontSize: 13,
                  color: AppColors.grayText,
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: (active ? AppColors.success : AppColors.grayLight)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  active ? 'פעיל' : 'לא פעיל',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 12,
                    color: active ? AppColors.success : AppColors.grayText,
                  ),
                ),
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert,
                size: 18,
                color: AppColors.grayLight,
              ),
              onSelected: (v) => _handle(v, a, listings),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Text(
                    'עריכה',
                    style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
                  ),
                ),
                PopupMenuItem(
                  value: active ? 'deactivate' : 'activate',
                  child: Text(
                    active ? 'השבתה' : 'הפעלה',
                    style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'מחיקה',
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
  }

  void _handle(String action, Map<String, dynamic> a, int listings) {
    final notifier = ref.read(adminAgentListProvider.notifier);
    final id = a['id'] as String;
    switch (action) {
      case 'edit':
        _showEditor(agent: a);
      case 'activate':
        notifier.updateAgent(id, {'is_active': true});
      case 'deactivate':
        notifier.updateAgent(id, {'is_active': false});
      case 'delete':
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(
              'מחיקת מתווך',
              style: TextStyle(
                fontFamily: AppFonts.rubik,
                fontWeight: FontWeight.w700,
              ),
            ),
            // Deleting nulls `listings.agent_id` rather than removing the
            // listing, so the count is shown to make that plain.
            content: Text(
              listings == 0
                  ? 'למחוק את "${a['name']}"?'
                  : 'למחוק את "${a['name']}"? $listings מודעות יישארו, אך ללא שיוך למתווך.',
              style: TextStyle(fontFamily: AppFonts.rubik),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'ביטול',
                  style: TextStyle(fontFamily: AppFonts.rubik),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  notifier.deleteAgent(id);
                },
                child: Text(
                  'מחק',
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }

  void _showEditor({Map<String, dynamic>? agent}) {
    showDialog<void>(
      context: context,
      builder: (_) => _AgentEditor(agent: agent),
    );
  }
}

/// Create or edit one agent.
class _AgentEditor extends ConsumerStatefulWidget {
  final Map<String, dynamic>? agent;
  const _AgentEditor({this.agent});

  @override
  ConsumerState<_AgentEditor> createState() => _AgentEditorState();
}

class _AgentEditorState extends ConsumerState<_AgentEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _agency;
  late final TextEditingController _phone;
  late final TextEditingController _whatsapp;
  late final TextEditingController _email;
  late final TextEditingController _licence;
  late final TextEditingController _about;
  late final TextEditingController _photoUrl;
  bool _isActive = true;
  bool _saving = false;

  bool get _isEditing => widget.agent != null;

  @override
  void initState() {
    super.initState();
    final a = widget.agent;
    _name = TextEditingController(text: a?['name'] as String? ?? '');
    _agency = TextEditingController(text: a?['agency'] as String? ?? '');
    _phone = TextEditingController(text: a?['phone'] as String? ?? '');
    _whatsapp = TextEditingController(text: a?['whatsapp'] as String? ?? '');
    _email = TextEditingController(text: a?['email'] as String? ?? '');
    _licence = TextEditingController(text: a?['licence_no'] as String? ?? '');
    _about = TextEditingController(text: a?['about'] as String? ?? '');
    _photoUrl = TextEditingController(text: a?['photo_url'] as String? ?? '');
    _isActive = a?['is_active'] as bool? ?? true;
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _agency,
      _phone,
      _whatsapp,
      _email,
      _licence,
      _about,
      _photoUrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _empty(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final fields = <String, dynamic>{
      'name': _name.text.trim(),
      'agency': _empty(_agency),
      'phone': _empty(_phone),
      'whatsapp': _empty(_whatsapp),
      'email': _empty(_email),
      'licence_no': _empty(_licence),
      'about': _empty(_about),
      'photo_url': _empty(_photoUrl),
      'is_active': _isActive,
    };

    try {
      final notifier = ref.read(adminAgentListProvider.notifier);
      if (_isEditing) {
        await notifier.updateAgent(widget.agent!['id'] as String, fields);
      } else {
        await notifier.createAgent(fields);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'שגיאה: $e',
              style: TextStyle(fontFamily: AppFonts.rubik),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: Row(
                  children: [
                    Text(
                      _isEditing ? 'עריכת מתווך' : 'מתווך חדש',
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
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _field(
                      'שם *',
                      _name,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'שדה חובה' : null,
                    ),
                    _field('סוכנות', _agency),
                    Row(
                      children: [
                        Expanded(child: _field('טלפון', _phone)),
                        const SizedBox(width: 12),
                        Expanded(child: _field('וואטסאפ', _whatsapp)),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(child: _field('אימייל', _email)),
                        const SizedBox(width: 12),
                        Expanded(child: _field('מספר רישיון', _licence)),
                      ],
                    ),
                    _field('אודות', _about, maxLines: 3),
                    ImageUploadField(
                      label: 'תמונה',
                      controller: _photoUrl,
                      folder: 'agents',
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'פעיל',
                        style: TextStyle(
                          fontFamily: AppFonts.rubik,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'ביטול',
                        style: TextStyle(fontFamily: AppFonts.rubik),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: Text(
                        _saving ? 'שומר...' : 'שמירה',
                        style: TextStyle(fontFamily: AppFonts.rubik),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
