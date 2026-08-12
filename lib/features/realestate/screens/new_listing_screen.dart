import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

class NewListingScreen extends ConsumerStatefulWidget {
  const NewListingScreen({super.key});

  @override
  ConsumerState<NewListingScreen> createState() => _NewListingScreenState();
}

class _NewListingScreenState extends ConsumerState<NewListingScreen> {
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

  final _neighborhoods = [
    'הנחלים', 'אבני חן', 'נופים', 'המע"ר', 'הכרמים', 'מוריה', 'הפרחים', 'משואה',
  ];

  final _propertyTypes = ['דירה', 'דופלקס', 'פנטהאוז', 'דירת גן', 'קוטג\'', 'מסחרי'];

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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('העלאת מודעה', style: GoogleFonts.rubik(fontWeight: FontWeight.w700)),
        ),
        body: user == null
            ? _buildLoginPrompt()
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTypeToggle(),
                    const SizedBox(height: 20),
                    _buildLabel('סוג נכס'),
                    _buildDropdown(
                      value: _propertyType,
                      hint: 'בחרו סוג נכס',
                      items: _propertyTypes,
                      onChanged: (v) => setState(() => _propertyType = v),
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('שכונה'),
                    _buildDropdown(
                      value: _neighborhood,
                      hint: 'בחרו שכונה',
                      items: _neighborhoods,
                      onChanged: (v) => setState(() => _neighborhood = v),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _buildLabel('מחיר (₪)'),
                          _buildTextField(_priceController, 'מחיר', TextInputType.number),
                        ])),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _buildLabel('חדרים'),
                          _buildTextField(_roomsController, 'חדרים', TextInputType.number),
                        ])),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _buildLabel('שטח (מ"ר)'),
                          _buildTextField(_sqmController, 'מ"ר', TextInputType.number),
                        ])),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _buildLabel('קומה'),
                          _buildTextField(_floorController, 'קומה', TextInputType.number),
                        ])),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('מאפייני הנכס'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildFeatureChip('חניה', _hasParking, (v) => setState(() => _hasParking = v)),
                        _buildFeatureChip('מעלית', _hasElevator, (v) => setState(() => _hasElevator = v)),
                        _buildFeatureChip('ממ"ד', _hasMamad, (v) => setState(() => _hasMamad = v)),
                        _buildFeatureChip('מחסן', _hasStorage, (v) => setState(() => _hasStorage = v)),
                        _buildFeatureChip('מרפסת', _hasBalcony, (v) => setState(() => _hasBalcony = v)),
                        _buildFeatureChip('משופץ', _isRenovated, (v) => setState(() => _isRenovated = v)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('תמונות הנכס'),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ..._images.asMap().entries.map((entry) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(entry.value, width: 100, height: 100, fit: BoxFit.cover),
                                ),
                                Positioned(
                                  top: 4, right: 4,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _images.removeAt(entry.key)),
                                    child: Container(
                                      width: 24, height: 24,
                                      decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                                      child: const Icon(Icons.close, size: 14, color: AppColors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                          GestureDetector(
                            onTap: _pickImages,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_photo_alternate_outlined, size: 28, color: AppColors.turquoise),
                                  const SizedBox(height: 4),
                                  Text('הוסיפו', style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayMeta)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('תיאור'),
                    TextField(
                      controller: _descriptionController,
                      textDirection: TextDirection.rtl,
                      maxLines: 4,
                      decoration: _inputDecoration('ספרו על הנכס...'),
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('טלפון ליצירת קשר'),
                    _buildTextField(_phoneController, '050-0000000', TextInputType.phone, textDirection: TextDirection.ltr),
                    const SizedBox(height: 28),
                    Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.cyanGradient,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: ElevatedButton(
                        onPressed: _submitListing,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                        ),
                        child: Text('פרסום מודעה', style: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.white)),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 48, color: AppColors.grayMeta.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('יש להתחבר כדי לפרסם מודעה', style: GoogleFonts.rubik(fontSize: 16, color: AppColors.grayMeta)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.push('/login'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14)),
              child: Text('התחברות', style: GoogleFonts.rubik(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Row(
      children: [
        Expanded(child: _buildTypePill('למכירה', 0)),
        const SizedBox(width: 8),
        Expanded(child: _buildTypePill('להשכרה', 1)),
      ],
    );
  }

  Widget _buildTypePill(String label, int index) {
    final isActive = _listingType == index;
    return GestureDetector(
      onTap: () => setState(() => _listingType = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isActive ? AppColors.cyanGradient : null,
          color: isActive ? null : AppColors.inactiveTabBg,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w600, color: isActive ? AppColors.white : AppColors.grayMeta),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.grayMeta)),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        hint: Text(hint, style: GoogleFonts.rubik(fontSize: 14, color: AppColors.grayLight)),
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: GoogleFonts.rubik(fontSize: 14)))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, TextInputType type, {TextDirection? textDirection}) {
    return TextField(
      controller: controller,
      keyboardType: type,
      textDirection: textDirection,
      decoration: _inputDecoration(hint),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.rubik(color: AppColors.grayLight),
      filled: true,
      fillColor: AppColors.surfaceLight,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.turquoise, width: 1.5)),
    );
  }

  Widget _buildFeatureChip(String label, bool selected, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!selected),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.turquoise.withValues(alpha: 0.1) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: selected ? AppColors.turquoise : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check, size: 14, color: AppColors.turquoise),
              const SizedBox(width: 4),
            ],
            Text(label, style: GoogleFonts.rubik(fontSize: 13, color: selected ? AppColors.turquoise : AppColors.grayText, fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(maxWidth: 1024, maxHeight: 1024, imageQuality: 80);
    for (final img in images) {
      final bytes = await img.readAsBytes();
      setState(() => _images.add(bytes));
    }
  }

  void _submitListing() {
    if (_priceController.text.isEmpty || _neighborhood == null || _propertyType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('יש למלא את כל השדות הנדרשים', style: GoogleFonts.rubik()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.success, size: 28),
              const SizedBox(width: 10),
              Text('המודעה פורסמה!', style: GoogleFonts.rubik(fontWeight: FontWeight.w700)),
            ],
          ),
          content: Text('המודעה שלך פורסמה בהצלחה ותופיע בקרוב ברשימת הנכסים.', style: GoogleFonts.rubik(fontSize: 14)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.pop();
              },
              child: Text('אישור', style: GoogleFonts.rubik(color: AppColors.turquoise, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
