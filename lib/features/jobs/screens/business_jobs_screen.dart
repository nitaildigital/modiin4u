import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../shared/widgets/m_kit.dart';
import '../../../shared/widgets/m_step_form.dart';
import '../../auth/widgets/m_account_widgets.dart';
import '../../business_owner/data/owner_data.dart';
import '../models/job.dart';
import '../providers/job_providers.dart';

/// My Jobs (`business_side/My Jobs.png`): the business's own jobs, live or
/// not, with how many applied and how many looked, and the way to post
/// another.
class BusinessJobsScreen extends ConsumerStatefulWidget {
  const BusinessJobsScreen({super.key});

  @override
  ConsumerState<BusinessJobsScreen> createState() => _BusinessJobsScreenState();
}

enum _Tab { all, active, draft, closed }

/// The status a job is shown under. An active job past its end date is no
/// longer live, so it is counted and labelled with the expired ones rather
/// than as Active.
JobStatus shownJobStatus(Job job) =>
    job.status == JobStatus.active && !job.isLive ? JobStatus.expired : job.status;

class _BusinessJobsScreenState extends ConsumerState<BusinessJobsScreen> {
  _Tab _tab = _Tab.all;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _inTab(Job job, _Tab tab) {
    final s = shownJobStatus(job);
    return switch (tab) {
      _Tab.all => true,
      _Tab.active => s == JobStatus.active,
      _Tab.draft => s == JobStatus.draft,
      _Tab.closed => s == JobStatus.closed || s == JobStatus.expired,
    };
  }

  String _tabLabel(_Tab tab) => switch (tab) {
    _Tab.all => mTr(context, 'All', 'הכל'),
    _Tab.active => mTr(context, 'Active', 'פעילות'),
    _Tab.draft => mTr(context, 'Draft', 'טיוטות'),
    _Tab.closed => mTr(context, 'Closed', 'סגורות'),
  };

  @override
  Widget build(BuildContext context) {
    final businessId = ref.watch(myBusinessIdProvider);
    return MPage(
      title: mTr(context, 'My Jobs', 'המשרות שלי'),
      body: businessId == null
          ? MEmpty(
              icon: IconsaxPlusLinear.briefcase,
              title: mTr(context, 'This needs a business account', 'נדרש חשבון עסקי'),
              text: mTr(
                context,
                'Jobs are posted by businesses. Sign in with your business account to manage them.',
                'משרות מפורסמות על ידי עסקים. התחברו עם החשבון העסקי כדי לנהל אותן.',
              ),
            )
          : _body(businessId),
    );
  }

  Widget _body(String businessId) {
    final jobsAsync = ref.watch(businessJobsProvider(businessId));
    return Stack(
      children: [
        jobsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => MEmpty(
            icon: IconsaxPlusLinear.briefcase,
            title: mTr(context, 'Could not load your jobs', 'לא הצלחנו לטעון את המשרות'),
            text: mTr(context, 'Check the connection and try again.', 'בדקו את החיבור ונסו שוב.'),
          ),
          data: (jobs) => _list(businessId, jobs),
        ),
        PositionedDirectional(
          start: 0,
          end: 0,
          bottom: 20,
          child: Center(
            child: MFloatingAdd(
              label: mTr(context, 'Post a Job', 'פרסום משרה'),
              onTap: () => context.push('/business-jobs/new'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _list(String businessId, List<Job> jobs) {
    final counts = ref.watch(applicationCountsProvider(businessId)).valueOrNull ?? const {};
    final query = _search.text.trim().toLowerCase();
    final shown = [
      for (final j in jobs)
        if (_inTab(j, _tab) && (query.isEmpty || j.title.toLowerCase().contains(query))) j,
    ];
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(businessJobsProvider(businessId));
        for (final j in jobs) {
          ref.invalidate(jobStatsProvider(j.id));
        }
        await ref.read(businessJobsProvider(businessId).future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        // Room at the foot for the floating Post a Job pill.
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
        children: [
          _tabs(jobs),
          const SizedBox(height: 16),
          _searchField(),
          const SizedBox(height: 16),
          if (jobs.isEmpty)
            MEmpty(
              icon: IconsaxPlusLinear.briefcase,
              title: mTr(context, 'No jobs yet', 'עדיין אין משרות'),
              text: mTr(
                context,
                'Post your first job and residents of Modiin will see it.',
                'פרסמו את המשרה הראשונה ותושבי מודיעין יראו אותה.',
              ),
            )
          else if (shown.isEmpty)
            MEmpty(
              icon: IconsaxPlusLinear.search_normal,
              title: mTr(context, 'Nothing here', 'אין כאן כלום'),
            )
          else
            for (var i = 0; i < shown.length; i++) ...[
              if (i > 0) const Divider(height: 1, thickness: 1, color: mStepHairline),
              _JobCard(job: shown[i], applications: counts[shown[i].id] ?? 0),
            ],
        ],
      ),
    );
  }

  Widget _tabs(List<Job> jobs) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final t in _Tab.values)
            _PillTab(
              label: '${_tabLabel(t)} (${jobs.where((j) => _inTab(j, t)).length})',
              selected: _tab == t,
              onTap: () => setState(() => _tab = t),
            ),
        ],
      ),
    );
  }

  Widget _searchField() {
    return Container(
      height: 48,
      padding: const EdgeInsetsDirectional.only(start: 16, end: 12),
      decoration: BoxDecoration(
        border: Border.all(color: mStepHairline),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: [
          const Icon(IconsaxPlusLinear.search_normal_1, size: 20, color: mStepGrey),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              style: mText(14),
              decoration: InputDecoration(
                hintText: mTr(context, 'Search your jobs', 'חיפוש במשרות שלכם'),
                hintStyle: mText(14, color: mStepGrey),
                // The theme fills inputs grey; this one sits in the white pill.
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_search.text.isNotEmpty)
            GestureDetector(
              onTap: () => setState(_search.clear),
              child: const Icon(Icons.close, size: 18, color: mStepGrey),
            ),
        ],
      ),
    );
  }
}

/// One of the pill tabs: the selected one light blue, the rest plain text.
class _PillTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PillTab({required this.label, required this.selected, required this.onTap});

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

class _JobCard extends ConsumerWidget {
  final Job job;
  final int applications;
  const _JobCard({required this.job, required this.applications});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A job nobody has opened has no 'view' row at all: that is 0, not
    // unknown. Only while the numbers load is there nothing to show.
    final stats = ref.watch(jobStatsProvider(job.id)).valueOrNull;
    final views = stats == null ? null : (stats['view'] ?? 0);
    final status = shownJobStatus(job);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/business-jobs/${job.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(job.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: mHeading(18)),
                ),
                const SizedBox(width: 10),
                MStatusPill.forStatus(status.value, status.label),
              ],
            ),
            const SizedBox(height: 4),
            Text(mDate(context, job.shownDate), style: mText(13, color: mStepGrey)),
            if (job.jobType != null || job.salaryLabel != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: job.jobType == null
                        ? const SizedBox.shrink()
                        : MMeta(IconsaxPlusLinear.briefcase, job.jobType!.label, color: mStepGrey),
                  ),
                  Expanded(
                    child: job.salaryLabel == null
                        ? const SizedBox.shrink()
                        : MMeta(IconsaxPlusLinear.money_send, job.salaryLabel!, color: mStepGrey),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: mKitBlueBg, borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Expanded(
                    child: _Stat(
                      icon: IconsaxPlusLinear.profile_2user,
                      value: '$applications',
                      label: mTr(context, 'Applications', 'מועמדויות'),
                    ),
                  ),
                  Expanded(
                    child: _Stat(
                      icon: IconsaxPlusLinear.eye,
                      value: views == null ? '—' : '$views',
                      label: mTr(context, 'Views', 'צפיות'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _Stat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: mStepMid),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: mText(14, weight: FontWeight.w600)),
            Text(label, style: mText(12, color: mStepGrey)),
          ],
        ),
      ],
    );
  }
}
