import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../municipal/models/municipal_place.dart';
import '../providers/admin_municipal_places_provider.dart';

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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: isWide ? 320 : 200,
                    height: 40,
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'חיפוש לפי שם, כתובת או טלפון...',
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
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                      ),
                      onChanged: (v) => _debouncer.run(
                        () => _notifier.setSearch(v.isEmpty ? null : v),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _FilterChip('הכל', _activeFilter.isEmpty, () {
                    setState(() => _activeFilter = '');
                    _notifier.setActiveFilter(null);
                  }),
                  _FilterChip('מוצג', _activeFilter == 'active', () {
                    setState(() => _activeFilter = 'active');
                    _notifier.setActiveFilter('active');
                  }),
                  _FilterChip('מוסתר', _activeFilter == 'inactive', () {
                    setState(() => _activeFilter = 'inactive');
                    _notifier.setActiveFilter('inactive');
                  }),
                  const Spacer(),
                  if (count != null)
                    Text(
                      '$count רשומות',
                      style: TextStyle(
                        fontFamily: AppFonts.rubik,
                        fontSize: 13,
                        color: AppColors.grayText,
                      ),
                    ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    onPressed: () => _showEditor(),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(
                      'רשומה חדשה',
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
              const SizedBox(height: 10),
              Wrap(
                spacing: 0,
                runSpacing: 6,
                children: [
                  _FilterChip('כל הקטגוריות', _category.isEmpty, () {
                    setState(() => _category = '');
                    _notifier.setCategory(null);
                  }),
                  for (final e in kMunicipalCategories.entries)
                    _FilterChip(e.value.he, _category == e.key, () {
                      setState(() => _category = e.key);
                      _notifier.setCategory(e.key);
                    }),
                ],
              ),
            ],
          ),
        ),

        // ─── List ───
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                'שגיאה: $e',
                style: TextStyle(fontFamily: AppFonts.rubik, color: AppColors.error),
              ),
            ),
            data: (rows) {
              if (rows.isEmpty) {
                return Center(
                  child: Text(
                    'אין רשומות. רשומה שנוספה כאן מופיעה באריח המתאים בעמוד העירייה.',
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
    final category = kMunicipalCategories[p['category']]?.he ?? '';
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
                    'panel' => 'הוזן בפאנל',
                    'national' => 'מספר ארצי',
                    'osm' => 'OpenStreetMap',
                    'gov' => 'מידע ממשלתי',
                    _ => source,
                  },
                  style: small.copyWith(color: AppColors.grayLight),
                ),
              ),
            _StatusPill(
              active ? 'מוצג' : 'מוסתר',
              active ? AppColors.success : AppColors.grayLight,
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 18, color: AppColors.grayLight),
              onSelected: (v) => v == 'edit' ? _showEditor(place: p) : _toggle(p),
              itemBuilder: (_) => [
                _menuItem('edit', 'עריכה'),
                _menuItem('toggle', active ? 'הסתרה' : 'הצגה מחדש'),
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
        SnackBar(content: Text('העדכון נכשל: $e')),
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
          textDirection: TextDirection.rtl,
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
                        _isEditing ? 'עריכת רשומה' : 'רשומה חדשה',
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
                            labelText: 'קטגוריה *',
                            labelStyle: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          items: [
                            for (final e in kMunicipalCategories.entries)
                              DropdownMenuItem(
                                value: e.key,
                                child: Text(
                                  e.value.he,
                                  style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
                                ),
                              ),
                          ],
                          onChanged: (v) => setState(() => _category = v ?? _category),
                        ),
                      ),
                      _field(
                        'שם *',
                        _name,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'שדה חובה' : null,
                      ),
                      _field('שם באנגלית (לאפליקציה באנגלית)', _nameEn),
                      _field('כתובת', _address),
                      _field('טלפון', _phone, ltr: true),
                      _field(
                        'קואורדינטות',
                        _coordinates,
                        hint: '31.8928, 35.0104',
                        ltr: true,
                        validator: (v) {
                          final t = v?.trim() ?? '';
                          if (t.isEmpty) return null;
                          return _parseCoordinates(t) == null
                              ? 'קו רוחב, קו אורך — למשל 31.8928, 35.0104 — או ריק'
                              : null;
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Text(
                          'לא חובה (למספר חירום אין מיקום). בגוגל מפות: לחיצה ימנית '
                          'על המקום, ולחיצה על המספרים שבראש התפריט מעתיקה אותם.',
                          style: TextStyle(
                            fontFamily: AppFonts.rubik,
                            fontSize: 12,
                            color: AppColors.adminTextLight,
                          ),
                        ),
                      ),
                      _field('הערות (שעות, זרם, מגזר וכו׳)', _notes, maxLines: 3),
                      _field('סדר מיון', _sortOrder, ltr: true),
                      SwitchListTile(
                        title: Text(
                          'מוצג באתר ובאפליקציה',
                          style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14),
                        ),
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                        activeThumbColor: AppColors.turquoise,
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
                        child: Text('ביטול', style: TextStyle(fontFamily: AppFonts.rubik)),
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
                                _isEditing ? 'שמור' : 'צור רשומה',
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
              ? 'השמירה נכשלה: ${e.message}'
              : 'השמירה נכשלה: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ─── Shared widgets ───

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
    _pending = Future.delayed(Duration(milliseconds: milliseconds)).then((_) => action());
  }
}
