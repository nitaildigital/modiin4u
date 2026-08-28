import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/admin_campaigns_provider.dart';

class AdminCampaignsScreen extends ConsumerStatefulWidget {
  const AdminCampaignsScreen({super.key});

  @override
  ConsumerState<AdminCampaignsScreen> createState() => _AdminCampaignsScreenState();
}

class _AdminCampaignsScreenState extends ConsumerState<AdminCampaignsScreen> {
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
    final asyncData = ref.watch(adminCampaignListProvider);
    final isWide = MediaQuery.of(context).size.width > 900;

    return Column(children: [
      // ─── Stats bar ───
      asyncData.whenData((list) {
        final active = list.where((c) => c['status'] == 'active').length;
        final totalImpressions = list.fold<int>(0, (s, c) => s + ((c['impressions'] as int?) ?? 0));
        final totalClicks = list.fold<int>(0, (s, c) => s + ((c['clicks'] as int?) ?? 0));
        final ctr = totalImpressions > 0 ? (totalClicks / totalImpressions * 100) : 0.0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
          ),
          child: Row(children: [
            _StatChip('קמפיינים פעילים', '$active', AppColors.success),
            const SizedBox(width: 16),
            _StatChip('חשיפות', _formatNumber(totalImpressions), AppColors.turquoise),
            const SizedBox(width: 16),
            _StatChip('קליקים', _formatNumber(totalClicks), AppColors.navy),
            const SizedBox(width: 16),
            _StatChip('CTR ממוצע', '${ctr.toStringAsFixed(1)}%', AppColors.gold),
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
                hintText: 'חיפוש קמפיין...',
                hintStyle: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayLight),
                prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.grayLight),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.turquoise)),
              ),
              onChanged: (v) => _debouncer.run(() {
                ref.read(adminCampaignListProvider.notifier).setSearch(v.isEmpty ? null : v);
              }),
            ),
          ),
          const SizedBox(width: 12),
          _FilterChip('הכל', _statusFilter.isEmpty, () { setState(() => _statusFilter = ''); ref.read(adminCampaignListProvider.notifier).setStatusFilter(null); }),
          _FilterChip('פעיל', _statusFilter == 'active', () { setState(() => _statusFilter = 'active'); ref.read(adminCampaignListProvider.notifier).setStatusFilter('active'); }),
          _FilterChip('מתוכנן', _statusFilter == 'scheduled', () { setState(() => _statusFilter = 'scheduled'); ref.read(adminCampaignListProvider.notifier).setStatusFilter('scheduled'); }),
          _FilterChip('מושהה', _statusFilter == 'paused', () { setState(() => _statusFilter = 'paused'); ref.read(adminCampaignListProvider.notifier).setStatusFilter('paused'); }),
          const Spacer(),
          asyncData.whenData((list) => Text('${list.length} קמפיינים', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText))).value ?? const SizedBox.shrink(),
          const SizedBox(width: 16),
          FilledButton.icon(
            onPressed: () => _showEditor(context, ref),
            icon: const Icon(Icons.add, size: 18),
            label: Text('קמפיין חדש', style: GoogleFonts.rubik(fontSize: 13)),
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
                Icon(Icons.campaign_outlined, size: 48, color: AppColors.grayLight.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text('אין קמפיינים', style: GoogleFonts.rubik(color: AppColors.grayText)),
              ]));
            }
            return Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(color: AppColors.surfaceLight, border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5)))),
                child: Row(children: [
                  _Col('קמפיין', flex: 3),
                  _Col('מיקום', flex: 2),
                  if (isWide) _Col('חשיפות', flex: 1),
                  if (isWide) _Col('קליקים', flex: 1),
                  if (isWide) _Col('CTR', flex: 1),
                  _Col('סטטוס', flex: 1),
                  const SizedBox(width: 40),
                ]),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.border.withValues(alpha: 0.3)),
                  itemBuilder: (_, i) {
                    final c = list[i];
                    final status = c['status'] as String? ?? 'draft';
                    final impressions = c['impressions'] as int? ?? 0;
                    final clicks = c['clicks'] as int? ?? 0;
                    final ctr = impressions > 0 ? (clicks / impressions * 100) : 0.0;

                    return InkWell(
                      onTap: () => _showEditor(context, ref, campaign: c),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Row(children: [
                          Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(c['name'] as String? ?? '', style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy)),
                            Text(c['business_name'] as String? ?? '', style: GoogleFonts.rubik(fontSize: 11, color: AppColors.grayLight)),
                          ])),
                          Expanded(flex: 2, child: Text(c['placement_label'] as String? ?? '', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText))),
                          if (isWide) Expanded(flex: 1, child: Text(_formatNumber(impressions), style: GoogleFonts.rubik(fontSize: 13, fontFeatures: [const FontFeature.tabularFigures()]))),
                          if (isWide) Expanded(flex: 1, child: Text(_formatNumber(clicks), style: GoogleFonts.rubik(fontSize: 13, fontFeatures: [const FontFeature.tabularFigures()]))),
                          if (isWide) Expanded(flex: 1, child: Text('${ctr.toStringAsFixed(1)}%', style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w600, color: ctr > 3 ? AppColors.success : AppColors.grayText))),
                          Expanded(flex: 1, child: _StatusPill(status)),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 18, color: AppColors.grayLight),
                            onSelected: (v) => _handleAction(v, c),
                            itemBuilder: (_) => [
                              PopupMenuItem(value: 'edit', child: Text('עריכה', style: GoogleFonts.rubik(fontSize: 13))),
                              if (status != 'active') PopupMenuItem(value: 'activate', child: Text('הפעל', style: GoogleFonts.rubik(fontSize: 13))),
                              if (status == 'active') PopupMenuItem(value: 'pause', child: Text('השהה', style: GoogleFonts.rubik(fontSize: 13))),
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

  String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  void _handleAction(String action, Map<String, dynamic> c) {
    final notifier = ref.read(adminCampaignListProvider.notifier);
    final id = c['id'] as String;
    switch (action) {
      case 'edit': _showEditor(context, ref, campaign: c);
      case 'activate': notifier.updateStatus(id, 'active');
      case 'pause': notifier.updateStatus(id, 'paused');
      case 'delete': notifier.deleteCampaign(id);
    }
  }

  void _showEditor(BuildContext context, WidgetRef ref, {Map<String, dynamic>? campaign}) {
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => _CampaignEditorDialog(campaign: campaign));
  }
}

// ─── Editor Dialog ───

class _CampaignEditorDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? campaign;
  const _CampaignEditorDialog({this.campaign});

  @override
  ConsumerState<_CampaignEditorDialog> createState() => _CampaignEditorDialogState();
}

class _CampaignEditorDialogState extends ConsumerState<_CampaignEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late final TextEditingController _name;
  late final TextEditingController _businessName;
  late final TextEditingController _businessId;
  late final TextEditingController _placementLabel;
  late final TextEditingController _placementId;
  late final TextEditingController _destinationUrl;
  late final TextEditingController _startAt;
  late final TextEditingController _endAt;
  late final TextEditingController _priority;
  late final TextEditingController _frequencyCap;
  late final TextEditingController _salesperson;
  String _status = 'draft';
  String _targetAudience = 'all';

  bool get _isEditing => widget.campaign != null;

  @override
  void initState() {
    super.initState();
    final c = widget.campaign;
    _name = TextEditingController(text: c?['name'] as String? ?? '');
    _businessName = TextEditingController(text: c?['business_name'] as String? ?? '');
    _businessId = TextEditingController(text: c?['business_id'] as String? ?? '');
    _placementLabel = TextEditingController(text: c?['placement_label'] as String? ?? '');
    _placementId = TextEditingController(text: c?['placement_id'] as String? ?? '');
    _destinationUrl = TextEditingController(text: c?['destination_url'] as String? ?? '');
    _startAt = TextEditingController(text: c?['start_at'] as String? ?? '');
    _endAt = TextEditingController(text: c?['end_at'] as String? ?? '');
    _priority = TextEditingController(text: (c?['priority'] as int?)?.toString() ?? '5');
    _frequencyCap = TextEditingController(text: (c?['frequency_cap'] as int?)?.toString() ?? '');
    _salesperson = TextEditingController(text: c?['salesperson'] as String? ?? '');
    _status = c?['status'] as String? ?? 'draft';
    _targetAudience = c?['target_audience'] as String? ?? 'all';
  }

  @override
  void dispose() {
    _name.dispose(); _businessName.dispose(); _businessId.dispose();
    _placementLabel.dispose(); _placementId.dispose(); _destinationUrl.dispose();
    _startAt.dispose(); _endAt.dispose();
    _priority.dispose(); _frequencyCap.dispose(); _salesperson.dispose();
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
                  Text(_isEditing ? 'עריכת קמפיין' : 'קמפיין חדש', style: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
                ]),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _buildField('שם קמפיין', _name, hint: 'פיצה פרגו — 20% הנחה', validator: (v) => v == null || v.isEmpty ? 'שדה חובה' : null),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(child: _buildField('עסק', _businessName, hint: 'פיצה פרגו')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildField('מיקום פרסום', _placementLabel, hint: 'ראש עמוד הבית')),
                    ]),
                    const SizedBox(height: 14),
                    _buildField('קישור יעד', _destinationUrl, hint: 'https://...'),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(child: _buildField('תחילת קמפיין', _startAt, hint: '2026-09-01')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildField('סיום קמפיין', _endAt, hint: '2026-09-30')),
                    ]),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(child: _buildField('עדיפות', _priority, hint: '1-10', keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildField('תדירות מקסימלית', _frequencyCap, hint: 'חשיפות ליום', keyboardType: TextInputType.number)),
                    ]),
                    const SizedBox(height: 14),
                    _buildField('איש מכירות', _salesperson, hint: 'שם מלא'),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(child: _buildDropdown('סטטוס', _status, {'draft': 'טיוטה', 'active': 'פעיל', 'scheduled': 'מתוכנן', 'paused': 'מושהה', 'ended': 'הסתיים'}, (v) => setState(() => _status = v!))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildDropdown('קהל יעד', _targetAudience, {'all': 'כולם', 'new': 'משתמשים חדשים', 'returning': 'חוזרים'}, (v) => setState(() => _targetAudience = v!))),
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
    final notifier = ref.read(adminCampaignListProvider.notifier);
    final data = {
      'name': _name.text.trim(),
      'business_name': _businessName.text.trim(),
      'business_id': _businessId.text.trim(),
      'placement_label': _placementLabel.text.trim(),
      'placement_id': _placementId.text.trim(),
      'destination_url': _destinationUrl.text.trim(),
      'start_at': _startAt.text.trim(),
      'end_at': _endAt.text.trim(),
      'priority': int.tryParse(_priority.text) ?? 5,
      'frequency_cap': int.tryParse(_frequencyCap.text),
      'salesperson': _salesperson.text.trim(),
      'status': _status,
      'target_audience': _targetAudience,
    };
    if (_isEditing) {
      await notifier.updateCampaign(widget.campaign!['id'] as String, data);
    } else {
      await notifier.createCampaign(data);
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
      'paused' => ('מושהה', AppColors.gold),
      'ended' => ('הסתיים', AppColors.grayText),
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
