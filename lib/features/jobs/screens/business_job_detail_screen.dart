import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../../../shared/widgets/error_retry.dart';
import '../../../shared/widgets/m_kit.dart';
import '../../../shared/widgets/m_step_form.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../auth/widgets/m_account_widgets.dart';
import '../../business_owner/data/owner_data.dart';
import '../models/job.dart';
import '../providers/job_providers.dart';
import 'applicant_profile_screen.dart' show confirmJobAction, contactApplicant, experienceYearsLabel;
import 'business_jobs_screen.dart' show shownJobStatus;

/// The owner's page for one job (`business_side/Job Detail*.png`): the job as
/// residents see it, who applied, and how it is doing — with Share and Boost
/// Post pinned to the bottom.
class BusinessJobDetailScreen extends ConsumerStatefulWidget {
  final String jobId;

  /// 1 opens on Applicants (`?tab=applicants`, from a notification).
  final int initialTab;

  const BusinessJobDetailScreen({super.key, required this.jobId, this.initialTab = 0});

  @override
  ConsumerState<BusinessJobDetailScreen> createState() => _BusinessJobDetailScreenState();
}

class _BusinessJobDetailScreenState extends ConsumerState<BusinessJobDetailScreen> {
  late int _tab = widget.initialTab.clamp(0, 2);
  bool _busy = false;

  void _refresh(Job job) {
    ref.invalidate(jobProvider(job.id));
    ref.invalidate(businessJobsProvider(job.businessId));
  }

  Future<void> _setStatus(Job job, JobStatus to) async {
    final closing = to == JobStatus.closed;
    final ok = await confirmJobAction(
      context,
      title: closing ? mTr(context, 'Close this job?', 'לסגור את המשרה?') : mTr(context, 'Reopen this job?', 'לפתוח מחדש את המשרה?'),
      text: closing
          ? mTr(
              context,
              'It stops showing to residents and stops taking applications. You can reopen it later.',
              'המשרה תפסיק להופיע לתושבים ולא תקבל מועמדויות. אפשר לפתוח אותה מחדש בהמשך.',
            )
          : mTr(context, 'It shows to residents again and takes applications.', 'המשרה תופיע שוב לתושבים ותקבל מועמדויות.'),
      confirm: closing ? mTr(context, 'Close job', 'סגירת המשרה') : mTr(context, 'Reopen', 'פתיחה מחדש'),
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(jobRepositoryProvider).setStatus(job.id, to);
      _refresh(job);
    } catch (_) {
      if (mounted) {
        mToast(context, mTr(context, 'That did not work. Try again.', 'הפעולה לא הצליחה. נסו שוב.'), error: true);
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  Widget _menu(Job job) {
    return PopupMenuButton<String>(
      enabled: !_busy,
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.more_horiz, color: Color(0xFF3D3D3D)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      onSelected: (v) => switch (v) {
        'edit' => context.push('/business-jobs/${job.id}/edit'),
        'close' => _setStatus(job, JobStatus.closed),
        'reopen' => _setStatus(job, JobStatus.active),
        _ => null,
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'edit', child: Text(mTr(context, 'Edit', 'עריכה'), style: mText(14))),
        if (job.status == JobStatus.active)
          PopupMenuItem(value: 'close', child: Text(mTr(context, 'Close job', 'סגירת המשרה'), style: mText(14)))
        else if (job.status == JobStatus.closed)
          PopupMenuItem(value: 'reopen', child: Text(mTr(context, 'Reopen', 'פתיחה מחדש'), style: mText(14))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(jobProvider(widget.jobId));
    final job = async.valueOrNull;
    return MPage(
      action: job == null ? null : SizedBox(width: 28, height: 28, child: _menu(job)),
      bottom: job == null ? null : _BottomBar(job: job),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: mStepMid)),
        error: (_, _) => ErrorRetry(onRetry: () => ref.invalidate(jobProvider(widget.jobId))),
        data: (job) => job == null
            ? MEmpty(icon: IconsaxPlusLinear.briefcase, title: mTr(context, 'This job was not found', 'המשרה לא נמצאה'))
            : _body(job),
      ),
    );
  }

  Widget _body(Job job) {
    final applicants = ref.watch(applicantsProvider(job.id));
    final views = ref.watch(jobStatsProvider(job.id)).valueOrNull?['view'];
    final status = shownJobStatus(job);
    final count = applicants.valueOrNull?.length;
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(applicantsProvider(job.id));
        ref.invalidate(jobStatsProvider(job.id));
        _refresh(job);
        await ref.read(jobProvider(job.id).future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(job.title, style: mHeading(24))),
              const SizedBox(width: 10),
              Padding(padding: const EdgeInsets.only(top: 4), child: MStatusPill.forStatus(status.value, status.label)),
            ],
          ),
          const SizedBox(height: 6),
          Text(mDate(context, job.shownDate), style: mText(13.5, color: const Color(0xFF3D3D3D))),
          if (job.jobType != null || job.salaryLabel != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: job.jobType == null
                      ? const SizedBox.shrink()
                      : Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: MMeta(IconsaxPlusLinear.briefcase, job.jobType!.label),
                        ),
                ),
                Expanded(
                  child: job.salaryLabel == null
                      ? const SizedBox.shrink()
                      : Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: MMeta(IconsaxPlusLinear.money_send, job.salaryLabel!),
                        ),
                ),
              ],
            ),
          ],
          if (views != null) ...[
            const SizedBox(height: 10),
            MMeta(IconsaxPlusLinear.eye, '$views'),
          ],
          if (job.chips.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(spacing: 6, runSpacing: 6, children: [for (final c in job.chips) MChip(c)]),
          ],
          const SizedBox(height: 22),
          Row(
            children: [
              _Tab(label: mTr(context, 'Details', 'פרטים'), selected: _tab == 0, onTap: () => setState(() => _tab = 0)),
              _Tab(
                label: count == null
                    ? mTr(context, 'Applicants', 'מועמדים')
                    : mTr(context, 'Applicants ($count)', 'מועמדים ($count)'),
                selected: _tab == 1,
                onTap: () => setState(() => _tab = 1),
              ),
              _Tab(label: mTr(context, 'Performance', 'ביצועים'), selected: _tab == 2, onTap: () => setState(() => _tab = 2)),
            ],
          ),
          ...switch (_tab) {
            0 => [_Details(job: job)],
            1 => [
              const SizedBox(height: 8),
              applicants.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator(color: mStepMid)),
                ),
                error: (_, _) => ErrorRetry(onRetry: () => ref.invalidate(applicantsProvider(job.id))),
                data: (list) => list.isEmpty
                    ? MEmpty(
                        icon: IconsaxPlusLinear.profile_2user,
                        title: mTr(context, 'No applicants yet', 'עדיין אין מועמדים'),
                        text: mTr(
                          context,
                          'When someone applies, they will appear here.',
                          'כשמישהו יגיש מועמדות, הוא יופיע כאן.',
                        ),
                      )
                    : Column(
                        children: [
                          for (var i = 0; i < list.length; i++) ...[
                            if (i > 0) const Divider(height: 1, thickness: 1, color: mStepHairline),
                            _ApplicantRow(job: job, application: list[i]),
                          ],
                        ],
                      ),
              ),
            ],
            _ => [const SizedBox(height: 18), _Performance(job: job, applications: count)],
          },
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? mKitBlueBg : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: mText(14, weight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? mStepMid : mStepGrey),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Bottom bar: share, and Boost Post
// ═══════════════════════════════════════════════

class _BottomBar extends ConsumerWidget {
  final Job job;
  const _BottomBar({required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingPromotionProvider(job.id));
    final Widget boost;
    if (job.isPromoted) {
      boost = MButton(
        label: mTr(
          context,
          'Promoted until ${mDate(context, job.promotedUntil!.toLocal())}',
          'מקודמת עד ${mDate(context, job.promotedUntil!.toLocal())}',
        ),
        height: 44,
      );
    } else if (pending != null) {
      boost = MButton(label: mTr(context, 'Promotion requested', 'נשלחה בקשת קידום'), height: 44);
    } else {
      boost = MButton(
        label: mTr(context, 'Boost Post', 'קידום המשרה'),
        icon: Icons.rocket_launch_outlined,
        iconAfter: true,
        height: 44,
        // Only a live job is seen, so only a live job is worth promoting.
        onTap: job.isLive ? () => context.push('/promote/job/${job.id}') : null,
      );
    }
    return Row(
      children: [
        // A draft or closed job has no page residents can open, so there is
        // nothing to send them.
        if (job.isLive) ...[
          GestureDetector(
            onTap: () => Share.share(
              '${job.title}\nhttps://app.modiin4u.co.il/jobs/${job.id}',
              subject: job.title,
            ),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: mStepHairline)),
              child: const Icon(IconsaxPlusLinear.export_1, size: 20, color: mStepMid),
            ),
          ),
          const SizedBox(width: 16),
        ],
        Expanded(child: boost),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// Details: the job as residents see it
// ═══════════════════════════════════════════════

final _body = mText(14, color: const Color(0xFF3D3D3D), height: 1.6);

class _Details extends ConsumerWidget {
  final Job job;
  const _Details({required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final business = job.businessName;
    final photos = ref.watch(businessPhotosProvider(job.businessId)).valueOrNull ?? const <String>[];
    final responsibilities = Job.bullets(job.responsibilities);
    final requirements = Job.bullets(job.requirements);
    final description = (job.description ?? '').trim();
    final about = (job.businessAbout ?? '').trim();
    final empty = description.isEmpty &&
        responsibilities.isEmpty &&
        requirements.isEmpty &&
        job.images.isEmpty &&
        about.isEmpty &&
        photos.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (empty)
          MEmpty(
            icon: IconsaxPlusLinear.document_text,
            title: mTr(context, 'No details yet', 'עדיין אין פרטים'),
            text: mTr(context, 'Edit the job to describe it.', 'ערכו את המשרה כדי לתאר אותה.'),
          ),
        if (description.isNotEmpty)
          _Section(title: mTr(context, 'About the Job', 'על המשרה'), child: Text(description, style: _body)),
        if (responsibilities.isNotEmpty)
          _Section(title: mTr(context, 'Key Responsibilities', 'תחומי אחריות'), child: _Bullets(responsibilities)),
        if (requirements.isNotEmpty)
          _Section(title: mTr(context, 'Requirements', 'דרישות'), child: _Bullets(requirements)),
        if (job.images.isNotEmpty)
          _Section(title: mTr(context, 'Images', 'תמונות'), child: _Gallery(images: job.images)),
        if (about.isNotEmpty || photos.isNotEmpty)
          _Section(
            title: business == null
                ? mTr(context, 'About the business', 'אודות העסק')
                : mTr(context, 'About $business', 'אודות $business'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (about.isNotEmpty) Text(about, style: _body),
                if (photos.isNotEmpty) ...[
                  SizedBox(height: about.isEmpty ? 0 : 14),
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: photos.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (_, i) => NetworkPhoto(
                        url: photos[i],
                        width: 100,
                        height: 100,
                        radius: BorderRadius.circular(6),
                        icon: IconsaxPlusBold.image,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: mText(16, weight: FontWeight.w600)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Bullets extends StatelessWidget {
  final List<String> lines;
  const _Bullets(this.lines);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final l in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 4, end: 10),
                  child: Text('•', style: _body),
                ),
                Expanded(child: Text(l, style: _body)),
              ],
            ),
          ),
      ],
    );
  }
}

/// The job's pictures, one at a time, with "1/5" in the corner.
class _Gallery extends StatefulWidget {
  final List<String> images;
  const _Gallery({required this.images});

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 200,
        child: Stack(
          children: [
            PageView.builder(
              itemCount: widget.images.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) => NetworkPhoto(url: widget.images[i], height: 200, icon: IconsaxPlusBold.image),
            ),
            if (widget.images.length > 1)
              PositionedDirectional(
                end: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xCC363C3E), borderRadius: BorderRadius.circular(50)),
                  child: Text(
                    '${_page + 1}/${widget.images.length}',
                    textDirection: TextDirection.ltr,
                    style: mText(12, weight: FontWeight.w500, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Applicants
// ═══════════════════════════════════════════════

class _ApplicantRow extends ConsumerStatefulWidget {
  final Job job;
  final JobApplication application;
  const _ApplicantRow({required this.job, required this.application});

  @override
  ConsumerState<_ApplicantRow> createState() => _ApplicantRowState();
}

class _ApplicantRowState extends ConsumerState<_ApplicantRow> {
  bool _contacting = false;

  Future<void> _toggleShortlist() async {
    final a = widget.application;
    try {
      await ref.read(jobRepositoryProvider).setShortlisted(a.id, !a.shortlisted);
      ref.invalidate(applicantsProvider(widget.job.id));
    } catch (_) {
      if (mounted) {
        mToast(context, mTr(context, 'That did not work. Try again.', 'הפעולה לא הצליחה. נסו שוב.'), error: true);
      }
    }
  }

  Future<void> _contact() async {
    if (_contacting) return;
    setState(() => _contacting = true);
    await contactApplicant(context, ref, widget.job, widget.application);
    if (mounted) setState(() => _contacting = false);
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.application;
    final hasAccount = a.profileId != null;
    final location = (a.location ?? '').trim();
    final headline = (a.headline ?? '').trim();
    final years = a.experienceYears;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/applicant/${a.id}', extra: (widget.job, a)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MAvatar(url: a.avatarUrl, name: a.fullName, size: 56),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.fullName, maxLines: 1, overflow: TextOverflow.ellipsis, style: mHeading(18)),
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    MMeta(IconsaxPlusLinear.location, location),
                  ],
                  if (headline.isNotEmpty || years != null) ...[
                    const SizedBox(height: 6),
                    Text.rich(
                      TextSpan(
                        children: [
                          if (headline.isNotEmpty) TextSpan(text: headline, style: mText(14, color: const Color(0xFF3D3D3D))),
                          if (headline.isNotEmpty && years != null) const TextSpan(text: '  '),
                          if (years != null) TextSpan(text: experienceYearsLabel(context, years), style: mText(12, color: mStepGrey)),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    mTr(context, 'Applied ${mAgo(context, a.createdAt)}', 'הגיש/ה מועמדות ${mAgo(context, a.createdAt)}'),
                    style: mText(12.5, color: const Color(0xFF3D3D3D)),
                  ),
                  if (a.status != 'new') ...[
                    const SizedBox(height: 8),
                    MStatusPill.forStatus(a.status, a.statusLabel),
                  ],
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _contact,
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 26),
                      decoration: BoxDecoration(color: mStepMid, borderRadius: BorderRadius.circular(60)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_contacting)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          else
                            Icon(
                              hasAccount
                                  ? IconsaxPlusLinear.message_text
                                  : (a.phone ?? '').isNotEmpty
                                  ? IconsaxPlusLinear.call
                                  : IconsaxPlusLinear.sms,
                              size: 18,
                              color: Colors.white,
                            ),
                          const SizedBox(width: 8),
                          Text(
                            hasAccount
                                ? mTr(context, 'Contact', 'יצירת קשר')
                                : (a.phone ?? '').isNotEmpty
                                ? mTr(context, 'Call', 'התקשרות')
                                : mTr(context, 'Email', 'אימייל'),
                            style: mText(14, weight: FontWeight.w500, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleShortlist,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  a.shortlisted ? IconsaxPlusBold.heart : IconsaxPlusLinear.heart,
                  size: 22,
                  color: a.shortlisted ? mKitRed : const Color(0xFF3D3D3D),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Performance
// ═══════════════════════════════════════════════

class _Performance extends ConsumerWidget {
  final Job job;
  final int? applications;
  const _Performance({required this.job, required this.applications});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(jobStatsProvider(job.id));
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator(color: mStepMid)),
      ),
      error: (_, _) => ErrorRetry(onRetry: () => ref.invalidate(jobStatsProvider(job.id))),
      data: (stats) {
        final views = stats['view'] ?? 0;
        final applied = applications ?? stats['apply'] ?? 0;
        final tiles = [
          (IconsaxPlusLinear.eye, '$views', mTr(context, 'Views', 'צפיות')),
          (IconsaxPlusLinear.profile_2user, '$applied', mTr(context, 'Applications', 'מועמדויות')),
          (IconsaxPlusLinear.heart, '${stats['saves'] ?? 0}', mTr(context, 'Saves', 'שמירות')),
          (IconsaxPlusLinear.export_1, '${stats['share'] ?? 0}', mTr(context, 'Shares', 'שיתופים')),
          // Of those who looked, how many applied; nothing to say before
          // anyone has looked.
          if (views > 0)
            (IconsaxPlusLinear.chart_2, '${(applied * 100 / views).toStringAsFixed(1)}%', mTr(context, 'Conversion', 'המרה')),
        ];
        return LayoutBuilder(
          builder: (context, box) {
            final w = (box.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final t in tiles)
                  Container(
                    width: w,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: mKitBlueBg, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(t.$1, size: 22, color: mStepMid),
                        const SizedBox(height: 12),
                        Text(t.$2, textDirection: TextDirection.ltr, style: mHeading(22)),
                        const SizedBox(height: 2),
                        Text(t.$3, style: mText(13, color: mStepGrey)),
                      ],
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
