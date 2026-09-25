import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import 'web_reset_password_screen.dart';

/// Shown after someone follows the reset link in their email.
///
/// The link signs them in, so no old password is asked for — that is what
/// resetting one means. Without this screen the app would simply open as
/// though they had signed in normally, and the password they had forgotten
/// would still be the one on the account.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
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

  Future<void> _submit() async {
    final l = L.of(context);

    if (_password.text.length < 8) {
      _toast(l.errPasswordTooShort, error: true);
      return;
    }
    if (_password.text != _confirm.text) {
      _toast(l.errPasswordsDoNotMatch, error: true);
      return;
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(authProvider.notifier)
          .completePasswordReset(_password.text);
      if (!mounted) return;
      ref.read(passwordResetPendingProvider.notifier).state = false;
      _toast(l.passwordChanged);
      context.go('/');
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast(l.errCouldNotSave, error: true);
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
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) {
          return const WebResetPasswordContent();
        }
        return _buildMobile(context);
      },
    );
  }

  Widget _buildMobile(BuildContext context) {
    final l = L.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.midBlue.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      size: 32,
                      color: AppColors.midBlue,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l.newPassword,
                    style: TextStyle(
                      fontFamily: AppFonts.rubik,
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.chooseStrongPassword,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      color: const Color(0xFF6D6D6D),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _field(l.newPassword, _password),
                  const SizedBox(height: 20),
                  _field(l.confirmNewPassword, _confirm),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
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
                              l.changePassword,
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller) {
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
          obscureText: _obscure,
          style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14),
          decoration: InputDecoration(
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
            suffixIcon: IconButton(
              icon: Icon(
                _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: const Color(0xFF6D6D6D),
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
      ],
    );
  }
}
