import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/neighborhoods.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _otpControllers = List.generate(4, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(4, (_) => FocusNode());
  String? _selectedNeighborhood;
  bool _otpSent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.brandGradient),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.white),
                        onPressed: () => context.pop(),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: bottomInset > 0 ? 40 : 80,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (bottomInset == 0) ...[
                        Text(
                          'מודיעין בשבילך',
                          style: GoogleFonts.rubik(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.white),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'הצטרפו לקהילת התושבים',
                          style: GoogleFonts.rubik(fontSize: 15, color: AppColors.white.withValues(alpha: 0.8)),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _otpSent ? _buildOtpStep() : _buildRegistrationStep(),
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

  Widget _buildRegistrationStep() {
    return Column(
      key: const ValueKey('register'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'הרשמה חינם',
          style: GoogleFonts.rubik(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.navy),
        ),
        const SizedBox(height: 6),
        Text(
          'קבלו קופונים, התראות, שמרו מועדפים, וכתבו ביקורות',
          style: GoogleFonts.rubik(fontSize: 14, color: AppColors.grayMeta, height: 1.4),
        ),
        const SizedBox(height: 28),
        _buildInputField(
          controller: _nameController,
          icon: Icons.person_outline,
          label: 'שם מלא',
          hint: 'איך קוראים לכם?',
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _phoneController,
          icon: Icons.phone_outlined,
          label: 'טלפון נייד',
          hint: '050-0000000',
          keyboardType: TextInputType.phone,
          textDirection: TextDirection.ltr,
        ),
        const SizedBox(height: 16),
        Text('שכונה', style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.grayMeta)),
        const SizedBox(height: 6),
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
            hint: Text('בחרו שכונה (אופציונלי)', style: GoogleFonts.rubik(fontSize: 14, color: AppColors.grayLight)),
            items: neighborhoods.map((n) {
              return DropdownMenuItem(value: n.name, child: Text(n.displayName, style: GoogleFonts.rubik(fontSize: 14)));
            }).toList(),
            onChanged: (val) => setState(() => _selectedNeighborhood = val),
          ),
        ),
        const SizedBox(height: 28),
        _buildGradientButton('שלחו קוד אימות', () {
          if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
            _showError('יש למלא שם וטלפון');
            return;
          }
          setState(() {
            _isLoading = true;
          });
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) setState(() { _isLoading = false; _otpSent = true; });
          });
        }),
        const SizedBox(height: 24),
        Row(
          children: [
            const Expanded(child: Divider(color: AppColors.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('או התחברו עם', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayLight)),
            ),
            const Expanded(child: Divider(color: AppColors.border)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildSocialButton('Google', Icons.g_mobiledata, const Color(0xFFEA4335))),
            const SizedBox(width: 12),
            Expanded(child: _buildSocialButton('Apple', Icons.apple, AppColors.navy)),
          ],
        ),
        const SizedBox(height: 32),
        _buildBenefitsSection(),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      key: const ValueKey('otp'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.turquoise.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sms_outlined, size: 32, color: AppColors.turquoise),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            'הזינו את הקוד',
            style: GoogleFonts.rubik(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.navy),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'שלחנו קוד אימות ב-SMS למספר',
            style: GoogleFonts.rubik(fontSize: 14, color: AppColors.grayMeta),
          ),
        ),
        Center(
          child: Text(
            _phoneController.text,
            style: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.navy),
            textDirection: TextDirection.ltr,
          ),
        ),
        const SizedBox(height: 32),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              return Container(
                width: 60,
                height: 64,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                child: TextField(
                  controller: _otpControllers[index],
                  focusNode: _otpFocusNodes[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  style: GoogleFonts.rubik(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.navy),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.turquoise, width: 2),
                    ),
                  ),
                  onChanged: (val) {
                    if (val.isNotEmpty && index < 3) {
                      _otpFocusNodes[index + 1].requestFocus();
                    } else if (val.isEmpty && index > 0) {
                      _otpFocusNodes[index - 1].requestFocus();
                    }
                    if (index == 3 && val.isNotEmpty) {
                      FocusScope.of(context).unfocus();
                    }
                  },
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 32),
        _buildGradientButton('אישור והרשמה', () {
          setState(() => _isLoading = true);
          Future.delayed(const Duration(milliseconds: 600), () {
            ref.read(authProvider.notifier).login(
              name: _nameController.text,
              phone: _phoneController.text,
              neighborhood: _selectedNeighborhood,
            );
            context.go('/');
          });
        }),
        const SizedBox(height: 20),
        Center(
          child: TextButton(
            onPressed: () {},
            child: Text.rich(
              TextSpan(
                text: 'לא קיבלתם? ',
                style: GoogleFonts.rubik(fontSize: 14, color: AppColors.grayMeta),
                children: [
                  TextSpan(
                    text: 'שלחו שוב',
                    style: GoogleFonts.rubik(fontSize: 14, color: AppColors.turquoise, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _otpSent = false),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.grayMeta),
                const SizedBox(width: 4),
                Text('חזרה', style: GoogleFonts.rubik(fontSize: 14, color: AppColors.grayMeta)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    TextDirection? textDirection,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.grayMeta)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textDirection: textDirection,
          style: GoogleFonts.rubik(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.rubik(color: AppColors.grayLight),
            filled: true,
            fillColor: AppColors.surfaceLight,
            prefixIcon: Icon(icon, color: AppColors.grayMeta, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.turquoise, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildGradientButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: AppColors.cyanGradient,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(color: const Color(0xFF00EEFF).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2.5))
              : Text(label, style: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.white)),
        ),
      ),
    );
  }

  Widget _buildSocialButton(String label, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.navy)),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitsSection() {
    final benefits = [
      (Icons.local_offer, 'קופונים והטבות', 'הנחות בלעדיות מעסקים מקומיים'),
      (Icons.notifications_active, 'התראות חכמות', 'עדכונים מותאמים לשכונה שלכם'),
      (Icons.favorite, 'שמירת מועדפים', 'עסקים, נכסים ואירועים במקום אחד'),
      (Icons.emoji_events, 'נקודות ופרסים', 'צברו נקודות על מעורבות בקהילה'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('למה להירשם?', style: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navy)),
        const SizedBox(height: 14),
        ...benefits.map((b) {
          final (icon, title, subtitle) = b;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.cyanGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: AppColors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy)),
                      Text(subtitle, style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayMeta)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.rubik()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
