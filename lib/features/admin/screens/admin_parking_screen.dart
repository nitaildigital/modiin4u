import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show PostgrestException, StorageException;
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/network_photo.dart';
import '../providers/admin_parking_provider.dart';
import '../widgets/image_upload_field.dart';

/// חניונים — the lots on the parking screens and the app map's Parkings
/// layer.
///
/// The client asked for every car park in the city with its location
/// (handover, point 4). Each one he enters here is a pin and a card; hiding
/// one takes it off both and keeps the row.
class AdminParkingScreen extends ConsumerStatefulWidget {
  const AdminParkingScreen({super.key});

  @override
  ConsumerState<AdminParkingScreen> createState() => _AdminParkingScreenState();
}

class _AdminParkingScreenState extends ConsumerState<AdminParkingScreen> {
  String _activeFilter = '';
  final _searchController = TextEditingController();
  final _debouncer = _Debouncer(milliseconds: 400);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setFilter(String filter) {
    setState(() => _activeFilter = filter);
    ref
        .read(adminParkingListProvider.notifier)
        .setActiveFilter(filter.isEmpty ? null : filter);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminParkingListProvider);
    final isWide = MediaQuery.of(context).size.width > 900;
    // `valueOrNull`, not `whenData(...).value`: the latter rethrows on a
    // failed load and greys the whole section.
    final count = async.valueOrNull?.length;

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
                    hintText: 'חיפוש חניון...',
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
                        .read(adminParkingListProvider.notifier)
                        .setSearch(v.isEmpty ? null : v);
                  }),
                ),
              ),
              const SizedBox(width: 12),
              _FilterChip('הכל', _activeFilter.isEmpty, () => _setFilter('')),
              _FilterChip(
                'מוצג',
                _activeFilter == 'active',
                () => _setFilter('active'),
              ),
              _FilterChip(
                'מוסתר',
                _activeFilter == 'inactive',
                () => _setFilter('inactive'),
              ),
              const Spacer(),
              if (count != null)
                Text(
                  '$count חניונים',
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
                  'חניון חדש',
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
                // The likeliest cause on a fresh database: migration 00030
                // has not been applied, so the table does not exist yet.
                'שגיאה: $e',
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  color: AppColors.error,
                ),
              ),
            ),
            data: (lots) {
              if (lots.isEmpty) {
                return Center(
                  child: Text(
                    'אין חניונים. חניון שנוסף כאן מופיע בעמוד החניה ובמפת האפליקציה.',
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
                        const SizedBox(width: 48),
                        _Col('שם', flex: 3),
                        _Col('כתובת', flex: 3),
                        if (isWide) _Col('מיקום', flex: 2),
                        _Col('סטטוס', flex: 1),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      itemCount: lots.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: AppColors.border.withValues(alpha: 0.3),
                      ),
                      itemBuilder: (_, i) => _buildRow(lots[i], isWide),
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

  Widget _buildRow(Map<String, dynamic> p, bool isWide) {
    final active = p['is_active'] as bool? ?? true;
    final nameEn = (p['name_en'] as String?)?.trim() ?? '';
    final lat = (p['latitude'] as num?)?.toDouble();
    final lng = (p['longitude'] as num?)?.toDouble();
    final small = TextStyle(
      fontFamily: AppFonts.rubik,
      fontSize: 12,
      color: AppColors.grayText,
    );

    return InkWell(
      onTap: () => _showEditor(lot: p),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            NetworkPhoto(
              url: p['image_url'] as String?,
              width: 38,
              height: 38,
              radius: BorderRadius.circular(6),
              icon: Icons.local_parking,
              iconSize: 16,
            ),
            const SizedBox(width: 10),
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
                  if (nameEn.isNotEmpty)
                    Text(
                      nameEn,
                      style: small.copyWith(color: AppColors.grayLight),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                p['address'] as String? ?? '',
                style: small,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isWide)
              Expanded(
                flex: 2,
                child: Text(
                  lat == null || lng == null
                      ? ''
                      : '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                  style: small,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                ),
              ),
            Expanded(
              flex: 1,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: _StatusPill(
                  active ? 'מוצג' : 'מוסתר',
                  active ? AppColors.success : AppColors.grayLight,
                ),
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert,
                size: 18,
                color: AppColors.grayLight,
              ),
              onSelected: (v) => switch (v) {
                'edit' => _showEditor(lot: p),
                _ => _toggle(p),
              },
              itemBuilder: (_) => [
                _menuItem('edit', 'עריכה'),
                // Hidden, not deleted — shown again from the same menu.
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
    child: Text(
      label,
      style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
    ),
  );

  /// Awaited, with a message when it fails, so a refused update is not
  /// silently lost.
  Future<void> _toggle(Map<String, dynamic> p) async {
    try {
      await ref
          .read(adminParkingListProvider.notifier)
          .toggleActive(p['id'] as String);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('העדכון נכשל: $e')),
      );
    }
  }

  void _showEditor({Map<String, dynamic>? lot}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ParkingEditorDialog(lot: lot),
    );
  }
}

// ─── Editor Dialog ───

class _ParkingEditorDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? lot;
  const _ParkingEditorDialog({this.lot});

  @override
  ConsumerState<_ParkingEditorDialog> createState() =>
      _ParkingEditorDialogState();
}

class _ParkingEditorDialogState extends ConsumerState<_ParkingEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late final TextEditingController _name;
  late final TextEditingController _nameEn;
  late final TextEditingController _address;
  late final TextEditingController _coordinates;
  late final TextEditingController _hours;
  late final TextEditingController _priceNote;
  late final TextEditingController _capacity;
  late final TextEditingController _notes;
  late final TextEditingController _sortOrder;
  late final TextEditingController _imageUrl;
  bool _isActive = true;

  /// Free, paid, or null — not stated, which the screens leave unsaid rather
  /// than show as paid.
  bool? _isFree;

  /// Why the last save failed, shown in the dialog rather than behind it.
  String? _error;

  bool get _isEditing => widget.lot != null;

  @override
  void initState() {
    super.initState();
    final p = widget.lot;
    String text(String key) => (p?[key] as String?) ?? '';
    _name = TextEditingController(text: text('name'));
    _nameEn = TextEditingController(text: text('name_en'));
    _address = TextEditingController(text: text('address'));
    final lat = p?['latitude'] as num?;
    final lng = p?['longitude'] as num?;
    _coordinates = TextEditingController(
      text: lat == null || lng == null ? '' : '$lat, $lng',
    );
    _hours = TextEditingController(text: text('hours'));
    _priceNote = TextEditingController(text: text('price_note'));
    _capacity = TextEditingController(
      text: (p?['capacity'] as int?)?.toString() ?? '',
    );
    _isFree = p?['is_free'] as bool?;
    _notes = TextEditingController(text: text('notes'));
    _sortOrder = TextEditingController(
      text: (p?['sort_order'] as int?)?.toString() ?? '0',
    );
    _imageUrl = TextEditingController(text: text('image_url'));
    _isActive = p?['is_active'] as bool? ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _nameEn.dispose();
    _address.dispose();
    _coordinates.dispose();
    _hours.dispose();
    _priceNote.dispose();
    _capacity.dispose();
    _notes.dispose();
    _sortOrder.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  /// "31.8928, 35.0104" — what Google Maps copies when you right-click a
  /// place — as a latitude and a longitude, or null if it is not that.
  static (double, double)? _parseCoordinates(String input) {
    final parts = input
        .split(RegExp(r'[,\s]+'))
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.length != 2) return null;
    final lat = double.tryParse(parts[0]);
    final lng = double.tryParse(parts[1]);
    if (lat == null || lng == null) return null;
    if (lat.abs() > 90 || lng.abs() > 180) return null;
    return (lat, lng);
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
                        _isEditing ? 'עריכת חניון' : 'חניון חדש',
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
                        'שם החניון *',
                        _name,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'שדה חובה' : null,
                      ),
                      _field('שם באנגלית (לאפליקציה באנגלית)', _nameEn),
                      _field('כתובת', _address),
                      _field(
                        'קואורדינטות *',
                        _coordinates,
                        hint: '31.8928, 35.0104',
                        ltr: true,
                        validator: (v) => _parseCoordinates(v ?? '') == null
                            ? 'קו רוחב, קו אורך — למשל 31.8928, 35.0104'
                            : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Text(
                          'בגוגל מפות: לחיצה ימנית על החניון, ולחיצה על '
                          'המספרים שבראש התפריט מעתיקה אותם.',
                          style: TextStyle(
                            fontFamily: AppFonts.rubik,
                            fontSize: 12,
                            color: AppColors.adminTextLight,
                          ),
                        ),
                      ),
                      _field('שעות פתיחה', _hours, hint: 'למשל: פתוח 24/7'),
                      _freeChoice(),
                      _field(
                        'מחיר',
                        _priceNote,
                        hint: 'למשל: 2 שעות ראשונות חינם, אחר כך 5 ₪ לשעה',
                      ),
                      _field(
                        'מספר מקומות חניה',
                        _capacity,
                        hint: 'ריק אם לא ידוע',
                        ltr: true,
                        validator: (v) {
                          final t = v?.trim() ?? '';
                          if (t.isEmpty) return null;
                          final n = int.tryParse(t);
                          return n == null || n <= 0
                              ? 'מספר שלם גדול מאפס, או ריק'
                              : null;
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Text(
                          'מספר המקומות בחניון, לא כמה פנויים עכשיו — אין לנו '
                          'מקור לתפוסה.',
                          style: TextStyle(
                            fontFamily: AppFonts.rubik,
                            fontSize: 12,
                            color: AppColors.adminTextLight,
                          ),
                        ),
                      ),
                      _field(
                        'הערות (תו תושב, כניסה וכו׳)',
                        _notes,
                        maxLines: 4,
                      ),
                      _field('סדר מיון', _sortOrder, ltr: true),
                      const SizedBox(height: 8),
                      ImageUploadField(
                        label: 'תמונה',
                        controller: _imageUrl,
                        folder: 'parking',
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: Text(
                          'מוצג באתר ובאפליקציה',
                          style: TextStyle(
                            fontFamily: AppFonts.rubik,
                            fontSize: 14,
                          ),
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
                                _isEditing ? 'שמור' : 'צור חניון',
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
      ),
    );
  }

  /// חינם / בתשלום / לא צוין. "לא צוין" saves null, so a lot is never shown
  /// as paid (or free) because nobody said.
  Widget _freeChoice() {
    const options = [(null, 'לא צוין'), (true, 'חינם'), (false, 'בתשלום')];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            'חניה בחינם?',
            style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
          ),
          const SizedBox(width: 12),
          for (final (value, label) in options)
            _FilterChip(
              label,
              _isFree == value,
              () => setState(() => _isFree = value),
            ),
        ],
      ),
    );
  }

  String? _orNull(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    final (lat, lng) = _parseCoordinates(_coordinates.text)!;
    setState(() => _saving = true);

    final fields = <String, dynamic>{
      'name': _name.text.trim(),
      'name_en': _orNull(_nameEn),
      'address': _orNull(_address),
      'latitude': lat,
      'longitude': lng,
      'hours': _orNull(_hours),
      'price_note': _orNull(_priceNote),
      'is_free': _isFree,
      'capacity': int.tryParse(_capacity.text.trim()),
      'notes': _orNull(_notes),
      'image_url': _orNull(_imageUrl),
      'sort_order': int.tryParse(_sortOrder.text.trim()) ?? 0,
      'is_active': _isActive,
    };

    try {
      final notifier = ref.read(adminParkingListProvider.notifier);
      final id = widget.lot?['id'] as String?;
      if (id != null) {
        await notifier.update(id, fields);
      } else {
        await notifier.create(fields);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = switch (e) {
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
