import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../../core/router/app_router.dart' show AppNavigation;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/m_step_form.dart';
import '../../businesses/services/pending_business_media.dart';
import '../providers/auth_provider.dart';
import '../widgets/m_account_widgets.dart';

/// Sign-up for a business account, opened from the Business card on the
/// sign-up screen. Laid out like Add Apartment, as the design asks:
///
/// Step 1, basic details: logo, the person's name, the business's name,
///   e-mail, phone, address — and a password, since this creates the account.
/// Step 2, photos.
/// Step 3, additional details: website, opening hours Monday to Sunday,
///   about.
///
/// The details travel with the account, and the database creates the
/// business from them as `pending` (00068) for the client to approve in the
/// panel — sign-up needs the address confirmed, so there is no session to
/// write anything with here. The logo and photos are kept on the phone and
/// uploaded at the first sign-in ([PendingBusinessMedia]).
class BusinessSignUpScreen extends ConsumerStatefulWidget {
  const BusinessSignUpScreen({super.key});

  @override
  ConsumerState<BusinessSignUpScreen> createState() => _BusinessSignUpScreenState();
}

/// One day's opening hours as the form holds them. [day] is the table's
/// numbering, 0 = Sunday.
class _DayHours {
  final int day;
  bool open = false;
  TimeOfDay from = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay to = const TimeOfDay(hour: 17, minute: 0);

  /// Set once the person has changed this day, so a form left untouched
  /// sends no hours at all rather than seven days "closed".
  bool touched = false;

  _DayHours(this.day);
}

class _Picked {
  final XFile file;
  final Uint8List bytes;
  const _Picked(this.file, this.bytes);
}

class _BusinessSignUpScreenState extends ConsumerState<BusinessSignUpScreen> {
  int _step = 0; // 0 = basics, 1 = photos, 2 = details, 3 = sent

  // ── Step 1 ──
  _Picked? _logo;
  final _person = TextEditingController();
  final _business = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // ── Step 2 ──
  static const _maxPhotos = 9;
  final List<_Picked> _photos = [];

  // ── Step 3 ──
  final _website = TextEditingController();
  final _about = TextEditingController();

  /// Monday first, as the business page lists them.
  final List<_DayHours> _hours = [for (final d in const [1, 2, 3, 4, 5, 6, 0]) _DayHours(d)];
  bool _agreedToTerms = false;

  bool _saving = false;

  /// Whether the sign-up came back signed in (no confirmation asked).
  bool _signedIn = false;

  @override
  void dispose() {
    for (final c in [_person, _business, _email, _phone, _address, _password, _confirm, _website, _about]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Pictures ──

  Future<void> _pickLogo() async {
    final XFile? file;
    try {
      file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1000, imageQuality: 85);
    } catch (_) {
      if (mounted) _toast(L.of(context).uploadFailed, error: true);
      return;
    }
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    if (bytes.lengthInBytes > 10 * 1024 * 1024) {
      _toast(L.of(context).photoTooLarge, error: true);
      return;
    }
    setState(() => _logo = _Picked(file!, bytes));
  }

  Future<void> _pickPhotos() async {
    final l = L.of(context);
    final room = _maxPhotos - _photos.length;
    if (room <= 0) {
      _toast(l.maxPhotosReached(_maxPhotos));
      return;
    }
    final List<XFile> picked;
    try {
      picked = await ImagePicker().pickMultiImage(maxWidth: 2000, imageQuality: 85);
    } catch (_) {
      if (mounted) _toast(l.uploadFailed, error: true);
      return;
    }
    for (final file in picked.take(room)) {
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      // The bucket refuses anything over 10MB, which would only be found out
      // at the first sign-in; said now instead.
      if (bytes.lengthInBytes > 10 * 1024 * 1024) {
        _toast(l.photoTooLarge, error: true);
        continue;
      }
      setState(() => _photos.add(_Picked(file, bytes)));
    }
  }

  // ── Moving through the steps ──

  void _onBack() {
    if (_step > 0 && _step < 3) {
      setState(() => _step--);
    } else {
      context.back('/signup');
    }
  }

  /// What is missing, and the step it is on — checked on the way out of each
  /// step and again at the end.
  (int, String)? _problem() {
    final l = L.of(context);
    if (_person.text.trim().isEmpty ||
        _business.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _phone.text.trim().isEmpty ||
        _address.text.trim().isEmpty) {
      return (0, l.fillRequiredFields);
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim())) {
      return (0, mTr(context, 'Enter a valid email address.', 'הזינו כתובת אימייל תקינה.'));
    }
    if (_password.text.length < 8) return (0, l.errPasswordTooShort);
    if (_password.text != _confirm.text) return (0, l.errPasswordsDoNotMatch);
    return null;
  }

  void _onNext() {
    if (_step == 0) {
      final problem = _problem();
      if (problem != null) {
        _toast(problem.$2, error: true);
        return;
      }
    }
    setState(() => _step++);
  }

  Future<void> _onSubmit() async {
    if (_saving) return;
    final l = L.of(context);
    final problem = _problem();
    if (problem != null) {
      setState(() => _step = problem.$1);
      _toast(problem.$2, error: true);
      return;
    }
    if (!_agreedToTerms) {
      _toast(l.errAgreeToTerms, error: true);
      return;
    }

    final email = _email.text.trim();
    setState(() => _saving = true);
    try {
      await PendingBusinessMedia.save(
        email: email,
        logo: _logo?.file,
        photos: [for (final p in _photos) p.file],
      );
      final signedIn = await ref.read(authProvider.notifier).signUp(
        email: email,
        password: _password.text,
        data: {
          'full_name': _person.text.trim(),
          'phone': _phone.text.trim(),
          'account_type': 'business',
          'business': {
            'name': _business.text.trim(),
            'phone': _phone.text.trim(),
            'email': email,
            'address': _address.text.trim(),
            if (_websiteUrl() != null) 'website': _websiteUrl(),
            if (_about.text.trim().isNotEmpty) 'about': _about.text.trim(),
            if (_hours.any((h) => h.touched))
              'hours': [
                for (final h in _hours)
                  h.open
                      ? {'day': h.day, 'open': _hhmm(h.from), 'close': _hhmm(h.to)}
                      : {'day': h.day, 'closed': true},
              ],
          },
        },
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _signedIn = signedIn;
        _step = 3;
      });
    } on EmailAlreadyRegistered {
      await PendingBusinessMedia.discard(email);
      if (!mounted) return;
      setState(() => _saving = false);
      await _showAlreadyRegistered(email);
    } catch (e) {
      await PendingBusinessMedia.discard(email);
      if (!mounted) return;
      setState(() => _saving = false);
      _toast(e is AuthException ? e.message : l.errCouldNotSubmit, error: true);
    }
  }

  /// Points someone who already has an account to it.
  ///
  /// Supabase sends no email in this case, so "check your email" would leave
  /// them waiting for nothing. The reset is the same email the sign-in page
  /// sends from "Forgot Password?", to the address already typed here.
  Future<void> _showAlreadyRegistered(String email) {
    final l = L.of(context);
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(
          mTr(
            context,
            'This email already has an account. Sign in, or reset your '
                'password if you forgot it.',
            'לכתובת הזו כבר יש חשבון. התחברו, או אפסו את הסיסמה אם שכחתם אותה.',
          ),
          style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(authProvider.notifier).sendPasswordReset(email);
              } catch (_) {
                // Reported the same either way, as on the sign-in page.
              }
              if (mounted) _toast(l.resetLinkSent);
            },
            child: Text(
              mTr(context, 'Reset password', 'איפוס סיסמה'),
              style: TextStyle(fontFamily: AppFonts.inter),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/login');
            },
            child: Text(
              l.signIn,
              style: TextStyle(fontFamily: AppFonts.inter, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// A site typed without its scheme ("mybiz.co.il") still has to open from
  /// the business page.
  String? _websiteUrl() {
    final site = _website.text.trim();
    if (site.isEmpty) return null;
    return RegExp(r'^https?://', caseSensitive: false).hasMatch(site) ? site : 'https://$site';
  }

  static String _hhmm(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _resend() async {
    final l = L.of(context);
    try {
      await ref.read(authProvider.notifier).resendConfirmation(_email.text);
      if (mounted) _toast(l.confirmationResent);
    } catch (e) {
      if (!mounted) return;
      final wait = resendWaitSeconds(e);
      _toast(
        wait == null
            ? (e is AuthException ? e.message : l.errTooMany)
            : wait.isEmpty
            ? l.resendAgainSoon
            : l.resendAgainIn(wait),
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

  // ── Layout ──

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final sent = _step == 3;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: SafeArea(
            child: Column(
              children: [
                // Top bar: back and the centred title, as on Add Apartment.
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 10, 15, 0),
                  child: SizedBox(
                    height: 24,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          mTr(context, 'Business Sign Up', 'הרשמת עסק'),
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        if (!sent)
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: MBackArrow(color: const Color(0xFF3D3D3D), onTap: _onBack),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: sent
                      ? _buildSent(l)
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(15, 26, 15, 24),
                          children: [
                            Center(
                              child: MStepProgressBar(
                                currentStep: _step,
                                labels: [l.stepBasics, l.stepPhotos, l.stepDetails],
                                onStepTap: (i) => setState(() => _step = i),
                              ),
                            ),
                            const SizedBox(height: 32),
                            ...switch (_step) {
                              0 => _buildBasics(l),
                              1 => _buildPhotos(l),
                              _ => _buildDetails(l),
                            },
                          ],
                        ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: mStepHairline)),
                  ),
                  child: MStepButton(
                    label: sent
                        ? (_signedIn ? mTr(context, 'Done', 'סיום') : l.signIn)
                        : _step == 2
                        ? mTr(context, 'Create Account', 'יצירת חשבון')
                        : l.next,
                    arrow: _step < 2,
                    loading: _saving,
                    onTap: sent
                        ? () {
                            context.go('/');
                            if (!_signedIn) context.push('/login');
                          }
                        : _step < 2
                        ? _onNext
                        : _onSubmit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, String subtitle, {Widget? extra}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, fontWeight: FontWeight.w600, color: mStepInk),
        ),
        const SizedBox(height: 6),
        Text(subtitle, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 12, color: mStepGrey)),
        if (extra != null) ...[const SizedBox(height: 6), extra],
      ],
    );
  }

  // ═══════════════════════════════════════════════
  // Step 1: basic details
  // ═══════════════════════════════════════════════
  List<Widget> _buildBasics(L l) {
    return [
      _sectionHeader(
        mTr(context, 'Basic Details', 'פרטים בסיסיים'),
        mTr(context, 'Tell residents who you are.', 'ספרו לתושבים מי אתם.'),
      ),
      const SizedBox(height: 20),

      // ── Logo ──
      MFormCard(
        label: mTr(context, 'Logo', 'לוגו'),
        child: Row(
          children: [
            GestureDetector(
              onTap: _pickLogo,
              child: SizedBox(
                width: 64,
                height: 64,
                child: _logo == null
                    ? CustomPaint(
                        painter: MDashedBorderPainter(),
                        child: Center(
                          child: SvgPicture.asset('assets/icons/m_realestate_plus.svg', width: 22, height: 22),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(_logo!.bytes, fit: BoxFit.cover),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _pickLogo,
                child: Text(
                  _logo == null
                      ? mTr(context, 'Upload your logo', 'העלאת לוגו')
                      : mTr(context, 'Change logo', 'החלפת לוגו'),
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: mStepMid,
                  ),
                ),
              ),
            ),
            if (_logo != null)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _logo = null),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 18, color: mStepGrey),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      MFormCard(
        label: mTr(context, 'Contact Person *', 'איש/אשת קשר *'),
        child: MInputRow(controller: _person, placeholder: l.enterFullName),
      ),
      const SizedBox(height: 16),
      MFormCard(
        label: mTr(context, 'Business Name *', 'שם העסק *'),
        child: MInputRow(
          controller: _business,
          placeholder: mTr(context, 'Enter the business name', 'הזינו את שם העסק'),
        ),
      ),
      const SizedBox(height: 16),
      MFormCard(
        label: '${l.email} *',
        child: MInputRow(controller: _email, placeholder: l.enterEmail, keyboardType: TextInputType.emailAddress),
      ),
      const SizedBox(height: 16),
      MFormCard(
        label: '${l.phone} *',
        child: MInputRow(controller: _phone, placeholder: l.enterYourPhone, keyboardType: TextInputType.phone),
      ),
      const SizedBox(height: 16),
      // The design's "Location". The panel places the map pin when the
      // client approves the business.
      MFormCard(
        label: mTr(context, 'Location *', 'מיקום *'),
        child: MInputRow(controller: _address, placeholder: l.enterAddress),
      ),
      const SizedBox(height: 16),
      MFormCard(
        label: '${l.password} *',
        child: MInputRow(
          controller: _password,
          placeholder: l.choosePassword,
          obscureText: _obscurePassword,
          onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      const SizedBox(height: 16),
      MFormCard(
        label: '${l.confirmPassword} *',
        child: MInputRow(
          controller: _confirm,
          placeholder: l.reenterPassword,
          obscureText: _obscureConfirm,
          onToggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
        ),
      ),
    ];
  }

  // ═══════════════════════════════════════════════
  // Step 2: photos — the apartment form's nine places
  // ═══════════════════════════════════════════════
  List<Widget> _buildPhotos(L l) {
    return [
      _sectionHeader(
        l.addPhotos,
        mTr(context, 'Show residents your business.', 'הראו לתושבים את העסק.'),
        extra: Text(
          l.firstPhotoIsCover,
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFFFF3434),
          ),
        ),
      ),
      const SizedBox(height: 16),
      LayoutBuilder(
        builder: (context, box) {
          final side = (box.maxWidth - 10) * 118 / 353;
          return Column(
            children: [
              SizedBox(
                height: 210,
                child: Row(
                  children: [
                    Expanded(child: _slot(l, 0)),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: side,
                      child: Column(
                        children: [
                          Expanded(child: _slot(l, 1)),
                          const SizedBox(height: 10),
                          Expanded(child: _slot(l, 2)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              for (var row = 0; row < 2; row++) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 100,
                  child: Row(
                    children: [
                      for (var c = 0; c < 3; c++) ...[
                        if (c > 0) const SizedBox(width: 12),
                        Expanded(child: _slot(l, 3 + row * 3 + c)),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    ];
  }

  Widget _slot(L l, int index) {
    if (index < _photos.length) return _photoTile(l, index);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _pickPhotos,
      child: CustomPaint(
        painter: MDashedBorderPainter(),
        child: Center(child: SvgPicture.asset('assets/icons/m_realestate_plus.svg', width: 24, height: 24)),
      ),
    );
  }

  Widget _photoTile(L l, int index) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(_photos[index].bytes, fit: BoxFit.cover),
        ),
        if (index == 0)
          PositionedDirectional(
            start: 10,
            top: 10,
            child: Container(
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: mStepMid, borderRadius: BorderRadius.circular(50)),
              child: Text(
                l.mainImage,
                style: TextStyle(fontFamily: AppFonts.inter, fontSize: 11, color: Colors.white),
              ),
            ),
          )
        else
          // Made the cover by moving it first, as on the apartment form.
          PositionedDirectional(
            start: 6,
            bottom: 6,
            child: GestureDetector(
              onTap: () => setState(() => _photos.insert(0, _photos.removeAt(index))),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.star_border_rounded, size: 14, color: mStepMid),
              ),
            ),
          ),
        PositionedDirectional(
          end: 8,
          top: 8,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _photos.removeAt(index)),
            child: Container(
              width: 18,
              height: 18,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Color(0xFFFF3434), shape: BoxShape.circle),
              child: SvgPicture.asset('assets/icons/m_realestate_close_x.svg', width: 7.108, height: 7.036),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  // Step 3: additional details
  // ═══════════════════════════════════════════════
  List<Widget> _buildDetails(L l) {
    return [
      _sectionHeader(
        mTr(context, 'Additional Details', 'פרטים נוספים'),
        mTr(context, 'Optional — you can add them later too.', 'לא חובה — אפשר להוסיף גם בהמשך.'),
      ),
      const SizedBox(height: 20),
      MFormCard(
        label: mTr(context, 'Website', 'אתר אינטרנט'),
        child: MInputRow(
          controller: _website,
          placeholder: 'www.example.co.il',
          keyboardType: TextInputType.url,
        ),
      ),
      const SizedBox(height: 16),
      _hoursCard(l),
      const SizedBox(height: 16),

      // ── About ── drawn as the apartment form's description box
      Container(
        height: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: mStepHairline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mTr(context, 'About', 'אודות'),
              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 13, fontWeight: FontWeight.w500, color: mStepInk),
            ),
            const SizedBox(height: 13),
            Expanded(
              child: TextField(
                controller: _about,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: mStepInk),
                decoration: InputDecoration(
                  hintText: mTr(
                    context,
                    'What does your business offer?',
                    'מה העסק שלכם מציע?',
                  ),
                  hintMaxLines: 3,
                  hintStyle: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: mStepGrey),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      _terms(l),
    ];
  }

  static const _dayNamesHe = {
    1: 'יום שני',
    2: 'יום שלישי',
    3: 'יום רביעי',
    4: 'יום חמישי',
    5: 'יום שישי',
    6: 'שבת',
    0: 'יום ראשון',
  };
  static const _dayNamesEn = {
    1: 'Monday',
    2: 'Tuesday',
    3: 'Wednesday',
    4: 'Thursday',
    5: 'Friday',
    6: 'Saturday',
    0: 'Sunday',
  };

  Widget _hoursCard(L l) {
    final he = Localizations.localeOf(context).languageCode == 'he';
    final firstOpen = _hours.where((h) => h.open).firstOrNull;
    return MFormCard(
      label: mTr(context, 'Business Hours', 'שעות פעילות'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final h in _hours)
            SizedBox(
              height: 44,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      (he ? _dayNamesHe : _dayNamesEn)[h.day]!,
                      style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: mStepInk),
                    ),
                  ),
                  if (h.open) ...[
                    _timeChip(h, from: true),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text('–', style: TextStyle(color: mStepGrey)),
                    ),
                    _timeChip(h, from: false),
                  ] else
                    Text(l.closed, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 13, color: mStepGrey)),
                  const SizedBox(width: 8),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: h.open,
                      activeTrackColor: mStepMid,
                      // The theme draws an off switch with a black outline
                      // and thumb; these sit in the form's light grey.
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: mStepHairline,
                      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
                      onChanged: (v) => setState(() {
                        h.open = v;
                        h.touched = true;
                      }),
                    ),
                  ),
                ],
              ),
            ),
          // Most businesses keep the same hours most days; one tap copies
          // the first open day's to the rest.
          if (firstOpen != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 36)),
                onPressed: () => setState(() {
                  for (final h in _hours) {
                    h
                      ..open = true
                      ..from = firstOpen.from
                      ..to = firstOpen.to
                      ..touched = true;
                  }
                }),
                child: Text(
                  mTr(
                    context,
                    "Same hours every day (${_dayNamesEn[firstOpen.day]}'s)",
                    'אותן שעות בכל יום (של ${_dayNamesHe[firstOpen.day]})',
                  ),
                  style: TextStyle(fontFamily: AppFonts.inter, fontSize: 13, fontWeight: FontWeight.w500, color: mStepMid),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _timeChip(_DayHours h, {required bool from}) {
    final value = from ? h.from : h.to;
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: value,
          // Israel reads the clock in 24 hours, as the business page shows it.
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
        );
        if (picked == null) return;
        setState(() {
          from ? h.from = picked : h.to = picked;
          h.touched = true;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF4FD),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          _hhmm(value),
          style: TextStyle(fontFamily: AppFonts.inter, fontSize: 13, fontWeight: FontWeight.w500, color: mStepMid),
        ),
      ),
    );
  }

  /// The sign-up screen's terms line.
  Widget _terms(L l) {
    final link = TextStyle(
      fontFamily: AppFonts.inter,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.midBlue,
    );
    return GestureDetector(
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
              border: Border.all(color: _agreedToTerms ? AppColors.midBlue : const Color(0xFF7B899A)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: _agreedToTerms ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: mTr(context, 'I agree to the ', 'אני מסכים ל'),
                style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: Colors.black, height: 1.4),
                children: [
                  TextSpan(
                    text: l.termsOfService,
                    recognizer: TapGestureRecognizer()..onTap = () => context.push('/terms'),
                    style: link,
                  ),
                  TextSpan(text: l.andConjunction),
                  TextSpan(
                    text: l.privacyPolicy,
                    recognizer: TapGestureRecognizer()..onTap = () => context.push('/privacy'),
                    style: link,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Sent: confirm the address, then the client approves
  // ═══════════════════════════════════════════════
  Widget _buildSent(L l) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        children: [
          const SizedBox(height: 64),
          Image.asset('assets/images/m_realestate_listing_submitted.webp', width: 245, height: 162, fit: BoxFit.cover),
          const SizedBox(height: 24),
          Text(
            _signedIn ? mTr(context, 'Your account is ready', 'החשבון שלכם מוכן') : l.checkYourEmail,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: AppFonts.inter, fontSize: 20, fontWeight: FontWeight.w600, color: mStepInk),
          ),
          const SizedBox(height: 12),
          if (!_signedIn)
            Text(
              mTr(
                context,
                'We sent a confirmation link to ${_email.text.trim()}. Confirm your address, then sign in — your logo and photos are added when you first sign in on this phone.',
                'שלחנו קישור אימות אל ${_email.text.trim()}. אשרו את הכתובת והתחברו — הלוגו והתמונות יתווספו בהתחברות הראשונה בטלפון הזה.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, height: 1.4, color: mStepGrey),
            ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9EF),
              border: Border.all(color: const Color(0xFFFFE8C3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                SvgPicture.asset('assets/icons/m_realestate_clock.svg', width: 24, height: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.pendingApproval,
                        style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, fontWeight: FontWeight.w600, color: mStepInk),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        mTr(
                          context,
                          'Your business is shown in the app once the Modiin4u team approves it.',
                          'העסק יוצג באפליקציה לאחר שצוות מודיעין בשבילך יאשר אותו.',
                        ),
                        style: TextStyle(fontFamily: AppFonts.inter, fontSize: 12, color: mStepGrey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!_signedIn) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: _resend,
              child: Text(
                l.resendConfirmation,
                style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, fontWeight: FontWeight.w500, color: mStepMid),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
