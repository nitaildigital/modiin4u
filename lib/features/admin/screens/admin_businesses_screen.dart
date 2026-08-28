import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/admin_businesses_provider.dart';

class AdminBusinessesScreen extends ConsumerStatefulWidget {
  const AdminBusinessesScreen({super.key});

  @override
  ConsumerState<AdminBusinessesScreen> createState() => _AdminBusinessesScreenState();
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

    return Column(children: [
      // ─── Toolbar ───
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
        ),
        child: Row(children: [
          // Search
          SizedBox(
            width: isWide ? 320 : 200,
            height: 40,
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.rubik(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'חיפוש עסק...',
                hintStyle: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayLight),
                prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.grayLight),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.turquoise)),
              ),
              onChanged: (v) => _debouncer.run(() {
                ref.read(adminBusinessListProvider.notifier).setSearch(v.isEmpty ? null : v);
              }),
            ),
          ),
          const SizedBox(width: 12),

          // Status filter
          _FilterChip('הכל', _statusFilter.isEmpty, () {
            setState(() => _statusFilter = '');
            ref.read(adminBusinessListProvider.notifier).setStatusFilter(null);
          }),
          _FilterChip('פעיל', _statusFilter == 'active', () {
            setState(() => _statusFilter = 'active');
            ref.read(adminBusinessListProvider.notifier).setStatusFilter('active');
          }),
          _FilterChip('ממתין', _statusFilter == 'pending', () {
            setState(() => _statusFilter = 'pending');
            ref.read(adminBusinessListProvider.notifier).setStatusFilter('pending');
          }),
          _FilterChip('מושהה', _statusFilter == 'suspended', () {
            setState(() => _statusFilter = 'suspended');
            ref.read(adminBusinessListProvider.notifier).setStatusFilter('suspended');
          }),

          const Spacer(),

          // Count
          businessesAsync.whenData((list) => Text(
            '${list.length} עסקים',
            style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText),
          )).value ?? const SizedBox.shrink(),
          const SizedBox(width: 16),

          // Add button
          FilledButton.icon(
            onPressed: () => _showBusinessEditor(context, ref),
            icon: const Icon(Icons.add, size: 18),
            label: Text('עסק חדש', style: GoogleFonts.rubik(fontSize: 13)),
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
        child: businessesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text('שגיאה בטעינת עסקים', style: GoogleFonts.rubik(color: AppColors.error)),
            const SizedBox(height: 4),
            Text('$e', style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayText)),
            const SizedBox(height: 12),
            TextButton(onPressed: () => ref.read(adminBusinessListProvider.notifier).load(), child: const Text('נסה שוב')),
          ])),
          data: (businesses) {
            if (businesses.isEmpty) {
              return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.store_outlined, size: 48, color: AppColors.grayLight.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text('אין עסקים', style: GoogleFonts.rubik(color: AppColors.grayText)),
              ]));
            }

            return _BusinessTable(
              businesses: businesses,
              isWide: isWide,
              onTap: (biz) => _showBusinessEditor(context, ref, business: biz),
              onAction: (action, biz) => _handleAction(action, biz),
            );
          },
        ),
      ),
    ]);
  }

  void _handleAction(String action, Map<String, dynamic> biz) {
    final notifier = ref.read(adminBusinessListProvider.notifier);
    final id = biz['id'] as String;
    switch (action) {
      case 'edit':
        _showBusinessEditor(context, ref, business: biz);
      case 'activate':
        notifier.updateStatus(id, 'active');
      case 'suspend':
        notifier.updateStatus(id, 'suspended');
      case 'delete':
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('מחיקת עסק', style: GoogleFonts.rubik(fontWeight: FontWeight.w700)),
            content: Text('למחוק את "${biz['name']}"?', style: GoogleFonts.rubik()),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text('ביטול', style: GoogleFonts.rubik())),
              TextButton(
                onPressed: () { Navigator.pop(ctx); notifier.deleteBusiness(id); },
                child: Text('מחק', style: GoogleFonts.rubik(color: AppColors.error)),
              ),
            ],
          ),
        );
    }
  }

  void _showBusinessEditor(BuildContext context, WidgetRef ref, {Map<String, dynamic>? business}) {
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
  final bool isWide;
  final void Function(Map<String, dynamic>) onTap;
  final void Function(String action, Map<String, dynamic>) onAction;

  const _BusinessTable({required this.businesses, required this.isWide, required this.onTap, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Header
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(color: AppColors.surfaceLight, border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5)))),
        child: Row(children: [
          _Col('עסק', flex: 3),
          if (isWide) _Col('קטגוריה', flex: 2),
          _Col('שכונה', flex: 2),
          _Col('סטטוס', flex: 1),
          if (isWide) _Col('דירוג', flex: 1),
          if (isWide) _Col('ביקורות', flex: 1),
          const SizedBox(width: 40),
        ]),
      ),

      // Rows
      Expanded(
        child: ListView.separated(
          itemCount: businesses.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.border.withValues(alpha: 0.3)),
          itemBuilder: (_, i) {
            final biz = businesses[i];
            final status = biz['status'] as String? ?? 'draft';
            final neighborhood = biz['neighborhoods'] as Map<String, dynamic>?;
            final rating = (biz['rating'] as num?)?.toDouble() ?? 0;
            final reviewCount = biz['review_count'] as int? ?? 0;

            return InkWell(
              onTap: () => onTap(biz),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(children: [
                  // Logo + Name
                  if (biz['logo_url'] != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(biz['logo_url'] as String, width: 38, height: 38, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(width: 38, height: 38, decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.store, size: 18, color: AppColors.grayLight))),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(biz['name'] as String? ?? '', style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy)),
                    Text(biz['slug'] as String? ?? '', style: GoogleFonts.rubik(fontSize: 11, color: AppColors.grayLight)),
                  ])),
                  // Category placeholder (from entity_categories in the future)
                  if (isWide) Expanded(flex: 2, child: Text(biz['short_description'] as String? ?? '', style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayText), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  // Neighborhood
                  Expanded(flex: 2, child: Text(neighborhood?['name'] as String? ?? '—', style: GoogleFonts.rubik(fontSize: 13))),
                  // Status
                  Expanded(flex: 1, child: _StatusPill(status)),
                  // Rating
                  if (isWide) Expanded(flex: 1, child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (rating > 0) ...[
                      Icon(Icons.star, size: 14, color: rating >= 4 ? AppColors.gold : AppColors.grayLight),
                      const SizedBox(width: 2),
                      Text(rating.toStringAsFixed(1), style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w600)),
                    ] else
                      Text('—', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayLight)),
                  ])),
                  // Reviews
                  if (isWide) Expanded(flex: 1, child: Text('$reviewCount', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText))),
                  // Actions
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18, color: AppColors.grayLight),
                    onSelected: (v) => onAction(v, biz),
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'edit', child: Text('עריכה', style: GoogleFonts.rubik(fontSize: 13))),
                      if (status != 'active') PopupMenuItem(value: 'activate', child: Text('אשר', style: GoogleFonts.rubik(fontSize: 13))),
                      if (status != 'suspended') PopupMenuItem(value: 'suspend', child: Text('השהה', style: GoogleFonts.rubik(fontSize: 13))),
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
      child: Text(label, style: GoogleFonts.rubik(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
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

// ─── Business Editor Dialog ───

class _BusinessEditorDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? business;
  const _BusinessEditorDialog({this.business});

  @override
  ConsumerState<_BusinessEditorDialog> createState() => _BusinessEditorDialogState();
}

class _BusinessEditorDialogState extends ConsumerState<_BusinessEditorDialog> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  // Images
  late final TextEditingController _logoUrl;
  late final TextEditingController _coverImageUrl;
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

  String _status = 'draft';
  String? _neighborhoodId;
  String _kosher = 'none';
  String? _priceLevel;
  bool _hasDelivery = false;
  bool _isAccessible = false;
  bool _hasTakeaway = false;
  bool _hasParking = false;
  bool _petFriendly = false;
  bool _kidFriendly = false;
  bool _hasWifi = false;
  bool _openOnShabbat = false;
  bool _isFeatured = false;
  bool _isVerified = false;
  bool _noindex = false;

  bool get _isEditing => widget.business != null;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    final b = widget.business;

    _logoUrl = TextEditingController(text: b?['logo_url'] as String? ?? '');
    _coverImageUrl = TextEditingController(text: b?['cover_image_url'] as String? ?? '');
    _name = TextEditingController(text: b?['name'] as String? ?? '');
    _slug = TextEditingController(text: b?['slug'] as String? ?? '');
    _shortDesc = TextEditingController(text: b?['short_description'] as String? ?? '');
    _fullDesc = TextEditingController(text: b?['full_description'] as String? ?? '');
    _phone = TextEditingController(text: b?['phone'] as String? ?? '');
    _email = TextEditingController(text: b?['email'] as String? ?? '');
    _website = TextEditingController(text: b?['website'] as String? ?? '');
    _whatsapp = TextEditingController(text: b?['whatsapp'] as String? ?? '');
    _instagram = TextEditingController(text: b?['instagram'] as String? ?? '');
    _address = TextEditingController(text: b?['address'] as String? ?? '');
    _lat = TextEditingController(text: (b?['latitude'] as num?)?.toString() ?? '');
    _lng = TextEditingController(text: (b?['longitude'] as num?)?.toString() ?? '');
    _metaTitle = TextEditingController(text: b?['meta_title'] as String? ?? '');
    _metaDesc = TextEditingController(text: b?['meta_description'] as String? ?? '');
    _metaKeywords = TextEditingController(text: b?['meta_keywords'] as String? ?? '');
    _ogTitle = TextEditingController(text: b?['og_title'] as String? ?? '');
    _ogDesc = TextEditingController(text: b?['og_description'] as String? ?? '');

    _status = b?['status'] as String? ?? 'draft';
    _neighborhoodId = b?['neighborhood_id'] as String?;
    _kosher = b?['kosher_level'] as String? ?? 'none';
    _priceLevel = b?['price_level'] as String?;
    _hasDelivery = b?['has_delivery'] as bool? ?? false;
    _isAccessible = b?['is_accessible'] as bool? ?? false;
    _hasTakeaway = b?['has_takeaway'] as bool? ?? false;
    _hasParking = b?['has_parking'] as bool? ?? false;
    _petFriendly = b?['pet_friendly'] as bool? ?? false;
    _kidFriendly = b?['kid_friendly'] as bool? ?? false;
    _hasWifi = b?['has_wifi'] as bool? ?? false;
    _openOnShabbat = b?['open_on_shabbat'] as bool? ?? false;
    _isFeatured = b?['is_featured'] as bool? ?? false;
    _isVerified = b?['is_verified'] as bool? ?? false;
    _noindex = b?['noindex'] as bool? ?? false;
  }

  @override
  void dispose() {
    _tabs.dispose();
    _logoUrl.dispose(); _coverImageUrl.dispose();
    _name.dispose(); _slug.dispose(); _shortDesc.dispose(); _fullDesc.dispose();
    _phone.dispose(); _email.dispose(); _website.dispose(); _whatsapp.dispose(); _instagram.dispose();
    _address.dispose(); _lat.dispose(); _lng.dispose();
    _metaTitle.dispose(); _metaDesc.dispose(); _metaKeywords.dispose(); _ogTitle.dispose(); _ogDesc.dispose();
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
            child: Column(children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: Row(children: [
                  Text(_isEditing ? 'עריכת עסק' : 'עסק חדש', style: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
                ]),
              ),

              // Tabs
              Container(
                color: AppColors.surfaceLight,
                child: TabBar(
                  controller: _tabs,
                  labelStyle: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: GoogleFonts.rubik(fontSize: 13),
                  labelColor: AppColors.turquoise,
                  unselectedLabelColor: AppColors.grayText,
                  indicatorColor: AppColors.turquoise,
                  tabs: const [
                    Tab(text: 'פרטים'),
                    Tab(text: 'מאפיינים'),
                    Tab(text: 'SEO'),
                  ],
                ),
              ),

              // Tab content
              Expanded(
                child: TabBarView(controller: _tabs, children: [
                  _buildDetailsTab(neighborhoods),
                  _buildAttributesTab(),
                  _buildSeoTab(),
                ]),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
                child: Row(children: [
                  if (_isEditing) ...[
                    _StatusPill(_status),
                    const SizedBox(width: 8),
                  ],
                  const Spacer(),
                  TextButton(onPressed: () => Navigator.pop(context), child: Text('ביטול', style: GoogleFonts.rubik())),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(backgroundColor: AppColors.turquoise, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_isEditing ? 'שמור' : 'צור עסק', style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsTab(AsyncValue<List<Map<String, dynamic>>> neighborhoods) {
    return ListView(padding: const EdgeInsets.all(20), children: [
      _field('שם עסק *', _name, validator: (v) => v == null || v.isEmpty ? 'שדה חובה' : null),
      _field('Slug *', _slug, validator: (v) => v == null || v.isEmpty ? 'שדה חובה' : null),
      _field('תיאור קצר', _shortDesc, maxLines: 2),
      _field('תיאור מלא', _fullDesc, maxLines: 4),
      const SizedBox(height: 16),
      Text('תמונות', style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy)),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: _field('לוגו URL', _logoUrl)),
        const SizedBox(width: 12),
        Expanded(child: _field('תמונת כריכה URL', _coverImageUrl)),
      ]),
      if (_logoUrl.text.isNotEmpty || _coverImageUrl.text.isNotEmpty)
        Row(children: [
          if (_logoUrl.text.isNotEmpty) ...[
            ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(_logoUrl.text, width: 64, height: 64, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(width: 64, height: 64, decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.broken_image, size: 20, color: AppColors.grayLight)))),
            const SizedBox(width: 12),
          ],
          if (_coverImageUrl.text.isNotEmpty)
            Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(_coverImageUrl.text, height: 64, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(height: 64, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.broken_image, size: 20, color: AppColors.grayLight))))),
        ]),
      const SizedBox(height: 16),
      Text('קשר', style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy)),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: _field('טלפון', _phone)),
        const SizedBox(width: 12),
        Expanded(child: _field('WhatsApp', _whatsapp)),
      ]),
      Row(children: [
        Expanded(child: _field('אימייל', _email)),
        const SizedBox(width: 12),
        Expanded(child: _field('אתר', _website)),
      ]),
      _field('Instagram', _instagram),
      const SizedBox(height: 16),
      Text('מיקום', style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy)),
      const SizedBox(height: 8),
      _field('כתובת *', _address, validator: (v) => v == null || v.isEmpty ? 'שדה חובה' : null),
      neighborhoods.when(
        loading: () => const LinearProgressIndicator(),
        error: (_, __) => const SizedBox.shrink(),
        data: (hoods) => DropdownButtonFormField<String>(
          value: _neighborhoodId,
          decoration: InputDecoration(labelText: 'שכונה', labelStyle: GoogleFonts.rubik(fontSize: 13), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
          items: hoods.map((h) => DropdownMenuItem(value: h['id'] as String, child: Text(h['name'] as String, style: GoogleFonts.rubik(fontSize: 13)))).toList(),
          onChanged: (v) => setState(() => _neighborhoodId = v),
        ),
      ),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: _field('Latitude', _lat)),
        const SizedBox(width: 12),
        Expanded(child: _field('Longitude', _lng)),
      ]),
      const SizedBox(height: 16),
      Text('סטטוס', style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: _status,
        decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
        items: [
          DropdownMenuItem(value: 'draft', child: Text('טיוטה', style: GoogleFonts.rubik(fontSize: 13))),
          DropdownMenuItem(value: 'pending', child: Text('ממתין לאישור', style: GoogleFonts.rubik(fontSize: 13))),
          DropdownMenuItem(value: 'active', child: Text('פעיל', style: GoogleFonts.rubik(fontSize: 13))),
          DropdownMenuItem(value: 'suspended', child: Text('מושהה', style: GoogleFonts.rubik(fontSize: 13))),
          DropdownMenuItem(value: 'closed', child: Text('סגור', style: GoogleFonts.rubik(fontSize: 13))),
        ],
        onChanged: (v) => setState(() => _status = v!),
      ),
    ]);
  }

  Widget _buildAttributesTab() {
    return ListView(padding: const EdgeInsets.all(20), children: [
      Text('כשרות', style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: _kosher,
        decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
        items: [
          DropdownMenuItem(value: 'none', child: Text('ללא', style: GoogleFonts.rubik(fontSize: 13))),
          DropdownMenuItem(value: 'rabbanut', child: Text('רבנות', style: GoogleFonts.rubik(fontSize: 13))),
          DropdownMenuItem(value: 'mehadrin', child: Text('מהדרין', style: GoogleFonts.rubik(fontSize: 13))),
          DropdownMenuItem(value: 'badatz', child: Text('בד"ץ', style: GoogleFonts.rubik(fontSize: 13))),
        ],
        onChanged: (v) => setState(() => _kosher = v!),
      ),
      const SizedBox(height: 12),
      Text('רמת מחיר', style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String?>(
        value: _priceLevel,
        decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
        items: [
          DropdownMenuItem(value: null, child: Text('—', style: GoogleFonts.rubik(fontSize: 13))),
          DropdownMenuItem(value: '₪', child: Text('₪', style: GoogleFonts.rubik(fontSize: 13))),
          DropdownMenuItem(value: '₪₪', child: Text('₪₪', style: GoogleFonts.rubik(fontSize: 13))),
          DropdownMenuItem(value: '₪₪₪', child: Text('₪₪₪', style: GoogleFonts.rubik(fontSize: 13))),
          DropdownMenuItem(value: '₪₪₪₪', child: Text('₪₪₪₪', style: GoogleFonts.rubik(fontSize: 13))),
        ],
        onChanged: (v) => setState(() => _priceLevel = v),
      ),
      const SizedBox(height: 16),
      Text('מאפיינים', style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 4, children: [
        _toggle('משלוחים', _hasDelivery, (v) => setState(() => _hasDelivery = v)),
        _toggle('Takeaway', _hasTakeaway, (v) => setState(() => _hasTakeaway = v)),
        _toggle('נגיש', _isAccessible, (v) => setState(() => _isAccessible = v)),
        _toggle('חניה', _hasParking, (v) => setState(() => _hasParking = v)),
        _toggle('ידידותי לחיות', _petFriendly, (v) => setState(() => _petFriendly = v)),
        _toggle('ידידותי לילדים', _kidFriendly, (v) => setState(() => _kidFriendly = v)),
        _toggle('Wi-Fi', _hasWifi, (v) => setState(() => _hasWifi = v)),
        _toggle('פתוח בשבת', _openOnShabbat, (v) => setState(() => _openOnShabbat = v)),
      ]),
      const SizedBox(height: 16),
      Text('קידום', style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy)),
      const SizedBox(height: 8),
      _toggle('מומלץ / Featured', _isFeatured, (v) => setState(() => _isFeatured = v)),
      _toggle('מאומת / Verified', _isVerified, (v) => setState(() => _isVerified = v)),
    ]);
  }

  Widget _buildSeoTab() {
    return ListView(padding: const EdgeInsets.all(20), children: [
      _field('SEO Title', _metaTitle),
      _field('Meta Description', _metaDesc, maxLines: 3),
      _field('Meta Keywords', _metaKeywords),
      const SizedBox(height: 16),
      Text('Open Graph', style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy)),
      const SizedBox(height: 8),
      _field('OG Title', _ogTitle),
      _field('OG Description', _ogDesc, maxLines: 3),
      const SizedBox(height: 12),
      _toggle('Noindex', _noindex, (v) => setState(() => _noindex = v)),
    ]);
  }

  Widget _field(String label, TextEditingController controller, {int maxLines = 1, String? Function(String?)? validator}) {
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
    return FilterChip(
      label: Text(label, style: GoogleFonts.rubik(fontSize: 12)),
      selected: value,
      onSelected: onChanged,
      selectedColor: AppColors.turquoise.withValues(alpha: 0.15),
      checkmarkColor: AppColors.turquoise,
      side: BorderSide(color: value ? AppColors.turquoise : AppColors.border),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final fields = <String, dynamic>{
      'logo_url': _logoUrl.text.isEmpty ? null : _logoUrl.text,
      'cover_image_url': _coverImageUrl.text.isEmpty ? null : _coverImageUrl.text,
      'name': _name.text,
      'slug': _slug.text,
      'short_description': _shortDesc.text.isEmpty ? null : _shortDesc.text,
      'full_description': _fullDesc.text.isEmpty ? null : _fullDesc.text,
      'phone': _phone.text.isEmpty ? null : _phone.text,
      'email': _email.text.isEmpty ? null : _email.text,
      'website': _website.text.isEmpty ? null : _website.text,
      'whatsapp': _whatsapp.text.isEmpty ? null : _whatsapp.text,
      'instagram': _instagram.text.isEmpty ? null : _instagram.text,
      'address': _address.text,
      'neighborhood_id': _neighborhoodId,
      'latitude': double.tryParse(_lat.text),
      'longitude': double.tryParse(_lng.text),
      'status': _status,
      'kosher_level': _kosher,
      'price_level': _priceLevel,
      'has_delivery': _hasDelivery,
      'has_takeaway': _hasTakeaway,
      'is_accessible': _isAccessible,
      'has_parking': _hasParking,
      'pet_friendly': _petFriendly,
      'kid_friendly': _kidFriendly,
      'has_wifi': _hasWifi,
      'open_on_shabbat': _openOnShabbat,
      'is_featured': _isFeatured,
      'is_verified': _isVerified,
      'noindex': _noindex,
      'meta_title': _metaTitle.text.isEmpty ? null : _metaTitle.text,
      'meta_description': _metaDesc.text.isEmpty ? null : _metaDesc.text,
      'meta_keywords': _metaKeywords.text.isEmpty ? null : _metaKeywords.text,
      'og_title': _ogTitle.text.isEmpty ? null : _ogTitle.text,
      'og_description': _ogDesc.text.isEmpty ? null : _ogDesc.text,
    };

    try {
      final notifier = ref.read(adminBusinessListProvider.notifier);
      if (_isEditing) {
        await notifier.updateBusiness(widget.business!['id'] as String, fields);
      } else {
        await notifier.createBusiness(fields);
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

// ─── Debouncer ───

class _Debouncer {
  final int milliseconds;
  _Debouncer({required this.milliseconds});

  Future<void>? _pending;

  void run(VoidCallback action) {
    _pending?.ignore();
    _pending = Future.delayed(Duration(milliseconds: milliseconds)).then((_) => action());
  }
}
