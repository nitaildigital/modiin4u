import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/network_photo.dart';
import '../providers/admin_realestate_provider.dart';
import '../widgets/admin_listing_photos_field.dart';
import '../widgets/admin_load_error.dart';
import '../admin_language.dart';
import '../ui/admin_kit.dart';

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
        AdminListToolbar(
          search: AdminSearchField(
            controller: _searchController,
            width: isWide ? 280 : 180,
            hint: tr('חיפוש כתובת / שכונה...', 'Search address / neighbourhood...'),
            onChanged: (v) => _debouncer.run(() {
              ref
                  .read(adminListingListProvider.notifier)
                  .setSearch(v.isEmpty ? null : v);
            }),
          ),
          filters: [
            // Type filters
            AdminFilterChip(
              tr('הכל', 'All'),
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
            AdminFilterChip(tr('השכרה', 'Rent'), _typeFilter == 'rent', () {
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
            AdminFilterChip(tr('מכירה', 'Sale'), _typeFilter == 'sale', () {
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
                margin: const EdgeInsetsDirectional.only(end: 8),
                color: AdminKit.of(context).border,
              ),
              AdminFilterChip(tr('פעיל', 'Active'), _statusFilter == 'active', () {
                setState(() => _statusFilter = 'active');
                ref
                    .read(adminListingListProvider.notifier)
                    .setStatusFilter('active');
              }),
              AdminFilterChip(tr('ממתין', 'Pending'), _statusFilter == 'pending', () {
                setState(() => _statusFilter = 'pending');
                ref
                    .read(adminListingListProvider.notifier)
                    .setStatusFilter('pending');
              }),
            ],
          ],
          // `valueOrNull`, not `whenData(...).value`: the latter rethrows
          // on a failed load and greys the whole section instead of letting
          // the list below show the error and a retry.
          count: switch (listingsAsync.valueOrNull) {
            final list? => tr('${list.length} נכסים', '${list.length} properties'),
            null => null,
          },
          actions: [
            AdminToolbarButton(
              label: tr('נכס חדש', 'New property'),
              onPressed: () => _showListingEditor(context, ref),
            ),
          ],
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
                    tr('שגיאה בטעינת נכסים', 'Error loading properties'),
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
                    child: Text(tr('נסה שוב', 'Try again')),
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
                        tr('אין נכסים', 'No properties'),
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
        runAdminAction(context, () => notifier.approve(id));
      case 'reject':
        runAdminAction(context, () => notifier.reject(id));
      case 'activate':
        runAdminAction(context, () => notifier.updateStatus(id, 'active'));
      case 'sold':
        runAdminAction(
          context,
          () => notifier.updateStatus(
            id,
            listing['kind'] == 'rent' ? 'rented' : 'sold',
          ),
        );
      case 'expire':
        runAdminAction(context, () => notifier.updateStatus(id, 'expired'));
      case 'delete':
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(
              tr('מחיקת נכס', 'Delete property'),
              style: TextStyle(
                fontFamily: AppFonts.rubik,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              tr('להסיר את "${_listingTitle(listing)}"? המודעה תרד מהאפליקציה '
              'וניתן יהיה להחזירה על ידי שינוי הסטטוס.', 'Remove "${_listingTitle(listing)}"? The listing will leave the app, and it can be brought back by changing its status.'),
              style: TextStyle(fontFamily: AppFonts.rubik),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  tr('ביטול', 'Cancel'),
                  style: TextStyle(fontFamily: AppFonts.rubik),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  runAdminAction(context, () => notifier.deleteListing(id));
                },
                child: Text(
                  tr('מחק', 'Delete'),
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
    AdminEditorPage.open<void>(context, _ListingEditorDialog(listing: listing));
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
              _Col(tr('כתובת', 'Address'), flex: 3),
              _Col(tr('שכונה', 'Neighbourhood'), flex: 2),
              _Col(tr('סוג', 'Type'), flex: 1),
              _Col(tr('חדרים', 'Rooms'), flex: 1),
              if (isWide) _Col(tr('מ״ר', 'sqm'), flex: 1),
              _Col(tr('מחיר', 'Price'), flex: 2),
              _Col(tr('סטטוס', 'Status'), flex: 1),
              if (isWide) _Col(tr('צפיות', 'Views'), flex: 1),
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
                                    padding: const EdgeInsetsDirectional.only(end: 4),
                                    child: Icon(
                                      Icons.star,
                                      size: 14,
                                      color: AppColors.gold,
                                    ),
                                  ),
                                // The title, as residents see it; the row
                                // showed only the address, so two flats in
                                // one building looked the same.
                                Flexible(
                                  child: Text(
                                    _listingTitle(l),
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
                            // Where, and who posted it.
                            if (_listingSubline(l).isNotEmpty)
                              Text(
                                _listingSubline(l),
                                style: TextStyle(
                                  fontFamily: AppFonts.rubik,
                                  fontSize: 11,
                                  color: AppColors.grayText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (isBroker)
                              Text(
                                tr('מתווך', 'Agent'),
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
                      Expanded(
                        flex: 1,
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: _TypeBadge(kind),
                        ),
                      ),
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
                              tr('עריכה', 'Edit'),
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
                                tr('אישור ופרסום', 'Approve and publish'),
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
                                tr('דחייה', 'Reject'),
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
                                tr('הפעל', 'Activate'),
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
                                kind == 'rent' ? tr('סמן כהושכר', 'Mark as rented') : tr('סמן כנמכר', 'Mark as sold'),
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
                                tr('סמן כפג תוקף', 'Mark as expired'),
                                style: TextStyle(
                                  fontFamily: AppFonts.rubik,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          // "Remove" sets status = 'removed', the same as
                          // "דחייה" on a pending listing, so it is offered
                          // only where it does something of its own.
                          if (status != 'pending' && status != 'removed')
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                // The row is not removed; it becomes status = 'removed'.
                                tr('הסר', 'Remove'),
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
      return tr('₪${_numberFormat(price)}${type == 'rent' ? '/חודש' : ''}', '₪${_numberFormat(price)}${type == 'rent' ? '/month' : ''}');
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
  String? _error;

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
  /// "Send a notification when approved" (00060).
  bool _notify = true;
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
    _notify = l == null || (l['notify_on_publish'] as bool? ?? false);
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
    final k = AdminKit.of(context);
    return Form(
      key: _formKey,
      child: AdminEditorPage(
        title: _isEditing ? tr('עריכת נכס', 'Edit property') : tr('נכס חדש', 'New property'),
        status: _isEditing ? _StatusPill(_status) : null,
        onClose: () {
          if (!_saving) _close();
        },
        actions: [
          AdminButton.secondary(
            label: tr('ביטול', 'Cancel'),
            onPressed: _saving ? null : _close,
          ),
          AdminButton(
            label: _isEditing ? tr('שמור', 'Save') : tr('צור נכס', 'Create property'),
            icon: Icons.check,
            busy: _saving,
            onPressed: _saving ? null : _save,
          ),
        ],
        main: [
          if (_error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: k.danger.withValues(alpha: 0.06),
                border: Border.all(color: k.danger.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(k.radius),
              ),
              child: Text(_error!, style: k.body.copyWith(color: k.danger)),
            ),
          AdminCard(
            title: tr('פרטי הנכס', 'Property details'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // `title` is NOT NULL on the table and the form never
                // collected it, so even a corrected save would have failed.
                _field(
                  tr('כותרת *', 'Title *'),
                  _title,
                  validator: (v) =>
                      v == null || v.isEmpty ? tr('שדה חובה', 'Required field') : null,
                ),
                _field(
                  tr('כתובת *', 'Address *'),
                  _address,
                  validator: (v) =>
                      v == null || v.isEmpty ? tr('שדה חובה', 'Required field') : null,
                ),
                _field(
                  _kind == 'rent'
                      ? tr('מחיר לחודש (₪) *', 'Monthly price (₪) *')
                      : tr('מחיר (₪) *', 'Price (₪) *'),
                  _price,
                  hint: _kind == 'rent' ? '6000' : '2500000',
                  validator: (v) {
                    if (v == null || v.isEmpty) return tr('שדה חובה', 'Required field');
                    return int.tryParse(v) == null
                        ? tr('מספר שלם, בלי פסיקים', 'A whole number, without commas')
                        : null;
                  },
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _field(
                        tr('חדרים', 'Rooms'),
                        _rooms,
                        hint: '4.5',
                        validator: _number(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        tr('חדרי רחצה', 'Bathrooms'),
                        _bathrooms,
                        hint: '2',
                        validator: _number(whole: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        tr('מ״ר', 'sqm'),
                        _sqm,
                        hint: '110',
                        validator: _number(whole: true),
                      ),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _field(
                        tr('קומה', 'Floor'),
                        _floor,
                        hint: '3',
                        validator: _number(whole: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        tr('סה״כ קומות', 'Total floors'),
                        _totalFloors,
                        hint: '6',
                        validator: _number(whole: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _availableFromField()),
                  ],
                ),
              ],
            ),
          ),
          AdminCard(
            title: tr('תיאור', 'Description'),
            child: TextFormField(
              controller: _description,
              minLines: 4,
              maxLines: 12,
              style: k.body,
              decoration: k.input(),
            ),
          ),
          // The photos field has its own heading.
          AdminCard(
            child: AdminListingPhotosField(
              photos: _photos,
              onChanged: (p) => setState(() => _photos = p),
              onUploaded: _uploaded.add,
            ),
          ),
          AdminCard(
            title: tr('מיקום במפה', 'Location on the map'),
            subtitle: tr('המפה בעמוד הנכס מוצגת רק כששני השדות מלאים. '
            'ב-Google Maps: קליק ימני על הנקודה, והמספרים הראשונים שמופיעים הם קו הרוחב וקו האורך.', 'The map on the property page is shown only when both fields are filled. In Google Maps: right-click the spot, and the first numbers shown are the latitude and longitude.'),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _field(
                    tr('קו רוחב (latitude)', 'Latitude'),
                    _latitude,
                    hint: '31.8969',
                    ltr: true,
                    validator: _coordinate(90),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    tr('קו אורך (longitude)', 'Longitude'),
                    _longitude,
                    hint: '35.0104',
                    ltr: true,
                    validator: _coordinate(180),
                  ),
                ),
              ],
            ),
          ),
        ],
        side: [
          AdminCard(
            title: tr('פרסום', 'Publishing'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Every status the table knows, so a listing that is
                // `removed` or a rental marked `sold` opens showing
                // what it is rather than a blank box.
                _dropdown<String>(
                  label: tr('סטטוס', 'Status'),
                  value: _status,
                  items: [
                    if (_baseline['status'] == 'draft')
                      ('draft', tr('טיוטה', 'Draft')),
                    ('pending', tr('ממתין לאישור', 'Pending approval')),
                    ('active', tr('פעיל — מוצג באתר', 'Active — shown on the site')),
                    ('sold', tr('נמכר', 'Sold')),
                    ('rented', tr('הושכר', 'Rented')),
                    ('expired', tr('פג תוקף', 'Expired')),
                    ('removed', tr('הוסר', 'Removed')),
                  ],
                  onChanged: (v) => setState(() => _status = v!),
                ),
                AdminSwitchRow(
                  label: tr('מומלץ', 'Recommended'),
                  value: _isFeatured,
                  onChanged: (v) => setState(() => _isFeatured = v),
                ),
                AdminSwitchRow(
                  label: tr('לשלוח התראה באישור', 'Send a notification when approved'),
                  value: _notify,
                  onChanged: (v) => setState(() => _notify = v),
                ),
              ],
            ),
          ),
          AdminCard(
            title: tr('סוג ושכונה', 'Type and neighbourhood'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _dropdown<String>(
                  label: tr('סוג מודעה *', 'Listing type *'),
                  value: _kind,
                  items: [
                    ('rent', tr('השכרה', 'Rent')),
                    ('sale', tr('מכירה', 'Sale')),
                  ],
                  onChanged: (v) => setState(() => _kind = v!),
                ),
                _dropdown<String>(
                  label: tr('סוג נכס', 'Property type'),
                  value: _propertyType,
                  items: [
                    ('apartment', tr('דירה', 'Apartment')),
                    ('penthouse', tr('פנטהאוז', 'Penthouse')),
                    ('garden', tr('דירת גן', 'Garden apartment')),
                    ('duplex', tr('דופלקס', 'Duplex')),
                    ('villa', tr('וילה', 'Villa')),
                    ('studio', tr('סטודיו', 'Studio')),
                    ('other', tr('אחר', 'Other')),
                  ],
                  onChanged: (v) => setState(() => _propertyType = v!),
                ),
                // The neighbourhood is a row in `neighborhoods`, so it is
                // picked rather than typed — a typed name matched nothing.
                _optionsDropdown(
                  label: tr('שכונה', 'Neighbourhood'),
                  none: tr('ללא שכונה', 'No neighbourhood'),
                  value: _neighborhoodId,
                  options: ref.watch(adminNeighborhoodOptionsProvider),
                  labelOf: (h) => h['name'] as String,
                  onChanged: (v) => setState(() => _neighborhoodId = v),
                ),
              ],
            ),
          ),
          AdminCard(
            title: tr('פרטי קשר', 'Contact details'),
            subtitle: tr('כשנבחר סוכן, עמוד הנכס מציג את פרטי הסוכן; אחרת את השם והטלפון שכאן.', 'When an agent is chosen, the property page shows the agent\'s details; otherwise the name and phone here.'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _optionsDropdown(
                  label: tr('סוכן', 'Agent'),
                  none: tr('ללא סוכן', 'No agent'),
                  value: _agentId,
                  options: ref.watch(realEstateAgentsProvider),
                  labelOf: (a) => [
                    a['name'] as String? ?? '',
                    if ((a['agency'] as String?)?.isNotEmpty == true)
                      a['agency'] as String,
                  ].join(' — '),
                  onChanged: (v) => setState(() => _agentId = v),
                ),
                _field(tr('שם', 'Name'), _contactName),
                _field(tr('טלפון', 'Phone'), _contactPhone, ltr: true),
              ],
            ),
          ),
          AdminCard(
            title: tr('מאפיינים', 'Features'),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _toggle(
                  tr('חניה', 'Parking'),
                  _hasParking,
                  (v) => setState(() => _hasParking = v),
                ),
                _toggle(
                  tr('מעלית', 'Elevator'),
                  _hasElevator,
                  (v) => setState(() => _hasElevator = v),
                ),
                _toggle(
                  tr('מרפסת', 'Balcony'),
                  _hasBalcony,
                  (v) => setState(() => _hasBalcony = v),
                ),
                _toggle(
                  tr('מחסן', 'Storage room'),
                  _hasStorage,
                  (v) => setState(() => _hasStorage = v),
                ),
                _toggle(
                  tr('ממ״ד', 'Safe room'),
                  _hasMamad,
                  (v) => setState(() => _hasMamad = v),
                ),
                _toggle(
                  tr('מרוהט', 'Furnished'),
                  _isFurnished,
                  (v) => setState(() => _isFurnished = v),
                ),
                _toggle(
                  tr('נגיש', 'Accessible'),
                  _isAccessible,
                  (v) => setState(() => _isAccessible = v),
                ),
                _toggle(
                  tr('משופץ', 'Renovated'),
                  _isRenovated,
                  (v) => setState(() => _isRenovated = v),
                ),
                _toggle(
                  tr('מתווך', 'Agent'),
                  _isBroker,
                  (v) => setState(() => _isBroker = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown<T>({
    String? label,
    required T value,
    required List<(T, String)> items,
    required ValueChanged<T?> onChanged,
  }) {
    final k = AdminKit.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (label != null) ...[
            Text(label, style: k.label),
            const SizedBox(height: 6),
          ],
          DropdownButtonFormField<T>(
            initialValue: value,
            isExpanded: true,
            decoration: k.input(),
            items: [
              for (final (v, text) in items)
                DropdownMenuItem(
                  value: v,
                  child: Text(text, overflow: TextOverflow.ellipsis, style: k.body),
                ),
            ],
            onChanged: onChanged,
          ),
        ],
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
        padding: EdgeInsets.only(bottom: 16),
        child: LinearProgressIndicator(),
      );
    }
    final rows = options.valueOrNull ?? const <Map<String, dynamic>>[];
    final known = {for (final r in rows) r['id'] as String};
    return _dropdown<String?>(
      label: options.hasError ? tr('$label (הרשימה לא נטענה)', '$label (the list did not load)') : label,
      value: value,
      items: [
        (null, none),
        for (final r in rows)
          if (r['is_active'] != false || r['id'] == value)
            (
              r['id'] as String,
              r['is_active'] == false ? tr('${labelOf(r)} (לא פעיל)', '${labelOf(r)} (inactive)') : labelOf(r),
            ),
        if (value != null && !known.contains(value)) (value, tr('לא מוכר', 'Unknown')),
      ],
      onChanged: onChanged,
    );
  }

  Widget _availableFromField() {
    final k = AdminKit.of(context);
    final d = _availableFrom;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(tr('כניסה מ-', 'Move-in from'), style: k.label),
          const SizedBox(height: 6),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                locale: adminLocale,
                context: context,
                initialDate: d ?? now,
                firstDate: DateTime(now.year - 2),
                lastDate: DateTime(now.year + 3),
              );
              if (picked != null) setState(() => _availableFrom = picked);
            },
            child: InputDecorator(
              decoration: k.input(
                suffix: d == null
                    ? Icon(Icons.calendar_today_outlined, size: 16, color: k.inkSoft)
                    : IconButton(
                        tooltip: tr('ניקוי', 'Clear'),
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () => setState(() => _availableFrom = null),
                      ),
              ),
              child: Text(
                d == null ? tr('מיידי / לא צוין', 'Immediate / not specified') : '${d.day}/${d.month}/${d.year}',
                overflow: TextOverflow.ellipsis,
                style: d == null ? k.hint : k.body,
              ),
            ),
          ),
        ],
      ),
    );
  }

  FormFieldValidator<String> _number({bool whole = false}) => (v) {
    if (v == null || v.trim().isEmpty) return null;
    final ok = whole
        ? int.tryParse(v.trim()) != null
        : num.tryParse(v.trim()) != null;
    return ok ? null : (whole ? tr('מספר שלם', 'A whole number') : tr('מספר', 'Number'));
  };

  FormFieldValidator<String> _coordinate(double limit) => (v) {
    if (v == null || v.trim().isEmpty) {
      // One without the other draws no map, which would read as a bug.
      final other = limit == 90 ? _longitude.text : _latitude.text;
      return other.trim().isEmpty ? null : tr('יש למלא את שני השדות', 'Both fields must be filled');
    }
    final n = double.tryParse(v.trim());
    return n == null || n.abs() > limit ? tr('מספר בין ‎-$limit ל-$limit', 'A number between ‎-$limit and $limit') : null;
  };

  Widget _field(
    String label,
    TextEditingController controller, {
    String? hint,
    bool ltr = false,
    String? Function(String?)? validator,
  }) {
    return AdminField(
      label: label,
      controller: controller,
      hint: hint,
      validator: validator,
      textDirection: ltr ? TextDirection.ltr : null,
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
      selectedColor: AppColors.midBlue.withValues(alpha: 0.15),
      checkmarkColor: AppColors.midBlue,
      side: BorderSide(color: value ? AppColors.midBlue : AppColors.border),
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
      'notify_on_publish': _notify,
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

  /// Said at the top of the page and in a message at the bottom, since the
  /// page may be scrolled far from the top when Save is pressed.
  void _fail(String message) {
    setState(() => _error = message);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) {
      _fail(tr('יש שדות לתקן — הם מסומנים באדום.', 'Some fields need correcting — they are marked in red.'));
      return;
    }

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
      if (mounted) _fail(tr('שגיאה: $e', 'Error: $e'));
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
    final k = AdminKit.of(context);
    final (label, color) = switch (status) {
      'active' => (tr('פעיל', 'Active'), k.success),
      'pending' => (tr('ממתין', 'Pending'), k.warning),
      'sold' => (tr('נמכר', 'Sold'), k.accent),
      'rented' => (tr('הושכר', 'Rented'), k.accent),
      'expired' => (tr('פג תוקף', 'Expired'), k.danger),
      'removed' => (tr('הוסר', 'Removed'), k.danger),
      'draft' => (tr('טיוטה', 'Draft'), k.muted),
      _ => (status, k.muted),
    };
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: AdminPill(label, color),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge(this.type);

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (type) {
      'rent' => (tr('השכרה', 'Rent'), AppColors.midBlue),
      'sale' => (tr('מכירה', 'Sale'), AppColors.midBlue),
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

/// A listing's title, or its address when it has none.
String _listingTitle(Map<String, dynamic> l) {
  final title = (l['title'] as String?)?.trim() ?? '';
  return title.isNotEmpty ? title : (l['address'] as String?)?.trim() ?? '';
}

/// The address (when the title is not already it) and the poster's name.
String _listingSubline(Map<String, dynamic> l) {
  final title = (l['title'] as String?)?.trim() ?? '';
  final address = (l['address'] as String?)?.trim() ?? '';
  final owner = ((l['owner'] as Map?)?['full_name'] as String?)?.trim() ?? '';
  return [
    if (title.isNotEmpty && address.isNotEmpty) address,
    if (owner.isNotEmpty) owner,
  ].join(' · ');
}
