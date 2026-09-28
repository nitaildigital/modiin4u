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
  bool _isHebrew = webIsHebrew.value;

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
      _showError(_t('Enter your email address first', 'הזינו כתובת אימייל'));
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showError(_t('Enter your password.', 'הזינו סיסמה'));
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
      // Back to whatever sent us here, or home.
      final next = GoRouterState.of(context).uri.queryParameters['next'];
      context.go(next != null && next.startsWith('/') ? next : '/');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(_readable(e));
    }
  }

  /// Sends the reset email, and says so whether or not the address has an
  /// account — telling a stranger which addresses are registered is a way of
  /// finding out who uses the app.
  /// Asks for the address in a window of its own.
  ///
  /// It used to reuse whatever was in the sign-in field and report back
  /// through a SnackBar that never appeared on this page — so with the field
  /// empty, pressing it did nothing visible at all, and with an address in it
  /// the mail went out with no sign that it had. A person cannot be expected
  /// to guess either way.
  Future<void> _forgotPassword() async {
    await showDialog<void>(
      context: context,
      builder: (_) => _ForgotPasswordDialog(
        isHebrew: _isHebrew,
        initialEmail: _emailController.text.trim(),
        onSend: (email) =>
            ref.read(authProvider.notifier).sendPasswordReset(email),
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

  /// What went wrong, shown inside the card.
  ///
  /// This was a SnackBar, and on this page it never appeared: a wrong password
  /// failed in silence. A line in the card cannot be missed, does not time
  /// out, and sits where the person is already looking.
  String? _notice;

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _notice = message);
  }

  /// The line the above writes to.
  Widget _buildNotice() {
    final text = _notice;
    if (text == null) return const SizedBox.shrink();
    const colour = AppColors.error;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: colour.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colour.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, size: 18, color: colour),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 13,
                  height: 1.45,
                  color: colour,
                ),
              ),
            ),
          ],
        ),
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
            // The site's navigation belongs on the site, not over a single
            // card asking for an e-mail address. See WebAuthHeader.
            WebAuthHeader(
              isHebrew: _isHebrew,
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
        // hero_anaba.jpg is 300x184 — a thumbnail, stretched two to three
        // times over in a panel this size. This one is 853x1844 and
        // portrait, which is the shape the panel actually is.
        'assets/images/hero_modiin.jpg',
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
          // Somebody who came here from /admin asked for the control centre
          // and was handed the resident sign-in. It is the right screen —
          // there is one account system — but without a word saying so it
          // reads as the wrong one.
          if (GoRouterState.of(context).uri.queryParameters['next'] == '/admin')
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.adminActiveBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _t(
                    'Sign in to open the management panel.',
                    'התחברו כדי להיכנס לממשק הניהול.',
                  ),
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 13,
                    color: AppColors.midBlue,
                  ),
                ),
              ),
            ),
          Text(
            _t('Hi, welcome back! 👋', 'ברוכים השבים! 👋'),
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
              "Hello again, you've been missed!",
              'שמחים לראות אתכם שוב!',
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
            hint: _t('Please enter password', 'הזינו סיסמה'),
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
                        _t('Remember Me', 'זכור אותי'),
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
                    _t('Forgot Password?', 'שכחתם סיסמה?'),
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
          _buildNotice(),
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

/// "Forgot Password?" — its own field, and a plain answer when it is sent.
///
/// The address is asked for here rather than borrowed from the sign-in field,
/// because the two are not always the same thing: somebody resetting a
/// password often has not typed anything yet, and somebody who mistyped their
/// address in the field above would otherwise send the mail to the mistake.
class _ForgotPasswordDialog extends StatefulWidget {
  final bool isHebrew;
  final String initialEmail;
  final Future<void> Function(String email) onSend;

  const _ForgotPasswordDialog({
    required this.isHebrew,
    required this.initialEmail,
    required this.onSend,
  });

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  late final TextEditingController _email = TextEditingController(
    text: widget.initialEmail,
  );
  bool _sending = false;
  String? _sentTo;
  String? _error;

  String _t(String en, String he) => widget.isHebrew ? he : en;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  bool get _valid {
    final v = _email.text.trim();
    return v.contains('@') && v.contains('.') && v.length > 5;
  }

  Future<void> _send() async {
    final address = _email.text.trim();
    if (!_valid) {
      setState(() => _error = _t(
            'Enter a valid email address.',
            'הזינו כתובת אימייל תקינה.',
          ));
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await widget.onSend(address);
    } catch (_) {
      // Whether the address has an account is not said either way, so that
      // this cannot be used to find out who is registered.
    }
    if (!mounted) return;
    setState(() {
      _sending = false;
      _sentTo = address;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.isHebrew ? TextDirection.rtl : TextDirection.ltr,
      child: Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: _sentTo == null ? _buildForm() : _buildSent(),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t('Reset your password', 'איפוס סיסמה'),
          style: TextStyle(
            fontFamily: AppFonts.nunito,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: _kHeading,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _t(
            'Enter the address you signed up with and we will send a link to '
                'choose a new password.',
            'הזינו את הכתובת שאיתה נרשמתם ונשלח אליה קישור לבחירת סיסמה חדשה.',
          ),
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 14,
            height: 1.5,
            color: _kGreyText,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _t('Email', 'אימייל'),
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _kHeading,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _email,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) => setState(() => _error = null),
          onSubmitted: (_) => _sending ? null : _send(),
          style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14),
          decoration: InputDecoration(
            hintText: _t('you@example.com', 'you@example.com'),
            filled: false,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(
            _error!,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 13,
              color: AppColors.error,
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _sending ? null : () => Navigator.pop(context),
              child: Text(
                _t('Cancel', 'ביטול'),
                style: TextStyle(fontFamily: AppFonts.inter),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: _sending ? null : _send,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.midBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  elevation: 0,
                ),
                child: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _t('Send link', 'שליחת קישור'),
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.midBlue.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.email_outlined,
                size: 20,
                color: AppColors.midBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _t('Check your email', 'בדקו את תיבת האימייל'),
                style: TextStyle(
                  fontFamily: AppFonts.nunito,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: _kHeading,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // The address is repeated back, because a typo in it is the usual
        // reason the mail never turns up.
        Text.rich(
          TextSpan(
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              height: 1.55,
              color: _kGreyText,
            ),
            children: [
              TextSpan(
                text: _t(
                  'If an account exists for ',
                  'אם קיים חשבון עבור ',
                ),
              ),
              TextSpan(
                text: _sentTo,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _kHeading,
                ),
              ),
              TextSpan(
                text: _t(
                  ', a link to choose a new password is on its way. It is '
                      'good for one use. If it has not arrived in a few '
                      'minutes, check your spam folder.',
                  ', נשלח אליה קישור לבחירת סיסמה חדשה. הקישור תקף לשימוש אחד. '
                      'אם ההודעה לא הגיעה תוך כמה דקות, בדקו בתיקיית הספאם.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.midBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 28),
                elevation: 0,
              ),
              child: Text(
                _t('Done', 'סגירה'),
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
