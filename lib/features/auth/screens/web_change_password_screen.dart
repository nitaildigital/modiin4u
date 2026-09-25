import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../providers/auth_provider.dart';

// ═══════════════════════════════════════════════════════════
// Web Change Password — desktop
//
// Three password fields and a button. The card stays at the width a form
// wants: a password field drawn across a 1600px column would be harder to
// use than the phone's, not easier. The width the page gains goes to the
// chrome around it — the navbar it had none of, and the footer.
// ═══════════════════════════════════════════════════════════

const _kBorder = Color(0xFFE7E7E7);
const _kFieldBorder = Color(0xFFC6C6C6);
const _kGreyText = Color(0xFF6D6D6D);
const _kHeading = Color(0xFF1C1C1E);
const _kLabel = Color(0xFF4F4F4F);

/// Wide enough for a label, a field and its eye toggle, and no wider.
const _kCardWidth = 520.0;

class WebChangePasswordContent extends ConsumerStatefulWidget {
  const WebChangePasswordContent({super.key});

  @override
  ConsumerState<WebChangePasswordContent> createState() =>
      _WebChangePasswordContentState();
}

class _WebChangePasswordContentState
    extends ConsumerState<WebChangePasswordContent> {
  bool _isHebrew = false;

  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _saving = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String _t(String en, String he) => _isHebrew ? he : en;

  /// The same call the phone screen makes. Supabase has no "check the old
  /// one" step of its own, so the provider verifies the current password by
  /// signing in with it first.
  Future<void> _submit() async {
    if (_currentController.text.isEmpty) {
      _toast(_t('Enter your password.', 'הזינו סיסמה.'), error: true);
      return;
    }
    if (_newController.text.length < 8) {
      _toast(
        _t(
          'The password must be at least 8 characters.',
          'הסיסמה חייבת להיות באורך 8 תווים לפחות.',
        ),
        error: true,
      );
      return;
    }
    if (_newController.text != _confirmController.text) {
      _toast(
        _t('The passwords do not match.', 'הסיסמאות אינן תואמות.'),
        error: true,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(authProvider.notifier)
          .changePassword(
            currentPassword: _currentController.text,
            newPassword: _newController.text,
          );
      if (!mounted) return;
      _toast(_t('Your password has been changed.', 'הסיסמה שלכם שונתה.'));
      _back();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      final wrong =
          e is AuthException && e.message.toLowerCase().contains('credentials');
      _toast(
        wrong
            ? _t(
                'That is not your current password.',
                'זו אינה הסיסמה הנוכחית שלכם.',
              )
            : _t('Could not save. Try again.', 'לא ניתן היה לשמור. נסו שוב.'),
        error: true,
      );
    }
  }

  /// A browser tab opened straight on /change-password has nothing to pop
  /// back to, so it falls back to the page the row lives on.
  void _back() => context.canPop() ? context.pop() : context.go('/settings');

  void _toast(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontFamily: AppFonts.inter)),
        backgroundColor: error ? AppColors.error : null,
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
                        child: SizedBox(
                          width: _kCardWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildBackLink(),
                              const SizedBox(height: 24),
                              _buildCard(),
                            ],
                          ),
                        ),
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
        onTap: _back,
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
              _t('Back to Settings', 'חזרה להגדרות'),
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
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.midBlue.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              IconsaxPlusLinear.lock_1,
              size: 32,
              color: AppColors.midBlue,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _t('Change Password', 'שינוי סיסמה'),
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
              'Choose a strong new password of at least 8 characters.',
              'בחרו סיסמה חדשה וחזקה, באורך 8 תווים לפחות.',
            ),
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              color: _kGreyText,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 32),
          _buildPasswordField(
            label: _t('Current Password', 'סיסמה נוכחית'),
            hint: _t('Enter your current password', 'הזינו את הסיסמה הנוכחית'),
            controller: _currentController,
            obscure: _obscureCurrent,
            onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
          ),
          const SizedBox(height: 20),
          _buildPasswordField(
            label: _t('New Password', 'סיסמה חדשה'),
            hint: _t('Enter a new password', 'הזינו סיסמה חדשה'),
            controller: _newController,
            obscure: _obscureNew,
            onToggle: () => setState(() => _obscureNew = !_obscureNew),
          ),
          const SizedBox(height: 20),
          _buildPasswordField(
            label: _t('Confirm New Password', 'אימות סיסמה חדשה'),
            hint: _t('Re-enter the new password', 'הזינו שוב את הסיסמה החדשה'),
            controller: _confirmController,
            obscure: _obscureConfirm,
            onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
            onSubmitted: true,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _submit,
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
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      _t('Change Password', 'שינוי סיסמה'),
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    bool onSubmitted = false,
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
          obscureText: obscure,
          // Enter on the last field submits, which is what a keyboard-first
          // visitor expects of a form this short.
          onSubmitted: onSubmitted && !_saving ? (_) => _submit() : null,
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
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: _kGreyText,
              ),
              onPressed: onToggle,
            ),
          ),
        ),
      ],
    );
  }
}
