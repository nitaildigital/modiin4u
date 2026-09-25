import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../providers/auth_provider.dart';

// ═══════════════════════════════════════════════════════════
// Web Reset Password — desktop
//
// Where the reset link in the email lands, and on a laptop that link opens a
// browser rather than the app — so this is the version most people will
// actually see. Two fields in a card the width of a form, with the site's
// own navbar and footer around it, so the page looks like the site it
// belongs to rather than a bare column.
//
// There is no "current password" field and no back link: the link signed
// them in, and the password they forgot is the one being replaced.
// ═══════════════════════════════════════════════════════════

const _kBorder = Color(0xFFE7E7E7);
const _kFieldBorder = Color(0xFFC6C6C6);
const _kGreyText = Color(0xFF6D6D6D);
const _kHeading = Color(0xFF1C1C1E);
const _kLabel = Color(0xFF4F4F4F);

const _kCardWidth = 520.0;

class WebResetPasswordContent extends ConsumerStatefulWidget {
  const WebResetPasswordContent({super.key});

  @override
  ConsumerState<WebResetPasswordContent> createState() =>
      _WebResetPasswordContentState();
}

class _WebResetPasswordContentState
    extends ConsumerState<WebResetPasswordContent> {
  bool _isHebrew = false;

  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _saving = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String _t(String en, String he) => _isHebrew ? he : en;

  Future<void> _submit() async {
    if (_password.text.length < 8) {
      _toast(
        _t(
          'The password must be at least 8 characters.',
          'הסיסמה חייבת להיות באורך 8 תווים לפחות.',
        ),
        error: true,
      );
      return;
    }
    if (_password.text != _confirm.text) {
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
          .completePasswordReset(_password.text);
      if (!mounted) return;
      ref.read(passwordResetPendingProvider.notifier).state = false;
      _toast(_t('Your password has been changed.', 'הסיסמה שלכם שונתה.'));
      context.go('/');
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast(
        _t('Could not save. Try again.', 'לא ניתן היה לשמור. נסו שוב.'),
        error: true,
      );
    }
  }

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
                          child: _buildCard(),
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
            _t('New Password', 'סיסמה חדשה'),
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
              'Choose a strong password of at least 8 characters.',
              'בחרו סיסמה חזקה באורך 8 תווים לפחות.',
            ),
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              color: _kGreyText,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 32),
          _buildField(
            label: _t('New Password', 'סיסמה חדשה'),
            hint: _t('Enter a new password', 'הזינו סיסמה חדשה'),
            controller: _password,
          ),
          const SizedBox(height: 20),
          _buildField(
            label: _t('Confirm New Password', 'אימות סיסמה חדשה'),
            hint: _t('Re-enter the new password', 'הזינו שוב את הסיסמה החדשה'),
            controller: _confirm,
            submits: true,
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

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool submits = false,
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
          obscureText: _obscure,
          onSubmitted: submits && !_saving ? (_) => _submit() : null,
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
            // One toggle covers both fields, as it does on the phone: they
            // are meant to hold the same value.
            suffixIcon: IconButton(
              icon: Icon(
                _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: _kGreyText,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
      ],
    );
  }
}
