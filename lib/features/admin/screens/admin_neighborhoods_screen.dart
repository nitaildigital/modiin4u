import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show PostgrestException, StorageException;
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/network_photo.dart';
import '../providers/admin_neighborhoods_provider.dart';
import '../widgets/admin_gallery_editor.dart';
import '../widgets/image_upload_field.dart';

class AdminNeighborhoodsScreen extends ConsumerStatefulWidget {
  const AdminNeighborhoodsScreen({super.key});

  @override
  ConsumerState<AdminNeighborhoodsScreen> createState() =>
      _AdminNeighborhoodsScreenState();
}

class _AdminNeighborhoodsScreenState
    extends ConsumerState<AdminNeighborhoodsScreen> {
  String _activeFilter = '';
  final _searchController = TextEditingController();
  final _debouncer = _Debouncer(milliseconds: 400);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminNeighborhoodListProvider);
    final isWide = MediaQuery.of(context).size.width > 900;

    return Column(
      children: [
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
                width: isWide ? 320 : 200,
                height: 40,
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'חיפוש שכונה...',
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
                        .read(adminNeighborhoodListProvider.notifier)
                        .setSearch(v.isEmpty ? null : v);
                  }),
                ),
              ),
              const SizedBox(width: 12),
              _FilterChip('הכל', _activeFilter.isEmpty, () {
                setState(() => _activeFilter = '');
                ref
                    .read(adminNeighborhoodListProvider.notifier)
                    .setActiveFilter(null);
              }),
              _FilterChip('פעיל', _activeFilter == 'active', () {
                setState(() => _activeFilter = 'active');
                ref
                    .read(adminNeighborhoodListProvider.notifier)
                    .setActiveFilter('active');
              }),
              _FilterChip('לא פעיל', _activeFilter == 'inactive', () {
                setState(() => _activeFilter = 'inactive');
                ref
                    .read(adminNeighborhoodListProvider.notifier)
                    .setActiveFilter('inactive');
              }),
              const Spacer(),
              async
                      .whenData(
                        (list) => Text(
                          '${list.length} שכונות',
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
                onPressed: () => _showEditor(context, ref),
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  'שכונה חדשה',
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
          child: async.when(
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
            data: (neighborhoods) {
              if (neighborhoods.isEmpty) {
                return Center(
                  child: Text(
                    'אין שכונות',
                    style: TextStyle(
                      fontFamily: AppFonts.rubik,
                      color: AppColors.grayText,
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  // Header
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
                        const SizedBox(width: 48),
                        _Col('שם', flex: 3),
                        _Col('slug', flex: 2),
                        if (isWide) _Col('תושבים', flex: 1),
                        if (isWide) _Col('עסקים', flex: 1),
                        _Col('סטטוס', flex: 1),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      itemCount: neighborhoods.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: AppColors.border.withValues(alpha: 0.3),
                      ),
                      itemBuilder: (_, i) {
                        final n = neighborhoods[i];
                        final active = n['is_active'] as bool? ?? true;
                        return InkWell(
                          onTap: () =>
                              _showEditor(context, ref, neighborhood: n),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                NetworkPhoto(
                                  url: n['image_url'] as String?,
                                  width: 38,
                                  height: 38,
                                  radius: BorderRadius.circular(6),
                                  icon: Icons.image_outlined,
                                  iconSize: 16,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        n['name'] as String? ?? '',
                                        style: TextStyle(
                                          fontFamily: AppFonts.rubik,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.navy,
                                        ),
                                      ),
                                      if ((n['description'] as String?)
                                              ?.isNotEmpty ==
                                          true)
                                        Text(
                                          n['description'] as String,
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
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    n['slug'] as String? ?? '',
                                    style: TextStyle(
                                      fontFamily: AppFonts.rubik,
                                      fontSize: 12,
                                      color: AppColors.grayText,
                                    ),
                                  ),
                                ),
                                if (isWide)
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      '${AdminNeighborhoodListNotifier.count(n, 'profiles')}',
                                      style: TextStyle(
                                        fontFamily: AppFonts.rubik,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                if (isWide)
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      '${AdminNeighborhoodListNotifier.count(n, 'businesses')}',
                                      style: TextStyle(
                                        fontFamily: AppFonts.rubik,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                Expanded(
                                  flex: 1,
                                  child: _StatusPill(
                                    active ? 'פעיל' : 'לא פעיל',
                                    active
                                        ? AppColors.success
                                        : AppColors.grayLight,
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.more_vert,
                                    size: 18,
                                    color: AppColors.grayLight,
                                  ),
                                  onSelected: (v) => _handleAction(v, n),
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text(
                                        'עריכה',
                                        style: TextStyle(
                                          fontFamily: AppFonts.rubik,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'toggle',
                                      child: Text(
                                        active ? 'השבת' : 'הפעל',
                                        style: TextStyle(
                                          fontFamily: AppFonts.rubik,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text(
                                        // The row is not removed; it becomes is_active = false.
                                        'הסתר',
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

  void _handleAction(String action, Map<String, dynamic> n) {
    final notifier = ref.read(adminNeighborhoodListProvider.notifier);
    final id = n['id'] as String;
    switch (action) {
      case 'edit':
        _showEditor(context, ref, neighborhood: n);
      case 'toggle':
        notifier.toggleActive(id);
      case 'delete':
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(
              'מחיקת שכונה',
              style: TextStyle(
                fontFamily: AppFonts.rubik,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              'להסתיר את "${n['name']}"? השכונה תוסתר מהאפליקציה, '
              'והעסקים והמודעות המשויכים אליה יישמרו.',
              style: TextStyle(fontFamily: AppFonts.rubik),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'ביטול',
                  style: TextStyle(fontFamily: AppFonts.rubik),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  notifier.deleteNeighborhood(id);
                },
                child: Text(
                  'מחק',
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }

  void _showEditor(
    BuildContext context,
    WidgetRef ref, {
    Map<String, dynamic>? neighborhood,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _NeighborhoodEditorDialog(neighborhood: neighborhood),
    );
  }
}

// ─── Editor Dialog ───

class _NeighborhoodEditorDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? neighborhood;
  const _NeighborhoodEditorDialog({this.neighborhood});

  @override
  ConsumerState<_NeighborhoodEditorDialog> createState() =>
      _NeighborhoodEditorDialogState();
}

class _NeighborhoodEditorDialogState
    extends ConsumerState<_NeighborhoodEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late final TextEditingController _name;
  late final TextEditingController _slug;
  late final TextEditingController _description;
  late final TextEditingController _sortOrder;
  late final TextEditingController _imageUrl;
  bool _isActive = true;

  /// The photos the neighbourhood page shows after its main picture.
  final _gallery = AdminGalleryController(
    entityType: 'neighborhood',
    folder: 'neighborhoods/gallery',
  );

  /// Set once a new neighbourhood is inserted, so that a retry after a
  /// failed photo upload updates it rather than inserting it again.
  String? _createdId;

  /// Why the last save failed, shown in the dialog rather than behind it.
  String? _error;

  bool get _isEditing => widget.neighborhood != null;

  @override
  void initState() {
    super.initState();
    final n = widget.neighborhood;
    _name = TextEditingController(text: n?['name'] as String? ?? '');
    _slug = TextEditingController(text: n?['slug'] as String? ?? '');
    _description = TextEditingController(
      text: n?['description'] as String? ?? '',
    );
    _sortOrder = TextEditingController(
      text: (n?['sort_order'] as int?)?.toString() ?? '0',
    );
    _imageUrl = TextEditingController(text: n?['image_url'] as String? ?? '');
    _isActive = n?['is_active'] as bool? ?? true;
    if (n != null) _gallery.load(n['id'] as String);
  }

  @override
  void dispose() {
    _name.dispose();
    _slug.dispose();
    _description.dispose();
    _sortOrder.dispose();
    _imageUrl.dispose();
    _gallery.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 760),
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
                        _isEditing ? 'עריכת שכונה' : 'שכונה חדשה',
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
                        'שם שכונה *',
                        _name,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'שדה חובה' : null,
                      ),
                      _field('Slug (ריק ייווצר מהשם)', _slug),
                      _field('תיאור', _description, maxLines: 8),
                      // How the neighbourhood page splits it, so the client
                      // knows where a paragraph will land.
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Text(
                          'הפסקה הראשונה מוצגת כפתיח מתחת לשם השכונה; '
                          'שאר הפסקאות מוצגות תחת ״אודות״. '
                          'הפרידו בין פסקאות בשורה ריקה.',
                          style: TextStyle(
                            fontFamily: AppFonts.rubik,
                            fontSize: 12,
                            color: AppColors.adminTextLight,
                          ),
                        ),
                      ),
                      _field('סדר מיון', _sortOrder),
                      const SizedBox(height: 8),
                      // The first picture on the page and on the
                      // neighbourhood cards; the gallery follows it.
                      ImageUploadField(
                        label: 'תמונה ראשית',
                        controller: _imageUrl,
                        folder: 'neighborhoods',
                      ),
                      const SizedBox(height: 20),
                      AdminGalleryEditor(controller: _gallery),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: Text(
                          'פעיל',
                          style: TextStyle(
                            fontFamily: AppFonts.rubik,
                            fontSize: 14,
                          ),
                        ),
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                        activeColor: AppColors.turquoise,
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
                          'ביטול',
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
                                _isEditing ? 'שמור' : 'צור שכונה',
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

    // The table has no latitude or longitude. The form wrote both, and every
    // save — new or edited — was refused for it.
    final fields = <String, dynamic>{
      'name': _name.text.trim(),
      'slug': _slug.text.trim(),
      'description': _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
      'image_url': _imageUrl.text.trim().isEmpty ? null : _imageUrl.text.trim(),
      'sort_order': int.tryParse(_sortOrder.text.trim()) ?? 0,
      'is_active': _isActive,
    };

    try {
      final notifier = ref.read(adminNeighborhoodListProvider.notifier);
      final id = widget.neighborhood?['id'] as String? ?? _createdId;
      final String savedId;
      if (id != null) {
        await notifier.updateNeighborhood(id, fields);
        savedId = id;
      } else {
        savedId = await notifier.createNeighborhood(fields);
        _createdId = savedId;
      }
      await _gallery.save(savedId);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = switch (e) {
            PostgrestException(code: '23505') =>
              'השמירה נכשלה: שם או Slug זהים כבר קיימים בשכונה אחרת',
            PostgrestException(:final message) => 'השמירה נכשלה: $message',
            StorageException(:final message) => 'העלאת תמונה נכשלה: $message',
            _ => 'השמירה נכשלה: $e',
          },
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ─── Shared Widgets ───

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
