import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show PostgrestException, StorageException;
import '../../../core/theme/app_colors.dart';
import '../providers/admin_businesses_provider.dart';
import '../widgets/admin_gallery_editor.dart';
import '../widgets/admin_load_error.dart';
import '../widgets/image_upload_field.dart';

class AdminBusinessesScreen extends ConsumerStatefulWidget {
  const AdminBusinessesScreen({super.key});

  @override
  ConsumerState<AdminBusinessesScreen> createState() =>
      _AdminBusinessesScreenState();
}

class _AdminBusinessesScreenState extends ConsumerState<AdminBusinessesScreen> {
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
    final businessesAsync = ref.watch(adminBusinessListProvider);
    final isWide = MediaQuery.of(context).size.width > 900;

    return Column(
      children: [
        // ─── Toolbar (CRM-style) ───
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: AppColors.adminCardBorder, width: 1),
            ),
          ),
          child: Row(
            children: [
              // Search — CRM style
              SizedBox(
                width: isWide ? 320 : 200,
                height: 40,
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'חיפוש עסק...',
                    hintStyle: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      color: AppColors.adminTextLight,
                    ),
                    prefixIcon: Icon(
                      IconsaxPlusLinear.search_normal,
                      size: 18,
                      color: AppColors.adminTextLight,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(
                        color: AppColors.adminSearchBorder,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(
                        color: AppColors.adminSearchBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: AppColors.midBlue),
                    ),
                  ),
                  onChanged: (v) => _debouncer.run(() {
                    ref
                        .read(adminBusinessListProvider.notifier)
                        .setSearch(v.isEmpty ? null : v);
                  }),
                ),
              ),
              const SizedBox(width: 12),

              // Status filter
              _FilterChip('הכל', _statusFilter.isEmpty, () {
                setState(() => _statusFilter = '');
                ref
                    .read(adminBusinessListProvider.notifier)
                    .setStatusFilter(null);
              }),
              _FilterChip('פעיל', _statusFilter == 'active', () {
                setState(() => _statusFilter = 'active');
                ref
                    .read(adminBusinessListProvider.notifier)
                    .setStatusFilter('active');
              }),
              _FilterChip('ממתין', _statusFilter == 'pending', () {
                setState(() => _statusFilter = 'pending');
                ref
                    .read(adminBusinessListProvider.notifier)
                    .setStatusFilter('pending');
              }),
              _FilterChip('מושהה', _statusFilter == 'suspended', () {
                setState(() => _statusFilter = 'suspended');
                ref
                    .read(adminBusinessListProvider.notifier)
                    .setStatusFilter('suspended');
              }),
              // Where a closed business is found again to be reopened.
              _FilterChip('סגור', _statusFilter == 'closed', () {
                setState(() => _statusFilter = 'closed');
                ref
                    .read(adminBusinessListProvider.notifier)
                    .setStatusFilter('closed');
              }),

              const Spacer(),

              // Count
              // `valueOrNull`: `whenData(...).value` throws when the list
              // failed to load, and greyed the whole section until a reload.
              if (businessesAsync.valueOrNull case final list?)
                Text(
                  '${list.length} עסקים',
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 13,
                    color: AppColors.adminTextLight,
                  ),
                ),
              const SizedBox(width: 16),

              // Add button — CRM style
              SizedBox(
                height: 40,
                child: FilledButton.icon(
                  onPressed: () => _showBusinessEditor(context, ref),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(
                    'עסק חדש',
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.midBlue,
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ─── Table ───
        Expanded(
          child: businessesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'שגיאה בטעינת עסקים',
                    style: TextStyle(
                      fontFamily: AppFonts.rubik,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$e',
                    style: TextStyle(
                      fontFamily: AppFonts.rubik,
                      fontSize: 12,
                      color: AppColors.grayText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () =>
                        ref.read(adminBusinessListProvider.notifier).load(),
                    child: const Text('נסה שוב'),
                  ),
                ],
              ),
            ),
            data: (businesses) {
              if (businesses.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.store_outlined,
                        size: 48,
                        color: AppColors.grayLight.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'אין עסקים',
                        style: TextStyle(
                          fontFamily: AppFonts.rubik,
                          color: AppColors.grayText,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return _BusinessTable(
                businesses: businesses,
                categoryNames:
                    ref.watch(adminBusinessCategoryNamesProvider).valueOrNull ??
                    const {},
                isWide: isWide,
                onTap: (biz) =>
                    _showBusinessEditor(context, ref, business: biz),
                onAction: (action, biz) => _handleAction(action, biz),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Row actions wait for the write and say so when it is refused; they
  /// used to fire and forget, so a failure left the row as it was with no
  /// word why.
  Future<void> _handleAction(String action, Map<String, dynamic> biz) async {
    final notifier = ref.read(adminBusinessListProvider.notifier);
    final id = biz['id'] as String;
    switch (action) {
      case 'edit':
        _showBusinessEditor(context, ref, business: biz);
      case 'activate':
        await runAdminAction(
          context,
          () => notifier.updateStatus(id, 'active'),
        );
      case 'suspend':
        await runAdminAction(
          context,
          () => notifier.updateStatus(id, 'suspended'),
        );
      case 'delete':
        final close = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(
              'סגירת עסק',
              style: TextStyle(
                fontFamily: AppFonts.rubik,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              'לסמן את "${biz['name']}" כסגור? העסק ירד מהאפליקציה '
              'וניתן יהיה להחזירו על ידי שינוי הסטטוס.',
              style: TextStyle(fontFamily: AppFonts.rubik),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'ביטול',
                  style: TextStyle(fontFamily: AppFonts.rubik),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  'סמן כסגור',
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        );
        if (close == true && mounted) {
          await runAdminAction(context, () => notifier.deleteBusiness(id));
        }
    }
  }

  void _showBusinessEditor(
    BuildContext context,
    WidgetRef ref, {
    Map<String, dynamic>? business,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _BusinessEditorDialog(business: business),
    );
  }
}

// ─── Business Table ───

class _BusinessTable extends StatelessWidget {
  final List<Map<String, dynamic>> businesses;

  /// Business id → its categories as the list shows them.
  final Map<String, List<String>> categoryNames;
  final bool isWide;
  final void Function(Map<String, dynamic>) onTap;
  final void Function(String action, Map<String, dynamic>) onAction;

  const _BusinessTable({
    required this.businesses,
    required this.categoryNames,
    required this.isWide,
    required this.onTap,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header — CRM-style table header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: const BoxDecoration(
            color: AppColors.adminContentBg,
            border: Border(
              bottom: BorderSide(color: AppColors.adminCardBorder, width: 1),
            ),
          ),
          child: Row(
            children: [
              _Col('עסק', flex: 3),
              if (isWide) _Col('קטגוריה', flex: 2),
              _Col('שכונה', flex: 2),
              _Col('סטטוס', flex: 1),
              if (isWide) _Col('דירוג', flex: 1),
              if (isWide) _Col('ביקורות', flex: 1),
              const SizedBox(width: 40),
            ],
          ),
        ),

        // Rows
        Expanded(
          child: ListView.separated(
            itemCount: businesses.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: AppColors.border.withValues(alpha: 0.3),
            ),
            itemBuilder: (_, i) {
              final biz = businesses[i];
              final status = biz['status'] as String? ?? 'draft';
              final neighborhood =
                  biz['neighborhoods'] as Map<String, dynamic>?;
              final rating = (biz['rating'] as num?)?.toDouble() ?? 0;
              final reviewCount = biz['review_count'] as int? ?? 0;

              return InkWell(
                onTap: () => onTap(biz),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      // Logo + Name. The slot is kept when there is no
                      // logo, so the columns after it stay aligned.
                      if (biz['logo_url'] == null)
                        const SizedBox(width: 48)
                      else ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            biz['logo_url'] as String,
                            width: 38,
                            height: 38,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.store,
                                size: 18,
                                color: AppColors.grayLight,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    biz['name'] as String? ?? '',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: AppFonts.rubik,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.navy,
                                    ),
                                  ),
                                ),
                                // Parks share this list; the badge tells
                                // them apart at a glance.
                                if (biz['kind'] == 'park') ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE6F4EA),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'פארק',
                                      style: TextStyle(
                                        fontFamily: AppFonts.rubik,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1E7B34),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              biz['slug'] as String? ?? '',
                              style: TextStyle(
                                fontFamily: AppFonts.rubik,
                                fontSize: 11,
                                color: AppColors.grayLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Its categories, from entity_categories. A dash where
                      // there are none: such a business is in no category
                      // list on the site, which is worth seeing here.
                      if (isWide)
                        Expanded(
                          flex: 2,
                          child: Text(
                            (categoryNames[biz['id']] ?? const []).isEmpty
                                ? '—'
                                : categoryNames[biz['id']]!.join(', '),
                            style: TextStyle(
                              fontFamily: AppFonts.rubik,
                              fontSize: 12,
                              color: AppColors.grayText,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      // Neighborhood
                      Expanded(
                        flex: 2,
                        child: Text(
                          neighborhood?['name'] as String? ?? '—',
                          style: TextStyle(
                            fontFamily: AppFonts.rubik,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      // Status
                      Expanded(flex: 1, child: _StatusPill(status)),
                      // Rating
                      if (isWide)
                        Expanded(
                          flex: 1,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (rating > 0) ...[
                                Icon(
                                  Icons.star,
                                  size: 14,
                                  color: rating >= 4
                                      ? AppColors.gold
                                      : AppColors.grayLight,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontFamily: AppFonts.rubik,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ] else
                                Text(
                                  '—',
                                  style: TextStyle(
                                    fontFamily: AppFonts.rubik,
                                    fontSize: 13,
                                    color: AppColors.grayLight,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      // Reviews
                      if (isWide)
                        Expanded(
                          flex: 1,
                          child: Text(
                            '$reviewCount',
                            style: TextStyle(
                              fontFamily: AppFonts.rubik,
                              fontSize: 13,
                              color: AppColors.grayText,
                            ),
                          ),
                        ),
                      // Actions
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert,
                          size: 18,
                          color: AppColors.grayLight,
                        ),
                        onSelected: (v) => onAction(v, biz),
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
                          if (status != 'active')
                            PopupMenuItem(
                              value: 'activate',
                              child: Text(
                                status == 'closed' ? 'פתיחה מחדש' : 'אשר',
                                style: TextStyle(
                                  fontFamily: AppFonts.rubik,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          if (status != 'suspended')
                            PopupMenuItem(
                              value: 'suspend',
                              child: Text(
                                'השהה',
                                style: TextStyle(
                                  fontFamily: AppFonts.rubik,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          if (status != 'closed')
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                'סגירת העסק',
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

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill(this.status);

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'active' => ('פעיל', AppColors.success),
      'pending' => ('ממתין', AppColors.gold),
      'suspended' => ('מושהה', AppColors.error),
      'closed' => ('סגור', AppColors.grayLight),
      'draft' => ('טיוטה', AppColors.grayLight),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(this.label, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.adminActiveBg : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected
                  ? AppColors.midBlue.withValues(alpha: 0.3)
                  : AppColors.adminSearchBorder,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
              color: selected ? AppColors.midBlue : AppColors.adminTextMedium,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Business Editor Dialog ───

class _BusinessEditorDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? business;
  const _BusinessEditorDialog({this.business});

  @override
  ConsumerState<_BusinessEditorDialog> createState() =>
      _BusinessEditorDialogState();
}

class _BusinessEditorDialogState extends ConsumerState<_BusinessEditorDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  // Images
  late final TextEditingController _logoUrl;
  late final TextEditingController _coverUrl;
  late final TextEditingController _ogImageUrl;
  // Basic info
  late final TextEditingController _name;
  late final TextEditingController _slug;
  late final TextEditingController _shortDesc;
  late final TextEditingController _fullDesc;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _website;
  late final TextEditingController _whatsapp;
  late final TextEditingController _instagram;
  late final TextEditingController _address;
  late final TextEditingController _lat;
  late final TextEditingController _lng;

  // SEO
  late final TextEditingController _metaTitle;
  late final TextEditingController _metaDesc;
  late final TextEditingController _metaKeywords;
  late final TextEditingController _ogTitle;
  late final TextEditingController _ogDesc;

  // The homepage's recommended strip shows a featured business only inside
  // this window; empty means no limit on that side.
  late final TextEditingController _featuredStart;
  late final TextEditingController _featuredEnd;

  /// The photos under the business page's Photos tab.
  final _gallery = AdminGalleryController(
    entityType: 'business',
    folder: 'businesses/gallery',
  );

  /// Set once a new business has been inserted. If something after the
  /// insert fails — hours, a photo — saving again updates that row instead
  /// of inserting a second copy.
  String? _createdId;

  /// Why the last save failed, shown in the dialog itself. A snackbar opens
  /// on the page behind the dialog, under its barrier, where it is easy to
  /// miss.
  String? _error;

  String _status = 'draft';

  /// 'business' or 'park'. A park is shown on the Municipal page's Parks
  /// tile, not in the directory, and its page has no phone, website or menu.
  String _kind = 'business';
  String? _neighborhoodId;
  String _kosher = 'none';
  String? _priceLevel;
  bool _hasDelivery = false;
  bool _hasOutdoor = false;
  bool _isAccessible = false;
  bool _hasTakeaway = false;
  bool _hasParking = false;
  bool _petFriendly = false;
  bool _kidFriendly = false;
  bool _hasWifi = false;
  bool _openOnShabbat = false;
  bool _isFeatured = false;
  bool _isRecommended = false;
  bool _isVerified = false;
  bool _noindex = false;

  bool get _isEditing => widget.business != null;

  /// The row being edited, or the one this dialog has just created.
  String? get _rowId => widget.business?['id'] as String? ?? _createdId;

  /// The menu lines being edited. Loaded once when the editor opens on an
  /// existing business; a new business starts with none.
  final List<Map<String, dynamic>> _menuItems = [];
  bool _menuLoaded = false;
  int _nextMenuKey = 0;

  Widget _buildMenuTab() {
    // A new business has no menu to load, so it starts empty and is saved
    // with the rest once the row exists.
    if (!_isEditing) return _menuList();

    final id = widget.business!['id'] as String;
    final async = ref.watch(adminMenuItemsProvider(id));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('$e', style: TextStyle(fontFamily: AppFonts.rubik)),
      ),
      data: (rows) {
        if (!_menuLoaded) {
          _menuItems
            ..clear()
            ..addAll(
              rows.map(
                (r) => {
                  // The id goes with the line, so a save updates this row
                  // instead of replacing the whole menu.
                  'id': r['id'],
                  '_key': _nextMenuKey++,
                  'section': r['section'],
                  'name': r['name'],
                  'description': r['description'],
                  'price_agorot': r['price_agorot'],
                  'is_available': r['is_available'] ?? true,
                },
              ),
            );
          _menuLoaded = true;
        }
        return _menuList();
      },
    );
  }

  Widget _menuList() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'כל שורה היא פריט. \u05f4קטגוריה\u05f4 היא הכותרת שמעליו — למשל \u05f4ראשונות\u05f4.',
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontSize: 12,
            color: AppColors.grayText,
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < _menuItems.length; i++)
          _MenuItemRow(
            // Keyed by the line, not its place: keyed by index, removing a
            // line left the fields below it showing the text of the one
            // before.
            key: ValueKey(_menuItems[i]['_key']),
            item: _menuItems[i],
            onChanged: (v) => setState(() => _menuItems[i] = v),
            onRemove: () => setState(() => _menuItems.removeAt(i)),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => setState(
            () => _menuItems.add({
              '_key': _nextMenuKey++,
              'section': null,
              'name': '',
              'description': null,
              'price_agorot': null,
              'is_available': true,
            }),
          ),
          icon: const Icon(Icons.add, size: 18),
          label: Text(
            'הוספת פריט',
            style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 6, vsync: this);
    for (var d = DateTime.monday; d <= DateTime.sunday; d++) {
      _openCtl[d] = TextEditingController();
      _closeCtl[d] = TextEditingController();
      _dayClosed[d] = false;
    }
    if (_isEditing) {
      _loadHours();
      _loadCategories();
      _gallery.load(widget.business!['id'] as String);
    } else {
      _menuLoaded = true;
    }
    final b = widget.business;

    _logoUrl = TextEditingController(text: b?['logo_url'] as String? ?? '');
    // `cover_url` is the column. This read `cover_image_url`, which does
    // not exist, so every cover showed as empty and every save was refused.
    _coverUrl = TextEditingController(text: b?['cover_url'] as String? ?? '');
    _ogImageUrl = TextEditingController(
      text: b?['og_image_url'] as String? ?? '',
    );
    _name = TextEditingController(text: b?['name'] as String? ?? '');
    _slug = TextEditingController(text: b?['slug'] as String? ?? '');
    _shortDesc = TextEditingController(
      text: b?['short_description'] as String? ?? '',
    );
    _fullDesc = TextEditingController(
      text: b?['full_description'] as String? ?? '',
    );
    _phone = TextEditingController(text: b?['phone'] as String? ?? '');
    _email = TextEditingController(text: b?['email'] as String? ?? '');
    _website = TextEditingController(text: b?['website'] as String? ?? '');
    _whatsapp = TextEditingController(text: b?['whatsapp'] as String? ?? '');
    _instagram = TextEditingController(text: b?['instagram'] as String? ?? '');
    _address = TextEditingController(text: b?['address'] as String? ?? '');
    _lat = TextEditingController(
      text: (b?['latitude'] as num?)?.toString() ?? '',
    );
    _lng = TextEditingController(
      text: (b?['longitude'] as num?)?.toString() ?? '',
    );
    _metaTitle = TextEditingController(text: b?['meta_title'] as String? ?? '');
    _metaDesc = TextEditingController(
      text: b?['meta_description'] as String? ?? '',
    );
    _metaKeywords = TextEditingController(
      text: b?['meta_keywords'] as String? ?? '',
    );
    _ogTitle = TextEditingController(text: b?['og_title'] as String? ?? '');
    _ogDesc = TextEditingController(
      text: b?['og_description'] as String? ?? '',
    );
    _featuredStart = TextEditingController(
      text: _dateText(b?['featured_start'] as String?),
    );
    _featuredEnd = TextEditingController(
      text: _dateText(b?['featured_end'] as String?),
    );

    _status = b?['status'] as String? ?? 'draft';
    _kind = b?['kind'] as String? ?? 'business';
    _neighborhoodId = b?['neighborhood_id'] as String?;
    _kosher = b?['kosher_level'] as String? ?? 'none';
    _priceLevel = b?['price_level'] as String?;
    _hasDelivery = b?['has_delivery'] as bool? ?? false;
    _hasOutdoor = b?['has_outdoor'] as bool? ?? false;
    _isAccessible = b?['is_accessible'] as bool? ?? false;
    _hasTakeaway = b?['has_takeaway'] as bool? ?? false;
    _hasParking = b?['has_parking'] as bool? ?? false;
    _petFriendly = b?['pet_friendly'] as bool? ?? false;
    _kidFriendly = b?['kid_friendly'] as bool? ?? false;
    _hasWifi = b?['has_wifi'] as bool? ?? false;
    _openOnShabbat = b?['open_on_shabbat'] as bool? ?? false;
    _isFeatured = b?['is_featured'] as bool? ?? false;
    _isRecommended = b?['is_recommended'] as bool? ?? false;
    _isVerified = b?['is_verified'] as bool? ?? false;
    _noindex = b?['noindex'] as bool? ?? false;
  }

  @override
  void dispose() {
    _tabs.dispose();
    for (final c in _openCtl.values) {
      c.dispose();
    }
    for (final c in _closeCtl.values) {
      c.dispose();
    }
    _bulkOpen.dispose();
    _bulkClose.dispose();
    _logoUrl.dispose();
    _coverUrl.dispose();
    _ogImageUrl.dispose();
    _featuredStart.dispose();
    _featuredEnd.dispose();
    _gallery.dispose();
    _name.dispose();
    _slug.dispose();
    _shortDesc.dispose();
    _fullDesc.dispose();
    _phone.dispose();
    _email.dispose();
    _website.dispose();
    _whatsapp.dispose();
    _instagram.dispose();
    _address.dispose();
    _lat.dispose();
    _lng.dispose();
    _metaTitle.dispose();
    _metaDesc.dispose();
    _metaKeywords.dispose();
    _ogTitle.dispose();
    _ogDesc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final neighborhoods = ref.watch(neighborhoodsProvider);

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _isEditing ? 'עריכת עסק' : 'עסק חדש',
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

                // Tabs
                Container(
                  color: AppColors.surfaceLight,
                  child: TabBar(
                    controller: _tabs,
                    labelStyle: TextStyle(
                      fontFamily: AppFonts.rubik,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontFamily: AppFonts.rubik,
                      fontSize: 13,
                    ),
                    labelColor: AppColors.turquoise,
                    unselectedLabelColor: AppColors.grayText,
                    indicatorColor: AppColors.turquoise,
                    tabs: const [
                      Tab(text: 'פרטים'),
                      Tab(text: 'גלריה'),
                      Tab(text: 'שעות פתיחה'),
                      Tab(text: 'תפריט'),
                      Tab(text: 'מאפיינים'),
                      Tab(text: 'SEO'),
                    ],
                  ),
                ),

                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _buildDetailsTab(neighborhoods),
                      ListView(
                        padding: const EdgeInsets.all(20),
                        children: [AdminGalleryEditor(controller: _gallery)],
                      ),
                      _buildHoursTab(),
                      _buildMenuTab(),
                      _buildAttributesTab(),
                      _buildSeoTab(),
                    ],
                  ),
                ),

                // Footer
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
                      if (_isEditing) ...[
                        _StatusPill(_status),
                        const SizedBox(width: 8),
                      ],
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
                                _isEditing ? 'שמור' : 'צור עסק',
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

  Widget _buildDetailsTab(
    AsyncValue<List<Map<String, dynamic>>> neighborhoods,
  ) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'סוג',
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'business', label: Text('עסק')),
            ButtonSegment(value: 'park', label: Text('פארק')),
          ],
          selected: {_kind},
          onSelectionChanged: (v) => setState(() => _kind = v.first),
        ),
        if (_kind == 'park') ...[
          const SizedBox(height: 6),
          Text(
            'פארק מוצג בעמוד העירייה ← פארקים, ולא במדריך העסקים. בדף הפארק '
            'אין טלפון, אתר או תפריט; נשמרים תיאור, תמונות, ביקורות ומיקום.',
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontSize: 12,
              color: AppColors.adminTextLight,
            ),
          ),
        ],
        const SizedBox(height: 16),
        _field(
          _kind == 'park' ? 'שם הפארק *' : 'שם עסק *',
          _name,
          validator: (v) => v == null || v.isEmpty ? 'שדה חובה' : null,
        ),
        _field('Slug (כתובת הדף — ריק ייווצר מהשם)', _slug),
        _field('תיאור קצר (מוצג בכרטיס)', _shortDesc, maxLines: 2),
        _field('אודות (מוצג בדף העסק)', _fullDesc, maxLines: 6),
        const SizedBox(height: 16),
        Text(
          'תמונות',
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 8),
        // Upload rather than a URL typed by hand: the person managing the
        // directory should not have to host a picture somewhere else first.
        // Each field still shows what is stored and stays editable, so the
        // photographs already on the WordPress site keep working.
        const SizedBox(height: 4),
        ImageUploadField(
          label: 'לוגו',
          controller: _logoUrl,
          folder: 'businesses/logo',
        ),
        const SizedBox(height: 14),
        ImageUploadField(
          label: 'תמונת כריכה',
          controller: _coverUrl,
          folder: 'businesses/cover',
        ),
        const SizedBox(height: 6),
        Text(
          'תמונות נוספות מנוהלות בלשונית ״גלריה״.',
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontSize: 12,
            color: AppColors.adminTextLight,
          ),
        ),
        if (_kind != 'park') ...[
        const SizedBox(height: 16),
        Text(
          'קשר',
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _field('טלפון', _phone)),
            const SizedBox(width: 12),
            Expanded(child: _field('WhatsApp', _whatsapp)),
          ],
        ),
        Row(
          children: [
            Expanded(child: _field('אימייל', _email)),
            const SizedBox(width: 12),
            Expanded(child: _field('אתר', _website)),
          ],
        ),
        _field('Instagram', _instagram),
        ],
        const SizedBox(height: 16),
        Text(
          'סיווג',
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 8),
        _categoryPicker(),
        const SizedBox(height: 16),
        Text(
          'מיקום',
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 8),
        _field(
          'כתובת *',
          _address,
          validator: (v) => v == null || v.isEmpty ? 'שדה חובה' : null,
        ),
        neighborhoods.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const SizedBox.shrink(),
          data: (hoods) => DropdownButtonFormField<String>(
            value: _neighborhoodId,
            decoration: InputDecoration(
              labelText: 'שכונה',
              labelStyle: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            items: hoods
                .map(
                  (h) => DropdownMenuItem(
                    value: h['id'] as String,
                    child: Text(
                      h['name'] as String,
                      style: TextStyle(
                        fontFamily: AppFonts.rubik,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _neighborhoodId = v),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _field('Latitude', _lat)),
            const SizedBox(width: 12),
            Expanded(child: _field('Longitude', _lng)),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'סטטוס',
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _status,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
          items: [
            DropdownMenuItem(
              value: 'draft',
              child: Text(
                'טיוטה',
                style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
              ),
            ),
            DropdownMenuItem(
              value: 'pending',
              child: Text(
                'ממתין לאישור',
                style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
              ),
            ),
            DropdownMenuItem(
              value: 'active',
              child: Text(
                'פעיל',
                style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
              ),
            ),
            DropdownMenuItem(
              value: 'suspended',
              child: Text(
                'מושהה',
                style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
              ),
            ),
            DropdownMenuItem(
              value: 'closed',
              child: Text(
                'סגור',
                style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
              ),
            ),
          ],
          onChanged: (v) => setState(() => _status = v!),
        ),
      ],
    );
  }

  Widget _buildAttributesTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'כשרות',
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _kosher,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
          items: [
            DropdownMenuItem(
              value: 'none',
              child: Text(
                'ללא',
                style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
              ),
            ),
            DropdownMenuItem(
              value: 'rabbanut',
              child: Text(
                'רבנות',
                style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
              ),
            ),
            DropdownMenuItem(
              value: 'mehadrin',
              child: Text(
                'מהדרין',
                style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
              ),
            ),
            DropdownMenuItem(
              value: 'badatz',
              child: Text(
                'בד״ץ',
                style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
              ),
            ),
            // The fifth value of `kosher_level`. The site shows it as plain
            // "kosher"; without it here a business set to it opened with an
            // empty picker.
            DropdownMenuItem(
              value: 'other',
              child: Text(
                'כשר (אחר)',
                style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
              ),
            ),
          ],
          onChanged: (v) => setState(() => _kosher = v!),
        ),
        const SizedBox(height: 12),
        Text(
          'רמת מחיר',
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String?>(
          value: _priceLevel,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
          items: [
            DropdownMenuItem(
              value: null,
              child: Text(
                '—',
                style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
              ),
            ),
            DropdownMenuItem(
              value: '₪',
              child: Text(
                '₪',
                style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
              ),
            ),
            DropdownMenuItem(
              value: '₪₪',
              child: Text(
                '₪₪',
                style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
              ),
            ),
            DropdownMenuItem(
              value: '₪₪₪',
              child: Text(
                '₪₪₪',
                style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
              ),
            ),
            DropdownMenuItem(
              value: '₪₪₪₪',
              child: Text(
                '₪₪₪₪',
                style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
              ),
            ),
          ],
          onChanged: (v) => setState(() => _priceLevel = v),
        ),
        const SizedBox(height: 16),
        Text(
          'מאפיינים',
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _toggle(
              'משלוחים',
              _hasDelivery,
              (v) => setState(() => _hasDelivery = v),
            ),
            _toggle(
              'Takeaway',
              _hasTakeaway,
              (v) => setState(() => _hasTakeaway = v),
            ),
            _toggle(
              'ישיבה בחוץ',
              _hasOutdoor,
              (v) => setState(() => _hasOutdoor = v),
            ),
            _toggle(
              'נגיש',
              _isAccessible,
              (v) => setState(() => _isAccessible = v),
            ),
            _toggle(
              'חניה',
              _hasParking,
              (v) => setState(() => _hasParking = v),
            ),
            _toggle(
              'ידידותי לחיות',
              _petFriendly,
              (v) => setState(() => _petFriendly = v),
            ),
            _toggle(
              'ידידותי לילדים',
              _kidFriendly,
              (v) => setState(() => _kidFriendly = v),
            ),
            _toggle('Wi-Fi', _hasWifi, (v) => setState(() => _hasWifi = v)),
            _toggle(
              'פתוח בשבת',
              _openOnShabbat,
              (v) => setState(() => _openOnShabbat = v),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'קידום',
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 8),
        // The homepage's "recommended" strip takes a business marked
        // recommended at any time, or one marked featured inside the dates
        // below.
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _toggle(
              'מומלץ (תמיד בדף הבית)',
              _isRecommended,
              (v) => setState(() => _isRecommended = v),
            ),
            _toggle(
              'מקודם / Featured',
              _isFeatured,
              (v) => setState(() => _isFeatured = v),
            ),
            _toggle(
              'מאומת / Verified',
              _isVerified,
              (v) => setState(() => _isVerified = v),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _field(
                'קידום מתאריך (YYYY-MM-DD)',
                _featuredStart,
                validator: _dateValidator,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _field(
                'קידום עד תאריך (כולל)',
                _featuredEnd,
                validator: _dateValidator,
              ),
            ),
          ],
        ),
        Text(
          'ריק = ללא הגבלה. התאריכים חלים על ״מקודם״ בלבד.',
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontSize: 12,
            color: AppColors.adminTextLight,
          ),
        ),
      ],
    );
  }

  // ── Featured window ──

  /// `2026-10-01` for a stored timestamp, in the admin's own time zone.
  static String _dateText(String? stored) {
    final d = DateTime.tryParse(stored ?? '')?.toLocal();
    if (d == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  static DateTime? _parseDate(String text) {
    final m = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(text.trim());
    if (m == null) return null;
    return DateTime(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
    );
  }

  static String? _dateValidator(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    return _parseDate(v) == null ? 'YYYY-MM-DD' : null;
  }

  /// The start of the day for the first date and the end of it for the
  /// last, so "until the 31st" includes the 31st.
  static String? _dateForColumn(String text, {required bool endOfDay}) {
    final d = _parseDate(text);
    if (d == null) return null;
    final at = endOfDay ? DateTime(d.year, d.month, d.day, 23, 59, 59) : d;
    return at.toUtc().toIso8601String();
  }

  Widget _buildSeoTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _field('SEO Title', _metaTitle),
        _field('Meta Description', _metaDesc, maxLines: 3),
        _field('Meta Keywords', _metaKeywords),
        const SizedBox(height: 16),
        Text(
          'Open Graph',
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 8),
        _field('OG Title', _ogTitle),
        _field('OG Description', _ogDesc, maxLines: 3),
        // The site also falls back to this picture when there is no cover.
        ImageUploadField(
          label: 'תמונת שיתוף (OG)',
          controller: _ogImageUrl,
          folder: 'businesses/og',
        ),
        const SizedBox(height: 12),
        _toggle('Noindex', _noindex, (v) => setState(() => _noindex = v)),
      ],
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

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 12),
      ),
      selected: value,
      onSelected: onChanged,
      selectedColor: AppColors.turquoise.withValues(alpha: 0.15),
      checkmarkColor: AppColors.turquoise,
      side: BorderSide(color: value ? AppColors.turquoise : AppColors.border),
    );
  }

  // ── Opening hours ──
  //
  // Held as the week the person sees it, Monday first. The table's 0 = Sunday
  // is converted in the provider, so nothing here has to think about it.

  static const _dayNames = {
    DateTime.monday: 'שני',
    DateTime.tuesday: 'שלישי',
    DateTime.wednesday: 'רביעי',
    DateTime.thursday: 'חמישי',
    DateTime.friday: 'שישי',
    DateTime.saturday: 'שבת',
    DateTime.sunday: 'ראשון',
  };

  final Map<int, TextEditingController> _openCtl = {};
  final Map<int, TextEditingController> _closeCtl = {};
  final Map<int, bool> _dayClosed = {};
  bool _hoursLoaded = false;
  bool _hoursTouched = false;

  /// Postgres hands back `09:00:00`; the field takes and validates `09:00`.
  static String _hhmm(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final parts = raw.split(':');
    return parts.length >= 2 ? '${parts[0]}:${parts[1]}' : raw;
  }

  // ── Categories ──
  //
  // A business's categories live in `entity_categories`, not on the row, so
  // they are loaded and saved separately. The directory and the restaurants
  // screen both filter on this, so a business with none is invisible in every
  // category list — which is why it belongs in the editor rather than
  // somewhere else.
  Set<String> _categoryIds = {};
  bool _categoriesTouched = false;

  Future<void> _loadCategories() async {
    final id = widget.business!['id'] as String;
    try {
      final ids = await ref.read(businessCategoryIdsProvider(id).future);
      if (mounted) setState(() => _categoryIds = ids.toSet());
    } catch (_) {
      // Leave it empty; saving without touching it changes nothing.
    }
  }

  Widget _categoryPicker() {
    final categories = ref.watch(businessCategoriesProvider);

    return categories.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      ),
      error: (_, _) => Text(
        'לא ניתן לטעון קטגוריות',
        style: TextStyle(
          fontFamily: AppFonts.rubik,
          fontSize: 12,
          color: AppColors.error,
        ),
      ),
      data: (list) {
        // Grouped by parent: the Services trades — electrician, plumber and
        // the rest — are children of Services, and in one flat run of chips
        // nothing said so. Each top-level category heads its own line, its
        // children after it.
        final roots = list.where((c) => c['parent_id'] == null).toList();
        final rootIds = roots.map((c) => c['id']).toSet();
        final childrenOf = <String, List<Map<String, dynamic>>>{};
        for (final c in list) {
          final parent = c['parent_id'] as String?;
          if (parent != null) childrenOf.putIfAbsent(parent, () => []).add(c);
        }
        // A child whose parent is hidden still needs a place to be picked.
        final orphans = list
            .where(
              (c) =>
                  c['parent_id'] != null && !rootIds.contains(c['parent_id']),
            )
            .toList();

        final leaves = roots
            .where((r) => (childrenOf[r['id']] ?? const []).isEmpty)
            .toList();
        final parents = roots
            .where((r) => (childrenOf[r['id']] ?? const []).isNotEmpty)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'קטגוריות',
              style: TextStyle(
                fontFamily: AppFonts.rubik,
                fontSize: 12,
                color: AppColors.adminTextMedium,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final c in leaves) _categoryChip(c)],
            ),
            for (final p in parents) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.adminContentBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.adminCardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // The parent itself can be picked too — a business can
                    // be filed under Services without naming a trade.
                    _categoryChip(p, bold: true),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: 16),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final c in childrenOf[p['id']]!)
                            _categoryChip(c),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (orphans.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [for (final c in orphans) _categoryChip(c)],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _categoryChip(Map<String, dynamic> c, {bool bold = false}) {
    return FilterChip(
      label: Text(
        c['name'] as String,
        style: TextStyle(
          fontFamily: AppFonts.rubik,
          fontSize: 12,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      selected: _categoryIds.contains(c['id']),
      onSelected: (on) => setState(() {
        on ? _categoryIds.add(c['id'] as String) : _categoryIds.remove(c['id']);
        _categoriesTouched = true;
      }),
    );
  }

  final _bulkOpen = TextEditingController();
  final _bulkClose = TextEditingController();

  /// Copies the pair at the top into a run of days. Sunday to Thursday wraps
  /// around the end of the week, which is the ordinary Israeli working week.
  void _applyToAll(int from, int to) {
    final open = _bulkOpen.text.trim();
    final close = _bulkClose.text.trim();
    if (open.isEmpty || close.isEmpty) return;

    final days = from <= to
        ? [for (var d = from; d <= to; d++) d]
        : [
            for (var d = from; d <= DateTime.sunday; d++) d,
            for (var d = DateTime.monday; d <= to; d++) d,
          ];

    setState(() {
      for (final d in days) {
        _openCtl[d]!.text = open;
        _closeCtl[d]!.text = close;
        _dayClosed[d] = false;
      }
      _hoursTouched = true;
    });
  }

  Future<void> _loadHours() async {
    final id = widget.business!['id'] as String;
    try {
      final week = await ref.read(businessHoursProvider(id).future);
      if (!mounted) return;
      setState(() {
        for (var d = DateTime.monday; d <= DateTime.sunday; d++) {
          final row = week[d];
          _openCtl[d]!.text = _hhmm(row?['open_time'] as String?);
          _closeCtl[d]!.text = _hhmm(row?['close_time'] as String?);
          _dayClosed[d] = row == null
              ? false
              : (row['is_closed'] as bool? ?? false);
        }
        _hoursLoaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _hoursLoaded = true);
    }
  }

  Widget _buildHoursTab() {
    if (_isEditing && !_hoursLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'השאירו ריק אם השעות אינן ידועות. יום ללא שעות לא יוצג באפליקציה.',
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontSize: 12,
            color: AppColors.adminTextLight,
          ),
        ),
        const SizedBox(height: 14),

        // Most businesses keep the same hours Sunday to Thursday and differ
        // only on Friday and Saturday, so typing fourteen times is the
        // common case. This fills the week from one pair.
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.adminContentBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(child: _timeField(_bulkOpen, 'פתיחה', enabled: true)),
              const SizedBox(width: 8),
              Expanded(child: _timeField(_bulkClose, 'סגירה', enabled: true)),
              const SizedBox(width: 10),
              TextButton(
                onPressed: () => _applyToAll(DateTime.monday, DateTime.sunday),
                child: Text(
                  'החל על כל השבוע',
                  style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 12),
                ),
              ),
              TextButton(
                onPressed: () =>
                    _applyToAll(DateTime.sunday, DateTime.thursday),
                child: Text(
                  'א׳–ה׳ בלבד',
                  style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (var day = DateTime.monday; day <= DateTime.sunday; day++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  child: Text(
                    _dayNames[day]!,
                    style: TextStyle(
                      fontFamily: AppFonts.rubik,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.adminTextDark,
                    ),
                  ),
                ),
                Expanded(
                  child: _timeField(
                    _openCtl[day]!,
                    'פתיחה',
                    enabled: !(_dayClosed[day] ?? false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _timeField(
                    _closeCtl[day]!,
                    'סגירה',
                    enabled: !(_dayClosed[day] ?? false),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'סגור',
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 12,
                    color: AppColors.adminTextLight,
                  ),
                ),
                Switch(
                  value: _dayClosed[day] ?? false,
                  onChanged: (v) => setState(() {
                    _dayClosed[day] = v;
                    _hoursTouched = true;
                  }),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// 24-hour HH:MM, which is what the column holds and what the app parses.
  Widget _timeField(
    TextEditingController controller,
    String hint, {
    required bool enabled,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      onChanged: (_) => _hoursTouched = true,
      style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: AppFonts.rubik,
          fontSize: 13,
          color: AppColors.adminTextLight,
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 12,
        ),
        border: const OutlineInputBorder(),
      ),
      validator: (v) {
        if (!enabled || v == null || v.isEmpty) return null;
        return RegExp(r'^([01]?\d|2[0-3]):[0-5]\d$').hasMatch(v)
            ? null
            : 'HH:MM';
      },
    );
  }

  /// Only the days that say something are written. A day left blank stays
  /// unknown rather than becoming "closed", so the app can hide it instead of
  /// stating hours nobody gave.
  Map<int, ({String? open, String? close, bool closed})> _weekFromForm() {
    final week = <int, ({String? open, String? close, bool closed})>{};
    for (var d = DateTime.monday; d <= DateTime.sunday; d++) {
      final closed = _dayClosed[d] ?? false;
      final open = _openCtl[d]!.text.trim();
      final close = _closeCtl[d]!.text.trim();
      if (!closed && (open.isEmpty || close.isEmpty)) continue;
      week[d] = (
        open: open.isEmpty ? null : open,
        close: close.isEmpty ? null : close,
        closed: closed,
      );
    }
    return week;
  }

  /// A slug from the name when none was typed: the site's existing ones are
  /// the Hebrew name with hyphens for spaces (`דקר-בן-ימין`).
  static String _slugFrom(String name) => name
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N}\s-]', unicode: true), '')
      .replaceAll(RegExp(r'[\s-]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');

  String? _t(TextEditingController c) {
    final v = c.text.trim();
    return v.isEmpty ? null : v;
  }

  Future<void> _save() async {
    setState(() => _error = null);

    // The tabs build only the one on screen, so the form cannot validate a
    // field on another tab. The required ones are checked here, and the
    // details tab brought forward when one is missing.
    if (_name.text.trim().isEmpty || _address.text.trim().isEmpty) {
      _tabs.animateTo(0);
      setState(() => _error = 'שם העסק והכתובת הם שדות חובה (לשונית פרטים).');
      return;
    }
    if (_dateValidator(_featuredStart.text) != null ||
        _dateValidator(_featuredEnd.text) != null) {
      _tabs.animateTo(4);
      setState(() => _error = 'תאריכי הקידום צריכים להיות בפורמט YYYY-MM-DD.');
      return;
    }
    final badDay = [
      for (var d = DateTime.monday; d <= DateTime.sunday; d++)
        if (!(_dayClosed[d] ?? false) &&
            [_openCtl[d]!.text.trim(), _closeCtl[d]!.text.trim()].any(
              (t) =>
                  t.isNotEmpty &&
                  !RegExp(r'^([01]?\d|2[0-3]):[0-5]\d$').hasMatch(t),
            ))
          _dayNames[d]!,
    ];
    if (badDay.isNotEmpty) {
      _tabs.animateTo(2);
      setState(
        () => _error =
            'שעה לא תקינה ביום ${badDay.join(', ')} — HH:MM, למשל 09:00.',
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    if (_slug.text.trim().isEmpty) _slug.text = _slugFrom(_name.text);

    setState(() => _saving = true);

    final fields = <String, dynamic>{
      'logo_url': _t(_logoUrl),
      'cover_url': _t(_coverUrl),
      'og_image_url': _t(_ogImageUrl),
      'name': _name.text.trim(),
      'slug': _slug.text.trim(),
      'short_description': _t(_shortDesc),
      'full_description': _t(_fullDesc),
      'kind': _kind,
      // A park has no contact details (the client's rule), so any typed
      // before switching the type are not kept.
      'phone': _kind == 'park' ? null : _t(_phone),
      'email': _kind == 'park' ? null : _t(_email),
      'website': _kind == 'park' ? null : _t(_website),
      'whatsapp': _kind == 'park' ? null : _t(_whatsapp),
      'instagram': _kind == 'park' ? null : _t(_instagram),
      'address': _address.text.trim(),
      'neighborhood_id': _neighborhoodId,
      'latitude': double.tryParse(_lat.text.trim()),
      'longitude': double.tryParse(_lng.text.trim()),
      'status': _status,
      'kosher_level': _kosher,
      'price_level': _priceLevel,
      'has_delivery': _hasDelivery,
      'has_takeaway': _hasTakeaway,
      'has_outdoor': _hasOutdoor,
      'is_accessible': _isAccessible,
      'has_parking': _hasParking,
      'pet_friendly': _petFriendly,
      'kid_friendly': _kidFriendly,
      'has_wifi': _hasWifi,
      'open_on_shabbat': _openOnShabbat,
      'is_featured': _isFeatured,
      'is_recommended': _isRecommended,
      'featured_start': _dateForColumn(_featuredStart.text, endOfDay: false),
      'featured_end': _dateForColumn(_featuredEnd.text, endOfDay: true),
      'is_verified': _isVerified,
      'noindex': _noindex,
      'meta_title': _t(_metaTitle),
      'meta_description': _t(_metaDesc),
      'meta_keywords': _t(_metaKeywords),
      'og_title': _t(_ogTitle),
      'og_description': _t(_ogDesc),
    };

    try {
      final notifier = ref.read(adminBusinessListProvider.notifier);

      // The row first: everything else hangs off its id.
      final String id;
      if (_rowId != null) {
        id = _rowId!;
        await notifier.updateBusiness(id, fields);
      } else {
        id = await notifier.createBusiness(fields);
        _createdId = id;
      }

      if (_hoursTouched) {
        await notifier.setHours(id, _weekFromForm());
        _hoursTouched = false;
        ref.invalidate(businessHoursProvider(id));
      }
      if (_categoriesTouched) {
        await notifier.setCategories(id, _categoryIds.toList());
        _categoriesTouched = false;
        ref.invalidate(businessCategoryIdsProvider(id));
        ref.invalidate(adminBusinessCategoryNamesProvider);
      }
      if (_menuLoaded) {
        // Lines with no name are rows someone started and left; they are
        // dropped rather than saved blank.
        // Only what changed is written; an untouched menu is not.
        await saveMenuItems(
          id,
          _menuItems
              .where((m) => (m['name'] as String? ?? '').trim().isNotEmpty)
              .toList(),
        );
        ref.invalidate(adminMenuItemsProvider(id));
      }
      await _gallery.save(id);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = 'השמירה נכשלה: ${_errorText(e)}');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// The database's refusal, in words the person can act on where it is one
  /// of the usual ones, and as it came otherwise.
  static String _errorText(Object e) {
    if (e is PostgrestException) {
      return switch (e.code) {
        '23505' => 'כתובת ה-Slug כבר בשימוש אצל עסק אחר',
        '23502' => 'חסר שדה חובה (${e.message})',
        '42501' => 'אין הרשאה לשמור — האם המשתמש מוגדר כמנהל?',
        _ => e.message,
      };
    }
    if (e is StorageException) return 'העלאת תמונה נכשלה (${e.message})';
    return '$e';
  }
}

// ─── Debouncer ───

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

/// One editable menu line.
class _MenuItemRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final VoidCallback onRemove;

  const _MenuItemRow({
    super.key,
    required this.item,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final agorot = item['price_agorot'] as int?;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: _small(
              'קטגוריה',
              item['section'] as String? ?? '',
              (v) => onChanged({...item, 'section': v.isEmpty ? null : v}),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: _small(
              'שם *',
              item['name'] as String? ?? '',
              (v) => onChanged({...item, 'name': v}),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: _small(
              'מחיר ₪',
              // Stored in agorot; shown in shekels.
              agorot == null
                  ? ''
                  : (agorot % 100 == 0
                        ? '${agorot ~/ 100}'
                        : (agorot / 100).toStringAsFixed(2)),
              (v) {
                final shekels = double.tryParse(v.trim());
                onChanged({
                  ...item,
                  'price_agorot': shekels == null
                      ? null
                      : (shekels * 100).round(),
                });
              },
              keyboardType: TextInputType.number,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: AppColors.error),
            onPressed: onRemove,
            tooltip: 'הסרה',
          ),
        ],
      ),
    );
  }

  Widget _small(
    String label,
    String value,
    ValueChanged<String> onChanged, {
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      initialValue: value,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontFamily: AppFonts.rubik, fontSize: 12),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
