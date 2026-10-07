import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/supabase/account_blocked.dart';
import '../../../shared/widgets/error_retry.dart';
import '../../../shared/widgets/m_kit.dart';
import '../../../shared/widgets/m_step_form.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/widgets/m_account_widgets.dart';
import '../models/job.dart';
import '../providers/job_providers.dart';
import '../widgets/m_job_card.dart';

/// Apply Job (`user_side/Apply Job.png`, `Apply Job-1.png`): pick one of the
/// person's CVs, upload another, or apply without one. The name and contact
/// sent are the account's.
class ApplyJobScreen extends ConsumerStatefulWidget {
  final String jobId;
  const ApplyJobScreen({super.key, required this.jobId});

  @override
  ConsumerState<ApplyJobScreen> createState() => _ApplyJobScreenState();
}

class _ApplyJobScreenState extends ConsumerState<ApplyJobScreen> {
  static const _maxBytes = 5 * 1024 * 1024;

  String? _selectedId;
  bool _withoutCv = false;
  bool _uploading = false;
  bool _sending = false;

  // The newest is chosen until the person picks another.
  Resume? _chosen(List<Resume> resumes) =>
      resumes.where((r) => r.id == _selectedId).firstOrNull ?? resumes.firstOrNull;

  Future<void> _upload() async {
    final user = ref.read(authProvider);
    if (user == null) return;
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx'],
      withData: true,
    );
    final file = result?.files.firstOrNull;
    if (file == null || !mounted) return;
    final bytes = file.bytes;
    if (bytes == null) {
      mToast(context, mTr(context, 'Could not read the file.', 'לא ניתן לקרוא את הקובץ.'), error: true);
      return;
    }
    if (bytes.lengthInBytes > _maxBytes) {
      mToast(context, mTr(context, 'The file is larger than 5 MB.', 'הקובץ גדול מ־5MB.'), error: true);
      return;
    }
    setState(() => _uploading = true);
    try {
      final resume = await ref.read(jobRepositoryProvider).uploadResume(fileName: file.name, bytes: bytes);
      // My Profile and this list read the same rows.
      ref.invalidate(jobSeekerProvider(user.id));
      if (mounted) setState(() => _selectedId = resume.id);
    } catch (_) {
      if (mounted) mToast(context, mTr(context, 'Could not upload the file.', 'העלאת הקובץ נכשלה.'), error: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _submit(List<Resume> resumes) async {
    final user = ref.read(authProvider);
    if (user == null) return;
    final resume = _withoutCv ? null : _chosen(resumes);
    if (!_withoutCv && resume == null) {
      mToast(context, mTr(context, 'Choose a resume, or apply without a CV.', 'יש לבחור קורות חיים, או להגיש בלי.'));
      return;
    }
    setState(() => _sending = true);
    try {
      await ref
          .read(jobRepositoryProvider)
          .apply(
            jobId: widget.jobId,
            fullName: user.name,
            phone: user.phone.trim().isEmpty ? null : user.phone.trim(),
            email: user.email.trim().isEmpty ? null : user.email.trim(),
            cvPath: resume?.filePath,
          );
      ref.invalidate(myApplicationsProvider);
      if (!mounted) return;
      mToast(context, mTr(context, 'Your application was sent', 'המועמדות נשלחה'));
      context.pop();
    } catch (e) {
      final blocked = await refusedAsBlocked(e);
      if (!mounted) return;
      final m = e.toString();
      final String message;
      if (blocked) {
        message = accountBlockedMessage(context);
      } else if (m.contains('already-applied')) {
        // The page behind may not know yet; it will once it is back.
        ref.invalidate(myApplicationsProvider);
        message = mTr(context, 'You already applied for this job.', 'כבר הגשת מועמדות למשרה הזו.');
      } else if (m.contains('job-not-open')) {
        message = mTr(context, 'This job is no longer taking applications.', 'המשרה כבר לא מקבלת מועמדויות.');
      } else if (m.contains('contact-required')) {
        message = mTr(
          context,
          'Add a phone number to your profile to apply.',
          'יש להוסיף מספר טלפון בפרופיל כדי להגיש מועמדות.',
        );
      } else {
        message = mTr(context, 'Could not send your application.', 'שליחת המועמדות נכשלה.');
      }
      mToast(context, message, error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    if (user == null) {
      return MPage(
        body: MEmpty(
          icon: IconsaxPlusLinear.user,
          title: mTr(context, 'Sign in to apply for this job', 'יש להתחבר כדי להגיש מועמדות'),
        ),
      );
    }

    final seeker = ref.watch(myJobSeekerProvider);
    final resumes = seeker.valueOrNull?.resumes ?? const <Resume>[];
    final selected = _chosen(resumes)?.id;

    return MPage(
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              children: [
                Text(mTr(context, 'Choose a resume', 'בחירת קורות חיים'), style: mHeading(26)),
                const SizedBox(height: 6),
                Text(
                  mTr(
                    context,
                    'Select an existing resume or upload a new one.',
                    'אפשר לבחור קורות חיים קיימים או להעלות חדשים.',
                  ),
                  style: mText(14, color: mStepGrey),
                ),
                const SizedBox(height: 24),
                _dimmed(_UploadBox(uploading: _uploading, onUpload: _upload)),
                if (seeker.isLoading && resumes.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator(color: mStepMid)),
                  )
                else if (seeker.hasError && resumes.isEmpty)
                  ErrorRetry(compact: true, onRetry: () => ref.invalidate(jobSeekerProvider(user.id)))
                else if (resumes.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  _dimmed(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                mTr(context, 'Your Resumes', 'קורות החיים שלך'),
                                style: mText(16, weight: FontWeight.w600),
                              ),
                            ),
                            Text(
                              resumes.length == 1
                                  ? mTr(context, '1 resume', 'קובץ אחד')
                                  : mTr(context, '${resumes.length} resumes', '${resumes.length} קבצים'),
                              style: mText(12, color: mStepGrey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: mStepHairline),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              for (var i = 0; i < resumes.length; i++) ...[
                                if (i > 0)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16),
                                    child: Divider(height: 1, thickness: 1, color: mStepHairline),
                                  ),
                                _ResumeRow(
                                  resume: resumes[i],
                                  selected: !_withoutCv && resumes[i].id == selected,
                                  onTap: () => setState(() => _selectedId = resumes[i].id),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _withoutCv = !_withoutCv),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        MJobTickBox(checked: _withoutCv, size: 18),
                        const SizedBox(width: 9),
                        Text(
                          mTr(context, 'Apply without a CV', 'הגשה ללא קורות חיים'),
                          style: mText(14, color: const Color(0xFF3D3D3D)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Submit sits on the page without the bar's hairline, as drawn.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: MButton(
              label: mTr(context, 'Submit', 'שליחה'),
              loading: _sending,
              onTap: seeker.isLoading || _uploading ? null : () => _submit(resumes),
            ),
          ),
        ],
      ),
    );
  }

  /// With "Apply without a CV" ticked, the CV choices fade and stop
  /// answering, as `Apply Job-1.png` draws them.
  Widget _dimmed(Widget child) => IgnorePointer(
    ignoring: _withoutCv,
    child: AnimatedOpacity(duration: const Duration(milliseconds: 150), opacity: _withoutCv ? 0.45 : 1, child: child),
  );
}

class _UploadBox extends StatelessWidget {
  final bool uploading;
  final VoidCallback onUpload;
  const _UploadBox({required this.uploading, required this.onUpload});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      decoration: BoxDecoration(color: const Color(0xFFF8FAFE), borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(mTr(context, 'Upload Resume', 'העלאת קורות חיים'), style: mText(16, weight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(mTr(context, 'PDF, DOC or DOCX', 'PDF, DOC או DOCX'), style: mText(12, color: mStepGrey)),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: uploading ? null : onUpload,
            child: Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: mStepMid, borderRadius: BorderRadius.circular(60)),
              child: uploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      mTr(context, 'Upload File', 'העלאת קובץ'),
                      style: mText(12.5, weight: FontWeight.w500, color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumeRow extends StatelessWidget {
  final Resume resume;
  final bool selected;
  final VoidCallback onTap;
  const _ResumeRow({required this.resume, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final size = resume.sizeLabel;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 14, 16, 14),
        child: Row(
          children: [
            _FileTile(fileName: resume.fileName),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resume.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.ltr,
                    style: mText(14.5, weight: FontWeight.w500),
                  ),
                  if (size.isNotEmpty) ...[const SizedBox(height: 2), Text(size, style: mText(12, color: mStepGrey))],
                ],
              ),
            ),
            const SizedBox(width: 12),
            _Radio(selected: selected),
          ],
        ),
      ),
    );
  }
}

/// The file icon: a page with a folded corner, red for a PDF, Word's blue for
/// a .doc, labelled with its kind.
class _FileTile extends StatelessWidget {
  final String fileName;
  const _FileTile({required this.fileName});

  @override
  Widget build(BuildContext context) {
    final dot = fileName.lastIndexOf('.');
    final ext = dot == -1 ? 'pdf' : fileName.substring(dot + 1).toLowerCase();
    final word = ext == 'doc' || ext == 'docx';
    return CustomPaint(
      painter: _PagePainter(word ? const Color(0xFF2B5CB8) : const Color(0xFFE5252A)),
      child: Container(
        width: 24,
        height: 32,
        alignment: const Alignment(0, 0.35),
        child: Text(
          word ? 'DOC' : 'PDF',
          style: mText(6.5, weight: FontWeight.w700, color: Colors.white),
        ),
      ),
    );
  }
}

/// A page whose top corner is folded down, the fold a lighter triangle. It
/// is a picture of a sheet of paper, so it is drawn the same way round in
/// either language.
class _PagePainter extends CustomPainter {
  final Color color;
  const _PagePainter(this.color);

  @override
  void paint(Canvas canvas, Size s) {
    const f = 8.0;
    const r = 3.0;
    final page = Path()
      ..moveTo(r, 0)
      ..lineTo(s.width - f, 0)
      ..lineTo(s.width, f)
      ..lineTo(s.width, s.height - r)
      ..quadraticBezierTo(s.width, s.height, s.width - r, s.height)
      ..lineTo(r, s.height)
      ..quadraticBezierTo(0, s.height, 0, s.height - r)
      ..lineTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..close();
    canvas.drawPath(page, Paint()..color = color);
    final fold = Path()
      ..moveTo(s.width - f, 0)
      ..lineTo(s.width, f)
      ..lineTo(s.width - f, f)
      ..close();
    canvas.drawPath(fold, Paint()..color = Colors.white.withValues(alpha: 0.45));
  }

  @override
  bool shouldRepaint(_PagePainter old) => old.color != color;
}

class _Radio extends StatelessWidget {
  final bool selected;
  const _Radio({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: selected ? mStepMid : const Color(0xFFCFCFCF), width: selected ? 2 : 1.5),
      ),
      alignment: Alignment.center,
      child: selected
          ? Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(color: mStepMid, shape: BoxShape.circle),
            )
          : null,
    );
  }
}
