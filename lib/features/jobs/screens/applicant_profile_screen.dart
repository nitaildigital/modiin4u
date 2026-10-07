import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/widgets/error_retry.dart';
import '../../../shared/widgets/m_kit.dart';
import '../../../shared/widgets/m_step_form.dart';
import '../../auth/widgets/m_account_widgets.dart';
import '../../messages/data/messages.dart';
import '../models/job.dart';
import '../providers/job_providers.dart';

/// "5 years experience" / "5 שנות ניסיון".
String experienceYearsLabel(BuildContext context, int years) => years == 1
    ? mTr(context, '1 year experience', 'שנת ניסיון אחת')
    : mTr(context, '$years years experience', '$years שנות ניסיון');

/// Reaches an applicant: a conversation in the app when they applied with an
/// account, otherwise their phone or e-mail — a person without an account
/// has no inbox to write to.
Future<void> contactApplicant(BuildContext context, WidgetRef ref, Job job, JobApplication a) async {
  if (a.profileId != null) {
    try {
      final id = await ref
          .read(messageRepositoryProvider)
          .start(businessId: job.businessId, profileId: a.profileId, jobId: job.id);
      if (context.mounted) context.push('/messages/$id');
    } catch (_) {
      if (context.mounted) {
        mToast(context, mTr(context, 'The conversation could not be opened.', 'לא ניתן היה לפתוח את השיחה.'), error: true);
      }
    }
    return;
  }
  final phone = (a.phone ?? '').trim();
  final email = (a.email ?? '').trim();
  final uri = phone.isNotEmpty
      ? Uri(scheme: 'tel', path: phone)
      : email.isNotEmpty
      ? Uri(scheme: 'mailto', path: email)
      : null;
  if (uri == null) {
    mToast(context, mTr(context, 'This applicant left no contact details.', 'המועמד/ת לא השאיר/ה פרטי קשר.'));
    return;
  }
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// A yes-or-no before something the other side will notice.
Future<bool> confirmJobAction(
  BuildContext context, {
  required String title,
  required String text,
  required String confirm,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: mText(17, weight: FontWeight.w600)),
      content: Text(text, style: mText(14, color: const Color(0xFF3D3D3D), height: 1.45)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(mTr(context, 'Cancel', 'ביטול'), style: mText(14, color: mStepGrey)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirm, style: mText(14, weight: FontWeight.w600, color: mStepMid)),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Applicant Profile (`business_side/Applicant Profile.png`): the person
/// behind an application, from their job profile, with their CV as they sent
/// it, and the business's moves on the application in the ⋯ menu.
class ApplicantProfileScreen extends ConsumerStatefulWidget {
  final Job job;
  final JobApplication application;
  const ApplicantProfileScreen({super.key, required this.job, required this.application});

  @override
  ConsumerState<ApplicantProfileScreen> createState() => _ApplicantProfileScreenState();
}

class _ApplicantProfileScreenState extends ConsumerState<ApplicantProfileScreen> {
  // Kept here as well, since the application came in with the route and is
  // not watched.
  late String _status = widget.application.status;
  late bool _shortlisted = widget.application.shortlisted;
  bool _contacting = false;

  JobApplication get _a => widget.application;

  @override
  void initState() {
    super.initState();
    // Opening it is what "Viewed" means to the applicant.
    if (_a.status == 'new') _markViewed();
  }

  Future<void> _markViewed() async {
    try {
      await ref.read(jobRepositoryProvider).setApplicationStatus(_a.id, 'viewed');
      if (!mounted) return;
      setState(() => _status = 'viewed');
      ref.invalidate(applicantsProvider(widget.job.id));
    } catch (_) {
      // Not worth an error: it only changes the label the applicant sees.
    }
  }

  Future<void> _toggleShortlist() async {
    final to = !_shortlisted;
    setState(() => _shortlisted = to);
    try {
      await ref.read(jobRepositoryProvider).setShortlisted(_a.id, to);
      ref.invalidate(applicantsProvider(widget.job.id));
    } catch (_) {
      if (!mounted) return;
      setState(() => _shortlisted = !to);
      _failed();
    }
  }

  Future<void> _move(String status) async {
    if (status == 'unsuitable') {
      final ok = await confirmJobAction(
        context,
        title: mTr(context, 'Mark as not selected?', 'לסמן כלא נבחר/ה?'),
        text: mTr(
          context,
          '${_a.fullName} will be told the application was not selected.',
          '${_a.fullName} יקבל/תקבל הודעה שהמועמדות לא נבחרה.',
        ),
        confirm: mTr(context, 'Not selected', 'לא נבחר/ה'),
      );
      if (!ok || !mounted) return;
    }
    try {
      await ref.read(jobRepositoryProvider).setApplicationStatus(_a.id, status);
      ref.invalidate(applicantsProvider(widget.job.id));
      if (!mounted) return;
      setState(() => _status = status);
      mToast(context, mTr(context, 'Updated.', 'עודכן.'));
    } catch (_) {
      if (mounted) _failed();
    }
  }

  void _failed() => mToast(context, mTr(context, 'That did not work. Try again.', 'הפעולה לא הצליחה. נסו שוב.'), error: true);

  Future<void> _contact() async {
    if (_contacting) return;
    setState(() => _contacting = true);
    await contactApplicant(context, ref, widget.job, _a);
    if (mounted) setState(() => _contacting = false);
  }

  Future<void> _openCv(String path) async {
    try {
      final url = await ref.read(jobRepositoryProvider).cvUrl(path);
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        mToast(context, mTr(context, 'The CV could not be opened.', 'לא ניתן היה לפתוח את קורות החיים.'), error: true);
      }
    }
  }

  Widget _actions() {
    final moves = [
      ('interview', mTr(context, 'Invite to interview', 'הזמנה לראיון')),
      ('accepted', mTr(context, 'Mark as accepted', 'סימון כהתקבל/ה')),
      ('unsuitable', mTr(context, 'Not selected', 'לא נבחר/ה')),
      ('archived', mTr(context, 'Archive', 'העברה לארכיון')),
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleShortlist,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Icon(
              _shortlisted ? IconsaxPlusBold.heart : IconsaxPlusLinear.heart,
              size: 24,
              color: _shortlisted ? mKitRed : const Color(0xFF3D3D3D),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 28,
          height: 28,
          child: PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.more_horiz, color: Color(0xFF3D3D3D)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: Colors.white,
            onSelected: _move,
            itemBuilder: (context) => [
              for (final m in moves)
                if (m.$1 != _status) PopupMenuItem(value: m.$1, child: Text(m.$2, style: mText(14))),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = _a;
    final hasAccount = a.profileId != null;
    final seeker = hasAccount ? ref.watch(jobSeekerProvider(a.profileId!)) : null;
    final profile = seeker?.valueOrNull?.profile;
    final headline = (a.headline ?? '').trim();
    final years = a.experienceYears ?? profile?.experienceYears;
    final location = (a.location ?? profile?.location ?? '').trim();
    final email = (a.email ?? '').trim();
    final phone = (a.phone ?? '').trim();

    return MPage(
      action: _actions(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MAvatar(url: a.avatarUrl, name: a.fullName, size: 72),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.fullName, style: mHeading(22)),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(email, textDirection: TextDirection.ltr, style: mText(13, color: mStepGrey)),
                    ],
                    if (!hasAccount && phone.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(phone, textDirection: TextDirection.ltr, style: mText(13, color: mStepGrey)),
                    ],
                    if (headline.isNotEmpty || years != null) ...[
                      const SizedBox(height: 6),
                      Text.rich(
                        TextSpan(
                          children: [
                            if (headline.isNotEmpty)
                              TextSpan(text: headline, style: mText(14, color: const Color(0xFF3D3D3D))),
                            if (headline.isNotEmpty && years != null) const TextSpan(text: '  '),
                            if (years != null)
                              TextSpan(text: experienceYearsLabel(context, years), style: mText(12.5, color: mStepGrey)),
                          ],
                        ),
                      ),
                    ],
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      MMeta(IconsaxPlusLinear.location, location),
                    ],
                    if (_status != 'new' && _status != 'viewed') ...[
                      const SizedBox(height: 8),
                      // The model holds the labels; this is the status as it
                      // stands after a move made on this page.
                      MStatusPill.forStatus(
                        _status,
                        JobApplication(id: a.id, jobId: a.jobId, fullName: a.fullName, status: _status, createdAt: a.createdAt)
                            .statusLabel,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (hasAccount)
            MButton(
              label: mTr(context, 'Contact', 'יצירת קשר'),
              icon: IconsaxPlusLinear.message_text,
              height: 44,
              loading: _contacting,
              onTap: _contact,
            )
          else if (phone.isNotEmpty || email.isNotEmpty)
            Row(
              children: [
                if (phone.isNotEmpty)
                  Expanded(
                    child: MButton(
                      label: mTr(context, 'Call', 'התקשרות'),
                      icon: IconsaxPlusLinear.call,
                      height: 44,
                      onTap: () => launchUrl(Uri(scheme: 'tel', path: phone)),
                    ),
                  ),
                if (phone.isNotEmpty && email.isNotEmpty) const SizedBox(width: 12),
                if (email.isNotEmpty)
                  Expanded(
                    child: MButton(
                      label: mTr(context, 'Email', 'אימייל'),
                      icon: IconsaxPlusLinear.sms,
                      height: 44,
                      outlined: phone.isNotEmpty,
                      onTap: () => launchUrl(Uri(scheme: 'mailto', path: email)),
                    ),
                  ),
              ],
            ),
          if (seeker != null && !seeker.hasValue)
            seeker.hasError
                ? ErrorRetry(onRetry: () => ref.invalidate(jobSeekerProvider(a.profileId!)))
                : const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator(color: mStepMid)),
                  ),
          ..._profileCards(seeker?.valueOrNull),
          if ((a.cvPath ?? '').isNotEmpty) _gap(_cvCard(a.cvPath!)),
          if ((profile?.additionalInfo ?? '').trim().isNotEmpty)
            _gap(
              MSectionCard(
                title: mTr(context, 'Additional Information', 'מידע נוסף'),
                child: Text(profile!.additionalInfo!.trim(), style: _body),
              ),
            ),
          if ((a.message ?? '').trim().isNotEmpty)
            _gap(
              MSectionCard(
                title: mTr(context, 'Message', 'הודעה'),
                child: Text(a.message!.trim(), style: _body),
              ),
            ),
        ],
      ),
    );
  }

  Widget _gap(Widget card) => Padding(padding: const EdgeInsets.only(top: 14), child: card);

  /// The job profile's cards, in the design's order; a part the person left
  /// empty is not drawn.
  List<Widget> _profileCards(JobSeekerData? data) {
    if (data == null) return const [];
    final p = data.profile;
    final about = (p?.about ?? '').trim();
    final skills = p?.skills ?? const <String>[];
    return [
      if (about.isNotEmpty)
        _gap(MSectionCard(title: mTr(context, 'About Me', 'קצת עליי'), child: Text(about, style: _body))),
      if (skills.isNotEmpty)
        _gap(
          MSectionCard(
            title: mTr(context, 'Skills', 'כישורים'),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final s in skills) MChip(s, background: mKitBlueBg)],
            ),
          ),
        ),
      if (data.experiences.isNotEmpty)
        _gap(
          MSectionCard(
            title: mTr(context, 'Work Experience', 'ניסיון תעסוקתי'),
            child: Column(
              children: [
                for (var i = 0; i < data.experiences.length; i++) ...[
                  if (i > 0) const Divider(height: 24, thickness: 1, color: mStepHairline),
                  _experience(data.experiences[i]),
                ],
              ],
            ),
          ),
        ),
      if (data.educations.isNotEmpty)
        _gap(
          MSectionCard(
            title: mTr(context, 'Education', 'השכלה'),
            child: Column(
              children: [
                for (var i = 0; i < data.educations.length; i++) ...[
                  if (i > 0) const Divider(height: 24, thickness: 1, color: mStepHairline),
                  _education(data.educations[i]),
                ],
              ],
            ),
          ),
        ),
    ];
  }

  String _month(DateTime d) {
    const en = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const he = ['ינו׳', 'פבר׳', 'מרץ', 'אפר׳', 'מאי', 'יוני', 'יולי', 'אוג׳', 'ספט׳', 'אוק׳', 'נוב׳', 'דצמ׳'];
    return mTr(context, '${en[d.month - 1]} ${d.year}', '${he[d.month - 1]} ${d.year}');
  }

  /// "Jan 2024 – Present", or as much of it as was given.
  String? _span(DateTime? start, DateTime? end, bool current, String Function(DateTime) f) {
    final to = current ? mTr(context, 'Present', 'היום') : (end == null ? null : f(end));
    if (start == null) return to;
    return to == null ? f(start) : '${f(start)} – $to';
  }

  Widget _experience(WorkExperience e) {
    final where = [e.company, e.location].whereType<String>().where((s) => s.trim().isNotEmpty).join(' • ');
    final when = [e.employmentType?.label, _span(e.startDate, e.endDate, e.isCurrent, _month)]
        .whereType<String>()
        .join(' • ');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MAvatar(name: e.company, size: 40),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(e.title, style: mText(14.5, weight: FontWeight.w500)),
              if (where.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(where, style: mText(12.5, color: mStepGrey)),
              ],
              if (when.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(when, style: mText(12.5, color: mStepGrey)),
              ],
              if ((e.description ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(e.description!.trim(), style: mText(13, color: const Color(0xFF3D3D3D), height: 1.45)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _education(Education e) {
    final where = [e.institution, e.location].whereType<String>().where((s) => s.trim().isNotEmpty).join(' · ');
    final when = _span(e.startDate, e.endDate, e.isCurrent, (d) => '${d.year}');
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(e.qualification, style: mText(14.5, weight: FontWeight.w500)),
          if (where.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(where, style: mText(12.5, color: mStepGrey)),
          ],
          if (when != null) ...[
            const SizedBox(height: 3),
            Text(when, style: mText(12.5, color: mStepGrey)),
          ],
        ],
      ),
    );
  }

  Widget _cvCard(String path) {
    final name = path.split('/').last;
    return MSectionCard(
      title: mTr(context, 'Resume / CV', 'קורות חיים'),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openCv(path),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: const Color(0xFFE53935), borderRadius: BorderRadius.circular(4)),
              child: Text(
                name.toLowerCase().endsWith('.pdf') ? 'PDF' : 'DOC',
                style: mText(9, weight: FontWeight.w700, color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: TextDirection.ltr,
                style: mText(14, weight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(IconsaxPlusLinear.import_1, size: 22, color: mStepMid),
          ],
        ),
      ),
    );
  }
}

final _body = mText(14, color: const Color(0xFF3D3D3D), height: 1.5);
