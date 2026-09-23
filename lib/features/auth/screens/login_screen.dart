import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;
import '../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();

  /// The screen is one page with two steps: ask for the address, then for the
  /// code that was sent to it.
  bool _codeSent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  bool get _looksLikeEmail {
    final v = _emailController.text.trim();
    return v.contains('@') && v.contains('.') && v.length > 4;
  }

  Future<void> _sendCode() async {
    if (!_looksLikeEmail) {
      _showError('Please enter your email address');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).sendCode(_emailController.text);
      if (!mounted) return;
      setState(() {
        _codeSent = true;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(_readable(e));
    }
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.trim().length < 6) {
      _showError('Please enter the 6-digit code');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).verifyCode(
        email: _emailController.text,
        code: _codeController.text,
      );
      if (!mounted) return;
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(_readable(e));
    }
  }

  /// Supabase phrases its errors for developers; these are the ones a resident
  /// can actually hit.
  String _readable(Object e) {
    final raw = e is AuthException ? e.message : e.toString();
    final lower = raw.toLowerCase();
    if (lower.contains('expired')) {
      return 'That code has expired. Send a new one.';
    }
    if (lower.contains('invalid') || lower.contains('token')) {
      return 'That code is not right. Check it and try again.';
    }
    if (lower.contains('rate') || lower.contains('too many')) {
      return 'Too many attempts. Wait a minute and try again.';
    }
    if (lower.contains('socket') || lower.contains('network')) {
      return 'No connection. Check your network and try again.';
    }
    return raw;
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
    // The photograph at the foot of the screen is 200px of decoration. With
    // the keyboard up that is exactly the room the button needs, so it stands
    // down while someone is typing.
    final keyboardUp = MediaQuery.of(context).viewInsets.bottom > 0;

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 34),
                    // Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Hi, Welcome Back! 👋',
                        style: TextStyle(fontFamily: AppFonts.rubik, 
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                          height: 1.21,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Subtitle
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        _codeSent
                            ? 'We sent a 6-digit code to ${_emailController.text.trim()}'
                            : 'Sign in with your email — we will send you a code.',
                        style: TextStyle(fontFamily: AppFonts.inter, 
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF6D6D6D),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Email field
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildTextField(
                        label: 'Email',
                        controller: _emailController,
                        hint: 'Enter your email',
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_codeSent,
                      ),
                    ),
                    if (_codeSent) ...[
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildTextField(
                          label: 'Code',
                          controller: _codeController,
                          hint: '6-digit code',
                          keyboardType: TextInputType.number,
                          autofocus: true,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    // Remember Me & Forgot Password
                    if (_codeSent)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: _isLoading
                                  ? null
                                  : () => setState(() {
                                      _codeSent = false;
                                      _codeController.clear();
                                    }),
                              child: Text(
                                'Use a different email',
                                style: TextStyle(
                                  fontFamily: AppFonts.inter,
                                  fontSize: 14,
                                  color: const Color(0xFF3D3D3D),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _isLoading ? null : _sendCode,
                              child: Text(
                                'Send again',
                                style: TextStyle(
                                  fontFamily: AppFonts.inter,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.midBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 40),
                    // Sign In button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : (_codeSent ? _verifyCode : _sendCode),
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
                                  _codeSent ? 'Sign In' : 'Send Code',
                                  style: TextStyle(fontFamily: AppFonts.inter, 
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Don't have an account? Sign Up
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          context.pop();
                          context.push('/signup');
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Don't have an account?",
                              style: TextStyle(fontFamily: AppFonts.inter, 
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF3D3D3D),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Sign Up',
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
            ),
            // Bottom decorative image
            if (!keyboardUp)
              ClipRRect(
                child: Image.asset(
                  'assets/images/hero_anaba.jpg',
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox(height: 200),
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
    bool enabled = true,
    bool autofocus = false,
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
          enabled: enabled,
          autofocus: autofocus,
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
            fillColor: enabled ? Colors.white : const Color(0xFFF4F4F4),
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
              borderSide: const BorderSide(color: AppColors.midBlue, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
