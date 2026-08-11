import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/neighborhoods.dart';
import '../../../shared/widgets/logo_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _otpController = TextEditingController();
  String? _selectedNeighborhood;
  bool _otpSent = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.4,
              decoration: const BoxDecoration(
                gradient: AppColors.brandGradient,
              ),
              child: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const LogoWidget(fontSize: 32),
                      const SizedBox(height: 8),
                      Text(
                        'הצטרפו לקהילת התושבים',
                        style: GoogleFonts.rubik(
                          fontSize: 15,
                          color: AppColors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              top: MediaQuery.of(context).size.height * 0.32,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                  child: _otpSent ? _buildOtpForm() : _buildRegistrationForm(),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  icon: const Icon(Icons.close, color: AppColors.white),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'הרשמה חינם לתושבי מודיעין',
          style: GoogleFonts.rubik(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'קבלו קופונים, התראות, שמרו מועדפים, וכתבו ביקורות',
          style: GoogleFonts.rubik(
            fontSize: 14,
            color: AppColors.grayText,
          ),
        ),
        const SizedBox(height: 24),
        _InputField(
          controller: _nameController,
          label: 'שם מלא',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 14),
        _InputField(
          controller: _phoneController,
          label: 'טלפון נייד',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          textDirection: TextDirection.ltr,
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: _selectedNeighborhood,
            decoration: InputDecoration(
              labelText: 'שכונה',
              labelStyle: GoogleFonts.rubik(color: AppColors.grayLight),
              prefixIcon: const Icon(
                Icons.location_on_outlined,
                color: AppColors.grayLight,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            items: neighborhoods.map((n) {
              return DropdownMenuItem(
                value: n.name,
                child: Text(
                  n.displayName,
                  style: GoogleFonts.rubik(fontSize: 14),
                ),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedNeighborhood = val),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            setState(() => _otpSent = true);
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text(
            'שלחו קוד אימות',
            style: GoogleFonts.rubik(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(child: Divider(color: AppColors.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'למה להירשם?',
                style: GoogleFonts.rubik(
                  fontSize: 13,
                  color: AppColors.grayLight,
                ),
              ),
            ),
            const Expanded(child: Divider(color: AppColors.border)),
          ],
        ),
        const SizedBox(height: 16),
        _BenefitRow(Icons.local_offer, 'קופונים והטבות בלעדיות מעסקים מקומיים'),
        const SizedBox(height: 10),
        _BenefitRow(Icons.notifications_active, 'התראות חדשות ומבצעים מותאמים לשכונה'),
        const SizedBox(height: 10),
        _BenefitRow(Icons.star, 'כתיבת ביקורות ודירוג עסקים'),
        const SizedBox(height: 10),
        _BenefitRow(Icons.favorite, 'שמירת עסקים מועדפים'),
        const SizedBox(height: 10),
        _BenefitRow(Icons.emoji_events, 'צבירת נקודות ופרסים על מעורבות'),
      ],
    );
  }

  Widget _buildOtpForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'הזינו את הקוד',
          style: GoogleFonts.rubik(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'שלחנו קוד אימות ב-SMS למספר ${_phoneController.text}',
          style: GoogleFonts.rubik(
            fontSize: 14,
            color: AppColors.grayText,
          ),
        ),
        const SizedBox(height: 24),
        _InputField(
          controller: _otpController,
          label: 'קוד אימות',
          icon: Icons.lock_outline,
          keyboardType: TextInputType.number,
          textDirection: TextDirection.ltr,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            context.go('/');
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text(
            'אישור והרשמה',
            style: GoogleFonts.rubik(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () {},
            child: Text(
              'שלחו קוד שוב',
              style: GoogleFonts.rubik(
                fontSize: 14,
                color: AppColors.turquoise,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _otpSent = false),
            child: Text(
              'חזרה',
              style: GoogleFonts.rubik(
                fontSize: 14,
                color: AppColors.grayLight,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextDirection? textDirection;

  const _InputField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.textDirection,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textDirection: textDirection,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.rubik(color: AppColors.grayLight),
        prefixIcon: Icon(icon, color: AppColors.grayLight),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.turquoise, width: 2),
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BenefitRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.turquoise.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.turquoise),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.rubik(
              fontSize: 13,
              color: AppColors.grayText,
            ),
          ),
        ),
      ],
    );
  }
}
