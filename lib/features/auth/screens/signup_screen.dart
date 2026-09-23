import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/neighborhoods.dart';
import '../providers/auth_provider.dart';

enum AccountType { resident, broker }

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  AccountType _accountType = AccountType.resident;
  String? _selectedNeighborhood;
  String? _familyStatus;
  String? _hasPet;
  DateTime? _dateOfBirth;
  bool _agreedToTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty) {
      _showError('Please fill in required fields');
      return;
    }
    if (!_agreedToTerms) {
      _showError('Please agree to the Terms of Service');
      return;
    }
    setState(() => _isLoading = true);
    try {
      // The name travels with the account, so the profile row the database
      // creates already carries it rather than the part before the @.
      await ref.read(authProvider.notifier).sendCode(
        _emailController.text,
        data: {
          'full_name': _nameController.text.trim(),
          if (_phoneController.text.trim().isNotEmpty)
            'phone': _phoneController.text.trim(),
        },
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      await _askForCode();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(e is AuthException ? e.message : e.toString());
    }
  }

  /// The code arrives by email, so it is asked for here rather than on another
  /// screen — everything they typed is still in front of them.
  Future<void> _askForCode() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CodeSheet(email: _emailController.text.trim()),
    );
    if (ok != true || !mounted) return;

    // Anything the account metadata does not carry is saved once the session
    // exists, because until then there is no row to write to.
    await ref.read(authProvider.notifier).updateProfile(
      neighborhood: _selectedNeighborhood,
    );
    if (!mounted) return;
    context.go('/');
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with back button
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const SizedBox(
                      width: 24,
                      height: 24,
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        size: 16,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 34),
                    // Title
                    Text(
                      'Create Your Account',
                      style: TextStyle(fontFamily: AppFonts.rubik, 
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        height: 1.21,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Subtitle
                    Text(
                      "Let's get you started. It only takes a minute.",
                      style: TextStyle(fontFamily: AppFonts.inter, 
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6D6D6D),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Account Type
                    Text(
                      'Account Type',
                      style: TextStyle(fontFamily: AppFonts.inter, 
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF4F4F4F),
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
                            title: 'Resident',
                            subtitle:
                                'For residents and community members.',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildAccountTypeCard(
                            type: AccountType.broker,
                            icon: Icons.business_outlined,
                            iconColor: const Color(0xFFB0B0B0),
                            title: 'Business',
                            subtitle:
                                'I am a licensed real estate broker.',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Form fields
                    _buildTextField(
                      label: 'Full Name',
                      controller: _nameController,
                      hint: 'Enter your full name',
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      label: 'Email',
                      controller: _emailController,
                      hint: 'Enter your email',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      label: 'Phone',
                      controller: _phoneController,
                      hint: 'Enter your phone number',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 20),
                    // Neighborhood dropdown
                    _buildDropdownField(
                      label: 'Neighborhood',
                      hint: 'Select your neighborhood',
                      value: _selectedNeighborhood,
                      items: neighborhoods
                          .map((n) => DropdownMenuItem(
                              value: n.name,
                              child: Text(n.displayName,
                                  style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14))))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedNeighborhood = val),
                    ),
                    const SizedBox(height: 20),
                    // Family Status & Pet (side by side)
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdownField(
                            label: 'Family Status',
                            hint: 'Select',
                            value: _familyStatus,
                            items: ['Single', 'Married', 'Family']
                                .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s,
                                        style:
                                            TextStyle(fontFamily: AppFonts.inter, fontSize: 14))))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _familyStatus = val),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildDropdownField(
                            label: 'Do you have a pet?',
                            hint: 'Select',
                            value: _hasPet,
                            items: ['Yes', 'No']
                                .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s,
                                        style:
                                            TextStyle(fontFamily: AppFonts.inter, fontSize: 14))))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _hasPet = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Date of Birth
                    _buildDateField(
                      label: 'Date of Birth',
                      hint: 'Select your date of birth',
                      value: _dateOfBirth,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime(2000),
                          firstDate: DateTime(1930),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _dateOfBirth = date);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    // Terms checkbox
                    GestureDetector(
                      onTap: () =>
                          setState(() => _agreedToTerms = !_agreedToTerms),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              color: _agreedToTerms
                                  ? AppColors.midBlue
                                  : Colors.white,
                              border: Border.all(
                                color: _agreedToTerms
                                    ? AppColors.midBlue
                                    : const Color(0xFF7B899A),
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: _agreedToTerms
                                ? const Icon(Icons.check,
                                    size: 14, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                text: 'I agree to the ',
                                style: TextStyle(fontFamily: AppFonts.inter, 
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black,
                                  height: 1.4,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Terms of Service',
                                    style: TextStyle(fontFamily: AppFonts.inter, 
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.midBlue,
                                    ),
                                  ),
                                  const TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: TextStyle(fontFamily: AppFonts.inter, 
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
                    const SizedBox(height: 32),
                    // Sign Up button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.midBlue,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              AppColors.midBlue.withValues(alpha: 0.6),
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
                                'Sign Up',
                                style: TextStyle(fontFamily: AppFonts.inter, 
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Already have an account? Sign In
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          context.pop();
                          context.push('/login');
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Already have an account?',
                              style: TextStyle(fontFamily: AppFonts.inter, 
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF3D3D3D),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Sign In',
                              style: TextStyle(fontFamily: AppFonts.inter, 
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.midBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
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
    return GestureDetector(
      onTap: () => setState(() => _accountType = type),
      child: Container(
        padding: const EdgeInsets.all(12),
        height: 127,
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.midBlue : const Color(0xFFE7E7E7),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? iconColor.withValues(alpha: 0.15)
                        : const Color(0xFFF6F6F6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                // Radio button
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
            const Spacer(),
            Text(
              title,
              style: TextStyle(fontFamily: AppFonts.inter, 
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3D3D3D),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: TextStyle(fontFamily: AppFonts.inter, 
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6D6D6D),
                height: 1.25,
              ),
            ),
          ],
        ),
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
        Text(
          label,
          style: TextStyle(fontFamily: AppFonts.inter, 
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF4F4F4F),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: isPassword && obscure,
          style: TextStyle(fontFamily: AppFonts.inter, 
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1F1F1F),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontFamily: AppFonts.inter, 
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6D6D6D),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFC6C6C6)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFC6C6C6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.midBlue, width: 1.5),
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: const Color(0xFF6D6D6D),
                    ),
                    onPressed: onToggleObscure,
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontFamily: AppFonts.inter, 
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF4F4F4F),
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: value,
          items: items,
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down,
              size: 20, color: Color(0xFF6D6D6D)),
          style: TextStyle(fontFamily: AppFonts.inter, 
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1F1F1F),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontFamily: AppFonts.inter, 
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6D6D6D),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFC6C6C6)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFC6C6C6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.midBlue, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required String hint,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontFamily: AppFonts.inter, 
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF4F4F4F),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFC6C6C6)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value != null
                      ? '${value.day}/${value.month}/${value.year}'
                      : hint,
                  style: TextStyle(fontFamily: AppFonts.inter, 
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: value != null
                        ? const Color(0xFF1F1F1F)
                        : const Color(0xFF6D6D6D),
                  ),
                ),
                const Icon(Icons.calendar_today_outlined,
                    size: 20, color: Color(0xFF6D6D6D)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Asks for the 6-digit code and verifies it. Pops true once a session exists.
class _CodeSheet extends ConsumerStatefulWidget {
  final String email;
  const _CodeSheet({required this.email});

  @override
  ConsumerState<_CodeSheet> createState() => _CodeSheetState();
}

class _CodeSheetState extends ConsumerState<_CodeSheet> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_controller.text.trim().length < 6) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).verifyCode(
        email: widget.email,
        code: _controller.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e is AuthException ? e.message : 'That code is not right.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Check your email',
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'We sent a 6-digit code to ${widget.email}',
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              color: const Color(0xFF6D6D6D),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16),
            decoration: InputDecoration(
              hintText: '6-digit code',
              errorText: _error,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 13,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFC6C6C6)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFC6C6C6)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.midBlue,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _busy ? null : _verify,
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
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      'Confirm',
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
