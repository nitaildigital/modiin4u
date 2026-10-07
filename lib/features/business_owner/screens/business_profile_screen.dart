import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/m_kit.dart';
import '../../../shared/widgets/m_step_form.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../auth/widgets/m_account_widgets.dart';
import '../../businesses/models/business.dart';
import '../../businesses/models/business_review.dart';
import '../../businesses/providers/business_providers.dart';
import '../data/owner_data.dart';

/// The owner's own business page (`business_side/Business Profile.png`):
/// cover, logo, name and contact lines, About, Working Hours, Photos and
/// Reviews, each editable in place. Edits are live at once (00051); only
/// promotion goes through the panel.
class BusinessProfileScreen extends ConsumerStatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  ConsumerState<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

/// The bucket refuses anything larger.
const _maxBytes = 10 * 1024 * 1024;

class _BusinessProfileScreenState extends ConsumerState<BusinessProfileScreen> {
  /// What is uploading now — 'cover', 'logo' or 'photos' — so that spot
  /// shows a spinner rather than the whole page.
  final Set<String> _busy = {};

  void _refresh(String businessId) {
    ref.invalidate(myBusinessProvider);
    // The public page keeps what it read for the session; dropped so the
    // owner sees the change there too.
    ref.invalidate(businessByIdProvider(businessId));
  }

  Future<({String name, Uint8List bytes})?> _pickOne({double maxWidth = 2000}) async {
    final XFile? file;
    try {
      file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: maxWidth, imageQuality: 85);
    } catch (_) {
      if (mounted) mToast(context, mTr(context, 'Could not open your photos', 'לא ניתן לפתוח את התמונות'), error: true);
      return null;
    }
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    if (!mounted) return null;
    if (bytes.lengthInBytes > _maxBytes) {
      mToast(context, mTr(context, 'That photo is over 10 MB', 'התמונה גדולה מ-10MB'), error: true);
      return null;
    }
    return (name: file.name, bytes: bytes);
  }

  /// The cover or the logo: picked, uploaded, and written to the business.
  Future<void> _changeImage(Business b, {required bool cover}) async {
    final key = cover ? 'cover' : 'logo';
    if (_busy.contains(key)) return;
    final picked = await _pickOne(maxWidth: cover ? 2000 : 1000);
    if (picked == null) return;
    setState(() => _busy.add(key));
    try {
      final repo = ref.read(ownerRepositoryProvider);
      final url = await repo.upload(folder: 'businesses', businessId: b.id, fileName: picked.name, bytes: picked.bytes);
      await repo.updateBusiness(b.id, {cover ? 'cover_url' : 'logo_url': url});
      _refresh(b.id);
    } catch (_) {
      if (mounted) mToast(context, mTr(context, 'Upload failed. Try again.', 'ההעלאה נכשלה. נסו שוב.'), error: true);
    } finally {
      if (mounted) setState(() => _busy.remove(key));
    }
  }

  Future<void> _addPhotos(Business b) async {
    if (_busy.contains('photos')) return;
    final List<XFile> picked;
    try {
      picked = await ImagePicker().pickMultiImage(maxWidth: 2000, imageQuality: 85);
    } catch (_) {
      if (mounted) mToast(context, mTr(context, 'Could not open your photos', 'לא ניתן לפתוח את התמונות'), error: true);
      return;
    }
    if (picked.isEmpty || !mounted) return;
    setState(() => _busy.add('photos'));
    final repo = ref.read(ownerRepositoryProvider);
    var failed = 0;
    for (final file in picked) {
      final bytes = await file.readAsBytes();
      if (bytes.lengthInBytes > _maxBytes) {
        failed++;
        continue;
      }
      try {
        await repo.addGalleryPhoto(businessId: b.id, fileName: file.name, bytes: bytes);
      } catch (_) {
        failed++;
      }
    }
    ref.invalidate(businessGalleryProvider(b.id));
    if (!mounted) return;
    setState(() => _busy.remove('photos'));
    if (failed > 0) {
      mToast(
        context,
        mTr(
          context,
          failed == 1 ? '1 photo could not be added' : '$failed photos could not be added',
          failed == 1 ? 'תמונה אחת לא נוספה' : '$failed תמונות לא נוספו',
        ),
        error: true,
      );
    }
  }

  Future<void> _open(Widget page, String businessId) async {
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => page));
    if (saved == true && mounted) {
      _refresh(businessId);
      mToast(context, mTr(context, 'Saved', 'נשמר'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(myBusinessProvider);
    final business = async.valueOrNull;
    return MPage(
      title: mTr(context, 'Business Profile', 'פרופיל העסק'),
      bottom: business == null ? null : _promoteButton(business),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => MEmpty(
          icon: IconsaxPlusLinear.shop,
          title: mTr(context, 'Could not load your business', 'לא ניתן לטעון את העסק'),
        ),
        data: (b) => b == null
            ? MEmpty(
                icon: IconsaxPlusLinear.shop,
                title: mTr(context, 'No business on this account', 'אין עסק בחשבון הזה'),
              )
            : RefreshIndicator(
                onRefresh: () async {
                  _refresh(b.id);
                  ref.invalidate(businessGalleryProvider(b.id));
                  ref.invalidate(myPromotionRequestsProvider);
                  await ref.read(myBusinessProvider.future);
                },
                child: _body(b),
              ),
      ),
    );
  }

  Widget _promoteButton(Business b) {
    final pending = ref.watch(pendingPromotionProvider(b.id));
    if (b.isPromoted) {
      return MButton(
        label: mTr(
          context,
          'Promoted until ${mDate(context, b.promotedUntil!.toLocal())}',
          'מקודם עד ${mDate(context, b.promotedUntil!.toLocal())}',
        ),
      );
    }
    if (pending != null) {
      return MButton(label: mTr(context, 'Promotion requested', 'נשלחה בקשת קידום'));
    }
    // Nobody sees a business still waiting for approval, so there is nothing
    // to put at the top of a list yet.
    if (b.status == BusinessStatus.pending) {
      return MButton(label: mTr(context, 'Promote after approval', 'קידום לאחר האישור'));
    }
    return MButton(
      label: mTr(context, 'Promote Business', 'קידום העסק'),
      onTap: () => context.push('/promote/business/${b.id}'),
    );
  }

  Widget _body(Business b) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (b.status == BusinessStatus.pending) _pendingBanner(),
        _header(b),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 14),
              _nameAndContacts(b),
              const SizedBox(height: 24),
              _aboutCard(b),
              const SizedBox(height: 16),
              _hoursCard(b),
              const SizedBox(height: 16),
              _photosCard(b),
              _reviewsCard(b),
            ],
          ),
        ),
      ],
    );
  }

  /// A business signed up from the app waits for the panel (00068); until
  /// then the owner can fill it in, but nobody else sees it.
  Widget _pendingBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6D9),
        border: Border.all(color: const Color(0xFFF2CC4E)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(IconsaxPlusLinear.clock, size: 20, color: Color(0xFF9A6B00)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mTr(context, 'Waiting for approval', 'ממתין לאישור'),
                  style: mText(14, weight: FontWeight.w600, color: const Color(0xFF6B4A00)),
                ),
                const SizedBox(height: 2),
                Text(
                  mTr(
                    context,
                    'Your business will be shown in the app once the Modiin4u team approves it.',
                    'העסק יוצג באפליקציה לאחר שצוות Modiin4u יאשר אותו.',
                  ),
                  style: mText(13, color: const Color(0xFF6B4A00), height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The cover across the page, with the round logo over its lower edge.
  Widget _header(Business b) {
    const coverHeight = 220.0;
    const logoSize = 100.0;
    return SizedBox(
      height: coverHeight + logoSize / 2,
      child: Stack(
        children: [
          SizedBox(
            height: coverHeight,
            width: double.infinity,
            child: (b.imageUrl ?? '').isEmpty
                ? Container(color: mKitBlueBg, child: const Icon(IconsaxPlusLinear.image, size: 32, color: mStepMid))
                : NetworkPhoto(url: b.imageUrl!, height: coverHeight, icon: IconsaxPlusBold.image),
          ),
          if (_busy.contains('cover'))
            const SizedBox(
              height: coverHeight,
              child: ColoredBox(
                color: Color(0x55000000),
                child: Center(child: CircularProgressIndicator(color: Colors.white)),
              ),
            ),
          PositionedDirectional(
            end: 8,
            top: coverHeight - 40,
            child: GestureDetector(
              onTap: () => _changeImage(b, cover: true),
              child: Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0x99000000),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(IconsaxPlusLinear.edit_2, size: 15, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(mTr(context, 'Change Cover', 'החלפת תמונת נושא'), style: mText(12.5, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
          PositionedDirectional(
            start: 16,
            top: coverHeight - logoSize / 2,
            child: GestureDetector(
              onTap: () => _changeImage(b, cover: false),
              child: Container(
                width: logoSize,
                height: logoSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: Stack(
                  children: [
                    MAvatar(url: b.logoUrl, name: b.name, size: logoSize - 6),
                    if (_busy.contains('logo'))
                      const Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: Color(0x55000000), shape: BoxShape.circle),
                          child: Center(child: CircularProgressIndicator(color: Colors.white)),
                        ),
                      ),
                    // The design draws no mark on the logo; a small camera
                    // says it can be tapped.
                    PositionedDirectional(
                      end: 2,
                      bottom: 2,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: mStepHairline),
                        ),
                        child: const Icon(IconsaxPlusLinear.camera, size: 14, color: mStepMid),
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

  Widget _nameAndContacts(Business b) {
    const grey = Color(0xFF3D3D3D);
    Widget line(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: mStepGrey),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: mText(14, color: grey))),
        ],
      ),
    );
    String? filled(String? s) => (s ?? '').trim().isEmpty ? null : s!.trim();

    final phone = filled(b.phone);
    final email = filled(b.email);
    final website = filled(b.website);
    final address = filled(b.address);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(b.name, style: mHeading(26))),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _open(_DetailsEditor(business: b), b.id),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(IconsaxPlusLinear.edit_2, size: 20, color: mStepMid),
              ),
            ),
          ],
        ),
        if (b.category.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(b.category, style: mText(14, color: mStepGrey)),
        ],
        if (b.reviewCount > 0 || b.isOpenNow)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: [
                if (b.reviewCount > 0) ...[
                  const Icon(Icons.star_rounded, size: 20, color: Color(0xFFFFB800)),
                  const SizedBox(width: 4),
                  Text(b.rating.toStringAsFixed(1), style: mText(14, weight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  Text('(${b.reviewCount})', style: mText(14, color: mStepGrey)),
                  const SizedBox(width: 16),
                ],
                if (b.isOpenNow) ...[
                  const Icon(Icons.check_circle, size: 17, color: mKitGreen),
                  const SizedBox(width: 6),
                  Text(mTr(context, 'Open now', 'פתוח עכשיו'), style: mText(14, weight: FontWeight.w500, color: mKitGreen)),
                ],
              ],
            ),
          ),
        if (phone != null) line(IconsaxPlusLinear.call, phone),
        if (email != null) line(IconsaxPlusLinear.sms, email),
        if (website != null) line(IconsaxPlusLinear.global, website),
        if (address != null) line(IconsaxPlusLinear.location, address),
      ],
    );
  }

  Widget _aboutCard(Business b) {
    final about = b.about;
    return MSectionCard(
      title: mTr(context, 'About ${b.name}', 'אודות ${b.name}'),
      actionIcon: IconsaxPlusLinear.edit_2,
      onAction: () => _open(_AboutEditor(business: b), b.id),
      hint: about == null
          ? mTr(context, 'Tell customers about your business.', 'ספרו ללקוחות על העסק.')
          : null,
      child: about == null ? null : Text(about, style: mText(14, color: const Color(0xFF3D3D3D), height: 1.45)),
    );
  }

  static const _dayShortEn = {1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun'};
  static const _dayShortHe = {1: 'שני', 2: 'שלישי', 3: 'רביעי', 4: 'חמישי', 5: 'שישי', 6: 'שבת', 7: 'ראשון'};

  Widget _hoursCard(Business b) {
    final he = Localizations.localeOf(context).languageCode == 'he';
    return MSectionCard(
      title: mTr(context, 'Working Hours', 'שעות פעילות'),
      actionIcon: IconsaxPlusLinear.edit_2,
      onAction: () => _open(_HoursEditor(business: b), b.id),
      // No rows at all is not the same as closed every day: the business
      // simply has not said.
      hint: b.hours.isEmpty ? mTr(context, 'Add your opening hours.', 'הוסיפו את שעות הפתיחה.') : null,
      child: b.hours.isEmpty
          ? null
          : Column(
              children: [
                // Business.hours counts 1 = Monday .. 7 = Sunday.
                for (var d = 1; d <= 7; d++)
                  Padding(
                    padding: EdgeInsets.only(top: d == 1 ? 0 : 16),
                    child: Builder(
                      builder: (context) {
                        final open = b.hours.where((h) => h.dayOfWeek == d && !h.isClosed).toList();
                        return Row(
                          children: [
                            Expanded(
                              child: Text((he ? _dayShortHe : _dayShortEn)[d]!, style: mText(14, color: const Color(0xFF3D3D3D))),
                            ),
                            if (open.isEmpty)
                              Text(mTr(context, 'Closed', 'סגור'), style: mText(14, color: mKitRed))
                            else
                              Text(
                                open.map((h) => '${h.openTime} – ${h.closeTime}').join(', '),
                                textDirection: TextDirection.ltr,
                                style: mText(14, color: const Color(0xFF3D3D3D)),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _photosCard(Business b) {
    final photos = ref.watch(businessGalleryProvider(b.id)).valueOrNull ?? const <String>[];
    final uploading = _busy.contains('photos');
    // Nine tiles; past nine, the last says how many more there are.
    final shown = photos.length > 9 ? photos.take(9).toList() : photos;
    final more = photos.length - 8;
    return MSectionCard(
      title: mTr(context, 'Photos', 'תמונות'),
      actionIcon: uploading ? null : IconsaxPlusLinear.add,
      onAction: () => _addPhotos(b),
      hint: photos.isEmpty && !uploading
          ? mTr(context, 'Add photos of your business.', 'הוסיפו תמונות של העסק.')
          : null,
      child: photos.isEmpty && !uploading
          ? null
          : Column(
              children: [
                if (uploading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: LinearProgressIndicator(color: mStepMid, backgroundColor: mKitBlueBg),
                  ),
                GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 13,
                  crossAxisSpacing: 13,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: [
                    for (var i = 0; i < shown.length; i++)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            NetworkPhoto(url: shown[i], icon: IconsaxPlusBold.image),
                            if (photos.length > 9 && i == 8) ...[
                              const ColoredBox(color: Color(0x88000000)),
                              Center(
                                child: Text('+$more', style: mText(30, weight: FontWeight.w500, color: Colors.white)),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
    );
  }

  /// Left out entirely while there are no approved reviews.
  Widget _reviewsCard(Business b) {
    final reviews = ref.watch(businessReviewsProvider(b.id)).valueOrNull ?? const <BusinessReview>[];
    // The provider also returns the signed-in person's own unapproved one;
    // the summary counts only approved reviews.
    final s = ReviewSummary.of(reviews);
    if (s.total == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: MSectionCard(
        title: mTr(context, 'Reviews', 'ביקורות'),
        actionIcon: Directionality.of(context) == TextDirection.rtl
            ? IconsaxPlusLinear.arrow_left_2
            : IconsaxPlusLinear.arrow_right_3,
        onAction: () => context.push('/business/${b.id}'),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(s.average.toStringAsFixed(1), style: mText(32, weight: FontWeight.w600, color: Colors.black)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        for (var i = 1; i <= 5; i++)
                          Icon(
                            Icons.star_rounded,
                            size: 26,
                            color: i <= s.average.round() ? const Color(0xFFFFB800) : const Color(0xFFD9D9D9),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      mTr(
                        context,
                        s.total == 1 ? 'Based on 1 review' : 'Based on ${s.total} reviews',
                        s.total == 1 ? 'על סמך ביקורת אחת' : 'על סמך ${s.total} ביקורות',
                      ),
                      style: mText(12, color: const Color(0xFF3D3D3D)),
                    ),
                  ],
                ),
              ),
              const VerticalDivider(width: 24, color: mStepHairline),
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    for (var score = 5; score >= 1; score--)
                      Padding(
                        padding: EdgeInsets.only(top: score == 5 ? 0 : 12),
                        child: Row(
                          children: [
                            SizedBox(width: 12, child: Text('$score', style: mText(13))),
                            const Icon(Icons.star_rounded, size: 15, color: Color(0xFFFFB800)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: s.shareOf(score),
                                  minHeight: 5,
                                  color: const Color(0xFF1C9AD6),
                                  backgroundColor: const Color(0xFFE6E6E6),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 34,
                              child: Text(
                                '${(s.shareOf(score) * 100).round()}%',
                                textAlign: TextAlign.end,
                                style: mText(11.5, color: mStepGrey),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Editors
// ═══════════════════════════════════════════════════

/// A one-line field in the step form's bordered card.
Widget _field(String label, TextEditingController c, {String placeholder = '', TextInputType? keyboard}) =>
    MFormCard(label: label, child: MInputRow(placeholder: placeholder, controller: c, keyboardType: keyboard));

/// The editor pages share a white page with the Save pill at the foot.
class _EditorPage extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool saving;
  final VoidCallback onSave;
  const _EditorPage({required this.title, required this.children, required this.saving, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return MPage(
      title: title,
      onBack: () => Navigator.of(context).pop(false),
      bottom: MButton(label: mTr(context, 'Save', 'שמירה'), loading: saving, onTap: onSave),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: children,
      ),
    );
  }
}

/// Name and the contact lines under it.
class _DetailsEditor extends ConsumerStatefulWidget {
  final Business business;
  const _DetailsEditor({required this.business});

  @override
  ConsumerState<_DetailsEditor> createState() => _DetailsEditorState();
}

class _DetailsEditorState extends ConsumerState<_DetailsEditor> {
  late final _name = TextEditingController(text: widget.business.nameHe);
  late final _phone = TextEditingController(text: widget.business.phone ?? '');
  late final _email = TextEditingController(text: widget.business.email ?? '');
  late final _website = TextEditingController(text: widget.business.website ?? '');
  late final _address = TextEditingController(text: widget.business.address);
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _website, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      mToast(context, mTr(context, 'Enter the business name', 'נא להזין את שם העסק'), error: true);
      return;
    }
    final email = _email.text.trim();
    if (email.isNotEmpty && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      mToast(context, mTr(context, 'That e-mail address does not look right', 'כתובת הדוא״ל אינה תקינה'), error: true);
      return;
    }
    String? orNull(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    setState(() => _saving = true);
    try {
      await ref.read(ownerRepositoryProvider).updateBusiness(widget.business.id, {
        'name': name,
        'phone': orNull(_phone),
        'email': orNull(_email),
        'website': orNull(_website),
        // The column may not be null.
        'address': _address.text.trim(),
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        mToast(context, mTr(context, 'Could not save. Try again.', 'השמירה נכשלה. נסו שוב.'), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 16);
    return _EditorPage(
      title: mTr(context, 'Business Details', 'פרטי העסק'),
      saving: _saving,
      onSave: _save,
      children: [
        _field(mTr(context, 'Business Name', 'שם העסק'), _name),
        gap,
        _field(mTr(context, 'Phone', 'טלפון'), _phone, keyboard: TextInputType.phone),
        gap,
        _field(mTr(context, 'Email', 'דוא״ל'), _email, keyboard: TextInputType.emailAddress),
        gap,
        _field(mTr(context, 'Website', 'אתר'), _website, keyboard: TextInputType.url),
        gap,
        _field(mTr(context, 'Address', 'כתובת'), _address, keyboard: TextInputType.streetAddress),
      ],
    );
  }
}

/// The About text — `full_description`.
class _AboutEditor extends ConsumerStatefulWidget {
  final Business business;
  const _AboutEditor({required this.business});

  @override
  ConsumerState<_AboutEditor> createState() => _AboutEditorState();
}

class _AboutEditorState extends ConsumerState<_AboutEditor> {
  late final _about = TextEditingController(text: widget.business.about ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _about.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final text = _about.text.trim();
      await ref.read(ownerRepositoryProvider).updateBusiness(widget.business.id, {
        'full_description': text.isEmpty ? null : text,
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        mToast(context, mTr(context, 'Could not save. Try again.', 'השמירה נכשלה. נסו שוב.'), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _EditorPage(
      title: mTr(context, 'About', 'אודות'),
      saving: _saving,
      onSave: _save,
      children: [
        Container(
          height: 320,
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
                mTr(context, 'About ${widget.business.name}', 'אודות ${widget.business.name}'),
                style: mText(13, weight: FontWeight.w500),
              ),
              const SizedBox(height: 13),
              Expanded(
                child: TextField(
                  controller: _about,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: mStepInk, height: 1.4),
                  decoration: InputDecoration(
                    hintText: mTr(context, 'What does your business offer?', 'מה העסק שלכם מציע?'),
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
      ],
    );
  }
}

/// One day's hours as the editor holds them. [day] is the table's
/// numbering, 0 = Sunday.
class _DayHours {
  final int day;
  bool open;
  TimeOfDay from;
  TimeOfDay to;
  _DayHours(this.day, {this.open = false, this.from = const TimeOfDay(hour: 9, minute: 0), this.to = const TimeOfDay(hour: 17, minute: 0)});
}

/// Monday to Sunday, a switch and two times each — the sign-up form's hours
/// card, filled from what the business has.
class _HoursEditor extends ConsumerStatefulWidget {
  final Business business;
  const _HoursEditor({required this.business});

  @override
  ConsumerState<_HoursEditor> createState() => _HoursEditorState();
}

class _HoursEditorState extends ConsumerState<_HoursEditor> {
  late final List<_DayHours> _days = [
    for (final d in const [1, 2, 3, 4, 5, 6, 0]) _fromBusiness(d),
  ];
  bool _saving = false;

  static TimeOfDay? _parse(String? hhmm) {
    final parts = (hhmm ?? '').split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    return h == null || m == null ? null : TimeOfDay(hour: h, minute: m);
  }

  static String _hhmm(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// The table counts 0 = Sunday; [Business.hours] counts 7 = Sunday.
  _DayHours _fromBusiness(int tableDay) {
    final modelDay = tableDay == 0 ? DateTime.sunday : tableDay;
    final h = widget.business.hours.where((h) => h.dayOfWeek == modelDay && !h.isClosed).firstOrNull;
    final from = _parse(h?.openTime);
    final to = _parse(h?.closeTime);
    if (h == null || from == null || to == null) return _DayHours(tableDay);
    return _DayHours(tableDay, open: true, from: from, to: to);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(ownerRepositoryProvider).saveHours(widget.business.id, {
        for (final d in _days) d.day: d.open ? (open: _hhmm(d.from), close: _hhmm(d.to)) : null,
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        mToast(context, mTr(context, 'Could not save. Try again.', 'השמירה נכשלה. נסו שוב.'), error: true);
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final he = Localizations.localeOf(context).languageCode == 'he';
    final firstOpen = _days.where((h) => h.open).firstOrNull;
    return _EditorPage(
      title: mTr(context, 'Working Hours', 'שעות פעילות'),
      saving: _saving,
      onSave: _save,
      children: [
        MFormCard(
          label: mTr(context, 'Business Hours', 'שעות פעילות'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final h in _days)
                SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text((he ? _dayNamesHe : _dayNamesEn)[h.day]!, style: mText(14)),
                      ),
                      if (h.open) ...[
                        _timeChip(h, from: true),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text('–', style: TextStyle(color: mStepGrey)),
                        ),
                        _timeChip(h, from: false),
                      ] else
                        Text(mTr(context, 'Closed', 'סגור'), style: mText(13, color: mStepGrey)),
                      const SizedBox(width: 8),
                      Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: h.open,
                          activeTrackColor: mStepMid,
                          // The theme draws an off switch with a black
                          // outline and thumb; these sit in the form's grey.
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: mStepHairline,
                          trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
                          onChanged: (v) => setState(() => h.open = v),
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
                      for (final h in _days) {
                        h
                          ..open = true
                          ..from = firstOpen.from
                          ..to = firstOpen.to;
                      }
                    }),
                    child: Text(
                      mTr(
                        context,
                        "Same hours every day (${_dayNamesEn[firstOpen.day]}'s)",
                        'אותן שעות בכל יום (של ${_dayNamesHe[firstOpen.day]})',
                      ),
                      style: mText(13, weight: FontWeight.w500, color: mStepMid),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
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
        setState(() => from ? h.from = picked : h.to = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(color: mKitBlueBg, borderRadius: BorderRadius.circular(6)),
        child: Text(_hhmm(value), style: mText(13, weight: FontWeight.w500, color: mStepMid)),
      ),
    );
  }
}
