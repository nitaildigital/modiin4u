import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../../../shared/widgets/error_retry.dart';
import '../../../shared/widgets/m_kit.dart';
import '../../../shared/widgets/m_step_form.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../../shared/widgets/sign_in_action.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/widgets/m_account_widgets.dart';
import '../../messages/open_conversation.dart';
import '../models/job.dart';
import '../providers/job_providers.dart';
import '../widgets/m_job_card.dart';

/// Job Detail (`user_side/Job Detail.png`, `Job Detail Applied.png`): the
/// job, what it asks, its pictures and the business behind it, with Share and
/// Apply Now — once applied, Message the employer — pinned to the bottom. A section the business left empty is not
/// drawn.
class JobDetailScreen extends ConsumerStatefulWidget {
  final String jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  @override
  void initState() {
    super.initState();
    // One view per opening of the page, for the business's statistics.
    ref.read(jobRepositoryProvider).recordEvent(widget.jobId, 'view');
  }

  void _share(Job job) {
    ref.read(jobRepositoryProvider).recordEvent(job.id, 'share');
    Share.share(
      '${job.title}\nhttps://app.modiin4u.co.il/jobs/${job.id}',
      subject: job.title,
    );
  }

  void _apply(Job job) {
    if (ref.read(authProvider) == null) {
      // Applying sends the person's name and contact, so it needs an account.
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(mTr(context, 'Sign in to apply for this job', 'יש להתחבר כדי להגיש מועמדות'), style: mText(14, color: Colors.white)),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: signInAction(context),
        ),
      );
      return;
    }
    context.push('/jobs/${job.id}/apply');
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(jobProvider(widget.jobId));
    final job = async.valueOrNull;
    final appliedAt = ref.watch(appliedAtProvider(widget.jobId));

    return MPage(
      action: job == null ? null : MJobHeart(jobId: job.id, iconSize: 24),
      bottom: job == null ? null : _bottomBar(job, appliedAt),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: mStepMid)),
        error: (_, _) => ErrorRetry(onRetry: () => ref.invalidate(jobProvider(widget.jobId))),
        data: (job) => job == null
            ? MEmpty(
                icon: IconsaxPlusLinear.briefcase,
                title: mTr(context, 'This job is no longer available', 'המשרה אינה זמינה עוד'),
              )
            : _JobBody(job: job, appliedAt: appliedAt),
      ),
    );
  }

  Widget _bottomBar(Job job, DateTime? appliedAt) {
    final Widget main;
    if (appliedAt != null) {
      // Applied: the box above says so, and the button writes to the
      // employer instead (the client, 9 Oct — "if we applied for the job …
      // then we can send them a message").
      main = MButton(
        label: mTr(context, 'Message the employer', 'שליחת הודעה למעסיק'),
        icon: IconsaxPlusLinear.message_text,
        height: 44,
        onTap: () => messageBusiness(context, ref, businessId: job.businessId, jobId: job.id),
      );
    } else if (!job.isLive) {
      main = MButton(label: mTr(context, 'Closed', 'המשרה סגורה'), height: 44);
    } else {
      main = MButton(label: mTr(context, 'Apply Now', 'הגשת מועמדות'), height: 44, onTap: () => _apply(job));
    }
    return Row(
      children: [
        GestureDetector(
          onTap: () => _share(job),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: mStepHairline),
            ),
            child: const Icon(IconsaxPlusLinear.export_1, size: 20, color: mStepMid),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: main),
      ],
    );
  }
}

class _JobBody extends ConsumerWidget {
  final Job job;
  final DateTime? appliedAt;
  const _JobBody({required this.job, required this.appliedAt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final business = job.businessName;
    final photos = ref.watch(businessPhotosProvider(job.businessId)).valueOrNull ?? const <String>[];
    final responsibilities = Job.bullets(job.responsibilities);
    final requirements = Job.bullets(job.requirements);
    final description = (job.description ?? '').trim();
    final about = (job.businessAbout ?? '').trim();
    void openBusiness() => context.push('/business/${job.businessId}');

    final meta = <Widget>[
      if ((job.location ?? '').trim().isNotEmpty) MJobMeta(IconsaxPlusLinear.location, job.location!.trim(), size: 14),
      if (job.jobType != null) MJobMeta(IconsaxPlusLinear.briefcase, job.jobType!.label, size: 14),
      if (job.salaryLabel != null) MJobMeta(IconsaxPlusLinear.money_send, job.salaryLabel!, size: 14),
      if (job.publishedAt != null) MJobMeta(IconsaxPlusLinear.clock, mAgo(context, job.publishedAt!), size: 14),
    ];

    return ListView(
      padding: const EdgeInsets.only(top: 18, bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: openBusiness,
                child: MAvatar(url: job.businessLogo, name: business ?? job.title, size: 70),
              ),
              const SizedBox(height: 14),
              Text(job.title, style: mHeading(24)),
              if (business != null) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: openBusiness,
                  child: Text(business, style: mText(14, color: const Color(0xFF3D3D3D))),
                ),
              ],
              if (meta.isNotEmpty) ...[
                const SizedBox(height: 14),
                // Two columns, filled in order, so a missing item leaves no
                // hole.
                for (var i = 0; i < meta.length; i += 2)
                  Padding(
                    padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
                    child: Row(
                      children: [
                        Expanded(child: Align(alignment: AlignmentDirectional.centerStart, child: meta[i])),
                        Expanded(
                          child: i + 1 < meta.length
                              ? Align(alignment: AlignmentDirectional.centerStart, child: meta[i + 1])
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
              ],
              if (job.chips.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [for (final c in job.chips) MChip(c, background: mJobChipBg)],
                ),
              ],
              if (appliedAt != null) ...[
                const SizedBox(height: 22),
                _AppliedBox(appliedAt: appliedAt!),
              ],
              if (description.isNotEmpty)
                _Section(
                  title: mTr(context, 'About the Job', 'על המשרה'),
                  child: Text(description, style: _body),
                ),
              if (responsibilities.isNotEmpty)
                _Section(
                  title: mTr(context, 'Key Responsibilities', 'תחומי אחריות'),
                  child: _Bullets(responsibilities),
                ),
              if (requirements.isNotEmpty)
                _Section(
                  title: mTr(context, 'Requirements', 'דרישות'),
                  child: _Bullets(requirements),
                ),
              if (job.images.isNotEmpty)
                _Section(title: mTr(context, 'Images', 'תמונות'), child: _Gallery(images: job.images)),
              if (about.isNotEmpty || photos.isNotEmpty)
                _Section(
                  title: business == null
                      ? mTr(context, 'About the business', 'אודות העסק')
                      : mTr(context, 'About $business', 'אודות $business'),
                  onTitleTap: openBusiness,
                  child: about.isEmpty ? const SizedBox.shrink() : Text(about, style: _body),
                ),
            ],
          ),
        ),
        if (photos.isNotEmpty) ...[
          SizedBox(height: about.isEmpty ? 0 : 14),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: photos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) => GestureDetector(
                onTap: openBusiness,
                child: NetworkPhoto(
                  url: photos[i],
                  width: 100,
                  height: 100,
                  radius: BorderRadius.circular(6),
                  icon: IconsaxPlusBold.image,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

final _body = mText(14, color: const Color(0xFF3D3D3D), height: 1.6);

/// "05 Oct 2026", as the applied box writes it; Hebrew in the app's form.
String _appliedDate(BuildContext context, DateTime d) {
  const en = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final local = d.toLocal();
  return mTr(
    context,
    '${local.day.toString().padLeft(2, '0')} ${en[local.month - 1]} ${local.year}',
    mDate(context, local),
  );
}

class _AppliedBox extends StatelessWidget {
  final DateTime appliedAt;
  const _AppliedBox({required this.appliedAt});

  @override
  Widget build(BuildContext context) {
    final date = _appliedDate(context, appliedAt);
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 14),
      decoration: BoxDecoration(color: const Color(0xFFE7F9E8), borderRadius: BorderRadius.circular(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(IconsaxPlusLinear.tick_circle, size: 28, color: Color(0xFF2EA84A)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mTr(context, 'You’ve already applied', 'כבר הגשת מועמדות'), style: mText(16, weight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(
                  mTr(context, 'Your application was submitted on $date.', 'המועמדות שלך נשלחה ב־$date.'),
                  style: mText(13.5, color: const Color(0xFF3D3D3D), height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onTitleTap;
  const _Section({required this.title, required this.child, this.onTitleTap});

  @override
  Widget build(BuildContext context) {
    final heading = Text(title, style: mText(16, weight: FontWeight.w600));
    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          onTitleTap == null ? heading : GestureDetector(onTap: onTitleTap, child: heading),
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
              itemBuilder: (_, i) => NetworkPhoto(
                url: widget.images[i],
                height: 200,
                icon: IconsaxPlusBold.image,
              ),
            ),
            if (widget.images.length > 1)
              PositionedDirectional(
                end: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xCC363C3E),
                    borderRadius: BorderRadius.circular(50),
                  ),
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
