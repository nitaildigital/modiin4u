import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/neighborhoods.dart';
import '../providers/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  String? _selectedNeighborhood;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider);
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _selectedNeighborhood = user?.neighborhood;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          title: Text('עריכת פרטים', style: GoogleFonts.rubik(fontWeight: FontWeight.w700)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: GestureDetector(
                  onTap: () {},
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: AppColors.cyanGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF00EEFF).withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6)),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            ref.watch(authProvider)?.initials ?? '?',
                            style: GoogleFonts.rubik(fontSize: 34, fontWeight: FontWeight.w700, color: AppColors.white),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.border, width: 2),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6)],
                          ),
                          child: const Icon(Icons.camera_alt_outlined, size: 16, color: AppColors.turquoise),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text('שנו תמונת פרופיל', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.turquoise, fontWeight: FontWeight.w500)),
              ),
              const SizedBox(height: 32),
              _buildField('שם מלא', _nameController, Icons.person_outline),
              const SizedBox(height: 20),
              _buildField('טלפון', _phoneController, Icons.phone_outlined, keyboardType: TextInputType.phone, textDirection: TextDirection.ltr),
              const SizedBox(height: 20),
              Text('שכונה', style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.grayMeta)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedNeighborhood,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.grayMeta, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  items: neighborhoods.map((n) {
                    return DropdownMenuItem(value: n.name, child: Text(n.displayName, style: GoogleFonts.rubik(fontSize: 14)));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedNeighborhood = val),
                ),
              ),
              const SizedBox(height: 36),
              GestureDetector(
                onTap: () {
                  ref.read(authProvider.notifier).updateProfile(
                    name: _nameController.text,
                    phone: _phoneController.text,
                    neighborhood: _selectedNeighborhood,
                  );
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: AppColors.white, size: 20),
                          const SizedBox(width: 10),
                          Text('הפרטים עודכנו בהצלחה', style: GoogleFonts.rubik()),
                        ],
                      ),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: AppColors.cyanGradient,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF00EEFF).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Center(
                    child: Text('שמירת שינויים', style: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.white)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: Text('ביטול', style: GoogleFonts.rubik(fontSize: 14, color: AppColors.grayMeta)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType, TextDirection? textDirection}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.grayMeta)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textDirection: textDirection,
          style: GoogleFonts.rubik(fontSize: 15),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceLight,
            prefixIcon: Icon(icon, color: AppColors.grayMeta, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.turquoise, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
