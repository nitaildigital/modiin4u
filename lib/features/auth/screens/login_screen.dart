import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _looksLikeEmail {
    final v = _emailController.text.trim();
    return v.contains('@') && v.contains('.') && v.length > 4;
  }

  Future<void> _signIn() async {
    final l = L.of(context);
    if (!_looksLikeEmail) {
      _showError(l.errEnterEmail);
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showError(l.errEnterPassword);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref
          .read(authProvider.notifier)
          .signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );
      if (!mounted) return;
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(_readable(e));
    }
  }

  /// Sends the reset email, and says so whether or not the address has an
  /// account — telling a stranger which addresses are registered is a way of
  /// finding out who uses the app.
  Future<void> _forgotPassword() async {
    final l = L.of(context);
    if (!_looksLikeEmail) {
      _showError(l.errEnterEmailFirst);
      return;
    }
    try {
      await ref
          .read(authProvider.notifier)
          .sendPasswordReset(_emailController.text);
    } catch (_) {
      // Reported the same either way, for the reason above.
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l.resetLinkSent,
          style: TextStyle(fontFamily: AppFonts.inter),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Supabase phrases its errors for developers; these are the ones a resident
  /// can actually hit.
  String _readable(Object e) {
    final raw = e is AuthException ? e.message : e.toString();
    final lower = raw.toLowerCase();
    final l = L.of(context);
    if (lower.contains('invalid login') || lower.contains('credentials')) {
      return l.errWrongCredentials;
    }
    if (lower.contains('not confirmed') || lower.contains('confirm')) {
      return l.errEmailNotConfirmed;
    }
    if (lower.contains('rate') || lower.contains('too many')) {
      return l.errTooMany;
    }
    if (lower.contains('socket') || lower.contains('network')) {
      return l.errNoConnection;
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
    final l = L.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      // The screen is drawn for a phone. On a desktop browser, without this,
      // the fields stretch the whole window.
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
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
                            l.welcomeBack,
                            style: TextStyle(
                              fontFamily: AppFonts.rubik,
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
                            l.signInSubtitle,
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF6D6D6D),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _buildTextField(
                            label: l.email,
                            controller: _emailController,
                            hint: l.emailHint,
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _buildTextField(
                            label: l.password,
                            controller: _passwordController,
                            hint: l.passwordHint,
                            isPassword: true,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Remember Me and Forgot Password, as the design has them.
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _rememberMe = !_rememberMe),
                                behavior: HitTestBehavior.opaque,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: _rememberMe
                                            ? AppColors.midBlue
                                            : Colors.white,
                                        border: Border.all(
                                          color: _rememberMe
                                              ? AppColors.midBlue
                                              : const Color(0xFF7B899A),
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: _rememberMe
                                          ? const Icon(
                                              Icons.check,
                                              size: 14,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 9),
                                    Text(
                                      l.rememberMe,
                                      style: TextStyle(
                                        fontFamily: AppFonts.inter,
                                        fontSize: 14,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: _isLoading ? null : _forgotPassword,
                                child: Text(
                                  l.forgotPassword,
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
                              onPressed: _isLoading ? null : _signIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.midBlue,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: AppColors.midBlue
                                    .withValues(alpha: 0.6),
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
                                      l.signIn,
                                      style: TextStyle(
                                        fontFamily: AppFonts.inter,
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
                                  l.noAccount,
                                  style: TextStyle(
                                    fontFamily: AppFonts.inter,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF3D3D3D),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l.signUp,
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
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.inter,
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
          obscureText: isPassword && _obscurePassword,
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1F1F1F),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6D6D6D),
            ),
            filled: true,
            fillColor: enabled ? Colors.white : const Color(0xFFF4F4F4),
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
            // The eye the design puts inside the password field.
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: const Color(0xFF6D6D6D),
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
