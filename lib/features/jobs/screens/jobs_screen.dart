import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../shared/widgets/error_retry.dart';
import '../../../shared/widgets/m_kit.dart';
import '../../../shared/widgets/m_step_form.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/widgets/m_account_widgets.dart';
import '../models/job.dart';
import '../providers/job_providers.dart';
import '../repositories/job_repository.dart';
import '../widgets/m_job_card.dart';

/// Jobs (`user_side/Jobs.png`): the search, the five quick filters as
/// ticked chips, and the open jobs — promoted first, as the repository orders
/// them — with an invitation to finish My Profile after the second.
class JobsScreen extends ConsumerStatefulWidget {
  const JobsScreen({super.key});

  @override
  ConsumerState<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends ConsumerState<JobsScreen> {
  late final TextEditingController _search;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // The filters outlive the page, so the box shows what is still applied.
    _search = TextEditingController(text: ref.read(jobFiltersProvider).search);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  // Each keystroke would be a query; wait for a pause in the typing.
  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final f = ref.read(jobFiltersProvider);
      if (f.search != value) ref.read(jobFiltersProvider.notifier).state = f.copyWith(search: value);
    });
  }

  void _update(JobFilters Function(JobFilters) change) {
    final n = ref.read(jobFiltersProvider.notifier);
    n.state = change(n.state);
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(jobFiltersProvider);
    final jobs = ref.watch(liveJobsProvider);
    final sheetSet = filters.type != null || filters.categoryId != null;

    return MPage(
      title: mTr(context, 'Jobs', 'משרות'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _SearchBox(
              controller: _search,
              onChanged: _onSearch,
              filterSet: sheetSet,
              onFilter: () => _openFilters(context),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _CheckChip(
                  label: mTr(context, 'Youth Jobs', 'משרות לנוער'),
                  checked: filters.youth,
                  onTap: () => _update((f) => f.copyWith(youth: !f.youth)),
                ),
                _CheckChip(
                  label: mTr(context, 'No Experience', 'ללא ניסיון'),
                  checked: filters.noExperience,
                  onTap: () => _update((f) => f.copyWith(noExperience: !f.noExperience)),
                ),
                _CheckChip(
                  label: mTr(context, 'Part-Time', 'משרה חלקית'),
                  checked: filters.partTime,
                  onTap: () => _update((f) => f.copyWith(partTime: !f.partTime)),
                ),
                _CheckChip(
                  label: mTr(context, 'Students', 'סטודנטים'),
                  checked: filters.students,
                  onTap: () => _update((f) => f.copyWith(students: !f.students)),
                ),
                _CheckChip(
                  label: mTr(context, 'Shift work', 'עבודה במשמרות'),
                  checked: filters.shifts,
                  onTap: () => _update((f) => f.copyWith(shifts: !f.shifts)),
                  last: true,
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: mStepMid,
              onRefresh: () => ref.refresh(liveJobsProvider.future),
              child: jobs.when(
                loading: () => const Center(child: CircularProgressIndicator(color: mStepMid)),
                error: (_, _) => ListView(
                  children: [ErrorRetry(onRetry: () => ref.invalidate(liveJobsProvider))],
                ),
                data: (list) => _JobList(jobs: list, filtered: filters != const JobFilters()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFilters(BuildContext context) async {
    final picked = await showModalBottomSheet<JobFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FilterSheet(initial: ref.read(jobFiltersProvider)),
    );
    if (picked != null) ref.read(jobFiltersProvider.notifier).state = picked;
  }
}

class _JobList extends ConsumerWidget {
  final List<Job> jobs;
  final bool filtered;
  const _JobList({required this.jobs, required this.filtered});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    // The band asks the signed-in to finish My Profile, until it is whole.
    final seeker = user == null ? null : ref.watch(myJobSeekerProvider).valueOrNull;
    final showBand = seeker != null && seeker.completion(hasBasics: user!.phone.trim().isNotEmpty) < 1.0;

    final heading = Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Text(
        mTr(context, 'Jobs Near You', 'משרות באזור'),
        style: mText(16, weight: FontWeight.w600),
      ),
    );

    if (jobs.isEmpty) {
      return ListView(
        children: [
          heading,
          const SizedBox(height: 40),
          filtered
              ? MEmpty(
                  icon: IconsaxPlusLinear.search_normal_1,
                  title: mTr(context, 'No jobs found', 'לא נמצאו משרות'),
                  text: mTr(context, 'Try other filters or another search.', 'אפשר לנסות סינון או חיפוש אחר.'),
                )
              : MEmpty(
                  icon: IconsaxPlusLinear.briefcase,
                  title: mTr(context, 'No jobs right now', 'אין משרות כרגע'),
                  text: mTr(context, 'New openings will appear here.', 'משרות חדשות יופיעו כאן.'),
                ),
        ],
      );
    }

    // Between the second card and the third, or after the last when there
    // are fewer.
    final bandAt = jobs.length < 2 ? jobs.length : 2;
    final children = <Widget>[heading, const SizedBox(height: 4)];
    for (var i = 0; i < jobs.length; i++) {
      if (showBand && i == bandAt) children.add(const _CompleteProfileBand());
      final job = jobs[i];
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              MJobCardWithHeart(
                card: MJobCard(job: job, onTap: () => context.push('/jobs/${job.id}')),
              ),
              // The band draws its own edge, so no hairline runs into it.
              if (i < jobs.length - 1 && !(showBand && i + 1 == bandAt)) const MJobDivider(),
            ],
          ),
        ),
      );
    }
    if (showBand && bandAt == jobs.length) children.add(const _CompleteProfileBand());
    children.add(const SizedBox(height: 24));

    return ListView(children: children);
  }
}

/// The blue band in the list: "Complete your profile".
class _CompleteProfileBand extends StatelessWidget {
  const _CompleteProfileBand();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F7FD),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            margin: const EdgeInsets.only(top: 6),
            decoration: const BoxDecoration(color: Color(0xFFD2E4F8), shape: BoxShape.circle),
            child: const Icon(IconsaxPlusBold.user, size: 24, color: mStepMid),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mTr(context, 'Complete your profile', 'השלמת הפרופיל'), style: mHeading(18)),
                const SizedBox(height: 4),
                Text(
                  mTr(
                    context,
                    'Apply faster and get discovered by local employers',
                    'הגשה מהירה יותר וחשיפה למעסיקים באזור',
                  ),
                  style: mText(12.5, color: const Color(0xFF4A4A4A), height: 1.35),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => context.push('/my-profile'),
                  child: Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: mStepMid, borderRadius: BorderRadius.circular(60)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          mTr(context, 'Complete Profile', 'להשלמת הפרופיל'),
                          style: mText(12.5, weight: FontWeight.w500, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        // The arrow points onward, which in Hebrew is left.
                        Icon(
                          Directionality.of(context) == TextDirection.rtl
                              ? Icons.arrow_back_rounded
                              : Icons.arrow_forward_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool filterSet;
  final VoidCallback onFilter;

  const _SearchBox({
    required this.controller,
    required this.onChanged,
    required this.filterSet,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsetsDirectional.only(start: 16, end: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: mStepHairline),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          const Icon(IconsaxPlusLinear.search_normal_1, size: 19, color: Color(0xFF3D3D3D)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: mText(14.5),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                hintText: mTr(context, 'Search jobs, companies or keywords...', 'חיפוש משרות, עסקים או מילות מפתח...'),
                hintStyle: mText(14.5, color: const Color(0xFF8A8A8A)),
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onFilter,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(IconsaxPlusLinear.setting_4, size: 22, color: mStepMid),
                  // A dot says the sheet holds a choice the chips do not show.
                  if (filterSet)
                    const PositionedDirectional(
                      top: -2,
                      end: -2,
                      child: SizedBox(
                        width: 8,
                        height: 8,
                        child: DecoratedBox(decoration: BoxDecoration(color: mKitRed, shape: BoxShape.circle)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A bordered chip with a tick box in it, as the frames draw the quick
/// filters.
class _CheckChip extends StatelessWidget {
  final String label;
  final bool checked;
  final VoidCallback onTap;
  final bool last;

  const _CheckChip({required this.label, required this.checked, required this.onTap, this.last = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(end: last ? 0 : 8),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: checked ? mKitBlueBg : Colors.white,
            border: Border.all(color: checked ? mStepMid : mStepHairline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MJobTickBox(checked: checked),
              const SizedBox(width: 8),
              Text(label, style: mText(14, color: const Color(0xFF3D3D3D))),
            ],
          ),
        ),
      ),
    );
  }
}

/// The filter icon's sheet: the kind of job, the category (when the client
/// keeps any), and the same five flags as the chips.
class _FilterSheet extends ConsumerStatefulWidget {
  final JobFilters initial;
  const _FilterSheet({required this.initial});

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late JobFilters _f = widget.initial;

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(jobCategoriesProvider).valueOrNull ?? const [];
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 14),
                decoration: BoxDecoration(color: mStepHairline, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(mTr(context, 'Filters', 'סינון'), style: mHeading(20)),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label(mTr(context, 'Job type', 'סוג משרה')),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _choice(mTr(context, 'Any', 'הכול'), _f.type == null, () => _f = _f.copyWith(clearType: true)),
                        for (final t in JobType.values)
                          _choice(t.label, _f.type == t, () => _f = _f.copyWith(type: t)),
                      ],
                    ),
                    if (categories.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _label(mTr(context, 'Category', 'קטגוריה')),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _choice(
                            mTr(context, 'Any', 'הכול'),
                            _f.categoryId == null,
                            () => _f = _f.copyWith(clearCategory: true),
                          ),
                          for (final c in categories)
                            _choice(c.name, _f.categoryId == c.id, () => _f = _f.copyWith(categoryId: c.id)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                    _label(mTr(context, 'Show only', 'רק משרות')),
                    _flag(mTr(context, 'Youth Jobs', 'משרות לנוער'), _f.youth, () => _f = _f.copyWith(youth: !_f.youth)),
                    _flag(
                      mTr(context, 'No Experience', 'ללא ניסיון'),
                      _f.noExperience,
                      () => _f = _f.copyWith(noExperience: !_f.noExperience),
                    ),
                    _flag(
                      mTr(context, 'Part-Time', 'משרה חלקית'),
                      _f.partTime,
                      () => _f = _f.copyWith(partTime: !_f.partTime),
                    ),
                    _flag(
                      mTr(context, 'Students', 'סטודנטים'),
                      _f.students,
                      () => _f = _f.copyWith(students: !_f.students),
                    ),
                    _flag(
                      mTr(context, 'Shift work', 'עבודה במשמרות'),
                      _f.shifts,
                      () => _f = _f.copyWith(shifts: !_f.shifts),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: MButton(
                      label: mTr(context, 'Clear', 'ניקוי'),
                      outlined: true,
                      // The search stays: it is typed on the page, not here.
                      onTap: () => Navigator.pop(context, JobFilters(search: _f.search)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MButton(
                      label: mTr(context, 'Show jobs', 'הצגת משרות'),
                      onTap: () => Navigator.pop(context, _f),
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

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text, style: mText(14, weight: FontWeight.w600)),
  );

  Widget _choice(String label, bool selected, VoidCallback pick) => GestureDetector(
    onTap: () => setState(pick),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? mKitBlueBg : Colors.white,
        border: Border.all(color: selected ? mStepMid : mStepHairline),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        label,
        style: mText(13.5, weight: selected ? FontWeight.w500 : FontWeight.w400, color: selected ? mStepMid : const Color(0xFF3D3D3D)),
      ),
    ),
  );

  Widget _flag(String label, bool checked, VoidCallback toggle) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () => setState(toggle),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          MJobTickBox(checked: checked, size: 20),
          const SizedBox(width: 10),
          Text(label, style: mText(14, color: const Color(0xFF3D3D3D))),
        ],
      ),
    ),
  );
}
