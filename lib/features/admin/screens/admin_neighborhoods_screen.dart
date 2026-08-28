import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/admin_neighborhoods_provider.dart';

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
                hintText: 'חיפוש שכונה...',
                hintStyle:
                    GoogleFonts.rubik(fontSize: 13, color: AppColors.grayLight),
                prefixIcon:
                    const Icon(Icons.search, size: 18, color: AppColors.grayLight),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.turquoise)),
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
                  .whenData((list) => Text('${list.length} שכונות',
                      style: GoogleFonts.rubik(
                          fontSize: 13, color: AppColors.grayText)))
                  .value ??
              const SizedBox.shrink(),
          const SizedBox(width: 16),
          FilledButton.icon(
            onPressed: () => _showEditor(context, ref),
            icon: const Icon(Icons.add, size: 18),
            label: Text('שכונה חדשה', style: GoogleFonts.rubik(fontSize: 13)),
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
          data: (neighborhoods) {
            if (neighborhoods.isEmpty) {
              return Center(
                  child: Text('אין שכונות',
                      style: GoogleFonts.rubik(color: AppColors.grayText)));
            }
            return Column(children: [
              // Header
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
                  _Col('slug', flex: 2),
                  if (isWide) _Col('תושבים', flex: 1),
                  if (isWide) _Col('עסקים', flex: 1),
                  _Col('סטטוס', flex: 1),
                  const SizedBox(width: 40),
                ]),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: neighborhoods.length,
                  separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: AppColors.border.withValues(alpha: 0.3)),
                  itemBuilder: (_, i) {
                    final n = neighborhoods[i];
                    final active = n['is_active'] as bool? ?? true;
                    return InkWell(
                      onTap: () => _showEditor(context, ref, neighborhood: n),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        child: Row(children: [
                          Expanded(
                              flex: 3,
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(n['name'] as String? ?? '',
                                        style: GoogleFonts.rubik(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.navy)),
                                    if ((n['description'] as String?)
                                            ?.isNotEmpty ==
                                        true)
                                      Text(n['description'] as String,
                                          style: GoogleFonts.rubik(
                                              fontSize: 11,
                                              color: AppColors.grayLight),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                  ])),
                          Expanded(
                              flex: 2,
                              child: Text(n['slug'] as String? ?? '',
                                  style: GoogleFonts.rubik(
                                      fontSize: 12,
                                      color: AppColors.grayText))),
                          if (isWide)
                            Expanded(
                                flex: 1,
                                child: Text(
                                    '${n['resident_count'] ?? 0}',
                                    style: GoogleFonts.rubik(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500))),
                          if (isWide)
                            Expanded(
                                flex: 1,
                                child: Text(
                                    '${n['business_count'] ?? 0}',
                                    style: GoogleFonts.rubik(fontSize: 13))),
                          Expanded(
                              flex: 1,
                              child: _StatusPill(
                                  active ? 'פעיל' : 'לא פעיל',
                                  active
                                      ? AppColors.success
                                      : AppColors.grayLight)),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert,
                                size: 18, color: AppColors.grayLight),
                            onSelected: (v) => _handleAction(v, n),
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                  value: 'edit',
                                  child: Text('עריכה',
                                      style:
                                          GoogleFonts.rubik(fontSize: 13))),
                              PopupMenuItem(
                                  value: 'toggle',
                                  child: Text(
                                      active ? 'השבת' : 'הפעל',
                                      style:
                                          GoogleFonts.rubik(fontSize: 13))),
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
            title: Text('מחיקת שכונה',
                style: GoogleFonts.rubik(fontWeight: FontWeight.w700)),
            content: Text('למחוק את "${n['name']}"?',
                style: GoogleFonts.rubik()),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('ביטול', style: GoogleFonts.rubik())),
              TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    notifier.deleteNeighborhood(id);
                  },
                  child: Text('מחק',
                      style: GoogleFonts.rubik(color: AppColors.error))),
            ],
          ),
        );
    }
  }

  void _showEditor(BuildContext context, WidgetRef ref,
      {Map<String, dynamic>? neighborhood}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) =>
          _NeighborhoodEditorDialog(neighborhood: neighborhood),
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
  late final TextEditingController _lat;
  late final TextEditingController _lng;
  bool _isActive = true;

  bool get _isEditing => widget.neighborhood != null;

  @override
  void initState() {
    super.initState();
    final n = widget.neighborhood;
    _name = TextEditingController(text: n?['name'] as String? ?? '');
    _slug = TextEditingController(text: n?['slug'] as String? ?? '');
    _description =
        TextEditingController(text: n?['description'] as String? ?? '');
    _sortOrder = TextEditingController(
        text: (n?['sort_order'] as int?)?.toString() ?? '0');
    _lat = TextEditingController(
        text: (n?['latitude'] as num?)?.toString() ?? '');
    _lng = TextEditingController(
        text: (n?['longitude'] as num?)?.toString() ?? '');
    _isActive = n?['is_active'] as bool? ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _slug.dispose();
    _description.dispose();
    _sortOrder.dispose();
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 600),
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
                  Text(_isEditing ? 'עריכת שכונה' : 'שכונה חדשה',
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
                      _field('שם שכונה *', _name,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'שדה חובה' : null),
                      _field('Slug *', _slug,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'שדה חובה' : null),
                      _field('תיאור', _description, maxLines: 3),
                      _field('סדר מיון', _sortOrder),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: _field('Latitude', _lat)),
                        const SizedBox(width: 12),
                        Expanded(child: _field('Longitude', _lng)),
                      ]),
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
                        : Text(_isEditing ? 'שמור' : 'צור שכונה',
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
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
      'description': _description.text.isEmpty ? null : _description.text,
      'sort_order': int.tryParse(_sortOrder.text) ?? 0,
      'latitude': double.tryParse(_lat.text),
      'longitude': double.tryParse(_lng.text),
      'is_active': _isActive,
    };

    try {
      final notifier = ref.read(adminNeighborhoodListProvider.notifier);
      if (_isEditing) {
        await notifier.updateNeighborhood(
            widget.neighborhood!['id'] as String, fields);
      } else {
        await notifier.createNeighborhood(fields);
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
                color:
                    selected ? AppColors.turquoise : AppColors.border,
                width: 0.5),
          ),
          child: Text(label,
              style: GoogleFonts.rubik(
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected
                      ? AppColors.turquoise
                      : AppColors.grayText)),
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
