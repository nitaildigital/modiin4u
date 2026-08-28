import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/admin_ad_placements_provider.dart';

class AdminAdPlacementsScreen extends ConsumerStatefulWidget {
  const AdminAdPlacementsScreen({super.key});

  @override
  ConsumerState<AdminAdPlacementsScreen> createState() => _AdminAdPlacementsScreenState();
}

class _AdminAdPlacementsScreenState extends ConsumerState<AdminAdPlacementsScreen> {
  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(adminAdPlacementListProvider);
    final isWide = MediaQuery.of(context).size.width > 900;

    return Column(children: [
      // ─── Stats bar ───
      asyncData.whenData((list) {
        final active = list.where((p) => p['is_active'] == true).length;
        final totalCampaigns = list.fold<int>(0, (s, p) => s + ((p['active_campaigns_count'] as int?) ?? 0));
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
          ),
          child: Row(children: [
            _StatChip('סה"כ מיקומים', '${list.length}', AppColors.navy),
            const SizedBox(width: 16),
            _StatChip('פעילים', '$active', AppColors.success),
            const SizedBox(width: 16),
            _StatChip('קמפיינים פעילים', '$totalCampaigns', AppColors.turquoise),
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
          Icon(Icons.ad_units, size: 20, color: AppColors.navy),
          const SizedBox(width: 8),
          Text('מיקומי פרסום', style: GoogleFonts.rubik(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.navy)),
          const Spacer(),
          asyncData.whenData((list) => Text('${list.length} מיקומים', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText))).value ?? const SizedBox.shrink(),
          const SizedBox(width: 16),
          FilledButton.icon(
            onPressed: () => _showEditor(context, ref),
            icon: const Icon(Icons.add, size: 18),
            label: Text('מיקום חדש', style: GoogleFonts.rubik(fontSize: 13)),
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
                Icon(Icons.ad_units_outlined, size: 48, color: AppColors.grayLight.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text('אין מיקומי פרסום', style: GoogleFonts.rubik(color: AppColors.grayText)),
              ]));
            }
            return Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(color: AppColors.surfaceLight, border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5)))),
                child: Row(children: [
                  _Col('קוד', flex: 2),
                  _Col('תיאור', flex: 3),
                  if (isWide) _Col('גדלים', flex: 2),
                  _Col('באנרים', flex: 1),
                  _Col('קמפיינים', flex: 1),
                  _Col('סטטוס', flex: 1),
                  const SizedBox(width: 40),
                ]),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.border.withValues(alpha: 0.3)),
                  itemBuilder: (_, i) {
                    final p = list[i];
                    final isActive = p['is_active'] as bool? ?? false;
                    final campaigns = p['active_campaigns_count'] as int? ?? 0;

                    return InkWell(
                      onTap: () => _showEditor(context, ref, placement: p),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Row(children: [
                          Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(p['label'] as String? ?? '', style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy)),
                            Text(p['code'] as String? ?? '', style: GoogleFonts.rubik(fontSize: 11, color: AppColors.grayLight)),
                          ])),
                          Expanded(flex: 3, child: Text(p['description'] as String? ?? '', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText))),
                          if (isWide) Expanded(flex: 2, child: Text(p['allowed_sizes'] as String? ?? '', style: GoogleFonts.rubik(fontSize: 11, color: AppColors.grayLight))),
                          Expanded(flex: 1, child: Text('${p['max_banners'] ?? 1}', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText), textAlign: TextAlign.center)),
                          Expanded(flex: 1, child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: campaigns > 0 ? AppColors.turquoise.withValues(alpha: 0.1) : AppColors.grayLight.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('$campaigns', style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w600, color: campaigns > 0 ? AppColors.turquoise : AppColors.grayText), textAlign: TextAlign.center),
                          )),
                          Expanded(flex: 1, child: _StatusPill(isActive ? 'active' : 'inactive')),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 18, color: AppColors.grayLight),
                            onSelected: (v) => _handleAction(v, p),
                            itemBuilder: (_) => [
                              PopupMenuItem(value: 'edit', child: Text('עריכה', style: GoogleFonts.rubik(fontSize: 13))),
                              PopupMenuItem(value: 'toggle', child: Text(isActive ? 'השבת' : 'הפעל', style: GoogleFonts.rubik(fontSize: 13))),
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

  void _handleAction(String action, Map<String, dynamic> p) {
    final notifier = ref.read(adminAdPlacementListProvider.notifier);
    final id = p['id'] as String;
    switch (action) {
      case 'edit': _showEditor(context, ref, placement: p);
      case 'toggle': notifier.toggleActive(id);
      case 'delete': notifier.deletePlacement(id);
    }
  }

  void _showEditor(BuildContext context, WidgetRef ref, {Map<String, dynamic>? placement}) {
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => _PlacementEditorDialog(placement: placement));
  }
}

// ─── Editor Dialog ───

class _PlacementEditorDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? placement;
  const _PlacementEditorDialog({this.placement});

  @override
  ConsumerState<_PlacementEditorDialog> createState() => _PlacementEditorDialogState();
}

class _PlacementEditorDialogState extends ConsumerState<_PlacementEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late final TextEditingController _code;
  late final TextEditingController _label;
  late final TextEditingController _description;
  late final TextEditingController _maxBanners;
  late final TextEditingController _allowedSizes;
  bool _isActive = true;

  bool get _isEditing => widget.placement != null;

  @override
  void initState() {
    super.initState();
    final p = widget.placement;
    _code = TextEditingController(text: p?['code'] as String? ?? '');
    _label = TextEditingController(text: p?['label'] as String? ?? '');
    _description = TextEditingController(text: p?['description'] as String? ?? '');
    _maxBanners = TextEditingController(text: (p?['max_banners'] as int?)?.toString() ?? '1');
    _allowedSizes = TextEditingController(text: p?['allowed_sizes'] as String? ?? '');
    _isActive = p?['is_active'] as bool? ?? true;
  }

  @override
  void dispose() {
    _code.dispose(); _label.dispose(); _description.dispose();
    _maxBanners.dispose(); _allowedSizes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 580),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Form(
            key: _formKey,
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
                child: Row(children: [
                  Text(_isEditing ? 'עריכת מיקום' : 'מיקום חדש', style: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
                ]),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _buildField('קוד מיקום', _code, hint: 'HOME_TOP', validator: (v) => v == null || v.isEmpty ? 'שדה חובה' : null),
                    const SizedBox(height: 14),
                    _buildField('תווית', _label, hint: 'ראש עמוד הבית', validator: (v) => v == null || v.isEmpty ? 'שדה חובה' : null),
                    const SizedBox(height: 14),
                    _buildField('תיאור', _description, hint: 'באנר ראשי מעל הפיד', maxLines: 2),
                    const SizedBox(height: 14),
                    _buildField('מקסימום באנרים', _maxBanners, hint: '1', keyboardType: TextInputType.number),
                    const SizedBox(height: 14),
                    _buildField('גדלים מותרים', _allowedSizes, hint: '728x90, 320x100'),
                    const SizedBox(height: 14),
                    SwitchListTile(
                      title: Text('פעיל', style: GoogleFonts.rubik(fontSize: 14)),
                      value: _isActive,
                      activeColor: AppColors.turquoise,
                      onChanged: (v) => setState(() => _isActive = v),
                    ),
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final notifier = ref.read(adminAdPlacementListProvider.notifier);
    final data = {
      'code': _code.text.trim(),
      'label': _label.text.trim(),
      'description': _description.text.trim(),
      'max_banners': int.tryParse(_maxBanners.text) ?? 1,
      'allowed_sizes': _allowedSizes.text.trim(),
      'is_active': _isActive,
      'sort_order': 99,
    };
    if (_isEditing) {
      await notifier.updatePlacement(widget.placement!['id'] as String, data);
    } else {
      await notifier.createPlacement(data);
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
      'inactive' => ('מושבת', AppColors.grayText),
      _ => (status, AppColors.grayText),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: GoogleFonts.rubik(fontSize: 11, fontWeight: FontWeight.w600, color: color), textAlign: TextAlign.center),
    );
  }
}
