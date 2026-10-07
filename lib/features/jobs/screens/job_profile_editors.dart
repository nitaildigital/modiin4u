import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/router/app_router.dart' show AppNavigation;
import '../../../shared/widgets/m_kit.dart';
import '../../../shared/widgets/m_step_form.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/widgets/m_account_widgets.dart';
import '../models/job.dart';
import '../providers/job_providers.dart';

/// The pages behind the pencils and pluses of My Profile (`user_side/`, 7
/// Oct): Basic details, About me, Skills, Work experience, Education and
/// Additional information. Each is a back arrow, a large title, white
/// bordered cards holding one field each, and Save pinned to the bottom.

/// Reloads My Profile, and anyone else's view of it, after a change.
void refreshJobSeeker(WidgetRef ref) {
  ref.invalidate(myJobSeekerProvider);
  ref.invalidate(jobSeekerProvider);
}

/// Asks before something is removed; true when the person agrees.
Future<bool> confirmJobProfileRemoval(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      title: Text(title, style: mText(17, weight: FontWeight.w600)),
      content: Text(message, style: mText(14, color: mStepGrey, height: 1.4)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(mTr(ctx, 'Cancel', 'ביטול'), style: mText(14, weight: FontWeight.w500, color: mStepGrey)),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(mTr(ctx, 'Delete', 'מחיקה'), style: mText(14, weight: FontWeight.w600, color: mKitRed)),
        ),
      ],
    ),
  );
  return ok ?? false;
}

const _maxLongText = 1000;
const _maxSkills = 30;

/// "September 2025" / "ספטמבר 2025": the month and year the date fields show.
String _monthYear(BuildContext context, DateTime d) {
  const en = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  const he = [
    'ינואר', 'פברואר', 'מרץ', 'אפריל', 'מאי', 'יוני',
    'יולי', 'אוגוסט', 'ספטמבר', 'אוקטובר', 'נובמבר', 'דצמבר',
  ];
  return mTr(context, '${en[d.month - 1]} ${d.year}', '${he[d.month - 1]} ${d.year}');
}

String? _orNull(String s) => s.trim().isEmpty ? null : s.trim();

// ═══════════════════════════════════════════════════
// The page and its fields
// ═══════════════════════════════════════════════════

class _EditorPage extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final VoidCallback? onSave;
  final bool saving;
  final Widget? action;

  const _EditorPage({
    required this.title,
    required this.children,
    required this.onSave,
    this.saving = false,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(15, 10, 8, 0),
                  child: SizedBox(
                    height: 36,
                    child: Row(
                      children: [
                        MBackArrow(
                          color: const Color(0xFF3D3D3D),
                          onTap: () => context.back('/my-profile'),
                        ),
                        const Spacer(),
                        ?action,
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsetsDirectional.fromSTEB(16, 6, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(title, style: mHeading(26)),
                        const SizedBox(height: 14),
                        ...children,
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: MButton(
                      label: mTr(context, 'Save', 'שמירה'),
                      loading: saving,
                      onTap: onSave,
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
}

/// The page while the profile it edits is still on its way — reached
/// straight from an address rather than from My Profile.
class _LoadingPage extends ConsumerWidget {
  final String title;
  final AsyncValue<JobSeekerData> data;
  final Widget Function(JobSeekerData data) builder;

  const _LoadingPage({required this.title, required this.data, required this.builder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return data.when(
      data: builder,
      loading: () => _EditorPage(
        title: title,
        onSave: null,
        children: const [
          Padding(
            padding: EdgeInsets.only(top: 60),
            child: Center(child: CircularProgressIndicator(color: mStepMid)),
          ),
        ],
      ),
      error: (_, _) => _EditorPage(
        title: title,
        onSave: null,
        children: [
          const SizedBox(height: 40),
          Text(
            mTr(context, 'Your profile could not be loaded.', 'לא ניתן לטעון את הפרופיל.'),
            textAlign: TextAlign.center,
            style: mText(14, color: mStepGrey),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => refreshJobSeeker(ref),
              child: Text(mTr(context, 'Try again', 'נסו שוב'), style: mText(14, weight: FontWeight.w600, color: mStepMid)),
            ),
          ),
        ],
      ),
    );
  }
}

/// One field: a white bordered card, the grey label above the value.
class _FieldCard extends StatelessWidget {
  final String label;
  final Widget child;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _FieldCard({required this.label, required this.child, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: mStepHairline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: mText(13, weight: FontWeight.w500, color: mStepGrey)),
                const SizedBox(height: 8),
                child,
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: onTap == null ? card : GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: card),
    );
  }
}

/// A one-line text field in its card.
class _TextField extends StatelessWidget {
  final String label;
  final String placeholder;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  const _TextField({
    required this.label,
    required this.placeholder,
    required this.controller,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return _FieldCard(
      label: label,
      child: MInputRow(placeholder: placeholder, controller: controller, keyboardType: keyboardType),
    );
  }
}

/// The tall card for a paragraph, with "n/1000" under it.
class _LongTextField extends StatelessWidget {
  final String label;
  final String placeholder;
  final TextEditingController controller;

  const _LongTextField({required this.label, required this.placeholder, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 270,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: mStepHairline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: mText(13, weight: FontWeight.w500, color: mStepGrey)),
                const SizedBox(height: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    expands: true,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textAlignVertical: TextAlignVertical.top,
                    inputFormatters: [LengthLimitingTextInputFormatter(_maxLongText)],
                    style: mText(14, height: 1.45),
                    decoration: InputDecoration(
                      hintText: placeholder,
                      hintMaxLines: 3,
                      hintStyle: mText(14, color: mStepGrey, height: 1.45),
                      // The theme fills inputs grey and rounds them; this one
                      // sits inside the white bordered card.
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, v, _) => Text(
              '${v.text.characters.length}/$_maxLongText',
              textAlign: TextAlign.end,
              style: mText(12, color: mStepGrey),
            ),
          ),
        ],
      ),
    );
  }
}

/// A month and year, chosen from the date picker opened on its years.
class _MonthField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final DateTime lastDate;
  final ValueChanged<DateTime> onChanged;

  const _MonthField({required this.label, required this.value, required this.lastDate, required this.onChanged});

  Future<void> _pick(BuildContext context) async {
    final first = DateTime(1950);
    var initial = value ?? DateTime.now();
    if (initial.isAfter(lastDate)) initial = lastDate;
    if (initial.isBefore(first)) initial = first;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: lastDate,
      initialDatePickerMode: DatePickerMode.year,
    );
    // The profile keeps a month, not a day.
    if (picked != null) onChanged(DateTime(picked.year, picked.month));
  }

  @override
  Widget build(BuildContext context) {
    final v = value;
    return _FieldCard(
      label: label,
      onTap: () => _pick(context),
      trailing: const Icon(IconsaxPlusLinear.calendar_1, size: 20, color: mStepGrey),
      child: SizedBox(
        height: 20,
        child: Text(
          v == null ? mTr(context, 'Month / Year', 'חודש / שנה') : _monthYear(context, v),
          style: mText(14, color: v == null ? mStepGrey : mStepInk),
        ),
      ),
    );
  }
}

/// The square tick box with its label ("Currently working here").
class _CheckRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CheckRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: value ? mStepMid : Colors.white,
                border: Border.all(color: mStepMid, width: 1.4),
                borderRadius: BorderRadius.circular(4),
              ),
              child: value ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: mText(14, color: const Color(0xFF3D3D3D)))),
          ],
        ),
      ),
    );
  }
}

/// "Delete" in the top bar of an entry that already exists.
class _DeleteAction extends StatelessWidget {
  final VoidCallback? onTap;
  const _DeleteAction({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(mTr(context, 'Delete', 'מחיקה'), style: mText(14, weight: FontWeight.w600, color: mKitRed)),
    );
  }
}

/// Runs a save, then refreshes My Profile and goes back to it; a failure
/// stays on the page with a message.
Future<void> _save(
  BuildContext context,
  WidgetRef ref,
  void Function(bool saving) setSaving,
  Future<void> Function() write,
) async {
  setSaving(true);
  try {
    await write();
    refreshJobSeeker(ref);
    if (context.mounted) context.back('/my-profile');
  } catch (_) {
    if (context.mounted) {
      mToast(context, mTr(context, 'Could not save. Please try again.', 'השמירה נכשלה. נסו שוב.'), error: true);
    }
  } finally {
    if (context.mounted) setSaving(false);
  }
}

// ═══════════════════════════════════════════════════
// Basic details
// ═══════════════════════════════════════════════════

/// Email, phone, location and years of experience. The phone is the
/// account's (profiles); the location and experience are the job profile's.
class BasicDetailsEditor extends ConsumerWidget {
  const BasicDetailsEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _LoadingPage(
      title: mTr(context, 'Basic details', 'פרטים בסיסיים'),
      data: ref.watch(myJobSeekerProvider),
      builder: (d) => _BasicDetailsForm(profile: d.profile),
    );
  }
}

class _BasicDetailsForm extends ConsumerStatefulWidget {
  final JobProfile? profile;
  const _BasicDetailsForm({required this.profile});

  @override
  ConsumerState<_BasicDetailsForm> createState() => _BasicDetailsFormState();
}

class _BasicDetailsFormState extends ConsumerState<_BasicDetailsForm> {
  late final _phone = TextEditingController(text: ref.read(authProvider)?.phone ?? '');
  late final _location = TextEditingController(text: widget.profile?.location ?? '');
  late int? _years = widget.profile?.experienceYears;
  bool _saving = false;

  @override
  void dispose() {
    _phone.dispose();
    _location.dispose();
    super.dispose();
  }

  String _yearsLabel(int n) => switch (n) {
    0 => mTr(context, 'No experience', 'ללא ניסיון'),
    1 => mTr(context, '1 year', 'שנה אחת'),
    _ => mTr(context, '$n years', '$n שנים'),
  };

  void _onSave() {
    final user = ref.read(authProvider);
    final phone = _phone.text.trim();
    _save(context, ref, (v) => setState(() => _saving = v), () async {
      if (user != null && phone != user.phone) {
        await ref.read(authProvider.notifier).updateProfile(phone: phone);
      }
      await ref.read(jobRepositoryProvider).saveProfile({
        'location': _orNull(_location.text),
        'experience_years': _years,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(authProvider)?.email ?? '';
    return _EditorPage(
      title: mTr(context, 'Basic details', 'פרטים בסיסיים'),
      saving: _saving,
      onSave: _onSave,
      children: [
        // Changing the address one signs in with is not done here, so it is
        // shown greyed rather than as a field.
        _FieldCard(
          label: mTr(context, 'Email', 'אימייל'),
          child: SizedBox(
            height: 20,
            child: Text(email, maxLines: 1, overflow: TextOverflow.ellipsis, style: mText(14, color: mStepGrey)),
          ),
        ),
        _TextField(
          label: mTr(context, 'Phone', 'טלפון'),
          placeholder: mTr(context, 'Your phone number', 'מספר הטלפון שלך'),
          controller: _phone,
          keyboardType: TextInputType.phone,
        ),
        _TextField(
          label: mTr(context, 'Location', 'מיקום'),
          placeholder: mTr(context, 'e.g. Modiin', 'לדוגמה: מודיעין'),
          controller: _location,
        ),
        _FieldCard(
          label: mTr(context, 'Experience', 'ניסיון'),
          child: MDropdownRow<int>(
            placeholder: mTr(context, 'Select', 'בחירה'),
            value: _years,
            items: [
              for (var n = 0; n <= 30; n++) DropdownMenuItem(value: n, child: Text(_yearsLabel(n))),
            ],
            onChanged: (v) => setState(() => _years = v),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════
// About me / Additional information
// ═══════════════════════════════════════════════════

/// A paragraph on the job profile, under [column].
class _ParagraphForm extends ConsumerStatefulWidget {
  final String title;
  final String label;
  final String placeholder;
  final String column;
  final String? initial;

  const _ParagraphForm({
    required this.title,
    required this.label,
    required this.placeholder,
    required this.column,
    required this.initial,
  });

  @override
  ConsumerState<_ParagraphForm> createState() => _ParagraphFormState();
}

class _ParagraphFormState extends ConsumerState<_ParagraphForm> {
  late final _text = TextEditingController(text: widget.initial ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _EditorPage(
      title: widget.title,
      saving: _saving,
      onSave: () => _save(
        context,
        ref,
        (v) => setState(() => _saving = v),
        () => ref.read(jobRepositoryProvider).saveProfile({widget.column: _orNull(_text.text)}),
      ),
      children: [_LongTextField(label: widget.label, placeholder: widget.placeholder, controller: _text)],
    );
  }
}

class AboutMeEditor extends ConsumerWidget {
  const AboutMeEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = mTr(context, 'About me', 'קצת עליי');
    return _LoadingPage(
      title: title,
      data: ref.watch(myJobSeekerProvider),
      builder: (d) => _ParagraphForm(
        title: title,
        label: title,
        placeholder: mTr(
          context,
          'Tell employers what you do best and what you’re looking for.',
          'ספרו למעסיקים במה אתם הכי טובים ומה אתם מחפשים.',
        ),
        column: 'about',
        initial: d.profile?.about,
      ),
    );
  }
}

class AdditionalInfoEditor extends ConsumerWidget {
  const AdditionalInfoEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = mTr(context, 'Additional information', 'מידע נוסף');
    return _LoadingPage(
      title: title,
      data: ref.watch(myJobSeekerProvider),
      builder: (d) => _ParagraphForm(
        title: title,
        label: title,
        placeholder: mTr(
          context,
          'Share any other information you’d like employers to know.',
          'שתפו כל מידע נוסף שתרצו שמעסיקים ידעו.',
        ),
        column: 'additional_info',
        initial: d.profile?.additionalInfo,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Skills
// ═══════════════════════════════════════════════════

class SkillsEditor extends ConsumerWidget {
  const SkillsEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _LoadingPage(
      title: mTr(context, 'Skills', 'כישורים'),
      data: ref.watch(myJobSeekerProvider),
      builder: (d) => _SkillsForm(initial: d.profile?.skills ?? const []),
    );
  }
}

class _SkillsForm extends ConsumerStatefulWidget {
  final List<String> initial;
  const _SkillsForm({required this.initial});

  @override
  ConsumerState<_SkillsForm> createState() => _SkillsFormState();
}

class _SkillsFormState extends ConsumerState<_SkillsForm> {
  late final List<String> _skills = [...widget.initial];
  final _input = TextEditingController();
  final _focus = FocusNode();
  bool _saving = false;

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Adds what is typed; false when it could not be.
  bool _add() {
    final s = _input.text.trim();
    if (s.isEmpty) return true;
    if (_skills.any((k) => k.toLowerCase() == s.toLowerCase())) {
      _input.clear();
      return true;
    }
    if (_skills.length >= _maxSkills) {
      mToast(context, mTr(context, 'Up to $_maxSkills skills.', 'עד $_maxSkills כישורים.'), error: true);
      return false;
    }
    setState(() => _skills.add(s));
    _input.clear();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return _EditorPage(
      title: mTr(context, 'Skills', 'כישורים'),
      saving: _saving,
      onSave: () {
        // A skill typed but not yet added with Enter is kept too.
        if (!_add()) return;
        _save(
          context,
          ref,
          (v) => setState(() => _saving = v),
          () => ref.read(jobRepositoryProvider).saveProfile({'skills': _skills}),
        );
      },
      children: [
        _FieldCard(
          label: mTr(context, 'Skills', 'כישורים'),
          child: SizedBox(
            height: 20,
            child: TextField(
              controller: _input,
              focusNode: _focus,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                _add();
                // Keeps the keyboard up for the next one.
                _focus.requestFocus();
              },
              style: mText(14),
              decoration: InputDecoration(
                hintText: mTr(context, 'Search or add a skill…', 'חיפוש או הוספת כישור…'),
                hintStyle: mText(14, color: mStepGrey),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: [
            for (final s in _skills)
              MChip(s, background: mKitBlueBg, onRemove: () => setState(() => _skills.remove(s))),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════
// Work experience
// ═══════════════════════════════════════════════════

/// A job held, new or [existing].
class WorkExperienceEditor extends ConsumerStatefulWidget {
  final WorkExperience? existing;
  const WorkExperienceEditor({super.key, this.existing});

  @override
  ConsumerState<WorkExperienceEditor> createState() => _WorkExperienceEditorState();
}

class _WorkExperienceEditorState extends ConsumerState<WorkExperienceEditor> {
  late final _title = TextEditingController(text: widget.existing?.title ?? '');
  late final _company = TextEditingController(text: widget.existing?.company ?? '');
  late final _location = TextEditingController(text: widget.existing?.location ?? '');
  late final _description = TextEditingController(text: widget.existing?.description ?? '');
  late JobType? _type = widget.existing?.employmentType;
  late DateTime? _start = widget.existing?.startDate;
  late DateTime? _end = widget.existing?.endDate;
  late bool _current = widget.existing?.isCurrent ?? false;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _company.dispose();
    _location.dispose();
    _description.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_title.text.trim().isEmpty || _company.text.trim().isEmpty) {
      mToast(context, mTr(context, 'Add the job title and the company.', 'יש להזין תפקיד ושם חברה.'), error: true);
      return;
    }
    if (!_current && _start != null && _end != null && _end!.isBefore(_start!)) {
      mToast(context, mTr(context, 'The end date is before the start date.', 'תאריך הסיום מוקדם מתאריך ההתחלה.'), error: true);
      return;
    }
    final e = WorkExperience(
      id: widget.existing?.id,
      title: _title.text.trim(),
      company: _company.text.trim(),
      location: _orNull(_location.text),
      employmentType: _type,
      startDate: _start,
      endDate: _current ? null : _end,
      isCurrent: _current,
      description: _orNull(_description.text),
    );
    _save(context, ref, (v) => setState(() => _saving = v), () => ref.read(jobRepositoryProvider).saveExperience(e));
  }

  Future<void> _onDelete() async {
    final id = widget.existing?.id;
    if (id == null) return;
    final ok = await confirmJobProfileRemoval(
      context,
      title: mTr(context, 'Delete this experience?', 'למחוק את הניסיון הזה?'),
      message: mTr(context, 'It will be removed from your profile.', 'הוא יוסר מהפרופיל שלך.'),
    );
    if (!ok || !mounted) return;
    _save(context, ref, (v) => setState(() => _saving = v), () => ref.read(jobRepositoryProvider).deleteExperience(id));
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return _EditorPage(
      title: mTr(context, 'Work experience', 'ניסיון תעסוקתי'),
      saving: _saving,
      onSave: _onSave,
      action: widget.existing?.id == null ? null : _DeleteAction(onTap: _saving ? null : _onDelete),
      children: [
        _TextField(
          label: mTr(context, 'Job Title', 'תפקיד'),
          placeholder: mTr(context, 'Your role', 'התפקיד שלך'),
          controller: _title,
        ),
        _TextField(
          label: mTr(context, 'Company Name', 'שם החברה'),
          placeholder: mTr(context, 'Where you worked', 'איפה עבדת'),
          controller: _company,
        ),
        _TextField(
          label: mTr(context, 'Location', 'מיקום'),
          placeholder: mTr(context, 'e.g. Modiin', 'לדוגמה: מודיעין'),
          controller: _location,
        ),
        _FieldCard(
          label: mTr(context, 'Employment Type', 'סוג העסקה'),
          child: MDropdownRow<JobType>(
            placeholder: mTr(context, 'Select', 'בחירה'),
            value: _type,
            items: [for (final t in JobType.values) DropdownMenuItem(value: t, child: Text(t.label))],
            onChanged: (v) => setState(() => _type = v),
          ),
        ),
        _MonthField(
          label: mTr(context, 'Start Date', 'תאריך התחלה'),
          value: _start,
          lastDate: now,
          onChanged: (d) => setState(() => _start = d),
        ),
        _CheckRow(
          label: mTr(context, 'Currently working here', 'עובד/ת כאן כעת'),
          value: _current,
          onChanged: (v) => setState(() => _current = v),
        ),
        if (!_current)
          _MonthField(
            label: mTr(context, 'End Date', 'תאריך סיום'),
            value: _end,
            lastDate: now,
            onChanged: (d) => setState(() => _end = d),
          ),
        _LongTextField(
          label: mTr(context, 'Job Description', 'תיאור התפקיד'),
          placeholder: mTr(context, 'What you did there', 'מה עשית בתפקיד'),
          controller: _description,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════
// Education
// ═══════════════════════════════════════════════════

/// A qualification, new or [existing].
class EducationEditor extends ConsumerStatefulWidget {
  final Education? existing;
  const EducationEditor({super.key, this.existing});

  @override
  ConsumerState<EducationEditor> createState() => _EducationEditorState();
}

class _EducationEditorState extends ConsumerState<EducationEditor> {
  late final _qualification = TextEditingController(text: widget.existing?.qualification ?? '');
  late final _institution = TextEditingController(text: widget.existing?.institution ?? '');
  late final _location = TextEditingController(text: widget.existing?.location ?? '');
  late DateTime? _start = widget.existing?.startDate;
  late DateTime? _end = widget.existing?.endDate;
  late bool _current = widget.existing?.isCurrent ?? false;
  bool _saving = false;

  @override
  void dispose() {
    _qualification.dispose();
    _institution.dispose();
    _location.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_qualification.text.trim().isEmpty || _institution.text.trim().isEmpty) {
      mToast(
        context,
        mTr(context, 'Add the qualification and the school.', 'יש להזין השכלה ומוסד לימודים.'),
        error: true,
      );
      return;
    }
    if (!_current && _start != null && _end != null && _end!.isBefore(_start!)) {
      mToast(context, mTr(context, 'The end date is before the start date.', 'תאריך הסיום מוקדם מתאריך ההתחלה.'), error: true);
      return;
    }
    final e = Education(
      id: widget.existing?.id,
      qualification: _qualification.text.trim(),
      institution: _institution.text.trim(),
      location: _orNull(_location.text),
      startDate: _start,
      endDate: _current ? null : _end,
      isCurrent: _current,
    );
    _save(context, ref, (v) => setState(() => _saving = v), () => ref.read(jobRepositoryProvider).saveEducation(e));
  }

  Future<void> _onDelete() async {
    final id = widget.existing?.id;
    if (id == null) return;
    final ok = await confirmJobProfileRemoval(
      context,
      title: mTr(context, 'Delete this education?', 'למחוק את ההשכלה הזו?'),
      message: mTr(context, 'It will be removed from your profile.', 'היא תוסר מהפרופיל שלך.'),
    );
    if (!ok || !mounted) return;
    _save(context, ref, (v) => setState(() => _saving = v), () => ref.read(jobRepositoryProvider).deleteEducation(id));
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return _EditorPage(
      title: mTr(context, 'Education', 'השכלה'),
      saving: _saving,
      onSave: _onSave,
      action: widget.existing?.id == null ? null : _DeleteAction(onTap: _saving ? null : _onDelete),
      children: [
        _TextField(
          label: mTr(context, 'Education / Qualification', 'השכלה / תעודה'),
          placeholder: mTr(context, 'e.g. High School Diploma', 'לדוגמה: תעודת בגרות'),
          controller: _qualification,
        ),
        _TextField(
          label: mTr(context, 'School / Institution', 'בית ספר / מוסד'),
          placeholder: mTr(context, 'e.g. Modiin High School', 'לדוגמה: תיכון מודיעין'),
          controller: _institution,
        ),
        _TextField(
          label: mTr(context, 'Location', 'מיקום'),
          placeholder: mTr(context, 'e.g. Modiin', 'לדוגמה: מודיעין'),
          controller: _location,
        ),
        _MonthField(
          label: mTr(context, 'Start Date', 'תאריך התחלה'),
          value: _start,
          lastDate: now,
          onChanged: (d) => setState(() => _start = d),
        ),
        _CheckRow(
          label: mTr(context, 'Currently Studying Here', 'לומד/ת כאן כעת'),
          value: _current,
          onChanged: (v) => setState(() => _current = v),
        ),
        if (!_current)
          _MonthField(
            label: mTr(context, 'End Date', 'תאריך סיום'),
            value: _end,
            // Someone still studying may give the year they expect to finish.
            lastDate: DateTime(now.year + 10, 12, 31),
            onChanged: (d) => setState(() => _end = d),
          ),
      ],
    );
  }
}
