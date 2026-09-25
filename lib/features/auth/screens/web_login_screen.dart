import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../providers/auth_provider.dart';

// ═══════════════════════════════════════════════════════════
// Web Login — desktop sign-in
//
// The phone screen puts the photograph under the form because that is the
// only place a 430px column has for it. On a laptop the two sit side by
// side: the card keeps the width a form wants, and the picture takes the
// room that was otherwise white.
// ═══════════════════════════════════════════════════════════

const _kBorder = Color(0xFFE7E7E7);
const _kFieldBorder = Color(0xFFC6C6C6);
const _kGreyText = Color(0xFF6D6D6D);
const _kHeading = Color(0xFF1C1C1E);
const _kLabel = Color(0xFF4F4F4F);

/// The tallest the split panel needs. The card below is shorter than this at
/// every width the page is drawn at, so nothing scrolls inside it.
const _kPanelHeight = 600.0;

class WebLoginContent extends ConsumerStatefulWidget {
  const WebLoginContent({super.key});

  @override
  ConsumerState<WebLoginContent> createState() => _WebLoginContentState();
}

class _WebLoginContentState extends ConsumerState<WebLoginContent> {
  bool _isHebrew = false;

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

  String _t(String en, String he) => _isHebrew ? he : en;

  bool get _looksLikeEmail {
    final v = _emailController.text.trim();
    return v.contains('@') && v.contains('.') && v.length > 4;
  }

  Future<void> _signIn() async {
    if (!_looksLikeEmail) {
      _showError(_t('Enter your email address.', 'הזינו כתובת אימייל.'));
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showError(_t('Enter your password.', 'הזינו סיסמה.'));
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
    if (!_looksLikeEmail) {
      _showError(
        _t('Enter your email address first.', 'הזינו קודם כתובת אימייל.'),
      );
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
    _showInfo(
      _t(
        'If that address has an account, a reset link is on its way.',
        'אם קיים חשבון לכתובת הזו, נשלח אליה קישור לאיפוס.',
      ),
    );
  }

  /// Supabase phrases its errors for developers; these are the ones a resident
  /// can actually hit.
  String _readable(Object e) {
    final raw = e is AuthException ? e.message : e.toString();
    final lower = raw.toLowerCase();
    if (lower.contains('invalid login') || lower.contains('credentials')) {
      return _t('Wrong email or password.', 'אימייל או סיסמה שגויים.');
    }
    if (lower.contains('not confirmed') || lower.contains('confirm')) {
      return _t(
        'Your email address has not been confirmed yet.',
        'כתובת האימייל שלכם עדיין לא אושרה.',
      );
    }
    if (lower.contains('rate') || lower.contains('too many')) {
      return _t(
        'Too many attempts. Try again in a few minutes.',
        'יותר מדי נסיונות. נסו שוב בעוד כמה דקות.',
      );
    }
    if (lower.contains('socket') || lower.contains('network')) {
      return _t('No connection.', 'אין חיבור לאינטרנט.');
    }
    return raw;
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
                    WebSection(child: _buildSplitPanel()),
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

  Widget _buildSplitPanel() {
    return SizedBox(
      height: _kPanelHeight,
      child: Row(
        children: [
          Expanded(
            child: Center(child: SizedBox(width: 480, child: _buildCard())),
          ),
          const SizedBox(width: 48),
          Expanded(child: _buildHero()),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Image.asset(
        'assets/images/hero_anaba.jpg',
        height: _kPanelHeight,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          height: _kPanelHeight,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(24),
          ),
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
            _t('Welcome Back', 'ברוכים הבאים בחזרה'),
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
              'Sign in to save places, follow the city and manage your listings.',
              'התחברו כדי לשמור מקומות, לעקוב אחרי העיר ולנהל את המודעות שלכם.',
            ),
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              color: _kGreyText,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 32),
          _buildTextField(
            label: _t('Email', 'אימייל'),
            controller: _emailController,
            hint: _t('Enter your email', 'הזינו את האימייל שלכם'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            label: _t('Password', 'סיסמה'),
            controller: _passwordController,
            hint: _t('Enter your password', 'הזינו סיסמה'),
            isPassword: true,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => setState(() => _rememberMe = !_rememberMe),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: _rememberMe ? AppColors.midBlue : Colors.white,
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
                        _t('Remember me', 'זכרו אותי'),
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _isLoading ? null : _forgotPassword,
                  child: Text(
                    _t('Forgot password?', 'שכחתם סיסמה?'),
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.midBlue,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _signIn,
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
                      _t('Sign In', 'התחברות'),
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                // A browser tab opened straight on /login has nothing to pop
                // back to, so this goes to the page rather than replacing a
                // history entry that may not exist.
                onTap: () => context.go('/signup'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _t("Don't have an account?", 'אין לכם חשבון?'),
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 14,
                        color: const Color(0xFF3D3D3D),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _t('Sign Up', 'הרשמה'),
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
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
            color: _kLabel,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: isPassword && _obscurePassword,
          onSubmitted: (_) => _isLoading ? null : _signIn(),
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
              color: _kGreyText,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
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
              borderSide: const BorderSide(
                color: AppColors.midBlue,
                width: 1.5,
              ),
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: _kGreyText,
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
