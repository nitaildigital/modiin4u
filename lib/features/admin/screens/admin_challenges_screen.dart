import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../providers/admin_challenges_provider.dart';
import '../widgets/admin_load_error.dart';
import '../admin_language.dart';

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
                    hintText: tr('חיפוש אתגר...', 'Search challenges...'),
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
              _chip(tr('הכל', 'All'), _activeFilter.isEmpty, () => _setFilter('')),
              _chip(
                tr('פעילים', 'Active'),
                _activeFilter == 'active',
                () => _setFilter('active'),
              ),
              _chip(
                tr('לא פעילים', 'Inactive'),
                _activeFilter == 'inactive',
                () => _setFilter('inactive'),
              ),
              const Spacer(),
              // `valueOrNull`, not `whenData(...).value`: the latter rethrows
              // on a failed load and greys the whole section instead of letting
              // the list below show the error and a retry.
              if (async.valueOrNull case final l?)
                Text(
                  tr('${l.length} אתגרים', '${l.length} challenges'),
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 13,
                    color: AppColors.grayText,
                  ),
                ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: () => _showEditor(),
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  tr('אתגר חדש', 'New challenge'),
                  style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => AdminLoadError(
              message: tr('שגיאה בטעינת האתגרים', 'Error loading the challenges'),
              error: e,
              onRetry: () =>
                  ref.read(adminChallengeListProvider.notifier).load(),
            ),
            data: (rows) {
              if (rows.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      tr('אין אתגרים עדיין. אתגר פעיל יופיע במסך מד הצעדים.', 'No challenges yet. An active challenge appears on the Step Counter screen.'),
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
    padding: const EdgeInsetsDirectional.only(end: 6),
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
                  // Named by the database, the first to reach the goal (00058).
                  if ((c['winner_name'] as String?)?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 2),
                    Text(
                      tr('🏆 זוכה: ${c['winner_name']}', '🏆 Winner: ${c['winner_name']}') +
                          ((c['won_steps'] as num?) == null ? '' : tr(' · ${c['won_steps']} צעדים', ' · ${c['won_steps']} steps')),
                      style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success),
                    ),
                  ],
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
                  goal == null ? '—' : tr('$goal צעדים', '$goal steps'),
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 13,
                    color: AppColors.grayText,
                  ),
                ),
              ),
            Expanded(
              child: Text(
                tr('$joined משתתפים', '$joined participants'),
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
                  active ? tr('פעיל', 'Active') : tr('לא פעיל', 'Inactive'),
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
                    tr('עריכה', 'Edit'),
                    style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
                  ),
                ),
                PopupMenuItem(
                  value: active ? 'deactivate' : 'activate',
                  child: Text(
                    active ? tr('השבתה', 'Disable') : tr('הפעלה', 'Activate'),
                    style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
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
        runAdminAction(
          context,
          () => notifier.updateChallenge(id, {'is_active': true}),
        );
      // השבתה is the only way out: a delete removed the row for good, which
      // the client's rule forbids — removal in the panel must be undoable.
      case 'deactivate':
        runAdminAction(
          context,
          () => notifier.updateChallenge(id, {'is_active': false}),
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
  // The prize, as the client words it — on the banner and in the win
  // message (00058).
  late final TextEditingController _prize;
  late final TextEditingController _prizeEn;
  bool _perDay = false;
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
    _prize = TextEditingController(text: c?['prize'] as String? ?? '');
    _prizeEn = TextEditingController(text: c?['prize_en'] as String? ?? '');
    _perDay = c?['goal_per_day'] as bool? ?? false;
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
    _prize.dispose();
    _prizeEn.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool start) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      locale: adminLocale,
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
      _toast(tr('יש לבחור תאריך התחלה וסיום', 'A start and end date must be chosen'));
      return;
    }
    if (!_endAt!.isAfter(_startAt!)) {
      _toast(tr('תאריך הסיום חייב להיות אחרי תאריך ההתחלה', 'The end date must be after the start date'));
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
      'prize': _prize.text.trim().isEmpty ? null : _prize.text.trim(),
      'prize_en': _prizeEn.text.trim().isEmpty ? null : _prizeEn.text.trim(),
      'goal_per_day': _perDay,
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
      if (mounted) _toast(tr('שגיאה: $e', 'Error: $e'));
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
                      _isEditing ? tr('עריכת אתגר', 'Edit challenge') : tr('אתגר חדש', 'New challenge'),
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
                      tr('שם האתגר *', 'Challenge name *'),
                      _name,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? tr('שדה חובה', 'Required field') : null,
                    ),
                    _field(tr('תיאור', 'Description'), _description, maxLines: 3),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            tr('יעד (צעדים)', 'Goal (steps)'),
                            _goal,
                            hint: '150000',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _field(
                            tr('נקודות תגמול', 'Reward points'),
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
                          child: _field(
                            tr('פרס', 'Prize (Hebrew)'),
                            _prize,
                            hint: tr('לדוגמה: שובר בשווי 500 ₪', 'e.g. שובר בשווי 500 ₪'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _field(
                            tr('פרס (אנגלית)', 'Prize (English)'),
                            _prizeEn,
                            hint: 'e.g. a ₪500 voucher',
                          ),
                        ),
                      ],
                    ),
                    SwitchListTile(
                      value: _perDay,
                      onChanged: (v) => setState(() => _perDay = v),
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        tr('היעד ביום אחד', 'Goal in a single day'),
                        style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14),
                      ),
                      subtitle: Text(
                        tr('הראשון שמגיע ליעד ביום אחד זוכה. כבוי: הצעדים מצטברים מתחילת האתגר.',
                            'The first to reach the goal in one day wins. Off: steps add up from the start.'),
                        style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 12, color: AppColors.grayText),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _dateField(
                            tr('התחלה *', 'Start *'),
                            _startAt,
                            () => _pickDate(true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _dateField(
                            tr('סיום *', 'End *'),
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
                        tr('פעיל', 'Active'),
                        style: TextStyle(
                          fontFamily: AppFonts.rubik,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        tr('אתגר פעיל שהתאריך של היום נמצא בטווח שלו יוצג במסך מד הצעדים', 'An active challenge whose date range includes today is shown on the Step Counter screen'),
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
                        tr('ביטול', 'Cancel'),
                        style: TextStyle(fontFamily: AppFonts.rubik),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: Text(
                        _saving ? tr('שומר...', 'Saving...') : tr('שמירה', 'Save'),
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
              ? tr('בחרו תאריך', 'Choose a date')
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
