import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../municipal/models/municipal_place.dart';
import '../providers/admin_municipal_places_provider.dart';
import '../admin_language.dart';
import '../ui/admin_kit.dart';

/// מוסדות עירוניים — what the Municipal page's service tiles list.
///
/// The client: public institutions (with synagogues), clinics, schools and
/// kindergartens, bus and train stations, and the emergency numbers. Each
/// row he adds or edits here appears on its tile; hiding one takes it off
/// and keeps the row. Rows brought in from an outside source say where from.
class AdminMunicipalPlacesScreen extends ConsumerStatefulWidget {
  const AdminMunicipalPlacesScreen({super.key});

  @override
  ConsumerState<AdminMunicipalPlacesScreen> createState() =>
      _AdminMunicipalPlacesScreenState();
}

class _AdminMunicipalPlacesScreenState
    extends ConsumerState<AdminMunicipalPlacesScreen> {
  String _category = '';
  String _activeFilter = '';
  final _searchController = TextEditingController();
  final _debouncer = _Debouncer(milliseconds: 400);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  AdminMunicipalPlacesNotifier get _notifier =>
      ref.read(adminMunicipalPlacesProvider.notifier);

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminMunicipalPlacesProvider);
    final isWide = MediaQuery.of(context).size.width > 900;
    final count = async.valueOrNull?.length;

    return Column(
      children: [
        // ─── Toolbar ───
        AdminListToolbar(
          search: AdminSearchField(
            controller: _searchController,
            width: isWide ? 320 : 200,
            hint: tr('חיפוש לפי שם, כתובת או טלפון...', 'Search by name, address or phone...'),
            onChanged: (v) => _debouncer.run(
              () => _notifier.setSearch(v.isEmpty ? null : v),
            ),
          ),
          filters: [
            AdminFilterChip(tr('הכל', 'All'), _activeFilter.isEmpty, () {
              setState(() => _activeFilter = '');
              _notifier.setActiveFilter(null);
            }),
            AdminFilterChip(tr('מוצג', 'Shown'), _activeFilter == 'active', () {
              setState(() => _activeFilter = 'active');
              _notifier.setActiveFilter('active');
            }),
            AdminFilterChip(tr('מוסתר', 'Hidden'), _activeFilter == 'inactive', () {
              setState(() => _activeFilter = 'inactive');
              _notifier.setActiveFilter('inactive');
            }),
          ],
          count: count == null ? null : tr('$count רשומות', '$count records'),
          actions: [
            AdminToolbarButton(
              label: tr('רשומה חדשה', 'New record'),
              onPressed: () => _showEditor(),
            ),
          ],
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            color: AdminKit.of(context).surface,
            border: Border(bottom: BorderSide(color: AdminKit.of(context).border)),
          ),
          child: Wrap(
            spacing: 0,
            runSpacing: 6,
            children: [
              AdminFilterChip(tr('כל הקטגוריות', 'All categories'), _category.isEmpty, () {
                setState(() => _category = '');
                _notifier.setCategory(null);
              }),
              for (final e in kMunicipalCategories.entries)
                AdminFilterChip(tr(e.value.he, e.value.en), _category == e.key, () {
                  setState(() => _category = e.key);
                  _notifier.setCategory(e.key);
                }),
            ],
          ),
        ),

        // ─── List ───
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                tr('שגיאה: $e', 'Error: $e'),
                style: TextStyle(fontFamily: AppFonts.rubik, color: AppColors.error),
              ),
            ),
            data: (rows) {
              if (rows.isEmpty) {
                return Center(
                  child: Text(
                    tr('אין רשומות. רשומה שנוספה כאן מופיעה באריח המתאים בעמוד העירייה.', 'No records. A record added here appears on the matching tile of the Municipal page.'),
                    style: TextStyle(
                      fontFamily: AppFonts.rubik,
                      color: AppColors.grayText,
                    ),
                  ),
                );
              }
              return ListView.separated(
                itemCount: rows.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  color: AppColors.border.withValues(alpha: 0.3),
                ),
                itemBuilder: (_, i) => _buildRow(rows[i], isWide),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRow(Map<String, dynamic> p, bool isWide) {
    final active = p['is_active'] as bool? ?? true;
    final category = switch (kMunicipalCategories[p['category']]) {
      final c? => tr(c.he, c.en),
      null => '',
    };
    final source = p['source'] as String? ?? 'panel';
    final small = TextStyle(
      fontFamily: AppFonts.rubik,
      fontSize: 12,
      color: AppColors.grayText,
    );
    return InkWell(
      onTap: () => _showEditor(place: p),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p['name'] as String? ?? '',
                    style: TextStyle(
                      fontFamily: AppFonts.rubik,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
                    ),
                  ),
                  Text(category, style: small),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                [p['address'], p['phone']]
                    .whereType<String>()
                    .where((s) => s.trim().isNotEmpty)
                    .join(' · '),
                style: small,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isWide)
              Expanded(
                flex: 1,
                child: Text(
                  switch (source) {
                    'panel' => tr('הוזן בפאנל', 'Entered in the panel'),
                    'national' => tr('מספר ארצי', 'National number'),
                    'osm' => 'OpenStreetMap',
                    'gov' => tr('מידע ממשלתי', 'Government information'),
                    _ => source,
                  },
                  style: small.copyWith(color: AppColors.grayLight),
                ),
              ),
            AdminPill(
              active ? tr('מוצג', 'Shown') : tr('מוסתר', 'Hidden'),
              active ? AdminKit.of(context).success : AdminKit.of(context).muted,
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 18, color: AppColors.grayLight),
              onSelected: (v) => v == 'edit' ? _showEditor(place: p) : _toggle(p),
              itemBuilder: (_) => [
                _menuItem('edit', tr('עריכה', 'Edit')),
                _menuItem('toggle', active ? tr('הסתרה', 'Hide') : tr('הצגה מחדש', 'Show again')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, String label) => PopupMenuItem(
    value: value,
    child: Text(label, style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13)),
  );

  Future<void> _toggle(Map<String, dynamic> p) async {
    try {
      await _notifier.toggleActive(p['id'] as String);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('העדכון נכשל: $e', 'The update failed: $e'))),
      );
    }
  }

  void _showEditor({Map<String, dynamic>? place}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PlaceEditorDialog(
        place: place,
        defaultCategory: _category.isEmpty ? 'institution' : _category,
      ),
    );
  }
}

// ─── Editor ───

class _PlaceEditorDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? place;
  final String defaultCategory;
  const _PlaceEditorDialog({this.place, required this.defaultCategory});

  @override
  ConsumerState<_PlaceEditorDialog> createState() => _PlaceEditorDialogState();
}

class _PlaceEditorDialogState extends ConsumerState<_PlaceEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  String? _error;

  late String _category;
  late final TextEditingController _name;
  late final TextEditingController _nameEn;
  late final TextEditingController _address;
  late final TextEditingController _phone;
  late final TextEditingController _coordinates;
  late final TextEditingController _notes;
  late final TextEditingController _sortOrder;
  bool _isActive = true;

  bool get _isEditing => widget.place != null;

  @override
  void initState() {
    super.initState();
    final p = widget.place;
    String text(String key) => (p?[key] as String?) ?? '';
    _category = p?['category'] as String? ?? widget.defaultCategory;
    _name = TextEditingController(text: text('name'));
    _nameEn = TextEditingController(text: text('name_en'));
    _address = TextEditingController(text: text('address'));
    _phone = TextEditingController(text: text('phone'));
    final lat = p?['latitude'] as num?;
    final lng = p?['longitude'] as num?;
    _coordinates = TextEditingController(
      text: lat == null || lng == null ? '' : '$lat, $lng',
    );
    _notes = TextEditingController(text: text('notes'));
    _sortOrder = TextEditingController(
      text: (p?['sort_order'] as int?)?.toString() ?? '0',
    );
    _isActive = p?['is_active'] as bool? ?? true;
  }

  @override
  void dispose() {
    for (final c in [_name, _nameEn, _address, _phone, _coordinates, _notes, _sortOrder]) {
      c.dispose();
    }
    super.dispose();
  }

  /// "31.8928, 35.0104" — what Google Maps copies on a right-click — or
  /// null when the field is empty or not that. A location is optional.
  static (double, double)? _parseCoordinates(String input) {
    final parts = input.split(RegExp(r'[,\s]+')).where((s) => s.isNotEmpty).toList();
    if (parts.length != 2) return null;
    final lat = double.tryParse(parts[0]);
    final lng = double.tryParse(parts[1]);
    if (lat == null || lng == null || lat.abs() > 90 || lng.abs() > 180) return null;
    return (lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 720),
        child: Directionality(
          textDirection: adminDir,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: const BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _isEditing ? tr('עריכת רשומה', 'Edit record') : tr('רשומה חדשה', 'New record'),
                        style: TextStyle(
                          fontFamily: AppFonts.rubik,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DropdownButtonFormField<String>(
                          initialValue: _category,
                          decoration: InputDecoration(
                            labelText: tr('קטגוריה *', 'Category *'),
                            labelStyle: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          items: [
                            for (final e in kMunicipalCategories.entries)
                              DropdownMenuItem(
                                value: e.key,
                                child: Text(
                                  tr(e.value.he, e.value.en),
                                  style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
                                ),
                              ),
                          ],
                          onChanged: (v) => setState(() => _category = v ?? _category),
                        ),
                      ),
                      _field(
                        tr('שם *', 'Name *'),
                        _name,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? tr('שדה חובה', 'Required field') : null,
                      ),
                      _field(tr('שם באנגלית (לאפליקציה באנגלית)', 'English name (for the app in English)'), _nameEn),
                      _field(tr('כתובת', 'Address'), _address),
                      _field(tr('טלפון', 'Phone'), _phone, ltr: true),
                      _field(
                        tr('קואורדינטות', 'Coordinates'),
                        _coordinates,
                        hint: '31.8928, 35.0104',
                        ltr: true,
                        validator: (v) {
                          final t = v?.trim() ?? '';
                          if (t.isEmpty) return null;
                          return _parseCoordinates(t) == null
                              ? tr('קו רוחב, קו אורך — למשל 31.8928, 35.0104 — או ריק', 'Latitude, longitude — for example 31.8928, 35.0104 — or empty')
                              : null;
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Text(
                          tr('לא חובה (למספר חירום אין מיקום). בגוגל מפות: לחיצה ימנית '
                          'על המקום, ולחיצה על המספרים שבראש התפריט מעתיקה אותם.', 'Optional (an emergency number has no location). In Google Maps: right-click the place, and clicking the numbers at the top of the menu copies them.'),
                          style: TextStyle(
                            fontFamily: AppFonts.rubik,
                            fontSize: 12,
                            color: AppColors.adminTextLight,
                          ),
                        ),
                      ),
                      _field(tr('הערות (שעות, זרם, מגזר וכו׳)', 'Notes (hours, stream, sector, etc.)'), _notes, maxLines: 3),
                      _field(tr('סדר מיון', 'Sort order'), _sortOrder, ltr: true),
                      SwitchListTile(
                        title: Text(
                          tr('מוצג באתר ובאפליקציה', 'Shown on the site and in the app'),
                          style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14),
                        ),
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                        child: Text(tr('ביטול', 'Cancel'), style: TextStyle(fontFamily: AppFonts.rubik)),
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
                                _isEditing ? tr('שמור', 'Save') : tr('צור רשומה', 'Create record'),
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
    String? hint,
    bool ltr = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        textDirection: ltr ? TextDirection.ltr : null,
        style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  String? _orNull(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    final coords = _parseCoordinates(_coordinates.text.trim());
    setState(() => _saving = true);
    final fields = <String, dynamic>{
      'category': _category,
      'name': _name.text.trim(),
      'name_en': _orNull(_nameEn),
      'address': _orNull(_address),
      'phone': _orNull(_phone),
      'latitude': coords?.$1,
      'longitude': coords?.$2,
      'notes': _orNull(_notes),
      'sort_order': int.tryParse(_sortOrder.text.trim()) ?? 0,
      'is_active': _isActive,
    };
    try {
      final notifier = ref.read(adminMunicipalPlacesProvider.notifier);
      final id = widget.place?['id'] as String?;
      if (id != null) {
        await notifier.update(id, fields);
      } else {
        await notifier.create(fields);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is PostgrestException
              ? tr('השמירה נכשלה: ${e.message}', 'Saving failed: ${e.message}')
              : tr('השמירה נכשלה: $e', 'Saving failed: $e'),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ─── Shared widgets ───

class _Debouncer {
  final int milliseconds;
  _Debouncer({required this.milliseconds});

  Future<void>? _pending;

  void run(VoidCallback action) {
    _pending?.ignore();
    _pending = Future.delayed(Duration(milliseconds: milliseconds)).then((_) => action());
  }
}
