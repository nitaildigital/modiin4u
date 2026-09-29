import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../deals/models/offer.dart' show offerBadge;
import '../providers/admin_offers_provider.dart';
import '../widgets/admin_events_form_fields.dart';
import '../widgets/image_upload_field.dart';

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
        asyncData.whenData((list) {
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
                    _StatChip('מבצעים פעילים', '$active', AppColors.success),
                    const SizedBox(width: 16),
                    _StatChip(
                      'סה״כ מימושים',
                      '$totalClaims',
                      AppColors.turquoise,
                    ),
                    const SizedBox(width: 16),
                    _StatChip('מומלצים', '$featured', AppColors.gold),
                    const SizedBox(width: 16),
                    _StatChip('סה״כ מבצעים', '${list.length}', AppColors.navy),
                  ],
                ),
              );
            }).value ??
            const SizedBox.shrink(),

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
                    hintText: 'חיפוש מבצע...',
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
              _FilterChip('הכל', _statusFilter.isEmpty, () => _filter('')),
              _FilterChip(
                'פעיל',
                _statusFilter == 'active',
                () => _filter('active'),
              ),
              _FilterChip(
                'טיוטה',
                _statusFilter == 'draft',
                () => _filter('draft'),
              ),
              _FilterChip(
                'פג תוקף',
                _statusFilter == 'expired',
                () => _filter('expired'),
              ),
              _FilterChip(
                'אזל',
                _statusFilter == 'redeemed_out',
                () => _filter('redeemed_out'),
              ),
              const Spacer(),
              asyncData
                      .whenData(
                        (list) => Text(
                          '${list.length} מבצעים',
                          style: TextStyle(
                            fontFamily: AppFonts.rubik,
                            fontSize: 13,
                            color: AppColors.grayText,
                          ),
                        ),
                      )
                      .value ??
                  const SizedBox.shrink(),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: () => _showEditor(context),
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  'מבצע חדש',
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
            error: (e, _) => Center(
              child: Text(
                'שגיאה: $e',
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  color: AppColors.error,
                ),
              ),
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
                        'אין מבצעים',
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
                        _Col('מבצע', flex: 3),
                        _Col('עסק', flex: 2),
                        if (isWide) _Col('תגית באתר', flex: 1),
                        if (isWide) _Col('מימושים', flex: 1),
                        if (isWide) _Col('בתוקף עד', flex: 1),
                        _Col('סטטוס', flex: 1),
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
                                                  'לתושבים בלבד',
                                                if ((o['code'] as String? ?? '')
                                                    .isNotEmpty)
                                                  'קוד ${o['code']}',
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
                                          ? 'ללא'
                                          : '${formatAdminDate(endAt)} '
                                                '${formatAdminTime(endAt.hour, endAt.minute)}',
                                      textDirection: TextDirection.ltr,
                                      textAlign: TextAlign.right,
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
                                    _menuItem('edit', 'עריכה'),
                                    if (status != 'active')
                                      _menuItem('activate', 'הפעל'),
                                    if (status == 'active')
                                      _menuItem('expire', 'סיים'),
                                    _menuItem(
                                      'delete',
                                      // The row is not removed; it becomes status = 'expired'.
                                      'סיום',
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
        SnackBar(content: Text('שגיאה: $e'), backgroundColor: AppColors.error),
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
        _run(() => notifier.updateStatus(id, 'expired'));
      case 'delete':
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

  static const _statuses = {
    'draft': 'טיוטה',
    'active': 'פעיל',
    'expired': 'פג תוקף',
    'redeemed_out': 'אזל',
  };

  /// `audience` per migration 00007. The website marks `verified` as
  /// "Residents Only".
  static const _audiences = {
    'all': 'כולם',
    'verified': 'תושבים מאומתים בלבד',
    'new_users': 'משתמשים חדשים',
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
          textDirection: TextDirection.rtl,
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
                        _isEditing ? 'עריכת מבצע' : 'מבצע חדש',
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
                          'שם המבצע *',
                          _name,
                          hint: '20% הנחה על כל הפיצות',
                          validator: (v) =>
                              (v ?? '').trim().isEmpty ? 'שדה חובה' : null,
                        ),
                        const SizedBox(height: 6),
                        _BadgeHint(controller: _name),
                        const SizedBox(height: 14),
                        _label('עסק *'),
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
                          'תיאור',
                          _description,
                          hint: 'פירוט המבצע...',
                          maxLines: 3,
                        ),
                        const SizedBox(height: 14),
                        _buildField(
                          'תנאים',
                          _terms,
                          hint: 'תנאים והגבלות...',
                          maxLines: 3,
                        ),
                        const SizedBox(height: 14),
                        ImageUploadField(
                          label: 'תמונה',
                          controller: _image,
                          folder: 'offers',
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildField(
                                'קוד קופון',
                                _code,
                                hint: 'PIZZA20',
                                ltr: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildField(
                                'מקסימום מימושים',
                                _maxClaims,
                                hint: 'ללא הגבלה',
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
                                'מימושים לכל משתמש',
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
                                'נקודות נדרשות',
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
                                'תחילת מבצע',
                                AdminDateField(
                                  controller: _startDate,
                                  decoration: _inputDecoration(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _labelled(
                                'שעה',
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
                                'סיום מבצע',
                                AdminDateField(
                                  controller: _endDate,
                                  decoration: _inputDecoration(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _labelled(
                                'שעה',
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
                          'בלי תאריך סיום לא יוצג באתר שעון ספירה לאחור.',
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
                                'קהל',
                                _audience,
                                _audiences,
                                (v) => setState(() => _audience = v!),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDropdown(
                                'סטטוס',
                                _status,
                                _statuses,
                                (v) => setState(() => _status = v!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'תושבים מאומתים בלבד — מסומן באתר "לתושבים בלבד". '
                          'רק מבצע בסטטוס "פעיל" מוצג באתר.',
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
                            'מומלץ',
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
                          'ביטול',
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
                                _isEditing ? 'עדכון' : 'יצירה',
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
    if (t.isEmpty) return required ? 'שדה חובה' : null;
    final n = int.tryParse(t);
    return n == null || n < min ? 'מספר שלם, $min ומעלה' : null;
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
      _toast('סיום המבצע חייב להיות אחרי תחילתו');
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
      if (mounted) _toast('שגיאה: $e');
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
              'ההנחה שכתובה בשם ("20% הנחה", "1+1", "₪50 הנחה", "מתנה") '
              'הופכת לתגית על כרטיס המבצע באתר.',
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
                  'תגית: ',
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
                    'אין — השם לא מציין הנחה',
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
      padding: const EdgeInsets.only(left: 6),
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
      'active' => ('פעיל', AppColors.success),
      'expired' => ('פג תוקף', AppColors.grayText),
      'redeemed_out' => ('אזל', AppColors.orange),
      'draft' => ('טיוטה', AppColors.grayLight),
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
