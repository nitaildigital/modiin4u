import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/admin_agreements_provider.dart';

class AdminAgreementsScreen extends ConsumerStatefulWidget {
  const AdminAgreementsScreen({super.key});

  @override
  ConsumerState<AdminAgreementsScreen> createState() => _AdminAgreementsScreenState();
}

class _AdminAgreementsScreenState extends ConsumerState<AdminAgreementsScreen> {
  String _statusFilter = '';
  String _typeFilter = '';
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
    final isWide = MediaQuery.of(context).size.width > 900;

    return Column(children: [
      // ─── Stats bar ───
      asyncData.whenData((list) {
        final active = list.where((a) => a['status'] == 'active').toList();
        final monthly = active.fold<double>(0.0, (sum, a) {
          final price = (a['price'] as num?)?.toDouble() ?? 0;
          final discount = (a['discount_pct'] as num?)?.toDouble() ?? 0;
          final net = price * (1 - discount / 100);
          final cycle = a['billing_cycle'] as String? ?? 'monthly';
          return sum + (cycle == 'yearly' ? net / 12 : cycle == 'quarterly' ? net / 3 : net);
        });
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
          ),
          child: Row(children: [
            _StatChip('הכנסה חודשית', '₪${monthly.toStringAsFixed(0)}', AppColors.turquoise),
            const SizedBox(width: 16),
            _StatChip('הסכמים פעילים', '${active.length}', AppColors.success),
            const SizedBox(width: 16),
            _StatChip('סה"כ הסכמים', '${list.length}', AppColors.navy),
          ]),
        );
      }).value ?? const SizedBox.shrink(),

      // ─── Toolbar ───
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
        ),
        child: Row(children: [
          SizedBox(
            width: isWide ? 280 : 180,
            height: 40,
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.rubik(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'חיפוש לפי עסק...',
                hintStyle: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayLight),
                prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.grayLight),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.turquoise)),
              ),
              onChanged: (v) => _debouncer.run(() {
                ref.read(adminAgreementListProvider.notifier).setSearch(v.isEmpty ? null : v);
              }),
            ),
          ),
          const SizedBox(width: 12),
          _FilterChip('הכל', _statusFilter.isEmpty, () { setState(() => _statusFilter = ''); ref.read(adminAgreementListProvider.notifier).setStatusFilter(null); }),
          _FilterChip('פעיל', _statusFilter == 'active', () { setState(() => _statusFilter = 'active'); ref.read(adminAgreementListProvider.notifier).setStatusFilter('active'); }),
          _FilterChip('מושהה', _statusFilter == 'paused', () { setState(() => _statusFilter = 'paused'); ref.read(adminAgreementListProvider.notifier).setStatusFilter('paused'); }),
          _FilterChip('בוטל', _statusFilter == 'cancelled', () { setState(() => _statusFilter = 'cancelled'); ref.read(adminAgreementListProvider.notifier).setStatusFilter('cancelled'); }),
          _FilterChip('פג תוקף', _statusFilter == 'expired', () { setState(() => _statusFilter = 'expired'); ref.read(adminAgreementListProvider.notifier).setStatusFilter('expired'); }),
          const Spacer(),
          asyncData.whenData((list) => Text('${list.length} הסכמים', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText))).value ?? const SizedBox.shrink(),
          const SizedBox(width: 16),
          FilledButton.icon(
            onPressed: () => _showEditor(context, ref),
            icon: const Icon(Icons.add, size: 18),
            label: Text('הסכם חדש', style: GoogleFonts.rubik(fontSize: 13)),
            style: FilledButton.styleFrom(backgroundColor: AppColors.turquoise, minimumSize: const Size(0, 40), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          ),
        ]),
      ),

      // ─── Table ───
      Expanded(
        child: asyncData.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('שגיאה: $e', style: GoogleFonts.rubik(color: AppColors.error))),
          data: (list) {
            if (list.isEmpty) {
              return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.handshake_outlined, size: 48, color: AppColors.grayLight.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text('אין הסכמים', style: GoogleFonts.rubik(color: AppColors.grayText)),
              ]));
            }
            return Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(color: AppColors.surfaceLight, border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5)))),
                child: Row(children: [
                  _Col('עסק', flex: 3),
                  _Col('סוג', flex: 2),
                  if (isWide) _Col('מחיר', flex: 1),
                  if (isWide) _Col('מחזור', flex: 1),
                  _Col('סטטוס', flex: 1),
                  if (isWide) _Col('תקופה', flex: 2),
                  const SizedBox(width: 40),
                ]),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.border.withValues(alpha: 0.3)),
                  itemBuilder: (_, i) {
                    final a = list[i];
                    final status = a['status'] as String? ?? 'active';
                    final price = (a['price'] as num?)?.toDouble() ?? 0;
                    final discount = (a['discount_pct'] as num?)?.toDouble() ?? 0;
                    final net = price * (1 - discount / 100);
                    final cycle = a['billing_cycle'] as String? ?? '';
                    final cycleLabel = _cycleLabel(cycle);
                    final typeLabel = _typeLabel(a['type'] as String? ?? '');
                    final start = a['start_date'] as String? ?? '';
                    final end = a['end_date'] as String? ?? '';

                    return InkWell(
                      onTap: () => _showEditor(context, ref, agreement: a),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Row(children: [
                          Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(a['business_name'] as String? ?? '', style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy)),
                            Text(a['name'] as String? ?? '', style: GoogleFonts.rubik(fontSize: 11, color: AppColors.grayLight)),
                          ])),
                          Expanded(flex: 2, child: Text(typeLabel, style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText))),
                          if (isWide) Expanded(flex: 1, child: Text(discount > 0 ? '₪${net.toStringAsFixed(0)} (${discount.toInt()}%-)' : '₪${price.toStringAsFixed(0)}', style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w600, fontFeatures: [const FontFeature.tabularFigures()]))),
                          if (isWide) Expanded(flex: 1, child: Text(cycleLabel, style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayText))),
                          Expanded(flex: 1, child: _StatusPill(status)),
                          if (isWide) Expanded(flex: 2, child: Text('$start → $end', style: GoogleFonts.rubik(fontSize: 11, color: AppColors.grayText))),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 18, color: AppColors.grayLight),
                            onSelected: (v) => _handleAction(v, a),
                            itemBuilder: (_) => [
                              PopupMenuItem(value: 'edit', child: Text('עריכה', style: GoogleFonts.rubik(fontSize: 13))),
                              if (status != 'active') PopupMenuItem(value: 'activate', child: Text('הפעל', style: GoogleFonts.rubik(fontSize: 13))),
                              if (status == 'active') PopupMenuItem(value: 'pause', child: Text('השהה', style: GoogleFonts.rubik(fontSize: 13))),
                              PopupMenuItem(value: 'cancel', child: Text('בטל', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.error))),
                            ],
                          ),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            ]);
          },
        ),
      ),
    ]);
  }

  void _handleAction(String action, Map<String, dynamic> a) {
    final notifier = ref.read(adminAgreementListProvider.notifier);
    final id = a['id'] as String;
    switch (action) {
      case 'edit': _showEditor(context, ref, agreement: a);
      case 'activate': notifier.updateStatus(id, 'active');
      case 'pause': notifier.updateStatus(id, 'paused');
      case 'cancel': notifier.updateStatus(id, 'cancelled');
    }
  }

  void _showEditor(BuildContext context, WidgetRef ref, {Map<String, dynamic>? agreement}) {
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => _AgreementEditorDialog(agreement: agreement));
  }

  String _typeLabel(String t) => switch (t) {
    'subscription' => 'מנוי',
    'banner' => 'באנר',
    'push' => 'Push',
    'featured' => 'מומלץ',
    'sponsored' => 'ממומן',
    'custom' => 'מותאם',
    _ => t,
  };

  String _cycleLabel(String c) => switch (c) {
    'monthly' => 'חודשי',
    'quarterly' => 'רבעוני',
    'yearly' => 'שנתי',
    'one_time' => 'חד פעמי',
    _ => c,
  };
}

// ─── Editor Dialog ───

class _AgreementEditorDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? agreement;
  const _AgreementEditorDialog({this.agreement});

  @override
  ConsumerState<_AgreementEditorDialog> createState() => _AgreementEditorDialogState();
}

class _AgreementEditorDialogState extends ConsumerState<_AgreementEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late final TextEditingController _businessName;
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _discount;
  late final TextEditingController _startDate;
  late final TextEditingController _endDate;
  late final TextEditingController _salesperson;
  late final TextEditingController _notes;

  String _type = 'subscription';
  String _billingCycle = 'monthly';
  String _status = 'active';
  bool _vatIncluded = true;
  bool _autoRenew = true;

  bool get _isEditing => widget.agreement != null;

  @override
  void initState() {
    super.initState();
    final a = widget.agreement;
    _businessName = TextEditingController(text: a?['business_name'] as String? ?? '');
    _name = TextEditingController(text: a?['name'] as String? ?? '');
    _description = TextEditingController(text: a?['description'] as String? ?? '');
    _price = TextEditingController(text: (a?['price'] as num?)?.toString() ?? '');
    _discount = TextEditingController(text: (a?['discount_pct'] as num?)?.toString() ?? '0');
    _startDate = TextEditingController(text: a?['start_date'] as String? ?? '');
    _endDate = TextEditingController(text: a?['end_date'] as String? ?? '');
    _salesperson = TextEditingController(text: a?['salesperson'] as String? ?? '');
    _notes = TextEditingController(text: a?['notes'] as String? ?? '');
    _type = a?['type'] as String? ?? 'subscription';
    _billingCycle = a?['billing_cycle'] as String? ?? 'monthly';
    _status = a?['status'] as String? ?? 'active';
    _vatIncluded = a?['vat_included'] as bool? ?? true;
    _autoRenew = a?['auto_renew'] as bool? ?? true;
  }

  @override
  void dispose() {
    _businessName.dispose(); _name.dispose(); _description.dispose();
    _price.dispose(); _discount.dispose(); _startDate.dispose(); _endDate.dispose();
    _salesperson.dispose(); _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650, maxHeight: 700),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Form(
            key: _formKey,
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
                child: Row(children: [
                  Text(_isEditing ? 'עריכת הסכם' : 'הסכם חדש', style: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
                ]),
              ),
              Expanded(
                child: ListView(padding: const EdgeInsets.all(20), children: [
                  _field('שם עסק *', _businessName, validator: (v) => v == null || v.isEmpty ? 'שדה חובה' : null),
                  _field('שם הסכם *', _name, validator: (v) => v == null || v.isEmpty ? 'שדה חובה' : null),
                  _field('תיאור', _description, maxLines: 2),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: DropdownButtonFormField<String>(
                      value: _type,
                      decoration: InputDecoration(labelText: 'סוג', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                      items: const [
                        DropdownMenuItem(value: 'subscription', child: Text('מנוי')),
                        DropdownMenuItem(value: 'banner', child: Text('באנר')),
                        DropdownMenuItem(value: 'push', child: Text('Push')),
                        DropdownMenuItem(value: 'featured', child: Text('מומלץ')),
                        DropdownMenuItem(value: 'sponsored', child: Text('ממומן')),
                        DropdownMenuItem(value: 'custom', child: Text('מותאם')),
                      ],
                      onChanged: (v) => setState(() => _type = v!),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: DropdownButtonFormField<String>(
                      value: _billingCycle,
                      decoration: InputDecoration(labelText: 'מחזור חיוב', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                      items: const [
                        DropdownMenuItem(value: 'monthly', child: Text('חודשי')),
                        DropdownMenuItem(value: 'quarterly', child: Text('רבעוני')),
                        DropdownMenuItem(value: 'yearly', child: Text('שנתי')),
                        DropdownMenuItem(value: 'one_time', child: Text('חד פעמי')),
                      ],
                      onChanged: (v) => setState(() => _billingCycle = v!),
                    )),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _field('מחיר (₪) *', _price, validator: (v) => v == null || v.isEmpty ? 'שדה חובה' : null)),
                    const SizedBox(width: 12),
                    Expanded(child: _field('הנחה %', _discount)),
                  ]),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 4, children: [
                    FilterChip(label: Text('כולל מע"מ', style: GoogleFonts.rubik(fontSize: 12)), selected: _vatIncluded, onSelected: (v) => setState(() => _vatIncluded = v), selectedColor: AppColors.turquoise.withValues(alpha: 0.15), checkmarkColor: AppColors.turquoise, side: BorderSide(color: _vatIncluded ? AppColors.turquoise : AppColors.border)),
                    FilterChip(label: Text('חידוש אוטומטי', style: GoogleFonts.rubik(fontSize: 12)), selected: _autoRenew, onSelected: (v) => setState(() => _autoRenew = v), selectedColor: AppColors.turquoise.withValues(alpha: 0.15), checkmarkColor: AppColors.turquoise, side: BorderSide(color: _autoRenew ? AppColors.turquoise : AppColors.border)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _field('תאריך התחלה', _startDate)),
                    const SizedBox(width: 12),
                    Expanded(child: _field('תאריך סיום', _endDate)),
                  ]),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: InputDecoration(labelText: 'סטטוס', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('פעיל')),
                      DropdownMenuItem(value: 'paused', child: Text('מושהה')),
                      DropdownMenuItem(value: 'cancelled', child: Text('בוטל')),
                      DropdownMenuItem(value: 'expired', child: Text('פג תוקף')),
                    ],
                    onChanged: (v) => setState(() => _status = v!),
                  ),
                  const SizedBox(height: 12),
                  _field('איש מכירות', _salesperson),
                  _field('הערות', _notes, maxLines: 2),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
                child: Row(children: [
                  const Spacer(),
                  TextButton(onPressed: () => Navigator.pop(context), child: Text('ביטול', style: GoogleFonts.rubik())),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(backgroundColor: AppColors.turquoise, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_isEditing ? 'שמור' : 'צור הסכם', style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, {int maxLines = 1, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller, maxLines: maxLines, validator: validator,
        style: GoogleFonts.rubik(fontSize: 13),
        decoration: InputDecoration(labelText: label, labelStyle: GoogleFonts.rubik(fontSize: 13), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final fields = <String, dynamic>{
      'business_name': _businessName.text,
      'name': _name.text,
      'description': _description.text.isEmpty ? null : _description.text,
      'type': _type,
      'price': double.tryParse(_price.text) ?? 0,
      'vat_included': _vatIncluded,
      'discount_pct': double.tryParse(_discount.text) ?? 0,
      'billing_cycle': _billingCycle,
      'start_date': _startDate.text.isEmpty ? null : _startDate.text,
      'end_date': _endDate.text.isEmpty ? null : _endDate.text,
      'auto_renew': _autoRenew,
      'status': _status,
      'salesperson': _salesperson.text.isEmpty ? null : _salesperson.text,
      'notes': _notes.text.isEmpty ? null : _notes.text,
    };
    try {
      final notifier = ref.read(adminAgreementListProvider.notifier);
      if (_isEditing) {
        await notifier.updateAgreement(widget.agreement!['id'] as String, fields);
      } else {
        await notifier.createAgreement(fields);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('שגיאה: $e'), backgroundColor: AppColors.error));
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
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w700, color: color, fontFeatures: [const FontFeature.tabularFigures()])),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayText)),
      ]),
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
      'paused' => ('מושהה', AppColors.gold),
      'cancelled' => ('בוטל', AppColors.error),
      'expired' => ('פג תוקף', AppColors.grayLight),
      _ => (status, AppColors.grayLight),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: GoogleFonts.rubik(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _Col extends StatelessWidget {
  final String label;
  final int flex;
  const _Col(this.label, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(flex: flex, child: Text(label, style: GoogleFonts.rubik(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.grayLight)));
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
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.turquoise.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: selected ? AppColors.turquoise : AppColors.border, width: 0.5),
          ),
          child: Text(label, style: GoogleFonts.rubik(fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? AppColors.turquoise : AppColors.grayText)),
        ),
      ),
    );
  }
}

class _Debouncer {
  final int milliseconds;
  _Debouncer({required this.milliseconds});
  Future<void>? _pending;
  void run(VoidCallback action) {
    _pending?.ignore();
    _pending = Future.delayed(Duration(milliseconds: milliseconds)).then((_) => action());
  }
}
