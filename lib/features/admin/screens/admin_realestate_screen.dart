import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/admin_realestate_provider.dart';

class AdminRealEstateScreen extends ConsumerStatefulWidget {
  const AdminRealEstateScreen({super.key});

  @override
  ConsumerState<AdminRealEstateScreen> createState() => _AdminRealEstateScreenState();
}

class _AdminRealEstateScreenState extends ConsumerState<AdminRealEstateScreen> {
  String _typeFilter = '';
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
    final listingsAsync = ref.watch(adminListingListProvider);
    final isWide = MediaQuery.of(context).size.width > 900;

    return Column(children: [
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
                hintText: 'חיפוש כתובת / שכונה...',
                hintStyle: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayLight),
                prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.grayLight),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.turquoise)),
              ),
              onChanged: (v) => _debouncer.run(() {
                ref.read(adminListingListProvider.notifier).setSearch(v.isEmpty ? null : v);
              }),
            ),
          ),
          const SizedBox(width: 12),

          // Type filters
          _FilterChip('הכל', _typeFilter.isEmpty && _statusFilter.isEmpty, () {
            setState(() { _typeFilter = ''; _statusFilter = ''; });
            ref.read(adminListingListProvider.notifier).setTypeFilter(null);
            ref.read(adminListingListProvider.notifier).setStatusFilter(null);
          }),
          _FilterChip('השכרה', _typeFilter == 'rent', () {
            setState(() { _typeFilter = 'rent'; _statusFilter = ''; });
            ref.read(adminListingListProvider.notifier).setTypeFilter('rent');
            ref.read(adminListingListProvider.notifier).setStatusFilter(null);
          }),
          _FilterChip('מכירה', _typeFilter == 'sale', () {
            setState(() { _typeFilter = 'sale'; _statusFilter = ''; });
            ref.read(adminListingListProvider.notifier).setTypeFilter('sale');
            ref.read(adminListingListProvider.notifier).setStatusFilter(null);
          }),

          if (isWide) ...[
            Container(width: 1, height: 24, margin: const EdgeInsets.symmetric(horizontal: 8), color: AppColors.border),
            _FilterChip('פעיל', _statusFilter == 'active', () {
              setState(() => _statusFilter = 'active');
              ref.read(adminListingListProvider.notifier).setStatusFilter('active');
            }),
            _FilterChip('ממתין', _statusFilter == 'pending', () {
              setState(() => _statusFilter = 'pending');
              ref.read(adminListingListProvider.notifier).setStatusFilter('pending');
            }),
          ],

          const Spacer(),
          listingsAsync.whenData((list) => Text('${list.length} נכסים', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText))).value ?? const SizedBox.shrink(),
          const SizedBox(width: 16),
          FilledButton.icon(
            onPressed: () => _showListingEditor(context, ref),
            icon: const Icon(Icons.add, size: 18),
            label: Text('נכס חדש', style: GoogleFonts.rubik(fontSize: 13)),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.turquoise,
              minimumSize: const Size(0, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ]),
      ),

      // ─── Table ───
      Expanded(
        child: listingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text('שגיאה בטעינת נכסים', style: GoogleFonts.rubik(color: AppColors.error)),
            Text('$e', style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayText)),
            const SizedBox(height: 12),
            TextButton(onPressed: () => ref.read(adminListingListProvider.notifier).load(), child: const Text('נסה שוב')),
          ])),
          data: (listings) {
            if (listings.isEmpty) {
              return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.apartment_outlined, size: 48, color: AppColors.grayLight.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text('אין נכסים', style: GoogleFonts.rubik(color: AppColors.grayText)),
              ]));
            }
            return _ListingTable(listings: listings, isWide: isWide, onTap: (l) => _showListingEditor(context, ref, listing: l), onAction: _handleAction);
          },
        ),
      ),
    ]);
  }

  void _handleAction(String action, Map<String, dynamic> listing) {
    final notifier = ref.read(adminListingListProvider.notifier);
    final id = listing['id'] as String;
    switch (action) {
      case 'edit':
        _showListingEditor(context, ref, listing: listing);
      case 'activate':
        notifier.updateStatus(id, 'active');
      case 'sold':
        notifier.updateStatus(id, listing['type'] == 'rent' ? 'rented' : 'sold');
      case 'expire':
        notifier.updateStatus(id, 'expired');
      case 'delete':
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('מחיקת נכס', style: GoogleFonts.rubik(fontWeight: FontWeight.w700)),
            content: Text('למחוק את "${listing['address']}"?', style: GoogleFonts.rubik()),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text('ביטול', style: GoogleFonts.rubik())),
              TextButton(onPressed: () { Navigator.pop(ctx); notifier.deleteListing(id); }, child: Text('מחק', style: GoogleFonts.rubik(color: AppColors.error))),
            ],
          ),
        );
    }
  }

  void _showListingEditor(BuildContext context, WidgetRef ref, {Map<String, dynamic>? listing}) {
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => _ListingEditorDialog(listing: listing));
  }
}

// ─── Listing Table ───

class _ListingTable extends StatelessWidget {
  final List<Map<String, dynamic>> listings;
  final bool isWide;
  final void Function(Map<String, dynamic>) onTap;
  final void Function(String, Map<String, dynamic>) onAction;
  const _ListingTable({required this.listings, required this.isWide, required this.onTap, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(color: AppColors.surfaceLight, border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5)))),
        child: Row(children: [
          _Col('כתובת', flex: 3),
          _Col('שכונה', flex: 2),
          _Col('סוג', flex: 1),
          _Col('חדרים', flex: 1),
          if (isWide) _Col('מ"ר', flex: 1),
          _Col('מחיר', flex: 2),
          _Col('סטטוס', flex: 1),
          if (isWide) _Col('צפיות', flex: 1),
          const SizedBox(width: 40),
        ]),
      ),
      Expanded(
        child: ListView.separated(
          itemCount: listings.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.border.withValues(alpha: 0.3)),
          itemBuilder: (_, i) {
            final l = listings[i];
            final type = l['type'] as String? ?? 'rent';
            final status = l['status'] as String? ?? 'pending';
            final price = l['price'] as num? ?? 0;
            final isFeatured = l['is_featured'] as bool? ?? false;
            final isBroker = l['is_broker'] as bool? ?? false;

            return InkWell(
              onTap: () => onTap(l),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(children: [
                  Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      if (isFeatured) Padding(padding: const EdgeInsets.only(left: 4), child: Icon(Icons.star, size: 14, color: AppColors.gold)),
                      Flexible(child: Text(l['address'] as String? ?? '', style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy), overflow: TextOverflow.ellipsis)),
                    ]),
                    if (isBroker) Text('מתווך', style: GoogleFonts.rubik(fontSize: 10, color: AppColors.grayLight)),
                  ])),
                  Expanded(flex: 2, child: Text(l['neighborhood'] as String? ?? '', style: GoogleFonts.rubik(fontSize: 13))),
                  Expanded(flex: 1, child: _TypeBadge(type)),
                  Expanded(flex: 1, child: Text('${l['rooms'] ?? '—'}', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText))),
                  if (isWide) Expanded(flex: 1, child: Text('${l['sqm'] ?? '—'}', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText))),
                  Expanded(flex: 2, child: Text(_formatPrice(price, type), style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navy))),
                  Expanded(flex: 1, child: _StatusPill(status)),
                  if (isWide) Expanded(flex: 1, child: Text('${l['view_count'] ?? 0}', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText))),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18, color: AppColors.grayLight),
                    onSelected: (v) => onAction(v, l),
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'edit', child: Text('עריכה', style: GoogleFonts.rubik(fontSize: 13))),
                      if (status != 'active') PopupMenuItem(value: 'activate', child: Text('הפעל', style: GoogleFonts.rubik(fontSize: 13))),
                      if (status == 'active') PopupMenuItem(value: 'sold', child: Text(type == 'rent' ? 'סמן כהושכר' : 'סמן כנמכר', style: GoogleFonts.rubik(fontSize: 13))),
                      if (status != 'expired') PopupMenuItem(value: 'expire', child: Text('סמן כפג תוקף', style: GoogleFonts.rubik(fontSize: 13))),
                      PopupMenuItem(value: 'delete', child: Text('מחק', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.error))),
                    ],
                  ),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }

  String _formatPrice(num price, String type) {
    if (price >= 1000000) {
      return '₪${(price / 1000000).toStringAsFixed(1)}M';
    }
    if (price >= 1000) {
      return '₪${_numberFormat(price)}${type == 'rent' ? '/חודש' : ''}';
    }
    return '₪$price';
  }

  String _numberFormat(num n) {
    final s = n.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ─── Listing Editor Dialog ───

class _ListingEditorDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? listing;
  const _ListingEditorDialog({this.listing});

  @override
  ConsumerState<_ListingEditorDialog> createState() => _ListingEditorDialogState();
}

class _ListingEditorDialogState extends ConsumerState<_ListingEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late final TextEditingController _address;
  late final TextEditingController _neighborhood;
  late final TextEditingController _price;
  late final TextEditingController _rooms;
  late final TextEditingController _sqm;
  late final TextEditingController _floor;
  late final TextEditingController _totalFloors;
  late final TextEditingController _description;
  late final TextEditingController _contactName;
  late final TextEditingController _contactPhone;

  String _type = 'rent';
  String _status = 'pending';
  bool _isBroker = false;
  bool _hasParking = false;
  bool _hasElevator = false;
  bool _hasBalcony = false;
  bool _hasStorage = false;
  bool _hasMamad = false;
  bool _isFurnished = false;
  bool _isFeatured = false;

  bool get _isEditing => widget.listing != null;

  @override
  void initState() {
    super.initState();
    final l = widget.listing;
    _address = TextEditingController(text: l?['address'] as String? ?? '');
    _neighborhood = TextEditingController(text: l?['neighborhood'] as String? ?? '');
    _price = TextEditingController(text: (l?['price'] as num?)?.toString() ?? '');
    _rooms = TextEditingController(text: (l?['rooms'] as num?)?.toString() ?? '');
    _sqm = TextEditingController(text: (l?['sqm'] as num?)?.toString() ?? '');
    _floor = TextEditingController(text: (l?['floor'] as num?)?.toString() ?? '');
    _totalFloors = TextEditingController(text: (l?['total_floors'] as num?)?.toString() ?? '');
    _description = TextEditingController(text: l?['description'] as String? ?? '');
    _contactName = TextEditingController(text: l?['contact_name'] as String? ?? '');
    _contactPhone = TextEditingController(text: l?['contact_phone'] as String? ?? '');

    _type = l?['type'] as String? ?? 'rent';
    _status = l?['status'] as String? ?? 'pending';
    _isBroker = l?['is_broker'] as bool? ?? false;
    _hasParking = l?['has_parking'] as bool? ?? false;
    _hasElevator = l?['has_elevator'] as bool? ?? false;
    _hasBalcony = l?['has_balcony'] as bool? ?? false;
    _hasStorage = l?['has_storage'] as bool? ?? false;
    _hasMamad = l?['has_mamad'] as bool? ?? false;
    _isFurnished = l?['is_furnished'] as bool? ?? false;
    _isFeatured = l?['is_featured'] as bool? ?? false;
  }

  @override
  void dispose() {
    _address.dispose(); _neighborhood.dispose(); _price.dispose(); _rooms.dispose();
    _sqm.dispose(); _floor.dispose(); _totalFloors.dispose(); _description.dispose();
    _contactName.dispose(); _contactPhone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 700),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Form(
            key: _formKey,
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
                child: Row(children: [
                  Text(_isEditing ? 'עריכת נכס' : 'נכס חדש', style: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
                ]),
              ),

              Expanded(
                child: ListView(padding: const EdgeInsets.all(20), children: [
                  Row(children: [
                    Expanded(child: DropdownButtonFormField<String>(
                      value: _type,
                      decoration: InputDecoration(labelText: 'סוג *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                      items: [
                        DropdownMenuItem(value: 'rent', child: Text('השכרה', style: GoogleFonts.rubik(fontSize: 13))),
                        DropdownMenuItem(value: 'sale', child: Text('מכירה', style: GoogleFonts.rubik(fontSize: 13))),
                      ],
                      onChanged: (v) => setState(() => _type = v!),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _field('מחיר *', _price, hint: _type == 'rent' ? '6000' : '2500000', validator: (v) => v == null || v.isEmpty ? 'שדה חובה' : null)),
                  ]),
                  _field('כתובת *', _address, validator: (v) => v == null || v.isEmpty ? 'שדה חובה' : null),
                  _field('שכונה *', _neighborhood, validator: (v) => v == null || v.isEmpty ? 'שדה חובה' : null),
                  Row(children: [
                    Expanded(child: _field('חדרים', _rooms, hint: '4')),
                    const SizedBox(width: 12),
                    Expanded(child: _field('מ"ר', _sqm, hint: '110')),
                  ]),
                  Row(children: [
                    Expanded(child: _field('קומה', _floor, hint: '3')),
                    const SizedBox(width: 12),
                    Expanded(child: _field('סה"כ קומות', _totalFloors, hint: '6')),
                  ]),
                  _field('תיאור', _description, maxLines: 3),
                  const SizedBox(height: 8),
                  Text('פרטי קשר', style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _field('שם', _contactName)),
                    const SizedBox(width: 12),
                    Expanded(child: _field('טלפון', _contactPhone)),
                  ]),
                  const SizedBox(height: 8),
                  Text('מאפיינים', style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 4, children: [
                    _toggle('חניה', _hasParking, (v) => setState(() => _hasParking = v)),
                    _toggle('מעלית', _hasElevator, (v) => setState(() => _hasElevator = v)),
                    _toggle('מרפסת', _hasBalcony, (v) => setState(() => _hasBalcony = v)),
                    _toggle('מחסן', _hasStorage, (v) => setState(() => _hasStorage = v)),
                    _toggle('ממ"ד', _hasMamad, (v) => setState(() => _hasMamad = v)),
                    _toggle('מרוהט', _isFurnished, (v) => setState(() => _isFurnished = v)),
                    _toggle('מתווך', _isBroker, (v) => setState(() => _isBroker = v)),
                    _toggle('מומלץ', _isFeatured, (v) => setState(() => _isFeatured = v)),
                  ]),
                  const SizedBox(height: 16),
                  Text('סטטוס', style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                    items: [
                      DropdownMenuItem(value: 'pending', child: Text('ממתין', style: GoogleFonts.rubik(fontSize: 13))),
                      DropdownMenuItem(value: 'active', child: Text('פעיל', style: GoogleFonts.rubik(fontSize: 13))),
                      DropdownMenuItem(value: _type == 'rent' ? 'rented' : 'sold', child: Text(_type == 'rent' ? 'הושכר' : 'נמכר', style: GoogleFonts.rubik(fontSize: 13))),
                      DropdownMenuItem(value: 'expired', child: Text('פג תוקף', style: GoogleFonts.rubik(fontSize: 13))),
                    ],
                    onChanged: (v) => setState(() => _status = v!),
                  ),
                ]),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
                child: Row(children: [
                  const Spacer(),
                  TextButton(onPressed: () => Navigator.pop(context), child: Text('ביטול', style: GoogleFonts.rubik())),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(backgroundColor: AppColors.turquoise, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_isEditing ? 'שמור' : 'צור נכס', style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, {int maxLines = 1, String? hint, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller, maxLines: maxLines, validator: validator,
        style: GoogleFonts.rubik(fontSize: 13),
        decoration: InputDecoration(
          labelText: label, hintText: hint,
          labelStyle: GoogleFonts.rubik(fontSize: 13),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
    return FilterChip(
      label: Text(label, style: GoogleFonts.rubik(fontSize: 12)),
      selected: value, onSelected: onChanged,
      selectedColor: AppColors.turquoise.withValues(alpha: 0.15),
      checkmarkColor: AppColors.turquoise,
      side: BorderSide(color: value ? AppColors.turquoise : AppColors.border),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final fields = <String, dynamic>{
      'type': _type,
      'price': num.tryParse(_price.text) ?? 0,
      'address': _address.text,
      'neighborhood': _neighborhood.text,
      'rooms': num.tryParse(_rooms.text),
      'sqm': int.tryParse(_sqm.text),
      'floor': int.tryParse(_floor.text),
      'total_floors': int.tryParse(_totalFloors.text),
      'description': _description.text.isEmpty ? null : _description.text,
      'contact_name': _contactName.text.isEmpty ? null : _contactName.text,
      'contact_phone': _contactPhone.text.isEmpty ? null : _contactPhone.text,
      'status': _status,
      'is_broker': _isBroker,
      'has_parking': _hasParking,
      'has_elevator': _hasElevator,
      'has_balcony': _hasBalcony,
      'has_storage': _hasStorage,
      'has_mamad': _hasMamad,
      'is_furnished': _isFurnished,
      'is_featured': _isFeatured,
    };

    try {
      final notifier = ref.read(adminListingListProvider.notifier);
      if (_isEditing) {
        await notifier.updateListing(widget.listing!['id'] as String, fields);
      } else {
        fields['view_count'] = 0;
        await notifier.createListing(fields);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('שגיאה: $e'), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ─── Shared Widgets ───

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill(this.status);

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'active' => ('פעיל', AppColors.success),
      'pending' => ('ממתין', AppColors.gold),
      'sold' => ('נמכר', AppColors.midBlue),
      'rented' => ('הושכר', AppColors.midBlue),
      'expired' => ('פג תוקף', AppColors.grayLight),
      _ => (status, AppColors.grayLight),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: GoogleFonts.rubik(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge(this.type);

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (type) {
      'rent' => ('השכרה', AppColors.turquoise),
      'sale' => ('מכירה', AppColors.midBlue),
      _ => (type, AppColors.grayLight),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: GoogleFonts.rubik(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _Col extends StatelessWidget {
  final String label;
  final int flex;
  const _Col(this.label, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(flex: flex, child: Text(label, style: GoogleFonts.rubik(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.grayLight)));
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
        onTap: onTap, borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.turquoise.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: selected ? AppColors.turquoise : AppColors.border, width: 0.5),
          ),
          child: Text(label, style: GoogleFonts.rubik(fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? AppColors.turquoise : AppColors.grayText)),
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
