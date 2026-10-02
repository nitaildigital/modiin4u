import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/admin_agreements_provider.dart';
import '../widgets/admin_form_pickers.dart';
import '../admin_language.dart';

class AdminAgreementsScreen extends ConsumerStatefulWidget {
  const AdminAgreementsScreen({super.key});

  @override
  ConsumerState<AdminAgreementsScreen> createState() =>
      _AdminAgreementsScreenState();
}

class _AdminAgreementsScreenState extends ConsumerState<AdminAgreementsScreen> {
  String _statusFilter = '';
  final _searchController = TextEditingController();
  final _debouncer = _Debouncer(milliseconds: 400);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(adminAgreementListProvider);
    final loaded = asyncData.valueOrNull;
    final isWide = MediaQuery.of(context).size.width > 900;

    return Column(
      children: [
        // ─── Stats bar ───
        if (loaded != null)
          Builder(
            builder: (_) {
              final list = loaded;
              final active = list
                  .where((a) => a['status'] == 'active')
                  .toList();
              final monthly = active.fold<double>(0.0, (sum, a) {
                final price = (a['price'] as num?)?.toDouble() ?? 0;
                final discount = (a['discount_pct'] as num?)?.toDouble() ?? 0;
                final net = price * (1 - discount / 100);
                // A one-off payment is not a monthly income, so it is left
                // out; the rest are spread over the months they cover.
                final months = switch (a['billing_cycle'] as String?) {
                  'quarterly' => 3,
                  'semi_annual' => 6,
                  'annual' => 12,
                  'one_time' => 0,
                  _ => 1,
                };
                return months == 0 ? sum : sum + net / months;
              });
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
                    _StatChip(
                      tr('הכנסה חודשית משוערת', 'Estimated monthly revenue'),
                      '₪${monthly.toStringAsFixed(0)}',
                      AppColors.turquoise,
                    ),
                    const SizedBox(width: 16),
                    _StatChip(
                      tr('הסכמים פעילים', 'Active agreements'),
                      '${active.length}',
                      AppColors.success,
                    ),
                    const SizedBox(width: 16),
                    _StatChip(tr('סה״כ הסכמים', 'Total agreements'), '${list.length}', AppColors.navy),
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
                    hintText: tr('חיפוש לפי עסק...', 'Search by business...'),
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
                        .read(adminAgreementListProvider.notifier)
                        .setSearch(v.isEmpty ? null : v);
                  }),
                ),
              ),
              const SizedBox(width: 12),
              _FilterChip(tr('הכל', 'All'), _statusFilter.isEmpty, () {
                setState(() => _statusFilter = '');
                ref
                    .read(adminAgreementListProvider.notifier)
                    .setStatusFilter(null);
              }),
              _FilterChip(tr('פעיל', 'Active'), _statusFilter == 'active', () {
                setState(() => _statusFilter = 'active');
                ref
                    .read(adminAgreementListProvider.notifier)
                    .setStatusFilter('active');
              }),
              _FilterChip(tr('מושהה', 'Paused'), _statusFilter == 'paused', () {
                setState(() => _statusFilter = 'paused');
                ref
                    .read(adminAgreementListProvider.notifier)
                    .setStatusFilter('paused');
              }),
              _FilterChip(tr('בוטל', 'Cancelled'), _statusFilter == 'cancelled', () {
                setState(() => _statusFilter = 'cancelled');
                ref
                    .read(adminAgreementListProvider.notifier)
                    .setStatusFilter('cancelled');
              }),
              _FilterChip(tr('פג תוקף', 'Expired'), _statusFilter == 'expired', () {
                setState(() => _statusFilter = 'expired');
                ref
                    .read(adminAgreementListProvider.notifier)
                    .setStatusFilter('expired');
              }),
              const Spacer(),
              if (loaded != null)
                Text(
                  tr('${loaded.length} הסכמים', '${loaded.length} agreements'),
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 13,
                    color: AppColors.grayText,
                  ),
                ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: () => _showEditor(context, ref),
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  tr('הסכם חדש', 'New agreement'),
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
                tr('שגיאה בטעינת ההסכמים: ${adminErrorText(e)}', 'Error loading the agreements: ${adminErrorText(e)}'),
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
                        Icons.handshake_outlined,
                        size: 48,
                        color: AppColors.grayLight.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        tr('אין הסכמים', 'No agreements'),
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
                        _Col(tr('עסק', 'Business'), flex: 3),
                        _Col(tr('סוג', 'Type'), flex: 2),
                        if (isWide) _Col(tr('מחיר', 'Price'), flex: 1),
                        if (isWide) _Col(tr('מחזור', 'Cycle'), flex: 1),
                        _Col(tr('סטטוס', 'Status'), flex: 1),
                        if (isWide) _Col(tr('תקופה', 'Period'), flex: 2),
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
                        final a = list[i];
                        final status = a['status'] as String? ?? 'active';
                        final price = (a['price'] as num?)?.toDouble() ?? 0;
                        final discount =
                            (a['discount_pct'] as num?)?.toDouble() ?? 0;
                        final net = price * (1 - discount / 100);
                        final cycle = a['billing_cycle'] as String? ?? '';
                        final cycleLabel = _cycleLabel(cycle);
                        final typeLabel = _typeLabel(
                          a['type'] as String? ?? '',
                        );
                        final start = a['start_date'] as String? ?? '';
                        final end = a['end_date'] as String? ?? '';

                        return InkWell(
                          onTap: () => _showEditor(context, ref, agreement: a),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (a['businesses'] as Map?)?['name']
                                                as String? ??
                                            '',
                                        style: TextStyle(
                                          fontFamily: AppFonts.rubik,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.navy,
                                        ),
                                      ),
                                      Text(
                                        a['name'] as String? ?? '',
                                        style: TextStyle(
                                          fontFamily: AppFonts.rubik,
                                          fontSize: 11,
                                          color: AppColors.grayLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    typeLabel,
                                    style: TextStyle(
                                      fontFamily: AppFonts.rubik,
                                      fontSize: 13,
                                      color: AppColors.grayText,
                                    ),
                                  ),
                                ),
                                if (isWide)
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      discount > 0
                                          ? '₪${net.toStringAsFixed(0)} (${discount.toInt()}%-)'
                                          : '₪${price.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontFamily: AppFonts.rubik,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        fontFeatures: [
                                          const FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (isWide)
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      cycleLabel,
                                      style: TextStyle(
                                        fontFamily: AppFonts.rubik,
                                        fontSize: 12,
                                        color: AppColors.grayText,
                                      ),
                                    ),
                                  ),
                                Expanded(flex: 1, child: _StatusPill(status)),
                                if (isWide)
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '$start → $end',
                                      style: TextStyle(
                                        fontFamily: AppFonts.rubik,
                                        fontSize: 11,
                                        color: AppColors.grayText,
                                      ),
                                    ),
                                  ),
                                PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.more_vert,
                                    size: 18,
                                    color: AppColors.grayLight,
                                  ),
                                  onSelected: (v) => _handleAction(v, a),
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text(
                                        tr('עריכה', 'Edit'),
                                        style: TextStyle(
                                          fontFamily: AppFonts.rubik,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    if (status != 'active')
                                      PopupMenuItem(
                                        value: 'activate',
                                        child: Text(
                                          tr('הפעל', 'Activate'),
                                          style: TextStyle(
                                            fontFamily: AppFonts.rubik,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    if (status == 'active')
                                      PopupMenuItem(
                                        value: 'pause',
                                        child: Text(
                                          tr('השהה', 'Pause'),
                                          style: TextStyle(
                                            fontFamily: AppFonts.rubik,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    PopupMenuItem(
                                      value: 'cancel',
                                      child: Text(
                                        tr('בטל', 'Cancel'),
                                        style: TextStyle(
                                          fontFamily: AppFonts.rubik,
                                          fontSize: 13,
                                          color: AppColors.error,
                                        ),
                                      ),
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

  Future<void> _handleAction(String action, Map<String, dynamic> a) async {
    final notifier = ref.read(adminAgreementListProvider.notifier);
    final id = a['id'] as String;
    if (action == 'edit') {
      _showEditor(context, ref, agreement: a);
      return;
    }
    final status = switch (action) {
      'activate' => 'active',
      'pause' => 'paused',
      _ => 'cancelled',
    };
    try {
      await notifier.updateStatus(id, status);
      if (!mounted) return;
      if (status == 'cancelled') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr('ההסכם בוטל ונשמר ברשימה תחת "בוטל". "הפעל" בתפריט שלו מחזיר '
              'אותו.', 'The agreement was cancelled and kept in the list under "Cancelled". "Activate" in its menu brings it back.'),
              style: TextStyle(fontFamily: AppFonts.rubik),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) showAdminError(context, tr('הפעולה נכשלה', 'The action failed'), e);
    }
  }

  void _showEditor(
    BuildContext context,
    WidgetRef ref, {
    Map<String, dynamic>? agreement,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _AgreementEditorDialog(agreement: agreement),
    );
  }

  String _typeLabel(String t) => switch (t) {
    'subscription' => tr('מנוי', 'Subscription'),
    'banner' => tr('באנר', 'Banner'),
    'push' => 'Push',
    'featured' => tr('מומלץ', 'Recommended'),
    'sponsored' => tr('ממומן', 'Sponsored'),
    'custom' => tr('מותאם', 'Custom'),
    _ => t,
  };

  String _cycleLabel(String c) => switch (c) {
    'monthly' => tr('חודשי', 'Monthly'),
    'quarterly' => tr('רבעוני', 'Quarterly'),
    'semi_annual' => tr('חצי שנתי', 'Half-yearly'),
    'annual' => tr('שנתי', 'Yearly'),
    'one_time' => tr('חד פעמי', 'One-time'),
    _ => c,
  };
}

// ─── Editor Dialog ───

class _AgreementEditorDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? agreement;
  const _AgreementEditorDialog({this.agreement});

  @override
  ConsumerState<_AgreementEditorDialog> createState() =>
      _AgreementEditorDialogState();
}

class _AgreementEditorDialogState
    extends ConsumerState<_AgreementEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _discount;
  late final TextEditingController _cancelReason;
  late final TextEditingController _notes;

  String? _businessId;
  String? _businessName;
  bool _businessMissing = false;
  String? _salespersonId;
  String? _startDate;
  String? _endDate;
  String _type = 'subscription';
  String _billingCycle = 'monthly';
  String _status = 'active';
  bool _vatIncluded = true;
  bool _autoRenew = true;

  bool get _isEditing => widget.agreement != null;

  static Map<String, String> get _types => {
    'subscription': tr('מנוי', 'Subscription'),
    'banner': tr('באנר', 'Banner'),
    'push': 'Push',
    'featured': tr('מומלץ', 'Recommended'),
    'sponsored': tr('ממומן', 'Sponsored'),
    'custom': tr('מותאם', 'Custom'),
  };

  static Map<String, String> get _cycles => {
    'monthly': tr('חודשי', 'Monthly'),
    'quarterly': tr('רבעוני', 'Quarterly'),
    'semi_annual': tr('חצי שנתי', 'Half-yearly'),
    'annual': tr('שנתי', 'Yearly'),
    'one_time': tr('חד פעמי', 'One-time'),
  };

  static Map<String, String> get _statuses => {
    'active': tr('פעיל', 'Active'),
    'paused': tr('מושהה', 'Paused'),
    'cancelled': tr('בוטל', 'Cancelled'),
    'expired': tr('פג תוקף', 'Expired'),
  };

  @override
  void initState() {
    super.initState();
    final a = widget.agreement;
    _name = TextEditingController(text: a?['name'] as String? ?? '');
    _description = TextEditingController(
      text: a?['description'] as String? ?? '',
    );
    _price = TextEditingController(
      text: (a?['price'] as num?)?.toString() ?? '',
    );
    _discount = TextEditingController(
      text: (a?['discount_pct'] as num?)?.toString() ?? '0',
    );
    _cancelReason = TextEditingController(
      text: a?['cancel_reason'] as String? ?? '',
    );
    _notes = TextEditingController(text: a?['notes'] as String? ?? '');
    _businessId = a?['business_id'] as String?;
    _businessName = (a?['businesses'] as Map?)?['name'] as String?;
    _salespersonId = a?['salesperson_id'] as String?;
    _startDate = a?['start_date'] as String?;
    _endDate = a?['end_date'] as String?;
    // A value the enum does not know would fail the dropdown; fall back to
    // the default rather than showing a blank form.
    final type = a?['type'] as String?;
    if (_types.containsKey(type)) _type = type!;
    final cycle = a?['billing_cycle'] as String?;
    if (_cycles.containsKey(cycle)) _billingCycle = cycle!;
    final status = a?['status'] as String?;
    if (_statuses.containsKey(status)) _status = status!;
    _vatIncluded = a?['vat_included'] as bool? ?? true;
    _autoRenew = a?['auto_renew'] as bool? ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _discount.dispose();
    _cancelReason.dispose();
    _notes.dispose();
    super.dispose();
  }

  Widget _dropdown(
    String label,
    String value,
    Map<String, String> items,
    ValueChanged<String> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      items: [
        for (final e in items.entries)
          DropdownMenuItem(
            value: e.key,
            child: Text(
              e.value,
              style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
            ),
          ),
      ],
      onChanged: (v) => setState(() => onChanged(v!)),
    );
  }

  String? _number(String? v, {bool required = false, double? max}) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return required ? tr('שדה חובה', 'Required field') : null;
    final n = double.tryParse(t);
    if (n == null || n < 0) return tr('מספר לא תקין', 'Invalid number');
    if (max != null && n > max) return tr('עד $max', 'Up to $max');
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650, maxHeight: 720),
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
                        _isEditing ? tr('עריכת הסכם', 'Edit agreement') : tr('הסכם חדש', 'New agreement'),
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
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      AdminBusinessField(
                        label: tr('עסק *', 'Business *'),
                        businessId: _businessId,
                        initialName: _businessName,
                        errorText: _businessMissing ? tr('שדה חובה', 'Required field') : null,
                        onPicked: (b) => setState(() {
                          _businessId = b['id'] as String;
                          _businessName = b['name'] as String?;
                          _businessMissing = false;
                        }),
                      ),
                      _field(
                        tr('שם הסכם *', 'Agreement name *'),
                        _name,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? tr('שדה חובה', 'Required field') : null,
                      ),
                      _field(tr('תיאור', 'Description'), _description, maxLines: 2),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _dropdown(
                              tr('סוג', 'Type'),
                              _type,
                              _types,
                              (v) => _type = v,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _dropdown(
                              tr('מחזור חיוב', 'Billing cycle'),
                              _billingCycle,
                              _cycles,
                              (v) => _billingCycle = v,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              tr('מחיר (₪) *', 'Price (₪) *'),
                              _price,
                              validator: (v) => _number(v, required: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              tr('הנחה %', 'Discount %'),
                              _discount,
                              validator: (v) => _number(v, max: 100),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          FilterChip(
                            label: Text(
                              tr('כולל מע״מ', 'Including VAT'),
                              style: TextStyle(
                                fontFamily: AppFonts.rubik,
                                fontSize: 12,
                              ),
                            ),
                            selected: _vatIncluded,
                            onSelected: (v) => setState(() => _vatIncluded = v),
                            selectedColor: AppColors.turquoise.withValues(
                              alpha: 0.15,
                            ),
                            checkmarkColor: AppColors.turquoise,
                            side: BorderSide(
                              color: _vatIncluded
                                  ? AppColors.turquoise
                                  : AppColors.border,
                            ),
                          ),
                          FilterChip(
                            label: Text(
                              tr('חידוש אוטומטי', 'Auto-renew'),
                              style: TextStyle(
                                fontFamily: AppFonts.rubik,
                                fontSize: 12,
                              ),
                            ),
                            selected: _autoRenew,
                            onSelected: (v) => setState(() => _autoRenew = v),
                            selectedColor: AppColors.turquoise.withValues(
                              alpha: 0.15,
                            ),
                            checkmarkColor: AppColors.turquoise,
                            side: BorderSide(
                              color: _autoRenew
                                  ? AppColors.turquoise
                                  : AppColors.border,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AdminDateField(
                              label: tr('תאריך התחלה *', 'Start date *'),
                              value: _startDate,
                              required: true,
                              onChanged: (v) => setState(() => _startDate = v),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AdminDateField(
                              label: tr('תאריך סיום', 'End date'),
                              value: _endDate,
                              onChanged: (v) => setState(() => _endDate = v),
                            ),
                          ),
                        ],
                      ),
                      _dropdown(
                        tr('סטטוס', 'Status'),
                        _status,
                        _statuses,
                        (v) => _status = v,
                      ),
                      const SizedBox(height: 12),
                      if (_status == 'cancelled')
                        _field(tr('סיבת ביטול', 'Cancellation reason'), _cancelReason),
                      AdminSalespersonField(
                        value: _salespersonId,
                        onChanged: (v) => setState(() => _salespersonId = v),
                      ),
                      _field(tr('הערות', 'Notes'), _notes, maxLines: 2),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          tr('ביטול', 'Cancel'),
                          style: TextStyle(fontFamily: AppFonts.rubik),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.turquoise,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isEditing ? tr('שמור', 'Save') : tr('צור הסכם', 'Create agreement'),
                                style: TextStyle(
                                  fontFamily: AppFonts.rubik,
                                  fontSize: 13,
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

  Widget _field(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
      ),
    );
  }

  String? _text(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _save() async {
    final valid = _formKey.currentState!.validate();
    setState(() => _businessMissing = _businessId == null);
    if (!valid || _businessId == null) return;
    setState(() => _saving = true);
    final was = widget.agreement?['status'] as String?;
    final fields = <String, dynamic>{
      'business_id': _businessId,
      'name': _name.text.trim(),
      'description': _text(_description),
      'type': _type,
      'price': double.parse(_price.text.trim()),
      'vat_included': _vatIncluded,
      'discount_pct': double.tryParse(_discount.text.trim()) ?? 0,
      'billing_cycle': _billingCycle,
      'start_date': _startDate,
      'end_date': _endDate,
      'auto_renew': _autoRenew,
      'status': _status,
      'cancel_reason': _status == 'cancelled' ? _text(_cancelReason) : null,
      // Stamped when the status becomes cancelled, kept while it stays so,
      // cleared when it is put back.
      'cancelled_at': _status != 'cancelled'
          ? null
          : was == 'cancelled'
          ? widget.agreement!['cancelled_at']
          : DateTime.now().toUtc().toIso8601String(),
      'salesperson_id': _salespersonId,
      'notes': _text(_notes),
    };
    try {
      final notifier = ref.read(adminAgreementListProvider.notifier);
      if (_isEditing) {
        await notifier.updateAgreement(
          widget.agreement!['id'] as String,
          fields,
        );
      } else {
        await notifier.createAgreement(fields);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showAdminError(context, tr('השמירה נכשלה', 'Saving failed'), e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ─── Shared Widgets ───

class _StatChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontSize: 12,
              color: AppColors.grayText,
            ),
          ),
        ],
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
      'paused' => (tr('מושהה', 'Paused'), AppColors.gold),
      'cancelled' => (tr('בוטל', 'Cancelled'), AppColors.error),
      'expired' => (tr('פג תוקף', 'Expired'), AppColors.grayLight),
      _ => (status, AppColors.grayLight),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppFonts.rubik,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
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
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.grayLight,
        ),
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
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.turquoise.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected ? AppColors.turquoise : AppColors.border,
              width: 0.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? AppColors.turquoise : AppColors.grayText,
            ),
          ),
        ),
      ),
    );
  }
}

/// Waits for typing to pause before searching. The old version chained
/// futures it could not cancel, so every keystroke still ran a search.
class _Debouncer {
  final int milliseconds;
  _Debouncer({required this.milliseconds});
  Timer? _timer;
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}
