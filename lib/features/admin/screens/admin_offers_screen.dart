import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/admin_offers_provider.dart';

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(adminOfferListProvider);
    final isWide = MediaQuery.of(context).size.width > 900;

    return Column(children: [
      // ─── Stats bar ───
      asyncData.whenData((list) {
        final active = list.where((o) => o['status'] == 'active').length;
        final totalClaims = list.fold<int>(0, (s, o) => s + ((o['current_claims'] as int?) ?? 0));
        final featured = list.where((o) => o['is_featured'] == true).length;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
          ),
          child: Row(children: [
            _StatChip('מבצעים פעילים', '$active', AppColors.success),
            const SizedBox(width: 16),
            _StatChip('סה"כ מימושים', '$totalClaims', AppColors.turquoise),
            const SizedBox(width: 16),
            _StatChip('מומלצים', '$featured', AppColors.gold),
            const SizedBox(width: 16),
            _StatChip('סה"כ מבצעים', '${list.length}', AppColors.navy),
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
                hintText: 'חיפוש מבצע...',
                hintStyle: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayLight),
                prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.grayLight),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.turquoise)),
              ),
              onChanged: (v) => _debouncer.run(() {
                ref.read(adminOfferListProvider.notifier).setSearch(v.isEmpty ? null : v);
              }),
            ),
          ),
          const SizedBox(width: 12),
          _FilterChip('הכל', _statusFilter.isEmpty, () { setState(() => _statusFilter = ''); ref.read(adminOfferListProvider.notifier).setStatusFilter(null); }),
          _FilterChip('פעיל', _statusFilter == 'active', () { setState(() => _statusFilter = 'active'); ref.read(adminOfferListProvider.notifier).setStatusFilter('active'); }),
          _FilterChip('מתוכנן', _statusFilter == 'scheduled', () { setState(() => _statusFilter = 'scheduled'); ref.read(adminOfferListProvider.notifier).setStatusFilter('scheduled'); }),
          _FilterChip('פג תוקף', _statusFilter == 'expired', () { setState(() => _statusFilter = 'expired'); ref.read(adminOfferListProvider.notifier).setStatusFilter('expired'); }),
          const Spacer(),
          asyncData.whenData((list) => Text('${list.length} מבצעים', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText))).value ?? const SizedBox.shrink(),
          const SizedBox(width: 16),
          FilledButton.icon(
            onPressed: () => _showEditor(context, ref),
            icon: const Icon(Icons.add, size: 18),
            label: Text('מבצע חדש', style: GoogleFonts.rubik(fontSize: 13)),
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
                Icon(Icons.local_offer_outlined, size: 48, color: AppColors.grayLight.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text('אין מבצעים', style: GoogleFonts.rubik(color: AppColors.grayText)),
              ]));
            }
            return Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(color: AppColors.surfaceLight, border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5)))),
                child: Row(children: [
                  _Col('מבצע', flex: 3),
                  _Col('עסק', flex: 2),
                  if (isWide) _Col('סוג הנחה', flex: 1),
                  if (isWide) _Col('מימושים', flex: 1),
                  if (isWide) _Col('קוד', flex: 1),
                  _Col('סטטוס', flex: 1),
                  const SizedBox(width: 40),
                ]),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.border.withValues(alpha: 0.3)),
                  itemBuilder: (_, i) {
                    final o = list[i];
                    final status = o['status'] as String? ?? 'draft';
                    final discountType = o['discount_type'] as String? ?? '';
                    final claims = o['current_claims'] as int? ?? 0;
                    final maxClaims = o['max_claims'] as int?;
                    final isFeatured = o['is_featured'] as bool? ?? false;

                    return InkWell(
                      onTap: () => _showEditor(context, ref, offer: o),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Row(children: [
                          Expanded(flex: 3, child: Row(children: [
                            if (isFeatured) Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Icon(Icons.star, size: 16, color: AppColors.gold),
                            ),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(o['title'] as String? ?? '', style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy)),
                              if (o['description'] != null) Text(o['description'] as String, style: GoogleFonts.rubik(fontSize: 11, color: AppColors.grayLight), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ])),
                          ])),
                          Expanded(flex: 2, child: Text(o['business_name'] as String? ?? '', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText))),
                          if (isWide) Expanded(flex: 1, child: Text(_discountLabel(discountType), style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayText))),
                          if (isWide) Expanded(flex: 1, child: Text(maxClaims != null ? '$claims / $maxClaims' : '$claims', style: GoogleFonts.rubik(fontSize: 13, fontFeatures: [const FontFeature.tabularFigures()]))),
                          if (isWide) Expanded(flex: 1, child: Text(o['code'] as String? ?? '—', style: GoogleFonts.rubik(fontSize: 12, color: AppColors.turquoise))),
                          Expanded(flex: 1, child: _StatusPill(status)),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 18, color: AppColors.grayLight),
                            onSelected: (v) => _handleAction(v, o),
                            itemBuilder: (_) => [
                              PopupMenuItem(value: 'edit', child: Text('עריכה', style: GoogleFonts.rubik(fontSize: 13))),
                              if (status != 'active') PopupMenuItem(value: 'activate', child: Text('הפעל', style: GoogleFonts.rubik(fontSize: 13))),
                              if (status == 'active') PopupMenuItem(value: 'expire', child: Text('סיים', style: GoogleFonts.rubik(fontSize: 13))),
                              PopupMenuItem(value: 'delete', child: Text('מחיקה', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.error))),
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

  String _discountLabel(String t) => switch (t) {
    'percentage' => 'אחוז',
    'fixed' => 'סכום קבוע',
    'bogo' => 'קנה-קבל',
    'gift' => 'מתנה',
    _ => t,
  };

  void _handleAction(String action, Map<String, dynamic> o) {
    final notifier = ref.read(adminOfferListProvider.notifier);
    final id = o['id'] as String;
    switch (action) {
      case 'edit': _showEditor(context, ref, offer: o);
      case 'activate': notifier.updateStatus(id, 'active');
      case 'expire': notifier.updateStatus(id, 'expired');
      case 'delete': notifier.deleteOffer(id);
    }
  }

  void _showEditor(BuildContext context, WidgetRef ref, {Map<String, dynamic>? offer}) {
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => _OfferEditorDialog(offer: offer));
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

  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _businessName;
  late final TextEditingController _businessId;
  late final TextEditingController _discountValue;
  late final TextEditingController _originalPrice;
  late final TextEditingController _discountedPrice;
  late final TextEditingController _code;
  late final TextEditingController _maxClaims;
  late final TextEditingController _terms;
  late final TextEditingController _startAt;
  late final TextEditingController _endAt;
  String _discountType = 'percentage';
  String _status = 'draft';
  bool _isFeatured = false;

  bool get _isEditing => widget.offer != null;

  @override
  void initState() {
    super.initState();
    final o = widget.offer;
    _title = TextEditingController(text: o?['title'] as String? ?? '');
    _description = TextEditingController(text: o?['description'] as String? ?? '');
    _businessName = TextEditingController(text: o?['business_name'] as String? ?? '');
    _businessId = TextEditingController(text: o?['business_id'] as String? ?? '');
    _discountValue = TextEditingController(text: (o?['discount_value'] as num?)?.toString() ?? '');
    _originalPrice = TextEditingController(text: (o?['original_price'] as num?)?.toString() ?? '');
    _discountedPrice = TextEditingController(text: (o?['discounted_price'] as num?)?.toString() ?? '');
    _code = TextEditingController(text: o?['code'] as String? ?? '');
    _maxClaims = TextEditingController(text: (o?['max_claims'] as int?)?.toString() ?? '');
    _terms = TextEditingController(text: o?['terms'] as String? ?? '');
    _startAt = TextEditingController(text: o?['start_at'] as String? ?? '');
    _endAt = TextEditingController(text: o?['end_at'] as String? ?? '');
    _discountType = o?['discount_type'] as String? ?? 'percentage';
    _status = o?['status'] as String? ?? 'draft';
    _isFeatured = o?['is_featured'] as bool? ?? false;
  }

  @override
  void dispose() {
    _title.dispose(); _description.dispose(); _businessName.dispose();
    _businessId.dispose(); _discountValue.dispose(); _originalPrice.dispose();
    _discountedPrice.dispose(); _code.dispose(); _maxClaims.dispose();
    _terms.dispose(); _startAt.dispose(); _endAt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650, maxHeight: 720),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Form(
            key: _formKey,
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
                child: Row(children: [
                  Text(_isEditing ? 'עריכת מבצע' : 'מבצע חדש', style: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
                ]),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _buildField('כותרת', _title, hint: '20% הנחה על כל הפיצות', validator: (v) => v == null || v.isEmpty ? 'שדה חובה' : null),
                    const SizedBox(height: 14),
                    _buildField('תיאור', _description, hint: 'פירוט המבצע...', maxLines: 2),
                    const SizedBox(height: 14),
                    _buildField('עסק', _businessName, hint: 'פיצה פרגו'),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(child: _buildDropdown('סוג הנחה', _discountType, {'percentage': 'אחוז', 'fixed': 'סכום קבוע', 'bogo': 'קנה-קבל', 'gift': 'מתנה'}, (v) => setState(() => _discountType = v!))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildField('ערך הנחה', _discountValue, hint: '20', keyboardType: TextInputType.number)),
                    ]),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(child: _buildField('מחיר מקורי', _originalPrice, hint: '₪', keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildField('מחיר לאחר הנחה', _discountedPrice, hint: '₪', keyboardType: TextInputType.number)),
                    ]),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(child: _buildField('קוד קופון', _code, hint: 'PIZZA20')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildField('מקסימום מימושים', _maxClaims, hint: 'ללא הגבלה', keyboardType: TextInputType.number)),
                    ]),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(child: _buildField('תחילת מבצע', _startAt, hint: '2026-09-01')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildField('סיום מבצע', _endAt, hint: '2026-09-30')),
                    ]),
                    const SizedBox(height: 14),
                    _buildField('תנאים', _terms, hint: 'תנאים והגבלות...', maxLines: 2),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(child: _buildDropdown('סטטוס', _status, {'draft': 'טיוטה', 'active': 'פעיל', 'scheduled': 'מתוכנן', 'expired': 'פג תוקף'}, (v) => setState(() => _status = v!))),
                      const SizedBox(width: 12),
                      Expanded(child: SwitchListTile(
                        title: Text('מומלץ', style: GoogleFonts.rubik(fontSize: 14)),
                        value: _isFeatured,
                        activeColor: AppColors.gold,
                        onChanged: (v) => setState(() => _isFeatured = v),
                      )),
                    ]),
                  ]),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.5)))),
                child: Row(children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: Text('ביטול', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText))),
                  const Spacer(),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(backgroundColor: AppColors.turquoise, minimumSize: const Size(120, 42), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_isEditing ? 'עדכון' : 'יצירה', style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, {String? hint, String? Function(String?)? validator, int maxLines = 1, TextInputType? keyboardType}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.rubik(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.grayText)),
      const SizedBox(height: 6),
      TextFormField(
        controller: ctrl,
        validator: validator,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: GoogleFonts.rubik(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayLight),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.turquoise)),
        ),
      ),
    ]);
  }

  Widget _buildDropdown(String label, String value, Map<String, String> items, ValueChanged<String?> onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.rubik(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.grayText)),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
        value: value,
        items: items.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: GoogleFonts.rubik(fontSize: 14)))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.turquoise)),
        ),
      ),
    ]);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final notifier = ref.read(adminOfferListProvider.notifier);
    final data = {
      'title': _title.text.trim(),
      'description': _description.text.trim(),
      'business_name': _businessName.text.trim(),
      'business_id': _businessId.text.trim(),
      'discount_type': _discountType,
      'discount_value': num.tryParse(_discountValue.text) ?? 0,
      'original_price': num.tryParse(_originalPrice.text),
      'discounted_price': num.tryParse(_discountedPrice.text),
      'code': _code.text.trim().isEmpty ? null : _code.text.trim(),
      'max_claims': int.tryParse(_maxClaims.text),
      'terms': _terms.text.trim(),
      'start_at': _startAt.text.trim().isEmpty ? null : _startAt.text.trim(),
      'end_at': _endAt.text.trim().isEmpty ? null : _endAt.text.trim(),
      'status': _status,
      'is_featured': _isFeatured,
    };
    if (_isEditing) {
      await notifier.updateOffer(widget.offer!['id'] as String, data);
    } else {
      await notifier.createOffer(data);
    }
    if (mounted) Navigator.pop(context);
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
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: GoogleFonts.rubik(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.rubik(fontSize: 12, color: color.withValues(alpha: 0.7))),
      ]),
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
            border: Border.all(color: selected ? AppColors.navy : AppColors.border),
          ),
          child: Text(label, style: GoogleFonts.rubik(fontSize: 12, fontWeight: FontWeight.w500, color: selected ? Colors.white : AppColors.grayText)),
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
    return Expanded(flex: flex, child: Text(label, style: GoogleFonts.rubik(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.grayText)));
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill(this.status);

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'active' => ('פעיל', AppColors.success),
      'scheduled' => ('מתוכנן', AppColors.turquoise),
      'expired' => ('פג תוקף', AppColors.grayText),
      'draft' => ('טיוטה', AppColors.grayLight),
      _ => (status, AppColors.grayText),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: GoogleFonts.rubik(fontSize: 11, fontWeight: FontWeight.w600, color: color), textAlign: TextAlign.center),
    );
  }
}

class _Debouncer {
  final int milliseconds;
  _Debouncer({required this.milliseconds});
  void run(VoidCallback action) {
    Future.delayed(Duration(milliseconds: milliseconds), action);
  }
}
