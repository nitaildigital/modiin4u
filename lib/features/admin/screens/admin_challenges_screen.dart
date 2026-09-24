import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../providers/admin_challenges_provider.dart';

/// Step challenges.
///
/// The Step Counter screen shows whichever challenge is running now. Until
/// this section existed nothing could create one, so the card was hidden for
/// good and the feature was unreachable.
class AdminChallengesScreen extends ConsumerStatefulWidget {
  const AdminChallengesScreen({super.key});

  @override
  ConsumerState<AdminChallengesScreen> createState() =>
      _AdminChallengesScreenState();
}

class _AdminChallengesScreenState extends ConsumerState<AdminChallengesScreen> {
  final _searchController = TextEditingController();
  String _activeFilter = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminChallengeListProvider);
    final counts =
        ref.watch(challengeParticipantCountsProvider).valueOrNull ?? const {};
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
                  onChanged: (v) => ref
                      .read(adminChallengeListProvider.notifier)
                      .setSearch(v),
                  decoration: InputDecoration(
                    hintText: 'חיפוש אתגר...',
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
                          '${l.length} אתגרים',
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
                  'אתגר חדש',
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
                      'אין אתגרים עדיין. אתגר פעיל יופיע במסך מד הצעדים.',
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
        .read(adminChallengeListProvider.notifier)
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

  Widget _row(Map<String, dynamic> c, Map<String, int> counts, bool isWide) {
    final active = c['is_active'] as bool? ?? false;
    final goal = (c['goal'] as num?)?.toInt();
    final joined = counts[c['id']] ?? 0;

    return InkWell(
      onTap: () => _showEditor(challenge: c),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (c['name'] as String?) ?? '',
                    style: TextStyle(
                      fontFamily: AppFonts.rubik,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
                    ),
                  ),
                  if ((c['description'] as String?)?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 2),
                    Text(
                      c['description'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                  goal == null ? '—' : '$goal צעדים',
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 13,
                    color: AppColors.grayText,
                  ),
                ),
              ),
            Expanded(
              child: Text(
                '$joined משתתפים',
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
              onSelected: (v) => _handle(v, c),
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

  void _handle(String action, Map<String, dynamic> c) {
    final notifier = ref.read(adminChallengeListProvider.notifier);
    final id = c['id'] as String;
    switch (action) {
      case 'edit':
        _showEditor(challenge: c);
      case 'activate':
        notifier.updateChallenge(id, {'is_active': true});
      case 'deactivate':
        notifier.updateChallenge(id, {'is_active': false});
      case 'delete':
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(
              'מחיקת אתגר',
              style: TextStyle(
                fontFamily: AppFonts.rubik,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              'למחוק את "${c['name']}"? המשתתפים שנרשמו יימחקו יחד איתו.',
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
                  notifier.deleteChallenge(id);
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

  void _showEditor({Map<String, dynamic>? challenge}) {
    showDialog<void>(
      context: context,
      builder: (_) => _ChallengeEditor(challenge: challenge),
    );
  }
}

/// Create or edit one challenge.
class _ChallengeEditor extends ConsumerStatefulWidget {
  final Map<String, dynamic>? challenge;
  const _ChallengeEditor({this.challenge});

  @override
  ConsumerState<_ChallengeEditor> createState() => _ChallengeEditorState();
}

class _ChallengeEditorState extends ConsumerState<_ChallengeEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _goal;
  late final TextEditingController _reward;
  DateTime? _startAt;
  DateTime? _endAt;
  bool _isActive = true;
  bool _saving = false;

  bool get _isEditing => widget.challenge != null;

  @override
  void initState() {
    super.initState();
    final c = widget.challenge;
    _name = TextEditingController(text: c?['name'] as String? ?? '');
    _description = TextEditingController(
      text: c?['description'] as String? ?? '',
    );
    _goal = TextEditingController(text: (c?['goal'] as num?)?.toString() ?? '');
    _reward = TextEditingController(
      text: (c?['reward_points'] as num?)?.toString() ?? '',
    );
    _startAt = DateTime.tryParse(c?['start_at'] as String? ?? '');
    _endAt = DateTime.tryParse(c?['end_at'] as String? ?? '');
    _isActive = c?['is_active'] as bool? ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _goal.dispose();
    _reward.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool start) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (start ? _startAt : _endAt) ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (picked == null) return;
    setState(() => start ? _startAt = picked : _endAt = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    // The Step Counter screen only shows a challenge whose window contains
    // today, so a challenge with no dates would never appear. Saying so here
    // is better than saving one that silently does nothing.
    if (_startAt == null || _endAt == null) {
      _toast('יש לבחור תאריך התחלה וסיום');
      return;
    }
    if (!_endAt!.isAfter(_startAt!)) {
      _toast('תאריך הסיום חייב להיות אחרי תאריך ההתחלה');
      return;
    }

    setState(() => _saving = true);
    final fields = <String, dynamic>{
      'name': _name.text.trim(),
      'description': _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
      'goal': int.tryParse(_goal.text.trim()),
      'reward_points': int.tryParse(_reward.text.trim()) ?? 0,
      'challenge_type': 'steps',
      'start_at': _startAt!.toIso8601String(),
      // Inclusive of the closing day: a challenge ending on the 30th should
      // still be running on the evening of the 30th.
      'end_at': DateTime(
        _endAt!.year,
        _endAt!.month,
        _endAt!.day,
        23,
        59,
        59,
      ).toIso8601String(),
      'is_active': _isActive,
    };

    try {
      final notifier = ref.read(adminChallengeListProvider.notifier);
      if (_isEditing) {
        await notifier.updateChallenge(
          widget.challenge!['id'] as String,
          fields,
        );
      } else {
        await notifier.createChallenge(fields);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) _toast('שגיאה: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontFamily: AppFonts.rubik)),
        backgroundColor: AppColors.error,
      ),
    );
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
                      _isEditing ? 'עריכת אתגר' : 'אתגר חדש',
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
                      'שם האתגר *',
                      _name,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'שדה חובה' : null,
                    ),
                    _field('תיאור', _description, maxLines: 3),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            'יעד (צעדים)',
                            _goal,
                            hint: '150000',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _field(
                            'נקודות תגמול',
                            _reward,
                            hint: '100',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _dateField(
                            'התחלה *',
                            _startAt,
                            () => _pickDate(true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _dateField(
                            'סיום *',
                            _endAt,
                            () => _pickDate(false),
                          ),
                        ),
                      ],
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
                      subtitle: Text(
                        'אתגר פעיל שהתאריך של היום נמצא בטווח שלו יוצג במסך מד הצעדים',
                        style: TextStyle(
                          fontFamily: AppFonts.rubik,
                          fontSize: 12,
                          color: AppColors.grayText,
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
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
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

  Widget _dateField(String label, DateTime? value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
        ),
        child: Text(
          value == null
              ? 'בחרו תאריך'
              : '${value.day}/${value.month}/${value.year}',
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontSize: 13,
            color: value == null ? AppColors.grayLight : AppColors.navy,
          ),
        ),
      ),
    );
  }
}
