import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/widgets/m_kit.dart';
import '../../../shared/widgets/m_step_form.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/widgets/m_account_widgets.dart';
import '../models/job.dart';
import '../providers/job_providers.dart';
import 'job_profile_editors.dart';

/// The job seeker's CV profile (`user_side/My Profile`, 7 Oct): who they
/// are, how complete the profile is, and a card for each part a business
/// sees with an application — basic details, about, skills, work, study,
/// CV files and anything else.
class MyProfileScreen extends ConsumerStatefulWidget {
  const MyProfileScreen({super.key});

  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

const _ink = Color(0xFF3D3D3D);
const _maxResumeBytes = 5 * 1024 * 1024;

class _MyProfileScreenState extends ConsumerState<MyProfileScreen> {
  bool _uploading = false;

  /// Skills being taken off, hidden at once while the save goes through.
  final Set<String> _removing = {};

  Future<void> _removeSkill(List<String> skills, String skill) async {
    setState(() => _removing.add(skill));
    try {
      await ref.read(jobRepositoryProvider).saveProfile({
        'skills': [for (final s in skills) if (s != skill) s],
      });
      refreshJobSeeker(ref);
      // Kept hidden until the reloaded profile no longer has it, so the chip
      // does not flash back in between.
      await ref.read(myJobSeekerProvider.future);
    } catch (_) {
      if (mounted) {
        mToast(context, mTr(context, 'Could not remove the skill.', 'לא ניתן להסיר את הכישור.'), error: true);
      }
    } finally {
      if (mounted) setState(() => _removing.remove(skill));
    }
  }

  Future<void> _uploadResume() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx'],
      withData: true,
    );
    final file = result?.files.firstOrNull;
    if (file == null || !mounted) return;
    final bytes = file.bytes;
    if (bytes == null) {
      mToast(context, mTr(context, 'The file could not be read.', 'לא ניתן לקרוא את הקובץ.'), error: true);
      return;
    }
    if (bytes.lengthInBytes > _maxResumeBytes) {
      mToast(context, mTr(context, 'The file is over 5 MB.', 'הקובץ גדול מ־5MB.'), error: true);
      return;
    }
    setState(() => _uploading = true);
    try {
      await ref.read(jobRepositoryProvider).uploadResume(fileName: file.name, bytes: bytes);
      refreshJobSeeker(ref);
    } catch (_) {
      if (mounted) {
        mToast(context, mTr(context, 'Could not upload the file.', 'העלאת הקובץ נכשלה.'), error: true);
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _openResume(Resume r) async {
    try {
      final url = await ref.read(jobRepositoryProvider).cvUrl(r.filePath);
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        mToast(context, mTr(context, 'Could not open the file.', 'לא ניתן לפתוח את הקובץ.'), error: true);
      }
    }
  }

  Future<void> _deleteResume(Resume r) async {
    final ok = await confirmJobProfileRemoval(
      context,
      title: mTr(context, 'Delete this file?', 'למחוק את הקובץ?'),
      message: mTr(
        context,
        '${r.fileName} will be removed from your profile.',
        '${r.fileName} יוסר מהפרופיל שלך.',
      ),
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(jobRepositoryProvider).deleteResume(r);
      refreshJobSeeker(ref);
    } catch (_) {
      if (mounted) {
        mToast(context, mTr(context, 'Could not delete the file.', 'מחיקת הקובץ נכשלה.'), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final async = ref.watch(myJobSeekerProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(15, 10, 15, 0),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: const MBackArrow(color: Color(0xFF3D3D3D)),
                  ),
                ),
                Expanded(
                  child: user == null
                      ? MEmpty(
                          icon: IconsaxPlusLinear.user,
                          title: mTr(context, 'Sign in to see your profile', 'יש להתחבר כדי לראות את הפרופיל'),
                        )
                      : RefreshIndicator(
                          color: mStepMid,
                          onRefresh: () async {
                            refreshJobSeeker(ref);
                            await ref.read(myJobSeekerProvider.future);
                          },
                          child: ListView(
                            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 24),
                            children: [
                              _Header(user: user),
                              const SizedBox(height: 28),
                              ...async.when(
                                data: (d) => _body(context, user, d),
                                loading: () => const [
                                  Padding(
                                    padding: EdgeInsets.only(top: 60),
                                    child: Center(child: CircularProgressIndicator(color: mStepMid)),
                                  ),
                                ],
                                error: (_, _) => [_LoadError(onRetry: () => refreshJobSeeker(ref))],
                              ),
                            ],
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

  List<Widget> _body(BuildContext context, UserModel user, JobSeekerData d) {
    final p = d.profile;
    final location = (p?.location ?? '').trim().isNotEmpty ? p!.location!.trim() : user.neighborhood;
    final hasBasics = user.phone.trim().isNotEmpty && (location ?? '').isNotEmpty;
    final about = (p?.about ?? '').trim();
    final skills = [for (final s in p?.skills ?? const <String>[]) if (!_removing.contains(s)) s];
    final additional = (p?.additionalInfo ?? '').trim();
    const gap = SizedBox(height: 16);

    return [
      _Progress(completion: d.completion(hasBasics: hasBasics), updatedAt: p?.updatedAt),
      const SizedBox(height: 20),

      // ── Basic details ──
      MSectionCard(
        title: mTr(context, 'Basic details', 'פרטים בסיסיים'),
        actionIcon: IconsaxPlusLinear.edit_2,
        onAction: () => context.push('/my-profile/basic'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            if (user.email.isNotEmpty) MMeta(IconsaxPlusLinear.sms, user.email, color: _ink),
            if (user.phone.trim().isNotEmpty) MMeta(IconsaxPlusLinear.call, user.phone.trim(), color: _ink),
            if ((location ?? '').isNotEmpty) MMeta(IconsaxPlusLinear.location, location!, color: _ink),
            if (p?.experienceYears != null)
              MMeta(IconsaxPlusLinear.briefcase, _yearsExp(context, p!.experienceYears!), color: _ink),
          ],
        ),
      ),
      gap,

      // ── About me ──
      MSectionCard(
        title: mTr(context, 'About Me', 'קצת עליי'),
        hint: about.isEmpty
            ? mTr(
                context,
                'Tell employers what you do best and what you’re looking for.',
                'ספרו למעסיקים במה אתם הכי טובים ומה אתם מחפשים.',
              )
            : null,
        actionIcon: about.isEmpty ? IconsaxPlusLinear.add : IconsaxPlusLinear.edit_2,
        onAction: () => context.push('/my-profile/about'),
        child: about.isEmpty ? null : Text(about, style: mText(14, color: mStepInk, height: 1.5)),
      ),
      gap,

      // ── Skills ──
      MSectionCard(
        title: mTr(context, 'Skills', 'כישורים'),
        hint: skills.isEmpty
            ? mTr(context, 'Add skills that match your experience.', 'הוסיפו כישורים שמתאימים לניסיון שלכם.')
            : null,
        actionIcon: skills.isEmpty ? IconsaxPlusLinear.add : IconsaxPlusLinear.edit_2,
        onAction: () => context.push('/my-profile/skills'),
        child: skills.isEmpty
            ? null
            : Wrap(
                spacing: 8,
                runSpacing: 10,
                children: [
                  for (final s in skills)
                    MChip(s, background: mKitBlueBg, onRemove: () => _removeSkill(skills, s)),
                ],
              ),
      ),
      gap,

      // ── Work experience ──
      MSectionCard(
        title: mTr(context, 'Work Experience', 'ניסיון תעסוקתי'),
        hint: d.experiences.isEmpty
            ? mTr(
                context,
                'Add your work experience to highlight your background.',
                'הוסיפו את הניסיון התעסוקתי שלכם כדי להציג את הרקע שלכם.',
              )
            : null,
        actionIcon: IconsaxPlusLinear.add,
        onAction: () => context.push('/my-profile/experience'),
        child: d.experiences.isEmpty
            ? null
            : Column(children: [for (final e in d.experiences) _ExperienceItem(e)]),
      ),
      gap,

      // ── Education ──
      MSectionCard(
        title: mTr(context, 'Education', 'השכלה'),
        hint: d.educations.isEmpty
            ? mTr(
                context,
                'Add your education details to showcase your qualifications.',
                'הוסיפו את פרטי ההשכלה שלכם כדי להציג את הכישורים שלכם.',
              )
            : null,
        actionIcon: IconsaxPlusLinear.add,
        onAction: () => context.push('/my-profile/education'),
        child: d.educations.isEmpty
            ? null
            : Column(
                children: [
                  for (var i = 0; i < d.educations.length; i++)
                    _EducationItem(d.educations[i], last: i == d.educations.length - 1),
                ],
              ),
      ),
      gap,

      // ── Resume / CV ──
      MSectionCard(
        title: mTr(context, 'Resume / CV', 'קורות חיים'),
        hint: d.resumes.isEmpty && !_uploading
            ? mTr(context, 'Upload your resume to make applying easier.', 'העלו קורות חיים כדי להגיש מועמדות בקלות.')
            : null,
        actionIcon: IconsaxPlusLinear.add,
        onAction: _uploading ? null : _uploadResume,
        child: d.resumes.isEmpty && !_uploading
            ? null
            : Column(
                children: [
                  for (final r in d.resumes)
                    _ResumeItem(r, onOpen: () => _openResume(r), onDelete: () => _deleteResume(r)),
                  if (_uploading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(color: mStepMid, backgroundColor: mStepHairline),
                    ),
                ],
              ),
      ),
      gap,

      // ── Additional information ──
      MSectionCard(
        title: mTr(context, 'Additional Information', 'מידע נוסף'),
        hint: additional.isEmpty
            ? mTr(
                context,
                'Share any other information you’d like employers to know.',
                'שתפו כל מידע נוסף שתרצו שמעסיקים ידעו.',
              )
            : null,
        actionIcon: additional.isEmpty ? IconsaxPlusLinear.add : IconsaxPlusLinear.edit_2,
        onAction: () => context.push('/my-profile/additional'),
        child: additional.isEmpty ? null : Text(additional, style: mText(14, color: mStepInk, height: 1.5)),
      ),
    ];
  }
}

String _yearsExp(BuildContext context, int n) => switch (n) {
  0 => mTr(context, 'No experience', 'ללא ניסיון'),
  1 => mTr(context, '1 Year exp.', 'שנת ניסיון אחת'),
  _ => mTr(context, '$n Years exp.', '$n שנות ניסיון'),
};

/// "Jan 2024" / "ינו׳ 2024".
String _shortMonth(BuildContext context, DateTime d) {
  const en = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  const he = ['ינו׳', 'פבר׳', 'מרץ', 'אפר׳', 'מאי', 'יוני', 'יולי', 'אוג׳', 'ספט׳', 'אוק׳', 'נוב׳', 'דצמ׳'];
  return mTr(context, '${en[d.month - 1]} ${d.year}', '${he[d.month - 1]} ${d.year}');
}

/// "start – end", "start – Present", or what there is of it.
String? _span(BuildContext context, String? start, String? end, bool current) {
  final finish = current ? mTr(context, 'Present', 'היום') : end;
  if (start == null) return finish == null || current ? null : finish;
  return finish == null ? start : '$start – $finish';
}

class _Header extends StatelessWidget {
  final UserModel user;
  const _Header({required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 88,
          child: Stack(
            children: [
              Center(child: MAvatar(url: user.avatarUrl, name: user.name, size: 88)),
              // The name and photo are the account's, changed on Edit Profile.
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.push('/edit-profile'),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(IconsaxPlusLinear.edit_2, size: 22, color: mStepMid),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(user.name, textAlign: TextAlign.center, style: mHeading(20)),
        if (user.email.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(user.email, textAlign: TextAlign.center, style: mText(14, color: _ink)),
        ],
      ],
    );
  }
}

/// "n% Profile Completed", when it was last changed, and the bar — red
/// while under half, green from half on.
class _Progress extends StatelessWidget {
  final double completion;
  final DateTime? updatedAt;
  const _Progress({required this.completion, required this.updatedAt});

  @override
  Widget build(BuildContext context) {
    final pct = (completion * 100).round();
    final at = updatedAt?.toLocal();
    final now = DateTime.now();
    final today = at != null && at.year == now.year && at.month == now.month && at.day == now.day;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                mTr(context, '$pct% Profile Completed', 'הפרופיל הושלם ב־$pct%'),
                style: mText(12.5, weight: FontWeight.w500, color: mStepInk),
              ),
            ),
            if (at != null)
              Text(
                today
                    ? mTr(context, 'Last updated Today', 'עודכן היום')
                    : mTr(context, 'Last updated ${mDate(context, at)}', 'עודכן ${mDate(context, at)}'),
                style: mText(12.5, color: mStepGrey),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: completion,
            minHeight: 6,
            backgroundColor: mStepHairline,
            color: completion < 0.5 ? mKitRed : mKitGreen,
          ),
        ),
      ],
    );
  }
}

class _ExperienceItem extends StatelessWidget {
  final WorkExperience e;
  const _ExperienceItem(this.e);

  @override
  Widget build(BuildContext context) {
    final where = [e.company, ?e.location].where((s) => s.trim().isNotEmpty).join(' • ');
    final span = _span(
      context,
      e.startDate == null ? null : _shortMonth(context, e.startDate!),
      e.endDate == null ? null : _shortMonth(context, e.endDate!),
      e.isCurrent,
    );
    final when = [?e.employmentType?.label, ?span].join(' • ');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: mStepHairline))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MAvatar(name: e.company, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.title, style: mText(14, weight: FontWeight.w500, color: mStepInk)),
                if (where.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(where, style: mText(12, color: _ink)),
                ],
                if (when.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(when, style: mText(12, color: mStepGrey)),
                ],
              ],
            ),
          ),
          _EditIcon(onTap: () => context.push('/my-profile/experience', extra: e)),
        ],
      ),
    );
  }
}

class _EducationItem extends StatelessWidget {
  final Education e;
  final bool last;
  const _EducationItem(this.e, {required this.last});

  @override
  Widget build(BuildContext context) {
    final where = [e.institution, ?e.location].where((s) => s.trim().isNotEmpty).join(' · ');
    final span = _span(context, e.startDate?.year.toString(), e.endDate?.year.toString(), e.isCurrent);
    return Container(
      padding: EdgeInsets.only(top: 4, bottom: last ? 0 : 12),
      margin: EdgeInsets.only(bottom: last ? 0 : 12),
      decoration: last
          ? null
          : const BoxDecoration(border: Border(bottom: BorderSide(color: mStepHairline))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.qualification, style: mText(14, weight: FontWeight.w600, color: mStepInk)),
                if (where.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(where, style: mText(12, color: _ink)),
                ],
                if (span != null) ...[
                  const SizedBox(height: 3),
                  Text(span, style: mText(12, color: mStepGrey)),
                ],
              ],
            ),
          ),
          _EditIcon(onTap: () => context.push('/my-profile/education', extra: e)),
        ],
      ),
    );
  }
}

class _ResumeItem extends StatelessWidget {
  final Resume r;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  const _ResumeItem(this.r, {required this.onOpen, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final dot = r.fileName.lastIndexOf('.');
    final ext = dot == -1 ? 'PDF' : r.fileName.substring(dot + 1).toUpperCase();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: const Color(0xFFE5252A), borderRadius: BorderRadius.circular(5)),
              child: Text(ext, style: mText(8.5, weight: FontWeight.w700, color: Colors.white)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: mText(14, weight: FontWeight.w500, color: mStepInk),
                  ),
                  if (r.sizeLabel.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(r.sizeLabel, style: mText(12, color: mStepGrey)),
                  ],
                ],
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onDelete,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(IconsaxPlusLinear.trash, size: 20, color: mKitRed),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditIcon extends StatelessWidget {
  final VoidCallback onTap;
  const _EditIcon({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: const Padding(
        padding: EdgeInsets.all(4),
        child: Icon(IconsaxPlusLinear.edit_2, size: 20, color: mStepMid),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  final VoidCallback onRetry;
  const _LoadError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          Text(
            mTr(context, 'Your profile could not be loaded.', 'לא ניתן לטעון את הפרופיל.'),
            textAlign: TextAlign.center,
            style: mText(14, color: mStepGrey),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: Text(mTr(context, 'Try again', 'נסו שוב'), style: mText(14, weight: FontWeight.w600, color: mStepMid)),
          ),
        ],
      ),
    );
  }
}
