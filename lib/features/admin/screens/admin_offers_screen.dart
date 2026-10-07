import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../deals/models/offer.dart' show offerBadge;
import '../../../core/supabase/supabase_config.dart';
import '../providers/admin_offers_provider.dart';
import '../providers/admin_table_notifier.dart' show recordAdminAction;
import '../widgets/admin_events_form_fields.dart';
import '../widgets/image_upload_field.dart';
import '../widgets/admin_load_error.dart';
import '../admin_language.dart';
import '../ui/admin_kit.dart';

class AdminOffersScreen extends ConsumerStatefulWidget {
  const AdminOffersScreen({super.key});

  @override
  ConsumerState<AdminOffersScreen> createState() => _AdminOffersScreenState();
}

class _AdminOffersScreenState extends ConsumerState<AdminOffersScreen> {
  String _statusFilter = '';
  final _searchController = TextEditingController();
  final _debouncer = _Debouncer(milliseconds: 400);

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.cancel();
    super.dispose();
  }

  void _filter(String status) {
    setState(() => _statusFilter = status);
    ref
        .read(adminOfferListProvider.notifier)
        .setStatusFilter(status.isEmpty ? null : status);
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(adminOfferListProvider);
    final isWide = MediaQuery.of(context).size.width > 900;

    return Column(
      children: [
        // ─── Stats bar ───
        // `valueOrNull`, not `whenData(...).value`: the latter rethrows on a
        // failed load and greys the whole section instead of letting the
        // table below show the error and a retry.
        if (asyncData.valueOrNull case final list?)
          Builder(
            builder: (context) {
              final active = list.where((o) => o['status'] == 'active').length;
              final totalClaims = list.fold<int>(
                0,
                (s, o) => s + ((o['claim_count'] as num?)?.toInt() ?? 0),
              );
              final totalUsed = list.fold<int>(
                0,
                (s, o) => s + ((o['redeem_count'] as num?)?.toInt() ?? 0),
              );
              final featured = list
                  .where((o) => o['is_featured'] == true)
                  .length;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.border.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    _StatChip(tr('מבצעים פעילים', 'Active deals'), '$active', AppColors.success),
                    const SizedBox(width: 16),
                    // "מימושים" counted claims; claimed and used are two
                    // numbers now that a voucher can be used (00056).
                    _StatChip(
                      tr('סה״כ נלקחו', 'Total claimed'),
                      '$totalClaims',
                      AppColors.midBlue,
                    ),
                    const SizedBox(width: 16),
                    _StatChip(
                      tr('סה״כ מומשו', 'Total used'),
                      '$totalUsed',
                      AppColors.success,
                    ),
                    const SizedBox(width: 16),
                    _StatChip(tr('מומלצים', 'Recommended'), '$featured', AppColors.gold),
                    const SizedBox(width: 16),
                    _StatChip(tr('סה״כ מבצעים', 'Total deals'), '${list.length}', AppColors.navy),
                  ],
                ),
              );
            },
          ),

        AdminListToolbar(
          search: AdminSearchField(
            controller: _searchController,
            width: isWide ? 280 : 180,
            hint: tr('חיפוש מבצע...', 'Search deals...'),
            onChanged: (v) => _debouncer.run(() {
              ref
                  .read(adminOfferListProvider.notifier)
                  .setSearch(v.isEmpty ? null : v);
            }),
          ),
          // The four values of `offer_status`. "Scheduled" and "paused"
          // were offered here too; the table has neither.
          filters: [
            AdminFilterChip(tr('הכל', 'All'), _statusFilter.isEmpty, () => _filter('')),
            AdminFilterChip(
              tr('פעיל', 'Active'),
              _statusFilter == 'active',
              () => _filter('active'),
            ),
            AdminFilterChip(
              tr('טיוטה', 'Draft'),
              _statusFilter == 'draft',
              () => _filter('draft'),
            ),
            AdminFilterChip(
              tr('פג תוקף', 'Expired'),
              _statusFilter == 'expired',
              () => _filter('expired'),
            ),
            AdminFilterChip(
              tr('אזל', 'Sold out'),
              _statusFilter == 'redeemed_out',
              () => _filter('redeemed_out'),
            ),
          ],
          count: switch (asyncData.valueOrNull) {
            final list? => tr('${list.length} מבצעים', '${list.length} deals'),
            null => null,
          },
          actions: [
            AdminToolbarButton(
              label: tr('מבצע חדש', 'New deal'),
              onPressed: () => _showEditor(context),
            ),
          ],
        ),

        // ─── Table ───
        Expanded(
          child: asyncData.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => AdminLoadError(
              message: tr('שגיאה בטעינת המבצעים', 'Error loading the deals'),
              error: e,
              onRetry: () => ref.read(adminOfferListProvider.notifier).load(),
            ),
            data: (list) {
              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_offer_outlined,
                        size: 48,
                        color: AppColors.grayLight.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        tr('אין מבצעים', 'No deals'),
                        style: TextStyle(
                          fontFamily: AppFonts.rubik,
                          color: AppColors.grayText,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.border.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        _Col(tr('מבצע', 'Deal'), flex: 3),
                        _Col(tr('עסק', 'Business'), flex: 2),
                        if (isWide) _Col(tr('תגית באתר', 'Tag on the site'), flex: 1),
                        if (isWide) _Col(tr('נלקחו · מומשו', 'Claimed · used'), flex: 1),
                        if (isWide) _Col(tr('בתוקף עד', 'Valid until'), flex: 1),
                        _Col(tr('סטטוס', 'Status'), flex: 1),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: AppColors.border.withValues(alpha: 0.3),
                      ),
                      itemBuilder: (_, i) {
                        final o = list[i];
                        final status = o['status'] as String? ?? 'draft';
                        final name = o['name'] as String? ?? '';
                        final biz = o['businesses'];
                        final bizName = biz is Map
                            ? biz['name'] as String? ?? ''
                            : '';
                        final claims = (o['claim_count'] as num?)?.toInt() ?? 0;
                        final used = (o['redeem_count'] as num?)?.toInt() ?? 0;
                        final maxClaims = (o['max_claims'] as num?)?.toInt();
                        final isFeatured = o['is_featured'] as bool? ?? false;
                        final residentsOnly = o['audience'] == 'verified';
                        final endAt = DateTime.tryParse(
                          o['end_at'] as String? ?? '',
                        )?.toLocal();

                        return InkWell(
                          onTap: () => _showEditor(context, offer: o),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Row(
                                    children: [
                                      if (isFeatured)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 6,
                                          ),
                                          child: Icon(
                                            Icons.star,
                                            size: 16,
                                            color: AppColors.gold,
                                          ),
                                        ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: TextStyle(
                                                fontFamily: AppFonts.rubik,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.navy,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              [
                                                if (residentsOnly)
                                                  tr('לתושבים בלבד', 'Residents only'),
                                                if ((o['code'] as String? ?? '')
                                                    .isNotEmpty)
                                                  tr('קוד ${o['code']}', 'Code ${o['code']}'),
                                                if ((o['description']
                                                            as String? ??
                                                        '')
                                                    .isNotEmpty)
                                                  o['description'] as String,
                                              ].join(' · '),
                                              style: TextStyle(
                                                fontFamily: AppFonts.rubik,
                                                fontSize: 11,
                                                color: AppColors.grayLight,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    bizName,
                                    style: TextStyle(
                                      fontFamily: AppFonts.rubik,
                                      fontSize: 13,
                                      color: AppColors.grayText,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isWide)
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      offerBadge(name) ?? '—',
                                      style: TextStyle(
                                        fontFamily: AppFonts.rubik,
                                        fontSize: 12,
                                        color: AppColors.orange,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                if (isWide)
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      '${maxClaims != null ? '$claims / $maxClaims' : '$claims'} · $used',
                                      style: TextStyle(
                                        fontFamily: AppFonts.rubik,
                                        fontSize: 13,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (isWide)
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      endAt == null
                                          ? tr('ללא', 'None')
                                          : '${formatAdminDate(endAt)} '
                                                '${formatAdminTime(endAt.hour, endAt.minute)}',
                                      textDirection: TextDirection.ltr,
                                      textAlign: adminEnglish.value
                                          ? TextAlign.left
                                          : TextAlign.right,
                                      style: TextStyle(
                                        fontFamily: AppFonts.rubik,
                                        fontSize: 12,
                                        color:
                                            endAt != null &&
                                                endAt.isBefore(DateTime.now())
                                            ? AppColors.error
                                            : AppColors.grayText,
                                      ),
                                    ),
                                  ),
                                Expanded(flex: 1, child: _StatusPill(status)),
                                PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.more_vert,
                                    size: 18,
                                    color: AppColors.grayLight,
                                  ),
                                  onSelected: (v) => _handleAction(v, o),
                                  itemBuilder: (_) => [
                                    _menuItem('edit', tr('עריכה', 'Edit')),
                                    _menuItem('claims', tr('שוברים שנלקחו', 'Claimed vouchers')),
                                    if (status != 'active')
                                      _menuItem('activate', tr('הפעל', 'Activate')),
                                    // One item: "end" and "delete" both set
                                    // status = 'expired' — the row is never
                                    // removed, and "הפעל" brings it back.
                                    if (status != 'expired')
                                      _menuItem(
                                        'expire',
                                        tr('סיים מבצע', 'End deal'),
                                        color: AppColors.error,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(String value, String label, {Color? color}) {
    return PopupMenuItem(
      value: value,
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppFonts.rubik,
          fontSize: 13,
          color: color,
        ),
      ),
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('הפעולה נכשלה: $e', 'The action failed: $e')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _handleAction(String action, Map<String, dynamic> o) {
    final notifier = ref.read(adminOfferListProvider.notifier);
    final id = o['id'] as String;
    switch (action) {
      case 'edit':
        _showEditor(context, offer: o);
      case 'activate':
        _run(() => notifier.updateStatus(id, 'active'));
      case 'claims':
        // The claimed and used counts change in the dialog; the row and the
        // totals behind it read again once it closes.
        showDialog<void>(
          context: context,
          builder: (_) => _ClaimsDialog(offerId: id, offerName: o['name'] as String? ?? ''),
        ).then((_) => notifier.load());
      case 'expire':
        _confirmEnd(id, o['name'] as String? ?? '');
    }
  }

  /// Ending took effect on the tap, with nothing to stop a slip; it is
  /// undone with "הפעל", but by then residents have lost the deal.
  Future<void> _confirmEnd(String id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('לסיים את המבצע?', 'End this deal?')),
        content: Text(tr(
          '"$name" יוסר מהאתר ומהאפליקציה. אפשר להפעיל אותו שוב מאוחר יותר.',
          '"$name" leaves the site and the app. It can be activated again later.',
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('ביטול', 'Cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('סיום מבצע', 'End deal'), style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true) _run(() => ref.read(adminOfferListProvider.notifier).deleteOffer(id));
  }

  void _showEditor(BuildContext context, {Map<String, dynamic>? offer}) {
    AdminEditorPage.open<void>(context, _OfferEditorDialog(offer: offer));
  }
}

// ─── Editor ───

class _OfferEditorDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? offer;
  const _OfferEditorDialog({this.offer});

  @override
  ConsumerState<_OfferEditorDialog> createState() => _OfferEditorDialogState();
}

class _OfferEditorDialogState extends ConsumerState<_OfferEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  String? _error;

  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _terms;
  late final TextEditingController _image;
  late final TextEditingController _code;
  late final TextEditingController _maxClaims;
  late final TextEditingController _maxPerUser;
  late final TextEditingController _points;
  late final TextEditingController _startDate;
  late final TextEditingController _startTime;
  late final TextEditingController _endDate;
  late final TextEditingController _endTime;
  String? _businessId;
  String? _businessName;
  String _status = 'draft';
  String _audience = 'all';
  bool _isFeatured = false;
  /// "Send a notification when it goes live" (00060): on for a new deal, off
  /// for one from before; clearing it in the five minutes cancels it.
  bool _notify = true;

  bool get _isEditing => widget.offer != null;

  static Map<String, String> get _statuses => {
    'draft': tr('טיוטה', 'Draft'),
    'active': tr('פעיל', 'Active'),
    'expired': tr('פג תוקף', 'Expired'),
    'redeemed_out': tr('אזל', 'Sold out'),
  };

  /// `audience` per migration 00007. The website marks `verified` as
  /// "Residents Only".
  static Map<String, String> get _audiences => {
    'all': tr('כולם', 'Everyone'),
    'verified': tr('תושבים מאומתים בלבד', 'Verified residents only'),
    'new_users': tr('משתמשים חדשים', 'New users'),
  };

  @override
  void initState() {
    super.initState();
    final o = widget.offer;
    String text(String key) => (o?[key] as String?) ?? '';
    String number(String key, {String fallback = ''}) =>
        (o?[key] as num?)?.toInt().toString() ?? fallback;

    // Stored in UTC; edited in the admin's own clock.
    final start = DateTime.tryParse(text('start_at'))?.toLocal();
    final end = DateTime.tryParse(text('end_at'))?.toLocal();

    _name = TextEditingController(text: text('name'));
    _description = TextEditingController(text: text('description'));
    _terms = TextEditingController(text: text('terms'));
    _image = TextEditingController(text: text('image_url'));
    _code = TextEditingController(text: text('code'));
    _maxClaims = TextEditingController(text: number('max_claims'));
    _maxPerUser = TextEditingController(
      text: number('max_per_user', fallback: '1'),
    );
    _points = TextEditingController(
      text: number('points_required', fallback: '0'),
    );
    _startDate = TextEditingController(
      text: start == null ? '' : formatAdminDate(start),
    );
    _startTime = TextEditingController(
      text: start == null ? '' : formatAdminTime(start.hour, start.minute),
    );
    _endDate = TextEditingController(
      text: end == null ? '' : formatAdminDate(end),
    );
    _endTime = TextEditingController(
      text: end == null ? '' : formatAdminTime(end.hour, end.minute),
    );

    _businessId = o?['business_id'] as String?;
    final biz = o?['businesses'];
    _businessName = biz is Map ? biz['name'] as String? : null;
    _status = o?['status'] as String? ?? 'draft';
    if (!_statuses.containsKey(_status)) _status = 'draft';
    _audience = o?['audience'] as String? ?? 'all';
    if (!_audiences.containsKey(_audience)) _audience = 'all';
    _isFeatured = o?['is_featured'] as bool? ?? false;
    _notify = o == null || (o['notify_on_publish'] as bool? ?? false);
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _description,
      _terms,
      _image,
      _code,
      _maxClaims,
      _maxPerUser,
      _points,
      _startDate,
      _startTime,
      _endDate,
      _endTime,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final k = AdminKit.of(context);
    return Form(
      key: _formKey,
      child: AdminEditorPage(
        title: _isEditing ? tr('עריכת מבצע', 'Edit deal') : tr('מבצע חדש', 'New deal'),
        status: _isEditing ? _StatusPill(_status) : null,
        onClose: () => Navigator.pop(context),
        actions: [
          AdminButton.secondary(
            label: tr('ביטול', 'Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          AdminButton(
            label: _isEditing ? tr('עדכון', 'Update') : tr('יצירה', 'Create'),
            icon: Icons.check,
            busy: _saving,
            onPressed: _saving ? null : _save,
          ),
        ],
        main: [
          if (_error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: k.danger.withValues(alpha: 0.06),
                border: Border.all(color: k.danger.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(k.radius),
              ),
              child: Text(_error!, style: k.body.copyWith(color: k.danger)),
            ),
          AdminCard(
            title: tr('פרטי המבצע', 'Deal details'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AdminField(
                  label: tr('שם המבצע *', 'Deal name *'),
                  controller: _name,
                  hint: tr('20% הנחה על כל הפיצות', '20% off all pizzas'),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? tr('שדה חובה', 'Required field') : null,
                ),
                _BadgeHint(controller: _name),
                const SizedBox(height: 16),
                _labelled(
                  tr('תיאור', 'Description'),
                  TextFormField(
                    controller: _description,
                    minLines: 3,
                    maxLines: null,
                    style: k.body,
                    decoration: k.input(hint: tr('פירוט המבצע...', 'Deal details...')),
                  ),
                ),
                _labelled(
                  tr('תנאים', 'Terms'),
                  TextFormField(
                    controller: _terms,
                    minLines: 3,
                    maxLines: null,
                    style: k.body,
                    decoration: k.input(hint: tr('תנאים והגבלות...', 'Terms and conditions...')),
                  ),
                ),
              ],
            ),
          ),
          AdminCard(
            title: tr('מימוש', 'Redemption'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AdminField(
                        label: tr('קוד קופון', 'Coupon code'),
                        controller: _code,
                        hint: 'PIZZA20',
                        textDirection: TextDirection.ltr,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AdminField(
                        label: tr('מקסימום מימושים', 'Maximum redemptions'),
                        controller: _maxClaims,
                        hint: tr('ללא הגבלה', 'No limit'),
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            _wholeNumber(v, min: 1, required: false),
                      ),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AdminField(
                        label: tr('מימושים לכל משתמש', 'Redemptions per user'),
                        controller: _maxPerUser,
                        hint: '1',
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            _wholeNumber(v, min: 1, required: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AdminField(
                        label: tr('נקודות נדרשות', 'Points required'),
                        controller: _points,
                        hint: '0',
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            _wholeNumber(v, min: 0, required: true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AdminCard(
            title: tr('מועדים', 'Dates'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _labelled(
                        tr('תחילת מבצע', 'Deal start'),
                        AdminDateField(
                          controller: _startDate,
                          decoration: k.input(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _labelled(
                        tr('שעה', 'Time'),
                        AdminTimeField(
                          controller: _startTime,
                          decoration: k.input(hint: '00:00'),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _labelled(
                        tr('סיום מבצע', 'End deal'),
                        AdminDateField(
                          controller: _endDate,
                          decoration: k.input(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _labelled(
                        tr('שעה', 'Time'),
                        AdminTimeField(
                          controller: _endTime,
                          decoration: k.input(hint: '23:59'),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  tr('בלי תאריך סיום לא יוצג באתר שעון ספירה לאחור.', 'Without an end date, no countdown is shown on the site.'),
                  style: k.hint.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
        side: [
          AdminCard(
            title: tr('פרסום', 'Publishing'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDropdown(
                  tr('סטטוס', 'Status'),
                  _status,
                  _statuses,
                  (v) => setState(() => _status = v!),
                ),
                _buildDropdown(
                  tr('קהל', 'Audience'),
                  _audience,
                  _audiences,
                  (v) => setState(() => _audience = v!),
                ),
                Text(
                  tr('תושבים מאומתים בלבד — מסומן באתר "לתושבים בלבד". '
                  'רק מבצע בסטטוס "פעיל" מוצג באתר.', 'Verified residents only — marked "Residents only" on the site. Only a deal with the status "Active" is shown on the site.'),
                  style: k.hint.copyWith(fontSize: 12),
                ),
                const SizedBox(height: 8),
                AdminSwitchRow(
                  label: tr('מומלץ', 'Recommended'),
                  value: _isFeatured,
                  onChanged: (v) => setState(() => _isFeatured = v),
                ),
                AdminSwitchRow(
                  label: tr('לשלוח התראה כשהמבצע עולה', 'Send a notification when it goes live'),
                  value: _notify,
                  onChanged: (v) => setState(() => _notify = v),
                ),
              ],
            ),
          ),
          AdminCard(
            title: tr('עסק *', 'Business *'),
            child: AdminBusinessPickerField(
              label: '',
              businessId: _businessId,
              fallbackName: _businessName,
              required: true,
              onChanged: (b) => setState(() {
                _businessId = b?.id;
                _businessName = b?.name;
              }),
            ),
          ),
          // The upload field has its own heading.
          AdminCard(
            child: ImageUploadField(
              label: tr('תמונה', 'Image'),
              controller: _image,
              folder: 'offers',
            ),
          ),
        ],
      ),
    );
  }

  /// A label above a field, as [AdminField] lays it out, for the fields it
  /// does not cover (dates, times, choices, longer text).
  Widget _labelled(String label, Widget field) {
    final k = AdminKit.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: k.label),
          const SizedBox(height: 6),
          field,
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    Map<String, String> items,
    ValueChanged<String?> onChanged,
  ) {
    final k = AdminKit.of(context);
    return _labelled(
      label,
      DropdownButtonFormField<String>(
        initialValue: value,
        style: k.body,
        items: items.entries
            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
            .toList(),
        onChanged: onChanged,
        decoration: k.input(),
      ),
    );
  }

  String? _wholeNumber(String? v, {required int min, required bool required}) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return required ? tr('שדה חובה', 'Required field') : null;
    final n = int.tryParse(t);
    return n == null || n < min ? tr('מספר שלם, $min ומעלה', 'A whole number, $min or more') : null;
  }

  /// A date and a time from the form, as a UTC timestamp. A missing time is
  /// the start of the day for an opening and its last minute for a close.
  String? _timestamp(
    TextEditingController date,
    TextEditingController time, {
    required bool endOfDay,
  }) {
    final d = parseAdminDate(date.text);
    if (d == null) return null;
    final t =
        parseAdminTime(time.text) ??
        (endOfDay ? (hour: 23, minute: 59) : (hour: 0, minute: 0));
    return DateTime(
      d.year,
      d.month,
      d.day,
      t.hour,
      t.minute,
    ).toUtc().toIso8601String();
  }

  /// Said at the top of the page and in a message at the bottom, since the
  /// page may be scrolled far from the top when Save is pressed.
  void _fail(String message) {
    setState(() => _error = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) {
      _fail(tr('יש שדות שצריך לתקן — הם מסומנים באדום.', 'Some fields need correcting — they are marked in red.'));
      return;
    }

    String? nullIfEmpty(TextEditingController c) {
      final t = c.text.trim();
      return t.isEmpty ? null : t;
    }

    final startAt = _timestamp(_startDate, _startTime, endOfDay: false);
    final endAt = _timestamp(_endDate, _endTime, endOfDay: true);
    if (startAt != null &&
        endAt != null &&
        !DateTime.parse(endAt).isAfter(DateTime.parse(startAt))) {
      _fail(tr('סיום המבצע חייב להיות אחרי תחילתו', 'The deal\'s end must be after its start'));
      return;
    }

    final data = <String, dynamic>{
      'name': _name.text.trim(),
      'business_id': _businessId,
      'description': nullIfEmpty(_description),
      'terms': nullIfEmpty(_terms),
      'image_url': nullIfEmpty(_image),
      'code': nullIfEmpty(_code),
      'max_claims': int.tryParse(_maxClaims.text.trim()),
      'max_per_user': int.tryParse(_maxPerUser.text.trim()) ?? 1,
      'points_required': int.tryParse(_points.text.trim()) ?? 0,
      'start_at': startAt,
      'end_at': endAt,
      'audience': _audience,
      'status': _status,
      'is_featured': _isFeatured,
      'notify_on_publish': _notify,
    };

    setState(() => _saving = true);
    final notifier = ref.read(adminOfferListProvider.notifier);
    try {
      if (_isEditing) {
        await notifier.updateOffer(widget.offer!['id'] as String, data);
      } else {
        await notifier.createOffer(data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) _fail(tr('שגיאה: $e', 'Error: $e'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

/// Says what the website will put on the card's corner, as the name is typed.
///
/// `offers` has no discount column; the site reads the badge out of the name
/// (see [offerBadge]). Showing the result here is the only way the person
/// entering the offer can know that "20% הנחה" in the name becomes the badge
/// and "מבצע מיוחד" becomes none.
class _BadgeHint extends StatelessWidget {
  final TextEditingController controller;
  const _BadgeHint({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (_, value, _) {
        final badge = offerBadge(value.text);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('ההנחה שכתובה בשם ("20% הנחה", "1+1", "₪50 הנחה", "מתנה") '
              'הופכת לתגית על כרטיס המבצע באתר.', 'The discount written in the name ("20% off", "1+1", "₪50 off", "gift") becomes a tag on the deal card on the site.'),
              style: TextStyle(
                fontFamily: AppFonts.rubik,
                fontSize: 11,
                color: AppColors.grayLight,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  tr('תגית: ', 'Tag: '),
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 11,
                    color: AppColors.grayText,
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontFamily: AppFonts.rubik,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  )
                else
                  Text(
                    tr('אין — השם לא מציין הנחה', 'None — the name does not mention a discount'),
                    style: TextStyle(
                      fontFamily: AppFonts.rubik,
                      fontSize: 11,
                      color: AppColors.grayLight,
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ─── Helper Widgets ───

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontSize: 12,
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _Col extends StatelessWidget {
  final String label;
  final int flex;
  const _Col(this.label, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppFonts.rubik,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.grayText,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill(this.status);

  @override
  Widget build(BuildContext context) {
    final k = AdminKit.of(context);
    final (label, color) = switch (status) {
      'active' => (tr('פעיל', 'Active'), k.success),
      'expired' => (tr('פג תוקף', 'Expired'), k.danger),
      'redeemed_out' => (tr('אזל', 'Sold out'), k.warning),
      'draft' => (tr('טיוטה', 'Draft'), k.muted),
      _ => (status, k.inkSoft),
    };
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: AdminPill(label, color),
    );
  }
}

/// Runs the search once typing pauses. The previous one queued a query for
/// every keystroke and never cancelled any of them.
class _Debouncer {
  final int milliseconds;
  _Debouncer({required this.milliseconds});
  Timer? _timer;
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void cancel() => _timer?.cancel();
}

/// The vouchers taken for one deal: who, their code, when, and whether it was
/// used. The office can mark one used (a business that phoned it in) or undo
/// a slip; the counts follow (00049).
class _ClaimsDialog extends StatefulWidget {
  final String offerId;
  final String offerName;
  const _ClaimsDialog({required this.offerId, required this.offerName});

  @override
  State<_ClaimsDialog> createState() => _ClaimsDialogState();
}

class _ClaimsDialogState extends State<_ClaimsDialog> {
  late Future<List<Map<String, dynamic>>> _rows = _load();

  Future<List<Map<String, dynamic>>> _load() async {
    final rows = await SupabaseConfig.client
        .from('offer_claims')
        .select('*, profiles(full_name, phone)')
        .eq('offer_id', widget.offerId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> _setUsed(Map<String, dynamic> c, bool used) async {
    final id = c['id'] as String;
    final fields = {
      'redeemed': used,
      'redeemed_at': used ? DateTime.now().toUtc().toIso8601String() : null,
    };
    try {
      await SupabaseConfig.client.from('offer_claims').update(fields).eq('id', id);
      await recordAdminAction(
        // `audit_action` has no "redeem"; the fields say which way.
        action: 'update',
        table: 'offer_claims',
        rowId: id,
        fields: fields,
        label: widget.offerName,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('השמירה נכשלה', 'Could not save'))),
        );
      }
    }
    if (mounted) setState(() => _rows = _load());
  }

  String _when(String? iso) {
    final d = DateTime.tryParse(iso ?? '')?.toLocal();
    if (d == null) return '—';
    return '${formatAdminDate(d)} ${formatAdminTime(d.hour, d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    TextStyle cell([Color? c, FontWeight? w]) =>
        TextStyle(fontFamily: AppFonts.rubik, fontSize: 13, color: c, fontWeight: w);
    return Dialog(
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${tr('שוברים', 'Vouchers')} — ${widget.offerName}',
                      style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _rows,
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return Center(child: Text(tr('לא ניתן לטעון', 'Could not load'), style: cell()));
                    }
                    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                    final rows = snap.data!;
                    if (rows.isEmpty) {
                      return Center(child: Text(tr('אף אחד עוד לא לקח את המבצע', 'Nobody has claimed this deal yet'), style: cell(AppColors.grayText)));
                    }
                    return ListView.separated(
                      itemCount: rows.length,
                      separatorBuilder: (_, _) => Divider(height: 1, color: AppColors.border.withValues(alpha: 0.4)),
                      itemBuilder: (_, i) {
                        final c = rows[i];
                        final p = c['profiles'] is Map ? c['profiles'] as Map : const {};
                        final used = c['redeemed'] == true;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text((p['full_name'] as String?) ?? tr('חשבון שנמחק', 'Deleted account'), style: cell(null, FontWeight.w600)),
                                    if ((p['phone'] as String? ?? '').isNotEmpty)
                                      Text(p['phone'] as String, textDirection: TextDirection.ltr, style: cell(AppColors.grayText)),
                                  ],
                                ),
                              ),
                              Expanded(flex: 2, child: Text((c['code'] as String?) ?? '—', style: cell(AppColors.navy, FontWeight.w700))),
                              Expanded(flex: 3, child: Text('${tr('נלקח', 'Claimed')} ${_when(c['created_at'] as String?)}', style: cell(AppColors.grayText))),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  used ? '${tr('מומש', 'Used')} ${_when(c['redeemed_at'] as String?)}' : tr('טרם מומש', 'Not used yet'),
                                  style: cell(used ? AppColors.success : AppColors.grayText, used ? FontWeight.w600 : null),
                                ),
                              ),
                              TextButton(
                                onPressed: () => _setUsed(c, !used),
                                child: Text(used ? tr('ביטול מימוש', 'Undo') : tr('סימון כמומש', 'Mark used'), style: cell(used ? AppColors.error : AppColors.midBlue)),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
