import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../../shared/widgets/network_photo.dart';
import '../admin_language.dart';
import '../ui/admin_kit.dart';

/// Photographs residents sent for a business page (00071). Each waits here;
/// approved, it joins the business's gallery, where the site and the app
/// already read it, and its sender is told; declined, the sender is told
/// why. Nothing is deleted: an approved one can be taken out of the gallery
/// again (a decline), and a declined one can still be approved.

final _filterProvider = StateProvider.autoDispose<String>((ref) => 'pending');

class _Submission {
  final String id;
  final String businessId;
  final String? businessName;
  final String? senderName;
  final String url;
  final String? caption;
  final String status;
  final String? reason;
  final DateTime createdAt;

  const _Submission({
    required this.id,
    required this.businessId,
    this.businessName,
    this.senderName,
    required this.url,
    this.caption,
    required this.status,
    this.reason,
    required this.createdAt,
  });
}

final _submissionsProvider = FutureProvider.autoDispose<List<_Submission>>((ref) async {
  final status = ref.watch(_filterProvider);
  final client = SupabaseConfig.client;
  // The sender by name: two columns point at profiles (sender and decider),
  // so the join names its key.
  var q = client
      .from('photo_submissions')
      .select('*, sender:profiles!photo_submissions_profile_id_fkey(full_name)');
  if (status != 'all') q = q.eq('status', status);
  final rows = List<Map<String, dynamic>>.from(await q.order('created_at', ascending: false).limit(200));

  // `entity_id` carries no foreign key (it is meant for more than businesses
  // one day), so the names are read on their own.
  final ids = {for (final r in rows) r['entity_id'] as String}.toList();
  final names = <String, String>{};
  if (ids.isNotEmpty) {
    final businesses = await client.from('businesses').select('id, name').inFilter('id', ids);
    for (final b in List<Map<String, dynamic>>.from(businesses)) {
      names[b['id'] as String] = b['name'] as String? ?? '';
    }
  }

  return [
    for (final r in rows)
      _Submission(
        id: r['id'] as String,
        businessId: r['entity_id'] as String,
        businessName: names[r['entity_id']],
        senderName: (r['sender'] as Map?)?['full_name'] as String?,
        url: r['url'] as String,
        caption: r['caption'] as String?,
        status: r['status'] as String? ?? 'pending',
        reason: r['reason'] as String?,
        createdAt: DateTime.tryParse(r['created_at'] as String? ?? '') ?? DateTime.now(),
      ),
  ];
});

class AdminPhotoSubmissionsScreen extends ConsumerWidget {
  const AdminPhotoSubmissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final k = AdminKit.of(context);
    final filter = ref.watch(_filterProvider);
    final submissions = ref.watch(_submissionsProvider);

    // Tapping the filter already chosen reads the list again: new photos
    // arrive while the panel is open.
    void setFilter(String f) {
      ref.read(_filterProvider.notifier).state = f;
      ref.invalidate(_submissionsProvider);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminListToolbar(
          filters: [
            AdminFilterChip(tr('ממתין', 'Pending'), filter == 'pending', () => setFilter('pending')),
            const SizedBox(width: 8),
            AdminFilterChip(tr('אושר', 'Approved'), filter == 'approved', () => setFilter('approved')),
            const SizedBox(width: 8),
            AdminFilterChip(tr('נדחה', 'Declined'), filter == 'declined', () => setFilter('declined')),
            const SizedBox(width: 8),
            AdminFilterChip(tr('הכל', 'All'), filter == 'all', () => setFilter('all')),
          ],
          count: submissions.valueOrNull == null ? null : '${submissions.valueOrNull!.length}',
          actions: [
            AdminToolbarButton(
              label: tr('רענון', 'Refresh'),
              icon: Icons.refresh,
              primary: false,
              onPressed: () => ref.invalidate(_submissionsProvider),
            ),
          ],
        ),
        Expanded(
          child: submissions.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tr('התמונות לא נטענו.', 'The photos did not load.'), style: k.body),
                  const SizedBox(height: 4),
                  Text(
                    '$e'.contains('photo_submissions') ? tr('הרץ את מיגרציה 00071.', 'Run migration 00071.') : '$e',
                    style: k.hint,
                  ),
                  const SizedBox(height: 12),
                  AdminButton.secondary(
                    label: tr('נסה שוב', 'Try again'),
                    onPressed: () => ref.invalidate(_submissionsProvider),
                  ),
                ],
              ),
            ),
            data: (list) => list.isEmpty
                ? Center(child: Text(tr('אין תמונות.', 'No photos.'), style: k.hint))
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: list.length,
                    itemBuilder: (context, i) => _SubmissionCard(submission: list[i]),
                  ),
          ),
        ),
      ],
    );
  }
}

class _SubmissionCard extends ConsumerStatefulWidget {
  final _Submission submission;
  const _SubmissionCard({required this.submission});

  @override
  ConsumerState<_SubmissionCard> createState() => _SubmissionCardState();
}

class _SubmissionCardState extends ConsumerState<_SubmissionCard> {
  bool _busy = false;

  String _date(DateTime d) {
    final l = d.toLocal();
    return '${l.day}/${l.month}/${l.year} ${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }

  /// [approve] false declines — and, for one already approved, takes it out
  /// of the gallery. The reason, if given, is sent to the resident.
  Future<void> _decide(bool approve) async {
    final s = widget.submission;
    String? reason;
    if (!approve) {
      final controller = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => Directionality(
          textDirection: adminDir,
          child: AlertDialog(
            title: Text(
              s.status == 'approved'
                  ? tr('להוציא את התמונה מהגלריה?', 'Remove the photo from the gallery?')
                  : tr('לדחות את התמונה?', 'Decline the photo?'),
            ),
            content: SizedBox(
              width: 420,
              child: TextField(
                controller: controller,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: tr('סיבה (תוצג לשולח/ת, לא חובה)', 'Reason (shown to the sender, optional)'),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('ביטול', 'Cancel'))),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(s.status == 'approved' ? tr('הוצא', 'Remove') : tr('דחה', 'Decline')),
              ),
            ],
          ),
        ),
      );
      if (ok != true) return;
      reason = controller.text.trim();
    }
    setState(() => _busy = true);
    try {
      await SupabaseConfig.client.rpc(
        'admin_decide_photo',
        params: {'p_submission': s.id, 'p_approve': approve, 'p_reason': reason},
      );
      ref.invalidate(_submissionsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tr('הפעולה נכשלה', 'Failed')}: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openFull() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              child: Center(
                child: NetworkPhoto(url: widget.submission.url, fit: BoxFit.contain, icon: IconsaxPlusBold.image),
              ),
            ),
          ),
          PositionedDirectional(
            top: 16,
            end: 16,
            child: IconButton(
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final k = AdminKit.of(context);
    final s = widget.submission;
    final (statusText, statusColor) = switch (s.status) {
      'pending' => (tr('ממתין', 'Pending'), k.warning),
      'approved' => (tr('בגלריה', 'In the gallery'), k.success),
      _ => (tr('נדחה', 'Declined'), k.danger),
    };

    return AdminCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.zoomIn,
            child: GestureDetector(
              onTap: _openFull,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 120,
                  height: 90,
                  child: NetworkPhoto(url: s.url, icon: IconsaxPlusBold.image),
                ),
              ),
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
                    Text(s.businessName ?? '—', style: k.heading),
                    AdminPill(statusText, statusColor),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  [
                    '${tr('נשלח על ידי', 'Sent by')} ${(s.senderName ?? '').trim().isEmpty ? '—' : s.senderName!.trim()}',
                    _date(s.createdAt),
                  ].join(' · '),
                  style: k.hint,
                ),
                if ((s.caption ?? '').isNotEmpty) ...[const SizedBox(height: 8), Text(s.caption!, style: k.body)],
                if (s.status == 'declined' && (s.reason ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('${tr('סיבה', 'Reason')}: ${s.reason}', style: k.hint),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (s.status == 'pending')
            // A column that stretches needs a width; a row gives it none.
            SizedBox(
              width: 150,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AdminButton(
                    label: tr('אשר', 'Approve'),
                    icon: Icons.check,
                    busy: _busy,
                    onPressed: _busy ? null : () => _decide(true),
                  ),
                  const SizedBox(height: 8),
                  AdminButton.secondary(
                    label: tr('דחה', 'Decline'),
                    danger: true,
                    onPressed: _busy ? null : () => _decide(false),
                  ),
                ],
              ),
            )
          else if (s.status == 'approved')
            AdminButton.secondary(
              label: tr('הוצא מהגלריה', 'Remove from gallery'),
              danger: true,
              busy: _busy,
              onPressed: _busy ? null : () => _decide(false),
            )
          else
            AdminButton.secondary(
              label: tr('אשר', 'Approve'),
              icon: Icons.check,
              busy: _busy,
              onPressed: _busy ? null : () => _decide(true),
            ),
        ],
      ),
    );
  }
}
