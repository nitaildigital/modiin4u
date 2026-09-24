import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/network_photo.dart';
import '../models/listing.dart';
import '../providers/listing_providers.dart';

/// Add Apartment – multi-step form wizard.
/// Step 1: Basic Information (listing type, property type, title, price,
///         address, neighbourhood, rooms, bathrooms).
/// Step 2: Apartment Details (description, floor, total floors, area,
///         amenities).
/// Step 3: Add Photos (main image, thumbnails, upload slots).
///
/// The form used to be a drawing: the inputs had no controllers, the
/// dropdowns were a line of text with an arrow beside it, and "Submit" only
/// advanced to the confirmation screen. Nothing was written, so every
/// apartment a resident entered was lost the moment they left. It writes to
/// `listings` now, as `pending`, for an administrator to approve.
class AddApartmentScreen extends ConsumerStatefulWidget {
  const AddApartmentScreen({super.key});

  @override
  ConsumerState<AddApartmentScreen> createState() => _AddApartmentScreenState();
}

class _AddApartmentScreenState extends ConsumerState<AddApartmentScreen> {
  int _currentStep = 0; // 0 = Basics, 1 = Details, 2 = Photos, 3 = Submitted

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

  /// Each chip maps to a boolean column, so a chip that is on is a value that
  /// is actually stored. The mock had "Air Conditioning" and "Garden" chips
  /// with nowhere to put them; a garden is a property type here, and there is
  /// no column for air conditioning, so neither is offered rather than
  /// offered and dropped.
  final Set<_Amenity> _amenities = {};

  bool _saving = false;

  // ── Photographs ──
  //
  // Uploaded as they are picked rather than on submit, so the person sees
  // them appear and a slow connection does not stall the final button. The
  // list holds public URLs; the first is the cover.
  static const _maxPhotos = 9;
  final List<String> _photos = [];
  bool _uploading = false;

  Future<void> _pickPhotos() async {
    final l = L.of(context);
    final room = _maxPhotos - _photos.length;
    if (room <= 0) {
      _toast(l.maxPhotosReached(_maxPhotos));
      return;
    }

    final List<XFile> picked;
    try {
      picked = await ImagePicker().pickMultiImage(
        maxWidth: 2000,
        imageQuality: 85,
      );
    } catch (_) {
      if (mounted) _toast(l.uploadFailed, error: true);
      return;
    }
    if (picked.isEmpty || !mounted) return;

    setState(() => _uploading = true);

    final uid = SupabaseConfig.client.auth.currentUser?.id;
    if (uid == null) {
      setState(() => _uploading = false);
      _toast(l.signInToPostListing, error: true);
      return;
    }

    for (final file in picked.take(room)) {
      try {
        final bytes = await file.readAsBytes();
        // The bucket refuses anything over 10MB and reports it as a plain
        // failure, so the size is checked here to say why.
        if (bytes.lengthInBytes > 10 * 1024 * 1024) {
          if (mounted) _toast(l.photoTooLarge, error: true);
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
        if (mounted) _toast(l.uploadFailed, error: true);
      }
    }

    if (mounted) setState(() => _uploading = false);
  }

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

  @override
  void dispose() {
    _title.dispose();
    _price.dispose();
    _address.dispose();
    _description.dispose();
    _area.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    }
  }

  Future<void> _onSubmit() async {
    if (_saving) return;
    final l = L.of(context);

    // Checked here rather than on the way out of step 1, so someone can fill
    // the form in whatever order they like and still be told what is missing.
    if (_title.text.trim().isEmpty) {
      setState(() => _currentStep = 0);
      _toast(l.errTitleRequired, error: true);
      return;
    }
    final price = int.tryParse(_price.text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (price == null || price <= 0) {
      setState(() => _currentStep = 0);
      _toast(l.errPriceRequired, error: true);
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

      // So "My Apartments" shows it without the person having to pull to
      // refresh.
      ref.invalidate(myListingsProvider);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _currentStep = 3;
      });
    } on StateError {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast(l.signInToPostListing, error: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast(l.errCouldNotSubmit, error: true);
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

  void _onBack() {
    if (_currentStep == 3) {
      // From confirmation, go back to My Apartments
      context.pushReplacement('/my-apartments');
    } else if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // ═══════════════════════════════════
                // Top bar: back + title + step label
                // ═══════════════════════════════════
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _onBack,
                        child: const SizedBox(
                          width: 24,
                          height: 24,
                          child: Icon(
                            IconsaxPlusLinear.arrow_left,
                            size: 24,
                            color: Color(0xFF3D3D3D),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            l.addApartment,
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      // Step label (hidden on confirmation)
                      if (_currentStep < 3)
                        SizedBox(
                          width: 65,
                          child: Text(
                            'Step ${_currentStep + 1} of 3',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF123A72),
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 24),
                    ],
                  ),
                ),

                // ═══════════════════════════════════
                // Step progress indicator (hidden on confirmation)
                // ═══════════════════════════════════
                if (_currentStep < 3) ...[
                  const SizedBox(height: 16),
                  _StepProgressBar(
                    currentStep: _currentStep,
                    labels: [l.stepBasics, l.stepDetails, l.stepPhotos],
                  ),
                  const SizedBox(height: 20),
                ],

                // ═══════════════════════════════════
                // Step content
                // ═══════════════════════════════════
                Expanded(
                  child: _currentStep == 0
                      ? _buildStep1()
                      : _currentStep == 1
                      ? _buildStep2()
                      : _currentStep == 2
                      ? _buildStep3()
                      : _buildConfirmation(),
                ),

                // ═══════════════════════════════════
                // Bottom bar button
                // ═══════════════════════════════════
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFE7E7E7))),
                  ),
                  child: GestureDetector(
                    onTap: _currentStep < 2
                        ? _onNext
                        : _currentStep == 2
                        ? _onSubmit
                        : () => context.pushReplacement('/my-apartments'),
                    child: Container(
                      width: double.infinity,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF123A72),
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentStep == 3
                                ? l.backToMyApartments
                                : _currentStep == 2
                                ? l.submitForApproval
                                : l.next,
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          if (_currentStep < 2) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              IconsaxPlusLinear.arrow_right_3,
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
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Step 1: Basic Information
  // ═══════════════════════════════════════════════
  Widget _buildStep1() {
    final l = L.of(context);
    final hoods = ref.watch(listingNeighborhoodsProvider);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      children: [
        // Section header
        Text(
          l.basicInformation,
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F1F1F),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l.fillInPropertyDetails,
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6D6D6D),
          ),
        ),
        const SizedBox(height: 20),

        // ── Listing Type (toggle) ──
        _FormCard(
          label: l.listingType,
          child: Row(
            children: [
              Expanded(
                child: _ToggleButton(
                  label: l.forSale,
                  icon: IconsaxPlusLinear.tag,
                  selected: _kind == ListingKind.sale,
                  onTap: () => setState(() => _kind = ListingKind.sale),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ToggleButton(
                  label: l.forRent,
                  icon: IconsaxPlusLinear.key,
                  selected: _kind == ListingKind.rent,
                  onTap: () => setState(() => _kind = ListingKind.rent),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Property Type ──
        _FormCard(
          label: l.propertyType,
          child: _DropdownRow<PropertyType>(
            placeholder: l.selectPropertyType,
            value: _propertyType,
            items: [
              for (final t in PropertyType.values)
                DropdownMenuItem(
                  value: t,
                  child: Text(_propertyTypeLabel(l, t)),
                ),
            ],
            onChanged: (v) => setState(() => _propertyType = v),
          ),
        ),
        const SizedBox(height: 16),

        // ── Title ──
        _FormCard(
          label: l.listingTitle,
          child: _InputRow(controller: _title, placeholder: l.listingTitleHint),
        ),
        const SizedBox(height: 16),

        // ── Price ──
        //
        // The label follows the listing type, because the number means a
        // different thing for a rental and is stored in a different column.
        _FormCard(
          label: _kind == ListingKind.rent ? l.pricePerMonth : l.price,
          child: _InputRow(
            controller: _price,
            placeholder: l.enterPrice,
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(height: 16),

        // ── Address ──
        _FormCard(
          label: l.address,
          child: _InputRow(controller: _address, placeholder: l.enterAddress),
        ),
        const SizedBox(height: 16),

        // ── Neighbourhood ──
        //
        // Stored as an id, so the list comes from the table rather than from
        // anything typed. While it is loading the field is simply empty; it
        // is optional, so a slow network must not block the form.
        _FormCard(
          label: l.neighborhood,
          child: _DropdownRow<String>(
            placeholder: l.selectHint,
            value: _neighborhoodId,
            items: [
              for (final h
                  in hoods.valueOrNull ?? const <({String id, String name})>[])
                DropdownMenuItem(value: h.id, child: Text(h.name)),
            ],
            onChanged: (v) => setState(() => _neighborhoodId = v),
          ),
        ),
        const SizedBox(height: 16),

        // ── Rooms ──
        //
        // Half rooms are normal in a listing here, so the options step by a
        // half rather than by a whole.
        _FormCard(
          label: l.roomsLabel,
          child: _DropdownRow<double>(
            placeholder: l.selectRooms,
            value: _rooms,
            items: [
              for (var i = 1; i <= 16; i++)
                DropdownMenuItem(value: i / 2, child: Text(_roomsLabel(i / 2))),
            ],
            onChanged: (v) => setState(() => _rooms = v),
          ),
        ),
        const SizedBox(height: 16),

        // ── Bathrooms ──
        _FormCard(
          label: l.bathrooms,
          child: _DropdownRow<int>(
            placeholder: l.selectBathrooms,
            value: _bathrooms,
            items: [
              for (var i = 1; i <= 6; i++)
                DropdownMenuItem(value: i, child: Text('$i')),
            ],
            onChanged: (v) => setState(() => _bathrooms = v),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  static String _propertyTypeLabel(L l, PropertyType t) => switch (t) {
    PropertyType.apartment => l.propTypeApartment,
    PropertyType.penthouse => l.propTypePenthouse,
    PropertyType.garden => l.propTypeGarden,
    PropertyType.duplex => l.propTypeDuplex,
    PropertyType.villa => l.propTypeVilla,
    PropertyType.studio => l.propTypeStudio,
    PropertyType.other => l.propTypeOther,
  };

  /// 3.5 reads as "3.5"; 3.0 reads as "3".
  static String _roomsLabel(double v) =>
      v == v.roundToDouble() ? '${v.toInt()}' : '$v';

  // ═══════════════════════════════════════════════
  // Step 2: Apartment Details
  // ═══════════════════════════════════════════════
  Widget _buildStep2() {
    final l = L.of(context);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      children: [
        // Section header
        Text(
          l.apartmentDetails,
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F1F1F),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l.addMoreDetails,
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6D6D6D),
          ),
        ),
        const SizedBox(height: 20),

        // ── Description ──
        Container(
          height: 150,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE7E7E7)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.description,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1F1F1F),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TextField(
                  controller: _description,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 14,
                    color: const Color(0xFF1F1F1F),
                  ),
                  decoration: InputDecoration(
                    hintText: l.describeYourApartment,
                    hintStyle: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      color: const Color(0xFF6D6D6D),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Floor / Total floors ──
        Row(
          children: [
            Expanded(
              child: _FormCard(
                label: l.floor,
                child: _DropdownRow<int>(
                  placeholder: l.selectHint,
                  value: _floor,
                  items: [
                    for (var i = 0; i <= 40; i++)
                      DropdownMenuItem(value: i, child: Text('$i')),
                  ],
                  onChanged: (v) => setState(() => _floor = v),
                ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: _FormCard(
                label: l.totalFloors,
                child: _DropdownRow<int>(
                  placeholder: l.selectHint,
                  value: _totalFloors,
                  items: [
                    for (var i = 1; i <= 40; i++)
                      DropdownMenuItem(value: i, child: Text('$i')),
                  ],
                  onChanged: (v) => setState(() => _totalFloors = v),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Area ──
        _FormCard(
          label: l.areaSqm,
          child: _InputRow(
            controller: _area,
            placeholder: l.enterArea,
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(height: 16),

        // ── Amenities ──
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE7E7E7)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.amenities,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1F1F1F),
                ),
              ),
              const SizedBox(height: 13),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final a in _Amenity.values)
                    _AmenityChip(
                      label: _amenityLabel(l, a),
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
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  static String _amenityLabel(L l, _Amenity a) => switch (a) {
    _Amenity.balcony => l.amenityBalcony,
    _Amenity.parking => l.amenityParking,
    _Amenity.elevator => l.amenityElevator,
    _Amenity.storage => l.amenityStorage,
    _Amenity.mamad => l.amenityMamad,
  };

  // Step 3: Add Photos
  // ═══════════════════════════════════════════════
  Widget _buildStep3() {
    final l = L.of(context);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      children: [
        Text(
          l.addPhotos,
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F1F1F),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l.uploadApartmentPhotos,
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 12,
            color: const Color(0xFF6D6D6D),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l.firstPhotoIsCover,
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFFFF3434),
          ),
        ),
        const SizedBox(height: 16),

        // ── The photographs, as a grid that grows ──
        //
        // This was eight fixed boxes: three painted blue to look like
        // uploaded pictures and five empty slots that did nothing. Nothing was
        // ever picked and nothing was ever uploaded, so every listing reached
        // the directory with no photograph at all.
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _photos.length + (_photos.length < _maxPhotos ? 1 : 0),
          itemBuilder: (_, i) {
            if (i == _photos.length) return _addPhotoSlot(l);
            return _photoTile(l, i);
          },
        ),

        if (_uploading) ...[
          const SizedBox(height: 16),
          const Center(child: CircularProgressIndicator()),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _photoTile(L l, int index) {
    return Stack(
      fit: StackFit.expand,
      children: [
        NetworkPhoto(
          url: _photos[index],
          radius: BorderRadius.circular(8),
          icon: IconsaxPlusBold.image,
        ),
        // The first one is the cover, which is what the label says, so
        // reordering is done by making another one first.
        if (index == 0)
          Positioned(
            left: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                l.mainImage,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 10,
                  color: Colors.white,
                ),
              ),
            ),
          )
        else
          Positioned(
            left: 6,
            bottom: 6,
            child: GestureDetector(
              onTap: () => setState(() {
                final photo = _photos.removeAt(index);
                _photos.insert(0, photo);
              }),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  IconsaxPlusLinear.star_1,
                  size: 14,
                  color: Color(0xFF123A72),
                ),
              ),
            ),
          ),
        Positioned(
          right: 6,
          top: 6,
          child: GestureDetector(
            onTap: () => _removePhoto(index),
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xFFE53935),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 15, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _addPhotoSlot(L l) {
    return GestureDetector(
      onTap: _uploading ? null : _pickPhotos,
      child: CustomPaint(
        painter: _DashedBorderPainter(),
        child: const Center(
          child: Icon(Icons.add, size: 28, color: Color(0xFF123A72)),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Confirmation: Listing Submitted
  // ═══════════════════════════════════════════════
  Widget _buildConfirmation() {
    final l = L.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        children: [
          const SizedBox(height: 60),

          // Success illustration placeholder
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
                color: Color(0xFF123A72),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            l.listingSubmitted,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 12),

          // Description
          SizedBox(
            width: 327,
            child: Text(
              l.submittedForApprovalLong,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.4,
                color: const Color(0xFF6D6D6D),
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Pending Approval card
          Container(
            width: 338,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9EF),
              border: Border.all(color: const Color(0xFFFFE8C3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Clock icon
                const Icon(
                  IconsaxPlusLinear.clock,
                  size: 24,
                  color: Color(0xFFEA9D23),
                ),
                const SizedBox(width: 12),
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.pendingApproval,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F1F1F),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l.listingBeingReviewed,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF6D6D6D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Footer note
          SizedBox(
            width: 327,
            child: Text(
              l.checkStatusAnytimeLong,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.4,
                color: const Color(0xFF6D6D6D),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Step progress bar (with checkmark for completed)
// ═══════════════════════════════════════════════════

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

class _StepProgressBar extends StatelessWidget {
  final int currentStep;
  final List<String> labels;

  const _StepProgressBar({required this.currentStep, required this.labels});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 268,
      height: 47,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Connecting line
          Positioned(
            left: 40,
            top: 11,
            child: Container(
              width: 186,
              height: 2,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                gradient: LinearGradient(
                  colors: const [
                    Color(0xFF123A72),
                    Color(0xFF123A72),
                    Color(0xFFE7E7E7),
                    Color(0xFFE7E7E7),
                  ],
                  stops: [
                    0.0,
                    currentStep == 0
                        ? 0.0
                        : currentStep == 1
                        ? 0.5
                        : 1.0,
                    currentStep == 0
                        ? 0.0
                        : currentStep == 1
                        ? 0.5
                        : 1.0,
                    1.0,
                  ],
                ),
              ),
            ),
          ),

          // Step circles + labels
          for (int i = 0; i < labels.length; i++)
            Positioned(
              left: i * 106.0,
              top: 0,
              child: SizedBox(
                width: 56,
                child: Column(
                  children: [
                    // Circle
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: i <= currentStep
                            ? const Color(0xFF123A72)
                            : const Color(0xFFF6F6F6),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Center(
                        child: i < currentStep
                            // Completed: show checkmark
                            ? const Icon(
                                Icons.check,
                                size: 12,
                                color: Colors.white,
                              )
                            // Current or future: show number
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontFamily: AppFonts.inter,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: i <= currentStep
                                      ? Colors.white
                                      : const Color(0xFF6D6D6D),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Label
                    Text(
                      labels[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: i <= currentStep
                            ? const Color(0xFF123A72)
                            : const Color(0xFF6D6D6D),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Form card wrapper
// ═══════════════════════════════════════════════════

class _FormCard extends StatelessWidget {
  final String label;
  final Widget child;
  const _FormCard({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE7E7E7)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Toggle button (For Sale / For Rent)
// ═══════════════════════════════════════════════════

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
    final color = selected ? const Color(0xFF123A72) : const Color(0xFF6D6D6D);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEEF4FD) : Colors.white,
          border: Border.all(
            color: selected
                ? const Color(0xFF123A72).withValues(alpha: 0.8)
                : const Color(0xFFE7E7E7),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Amenity chip (toggleable)
// ═══════════════════════════════════════════════════

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
    final color = selected ? const Color(0xFF123A72) : const Color(0xFF6D6D6D);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEEF4FD) : Colors.white,
          border: Border.all(
            color: selected
                ? const Color(0xFF123A72).withValues(alpha: 0.8)
                : const Color(0xFFE7E7E7),
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Dropdown-style row (placeholder + chevron)
// ═══════════════════════════════════════════════════

/// A dropdown, rather than a line of text with an arrow drawn next to it.
///
/// The mock version took only a placeholder and could not be opened, so every
/// choice on the form — property type, rooms, floor — was unreachable.
class _DropdownRow<T> extends StatelessWidget {
  final String placeholder;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropdownRow({
    required this.placeholder,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: items.any((i) => i.value == value) ? value : null,
        isExpanded: true,
        isDense: true,
        hint: Text(
          placeholder,
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6D6D6D),
          ),
        ),
        icon: const Icon(
          IconsaxPlusLinear.arrow_down_1,
          size: 20,
          color: Color(0xFF6D6D6D),
        ),
        style: TextStyle(
          fontFamily: AppFonts.inter,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF1F1F1F),
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Text input row (placeholder only, no chevron)
// ═══════════════════════════════════════════════════

/// A text field with a controller behind it.
///
/// It had none, so everything typed into the form was discarded on the way to
/// the next step.
class _InputRow extends StatelessWidget {
  final String placeholder;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  const _InputRow({
    required this.placeholder,
    required this.controller,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(
          fontFamily: AppFonts.inter,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF1F1F1F),
        ),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6D6D6D),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Red delete circle (photo remove button)
// ═══════════════════════════════════════════════════

// ═══════════════════════════════════════════════════
// Dashed upload slot (empty photo placeholder)
// ═══════════════════════════════════════════════════

// ═══════════════════════════════════════════════════
// Dashed border painter
// ═══════════════════════════════════════════════════

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6D6D6D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const dashWidth = 6.0;
    const dashGap = 4.0;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(8),
    );

    // Extract path from rounded rect and draw dashes along it
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
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
