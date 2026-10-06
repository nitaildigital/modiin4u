import 'package:flutter/material.dart';
import '../../../shared/widgets/sign_in_action.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../auth/widgets/m_account_widgets.dart';
import '../models/listing.dart';
import '../providers/listing_providers.dart';
import 'web_add_apartment_screen.dart';
import '../../../core/router/app_router.dart' show AppNavigation;

/// Add Apartment – multi-step form wizard.
/// Step 1: Basic Information (listing type, property type, title, price,
///         address, neighbourhood, rooms, bathrooms).
/// Step 2: Apartment Details (description, floor, total floors, area,
///         amenities).
/// Step 3: Add Photos (cover image, then the rest).
///
/// The form used to be a drawing: the inputs had no controllers, the
/// dropdowns were a line of text with an arrow beside it, and "Submit" only
/// advanced to the confirmation screen. Nothing was written, so every
/// apartment a resident entered was lost the moment they left. It writes to
/// `listings` now, as `pending`, for an administrator to approve — or as
/// `draft` when the person saves it to finish later.
class AddApartmentScreen extends StatelessWidget {
  /// A draft saved earlier, reopened from My Apartments.
  final String? draftId;

  const AddApartmentScreen({super.key, this.draftId});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) return WebAddApartmentContent(draftId: draftId);
        return _MobileAddApartmentContent(draftId: draftId);
      },
    );
  }
}

const _mid = Color(0xFF123A72);
const _grey = Color(0xFF6D6D6D);
const _hairline = Color(0xFFE7E7E7);
const _ink = Color(0xFF1F1F1F);

class _MobileAddApartmentContent extends ConsumerStatefulWidget {
  final String? draftId;
  const _MobileAddApartmentContent({this.draftId});

  @override
  ConsumerState<_MobileAddApartmentContent> createState() =>
      _MobileAddApartmentContentState();
}

class _MobileAddApartmentContentState
    extends ConsumerState<_MobileAddApartmentContent> {
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
  // Who buyers call. The form never asked, so an approved resident's listing
  // had no Contact button at all.
  final _contactName = TextEditingController();
  final _contactPhone = TextEditingController();
  final _area = TextEditingController();
  int? _floor;
  int? _totalFloors;

  /// Each chip maps to a boolean column, so a chip that is on is a value that
  /// is actually stored. The design also has "Air Conditioning" and
  /// "Security" chips and a parking drop-down with options; there is no
  /// column for air conditioning or security, and parking is a yes or a no,
  /// so those are not offered rather than offered and dropped.
  final Set<_Amenity> _amenities = {};

  bool _saving = false;

  /// The row this form writes over once it has been saved as a draft, so a
  /// second "Save Draft" or the final submit does not add another listing.
  String? _draftId;
  late bool _loadingDraft = widget.draftId != null;

  // ── Photographs ──
  //
  // Uploaded as they are picked rather than on submit, so the person sees
  // them appear and a slow connection does not stall the final button. The
  // list holds public URLs; the first is the cover.
  static const _maxPhotos = 9;
  final List<String> _photos = [];
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    // The poster's own name and phone to start with; they can change them.
    final me = ref.read(authProvider);
    _contactName.text = me?.name ?? '';
    _contactPhone.text = me?.phone ?? '';
    if (widget.draftId != null) _loadDraft(widget.draftId!);
  }

  /// Fills the form from a draft saved earlier. Anything that is no longer a
  /// draft — sent for review in the meantime, say — is not reopened, and the
  /// form starts empty instead of editing a listing that is being reviewed.
  Future<void> _loadDraft(String id) async {
    Listing? draft;
    try {
      draft = await ref.read(listingRepositoryProvider).fetchById(id);
    } catch (_) {
      draft = null;
    }
    if (!mounted) return;
    if (draft == null || draft.status != ListingStatus.draft) {
      setState(() => _loadingDraft = false);
      return;
    }
    final d = draft;
    setState(() {
      _draftId = d.id;
      _kind = d.kind;
      _propertyType = d.propertyType;
      _title.text = d.title;
      final price = d.effectivePrice;
      if (price != null) _price.text = '$price';
      _address.text = d.address ?? '';
      _neighborhoodId = d.neighborhoodId;
      _rooms = d.rooms;
      _bathrooms = d.bathrooms;
      _description.text = d.description ?? '';
      _contactName.text = d.contactName ?? _contactName.text;
      _contactPhone.text = d.contactPhone ?? _contactPhone.text;
      _area.text = d.sqm?.toString() ?? '';
      _floor = d.floor;
      _totalFloors = d.totalFloors;
      _amenities
        ..clear()
        ..addAll([
          if (d.hasBalcony) _Amenity.balcony,
          if (d.hasParking) _Amenity.parking,
          if (d.hasElevator) _Amenity.elevator,
          if (d.hasStorage) _Amenity.storage,
          if (d.hasMamad) _Amenity.mamad,
        ]);
      _photos
        ..clear()
        ..addAll([if (d.coverUrl != null) d.coverUrl!, ...d.gallery]);
      _loadingDraft = false;
    });
  }

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
      _toast(l.signInToPostListing, error: true, signIn: true);
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
    _contactName.dispose();
    _contactPhone.dispose();
    _area.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    }
  }

  int? _parsedPrice() {
    final price = int.tryParse(_price.text.replaceAll(RegExp(r'[^0-9]'), ''));
    return price == null || price <= 0 ? null : price;
  }

  /// What the form holds, written as a new row or over the saved draft.
  Future<Listing> _write({required bool asDraft, required int? price}) {
    final isRent = _kind == ListingKind.rent;
    return ref
        .read(listingRepositoryProvider)
        .create(
          draftId: _draftId,
          // A broker's listing says so ("Via Broker"); the form never
          // passed it, so every broker listing read as a private one.
          isBroker: ref.read(authProvider)?.isBroker ?? false,
          asDraft: asDraft,
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
          contactName: _contactName.text.trim().isEmpty ? null : _contactName.text.trim(),
          contactPhone: _contactPhone.text.trim().isEmpty ? null : _contactPhone.text.trim(),
          hasParking: _amenities.contains(_Amenity.parking),
          hasElevator: _amenities.contains(_Amenity.elevator),
          hasStorage: _amenities.contains(_Amenity.storage),
          hasBalcony: _amenities.contains(_Amenity.balcony),
          hasMamad: _amenities.contains(_Amenity.mamad),
          coverUrl: _photos.isEmpty ? null : _photos.first,
          gallery: _photos.length > 1 ? _photos.sublist(1) : const [],
        );
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
    final price = _parsedPrice();
    if (price == null) {
      setState(() => _currentStep = 0);
      _toast(l.errPriceRequired, error: true);
      return;
    }

    setState(() => _saving = true);
    try {
      await _write(asDraft: false, price: price);

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
      _toast(l.signInToPostListing, error: true, signIn: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast(l.errCouldNotSubmit, error: true);
    }
  }

  /// Keeps what has been filled in as a `draft` row — which only its owner
  /// can read — to be finished later from My Apartments. The table needs a
  /// title, so that is the one thing asked for; the price and the rest may
  /// still be empty.
  Future<void> _onSaveDraft() async {
    if (_saving || _loadingDraft) return;
    final l = L.of(context);

    if (_title.text.trim().isEmpty) {
      setState(() => _currentStep = 0);
      _toast(l.errTitleRequired, error: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final saved = await _write(asDraft: true, price: _parsedPrice());
      ref.invalidate(myListingsProvider);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _draftId = saved.id;
      });
      _toast(l.draftSaved);
    } on StateError {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast(l.signInToPostListing, error: true, signIn: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast(l.errCouldNotSaveDraft, error: true);
    }
  }

  void _toast(String message, {bool error = false, bool signIn = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontFamily: AppFonts.inter)),
        action: signIn ? signInAction(context) : null,
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
      context.back('/realestate');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final submitted = _currentStep == 3;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: SafeArea(
            child: Column(
              children: [
                // ═══════════════════════════════════
                // Top bar: back, centred title, Save Draft
                // ═══════════════════════════════════
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 10, 15, 0),
                  child: SizedBox(
                    height: 24,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          l.addApartment,
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        Row(
                          children: [
                            MBackArrow(
                              color: const Color(0xFF3D3D3D),
                              onTap: _onBack,
                            ),
                            const Spacer(),
                            // Nothing is left to save once it has been sent.
                            if (!submitted)
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: _onSaveDraft,
                                child: Text(
                                  l.saveDraft,
                                  style: TextStyle(
                                    fontFamily: AppFonts.inter,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: _saving
                                        ? _mid.withValues(alpha: 0.4)
                                        : _mid,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ═══════════════════════════════════
                // Step content
                // ═══════════════════════════════════
                Expanded(
                  child: _loadingDraft
                      ? const Center(child: CircularProgressIndicator())
                      : submitted
                      ? _buildConfirmation()
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(15, 26, 15, 24),
                          children: [
                            Center(
                              child: _StepProgressBar(
                                currentStep: _currentStep,
                                labels: [
                                  l.stepBasics,
                                  l.stepDetails,
                                  l.stepPhotos,
                                ],
                                onStepTap: (i) =>
                                    setState(() => _currentStep = i),
                              ),
                            ),
                            const SizedBox(height: 32),
                            ...switch (_currentStep) {
                              0 => _buildStep1(),
                              1 => _buildStep2(),
                              _ => _buildStep3(),
                            },
                          ],
                        ),
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
                    border: Border(top: BorderSide(color: _hairline)),
                  ),
                  child: _BottomButton(
                    label: submitted
                        ? l.backToMyApartments
                        : _currentStep == 2
                        ? l.submitForApproval
                        : l.next,
                    arrow: _currentStep < 2,
                    loading: _saving && _currentStep == 2,
                    onTap: _loadingDraft
                        ? null
                        : _currentStep < 2
                        ? _onNext
                        : _currentStep == 2
                        ? _onSubmit
                        : () => context.pushReplacement('/my-apartments'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Section title and the grey line under it.
  Widget _sectionHeader(String title, String subtitle, {Widget? extra}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: _grey,
          ),
        ),
        if (extra != null) ...[const SizedBox(height: 6), extra],
      ],
    );
  }

  // ═══════════════════════════════════════════════
  // Step 1: Basic Information
  // ═══════════════════════════════════════════════
  List<Widget> _buildStep1() {
    final l = L.of(context);
    final hoods = ref.watch(listingNeighborhoodsProvider);

    return [
      _sectionHeader(l.basicInformation, l.fillInPropertyDetails),
      const SizedBox(height: 20),

      // ── Listing Type (toggle) ──
      _FormCard(
        label: l.listingType,
        child: Row(
          children: [
            Expanded(
              child: _ToggleButton(
                label: l.forSale,
                svg: 'assets/icons/m_realestate_tag.svg',
                selected: _kind == ListingKind.sale,
                onTap: () => setState(() => _kind = ListingKind.sale),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ToggleButton(
                label: l.forRent,
                svg: 'assets/icons/m_realestate_key.svg',
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
              DropdownMenuItem(value: t, child: Text(_propertyTypeLabel(l, t))),
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
      //
      // The design has a single "Location" line; the table keeps the street
      // address and the neighbourhood apart, and the directory filters on
      // the neighbourhood, so both are asked for.
      _FormCard(
        label: l.address,
        child: _InputRow(controller: _address, placeholder: l.enterAddress),
      ),
      const SizedBox(height: 16),

      // ── Contact ──
      //
      // Filled from the profile; the listing page's Contact button calls it.
      _FormCard(
        label: l.fullName,
        child: _InputRow(controller: _contactName, placeholder: l.fullName),
      ),
      const SizedBox(height: 16),
      _FormCard(
        label: l.phone,
        child: _InputRow(
          controller: _contactPhone,
          placeholder: l.phone,
          keyboardType: TextInputType.phone,
        ),
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
      // The design says bedrooms; a listing here counts rooms, half rooms
      // included, and that is what the table stores — so the options step by
      // a half rather than by a whole.
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
    ];
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
  List<Widget> _buildStep2() {
    final l = L.of(context);

    return [
      _sectionHeader(l.apartmentDetails, l.addMoreDetails),
      const SizedBox(height: 20),

      // ── Description ──
      Container(
        height: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _hairline),
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
                color: _ink,
              ),
            ),
            const SizedBox(height: 13),
            Expanded(
              child: TextField(
                controller: _description,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  color: _ink,
                ),
                decoration: InputDecoration(
                  hintText: l.describeYourApartment,
                  hintMaxLines: 3,
                  hintStyle: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 14,
                    color: _grey,
                  ),
                  // The theme fills inputs grey and rounds them; these sit
                  // inside the white bordered cards.
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
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
          suffix: l.sqmUnit,
        ),
      ),
      const SizedBox(height: 16),

      // ── Amenities ──
      _FormCard(
        label: l.amenities,
        child: Wrap(
          spacing: 8,
          runSpacing: 13,
          children: [
            for (final a in _Amenity.values)
              _AmenityChip(
                label: _amenityLabel(l, a),
                amenity: a,
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
    ];
  }

  static String _amenityLabel(L l, _Amenity a) => switch (a) {
    _Amenity.balcony => l.amenityBalcony,
    _Amenity.parking => l.amenityParking,
    _Amenity.elevator => l.amenityElevator,
    _Amenity.storage => l.amenityStorage,
    _Amenity.mamad => l.amenityMamad,
  };

  // ═══════════════════════════════════════════════
  // Step 3: Add Photos
  // ═══════════════════════════════════════════════
  List<Widget> _buildStep3() {
    final l = L.of(context);

    return [
      // The design's red line asks for at least three photographs. Nothing
      // on the site or in the panel requires any, so no minimum is imposed
      // here; the line says what the first one is for instead.
      _sectionHeader(
        l.addPhotos,
        l.uploadApartmentPhotos,
        extra: Text(
          l.firstPhotoIsCover,
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFFFF3434),
          ),
        ),
      ),
      const SizedBox(height: 16),

      // ── Nine places, as drawn ──
      //
      // The cover large on the start side with two beside it, then two rows
      // of three. Every place that has no photograph yet is an empty dashed
      // slot that opens the picker.
      //
      // This was eight fixed boxes: three painted blue to look like uploaded
      // pictures and five empty slots that did nothing. Nothing was ever
      // picked and nothing was ever uploaded, so every listing reached the
      // directory with no photograph at all.
      LayoutBuilder(
        builder: (context, box) {
          // 235 : 118 with a 10 gap on the 363 the frame is drawn at.
          final side = (box.maxWidth - 10) * 118 / 353;
          return Column(
            children: [
              SizedBox(
                height: 210,
                child: Row(
                  children: [
                    Expanded(child: _slot(l, 0)),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: side,
                      child: Column(
                        children: [
                          Expanded(child: _slot(l, 1)),
                          const SizedBox(height: 10),
                          Expanded(child: _slot(l, 2)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              for (var row = 0; row < 2; row++) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 100,
                  child: Row(
                    children: [
                      for (var c = 0; c < 3; c++) ...[
                        if (c > 0) const SizedBox(width: 12),
                        Expanded(child: _slot(l, 3 + row * 3 + c)),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    ];
  }

  /// A photograph if there is one for this place, otherwise an empty slot.
  /// While photographs are uploading, the first empty place shows it.
  Widget _slot(L l, int index) {
    if (index < _photos.length) return _photoTile(l, index);
    if (_uploading && index == _photos.length) {
      return CustomPaint(
        painter: _DashedBorderPainter(),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: _mid),
          ),
        ),
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _uploading ? null : _pickPhotos,
      child: CustomPaint(
        painter: _DashedBorderPainter(),
        child: Center(
          child: SvgPicture.asset(
            'assets/icons/m_realestate_plus.svg',
            width: 24,
            height: 24,
          ),
        ),
      ),
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
          PositionedDirectional(
            start: 10,
            top: 10,
            child: Container(
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _mid,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                l.mainImage,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
            ),
          )
        else
          PositionedDirectional(
            start: 6,
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
                  color: _mid,
                ),
              ),
            ),
          ),
        PositionedDirectional(
          end: 8,
          top: 8,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _removePhoto(index),
            child: Container(
              width: 18,
              height: 18,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFFF3434),
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(
                'assets/icons/m_realestate_close_x.svg',
                width: 7.108,
                height: 7.036,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  // Confirmation: Listing Submitted
  // ═══════════════════════════════════════════════
  Widget _buildConfirmation() {
    final l = L.of(context);
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              children: [
                const SizedBox(height: 94),
                Image.asset(
                  'assets/images/m_realestate_listing_submitted.webp',
                  width: 245,
                  height: 162,
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 327,
                  child: Column(
                    children: [
                      Text(
                        l.listingSubmitted,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l.submittedForApprovalLong,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                          color: _grey,
                        ),
                      ),
                    ],
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
                      SvgPicture.asset(
                        'assets/icons/m_realestate_clock.svg',
                        width: 24,
                        height: 24,
                      ),
                      const SizedBox(width: 12),
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
                                color: _ink,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l.listingBeingReviewed,
                              style: TextStyle(
                                fontFamily: AppFonts.inter,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: _grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        // Footer note, kept above the button as drawn, with the page's name
        // picked out in mid blue.
        Padding(
          padding: const EdgeInsets.fromLTRB(33, 0, 33, 33),
          child: _footerNote(l),
        ),
      ],
    );
  }

  Widget _footerNote(L l) {
    final base = TextStyle(
      fontFamily: AppFonts.inter,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.4,
      color: _grey,
    );
    final text = l.checkStatusAnytimeLong;
    final at = text.indexOf(l.myApartments);
    if (at < 0) {
      return Text(text, textAlign: TextAlign.center, style: base);
    }
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: text.substring(0, at)),
          TextSpan(
            text: l.myApartments,
            style: base.copyWith(fontWeight: FontWeight.w500, color: _mid),
          ),
          TextSpan(text: text.substring(at + l.myApartments.length)),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

// ═══════════════════════════════════════════════════
// Bottom bar button
// ═══════════════════════════════════════════════════

/// The 44px mid-blue pill in the bottom bar, with the forward arrow on the
/// steps that lead on (turned round for right-to-left).
class _BottomButton extends StatelessWidget {
  final String label;
  final bool arrow;
  final bool loading;
  final VoidCallback? onTap;

  const _BottomButton({
    required this.label,
    required this.arrow,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: _mid,
          borderRadius: BorderRadius.circular(60),
        ),
        child: loading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 24 / 14,
                      color: Colors.white,
                    ),
                  ),
                  if (arrow) ...[
                    const SizedBox(width: 12),
                    Transform.flip(
                      flipX: rtl,
                      child: SvgPicture.asset(
                        'assets/icons/m_realestate_arrow_next.svg',
                        width: 20,
                        height: 20,
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Step progress bar (with checkmark for completed)
// ═══════════════════════════════════════════════════

/// The amenities that have somewhere to be stored. Each one is a boolean
/// column on `listings`, so a chip that is on becomes a value that is kept.
/// Elevator, balcony and parking carry the design's icons; storage and the
/// protected room are not in the design, so they keep a matching line icon.
enum _Amenity {
  elevator(svg: 'assets/icons/m_realestate_amenity_elevator.svg'),
  balcony(svg: 'assets/icons/m_realestate_amenity_balcony.svg'),
  parking(svg: 'assets/icons/m_realestate_amenity_parking.svg'),
  storage(icon: IconsaxPlusLinear.box_1),
  mamad(icon: IconsaxPlusLinear.shield_tick);

  const _Amenity({this.svg, this.icon});
  final String? svg;
  final IconData? icon;
}

class _StepProgressBar extends StatelessWidget {
  final int currentStep;
  final List<String> labels;

  /// Going back to a step already done, which the design draws as a link.
  final ValueChanged<int> onStepTap;

  const _StepProgressBar({
    required this.currentStep,
    required this.labels,
    required this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    // The frames draw the line to "Details" in mid blue from the first step
    // on; the line to "Photos" turns blue once the photographs are reached.
    final second = currentStep >= 2 ? _mid : _hairline;
    return SizedBox(
      width: 268,
      height: 47,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Connecting line
          PositionedDirectional(
            start: 40,
            top: 11,
            child: Container(
              width: 186,
              height: 2,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                gradient: LinearGradient(
                  begin: AlignmentDirectional.centerStart,
                  end: AlignmentDirectional.centerEnd,
                  colors: [_mid, _mid, second, second],
                  stops: const [0.0, 0.52, 0.58, 1.0],
                ),
              ),
            ),
          ),

          // Step circles + labels
          for (int i = 0; i < labels.length; i++)
            PositionedDirectional(
              start: i * 106.0,
              top: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: i < currentStep ? () => onStepTap(i) : null,
                child: SizedBox(
                  width: 56,
                  child: Column(
                    children: [
                      // A white ring outside each circle, so the line stops
                      // short of it as drawn.
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: i <= currentStep
                              ? _mid
                              : const Color(0xFFF6F6F6),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                            strokeAlign: BorderSide.strokeAlignOutside,
                          ),
                        ),
                        child: Center(
                          child: i < currentStep
                              // Completed: the design's ticked circle, which
                              // carries its own ring and so is 32 across.
                              ? OverflowBox(
                                  maxWidth: 32,
                                  maxHeight: 32,
                                  child: SvgPicture.asset(
                                    'assets/icons/m_realestate_step_done.svg',
                                    width: 32,
                                    height: 32,
                                  ),
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
                                        : _grey,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Label — centred under its circle even where it is
                      // wider than the 56 the circle's column is drawn at.
                      SizedBox(
                        height: 15,
                        child: OverflowBox(
                          maxWidth: 106,
                          child: Text(
                            labels[i],
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: i <= currentStep ? _mid : _grey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _hairline),
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
              color: _ink,
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
  final String svg;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.svg,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? _mid : _grey;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEEF4FD) : Colors.white,
          border: Border.all(
            color: selected ? _mid.withValues(alpha: 0.8) : _hairline,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              svg,
              width: 14,
              height: 14,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
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
  final _Amenity amenity;
  final bool selected;
  final VoidCallback onTap;

  const _AmenityChip({
    required this.label,
    required this.amenity,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? _mid : _grey;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEEF4FD) : Colors.white,
          border: Border.all(
            color: selected ? _mid.withValues(alpha: 0.8) : _hairline,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: Center(
                child: amenity.svg != null
                    ? SvgPicture.asset(
                        amenity.svg!,
                        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                      )
                    : Icon(amenity.icon, size: 16, color: color),
              ),
            ),
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
    // A dense drop-down is still 24 tall; the design's line is 20, as tall
    // as the arrow, so the button is let overhang by two either side rather
    // than making every card four taller than drawn.
    return SizedBox(
      height: 20,
      child: OverflowBox(
        maxHeight: 24,
        child: _button(),
      ),
    );
  }

  Widget _button() {
    return DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: items.any((i) => i.value == value) ? value : null,
        isExpanded: true,
        isDense: true,
        hint: Text(
          placeholder,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: _grey,
          ),
        ),
        icon: SvgPicture.asset(
          'assets/icons/m_account_chevron.svg',
          width: 20,
          height: 20,
        ),
        style: TextStyle(
          fontFamily: AppFonts.inter,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: _ink,
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

  /// A unit shown at the end of the line, such as m² beside the area.
  final String? suffix;

  const _InputRow({
    required this.placeholder,
    required this.controller,
    this.keyboardType,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final hint = TextStyle(
      fontFamily: AppFonts.inter,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: _grey,
    );
    return SizedBox(
      height: 20,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: _ink,
              ),
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: hint,
                // The theme fills inputs grey and rounds them; these sit
                // inside the white bordered cards.
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          if (suffix != null) Text(suffix!, style: hint),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Dashed border painter
// ═══════════════════════════════════════════════════

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _grey
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
