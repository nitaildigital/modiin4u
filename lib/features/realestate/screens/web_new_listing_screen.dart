import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../../auth/providers/auth_provider.dart';

// ═══════════════════════════════════════════════════════════
// Web New Listing — desktop layout for /new-listing
//
// The mobile screen is a single 430px column of stacked fields with the
// photographs on a horizontal strip in the middle of it. Here the fields sit
// two to a row in a 700px column and the photographs move into a panel beside
// them, where the whole set is visible at once instead of scrolled sideways.
//
// The behaviour is the mobile screen's, unchanged: the same fields, the same
// required-field check, and the same confirmation. This form is the older of
// the two listing forms — /add-apartment is the one that writes to `listings`.
// ═══════════════════════════════════════════════════════════

const _kBorder = Color(0xFFE7E7E7);
const _kLabel = Color(0xFF1F1F1F);
const _kGreyText = Color(0xFF5F5E5A);
const _kIconGrey = Color(0xFF6D6D6D);

class WebNewListingContent extends ConsumerStatefulWidget {
  const WebNewListingContent({super.key});

  @override
  ConsumerState<WebNewListingContent> createState() =>
      _WebNewListingContentState();
}

class _WebNewListingContentState extends ConsumerState<WebNewListingContent> {
  bool _isHebrew = false;

  int _listingType = 0;
  String? _propertyType;
  String? _neighborhood;
  final _priceController = TextEditingController();
  final _roomsController = TextEditingController();
  final _sqmController = TextEditingController();
  final _floorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _hasParking = false;
  bool _hasElevator = false;
  bool _hasMamad = false;
  bool _hasStorage = false;
  bool _hasBalcony = false;
  bool _isRenovated = false;
  final List<Uint8List> _images = [];

  /// The same eight neighbourhoods and six property types the mobile form
  /// offers. They are the form's own list, in Hebrew, with the English beside
  /// each one for the language this page can be read in.
  static const _neighborhoods = [
    ('Hanhalim', 'הנחלים'),
    ('Avnei Chen', 'אבני חן'),
    ('Nofim', 'נופים'),
    ('HaMaar', 'המע"ר'),
    ('HaKramim', 'הכרמים'),
    ('Moriah', 'מוריה'),
    ('HaPrachim', 'הפרחים'),
    ('Masua', 'משואה'),
  ];

  static const _propertyTypes = [
    ('Apartment', 'דירה'),
    ('Duplex', 'דופלקס'),
    ('Penthouse', 'פנטהאוז'),
    ('Garden Apartment', 'דירת גן'),
    ('Cottage', 'קוטג\''),
    ('Commercial', 'מסחרי'),
  ];

  @override
  void dispose() {
    _priceController.dispose();
    _roomsController.dispose();
    _sqmController.dispose();
    _floorController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _t(String en, String he) => _isHebrew ? he : en;

  /// The stored value is the Hebrew name, as the mobile form stores it; only
  /// the label beside it follows the language being read.
  String _optionLabel((String, String) option) =>
      _isHebrew ? option.$2 : option.$1;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);

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
                            _t('Post a Listing', 'העלאת מודעה'),
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
                              'Tell us about the property and how to reach you.',
                              'ספרו לנו על הנכס ואיך אפשר להשיג אתכם.',
                            ),
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 16,
                              color: _kIconGrey,
                            ),
                          ),
                          const SizedBox(height: 36),
                          // Signed out, there is nothing to fill in yet: the
                          // mobile form says so too rather than taking a
                          // listing it cannot attribute to anyone.
                          if (user == null)
                            _buildLoginPrompt()
                          else
                            _buildForm(),
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
            context.canPop() ? context.pop() : context.go('/realestate'),
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
              _t('Real Estate', 'נדל"ן'),
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

  // ─────────────────────────────────────────────
  // THE FORM — fields on one side, photographs on the other
  // ─────────────────────────────────────────────
  Widget _buildForm() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildFields()),
        const SizedBox(width: 40),
        SizedBox(width: 340, child: _buildPhotosPanel()),
      ],
    );
  }

  Widget _buildFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildTypePill(_t('For sale', 'למכירה'), 0)),
            const SizedBox(width: 12),
            Expanded(child: _buildTypePill(_t('For rent', 'להשכרה'), 1)),
          ],
        ),
        const SizedBox(height: 24),
        _fieldRow([
          _FieldCard(
            label: _t('Property Type', 'סוג נכס'),
            child: _Select(
              placeholder: _t('Select property type', 'בחרו סוג נכס'),
              value: _propertyType,
              items: _propertyTypes,
              label: _optionLabel,
              onChanged: (v) => setState(() => _propertyType = v),
            ),
          ),
          _FieldCard(
            label: _t('Neighborhood', 'שכונה'),
            child: _Select(
              placeholder: _t('Select a neighborhood', 'בחרו שכונה'),
              value: _neighborhood,
              items: _neighborhoods,
              label: _optionLabel,
              onChanged: (v) => setState(() => _neighborhood = v),
            ),
          ),
        ]),
        const SizedBox(height: 20),
        _fieldRow([
          _FieldCard(
            label: _t('Price (₪)', 'מחיר (₪)'),
            child: _TextRow(
              controller: _priceController,
              placeholder: _t('Price', 'מחיר'),
              keyboardType: TextInputType.number,
            ),
          ),
          _FieldCard(
            label: _t('Rooms', 'חדרים'),
            child: _TextRow(
              controller: _roomsController,
              placeholder: _t('Rooms', 'חדרים'),
              keyboardType: TextInputType.number,
            ),
          ),
        ]),
        const SizedBox(height: 20),
        _fieldRow([
          _FieldCard(
            label: _t('Area (m²)', 'שטח (מ"ר)'),
            child: _TextRow(
              controller: _sqmController,
              placeholder: _t('m²', 'מ"ר'),
              keyboardType: TextInputType.number,
            ),
          ),
          _FieldCard(
            label: _t('Floor', 'קומה'),
            child: _TextRow(
              controller: _floorController,
              placeholder: _t('Floor', 'קומה'),
              keyboardType: TextInputType.number,
            ),
          ),
        ]),
        const SizedBox(height: 20),
        _FieldCard(
          label: _t('Property Features', 'מאפייני הנכס'),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildFeatureChip(
                _t('Parking', 'חניה'),
                _hasParking,
                (v) => setState(() => _hasParking = v),
              ),
              _buildFeatureChip(
                _t('Elevator', 'מעלית'),
                _hasElevator,
                (v) => setState(() => _hasElevator = v),
              ),
              _buildFeatureChip(
                _t('Protected room', 'ממ"ד'),
                _hasMamad,
                (v) => setState(() => _hasMamad = v),
              ),
              _buildFeatureChip(
                _t('Storage', 'מחסן'),
                _hasStorage,
                (v) => setState(() => _hasStorage = v),
              ),
              _buildFeatureChip(
                _t('Balcony', 'מרפסת'),
                _hasBalcony,
                (v) => setState(() => _hasBalcony = v),
              ),
              _buildFeatureChip(
                _t('Renovated', 'משופץ'),
                _isRenovated,
                (v) => setState(() => _isRenovated = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _FieldCard(
          label: _t('Description', 'תיאור'),
          child: SizedBox(
            height: 130,
            child: TextField(
              controller: _descriptionController,
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
                  'Tell us about the property...',
                  'ספרו על הנכס...',
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
        _FieldCard(
          label: _t('Contact phone', 'טלפון ליצירת קשר'),
          child: _TextRow(
            controller: _phoneController,
            placeholder: '050-0000000',
            keyboardType: TextInputType.phone,
            // A telephone number reads left to right whichever way the page does.
            textDirection: TextDirection.ltr,
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            const Spacer(),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _submitListing,
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: AppColors.cyanGradient,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    _t('Publish Listing', 'פרסום מודעה'),
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypePill(String label, int index) {
    final isActive = _listingType == index;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _listingType = index),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: isActive ? AppColors.cyanGradient : null,
            color: isActive ? null : AppColors.inactiveTabBg,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : _kIconGrey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureChip(
    String label,
    bool selected,
    ValueChanged<bool> onChanged,
  ) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onChanged(!selected),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.turquoise.withValues(alpha: 0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: selected ? AppColors.turquoise : _kBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(Icons.check, size: 15, color: AppColors.turquoise),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  color: selected ? AppColors.turquoise : _kGreyText,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // THE PHOTOGRAPHS
  // ─────────────────────────────────────────────
  Widget _buildPhotosPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('Property Photos', 'תמונות הנכס'),
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
              'The first photo is the one the listing leads with.',
              'התמונה הראשונה היא זו שתוביל את המודעה.',
            ),
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 13,
              height: 1.4,
              color: _kGreyText,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 10.0;
              const perRow = 2;
              final tile = (constraints.maxWidth - gap * (perRow - 1)) / perRow;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (var i = 0; i < _images.length; i++)
                    SizedBox(
                      width: tile,
                      height: tile,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(_images[i], fit: BoxFit.cover),
                          ),
                          PositionedDirectional(
                            end: 6,
                            top: 6,
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _images.removeAt(i)),
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 15,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(
                    width: tile,
                    height: tile,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _kBorder),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 28,
                                color: AppColors.turquoise,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _t('Add', 'הוסיפו'),
                                style: TextStyle(
                                  fontFamily: AppFonts.inter,
                                  fontSize: 13,
                                  color: _kIconGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    for (final img in images) {
      final bytes = await img.readAsBytes();
      if (!mounted) return;
      setState(() => _images.add(bytes));
    }
  }

  // ─────────────────────────────────────────────
  // SIGNED OUT
  // ─────────────────────────────────────────────
  Widget _buildLoginPrompt() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 24),
      decoration: BoxDecoration(
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.lock_outline,
            size: 48,
            color: _kIconGrey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 20),
          Text(
            _t('Sign in to post a listing', 'יש להתחבר כדי לפרסם מודעה'),
            style: TextStyle(
              fontFamily: AppFonts.nunito,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => context.push('/login'),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 36),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.midBlue,
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Text(
                  _t('Sign in', 'התחברות'),
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
    );
  }

  // ─────────────────────────────────────────────
  // SUBMIT — the mobile screen's check and confirmation
  // ─────────────────────────────────────────────
  void _submitListing() {
    if (_priceController.text.isEmpty ||
        _neighborhood == null ||
        _propertyType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'Please fill in all the required fields',
              'יש למלא את כל השדות הנדרשים',
            ),
            style: TextStyle(fontFamily: AppFonts.inter),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: _isHebrew ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                _t('Listing published!', 'המודעה פורסמה!'),
                style: TextStyle(
                  fontFamily: AppFonts.nunito,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            _t(
              'Your listing was published and will appear in the property list shortly.',
              'המודעה שלך פורסמה בהצלחה ותופיע בקרוב ברשימת הנכסים.',
            ),
            style: TextStyle(fontFamily: AppFonts.inter, fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/realestate');
                }
              },
              child: Text(
                _t('OK', 'אישור'),
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  color: AppColors.turquoise,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Two fields on one line, each taking an equal share.
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

/// Narrower than [WebSection]'s 1600: a field 1600px wide is worse than one at
/// 430, and 1080 holds the 700px form and the photo panel beside it on a 1440
/// laptop as well as at 1920.
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
// FORM PARTS
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
        borderRadius: BorderRadius.circular(12),
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
  final TextDirection? textDirection;

  const _TextRow({
    required this.controller,
    required this.placeholder,
    this.keyboardType,
    this.textDirection,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textDirection: textDirection,
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

/// The form's dropdowns. The value stored is the Hebrew name the mobile form
/// stores; [label] decides only what is drawn.
class _Select extends StatelessWidget {
  final String placeholder;
  final String? value;
  final List<(String, String)> items;
  final String Function((String, String)) label;
  final ValueChanged<String?> onChanged;

  const _Select({
    required this.placeholder,
    required this.value,
    required this.items,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
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
          items: [
            for (final item in items)
              DropdownMenuItem(value: item.$2, child: Text(label(item))),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
