import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/network_photo.dart';
import '../providers/admin_categories_provider.dart';
import '../widgets/image_upload_field.dart';
import '../widgets/admin_load_error.dart';
import '../admin_language.dart';
import '../ui/admin_kit.dart';

class AdminCategoriesScreen extends ConsumerStatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  ConsumerState<AdminCategoriesScreen> createState() =>
      _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends ConsumerState<AdminCategoriesScreen> {
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

    return Column(
      children: [
        // ─── Toolbar ───
        AdminListToolbar(
          search: AdminSearchField(
            controller: _searchController,
            width: isWide ? 320 : 200,
            hint: tr('חיפוש קטגוריה...', 'Search categories...'),
            onChanged: (v) => _debouncer.run(() {
              ref
                  .read(adminCategoryListProvider.notifier)
                  .setSearch(v.isEmpty ? null : v);
            }),
          ),
          filters: [
            AdminFilterChip(tr('הכל', 'All'), _scopeFilter.isEmpty, () {
              setState(() => _scopeFilter = '');
              ref
                  .read(adminCategoryListProvider.notifier)
                  .setScopeFilter(null);
            }),
            AdminFilterChip(tr('עסקים', 'Businesses'), _scopeFilter == 'business', () {
              setState(() => _scopeFilter = 'business');
              ref
                  .read(adminCategoryListProvider.notifier)
                  .setScopeFilter('business');
            }),
            AdminFilterChip(tr('כתבות', 'Articles'), _scopeFilter == 'article', () {
              setState(() => _scopeFilter = 'article');
              ref
                  .read(adminCategoryListProvider.notifier)
                  .setScopeFilter('article');
            }),
            AdminFilterChip(tr('אירועים', 'Events'), _scopeFilter == 'event', () {
              setState(() => _scopeFilter = 'event');
              ref
                  .read(adminCategoryListProvider.notifier)
                  .setScopeFilter('event');
            }),
            const SizedBox(width: 8),
            // Job categories (00052): the trades the Post a Job form offers.
            AdminFilterChip(tr('משרות', 'Jobs'), _scopeFilter == 'job', () {
              setState(() => _scopeFilter = 'job');
              ref
                  .read(adminCategoryListProvider.notifier)
                  .setScopeFilter('job');
            }),
          ],
          // `valueOrNull`, not `whenData(...).value`: the latter rethrows
          // on a failed load and greys the whole section instead of letting
          // the list below show the error and a retry.
          count: switch (async.valueOrNull) {
            final list? => tr('${list.length} קטגוריות', '${list.length} categories'),
            null => null,
          },
          actions: [
            AdminToolbarButton(
              label: tr('קטגוריה חדשה', 'New category'),
              onPressed: () => _showEditor(context, ref),
            ),
          ],
        ),

        // ─── Table ───
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => AdminLoadError(
              message: tr('שגיאה בטעינת הקטגוריות', 'Error loading the categories'),
              error: e,
              onRetry: () =>
                  ref.read(adminCategoryListProvider.notifier).load(),
            ),
            data: (categories) {
              if (categories.isEmpty) {
                return Center(
                  child: Text(
                    tr('אין קטגוריות', 'No categories'),
                    style: TextStyle(
                      fontFamily: AppFonts.rubik,
                      color: AppColors.grayText,
                    ),
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
                        _Col(tr('שם', 'Name'), flex: 3),
                        _Col(tr('שיוך', 'Scope'), flex: 1),
                        if (isWide) _Col(tr('פריטים', 'Items'), flex: 1),
                        if (isWide) _Col(tr('סדר', 'Order'), flex: 1),
                        _Col(tr('סטטוס', 'Status'), flex: 1),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: AppColors.border.withValues(alpha: 0.3),
                      ),
                      itemBuilder: (_, i) {
                        final c = categories[i];
                        final isChild = c['parent_id'] != null;
                        final active = c['is_active'] as bool? ?? true;
                        final scope = c['scope'] as String? ?? '';
                        final icon = c['icon'] as String? ?? '';

                        return InkWell(
                          onTap: () => _showEditor(context, ref, category: c),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Row(
                                    children: [
                                      // A child is indented inside the name
                                      // cell only, so the columns after it
                                      // stay in line with its parent's.
                                      if (isChild) const SizedBox(width: 24),
                                      // The picture the site's category
                                      // tiles show, when it has one.
                                      if ((c['image_url'] as String? ?? '')
                                          .isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 8,
                                          ),
                                          child: NetworkPhoto(
                                            url: c['image_url'] as String,
                                            width: 32,
                                            height: 32,
                                            radius: BorderRadius.circular(4),
                                            icon: Icons.image_outlined,
                                            iconSize: 14,
                                          ),
                                        ),
                                      if (icon.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 8,
                                          ),
                                          child: Text(
                                            icon,
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      Flexible(
                                        child: Text(
                                          c['name'] as String? ?? '',
                                          style: TextStyle(
                                            fontFamily: AppFonts.rubik,
                                            fontSize: 14,
                                            fontWeight: isChild
                                                ? FontWeight.w400
                                                : FontWeight.w600,
                                            color: AppColors.navy,
                                          ),
                                        ),
                                      ),
                                      // The English name, when it has one.
                                      if ((c['name_en'] as String?)?.trim().isNotEmpty ?? false)
                                        Flexible(
                                          child: Text(
                                            '  ·  ${(c['name_en'] as String).trim()}',
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: AppFonts.rubik,
                                              fontSize: 13,
                                              color: AppColors.grayMeta,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Expanded(flex: 1, child: _ScopePill(scope)),
                                if (isWide)
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      '${AdminCategoryListNotifier.itemCount(c)}',
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
                                      '${c['sort_order'] ?? 0}',
                                      style: TextStyle(
                                        fontFamily: AppFonts.rubik,
                                        fontSize: 13,
                                        color: AppColors.grayText,
                                      ),
                                    ),
                                  ),
                                Expanded(
                                  flex: 1,
                                  child: Align(
                                    alignment: AlignmentDirectional.centerStart,
                                    child: AdminPill(
                                      active ? tr('פעיל', 'Active') : tr('מושבת', 'Disabled'),
                                      active
                                          ? AdminKit.of(context).success
                                          : AdminKit.of(context).muted,
                                    ),
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.more_vert,
                                    size: 18,
                                    color: AppColors.grayLight,
                                  ),
                                  onSelected: (v) => _handleAction(v, c),
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
                                    PopupMenuItem(
                                      value: 'toggle',
                                      child: Text(
                                        active ? tr('השבת', 'Disable') : tr('הפעל', 'Activate'),
                                        style: TextStyle(
                                          fontFamily: AppFonts.rubik,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    // A third item reading "delete" stood
                                    // here. It called setActive(id, false) —
                                    // exactly what the item above it does —
                                    // so the menu offered the same action
                                    // twice, once under a word that promised
                                    // something else. A category cannot be
                                    // removed outright without taking its
                                    // entity_categories links with it, which
                                    // is why hiding is the only action there
                                    // is.
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

  void _handleAction(String action, Map<String, dynamic> c) {
    final notifier = ref.read(adminCategoryListProvider.notifier);
    final id = c['id'] as String;
    switch (action) {
      case 'edit':
        _showEditor(context, ref, category: c);
      case 'toggle':
        runAdminAction(context, () => notifier.toggleActive(id));
    }
  }

  void _showEditor(
    BuildContext context,
    WidgetRef ref, {
    Map<String, dynamic>? category,
  }) {
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

class _CategoryEditorDialogState extends ConsumerState<_CategoryEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late final TextEditingController _name;
  late final TextEditingController _nameEn;
  late final TextEditingController _slug;
  late final TextEditingController _icon;
  late final TextEditingController _description;
  late final TextEditingController _sortOrder;
  late final TextEditingController _imageUrl;
  String _scope = 'business';

  /// Why the last save failed, shown in the dialog rather than behind it.
  String? _error;
  String? _parentId;
  bool _isActive = true;

  /// "Show in menus" (`in_menus`, migration 00047): off for the old site's
  /// lists that came back as categories, whose pages live at their old
  /// addresses but which are not categories to browse by.
  bool _inMenus = true;

  /// Whether the database has the column yet; until 00047 runs the field is
  /// neither shown nor saved, so a save cannot fail on it.
  bool get _hasInMenus =>
      widget.category?.containsKey('in_menus') ??
      (ref.read(adminCategoryListProvider).valueOrNull?.firstOrNull
              ?.containsKey('in_menus') ??
          false);

  /// The same for the English name, until 00062 runs.
  bool get _hasNameEn =>
      widget.category?.containsKey('name_en') ??
      (ref.read(adminCategoryListProvider).valueOrNull?.firstOrNull
              ?.containsKey('name_en') ??
          false);

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    final c = widget.category;
    _name = TextEditingController(text: c?['name'] as String? ?? '');
    _nameEn = TextEditingController(text: c?['name_en'] as String? ?? '');
    _slug = TextEditingController(text: c?['slug'] as String? ?? '');
    _icon = TextEditingController(text: c?['icon'] as String? ?? '');
    _description = TextEditingController(
      text: c?['description'] as String? ?? '',
    );
    _sortOrder = TextEditingController(
      text: (c?['sort_order'] as int?)?.toString() ?? '0',
    );
    _imageUrl = TextEditingController(text: c?['image_url'] as String? ?? '');
    _scope = c?['scope'] as String? ?? 'business';
    _parentId = c?['parent_id'] as String?;
    _isActive = c?['is_active'] as bool? ?? true;
    _inMenus = c?['in_menus'] as bool? ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _nameEn.dispose();
    _slug.dispose();
    _icon.dispose();
    _description.dispose();
    _sortOrder.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A category cannot sit under itself, and one that already has
    // children stays at the top: the site reads two levels, not three.
    final selfId = widget.category?['id'];
    final hasChildren =
        selfId != null &&
        (ref.watch(categoryHasChildrenProvider(selfId as String)).valueOrNull ??
            false);
    final parents =
        (ref.watch(categoryParentsProvider(_scope)).valueOrNull ??
                const <Map<String, dynamic>>[])
            .where((p) => p['id'] != selfId)
            .toList();

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 650),
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
                        _isEditing ? tr('עריכת קטגוריה', 'Edit category') : tr('קטגוריה חדשה', 'New category'),
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
                      _field(
                        tr('שם *', 'Name *'),
                        _name,
                        validator: (v) =>
                            v == null || v.isEmpty ? tr('שדה חובה', 'Required field') : null,
                      ),
                      // What the site and the app show with English chosen;
                      // empty, they show the Hebrew name.
                      if (_hasNameEn)
                        _field(tr('שם באנגלית', 'Name in English'), _nameEn),
                      _field(tr('Slug (ריק ייווצר מהשם)', 'Slug (left empty, it is made from the name)'), _slug),
                      _field(tr('אייקון (אמוג\'י)', 'Icon (emoji)'), _icon),
                      _field(tr('תיאור', 'Description'), _description, maxLines: 2),
                      // The picture on the site's category tiles — nine of
                      // them have one, and there was no way to set it here.
                      ImageUploadField(
                        label: tr('תמונה', 'Image'),
                        controller: _imageUrl,
                        folder: 'categories',
                      ),
                      const SizedBox(height: 14),
                      _field(tr('סדר מיון', 'Sort order'), _sortOrder),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _scope,
                        decoration: InputDecoration(
                          labelText: 'Scope',
                          labelStyle: TextStyle(
                            fontFamily: AppFonts.rubik,
                            fontSize: 13,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'business',
                            child: Text(
                              tr('עסקים', 'Businesses'),
                              style: TextStyle(
                                fontFamily: AppFonts.rubik,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'article',
                            child: Text(
                              tr('כתבות', 'Articles'),
                              style: TextStyle(
                                fontFamily: AppFonts.rubik,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'event',
                            child: Text(
                              tr('אירועים', 'Events'),
                              style: TextStyle(
                                fontFamily: AppFonts.rubik,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'job',
                            child: Text(
                              tr('משרות', 'Jobs'),
                              style: TextStyle(
                                fontFamily: AppFonts.rubik,
                                fontSize: 13,
                              ),
                            ),
                          ),
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
                          labelText: tr('קטגוריית אב', 'Parent category'),
                          labelStyle: TextStyle(
                            fontFamily: AppFonts.rubik,
                            fontSize: 13,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text(
                              tr('— ללא (קטגוריה ראשית) —', '— None (main category) —'),
                              style: TextStyle(
                                fontFamily: AppFonts.rubik,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          // The parent it has now, even if the picker's
                          // list has not arrived yet.
                          if (_parentId != null &&
                              !parents.any((p) => p['id'] == _parentId))
                            DropdownMenuItem(
                              value: _parentId,
                              child: Text(
                                '…',
                                style: TextStyle(
                                  fontFamily: AppFonts.rubik,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ...parents.map(
                            (p) => DropdownMenuItem(
                              value: p['id'] as String,
                              child: Text(
                                p['name'] as String,
                                style: TextStyle(
                                  fontFamily: AppFonts.rubik,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                        onChanged: hasChildren
                            ? null
                            : (v) => setState(() => _parentId = v),
                      ),
                      if (hasChildren)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            tr('לקטגוריה זו יש תתי־קטגוריות, ולכן היא נשארת ראשית.', 'This category has subcategories, so it stays a main category.'),
                            style: TextStyle(
                              fontFamily: AppFonts.rubik,
                              fontSize: 12,
                              color: AppColors.adminTextLight,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: Text(
                          tr('פעיל', 'Active'),
                          style: TextStyle(
                            fontFamily: AppFonts.rubik,
                            fontSize: 14,
                          ),
                        ),
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (_scope == 'business' && _hasInMenus)
                        SwitchListTile(
                          title: Text(
                            tr('מוצג בתפריטים', 'Shown in menus'),
                            style: TextStyle(
                              fontFamily: AppFonts.rubik,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            tr(
                              'כבוי: לעמוד יש כתובת משלו, אך הוא לא מופיע ברשימות הקטגוריות',
                              'Off: the page keeps its address but is left out of category lists',
                            ),
                            style: TextStyle(
                              fontFamily: AppFonts.rubik,
                              fontSize: 12,
                              color: AppColors.adminTextLight,
                            ),
                          ),
                          value: _inMenus,
                          onChanged: (v) => setState(() => _inMenus = v),
                          contentPadding: EdgeInsets.zero,
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
                      if (_error != null)
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(
                              fontFamily: AppFonts.rubik,
                              fontSize: 12,
                              color: AppColors.error,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      else
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
                          backgroundColor: AppColors.midBlue,
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
                                _isEditing ? tr('שמור', 'Save') : tr('צור קטגוריה', 'Create category'),
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

  /// A slug from the name when none was typed.
  static String _slugFrom(String name) => name
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N}\s-]', unicode: true), '')
      .replaceAll(RegExp(r'[\s-]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    if (_slug.text.trim().isEmpty) _slug.text = _slugFrom(_name.text);
    setState(() => _saving = true);

    final fields = <String, dynamic>{
      'name': _name.text.trim(),
      'slug': _slug.text.trim(),
      'icon': _icon.text.trim().isEmpty ? null : _icon.text.trim(),
      'description': _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
      'image_url': _imageUrl.text.trim().isEmpty ? null : _imageUrl.text.trim(),
      'sort_order': int.tryParse(_sortOrder.text.trim()) ?? 0,
      'scope': _scope,
      'parent_id': _parentId,
      'is_active': _isActive,
      if (_hasInMenus) 'in_menus': _scope != 'business' || _inMenus,
      if (_hasNameEn) 'name_en': _nameEn.text.trim().isEmpty ? null : _nameEn.text.trim(),
    };

    try {
      final notifier = ref.read(adminCategoryListProvider.notifier);
      if (_isEditing) {
        await notifier.updateCategory(widget.category!['id'] as String, fields);
      } else {
        await notifier.createCategory(fields);
      }
      ref.invalidate(categoryParentsProvider(_scope));
      ref.invalidate(categoryHasChildrenProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is PostgrestException && e.code == '23505'
              ? tr('השמירה נכשלה: ה-Slug כבר בשימוש בקטגוריה אחרת באותו תחום', 'Saving failed: the slug is already used by another category in the same scope')
              : tr('השמירה נכשלה: ${e is PostgrestException ? e.message : e}', 'Saving failed: ${e is PostgrestException ? e.message : e}'),
        );
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
      'business' => (tr('עסקים', 'Businesses'), AppColors.midBlue),
      'article' => (tr('כתבות', 'Articles'), AppColors.success),
      'event' => (tr('אירועים', 'Events'), AppColors.gold),
      'job' => (tr('משרות', 'Jobs'), AppColors.turquoise),
      _ => (scope, AppColors.grayLight),
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

class _Debouncer {
  final int milliseconds;
  _Debouncer({required this.milliseconds});

  Future<void>? _pending;

  void run(VoidCallback action) {
    _pending?.ignore();
    _pending = Future.delayed(
      Duration(milliseconds: milliseconds),
    ).then((_) => action());
  }
}
