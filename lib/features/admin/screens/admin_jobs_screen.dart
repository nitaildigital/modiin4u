import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../jobs/models/job.dart';
import '../admin_language.dart';
import '../ui/admin_kit.dart';

/// Every job opening businesses have posted (00052, 00069). Owners post and
/// edit their own, live at once; the panel keeps the last word, as the
/// client asked of everything shown in the app: it can close a job, open it
/// again, and end a promotion early. Nothing is deleted from here — closing
/// is the reversible removal.

final _statusProvider = StateProvider.autoDispose<String>((ref) => 'active');
final _searchProvider = StateProvider.autoDispose<String>((ref) => '');

final _jobsProvider = FutureProvider.autoDispose<List<(Job, int)>>((ref) async {
  final status = ref.watch(_statusProvider);
  final client = SupabaseConfig.client;
  var q = client.from('jobs').select('*, businesses(id, name, name_en, logo_url)');
  if (status != 'all') q = q.eq('status', status);
  final rows = await q.order('created_at', ascending: false).limit(300);
  final jobs = List<Map<String, dynamic>>.from(rows).map(Job.fromJson).toList();
  final counts = <String, int>{};
  if (jobs.isNotEmpty) {
    final apps = await client
        .from('job_applications')
        .select('job_id')
        .inFilter('job_id', jobs.map((j) => j.id).toList());
    for (final a in List<Map<String, dynamic>>.from(apps)) {
      final id = a['job_id'] as String;
      counts[id] = (counts[id] ?? 0) + 1;
    }
  }
  return [for (final j in jobs) (j, counts[j.id] ?? 0)];
});

class AdminJobsScreen extends ConsumerWidget {
  const AdminJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final k = AdminKit.of(context);
    final status = ref.watch(_statusProvider);
    final search = ref.watch(_searchProvider).trim().toLowerCase();
    final jobs = ref.watch(_jobsProvider);

    void setStatus(String s) {
      ref.read(_statusProvider.notifier).state = s;
      ref.invalidate(_jobsProvider);
    }

    final shown = (jobs.valueOrNull ?? const <(Job, int)>[])
        .where(
          (e) =>
              search.isEmpty ||
              e.$1.title.toLowerCase().contains(search) ||
              (e.$1.businessName ?? '').toLowerCase().contains(search),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminListToolbar(
          search: AdminSearchField(
            hint: tr('חיפוש משרה או עסק', 'Search a job or business'),
            onChanged: (v) => ref.read(_searchProvider.notifier).state = v,
          ),
          filters: [
            for (final (value, label) in [
              ('active', tr('פעילות', 'Active')),
              ('draft', tr('טיוטות', 'Drafts')),
              ('closed', tr('סגורות', 'Closed')),
              ('expired', tr('פגו', 'Expired')),
              ('all', tr('הכל', 'All')),
            ]) ...[AdminFilterChip(label, status == value, () => setStatus(value)), const SizedBox(width: 8)],
          ],
          count: jobs.valueOrNull == null ? null : '${shown.length}',
          actions: [
            AdminToolbarButton(
              label: tr('רענון', 'Refresh'),
              icon: Icons.refresh,
              primary: false,
              onPressed: () => ref.invalidate(_jobsProvider),
            ),
          ],
        ),
        Expanded(
          child: jobs.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tr('המשרות לא נטענו.', 'Jobs did not load.'), style: k.body),
                  const SizedBox(height: 4),
                  Text(
                    '$e'.contains('jobs')
                        ? tr('הרץ את מיגרציות 00052 ו־00069.', 'Run migrations 00052 and 00069.')
                        : '$e',
                    style: k.hint,
                  ),
                  const SizedBox(height: 12),
                  AdminButton.secondary(
                    label: tr('נסה שוב', 'Try again'),
                    onPressed: () => ref.invalidate(_jobsProvider),
                  ),
                ],
              ),
            ),
            data: (_) => shown.isEmpty
                ? Center(child: Text(tr('אין משרות.', 'No jobs.'), style: k.hint))
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: shown.length,
                    itemBuilder: (context, i) => _JobRow(job: shown[i].$1, applications: shown[i].$2),
                  ),
          ),
        ),
      ],
    );
  }
}

class _JobRow extends ConsumerStatefulWidget {
  final Job job;
  final int applications;
  const _JobRow({required this.job, required this.applications});

  @override
  ConsumerState<_JobRow> createState() => _JobRowState();
}

class _JobRowState extends ConsumerState<_JobRow> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(_jobsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tr('הפעולה נכשלה', 'Failed')}: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _date(DateTime d) {
    final l = d.toLocal();
    return '${l.day}/${l.month}/${l.year}';
  }

  // In the panel's language, which is not the app's (JobStatus.label is).
  static String _statusLabel(JobStatus s) => switch (s) {
    JobStatus.active => tr('פעילה', 'Active'),
    JobStatus.draft => tr('טיוטה', 'Draft'),
    JobStatus.expired => tr('פגה', 'Expired'),
    JobStatus.closed => tr('סגורה', 'Closed'),
  };

  @override
  Widget build(BuildContext context) {
    final k = AdminKit.of(context);
    final j = widget.job;
    final client = SupabaseConfig.client;
    final statusColor = switch (j.status) {
      JobStatus.active => k.success,
      JobStatus.draft => k.warning,
      _ => k.muted,
    };

    return AdminCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 72,
              height: 56,
              child: (j.coverImage ?? j.businessLogo ?? '').isEmpty
                  ? Container(
                      color: k.accentSoft,
                      child: Icon(IconsaxPlusLinear.briefcase, color: k.accent),
                    )
                  : NetworkPhoto(url: (j.coverImage ?? j.businessLogo)!, icon: IconsaxPlusBold.briefcase),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(j.title, style: k.heading),
                    AdminPill(_statusLabel(j.status), statusColor),
                    if (j.isPromoted)
                      AdminPill(
                        tr('מקודמת עד ${_date(j.promotedUntil!)}', 'Promoted until ${_date(j.promotedUntil!)}'),
                        k.accent,
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  [
                    if (j.businessName != null) j.businessName!,
                    
                    if (j.salaryLabel != null) j.salaryLabel!,
                    '${tr('פורסמה', 'Posted')} ${_date(j.shownDate)}',
                    tr('${widget.applications} מועמדויות', '${widget.applications} applications'),
                  ].join(' · '),
                  style: k.hint,
                ),
                if ((j.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(j.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: k.body),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          // A column that stretches needs a width; a row gives it none.
          SizedBox(
            width: 150,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (j.status == JobStatus.active)
                  AdminButton.secondary(
                    label: tr('סגור משרה', 'Close job'),
                    busy: _busy,
                    onPressed: _busy
                        ? null
                        : () => _run(() => client.from('jobs').update({'status': 'closed'}).eq('id', j.id)),
                  )
                else if (j.status != JobStatus.draft)
                  AdminButton.secondary(
                    label: tr('פתח מחדש', 'Reopen'),
                    busy: _busy,
                    onPressed: _busy
                        ? null
                        : () => _run(() => client.from('jobs').update({'status': 'active'}).eq('id', j.id)),
                  ),
                if (j.isPromoted) ...[
                  const SizedBox(height: 8),
                  AdminButton.secondary(
                    label: tr('סיים קידום', 'End promotion'),
                    onPressed: _busy
                        ? null
                        : () => _run(() async {
                            await client.rpc('admin_end_promotion', params: {'p_type': 'job', 'p_id': j.id});
                          }),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
