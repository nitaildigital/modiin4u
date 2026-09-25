import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;

import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../models/listing.dart';
import '../providers/listing_providers.dart';

// ═══════════════════════════════════════════════════════════
// Web Add Apartment — desktop layout for /add-apartment
//
// The same three steps in the same order, and the same write: the form fills
// `listings` as `pending` through the listing repository, and each photograph
// is uploaded to `listings/<auth.uid()>/` in the `media` bucket as it is
// picked. Nothing about that changes here.
//
// What the width buys is the arrangement. The fields that the mobile form
// stacks one per screenful sit two and three to a row in a 700px column, and
// the step indicator moves out of the way into a rail on the side, where it
// can carry what each step is for and let you walk back to one you have
// already done.
// ═══════════════════════════════════════════════════════════

const _kBorder = Color(0xFFE7E7E7);
const _kLabel = Color(0xFF1F1F1F);
const _kGreyText = Color(0xFF5F5E5A);
const _kIconGrey = Color(0xFF6D6D6D);
const _kSelectedBg = Color(0xFFEEF4FD);
const _kPendingBg = Color(0xFFFFF9EF);
const _kPendingBorder = Color(0xFFFFE8C3);
const _kPendingAccent = Color(0xFFEA9D23);

/// The amenities that have somewhere to be stored. Each one is a boolean
/// column on `listings`, so a chip that is on becomes a value that is kept.
enum _Amenity {
  balcony(IconsaxPlusLinear.building_4),
  parking(IconsaxPlusLinear.car),
  elevator(IconsaxPlusLinear.arrow_3),
  storage(IconsaxPlusLinear.box_1),
  mamad(IconsaxPlusLinear.shield_tick);

  const _Amenity(this.icon);
  final IconData icon;
}

class WebAddApartmentContent extends ConsumerStatefulWidget {
  const WebAddApartmentContent({super.key});

  @override
  ConsumerState<WebAddApartmentContent> createState() =>
      _WebAddApartmentContentState();
}

class _WebAddApartmentContentState
    extends ConsumerState<WebAddApartmentContent> {
  bool _isHebrew = false;

  /// 0 = Basics, 1 = Details, 2 = Photos, 3 = Submitted.
  int _currentStep = 0;

  // ── Step 1 ──
  ListingKind _kind = ListingKind.sale;
  PropertyType? _propertyType;
  final _title = TextEditingController();
  final _price = TextEditingController();
  final _address = TextEditingController();
  String? _neighborhoodId;
  double? _rooms;
  int? _bathrooms;

  // ── Step 2 ──
  final _description = TextEditingController();
  final _area = TextEditingController();
  int? _floor;
  int? _totalFloors;
  final Set<_Amenity> _amenities = {};

  // ── Step 3 ──
  //
  // Uploaded as they are picked rather than on submit, so the person sees them
  // appear and a slow connection does not stall the final button. The list
  // holds public URLs; the first is the cover.
  static const _maxPhotos = 9;
  final List<String> _photos = [];
  bool _uploading = false;

  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _price.dispose();
    _address.dispose();
    _description.dispose();
    _area.dispose();
    super.dispose();
  }

  String _t(String en, String he) => _isHebrew ? he : en;

  // ═══════════════════════════════════════════════
  // PHOTOGRAPHS
  // ═══════════════════════════════════════════════

  Future<void> _pickPhotos() async {
    final room = _maxPhotos - _photos.length;
    if (room <= 0) {
      _toast(
        _t('Up to $_maxPhotos photos', 'ניתן להעלות עד $_maxPhotos תמונות'),
      );
      return;
    }

    final List<XFile> picked;
    try {
      picked = await ImagePicker().pickMultiImage(
        maxWidth: 2000,
        imageQuality: 85,
      );
    } catch (_) {
      if (mounted) _toast(_uploadFailed, error: true);
      return;
    }
    if (picked.isEmpty || !mounted) return;

    setState(() => _uploading = true);

    final uid = SupabaseConfig.client.auth.currentUser?.id;
    if (uid == null) {
      setState(() => _uploading = false);
      _toast(_signInToPost, error: true);
      return;
    }

    for (final file in picked.take(room)) {
      try {
        final bytes = await file.readAsBytes();
        // The bucket refuses anything over 10MB and reports it as a plain
        // failure, so the size is checked here to say why.
        if (bytes.lengthInBytes > 10 * 1024 * 1024) {
          if (mounted) {
            _toast(
              _t('That file is larger than 10MB', 'הקובץ גדול מ-10MB'),
              error: true,
            );
          }
          continue;
        }

        // The storage policy only admits `listings/<your id>/…`, so the path
        // is built to match rather than hoped for.
        final ext = _extensionOf(file.name);
        final path =
            'listings/$uid/${DateTime.now().microsecondsSinceEpoch}$ext';

        await SupabaseConfig.client.storage
            .from('media')
            .uploadBinary(
              path,
              bytes,
              fileOptions: FileOptions(
                contentType: _mimeOf(ext),
                upsert: false,
              ),
            );

        final url = SupabaseConfig.client.storage
            .from('media')
            .getPublicUrl(path);
        if (!mounted) return;
        setState(() => _photos.add(url));
      } catch (_) {
        if (mounted) _toast(_uploadFailed, error: true);
      }
    }

    if (mounted) setState(() => _uploading = false);
  }

  String get _uploadFailed =>
      _t('The upload failed. Please try again.', 'ההעלאה נכשלה. נסו שוב.');

  String get _signInToPost =>
      _t('Sign in to post a listing', 'התחברו כדי לפרסם מודעה');

  /// Drops it from the listing. The file is left in the bucket: a half-filled
  /// form is often come back to, and an orphan costs less than a photograph
  /// deleted while it is still being used.
  void _removePhoto(int index) => setState(() => _photos.removeAt(index));

  static String _extensionOf(String name) {
    final dot = name.lastIndexOf('.');
    if (dot == -1) return '.jpg';
    final ext = name.substring(dot).toLowerCase();
    return const {'.jpg', '.jpeg', '.png', '.webp'}.contains(ext)
        ? ext
        : '.jpg';
  }

  static String _mimeOf(String ext) => switch (ext) {
    '.png' => 'image/png',
    '.webp' => 'image/webp',
    _ => 'image/jpeg',
  };

  // ═══════════════════════════════════════════════
  // THE WRITE
  // ═══════════════════════════════════════════════

  void _onNext() {
    if (_currentStep < 2) setState(() => _currentStep++);
  }

  void _onBack() {
    if (_currentStep > 0 && _currentStep < 3) setState(() => _currentStep--);
  }

  Future<void> _onSubmit() async {
    if (_saving) return;

    // Checked here rather than on the way out of step 1, so someone can fill
    // the form in whatever order they like and still be told what is missing.
    if (_title.text.trim().isEmpty) {
      setState(() => _currentStep = 0);
      _toast(_t('A title is required', 'יש להזין כותרת'), error: true);
      return;
    }
    final price = int.tryParse(_price.text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (price == null || price <= 0) {
      setState(() => _currentStep = 0);
      _toast(_t('A price is required', 'יש להזין מחיר'), error: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final isRent = _kind == ListingKind.rent;
      await ref
          .read(listingRepositoryProvider)
          .create(
            title: _title.text.trim(),
            description: _description.text.trim().isEmpty
                ? null
                : _description.text.trim(),
            kind: _kind,
            propertyType: _propertyType ?? PropertyType.apartment,
            rooms: _rooms,
            bathrooms: _bathrooms,
            floor: _floor,
            totalFloors: _totalFloors,
            sqm: int.tryParse(_area.text.trim()),
            // One column or the other, never both, so a rental does not read
            // as a sale at the same number.
            price: isRent ? null : price,
            pricePerMonth: isRent ? price : null,
            address: _address.text.trim().isEmpty ? null : _address.text.trim(),
            neighborhoodId: _neighborhoodId,
            hasParking: _amenities.contains(_Amenity.parking),
            hasElevator: _amenities.contains(_Amenity.elevator),
            hasStorage: _amenities.contains(_Amenity.storage),
            hasBalcony: _amenities.contains(_Amenity.balcony),
            hasMamad: _amenities.contains(_Amenity.mamad),
            coverUrl: _photos.isEmpty ? null : _photos.first,
            gallery: _photos.length > 1 ? _photos.sublist(1) : const [],
          );

      // So "My Apartments" shows it without the person having to reload.
      ref.invalidate(myListingsProvider);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _currentStep = 3;
      });
    } on StateError {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast(_signInToPost, error: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast(
        _t(
          'Could not submit. Please try again.',
          'לא ניתן היה לשלוח. נסו שוב.',
        ),
        error: true,
      );
    }
  }

  void _toast(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontFamily: AppFonts.inter)),
        backgroundColor: error ? AppColors.error : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // LAYOUT
  // ═══════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isHebrew ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            WebNavbar(
              isHebrew: _isHebrew,
              activeId: 'realestate',
              onToggleLanguage: () => setState(() => _isHebrew = !_isHebrew),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    _FormPage(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBackLink(),
                          const SizedBox(height: 20),
                          Text(
                            _t('Add Apartment', 'הוספת דירה'),
                            style: TextStyle(
                              fontFamily: AppFonts.nunito,
                              fontSize: 40,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _t(
                              'Fill in the details about your property',
                              'מלאו את פרטי הנכס',
                            ),
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 16,
                              color: _kIconGrey,
                            ),
                          ),
                          const SizedBox(height: 36),
                          _currentStep == 3
                              ? _buildConfirmation()
                              : _buildForm(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                    WebFooter(isHebrew: _isHebrew),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackLink() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () =>
            context.canPop() ? context.pop() : context.go('/my-apartments'),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isHebrew
                  ? IconsaxPlusLinear.arrow_right_3
                  : IconsaxPlusLinear.arrow_left,
              size: 20,
              color: AppColors.midBlue,
            ),
            const SizedBox(width: 8),
            Text(
              _t('My Apartments', 'הדירות שלי'),
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.midBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The form on the one side, the step rail on the other.
  Widget _buildForm() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildStepColumn()),
        const SizedBox(width: 40),
        SizedBox(width: 340, child: _buildRail()),
      ],
    );
  }

  Widget _buildStepColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          switch (_currentStep) {
            0 => _t('Basic Information', 'פרטים בסיסיים'),
            1 => _t('Apartment Details', 'פרטי הדירה'),
            _ => _t('Add Photos', 'הוספת תמונות'),
          },
          style: TextStyle(
            fontFamily: AppFonts.nunito,
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: AppColors.midBlue,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          switch (_currentStep) {
            0 => _t(
              'Fill in the details about your property',
              'מלאו את פרטי הנכס',
            ),
            1 => _t(
              'Add more details about your property',
              'הוסיפו פרטים נוספים על הנכס',
            ),
            _ => _t('Upload photos of your apartment', 'העלו תמונות של הדירה'),
          },
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 14,
            color: _kGreyText,
          ),
        ),
        const SizedBox(height: 24),
        switch (_currentStep) {
          0 => _buildStep1(),
          1 => _buildStep2(),
          _ => _buildStep3(),
        },
        const SizedBox(height: 32),
        _buildButtonRow(),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // STEP 1 — the basics
  // ─────────────────────────────────────────────
  Widget _buildStep1() {
    final hoods = ref.watch(listingNeighborhoodsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldCard(
          label: _t('Listing Type', 'סוג המודעה'),
          child: Row(
            children: [
              Expanded(
                child: _ToggleButton(
                  label: _t('For sale', 'למכירה'),
                  icon: IconsaxPlusLinear.tag,
                  selected: _kind == ListingKind.sale,
                  onTap: () => setState(() => _kind = ListingKind.sale),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ToggleButton(
                  label: _t('For rent', 'להשכרה'),
                  icon: IconsaxPlusLinear.key,
                  selected: _kind == ListingKind.rent,
                  onTap: () => setState(() => _kind = ListingKind.rent),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _fieldRow([
          _FieldCard(
            label: _t('Property Type', 'סוג הנכס'),
            child: _Select<PropertyType>(
              placeholder: _t('Select property type', 'בחרו סוג נכס'),
              value: _propertyType,
              items: [
                for (final t in PropertyType.values)
                  DropdownMenuItem(
                    value: t,
                    child: Text(_propertyTypeLabel(t)),
                  ),
              ],
              onChanged: (v) => setState(() => _propertyType = v),
            ),
          ),
          // Stored as an id, so the list comes from the table rather than from
          // anything typed. While it loads the field is simply empty; it is
          // optional, so a slow network must not block the form.
          _FieldCard(
            label: _t('Neighborhood', 'שכונה'),
            child: _Select<String>(
              placeholder: _t('Select', 'בחרו'),
              value: _neighborhoodId,
              items: [
                for (final h
                    in hoods.valueOrNull ??
                        const <({String id, String name})>[])
                  DropdownMenuItem(value: h.id, child: Text(h.name)),
              ],
              onChanged: (v) => setState(() => _neighborhoodId = v),
            ),
          ),
        ]),
        const SizedBox(height: 20),
        _FieldCard(
          label: _t('Title', 'כותרת'),
          child: _TextRow(
            controller: _title,
            placeholder: _t(
              'e.g. Modern 3BR Apartment in City Center',
              'לדוגמה: דירת 3 חדרים במרכז העיר',
            ),
          ),
        ),
        const SizedBox(height: 20),
        _FieldCard(
          label: _t('Address', 'כתובת'),
          child: _TextRow(
            controller: _address,
            placeholder: _t('Enter address', 'הזינו כתובת'),
          ),
        ),
        const SizedBox(height: 20),
        _fieldRow([
          // The label follows the listing type, because the number means a
          // different thing for a rental and is stored in a different column.
          _FieldCard(
            label: _kind == ListingKind.rent
                ? _t('Monthly price', 'מחיר לחודש')
                : _t('Price', 'מחיר'),
            child: _TextRow(
              controller: _price,
              placeholder: _t('Enter price', 'הזינו מחיר'),
              keyboardType: TextInputType.number,
            ),
          ),
          // Half rooms are normal in a listing here, so the options step by a
          // half rather than by a whole.
          _FieldCard(
            label: _t('Rooms', 'חדרים'),
            child: _Select<double>(
              placeholder: _t('Select', 'בחרו'),
              value: _rooms,
              items: [
                for (var i = 1; i <= 16; i++)
                  DropdownMenuItem(
                    value: i / 2,
                    child: Text(_roomsLabel(i / 2)),
                  ),
              ],
              onChanged: (v) => setState(() => _rooms = v),
            ),
          ),
          _FieldCard(
            label: _t('Bathrooms', 'חדרי רחצה'),
            child: _Select<int>(
              placeholder: _t('Select', 'בחרו'),
              value: _bathrooms,
              items: [
                for (var i = 1; i <= 6; i++)
                  DropdownMenuItem(value: i, child: Text('$i')),
              ],
              onChanged: (v) => setState(() => _bathrooms = v),
            ),
          ),
        ]),
      ],
    );
  }

  String _propertyTypeLabel(PropertyType t) => switch (t) {
    PropertyType.apartment => _t('Apartment', 'דירה'),
    PropertyType.penthouse => _t('Penthouse', 'פנטהאוז'),
    PropertyType.garden => _t('Garden Apartment', 'דירת גן'),
    PropertyType.duplex => _t('Duplex', 'דופלקס'),
    PropertyType.villa => _t('Villa', 'וילה'),
    PropertyType.studio => _t('Studio', 'סטודיו'),
    PropertyType.other => _t('Other', 'אחר'),
  };

  /// 3.5 reads as "3.5"; 3.0 reads as "3".
  static String _roomsLabel(double v) =>
      v == v.roundToDouble() ? '${v.toInt()}' : '$v';

  // ─────────────────────────────────────────────
  // STEP 2 — the details
  // ─────────────────────────────────────────────
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldCard(
          label: _t('Description', 'תיאור'),
          child: SizedBox(
            height: 140,
            child: TextField(
              controller: _description,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 15,
                color: _kLabel,
              ),
              decoration: InputDecoration(
                hintText: _t(
                  'Describe your apartment, features and highlights',
                  'תארו את הדירה, המאפיינים והיתרונות',
                ),
                hintStyle: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 15,
                  color: _kIconGrey,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _fieldRow([
          _FieldCard(
            label: _t('Floor', 'קומה'),
            child: _Select<int>(
              placeholder: _t('Select', 'בחרו'),
              value: _floor,
              items: [
                for (var i = 0; i <= 40; i++)
                  DropdownMenuItem(value: i, child: Text('$i')),
              ],
              onChanged: (v) => setState(() => _floor = v),
            ),
          ),
          _FieldCard(
            label: _t('Total Floors', 'סה״כ קומות'),
            child: _Select<int>(
              placeholder: _t('Select', 'בחרו'),
              value: _totalFloors,
              items: [
                for (var i = 1; i <= 40; i++)
                  DropdownMenuItem(value: i, child: Text('$i')),
              ],
              onChanged: (v) => setState(() => _totalFloors = v),
            ),
          ),
          _FieldCard(
            label: _t('Area (m²)', 'שטח (מ״ר)'),
            child: _TextRow(
              controller: _area,
              placeholder: _t('Enter area', 'הזינו שטח'),
              keyboardType: TextInputType.number,
            ),
          ),
        ]),
        const SizedBox(height: 20),
        _FieldCard(
          label: _t('Amenities', 'מתקנים'),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final a in _Amenity.values)
                _AmenityChip(
                  label: _amenityLabel(a),
                  icon: a.icon,
                  selected: _amenities.contains(a),
                  onTap: () => setState(() {
                    _amenities.contains(a)
                        ? _amenities.remove(a)
                        : _amenities.add(a);
                  }),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _amenityLabel(_Amenity a) => switch (a) {
    _Amenity.balcony => _t('Balcony', 'מרפסת'),
    _Amenity.parking => _t('Parking', 'חניה'),
    _Amenity.elevator => _t('Elevator', 'מעלית'),
    _Amenity.storage => _t('Storage', 'מחסן'),
    _Amenity.mamad => _t('Protected room', 'ממ״ד'),
  };

  // ─────────────────────────────────────────────
  // STEP 3 — the photographs
  // ─────────────────────────────────────────────
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t(
            'First photo will be used as the cover image',
            'התמונה הראשונה תשמש כתמונת השער',
          ),
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFFFF3434),
          ),
        ),
        const SizedBox(height: 20),
        // Four across rather than three: the column is 700 wide here, so a
        // tile is about the size the mobile grid draws one at.
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 12.0;
            const perRow = 4;
            final tile = (constraints.maxWidth - gap * (perRow - 1)) / perRow;
            final slots =
                _photos.length + (_photos.length < _maxPhotos ? 1 : 0);
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (var i = 0; i < slots; i++)
                  SizedBox(
                    width: tile,
                    height: tile,
                    child: i == _photos.length
                        ? _buildAddSlot()
                        : _buildPhotoTile(i),
                  ),
              ],
            );
          },
        ),
        if (_uploading) ...[
          const SizedBox(height: 20),
          const Center(child: CircularProgressIndicator()),
        ],
      ],
    );
  }

  Widget _buildPhotoTile(int index) {
    return Stack(
      fit: StackFit.expand,
      children: [
        NetworkPhoto(
          url: _photos[index],
          radius: BorderRadius.circular(10),
          icon: IconsaxPlusBold.image,
        ),
        // The first one is the cover, which is what the label says, so
        // reordering is done by making another one first.
        if (index == 0)
          PositionedDirectional(
            start: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                _t('Main Image', 'תמונה ראשית'),
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 11,
                  color: Colors.white,
                ),
              ),
            ),
          )
        else
          PositionedDirectional(
            start: 8,
            bottom: 8,
            child: Tooltip(
              message: _t('Make this the cover', 'הפכו לתמונת השער'),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => setState(() {
                    final photo = _photos.removeAt(index);
                    _photos.insert(0, photo);
                  }),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      IconsaxPlusLinear.star_1,
                      size: 15,
                      color: AppColors.midBlue,
                    ),
                  ),
                ),
              ),
            ),
          ),
        PositionedDirectional(
          end: 8,
          top: 8,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _removePhoto(index),
              child: Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: Color(0xFFE53935),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddSlot() {
    return MouseRegion(
      cursor: _uploading ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _uploading ? null : _pickPhotos,
        child: CustomPaint(
          painter: _DashedBorderPainter(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, size: 28, color: AppColors.midBlue),
              const SizedBox(height: 6),
              Text(
                _t('Add', 'הוסיפו'),
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 12,
                  color: _kIconGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // THE BUTTONS
  // ─────────────────────────────────────────────
  Widget _buildButtonRow() {
    final isLast = _currentStep == 2;

    return Row(
      children: [
        if (_currentStep > 0)
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _onBack,
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 28),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.midBlue),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Text(
                  _t('Back', 'חזרה'),
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.midBlue,
                  ),
                ),
              ),
            ),
          ),
        const Spacer(),
        MouseRegion(
          cursor: _saving ? SystemMouseCursors.basic : SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _saving ? null : (isLast ? _onSubmit : _onNext),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 32),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _saving ? const Color(0xFFB9C0CE) : AppColors.midBlue,
                borderRadius: BorderRadius.circular(60),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_saving) ...[
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    isLast
                        ? _t('Submit for Approval', 'שליחה לאישור')
                        : _t('Next', 'הבא'),
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  if (!isLast) ...[
                    const SizedBox(width: 8),
                    Icon(
                      _isHebrew
                          ? IconsaxPlusLinear.arrow_left
                          : IconsaxPlusLinear.arrow_right_3,
                      size: 20,
                      color: Colors.white,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // THE RAIL — which step, and what it is for
  // ─────────────────────────────────────────────
  Widget _buildRail() {
    final steps = [
      (
        label: _t('Basics', 'בסיס'),
        blurb: _t(
          'Fill in the details about your property',
          'מלאו את פרטי הנכס',
        ),
      ),
      (
        label: _t('Details', 'פרטים'),
        blurb: _t(
          'Add more details about your property',
          'הוסיפו פרטים נוספים על הנכס',
        ),
      ),
      (
        label: _t('Photos', 'תמונות'),
        blurb: _t('Upload photos of your apartment', 'העלו תמונות של הדירה'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _kBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < steps.length; i++)
                _RailStep(
                  number: i + 1,
                  label: steps[i].label,
                  blurb: steps[i].blurb,
                  done: i < _currentStep,
                  current: i == _currentStep,
                  isLast: i == steps.length - 1,
                  // A step already done can be reopened; one not reached yet
                  // cannot, because the form is filled in order.
                  onTap: i < _currentStep
                      ? () => setState(() => _currentStep = i)
                      : null,
                ),
            ],
          ),
        ),
        // Said on the step that submits, where it answers what the button
        // about to be pressed will do.
        if (_currentStep == 2) ...[
          const SizedBox(height: 20),
          _buildPendingCard(),
        ],
      ],
    );
  }

  Widget _buildPendingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kPendingBg,
        border: Border.all(color: _kPendingBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(IconsaxPlusLinear.clock, size: 24, color: _kPendingAccent),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('Pending Approval', 'ממתין לאישור'),
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _kLabel,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _t(
                    'You can check the status of your listing anytime from the My Apartments page.',
                    'תוכלו לבדוק את סטטוס המודעה בכל עת בעמוד ״הדירות שלי״.',
                  ),
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 13,
                    height: 1.45,
                    color: _kGreyText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // CONFIRMATION — the listing is in, as pending
  // ─────────────────────────────────────────────
  Widget _buildConfirmation() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 40),
          decoration: BoxDecoration(
            border: Border.all(color: _kBorder),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Container(
                width: 245,
                height: 162,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Icon(
                    IconsaxPlusLinear.tick_circle,
                    size: 72,
                    color: AppColors.midBlue,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                _t('Listing Submitted!', 'המודעה נשלחה!'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.nunito,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: _kLabel,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _t(
                  "Your apartment has been submitted for approval. We'll review the details and publish it once approved.",
                  'הדירה שלכם נשלחה לאישור. נבדוק את הפרטים ונפרסם אותה לאחר האישור.',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 15,
                  height: 1.5,
                  color: _kGreyText,
                ),
              ),
              const SizedBox(height: 28),
              _buildPendingCard(),
              const SizedBox(height: 32),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => context.go('/my-apartments'),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.midBlue,
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: Text(
                      _t('Back to My Apartments', 'חזרה לדירות שלי'),
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Two or three fields on one line, each taking an equal share.
  Widget _fieldRow(List<Widget> fields) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < fields.length; i++) ...[
          if (i > 0) const SizedBox(width: 20),
          Expanded(child: fields[i]),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// THE PAGE COLUMN
// ═══════════════════════════════════════════════

/// A narrower column than [WebSection]'s 1600: a form reads worse the wider
/// its fields get, and 1080 holds the 700px form and its rail with room to
/// spare on a 1440 laptop.
class _FormPage extends StatelessWidget {
  final Widget child;
  const _FormPage({required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1128),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: child,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// FORM PARTS — the mobile shapes, at desktop size
// ═══════════════════════════════════════════════

class _FieldCard extends StatelessWidget {
  final String label;
  final Widget child;
  const _FieldCard({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _kLabel,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _TextRow extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final TextInputType? keyboardType;

  const _TextRow({
    required this.controller,
    required this.placeholder,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(
          fontFamily: AppFonts.inter,
          fontSize: 15,
          color: _kLabel,
        ),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 15,
            color: _kIconGrey,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
      ),
    );
  }
}

class _Select<T> extends StatelessWidget {
  final String placeholder;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _Select({
    required this.placeholder,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          // The neighbourhood list arrives after the field is built, so a value
          // that is not in the list yet shows as the placeholder rather than
          // throwing.
          value: items.any((i) => i.value == value) ? value : null,
          isExpanded: true,
          isDense: true,
          hint: Text(
            placeholder,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 15,
              color: _kIconGrey,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          icon: const Icon(
            IconsaxPlusLinear.arrow_down_1,
            size: 20,
            color: _kIconGrey,
          ),
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 15,
            color: _kLabel,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.midBlue : _kIconGrey;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: selected ? _kSelectedBg : Colors.white,
            border: Border.all(
              color: selected
                  ? AppColors.midBlue.withValues(alpha: 0.8)
                  : _kBorder,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmenityChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _AmenityChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.midBlue : _kIconGrey;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? _kSelectedBg : Colors.white,
            border: Border.all(
              color: selected
                  ? AppColors.midBlue.withValues(alpha: 0.8)
                  : _kBorder,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// THE RAIL'S STEPS
// ═══════════════════════════════════════════════

class _RailStep extends StatelessWidget {
  final int number;
  final String label, blurb;
  final bool done, current, isLast;
  final VoidCallback? onTap;

  const _RailStep({
    required this.number,
    required this.label,
    required this.blurb,
    required this.done,
    required this.current,
    required this.isLast,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final reached = done || current;
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: reached ? AppColors.midBlue : const Color(0xFFF6F6F6),
                shape: BoxShape.circle,
                border: Border.all(
                  color: reached ? AppColors.midBlue : _kBorder,
                ),
              ),
              child: Center(
                child: done
                    ? const Icon(Icons.check, size: 15, color: Colors.white)
                    : Text(
                        '$number',
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: reached ? Colors.white : _kIconGrey,
                        ),
                      ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 44,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: done ? AppColors.midBlue : _kBorder,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: reached ? AppColors.midBlue : _kIconGrey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  blurb,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 13,
                    height: 1.4,
                    color: _kGreyText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (onTap == null) return row;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: row),
    );
  }
}

// ═══════════════════════════════════════════════
// THE EMPTY PHOTO SLOT'S BORDER
// ═══════════════════════════════════════════════

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _kIconGrey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const dashWidth = 6.0;
    const dashGap = 4.0;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(10),
    );

    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
