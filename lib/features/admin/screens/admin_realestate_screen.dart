import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/network_photo.dart';
import '../providers/admin_realestate_provider.dart';
import '../widgets/admin_listing_photos_field.dart';

class AdminRealEstateScreen extends ConsumerStatefulWidget {
  const AdminRealEstateScreen({super.key});

  @override
  ConsumerState<AdminRealEstateScreen> createState() =>
      _AdminRealEstateScreenState();
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
                width: isWide ? 280 : 180,
                height: 40,
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'חיפוש כתובת / שכונה...',
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
                        .read(adminListingListProvider.notifier)
                        .setSearch(v.isEmpty ? null : v);
                  }),
                ),
              ),
              const SizedBox(width: 12),

              // Type filters
              _FilterChip(
                'הכל',
                _typeFilter.isEmpty && _statusFilter.isEmpty,
                () {
                  setState(() {
                    _typeFilter = '';
                    _statusFilter = '';
                  });
                  ref
                      .read(adminListingListProvider.notifier)
                      .setKindFilter(null);
                  ref
                      .read(adminListingListProvider.notifier)
                      .setStatusFilter(null);
                },
              ),
              _FilterChip('השכרה', _typeFilter == 'rent', () {
                setState(() {
                  _typeFilter = 'rent';
                  _statusFilter = '';
                });
                ref
                    .read(adminListingListProvider.notifier)
                    .setKindFilter('rent');
                ref
                    .read(adminListingListProvider.notifier)
                    .setStatusFilter(null);
              }),
              _FilterChip('מכירה', _typeFilter == 'sale', () {
                setState(() {
                  _typeFilter = 'sale';
                  _statusFilter = '';
                });
                ref
                    .read(adminListingListProvider.notifier)
                    .setKindFilter('sale');
                ref
                    .read(adminListingListProvider.notifier)
                    .setStatusFilter(null);
              }),

              if (isWide) ...[
                Container(
                  width: 1,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: AppColors.border,
                ),
                _FilterChip('פעיל', _statusFilter == 'active', () {
                  setState(() => _statusFilter = 'active');
                  ref
                      .read(adminListingListProvider.notifier)
                      .setStatusFilter('active');
                }),
                _FilterChip('ממתין', _statusFilter == 'pending', () {
                  setState(() => _statusFilter = 'pending');
                  ref
                      .read(adminListingListProvider.notifier)
                      .setStatusFilter('pending');
                }),
              ],

              const Spacer(),
              listingsAsync
                      .whenData(
                        (list) => Text(
                          '${list.length} נכסים',
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
                onPressed: () => _showListingEditor(context, ref),
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  'נכס חדש',
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
          child: listingsAsync.when(
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
                    'שגיאה בטעינת נכסים',
                    style: TextStyle(
                      fontFamily: AppFonts.rubik,
                      color: AppColors.error,
                    ),
                  ),
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
                        ref.read(adminListingListProvider.notifier).load(),
                    child: const Text('נסה שוב'),
                  ),
                ],
              ),
            ),
            data: (listings) {
              if (listings.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.apartment_outlined,
                        size: 48,
                        color: AppColors.grayLight.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'אין נכסים',
                        style: TextStyle(
                          fontFamily: AppFonts.rubik,
                          color: AppColors.grayText,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return _ListingTable(
                listings: listings,
                isWide: isWide,
                onTap: (l) => _showListingEditor(context, ref, listing: l),
                onAction: _handleAction,
              );
            },
          ),
        ),
      ],
    );
  }

  void _handleAction(String action, Map<String, dynamic> listing) {
    final notifier = ref.read(adminListingListProvider.notifier);
    final id = listing['id'] as String;
    switch (action) {
      case 'edit':
        _showListingEditor(context, ref, listing: listing);
      case 'approve':
        notifier.approve(id);
      case 'reject':
        notifier.reject(id);
      case 'activate':
        notifier.updateStatus(id, 'active');
      case 'sold':
        notifier.updateStatus(
          id,
          listing['kind'] == 'rent' ? 'rented' : 'sold',
        );
      case 'expire':
        notifier.updateStatus(id, 'expired');
      case 'delete':
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(
              'מחיקת נכס',
              style: TextStyle(
                fontFamily: AppFonts.rubik,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              'להסיר את "${listing['address']}"? המודעה תרד מהאפליקציה '
              'וניתן יהיה להחזירה על ידי שינוי הסטטוס.',
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
                  notifier.deleteListing(id);
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

  void _showListingEditor(
    BuildContext context,
    WidgetRef ref, {
    Map<String, dynamic>? listing,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ListingEditorDialog(listing: listing),
    );
  }
}

// ─── Listing Table ───

class _ListingTable extends StatelessWidget {
  final List<Map<String, dynamic>> listings;
  final bool isWide;
  final void Function(Map<String, dynamic>) onTap;
  final void Function(String, Map<String, dynamic>) onAction;
  const _ListingTable({
    required this.listings,
    required this.isWide,
    required this.onTap,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
              const SizedBox(width: 62),
              _Col('כתובת', flex: 3),
              _Col('שכונה', flex: 2),
              _Col('סוג', flex: 1),
              _Col('חדרים', flex: 1),
              if (isWide) _Col('מ״ר', flex: 1),
              _Col('מחיר', flex: 2),
              _Col('סטטוס', flex: 1),
              if (isWide) _Col('צפיות', flex: 1),
              const SizedBox(width: 40),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: listings.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: AppColors.border.withValues(alpha: 0.3),
            ),
            itemBuilder: (_, i) {
              final l = listings[i];
              final kind = l['kind'] as String? ?? 'sale';
              final status = l['status'] as String? ?? 'pending';
              final price =
                  (l['kind'] == 'rent' ? l['price_per_month'] : l['price'])
                      as num? ??
                  0;
              final isFeatured = l['is_featured'] as bool? ?? false;
              final isBroker = l['is_broker'] as bool? ?? false;

              return InkWell(
                onTap: () => onTap(l),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      NetworkPhoto(
                        url: l['cover_url'] as String?,
                        width: 52,
                        height: 36,
                        radius: BorderRadius.circular(6),
                        icon: Icons.apartment_outlined,
                        iconSize: 16,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (isFeatured)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: Icon(
                                      Icons.star,
                                      size: 14,
                                      color: AppColors.gold,
                                    ),
                                  ),
                                Flexible(
                                  child: Text(
                                    l['address'] as String? ?? '',
                                    style: TextStyle(
                                      fontFamily: AppFonts.rubik,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.navy,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (isBroker)
                              Text(
                                'מתווך',
                                style: TextStyle(
                                  fontFamily: AppFonts.rubik,
                                  fontSize: 10,
                                  color: AppColors.grayLight,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        // The name comes from the join; the list read a
                        // `neighborhood` key nothing sets, so it was blank.
                        child: Text(
                          (l['neighborhoods'] as Map?)?['name'] as String? ??
                              '',
                          style: TextStyle(
                            fontFamily: AppFonts.rubik,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(flex: 1, child: _TypeBadge(kind)),
                      Expanded(
                        flex: 1,
                        child: Text(
                          '${l['rooms'] ?? '—'}',
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
                            '${l['sqm'] ?? '—'}',
                            style: TextStyle(
                              fontFamily: AppFonts.rubik,
                              fontSize: 13,
                              color: AppColors.grayText,
                            ),
                          ),
                        ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          _formatPrice(price, kind),
                          style: TextStyle(
                            fontFamily: AppFonts.rubik,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                      Expanded(flex: 1, child: _StatusPill(status)),
                      if (isWide)
                        Expanded(
                          flex: 1,
                          child: Text(
                            '${l['view_count'] ?? 0}',
                            style: TextStyle(
                              fontFamily: AppFonts.rubik,
                              fontSize: 13,
                              color: AppColors.grayText,
                            ),
                          ),
                        ),
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert,
                          size: 18,
                          color: AppColors.grayLight,
                        ),
                        onSelected: (v) => onAction(v, l),
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
                          if (status == 'pending') ...[
                            PopupMenuItem(
                              value: 'approve',
                              child: Text(
                                'אישור ופרסום',
                                style: TextStyle(
                                  fontFamily: AppFonts.rubik,
                                  fontSize: 13,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'reject',
                              child: Text(
                                'דחייה',
                                style: TextStyle(
                                  fontFamily: AppFonts.rubik,
                                  fontSize: 13,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                          if (status != 'active' && status != 'pending')
                            PopupMenuItem(
                              value: 'activate',
                              child: Text(
                                'הפעל',
                                style: TextStyle(
                                  fontFamily: AppFonts.rubik,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          if (status == 'active')
                            PopupMenuItem(
                              value: 'sold',
                              child: Text(
                                kind == 'rent' ? 'סמן כהושכר' : 'סמן כנמכר',
                                style: TextStyle(
                                  fontFamily: AppFonts.rubik,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          if (status != 'expired')
                            PopupMenuItem(
                              value: 'expire',
                              child: Text(
                                'סמן כפג תוקף',
                                style: TextStyle(
                                  fontFamily: AppFonts.rubik,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              // The row is not removed; it becomes status = 'removed'.
                              'הסר',
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
  ConsumerState<_ListingEditorDialog> createState() =>
      _ListingEditorDialogState();
}

class _ListingEditorDialogState extends ConsumerState<_ListingEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late final TextEditingController _address;
  late final TextEditingController _price;
  late final TextEditingController _rooms;
  late final TextEditingController _bathrooms;
  late final TextEditingController _sqm;
  late final TextEditingController _floor;
  late final TextEditingController _title;
  late final TextEditingController _totalFloors;
  late final TextEditingController _description;
  late final TextEditingController _contactName;
  late final TextEditingController _contactPhone;
  late final TextEditingController _latitude;
  late final TextEditingController _longitude;

  /// `kind` on the table. It was called `_type` and written to a column
  /// named `type`, which does not exist — so every save from this form was
  /// rejected by PostgREST and creating a listing here never worked.
  String _kind = 'rent';
  String _propertyType = 'apartment';
  String? _neighborhoodId;
  String? _agentId;
  String _status = 'pending';
  DateTime? _availableFrom;
  bool _isBroker = false;
  bool _hasParking = false;
  bool _hasElevator = false;
  bool _hasBalcony = false;
  bool _hasStorage = false;
  bool _hasMamad = false;
  bool _isFurnished = false;
  bool _isAccessible = false;
  bool _isRenovated = false;
  bool _isFeatured = false;

  /// The cover first, then the gallery — see [AdminListingPhotosField].
  List<String> _photos = const [];

  /// Files uploaded while this editor was open. Whatever of them is not in
  /// the listing when it closes is deleted from storage, so a photo tried
  /// and removed, or an editor closed without saving, leaves nothing behind.
  final _uploaded = <String>{};

  /// What the form held when it opened, in the shape [_collect] produces. A
  /// save sends only what differs from it, so a field the form reads
  /// imperfectly is not rewritten by someone who changed the price.
  late final Map<String, dynamic> _baseline;

  bool get _isEditing => widget.listing != null;

  @override
  void initState() {
    super.initState();
    final l = widget.listing;
    String num_(Object? v) => (v as num?)?.toString() ?? '';

    _title = TextEditingController(text: l?['title'] as String? ?? '');
    _address = TextEditingController(text: l?['address'] as String? ?? '');
    // Stored as an id against `neighborhoods`, not as free text.
    _neighborhoodId = l?['neighborhood_id'] as String?;
    _agentId = l?['agent_id'] as String?;
    // A rental is priced in `price_per_month`, a sale in `price`.
    _price = TextEditingController(
      text: l == null
          ? ''
          : num_(l['kind'] == 'rent' ? l['price_per_month'] : l['price']),
    );
    _rooms = TextEditingController(text: num_(l?['rooms']));
    _bathrooms = TextEditingController(text: num_(l?['bathrooms']));
    _sqm = TextEditingController(text: num_(l?['sqm']));
    _floor = TextEditingController(text: num_(l?['floor']));
    _totalFloors = TextEditingController(text: num_(l?['total_floors']));
    _latitude = TextEditingController(text: num_(l?['latitude']));
    _longitude = TextEditingController(text: num_(l?['longitude']));
    _description = TextEditingController(
      text: l?['description'] as String? ?? '',
    );
    _contactName = TextEditingController(
      text: l?['contact_name'] as String? ?? '',
    );
    _contactPhone = TextEditingController(
      text: l?['contact_phone'] as String? ?? '',
    );
    _availableFrom = DateTime.tryParse(l?['available_from'] as String? ?? '');

    _kind = l?['kind'] as String? ?? 'rent';
    _propertyType = l?['property_type'] as String? ?? 'apartment';
    _status = l?['status'] as String? ?? 'pending';
    _isBroker = l?['is_broker'] as bool? ?? false;
    _hasParking = l?['has_parking'] as bool? ?? false;
    _hasElevator = l?['has_elevator'] as bool? ?? false;
    _hasBalcony = l?['has_balcony'] as bool? ?? false;
    _hasStorage = l?['has_storage'] as bool? ?? false;
    _hasMamad = l?['has_mamad'] as bool? ?? false;
    _isFurnished = l?['is_furnished'] as bool? ?? false;
    _isAccessible = l?['is_accessible'] as bool? ?? false;
    _isRenovated = l?['is_renovated'] as bool? ?? false;
    _isFeatured = l?['is_featured'] as bool? ?? false;

    // The sample rows repeat the cover as the gallery's first photo; the
    // website leaves the repeat out, and so does this.
    final cover = l?['cover_url'] as String?;
    _photos = [
      if (cover != null && cover.isNotEmpty) cover,
      for (final u in List<String>.from(l?['gallery'] as List? ?? const []))
        if (u.isNotEmpty && u != cover) u,
    ];

    _baseline = _collect();
  }

  @override
  void dispose() {
    _address.dispose();
    _title.dispose();
    _price.dispose();
    _rooms.dispose();
    _bathrooms.dispose();
    _sqm.dispose();
    _floor.dispose();
    _totalFloors.dispose();
    _latitude.dispose();
    _longitude.dispose();
    _description.dispose();
    _contactName.dispose();
    _contactPhone.dispose();
    super.dispose();
  }

  void _close() {
    AdminListingPhotosField.discard(_uploaded);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 760),
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
                        _isEditing ? 'עריכת נכס' : 'נכס חדש',
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
                        onPressed: _saving ? null : _close,
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // `title` is NOT NULL on the table and the form never
                      // collected it, so even a corrected save would have failed.
                      _field(
                        'כותרת *',
                        _title,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'שדה חובה' : null,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _dropdown<String>(
                              label: 'סוג מודעה *',
                              value: _kind,
                              items: const [
                                ('rent', 'השכרה'),
                                ('sale', 'מכירה'),
                              ],
                              onChanged: (v) => setState(() => _kind = v!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              _kind == 'rent'
                                  ? 'מחיר לחודש (₪) *'
                                  : 'מחיר (₪) *',
                              _price,
                              hint: _kind == 'rent' ? '6000' : '2500000',
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'שדה חובה';
                                return int.tryParse(v) == null
                                    ? 'מספר שלם, בלי פסיקים'
                                    : null;
                              },
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _dropdown<String>(
                              label: 'סוג נכס',
                              value: _propertyType,
                              items: const [
                                ('apartment', 'דירה'),
                                ('penthouse', 'פנטהאוז'),
                                ('garden', 'דירת גן'),
                                ('duplex', 'דופלקס'),
                                ('villa', 'וילה'),
                                ('studio', 'סטודיו'),
                                ('other', 'אחר'),
                              ],
                              onChanged: (v) =>
                                  setState(() => _propertyType = v!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // The neighbourhood is a row in `neighborhoods`, so it is
                          // picked rather than typed — a typed name matched nothing.
                          Expanded(
                            child: _optionsDropdown(
                              label: 'שכונה',
                              none: 'ללא שכונה',
                              value: _neighborhoodId,
                              options: ref.watch(
                                adminNeighborhoodOptionsProvider,
                              ),
                              labelOf: (h) => h['name'] as String,
                              onChanged: (v) =>
                                  setState(() => _neighborhoodId = v),
                            ),
                          ),
                        ],
                      ),
                      _field(
                        'כתובת *',
                        _address,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'שדה חובה' : null,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              'חדרים',
                              _rooms,
                              hint: '4.5',
                              validator: _number(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              'חדרי רחצה',
                              _bathrooms,
                              hint: '2',
                              validator: _number(whole: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              'מ״ר',
                              _sqm,
                              hint: '110',
                              validator: _number(whole: true),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              'קומה',
                              _floor,
                              hint: '3',
                              validator: _number(whole: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              'סה״כ קומות',
                              _totalFloors,
                              hint: '6',
                              validator: _number(whole: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: _availableFromField()),
                        ],
                      ),
                      _field('תיאור', _description, maxLines: 4),
                      const SizedBox(height: 4),
                      AdminListingPhotosField(
                        photos: _photos,
                        onChanged: (p) => setState(() => _photos = p),
                        onUploaded: _uploaded.add,
                      ),
                      const SizedBox(height: 20),
                      _heading('מיקום במפה'),
                      const SizedBox(height: 4),
                      Text(
                        'המפה בעמוד הנכס מוצגת רק כששני השדות מלאים. '
                        'ב-Google Maps: קליק ימני על הנקודה, והמספרים הראשונים שמופיעים הם קו הרוחב וקו האורך.',
                        style: TextStyle(
                          fontFamily: AppFonts.rubik,
                          fontSize: 11,
                          color: AppColors.grayText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              'קו רוחב (latitude)',
                              _latitude,
                              hint: '31.8969',
                              ltr: true,
                              validator: _coordinate(90),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              'קו אורך (longitude)',
                              _longitude,
                              hint: '35.0104',
                              ltr: true,
                              validator: _coordinate(180),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _heading('פרטי קשר'),
                      const SizedBox(height: 4),
                      Text(
                        'כשנבחר סוכן, עמוד הנכס מציג את פרטי הסוכן; אחרת את השם והטלפון שכאן.',
                        style: TextStyle(
                          fontFamily: AppFonts.rubik,
                          fontSize: 11,
                          color: AppColors.grayText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _optionsDropdown(
                        label: 'סוכן',
                        none: 'ללא סוכן',
                        value: _agentId,
                        options: ref.watch(realEstateAgentsProvider),
                        labelOf: (a) => [
                          a['name'] as String? ?? '',
                          if ((a['agency'] as String?)?.isNotEmpty == true)
                            a['agency'] as String,
                        ].join(' — '),
                        onChanged: (v) => setState(() => _agentId = v),
                      ),
                      Row(
                        children: [
                          Expanded(child: _field('שם', _contactName)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field('טלפון', _contactPhone, ltr: true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _heading('מאפיינים'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _toggle(
                            'חניה',
                            _hasParking,
                            (v) => setState(() => _hasParking = v),
                          ),
                          _toggle(
                            'מעלית',
                            _hasElevator,
                            (v) => setState(() => _hasElevator = v),
                          ),
                          _toggle(
                            'מרפסת',
                            _hasBalcony,
                            (v) => setState(() => _hasBalcony = v),
                          ),
                          _toggle(
                            'מחסן',
                            _hasStorage,
                            (v) => setState(() => _hasStorage = v),
                          ),
                          _toggle(
                            'ממ״ד',
                            _hasMamad,
                            (v) => setState(() => _hasMamad = v),
                          ),
                          _toggle(
                            'מרוהט',
                            _isFurnished,
                            (v) => setState(() => _isFurnished = v),
                          ),
                          _toggle(
                            'נגיש',
                            _isAccessible,
                            (v) => setState(() => _isAccessible = v),
                          ),
                          _toggle(
                            'משופץ',
                            _isRenovated,
                            (v) => setState(() => _isRenovated = v),
                          ),
                          _toggle(
                            'מתווך',
                            _isBroker,
                            (v) => setState(() => _isBroker = v),
                          ),
                          _toggle(
                            'מומלץ',
                            _isFeatured,
                            (v) => setState(() => _isFeatured = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _heading('סטטוס'),
                      const SizedBox(height: 8),
                      // Every status the table knows, so a listing that is
                      // `removed` or a rental marked `sold` opens showing
                      // what it is rather than a blank box.
                      _dropdown<String>(
                        value: _status,
                        items: [
                          if (_baseline['status'] == 'draft')
                            ('draft', 'טיוטה'),
                          ('pending', 'ממתין לאישור'),
                          ('active', 'פעיל — מוצג באתר'),
                          ('sold', 'נמכר'),
                          ('rented', 'הושכר'),
                          ('expired', 'פג תוקף'),
                          ('removed', 'הוסר'),
                        ],
                        onChanged: (v) => setState(() => _status = v!),
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
                      const Spacer(),
                      TextButton(
                        onPressed: _saving ? null : _close,
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
                                _isEditing ? 'שמור' : 'צור נכס',
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

  Widget _heading(String text) => Text(
    text,
    style: TextStyle(
      fontFamily: AppFonts.rubik,
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: AppColors.navy,
    ),
  );

  InputDecoration _decoration(String? label) => InputDecoration(
    labelText: label,
    labelStyle: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  );

  Widget _dropdown<T>({
    String? label,
    required T value,
    required List<(T, String)> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        decoration: _decoration(label),
        items: [
          for (final (v, text) in items)
            DropdownMenuItem(
              value: v,
              child: Text(
                text,
                style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
              ),
            ),
        ],
        onChanged: onChanged,
      ),
    );
  }

  /// A pick from a table — neighbourhoods, agents — with "none" first.
  ///
  /// Inactive rows are offered only when the listing already points at one,
  /// and an id the list does not know is kept and shown as such. A dropdown
  /// whose value is not among its items draws an empty box, and a save would
  /// then look as though it had cleared the field.
  Widget _optionsDropdown({
    required String label,
    required String none,
    required String? value,
    required AsyncValue<List<Map<String, dynamic>>> options,
    required String Function(Map<String, dynamic>) labelOf,
    required ValueChanged<String?> onChanged,
  }) {
    if (options.isLoading) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: LinearProgressIndicator(),
      );
    }
    final rows = options.valueOrNull ?? const <Map<String, dynamic>>[];
    final known = {for (final r in rows) r['id'] as String};
    return _dropdown<String?>(
      label: options.hasError ? '$label (הרשימה לא נטענה)' : label,
      value: value,
      items: [
        (null, none),
        for (final r in rows)
          if (r['is_active'] != false || r['id'] == value)
            (
              r['id'] as String,
              r['is_active'] == false ? '${labelOf(r)} (לא פעיל)' : labelOf(r),
            ),
        if (value != null && !known.contains(value)) (value, 'לא מוכר'),
      ],
      onChanged: onChanged,
    );
  }

  Widget _availableFromField() {
    final d = _availableFrom;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: d ?? now,
            firstDate: DateTime(now.year - 2),
            lastDate: DateTime(now.year + 3),
          );
          if (picked != null) setState(() => _availableFrom = picked);
        },
        child: InputDecorator(
          decoration: _decoration('כניסה מ-').copyWith(
            suffixIcon: d == null
                ? const Icon(Icons.calendar_today_outlined, size: 16)
                : IconButton(
                    tooltip: 'ניקוי',
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => setState(() => _availableFrom = null),
                  ),
          ),
          child: Text(
            d == null ? 'מיידי / לא צוין' : '${d.day}/${d.month}/${d.year}',
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontSize: 13,
              color: d == null ? AppColors.grayLight : AppColors.navy,
            ),
          ),
        ),
      ),
    );
  }

  FormFieldValidator<String> _number({bool whole = false}) => (v) {
    if (v == null || v.trim().isEmpty) return null;
    final ok = whole
        ? int.tryParse(v.trim()) != null
        : num.tryParse(v.trim()) != null;
    return ok ? null : (whole ? 'מספר שלם' : 'מספר');
  };

  FormFieldValidator<String> _coordinate(double limit) => (v) {
    if (v == null || v.trim().isEmpty) {
      // One without the other draws no map, which would read as a bug.
      final other = limit == 90 ? _longitude.text : _latitude.text;
      return other.trim().isEmpty ? null : 'יש למלא את שני השדות';
    }
    final n = double.tryParse(v.trim());
    return n == null || n.abs() > limit ? 'מספר בין ‎-$limit ל-$limit' : null;
  };

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
        decoration: _decoration(label).copyWith(hintText: hint),
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

  /// Every column the form edits, as the form currently holds it.
  Map<String, dynamic> _collect() {
    final isRent = _kind == 'rent';
    final price = int.tryParse(_price.text.trim());
    String? text(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    final d = _availableFrom;
    return <String, dynamic>{
      'title': _title.text.trim(),
      'kind': _kind,
      'property_type': _propertyType,
      // One column or the other, and the unused one cleared, so a listing
      // switched from sale to rent does not keep the old figure.
      'price': isRent ? null : price,
      'price_per_month': isRent ? price : null,
      'address': _address.text.trim(),
      'neighborhood_id': _neighborhoodId,
      'agent_id': _agentId,
      'rooms': num.tryParse(_rooms.text.trim()),
      'bathrooms': int.tryParse(_bathrooms.text.trim()),
      'sqm': int.tryParse(_sqm.text.trim()),
      'floor': int.tryParse(_floor.text.trim()),
      'total_floors': int.tryParse(_totalFloors.text.trim()),
      'latitude': double.tryParse(_latitude.text.trim()),
      'longitude': double.tryParse(_longitude.text.trim()),
      // A date column: the day, with no time and so no zone to get wrong.
      'available_from': d == null
          ? null
          : '${d.year.toString().padLeft(4, '0')}-'
                '${d.month.toString().padLeft(2, '0')}-'
                '${d.day.toString().padLeft(2, '0')}',
      'description': text(_description),
      'contact_name': text(_contactName),
      'contact_phone': text(_contactPhone),
      'cover_url': _photos.isEmpty ? null : _photos.first,
      'gallery': _photos.length > 1 ? _photos.sublist(1) : const <String>[],
      'status': _status,
      'is_broker': _isBroker,
      'has_parking': _hasParking,
      'has_elevator': _hasElevator,
      'has_balcony': _hasBalcony,
      'has_storage': _hasStorage,
      'has_mamad': _hasMamad,
      'is_furnished': _isFurnished,
      'is_accessible': _isAccessible,
      'is_renovated': _isRenovated,
      'is_featured': _isFeatured,
    };
  }

  static bool _same(Object? a, Object? b) {
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (a[i] != b[i]) return false;
      }
      return true;
    }
    return a == b;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final fields = _collect();
    final changed = _isEditing
        ? {
            for (final e in fields.entries)
              if (!_same(_baseline[e.key], e.value)) e.key: e.value,
          }
        : fields;

    if (changed.isEmpty) {
      _close();
      return;
    }

    setState(() => _saving = true);
    try {
      final notifier = ref.read(adminListingListProvider.notifier);
      if (_isEditing) {
        await notifier.updateListing(widget.listing!['id'] as String, changed);
      } else {
        await notifier.createListing(changed);
      }
      // Saved: anything uploaded here that the listing does not use goes.
      AdminListingPhotosField.discard(
        _uploaded.where((u) => !_photos.contains(u)),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה: $e'),
            backgroundColor: AppColors.error,
          ),
        );
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
      'removed' => ('הוסר', AppColors.error),
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
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppFonts.rubik,
          fontSize: 10,
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
