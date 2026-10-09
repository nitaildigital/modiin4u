import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../shared/widgets/error_retry.dart';
import '../../../shared/widgets/m_kit.dart';
import '../../../shared/widgets/m_step_form.dart';
import '../../auth/widgets/m_account_widgets.dart';
import '../../messages/open_conversation.dart';
import '../models/job.dart';
import '../providers/job_providers.dart';
import '../widgets/m_job_card.dart';

/// My Jobs (`user_side/My Jobs.png`, `My Jobs-1.png`): the jobs the person
/// saved, and the ones they applied for with where each application stands.
class MyJobsScreen extends ConsumerStatefulWidget {
  /// 0 opens on Saved Jobs, 1 on Applied Jobs.
  final int initialTab;
  const MyJobsScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends ConsumerState<MyJobsScreen> {
  late int _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(savedJobsProvider);
    final applied = ref.watch(appliedJobsProvider);

    return MPage(
      title: mTr(context, 'My Jobs', 'המשרות שלי'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              height: 36,
              decoration: BoxDecoration(color: const Color(0xFFF6F6F6), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  _Segment(
                    icon: IconsaxPlusLinear.heart,
                    label: _counted(mTr(context, 'Saved Jobs', 'משרות שמורות'), saved.valueOrNull?.length),
                    selected: _tab == 0,
                    onTap: () => setState(() => _tab = 0),
                  ),
                  _Segment(
                    icon: IconsaxPlusLinear.tick_circle,
                    label: _counted(mTr(context, 'Applied Jobs', 'משרות שהגשתי'), applied.valueOrNull?.length),
                    selected: _tab == 1,
                    onTap: () => setState(() => _tab = 1),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: _tab == 0 ? _SavedTab(saved: saved) : _AppliedTab(applied: applied)),
        ],
      ),
    );
  }

  // The count waits for the list rather than showing a nought first.
  String _counted(String label, int? n) => n == null ? label : '$label ($n)';
}

class _Segment extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Segment({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? mStepMid : const Color(0xFF6D6D6D);
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: selected
              ? BoxDecoration(
                  color: mKitBlueBg,
                  border: Border.all(color: mStepMid),
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: mText(14, weight: selected ? FontWeight.w500 : FontWeight.w400, color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedTab extends ConsumerWidget {
  final AsyncValue<List<Job>> saved;
  const _SavedTab({required this.saved});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      color: mStepMid,
      onRefresh: () {
        ref.invalidate(myApplicationsProvider);
        return ref.refresh(savedJobsProvider.future);
      },
      child: saved.when(
        loading: () => const Center(child: CircularProgressIndicator(color: mStepMid)),
        error: (_, _) => ListView(children: [ErrorRetry(onRetry: () => ref.invalidate(savedJobsProvider))]),
        data: (jobs) => jobs.isEmpty
            ? ListView(
                children: [
                  const SizedBox(height: 60),
                  MEmpty(
                    icon: IconsaxPlusLinear.heart,
                    title: mTr(context, 'No saved jobs yet', 'אין עדיין משרות שמורות'),
                    text: mTr(context, 'Tap the heart on a job to keep it here.', 'לחיצה על הלב במשרה תשמור אותה כאן.'),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: jobs.length,
                separatorBuilder: (_, _) => const MJobDivider(),
                itemBuilder: (context, i) => _SavedCard(job: jobs[i]),
              ),
      ),
    );
  }
}

class _SavedCard extends ConsumerWidget {
  final Job job;
  const _SavedCard({required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appliedAt = ref.watch(appliedAtProvider(job.id));
    final Widget button;
    if (appliedAt != null) {
      button = MButton(
        label: mTr(context, 'Message the employer', 'שליחת הודעה למעסיק'),
        icon: IconsaxPlusLinear.message_text,
        height: 42,
        onTap: () => messageBusiness(context, ref, businessId: job.businessId, jobId: job.id),
      );
    } else if (!job.isLive) {
      button = MButton(label: mTr(context, 'Closed', 'המשרה סגורה'), height: 42);
    } else {
      button = MButton(
        label: mTr(context, 'Apply Now', 'הגשת מועמדות'),
        height: 42,
        // Saving needs an account, so whoever sees a saved job is signed in.
        onTap: () => context.push('/jobs/${job.id}/apply'),
      );
    }
    return MJobCardWithHeart(
      card: MJobCard(job: job, onTap: () => context.push('/jobs/${job.id}'), action: button),
    );
  }
}

class _AppliedTab extends ConsumerWidget {
  final AsyncValue<List<(Job, JobApplication)>> applied;
  const _AppliedTab({required this.applied});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      color: mStepMid,
      onRefresh: () {
        ref.invalidate(myApplicationsProvider);
        return ref.refresh(appliedJobsProvider.future);
      },
      child: applied.when(
        loading: () => const Center(child: CircularProgressIndicator(color: mStepMid)),
        error: (_, _) => ListView(children: [ErrorRetry(onRetry: () => ref.invalidate(myApplicationsProvider))]),
        data: (rows) => rows.isEmpty
            ? ListView(
                children: [
                  const SizedBox(height: 60),
                  MEmpty(
                    icon: IconsaxPlusLinear.briefcase,
                    title: mTr(context, 'No applications yet', 'עדיין לא הגשת מועמדות'),
                    text: mTr(context, 'Jobs you apply for will appear here.', 'משרות שהגשת אליהן מועמדות יופיעו כאן.'),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: rows.length + 1,
                // The frame closes the list with a hairline under the last.
                separatorBuilder: (_, _) => const MJobDivider(),
                itemBuilder: (context, i) {
                  if (i == rows.length) return const SizedBox.shrink();
                  final (job, application) = rows[i];
                  return MJobCardWithHeart(
                    card: MJobCard(
                      job: job,
                      onTap: () => context.push('/jobs/${job.id}'),
                      footer: _StatusBox(
                        application: application,
                        onMessage: () => messageBusiness(context, ref, businessId: job.businessId, jobId: job.id),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

/// Where an application stands: green while it is going ahead, grey once
/// the business has said no — with a way to write to the employer.
class _StatusBox extends StatelessWidget {
  final JobApplication application;
  final VoidCallback onMessage;
  const _StatusBox({required this.application, required this.onMessage});

  @override
  Widget build(BuildContext context) {
    final rejected = application.isRejected;
    final tint = rejected ? const Color(0xFF8A8A8A) : const Color(0xFF2EA84A);
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: rejected ? const Color(0xFFF6F6F6) : const Color(0xFFE7F9E8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(rejected ? IconsaxPlusLinear.close_circle : IconsaxPlusLinear.tick_circle, size: 24, color: tint),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(application.statusLabel, style: mText(12.5, weight: FontWeight.w500)),
                const SizedBox(height: 3),
                Text(mAgo(context, application.createdAt), style: mText(12, color: const Color(0xFF4A4A4A))),
              ],
            ),
          ),
          Tooltip(
            message: mTr(context, 'Message the employer', 'שליחת הודעה למעסיק'),
            child: InkResponse(
              onTap: onMessage,
              radius: 22,
              child: Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(IconsaxPlusLinear.message_text, size: 19, color: mStepMid),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
