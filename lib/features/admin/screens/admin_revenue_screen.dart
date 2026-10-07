import 'dart:async';

import '../../../core/theme/app_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/admin_revenue_provider.dart';
import '../widgets/admin_form_pickers.dart';
import '../admin_language.dart';
import '../ui/admin_kit.dart';

/// `payment_status`, the database enum, in the panel's words.
Map<String, String> get _paymentStatuses => {
  'pending': tr('ממתין', 'Pending'),
  'paid': tr('שולם', 'Paid'),
  'partial': tr('שולם חלקית', 'Partially paid'),
  'overdue': tr('באיחור', 'Overdue'),
  'refunded': tr('זיכוי', 'Credit'),
  'cancelled': tr('בוטל', 'Cancelled'),
};

/// `revenue_type` is free text; these are the words its migration lists,
/// the same as an agreement's type.
Map<String, String> get _revenueTypes => {
  'subscription': tr('מנוי', 'Subscription'),
  'banner': tr('באנר', 'Banner'),
  'push': 'Push',
  'featured': tr('מומלץ', 'Recommended'),
  'sponsored': tr('ממומן', 'Sponsored'),
  'custom': tr('מותאם', 'Custom'),
};

class AdminRevenueScreen extends ConsumerStatefulWidget {
  const AdminRevenueScreen({super.key});

  @override
  ConsumerState<AdminRevenueScreen> createState() => _AdminRevenueScreenState();
}

class _AdminRevenueScreenState extends ConsumerState<AdminRevenueScreen> {
  String _statusFilter = '';
  final _searchController = TextEditingController();
  final _debouncer = _Debouncer(milliseconds: 400);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double _sum(Iterable<Map<String, dynamic>> rows) => rows.fold<double>(
    0,
    (s, t) => s + ((t['amount'] as num?)?.toDouble() ?? 0),
  );

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(adminRevenueListProvider);
    final loaded = asyncData.valueOrNull;
    final isWide = MediaQuery.of(context).size.width > 900;

    return Column(
      children: [
        // ─── Stats ───
        // Worked out from the rows, for the month and year it is now. This
        // read "August" and summed every paid row as the year, whatever the
        // date.
        if (loaded != null)
          Builder(
            builder: (_) {
              final now = DateTime.now();
              bool paidIn(Map<String, dynamic> t, {required bool month}) {
                if (t['payment_status'] != 'paid') return false;
                final at = DateTime.tryParse(t['paid_at'] as String? ?? '');
                if (at == null) return false;
                final local = at.toLocal();
                return local.year == now.year &&
                    (!month || local.month == now.month);
              }

              final monthPaid = _sum(
                loaded.where((t) => paidIn(t, month: true)),
              );
              final yearPaid = _sum(
                loaded.where((t) => paidIn(t, month: false)),
              );
              final pending = _sum(
                loaded.where(
                  (t) =>
                      t['payment_status'] == 'pending' ||
                      t['payment_status'] == 'partial',
                ),
              );
              final overdue = _sum(
                loaded.where((t) => t['payment_status'] == 'overdue'),
              );

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
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
                      tr('שולם החודש', 'Paid this month'),
                      '₪${monthPaid.toStringAsFixed(0)}',
                      AppColors.midBlue,
                    ),
                    const SizedBox(width: 14),
                    _StatChip(
                      tr('ממתין לתשלום', 'Awaiting payment'),
                      '₪${pending.toStringAsFixed(0)}',
                      AppColors.gold,
                    ),
                    const SizedBox(width: 14),
                    _StatChip(
                      tr('באיחור', 'Overdue'),
                      '₪${overdue.toStringAsFixed(0)}',
                      AppColors.error,
                    ),
                    const SizedBox(width: 14),
                    _StatChip(
                      tr('שולם השנה', 'Paid this year'),
                      '₪${yearPaid.toStringAsFixed(0)}',
                      AppColors.success,
                    ),
                  ],
                ),
              );
            },
          ),

        AdminListToolbar(
          search: AdminSearchField(
            controller: _searchController,
            width: isWide ? 280 : 180,
            hint: tr('חיפוש לפי עסק / חשבונית...', 'Search by business / invoice...'),
            onChanged: (v) => _debouncer.run(
              () => ref
                  .read(adminRevenueListProvider.notifier)
                  .setSearch(v.isEmpty ? null : v),
            ),
          ),
          filters: [
            for (final e in {'': tr('הכל', 'All'), ..._paymentStatuses}.entries)
              AdminFilterChip(e.value, _statusFilter == e.key, () {
                setState(() => _statusFilter = e.key);
                ref
                    .read(adminRevenueListProvider.notifier)
                    .setStatusFilter(e.key.isEmpty ? null : e.key);
              }),
          ],
          count: loaded == null
              ? null
              : tr('${loaded.length} רשומות', '${loaded.length} records'),
          actions: [
            AdminToolbarButton(
              label: tr('רשומה חדשה', 'New record'),
              onPressed: () => _showEditor(),
            ),
          ],
        ),

        // ─── Table ───
        Expanded(
          child: asyncData.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                tr('שגיאה בטעינת ההכנסות: ${adminErrorText(e)}', 'Error loading the revenue: ${adminErrorText(e)}'),
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
                        Icons.receipt_long_outlined,
                        size: 48,
                        color: AppColors.grayLight.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        tr('אין רשומות', 'No records'),
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
                        _Col(tr('סוג', 'Type'), flex: 1),
                        _Col(tr('סכום', 'Amount'), flex: 1),
                        if (isWide) _Col(tr('חשבונית', 'Invoice'), flex: 2),
                        _Col(tr('סטטוס', 'Status'), flex: 1),
                        if (isWide) _Col(tr('לתשלום עד', 'Payable by'), flex: 1),
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
                      itemBuilder: (_, i) => _row(list[i], isWide),
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

  Widget _row(Map<String, dynamic> t, bool isWide) {
    final status = t['payment_status'] as String? ?? 'pending';
    final amount = (t['amount'] as num?)?.toDouble() ?? 0;
    final isOverdue = status == 'overdue';
    final isRefund = amount < 0;
    final type = t['revenue_type'] as String? ?? '';

    return InkWell(
      onTap: () => _showEditor(row: t),
      child: Container(
        color: isOverdue ? AppColors.error.withValues(alpha: 0.04) : null,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (t['businesses'] as Map?)?['name'] as String? ?? '',
                    style: TextStyle(
                      fontFamily: AppFonts.rubik,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
                    ),
                  ),
                  Text(
                    t['description'] as String? ?? '',
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
              flex: 1,
              child: Text(
                _revenueTypes[type] ?? type,
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  fontSize: 12,
                  color: AppColors.grayText,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                '${isRefund ? "" : "₪"}${amount.abs().toStringAsFixed(0)}${isRefund ? "₪-" : ""}',
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isRefund ? AppColors.error : AppColors.navy,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
            ),
            if (isWide)
              Expanded(
                flex: 2,
                child: Text(
                  t['invoice_ref'] as String? ?? '',
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 12,
                    color: AppColors.grayText,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
              ),
            Expanded(flex: 1, child: _StatusPill(status)),
            if (isWide)
              Expanded(
                flex: 1,
                child: Text(
                  _shortDate(t['due_date'] as String? ?? ''),
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 12,
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
              onSelected: (v) => _action(v, t),
              itemBuilder: (_) => [
                _menuItem('edit', tr('עריכה', 'Edit')),
                if (status != 'paid') _menuItem('paid', tr('סמן כשולם', 'Mark as paid')),
                if (status != 'pending') _menuItem('pending', tr('החזר לממתין', 'Back to pending')),
                if (status != 'cancelled')
                  _menuItem('cancelled', tr('בטל', 'Cancel'), color: AppColors.error),
              ],
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, String label, {Color? color}) =>
      PopupMenuItem(
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

  Future<void> _action(String action, Map<String, dynamic> t) async {
    if (action == 'edit') {
      _showEditor(row: t);
      return;
    }
    try {
      await ref
          .read(adminRevenueListProvider.notifier)
          .setPaymentStatus(t, action);
      if (!mounted || action != 'cancelled') return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr('הרשומה סומנה כמבוטלת ונשמרה ברשימה. "החזר לממתין" בתפריט שלה '
            'מחזיר אותה.', 'The record was marked cancelled and kept in the list. "Back to pending" in its menu brings it back.'),
            style: TextStyle(fontFamily: AppFonts.rubik),
          ),
        ),
      );
    } catch (e) {
      if (mounted) showAdminError(context, tr('הפעולה נכשלה', 'The action failed'), e);
    }
  }

  void _showEditor({Map<String, dynamic>? row}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _RevenueEditorDialog(row: row),
    );
  }

  String _shortDate(String iso) {
    final parts = iso.split('-');
    if (parts.length < 3) return iso;
    return '${parts[2]}/${parts[1]}/${parts[0].substring(2)}';
  }
}

// ─── Editor ───

class _RevenueEditorDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? row;
  const _RevenueEditorDialog({this.row});

  @override
  ConsumerState<_RevenueEditorDialog> createState() =>
      _RevenueEditorDialogState();
}

class _RevenueEditorDialogState extends ConsumerState<_RevenueEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late final TextEditingController _description;
  late final TextEditingController _amount;
  late final TextEditingController _vat;
  late final TextEditingController _invoice;

  String? _businessId;
  String? _businessName;
  bool _businessMissing = false;
  String? _salespersonId;
  String? _dueDate;
  String _type = 'subscription';
  String _status = 'pending';

  bool get _isEditing => widget.row != null;

  @override
  void initState() {
    super.initState();
    final r = widget.row;
    _description = TextEditingController(
      text: r?['description'] as String? ?? '',
    );
    _amount = TextEditingController(
      text: (r?['amount'] as num?)?.toString() ?? '',
    );
    _vat = TextEditingController(
      text: (r?['vat_amount'] as num?)?.toString() ?? '',
    );
    _invoice = TextEditingController(text: r?['invoice_ref'] as String? ?? '');
    _businessId = r?['business_id'] as String?;
    _businessName = (r?['businesses'] as Map?)?['name'] as String?;
    _salespersonId = r?['salesperson_id'] as String?;
    _dueDate = r?['due_date'] as String?;
    final type = r?['revenue_type'] as String?;
    if (_revenueTypes.containsKey(type)) _type = type!;
    final status = r?['payment_status'] as String?;
    if (_paymentStatuses.containsKey(status)) _status = status!;
  }

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    _vat.dispose();
    _invoice.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  );

  Widget _field(
    String label,
    TextEditingController c, {
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: c,
      validator: validator,
      style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
      decoration: _decoration(label),
    ),
  );

  Widget _dropdown(
    String label,
    String value,
    Map<String, String> items,
    ValueChanged<String> onChanged,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<String>(
      initialValue: value,
      decoration: _decoration(label),
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
    ),
  );

  String? _number(String? v, {bool required = false}) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return required ? tr('שדה חובה', 'Required field') : null;
    return double.tryParse(t) == null ? tr('מספר לא תקין', 'Invalid number') : null;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 680),
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
                        _isEditing ? tr('עריכת רשומה', 'Edit record') : tr('רשומת הכנסה חדשה', 'New revenue record'),
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
                        tr('תיאור *', 'Description *'),
                        _description,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? tr('שדה חובה', 'Required field') : null,
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _field(
                              tr('סכום (₪) *', 'Amount (₪) *'),
                              _amount,
                              validator: (v) => _number(v, required: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              tr('מתוכו מע״מ (₪)', 'Of which VAT (₪)'),
                              _vat,
                              validator: (v) => _number(v),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _dropdown(
                              tr('סוג', 'Type'),
                              _type,
                              _revenueTypes,
                              (v) => _type = v,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _dropdown(
                              tr('סטטוס תשלום', 'Payment status'),
                              _status,
                              _paymentStatuses,
                              (v) => _status = v,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AdminDateField(
                              label: tr('לתשלום עד', 'Payable by'),
                              value: _dueDate,
                              onChanged: (v) => setState(() => _dueDate = v),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: _field(tr('מספר חשבונית', 'Invoice number'), _invoice)),
                        ],
                      ),
                      AdminSalespersonField(
                        value: _salespersonId,
                        onChanged: (v) => setState(() => _salespersonId = v),
                      ),
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
                          backgroundColor: AdminKit.of(context).accent,
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
                                _isEditing ? tr('שמור', 'Save') : tr('צור רשומה', 'Create record'),
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

  Future<void> _save() async {
    final valid = _formKey.currentState!.validate();
    setState(() => _businessMissing = _businessId == null);
    if (!valid || _businessId == null) return;
    setState(() => _saving = true);
    final was = widget.row;
    final fields = <String, dynamic>{
      'business_id': _businessId,
      'description': _description.text.trim(),
      'amount': double.parse(_amount.text.trim()),
      'vat_amount': double.tryParse(_vat.text.trim()) ?? 0,
      'revenue_type': _type,
      'payment_status': _status,
      // Paid keeps the date it was first marked paid; any other status has
      // no payment date.
      'paid_at': _status != 'paid'
          ? null
          : was?['paid_at'] ?? DateTime.now().toUtc().toIso8601String(),
      'due_date': _dueDate,
      'invoice_ref': _invoice.text.trim().isEmpty ? null : _invoice.text.trim(),
      'salesperson_id': _salespersonId,
    };
    try {
      final notifier = ref.read(adminRevenueListProvider.notifier);
      if (_isEditing) {
        await notifier.updateTransaction(was!['id'] as String, fields);
      } else {
        await notifier.createTransaction(fields);
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
    final k = AdminKit.of(context);
    final color = switch (status) {
      'paid' => k.success,
      'pending' || 'partial' => k.warning,
      'overdue' || 'cancelled' => k.danger,
      _ => k.muted,
    };
    final label = _paymentStatuses[status] ?? status;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: AdminPill(label, color),
    );
  }
}

class _Col extends StatelessWidget {
  final String label;
  final int flex;
  const _Col(this.label, {this.flex = 1});
  @override
  Widget build(BuildContext context) => Expanded(
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
