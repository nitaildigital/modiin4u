import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../deals/models/offer.dart' show offerBadge;
import '../providers/admin_offers_provider.dart';
import '../widgets/admin_events_form_fields.dart';
import '../widgets/image_upload_field.dart';
import '../widgets/admin_load_error.dart';
import '../admin_language.dart';

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
                    _StatChip(
                      tr('סה״כ מימושים', 'Total redemptions'),
                      '$totalClaims',
                      AppColors.turquoise,
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

        // ─── Toolbar ───
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
              SizedBox(
                width: isWide ? 280 : 180,
                height: 40,
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: tr('חיפוש מבצע...', 'Search deals...'),
                    hintStyle: TextStyle(
                      fontFamily: AppFonts.rubik,
                      fontSize: 13,
                      color: AppColors.grayLight,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 18,
                      color: AppColors.grayLight,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.turquoise),
                    ),
                  ),
                  onChanged: (v) => _debouncer.run(() {
                    ref
                        .read(adminOfferListProvider.notifier)
                        .setSearch(v.isEmpty ? null : v);
                  }),
                ),
              ),
              const SizedBox(width: 12),
              // The four values of `offer_status`. "Scheduled" and "paused"
              // were offered here too; the table has neither.
              _FilterChip(tr('הכל', 'All'), _statusFilter.isEmpty, () => _filter('')),
              _FilterChip(
                tr('פעיל', 'Active'),
                _statusFilter == 'active',
                () => _filter('active'),
              ),
              _FilterChip(
                tr('טיוטה', 'Draft'),
                _statusFilter == 'draft',
                () => _filter('draft'),
              ),
              _FilterChip(
                tr('פג תוקף', 'Expired'),
                _statusFilter == 'expired',
                () => _filter('expired'),
              ),
              _FilterChip(
                tr('אזל', 'Sold out'),
                _statusFilter == 'redeemed_out',
                () => _filter('redeemed_out'),
              ),
              const Spacer(),
              if (asyncData.valueOrNull case final list?)
                Text(
                  tr('${list.length} מבצעים', '${list.length} deals'),
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 13,
                    color: AppColors.grayText,
                  ),
                ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: () => _showEditor(context),
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  tr('מבצע חדש', 'New deal'),
                  style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.turquoise,
                  minimumSize: const Size(0, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
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
                        if (isWide) _Col(tr('מימושים', 'Redemptions'), flex: 1),
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
                                      maxClaims != null
                                          ? '$claims / $maxClaims'
                                          : '$claims',
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
      case 'expire':
        _run(() => notifier.deleteOffer(id));
    }
  }

  void _showEditor(BuildContext context, {Map<String, dynamic>? offer}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _OfferEditorDialog(offer: offer),
    );
  }
}

// ─── Editor Dialog ───

class _OfferEditorDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? offer;
  const _OfferEditorDialog({this.offer});

  @override
  ConsumerState<_OfferEditorDialog> createState() => _OfferEditorDialogState();
}

class _OfferEditorDialogState extends ConsumerState<_OfferEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

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
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 860),
        child: Directionality(
          textDirection: adminDir,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _isEditing ? tr('עריכת מבצע', 'Edit deal') : tr('מבצע חדש', 'New deal'),
                        style: TextStyle(
                          fontFamily: AppFonts.rubik,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildField(
                          tr('שם המבצע *', 'Deal name *'),
                          _name,
                          hint: tr('20% הנחה על כל הפיצות', '20% off all pizzas'),
                          validator: (v) =>
                              (v ?? '').trim().isEmpty ? tr('שדה חובה', 'Required field') : null,
                        ),
                        const SizedBox(height: 6),
                        _BadgeHint(controller: _name),
                        const SizedBox(height: 14),
                        _label(tr('עסק *', 'Business *')),
                        AdminBusinessPickerField(
                          label: '',
                          businessId: _businessId,
                          fallbackName: _businessName,
                          required: true,
                          onChanged: (b) => setState(() {
                            _businessId = b?.id;
                            _businessName = b?.name;
                          }),
                        ),
                        const SizedBox(height: 14),
                        _buildField(
                          tr('תיאור', 'Description'),
                          _description,
                          hint: tr('פירוט המבצע...', 'Deal details...'),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 14),
                        _buildField(
                          tr('תנאים', 'Terms'),
                          _terms,
                          hint: tr('תנאים והגבלות...', 'Terms and conditions...'),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 14),
                        ImageUploadField(
                          label: tr('תמונה', 'Image'),
                          controller: _image,
                          folder: 'offers',
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildField(
                                tr('קוד קופון', 'Coupon code'),
                                _code,
                                hint: 'PIZZA20',
                                ltr: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildField(
                                tr('מקסימום מימושים', 'Maximum redemptions'),
                                _maxClaims,
                                hint: tr('ללא הגבלה', 'No limit'),
                                keyboardType: TextInputType.number,
                                validator: (v) =>
                                    _wholeNumber(v, min: 1, required: false),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildField(
                                tr('מימושים לכל משתמש', 'Redemptions per user'),
                                _maxPerUser,
                                hint: '1',
                                keyboardType: TextInputType.number,
                                validator: (v) =>
                                    _wholeNumber(v, min: 1, required: true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildField(
                                tr('נקודות נדרשות', 'Points required'),
                                _points,
                                hint: '0',
                                keyboardType: TextInputType.number,
                                validator: (v) =>
                                    _wholeNumber(v, min: 0, required: true),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _labelled(
                                tr('תחילת מבצע', 'Deal start'),
                                AdminDateField(
                                  controller: _startDate,
                                  decoration: _inputDecoration(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _labelled(
                                tr('שעה', 'Time'),
                                AdminTimeField(
                                  controller: _startTime,
                                  decoration: _inputDecoration(hint: '00:00'),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _labelled(
                                tr('סיום מבצע', 'End deal'),
                                AdminDateField(
                                  controller: _endDate,
                                  decoration: _inputDecoration(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _labelled(
                                tr('שעה', 'Time'),
                                AdminTimeField(
                                  controller: _endTime,
                                  decoration: _inputDecoration(hint: '23:59'),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tr('בלי תאריך סיום לא יוצג באתר שעון ספירה לאחור.', 'Without an end date, no countdown is shown on the site.'),
                          style: TextStyle(
                            fontFamily: AppFonts.rubik,
                            fontSize: 11,
                            color: AppColors.grayLight,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildDropdown(
                                tr('קהל', 'Audience'),
                                _audience,
                                _audiences,
                                (v) => setState(() => _audience = v!),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDropdown(
                                tr('סטטוס', 'Status'),
                                _status,
                                _statuses,
                                (v) => setState(() => _status = v!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tr('תושבים מאומתים בלבד — מסומן באתר "לתושבים בלבד". '
                          'רק מבצע בסטטוס "פעיל" מוצג באתר.', 'Verified residents only — marked "Residents only" on the site. Only a deal with the status "Active" is shown on the site.'),
                          style: TextStyle(
                            fontFamily: AppFonts.rubik,
                            fontSize: 11,
                            color: AppColors.grayLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            tr('מומלץ', 'Recommended'),
                            style: TextStyle(
                              fontFamily: AppFonts.rubik,
                              fontSize: 14,
                            ),
                          ),
                          value: _isFeatured,
                          activeThumbColor: AppColors.gold,
                          onChanged: (v) => setState(() => _isFeatured = v),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          tr('ביטול', 'Cancel'),
                          style: TextStyle(
                            fontFamily: AppFonts.rubik,
                            fontSize: 13,
                            color: AppColors.grayText,
                          ),
                        ),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.turquoise,
                          minimumSize: const Size(120, 42),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isEditing ? tr('עדכון', 'Update') : tr('יצירה', 'Create'),
                                style: TextStyle(
                                  fontFamily: AppFonts.rubik,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: TextStyle(
        fontFamily: AppFonts.rubik,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.grayText,
      ),
    ),
  );

  Widget _labelled(String label, Widget field) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [_label(label), field],
  );

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontFamily: AppFonts.rubik,
        fontSize: 13,
        color: AppColors.grayLight,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.turquoise),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl, {
    String? hint,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool ltr = false,
  }) {
    return _labelled(
      label,
      TextFormField(
        controller: ctrl,
        validator: validator,
        maxLines: maxLines,
        keyboardType: keyboardType,
        textDirection: ltr ? TextDirection.ltr : null,
        style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14),
        decoration: _inputDecoration(hint: hint),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    Map<String, String> items,
    ValueChanged<String?> onChanged,
  ) {
    return _labelled(
      label,
      DropdownButtonFormField<String>(
        initialValue: value,
        items: items.entries
            .map(
              (e) => DropdownMenuItem(
                value: e.key,
                child: Text(
                  e.value,
                  style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14),
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
        decoration: _inputDecoration(),
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

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    String? nullIfEmpty(TextEditingController c) {
      final t = c.text.trim();
      return t.isEmpty ? null : t;
    }

    final startAt = _timestamp(_startDate, _startTime, endOfDay: false);
    final endAt = _timestamp(_endDate, _endTime, endOfDay: true);
    if (startAt != null &&
        endAt != null &&
        !DateTime.parse(endAt).isAfter(DateTime.parse(startAt))) {
      _toast(tr('סיום המבצע חייב להיות אחרי תחילתו', 'The deal\'s end must be after its start'));
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
      if (mounted) _toast(tr('שגיאה: $e', 'Error: $e'));
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(this.label, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.navy : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.navy : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: selected ? Colors.white : AppColors.grayText,
            ),
          ),
        ),
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
    final (label, color) = switch (status) {
      'active' => (tr('פעיל', 'Active'), AppColors.success),
      'expired' => (tr('פג תוקף', 'Expired'), AppColors.grayText),
      'redeemed_out' => (tr('אזל', 'Sold out'), AppColors.orange),
      'draft' => (tr('טיוטה', 'Draft'), AppColors.grayLight),
      _ => (status, AppColors.grayText),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppFonts.rubik,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
        textAlign: TextAlign.center,
      ),
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
