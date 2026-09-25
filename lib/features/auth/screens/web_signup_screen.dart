import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../../core/constants/neighborhoods.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../providers/auth_provider.dart';
import 'signup_screen.dart' show AccountType;

// ═══════════════════════════════════════════════════════════
// Web Sign-up — desktop registration
//
// Eleven controls in one 430px column is a long scroll. The same eleven sit
// in a 760px card here, paired across the width where two answers belong
// together — name and email, family status and pet and birthday — so the
// form is read in six rows rather than eleven.
// ═══════════════════════════════════════════════════════════

const _kBorder = Color(0xFFE7E7E7);
const _kFieldBorder = Color(0xFFC6C6C6);
const _kGreyText = Color(0xFF6D6D6D);
const _kHeading = Color(0xFF1C1C1E);
const _kLabel = Color(0xFF4F4F4F);

/// The gap between two fields sharing a row.
const _kFieldGap = 20.0;

class WebSignupContent extends ConsumerStatefulWidget {
  const WebSignupContent({super.key});

  @override
  ConsumerState<WebSignupContent> createState() => _WebSignupContentState();
}

class _WebSignupContentState extends ConsumerState<WebSignupContent> {
  bool _isHebrew = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  AccountType _accountType = AccountType.resident;
  String? _selectedNeighborhood;
  String? _familyStatus;
  bool? _hasPet;
  DateTime? _dateOfBirth;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreedToTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _t(String en, String he) => _isHebrew ? he : en;

  Future<void> _signUp() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty) {
      _showError(_t('Fill in the required fields.', 'מלאו את השדות הנדרשים.'));
      return;
    }
    if (_passwordController.text.length < 8) {
      _showError(
        _t(
          'The password needs at least 8 characters.',
          'הסיסמה צריכה להכיל 8 תווים לפחות.',
        ),
      );
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError(_t('The passwords do not match.', 'הסיסמאות אינן תואמות.'));
      return;
    }
    if (!_agreedToTerms) {
      _showError(
        _t(
          'Please agree to the terms to continue.',
          'יש לאשר את התנאים כדי להמשיך.',
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Everything the form collected travels with the account, so the
      // profile row the database creates already carries it.
      final signedIn = await ref
          .read(authProvider.notifier)
          .signUp(
            email: _emailController.text,
            password: _passwordController.text,
            data: {
              'full_name': _nameController.text.trim(),
              if (_phoneController.text.trim().isNotEmpty)
                'phone': _phoneController.text.trim(),
              'is_broker': _accountType == AccountType.broker,
            },
          );
      if (!mounted) return;

      // A project that asks for the address to be confirmed returns no
      // session, and saying "welcome" then would be wrong.
      if (!signedIn) {
        setState(() => _isLoading = false);
        await _showCheckEmail();
        if (mounted) context.go('/login');
        return;
      }

      // The rest of the answers need a session to write with, so they follow
      // the account rather than travelling with it.
      if (_selectedNeighborhood != null ||
          _familyStatus != null ||
          _hasPet != null ||
          _dateOfBirth != null) {
        await ref
            .read(authProvider.notifier)
            .updateProfile(
              neighborhood: _selectedNeighborhood,
              familyStatus: _familyStatus,
              hasPet: _hasPet,
              dateOfBirth: _dateOfBirth,
            );
      }
      if (!mounted) return;
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(e is AuthException ? e.message : e.toString());
    }
  }

  /// Explains what happened and offers to send the email again.
  ///
  /// Someone who loses the confirmation email is otherwise stuck: they cannot
  /// sign in, and signing up again with the same address is refused.
  Future<void> _showCheckEmail() {
    return showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: _isHebrew ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          title: Text(
            _t('Check your email', 'בדקו את האימייל'),
            style: TextStyle(
              fontFamily: AppFonts.nunito,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            _t(
              'Your account was created. Follow the link we sent to confirm '
                  'your address, then sign in.',
              'החשבון נוצר. עקבו אחרי הקישור ששלחנו לאישור הכתובת, ואז התחברו.',
            ),
            style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                try {
                  await ref
                      .read(authProvider.notifier)
                      .resendConfirmation(_emailController.text);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    _showInfo(
                      _t('Confirmation sent again.', 'האישור נשלח שוב.'),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    _showError(
                      e is AuthException
                          ? e.message
                          : _t(
                              'Too many attempts. Try again in a few minutes.',
                              'יותר מדי נסיונות. נסו שוב בעוד כמה דקות.',
                            ),
                    );
                  }
                }
              },
              child: Text(
                _t('Send it again', 'שלחו שוב'),
                style: TextStyle(fontFamily: AppFonts.inter),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                _t('Got it', 'הבנתי'),
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontFamily: AppFonts.inter)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontFamily: AppFonts.inter)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

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
              activeId: null,
              onToggleLanguage: () => setState(() => _isHebrew = !_isHebrew),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 56),
                    WebSection(
                      child: Center(
                        child: SizedBox(width: 760, child: _buildCard()),
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

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('Create Your Account', 'פתיחת חשבון'),
            style: TextStyle(
              fontFamily: AppFonts.nunito,
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: _kHeading,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _t(
              "Let's get you started. It only takes a minute.",
              'נתחיל. זה לוקח דקה.',
            ),
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              color: _kGreyText,
            ),
          ),
          const SizedBox(height: 32),

          // ── Account type ──
          Text(
            _t('Account Type', 'סוג חשבון'),
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _kLabel,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildAccountTypeCard(
                  type: AccountType.resident,
                  icon: Icons.person_outline,
                  iconColor: AppColors.turquoise,
                  title: _t('Resident', 'תושב'),
                  subtitle: _t('I live in Modiin.', 'אני גר במודיעין.'),
                ),
              ),
              const SizedBox(width: _kFieldGap),
              Expanded(
                child: _buildAccountTypeCard(
                  type: AccountType.broker,
                  icon: Icons.business_outlined,
                  iconColor: const Color(0xFFB0B0B0),
                  title: _t('Real Estate Broker', 'מתווך נדל"ן'),
                  subtitle: _t(
                    'I am a licensed real estate broker.',
                    'אני מתווך נדל"ן מוסמך.',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Who you are ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildTextField(
                  label: _t('Full Name', 'שם מלא'),
                  controller: _nameController,
                  hint: _t('Enter your full name', 'הזינו שם מלא'),
                ),
              ),
              const SizedBox(width: _kFieldGap),
              Expanded(
                child: _buildTextField(
                  label: _t('Email', 'אימייל'),
                  controller: _emailController,
                  hint: _t('Enter your email', 'הזינו אימייל'),
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildTextField(
                  label: _t('Phone', 'טלפון'),
                  controller: _phoneController,
                  hint: _t('Enter your phone', 'הזינו טלפון'),
                  keyboardType: TextInputType.phone,
                ),
              ),
              const SizedBox(width: _kFieldGap),
              Expanded(
                child: _buildDropdownField<String>(
                  label: _t('Neighborhood', 'שכונה'),
                  hint: _t('Select a neighborhood', 'בחרו שכונה'),
                  value: _selectedNeighborhood,
                  items: neighborhoods
                      .map(
                        (n) => DropdownMenuItem(
                          value: n.name,
                          child: Text(
                            n.displayName,
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _selectedNeighborhood = val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── The three short answers, across the width ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildDropdownField<String>(
                  label: _t('Family Status', 'מצב משפחתי'),
                  hint: _t('Select', 'בחרו'),
                  value: _familyStatus,
                  items:
                      [
                            ('single', _t('Single', 'יחיד')),
                            ('married', _t('Married', 'נשוי')),
                            ('family', _t('Family', 'משפחה')),
                          ]
                          .map(
                            (s) => DropdownMenuItem(
                              value: s.$1,
                              child: Text(
                                s.$2,
                                style: TextStyle(
                                  fontFamily: AppFonts.inter,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (val) => setState(() => _familyStatus = val),
                ),
              ),
              const SizedBox(width: _kFieldGap),
              Expanded(
                child: _buildDropdownField<bool>(
                  label: _t('Do you have a pet?', 'יש לכם חיית מחמד?'),
                  hint: _t('Select', 'בחרו'),
                  value: _hasPet,
                  items: [(true, _t('Yes', 'כן')), (false, _t('No', 'לא'))]
                      .map(
                        (s) => DropdownMenuItem(
                          value: s.$1,
                          child: Text(
                            s.$2,
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _hasPet = val),
                ),
              ),
              const SizedBox(width: _kFieldGap),
              Expanded(child: _buildDateField()),
            ],
          ),
          const SizedBox(height: 20),

          // ── The password, twice ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildTextField(
                  label: _t('Password', 'סיסמה'),
                  controller: _passwordController,
                  hint: _t('Choose a password', 'בחרו סיסמה'),
                  isPassword: true,
                  obscure: _obscurePassword,
                  onToggleObscure: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(width: _kFieldGap),
              Expanded(
                child: _buildTextField(
                  label: _t('Confirm Password', 'אימות סיסמה'),
                  controller: _confirmPasswordController,
                  hint: _t('Re-enter your password', 'הזינו את הסיסמה שוב'),
                  isPassword: true,
                  obscure: _obscureConfirm,
                  onToggleObscure: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildTermsRow(),
          const SizedBox(height: 32),
          Center(
            child: SizedBox(
              width: 320,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.midBlue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.midBlue.withValues(
                    alpha: 0.6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        _t('Sign Up', 'הרשמה'),
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => context.go('/login'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _t('Already have an account?', 'יש לכם כבר חשבון?'),
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 14,
                        color: const Color(0xFF3D3D3D),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _t('Sign In', 'התחברות'),
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.midBlue,
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

  Widget _buildTermsRow() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 18,
              height: 18,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: _agreedToTerms ? AppColors.midBlue : Colors.white,
                border: Border.all(
                  color: _agreedToTerms
                      ? AppColors.midBlue
                      : const Color(0xFF7B899A),
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: _agreedToTerms
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: _t('I agree to the ', 'אני מסכים ל'),
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 14,
                    color: Colors.black,
                    height: 1.4,
                  ),
                  children: [
                    TextSpan(
                      text: _t('Terms of Service', 'תנאי השימוש'),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => context.push('/terms'),
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.midBlue,
                      ),
                    ),
                    TextSpan(text: _t(' and ', ' ול')),
                    TextSpan(
                      text: _t('Privacy Policy', 'מדיניות הפרטיות'),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => context.push('/terms'),
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.midBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTypeCard({
    required AccountType type,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _accountType == type;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _accountType = type),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? AppColors.midBlue : _kBorder,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? iconColor.withValues(alpha: 0.15)
                      : const Color(0xFFF6F6F6),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3D3D3D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 12,
                        color: _kGreyText,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.midBlue
                        : const Color(0xFFD1D1D1),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.midBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
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
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontFamily: AppFonts.inter,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: _kGreyText,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kFieldBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kFieldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.midBlue, width: 1.5),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggleObscure,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: isPassword && obscure,
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1F1F1F),
          ),
          decoration: _fieldDecoration(hint).copyWith(
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: _kGreyText,
                    ),
                    onPressed: onToggleObscure,
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 20,
            color: _kGreyText,
          ),
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1F1F1F),
          ),
          decoration: _fieldDecoration(hint),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    final value = _dateOfBirth;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(_t('Date of Birth', 'תאריך לידה')),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime(2000),
                firstDate: DateTime(1930),
                lastDate: DateTime.now(),
              );
              if (date != null) setState(() => _dateOfBirth = date);
            },
            child: Container(
              width: double.infinity,
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: _kFieldBorder),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value != null
                          ? '${value.day}/${value.month}/${value.year}'
                          : _t('Select a date', 'בחרו תאריך'),
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: value != null
                            ? const Color(0xFF1F1F1F)
                            : _kGreyText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: _kGreyText,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
