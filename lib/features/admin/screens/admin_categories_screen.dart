import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/admin_categories_provider.dart';

class AdminCategoriesScreen extends ConsumerStatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  ConsumerState<AdminCategoriesScreen> createState() =>
      _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState
    extends ConsumerState<AdminCategoriesScreen> {
  String _scopeFilter = '';
  final _searchController = TextEditingController();
  final _debouncer = _Debouncer(milliseconds: 400);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminCategoryListProvider);
    final isWide = MediaQuery.of(context).size.width > 900;

    return Column(children: [
      // ─── Toolbar ───
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
              bottom:
                  BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
        ),
        child: Row(children: [
          SizedBox(
            width: isWide ? 320 : 200,
            height: 40,
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.rubik(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'חיפוש קטגוריה...',
                hintStyle:
                    GoogleFonts.rubik(fontSize: 13, color: AppColors.grayLight),
                prefixIcon:
                    const Icon(Icons.search, size: 18, color: AppColors.grayLight),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.turquoise)),
              ),
              onChanged: (v) => _debouncer.run(() {
                ref
                    .read(adminCategoryListProvider.notifier)
                    .setSearch(v.isEmpty ? null : v);
              }),
            ),
          ),
          const SizedBox(width: 12),
          _FilterChip('הכל', _scopeFilter.isEmpty, () {
            setState(() => _scopeFilter = '');
            ref.read(adminCategoryListProvider.notifier).setScopeFilter(null);
          }),
          _FilterChip('עסקים', _scopeFilter == 'business', () {
            setState(() => _scopeFilter = 'business');
            ref
                .read(adminCategoryListProvider.notifier)
                .setScopeFilter('business');
          }),
          _FilterChip('כתבות', _scopeFilter == 'article', () {
            setState(() => _scopeFilter = 'article');
            ref
                .read(adminCategoryListProvider.notifier)
                .setScopeFilter('article');
          }),
          _FilterChip('אירועים', _scopeFilter == 'event', () {
            setState(() => _scopeFilter = 'event');
            ref
                .read(adminCategoryListProvider.notifier)
                .setScopeFilter('event');
          }),
          const Spacer(),
          async
                  .whenData((list) => Text('${list.length} קטגוריות',
                      style: GoogleFonts.rubik(
                          fontSize: 13, color: AppColors.grayText)))
                  .value ??
              const SizedBox.shrink(),
          const SizedBox(width: 16),
          FilledButton.icon(
            onPressed: () => _showEditor(context, ref),
            icon: const Icon(Icons.add, size: 18),
            label:
                Text('קטגוריה חדשה', style: GoogleFonts.rubik(fontSize: 13)),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.turquoise,
              minimumSize: const Size(0, 40),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ]),
      ),

      // ─── Table ───
      Expanded(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
              child: Text('שגיאה: $e',
                  style: GoogleFonts.rubik(color: AppColors.error))),
          data: (categories) {
            if (categories.isEmpty) {
              return Center(
                  child: Text('אין קטגוריות',
                      style: GoogleFonts.rubik(color: AppColors.grayText)));
            }
            return Column(children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    border: Border(
                        bottom: BorderSide(
                            color:
                                AppColors.border.withValues(alpha: 0.5)))),
                child: Row(children: [
                  _Col('שם', flex: 3),
                  _Col('scope', flex: 1),
                  if (isWide) _Col('פריטים', flex: 1),
                  if (isWide) _Col('סדר', flex: 1),
                  _Col('סטטוס', flex: 1),
                  const SizedBox(width: 40),
                ]),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: AppColors.border.withValues(alpha: 0.3)),
                  itemBuilder: (_, i) {
                    final c = categories[i];
                    final isChild = c['parent_id'] != null;
                    final active = c['is_active'] as bool? ?? true;
                    final scope = c['scope'] as String? ?? '';
                    final icon = c['icon'] as String? ?? '';

                    return InkWell(
                      onTap: () =>
                          _showEditor(context, ref, category: c),
                      child: Container(
                        padding: EdgeInsets.only(
                          right: isChild ? 44 : 20,
                          left: 20,
                          top: 10,
                          bottom: 10,
                        ),
                        child: Row(children: [
                          Expanded(
                              flex: 3,
                              child: Row(children: [
                                if (icon.isNotEmpty)
                                  Padding(
                                      padding:
                                          const EdgeInsets.only(left: 8),
                                      child: Text(icon,
                                          style: const TextStyle(
                                              fontSize: 16))),
                                Flexible(
                                  child: Text(
                                      c['name'] as String? ?? '',
                                      style: GoogleFonts.rubik(
                                          fontSize: 14,
                                          fontWeight: isChild
                                              ? FontWeight.w400
                                              : FontWeight.w600,
                                          color: AppColors.navy)),
                                ),
                              ])),
                          Expanded(
                              flex: 1,
                              child: _ScopePill(scope)),
                          if (isWide)
                            Expanded(
                                flex: 1,
                                child: Text(
                                    '${c['item_count'] ?? 0}',
                                    style: GoogleFonts.rubik(
                                        fontSize: 13,
                                        color: AppColors.grayText))),
                          if (isWide)
                            Expanded(
                                flex: 1,
                                child: Text(
                                    '${c['sort_order'] ?? 0}',
                                    style: GoogleFonts.rubik(
                                        fontSize: 13,
                                        color: AppColors.grayText))),
                          Expanded(
                              flex: 1,
                              child: _StatusPill(
                                  active ? 'פעיל' : 'מושבת',
                                  active
                                      ? AppColors.success
                                      : AppColors.grayLight)),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert,
                                size: 18, color: AppColors.grayLight),
                            onSelected: (v) =>
                                _handleAction(v, c),
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                  value: 'edit',
                                  child: Text('עריכה',
                                      style: GoogleFonts.rubik(
                                          fontSize: 13))),
                              PopupMenuItem(
                                  value: 'toggle',
                                  child: Text(
                                      active ? 'השבת' : 'הפעל',
                                      style: GoogleFonts.rubik(
                                          fontSize: 13))),
                              PopupMenuItem(
                                  value: 'delete',
                                  child: Text('מחק',
                                      style: GoogleFonts.rubik(
                                          fontSize: 13,
                                          color: AppColors.error))),
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

  void _handleAction(String action, Map<String, dynamic> c) {
    final notifier = ref.read(adminCategoryListProvider.notifier);
    final id = c['id'] as String;
    switch (action) {
      case 'edit':
        _showEditor(context, ref, category: c);
      case 'toggle':
        notifier.toggleActive(id);
      case 'delete':
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('מחיקת קטגוריה',
                style: GoogleFonts.rubik(fontWeight: FontWeight.w700)),
            content: Text('למחוק את "${c['name']}"? כל תת-הקטגוריות יימחקו גם.',
                style: GoogleFonts.rubik()),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('ביטול', style: GoogleFonts.rubik())),
              TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    notifier.deleteCategory(id);
                  },
                  child: Text('מחק',
                      style: GoogleFonts.rubik(color: AppColors.error))),
            ],
          ),
        );
    }
  }

  void _showEditor(BuildContext context, WidgetRef ref,
      {Map<String, dynamic>? category}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _CategoryEditorDialog(category: category),
    );
  }
}

// ─── Editor Dialog ───

class _CategoryEditorDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? category;
  const _CategoryEditorDialog({this.category});

  @override
  ConsumerState<_CategoryEditorDialog> createState() =>
      _CategoryEditorDialogState();
}

class _CategoryEditorDialogState
    extends ConsumerState<_CategoryEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late final TextEditingController _name;
  late final TextEditingController _slug;
  late final TextEditingController _icon;
  late final TextEditingController _description;
  late final TextEditingController _sortOrder;
  String _scope = 'business';
  String? _parentId;
  bool _isActive = true;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    final c = widget.category;
    _name = TextEditingController(text: c?['name'] as String? ?? '');
    _slug = TextEditingController(text: c?['slug'] as String? ?? '');
    _icon = TextEditingController(text: c?['icon'] as String? ?? '');
    _description =
        TextEditingController(text: c?['description'] as String? ?? '');
    _sortOrder = TextEditingController(
        text: (c?['sort_order'] as int?)?.toString() ?? '0');
    _scope = c?['scope'] as String? ?? 'business';
    _parentId = c?['parent_id'] as String?;
    _isActive = c?['is_active'] as bool? ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _slug.dispose();
    _icon.dispose();
    _description.dispose();
    _sortOrder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parents = ref
        .read(adminCategoryListProvider.notifier)
        .getParentsForScope(_scope);

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 650),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Form(
            key: _formKey,
            child: Column(children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                    color: AppColors.navy,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(14))),
                child: Row(children: [
                  Text(_isEditing ? 'עריכת קטגוריה' : 'קטגוריה חדשה',
                      style: GoogleFonts.rubik(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  const Spacer(),
                  IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context)),
                ]),
              ),
              Expanded(
                child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _field('שם *', _name,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'שדה חובה' : null),
                      _field('Slug *', _slug,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'שדה חובה' : null),
                      _field('אייקון (אמוג\'י)', _icon),
                      _field('תיאור', _description, maxLines: 2),
                      _field('סדר מיון', _sortOrder),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _scope,
                        decoration: InputDecoration(
                            labelText: 'Scope',
                            labelStyle: GoogleFonts.rubik(fontSize: 13),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10)),
                        items: [
                          DropdownMenuItem(
                              value: 'business',
                              child: Text('עסקים',
                                  style: GoogleFonts.rubik(fontSize: 13))),
                          DropdownMenuItem(
                              value: 'article',
                              child: Text('כתבות',
                                  style: GoogleFonts.rubik(fontSize: 13))),
                          DropdownMenuItem(
                              value: 'event',
                              child: Text('אירועים',
                                  style: GoogleFonts.rubik(fontSize: 13))),
                        ],
                        onChanged: (v) => setState(() {
                          _scope = v!;
                          _parentId = null;
                        }),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String?>(
                        value: _parentId,
                        decoration: InputDecoration(
                            labelText: 'קטגוריית אב',
                            labelStyle: GoogleFonts.rubik(fontSize: 13),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10)),
                        items: [
                          DropdownMenuItem(
                              value: null,
                              child: Text('— ללא (קטגוריה ראשית) —',
                                  style: GoogleFonts.rubik(fontSize: 13))),
                          ...parents.map((p) => DropdownMenuItem(
                              value: p['id'] as String,
                              child: Text(p['name'] as String,
                                  style: GoogleFonts.rubik(fontSize: 13)))),
                        ],
                        onChanged: (v) => setState(() => _parentId = v),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: Text('פעיל',
                            style: GoogleFonts.rubik(fontSize: 14)),
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                        activeColor: AppColors.turquoise,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ]),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.border))),
                child: Row(children: [
                  const Spacer(),
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('ביטול', style: GoogleFonts.rubik())),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.turquoise,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(_isEditing ? 'שמור' : 'צור קטגוריה',
                            style: GoogleFonts.rubik(
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller,
      {int maxLines = 1, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        style: GoogleFonts.rubik(fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.rubik(fontSize: 13),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final fields = <String, dynamic>{
      'name': _name.text,
      'slug': _slug.text,
      'icon': _icon.text.isEmpty ? null : _icon.text,
      'description': _description.text.isEmpty ? null : _description.text,
      'sort_order': int.tryParse(_sortOrder.text) ?? 0,
      'scope': _scope,
      'parent_id': _parentId,
      'is_active': _isActive,
    };

    try {
      final notifier = ref.read(adminCategoryListProvider.notifier);
      if (_isEditing) {
        await notifier.updateCategory(
            widget.category!['id'] as String, fields);
      } else {
        await notifier.createCategory(fields);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('שגיאה: $e'),
            backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ─── Shared Widgets ───

class _ScopePill extends StatelessWidget {
  final String scope;
  const _ScopePill(this.scope);

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (scope) {
      'business' => ('עסקים', AppColors.turquoise),
      'article' => ('כתבות', AppColors.success),
      'event' => ('אירועים', AppColors.gold),
      _ => (scope, AppColors.grayLight),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: GoogleFonts.rubik(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: GoogleFonts.rubik(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
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
        child: Text(label,
            style: GoogleFonts.rubik(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.grayLight)));
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
            color: selected
                ? AppColors.turquoise.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
                color: selected ? AppColors.turquoise : AppColors.border,
                width: 0.5),
          ),
          child: Text(label,
              style: GoogleFonts.rubik(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color:
                      selected ? AppColors.turquoise : AppColors.grayText)),
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
    _pending = Future.delayed(Duration(milliseconds: milliseconds))
        .then((_) => action());
  }
}
