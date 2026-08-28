import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/admin_home_builder_provider.dart';

class AdminHomeBuilderScreen extends ConsumerStatefulWidget {
  const AdminHomeBuilderScreen({super.key});

  @override
  ConsumerState<AdminHomeBuilderScreen> createState() => _AdminHomeBuilderScreenState();
}

class _AdminHomeBuilderScreenState extends ConsumerState<AdminHomeBuilderScreen> {
  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(adminHomeBuilderProvider);
    final isWide = MediaQuery.of(context).size.width > 900;

    return Column(children: [
      // ─── Stats bar ───
      asyncData.whenData((list) {
        final active = list.where((b) => b['is_active'] == true).length;
        final published = list.where((b) => b['published'] == true).length;
        final drafts = list.length - published;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
          ),
          child: Row(children: [
            _StatChip('סה"כ בלוקים', '${list.length}', AppColors.navy),
            const SizedBox(width: 16),
            _StatChip('פעילים', '$active', AppColors.success),
            const SizedBox(width: 16),
            _StatChip('מפורסמים', '$published', AppColors.turquoise),
            const SizedBox(width: 16),
            _StatChip('טיוטות', '$drafts', AppColors.gold),
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
          Icon(Icons.dashboard_customize, size: 20, color: AppColors.navy),
          const SizedBox(width: 8),
          Text('בונה מסך הבית', style: GoogleFonts.rubik(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.navy)),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () => ref.read(adminHomeBuilderProvider.notifier).publishAll(),
            icon: const Icon(Icons.publish, size: 16),
            label: Text('פרסם הכל', style: GoogleFonts.rubik(fontSize: 13)),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.success, side: const BorderSide(color: AppColors.success), minimumSize: const Size(0, 40), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: () => _showEditor(context, ref),
            icon: const Icon(Icons.add, size: 18),
            label: Text('בלוק חדש', style: GoogleFonts.rubik(fontSize: 13)),
            style: FilledButton.styleFrom(backgroundColor: AppColors.turquoise, minimumSize: const Size(0, 40), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          ),
        ]),
      ),

      // ─── Block List ───
      Expanded(
        child: asyncData.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('שגיאה: $e', style: GoogleFonts.rubik(color: AppColors.error))),
          data: (list) {
            if (list.isEmpty) {
              return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.dashboard_customize_outlined, size: 48, color: AppColors.grayLight.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text('אין בלוקים', style: GoogleFonts.rubik(color: AppColors.grayText)),
              ]));
            }
            return ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: list.length,
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) newIndex--;
                final blockId = list[oldIndex]['id'] as String;
                ref.read(adminHomeBuilderProvider.notifier).reorder(blockId, newIndex + 1);
              },
              itemBuilder: (_, i) {
                final b = list[i];
                final isActive = b['is_active'] as bool? ?? false;
                final isPublished = b['published'] as bool? ?? false;
                final blockType = b['block_type'] as String? ?? '';
                final version = b['version'] as int? ?? 1;

                return Container(
                  key: ValueKey(b['id']),
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isActive ? AppColors.turquoise.withValues(alpha: 0.3) : AppColors.border.withValues(alpha: 0.5)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.drag_indicator, size: 20, color: AppColors.grayLight),
                      Text('#${b['sort_order']}', style: GoogleFonts.rubik(fontSize: 10, color: AppColors.grayLight)),
                    ]),
                    title: Row(children: [
                      Icon(_blockIcon(blockType), size: 20, color: isActive ? AppColors.turquoise : AppColors.grayLight),
                      const SizedBox(width: 8),
                      Expanded(child: Text(b['title'] as String? ?? '', style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy))),
                    ]),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.navy.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(4)),
                          child: Text(blockType, style: GoogleFonts.rubik(fontSize: 10, color: AppColors.navy)),
                        ),
                        const SizedBox(width: 8),
                        Text('v$version', style: GoogleFonts.rubik(fontSize: 10, color: AppColors.grayLight)),
                        const SizedBox(width: 8),
                        if (isPublished)
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.check_circle, size: 12, color: AppColors.success),
                            const SizedBox(width: 3),
                            Text('מפורסם', style: GoogleFonts.rubik(fontSize: 10, color: AppColors.success)),
                          ])
                        else
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.edit_note, size: 12, color: AppColors.gold),
                            const SizedBox(width: 3),
                            Text('טיוטה', style: GoogleFonts.rubik(fontSize: 10, color: AppColors.gold)),
                          ]),
                        if (isWide && b['audience'] != null) ...[
                          const SizedBox(width: 12),
                          Text('קהל: ${b['audience']}', style: GoogleFonts.rubik(fontSize: 10, color: AppColors.grayLight)),
                        ],
                      ]),
                    ),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      Switch(
                        value: isActive,
                        activeColor: AppColors.turquoise,
                        onChanged: (_) => ref.read(adminHomeBuilderProvider.notifier).toggleActive(b['id'] as String),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 18, color: AppColors.grayLight),
                        onSelected: (v) => _handleAction(v, b),
                        itemBuilder: (_) => [
                          PopupMenuItem(value: 'edit', child: Text('עריכה', style: GoogleFonts.rubik(fontSize: 13))),
                          PopupMenuItem(value: 'delete', child: Text('מחיקה', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.error))),
                        ],
                      ),
                    ]),
                  ),
                );
              },
            );
          },
        ),
      ),
    ]);
  }

  IconData _blockIcon(String type) => switch (type) {
    'hero_banner' => Icons.view_carousel,
    'categories_grid' => Icons.grid_view,
    'featured_businesses' => Icons.store,
    'upcoming_events' => Icons.event,
    'deals' => Icons.local_offer,
    'latest_articles' => Icons.article,
    'map_preview' => Icons.map,
    'stats_bar' => Icons.bar_chart,
    _ => Icons.widgets,
  };

  void _handleAction(String action, Map<String, dynamic> b) {
    switch (action) {
      case 'edit': _showEditor(context, ref, block: b);
      case 'delete': ref.read(adminHomeBuilderProvider.notifier).deleteBlock(b['id'] as String);
    }
  }

  void _showEditor(BuildContext context, WidgetRef ref, {Map<String, dynamic>? block}) {
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => _BlockEditorDialog(block: block));
  }
}

// ─── Editor Dialog ───

class _BlockEditorDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? block;
  const _BlockEditorDialog({this.block});

  @override
  ConsumerState<_BlockEditorDialog> createState() => _BlockEditorDialogState();
}

class _BlockEditorDialogState extends ConsumerState<_BlockEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late final TextEditingController _title;
  late final TextEditingController _sortOrder;
  String _blockType = 'hero_banner';
  String _audience = 'all';
  bool _isActive = true;

  final _blockTypes = <String, String>{
    'hero_banner': 'באנר ראשי',
    'categories_grid': 'רשת קטגוריות',
    'featured_businesses': 'עסקים מומלצים',
    'upcoming_events': 'אירועים קרובים',
    'deals': 'מבצעים',
    'latest_articles': 'חדשות אחרונות',
    'map_preview': 'מפת העיר',
    'stats_bar': 'מספרים',
  };

  bool get _isEditing => widget.block != null;

  @override
  void initState() {
    super.initState();
    final b = widget.block;
    _title = TextEditingController(text: b?['title'] as String? ?? '');
    _sortOrder = TextEditingController(text: (b?['sort_order'] as int?)?.toString() ?? '');
    _blockType = b?['block_type'] as String? ?? 'hero_banner';
    _audience = b?['audience'] as String? ?? 'all';
    _isActive = b?['is_active'] as bool? ?? true;
  }

  @override
  void dispose() {
    _title.dispose(); _sortOrder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 520),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Form(
            key: _formKey,
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
                child: Row(children: [
                  Text(_isEditing ? 'עריכת בלוק' : 'בלוק חדש', style: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
                ]),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _buildField('כותרת', _title, hint: 'עסקים מומלצים', validator: (v) => v == null || v.isEmpty ? 'שדה חובה' : null),
                    const SizedBox(height: 14),
                    _buildDropdown('סוג בלוק', _blockType, _blockTypes, (v) => setState(() => _blockType = v!)),
                    const SizedBox(height: 14),
                    _buildField('סדר', _sortOrder, hint: '1', keyboardType: TextInputType.number),
                    const SizedBox(height: 14),
                    _buildDropdown('קהל יעד', _audience, {'all': 'כולם', 'new_users': 'משתמשים חדשים', 'returning': 'חוזרים'}, (v) => setState(() => _audience = v!)),
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
    final notifier = ref.read(adminHomeBuilderProvider.notifier);
    final data = {
      'title': _title.text.trim(),
      'block_type': _blockType,
      'sort_order': int.tryParse(_sortOrder.text) ?? 99,
      'audience': _audience,
      'is_active': _isActive,
      'config': {},
    };
    if (_isEditing) {
      await notifier.updateBlock(widget.block!['id'] as String, data);
    } else {
      await notifier.createBlock(data);
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
