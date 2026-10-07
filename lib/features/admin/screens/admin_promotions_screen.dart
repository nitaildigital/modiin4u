import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../business_owner/data/owner_data.dart' show PromotionRequest;
import '../admin_language.dart';
import '../ui/admin_kit.dart';

/// Promotion requests from businesses (00069): a business asks to put its
/// page, a deal or a job at the top of its list for some days; the panel
/// approves or declines. Approved, the promotion starts at once (or when one
/// already running ends) and the lists put it first until it ends; the
/// business is told either way. Payment is outside the system — the client
/// collects it himself.

final _filterProvider = StateProvider.autoDispose<String>((ref) => 'pending');

final _requestsProvider = FutureProvider.autoDispose<List<PromotionRequest>>((ref) async {
  final status = ref.watch(_filterProvider);
  final client = SupabaseConfig.client;
  var q = client.from('promotion_requests').select('*, businesses(name)');
  if (status != 'all') q = q.eq('status', status);
  final rows = await q.order('created_at', ascending: false).limit(200);
  final list = List<Map<String, dynamic>>.from(rows).map(PromotionRequest.fromJson).toList();
  // What each one is for: a title and a picture, from the business, deal or
  // job itself.
  return Future.wait(
    list.map((r) async {
      try {
        final t = await client.rpc('promotion_target', params: {'p_type': r.entityType, 'p_id': r.entityId});
        final first = List<Map<String, dynamic>>.from(t as List).firstOrNull;
        return r.withTarget(first?['title'] as String?, first?['image_url'] as String?);
      } catch (_) {
        return r;
      }
    }),
  );
});

class AdminPromotionsScreen extends ConsumerWidget {
  const AdminPromotionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final k = AdminKit.of(context);
    final filter = ref.watch(_filterProvider);
    final requests = ref.watch(_requestsProvider);

    // Tapping the filter already chosen reads the list again: new requests
    // arrive while the panel is open.
    void setFilter(String f) {
      ref.read(_filterProvider.notifier).state = f;
      ref.invalidate(_requestsProvider);
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
          count: requests.valueOrNull == null ? null : '${requests.valueOrNull!.length}',
          actions: [
            AdminToolbarButton(
              label: tr('רענון', 'Refresh'),
              icon: Icons.refresh,
              primary: false,
              onPressed: () => ref.invalidate(_requestsProvider),
            ),
          ],
        ),
        Expanded(
          child: requests.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tr('הקידומים לא נטענו.', 'Promotions did not load.'), style: k.body),
                  const SizedBox(height: 4),
                  Text(
                    '$e'.contains('promotion_requests') ? tr('הרץ את מיגרציה 00069.', 'Run migration 00069.') : '$e',
                    style: k.hint,
                  ),
                  const SizedBox(height: 12),
                  AdminButton.secondary(
                    label: tr('נסה שוב', 'Try again'),
                    onPressed: () => ref.invalidate(_requestsProvider),
                  ),
                ],
              ),
            ),
            data: (list) => list.isEmpty
                ? Center(child: Text(tr('אין בקשות.', 'No requests.'), style: k.hint))
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: list.length,
                    itemBuilder: (context, i) => _RequestCard(request: list[i]),
                  ),
          ),
        ),
      ],
    );
  }
}

class _RequestCard extends ConsumerStatefulWidget {
  final PromotionRequest request;
  const _RequestCard({required this.request});

  @override
  ConsumerState<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<_RequestCard> {
  bool _busy = false;

  String get _kind => switch (widget.request.entityType) {
    'business' => tr('עסק', 'Business'),
    'offer' => tr('מבצע', 'Deal'),
    _ => tr('משרה', 'Job'),
  };

  String _date(DateTime d) {
    final l = d.toLocal();
    return '${l.day}/${l.month}/${l.year} ${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _decide(bool approve) async {
    String? reason;
    if (!approve) {
      final controller = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => Directionality(
          textDirection: adminDir,
          child: AlertDialog(
            title: Text(tr('לדחות את הבקשה?', 'Decline the request?')),
            content: SizedBox(
              width: 420,
              child: TextField(
                controller: controller,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: tr('סיבה (תוצג לעסק, לא חובה)', 'Reason (shown to the business, optional)'),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('ביטול', 'Cancel'))),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('דחה', 'Decline'))),
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
        'admin_decide_promotion',
        params: {'p_request': widget.request.id, 'p_approve': approve, 'p_reason': reason},
      );
      ref.invalidate(_requestsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tr('הפעולה נכשלה', 'Failed')}: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _endNow() async {
    setState(() => _busy = true);
    try {
      await SupabaseConfig.client.rpc(
        'admin_end_promotion',
        params: {'p_type': widget.request.entityType, 'p_id': widget.request.entityId},
      );
      ref.invalidate(_requestsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tr('הפעולה נכשלה', 'Failed')}: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final k = AdminKit.of(context);
    final r = widget.request;
    final running = r.status == 'approved' && r.endsAt != null && r.endsAt!.isAfter(DateTime.now());
    final (statusText, statusColor) = switch (r.status) {
      'pending' => (tr('ממתין', 'Pending'), k.warning),
      'approved' =>
        running
            ? (tr('פעיל עד ${_date(r.endsAt!)}', 'Running until ${_date(r.endsAt!)}'), k.success)
            : (tr('הסתיים', 'Ended'), k.muted),
      'declined' => (tr('נדחה', 'Declined'), k.danger),
      _ => (tr('בוטל', 'Cancelled'), k.muted),
    };

    return AdminCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 88,
              height: 66,
              child: (r.imageUrl ?? '').isEmpty
                  ? Container(
                      color: k.accentSoft,
                      child: Icon(IconsaxPlusLinear.image, color: k.accent),
                    )
                  : NetworkPhoto(url: r.imageUrl!, icon: IconsaxPlusBold.image),
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
                    Text(r.title ?? '—', style: k.heading),
                    AdminPill(_kind, k.accent),
                    AdminPill(statusText, statusColor),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  [
                    if (r.businessName != null) r.businessName!,
                    tr('${r.days} ימים', '${r.days} days'),
                    '${tr('התבקש', 'Requested')} ${_date(r.createdAt)}',
                  ].join(' · '),
                  style: k.hint,
                ),
                if ((r.message ?? '').isNotEmpty) ...[const SizedBox(height: 8), Text(r.message!, style: k.body)],
                if (r.status == 'declined' && (r.reason ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('${tr('סיבה', 'Reason')}: ${r.reason}', style: k.hint),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (r.status == 'pending')
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
          else if (running)
            AdminButton.secondary(label: tr('סיים עכשיו', 'End now'), busy: _busy, onPressed: _busy ? null : _endNow),
        ],
      ),
    );
  }
}
