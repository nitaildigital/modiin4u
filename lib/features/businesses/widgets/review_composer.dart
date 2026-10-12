import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../auth/widgets/m_account_widgets.dart' show mTr;

typedef ReviewPhoto = ({Uint8List bytes, String name});

/// Writing a review, made to invite one (the client, TestFlight 11 Oct: "a
/// funner UX that encourages users to write reviews — learn from how Google
/// does it, in our own look"). A full-height sheet: the place, who is
/// writing, big stars with their word, one-tap phrases to start from, the
/// text, photos, then a thank-you. What it saves and how — the photo
/// question, the uploads, the review waiting for the panel — stays with the
/// business page ([onSubmit]).
class ReviewComposer extends StatefulWidget {
  final String businessName;
  final String? businessLogo;
  final String userName;
  final String? userAvatar;
  final int initialRating;

  /// Picks one photo; null when cancelled or refused (it says why itself).
  final Future<ReviewPhoto?> Function() onPickPhoto;

  /// Saves the review; null when it went through, else what to tell them.
  final Future<String?> Function(int rating, String text, List<ReviewPhoto> photos) onSubmit;

  static const maxPhotos = 4;

  const ReviewComposer({
    super.key,
    required this.businessName,
    required this.businessLogo,
    required this.userName,
    required this.userAvatar,
    required this.initialRating,
    required this.onPickPhoto,
    required this.onSubmit,
  });

  @override
  State<ReviewComposer> createState() => _ReviewComposerState();
}

class _ReviewComposerState extends State<ReviewComposer> {
  late int _rating = widget.initialRating;
  final _text = TextEditingController();
  final _photos = <ReviewPhoto>[];
  final _tags = <String>{};
  bool _saving = false;
  bool _done = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  String _word(int r) => switch (r) {
    1 => mTr(context, 'Poor', 'גרוע'),
    2 => mTr(context, 'Fair', 'סביר'),
    3 => mTr(context, 'Good', 'טוב'),
    4 => mTr(context, 'Very good', 'טוב מאוד'),
    _ => mTr(context, 'Excellent!', 'מצוין!'),
  };

  /// Phrases to start from — the writer's own choice, added to their text.
  /// Praise for four and five stars, what to improve below that.
  List<String> get _suggestions => _rating >= 4
      ? [
          mTr(context, 'Great service', 'שירות מעולה'),
          mTr(context, 'Friendly staff', 'צוות אדיב'),
          mTr(context, 'Pleasant atmosphere', 'אווירה נעימה'),
          mTr(context, 'Fair prices', 'מחירים הוגנים'),
          mTr(context, 'Clean and tidy', 'נקי ומסודר'),
          mTr(context, 'Highly recommended', 'ממליץ/ה בחום'),
        ]
      : [
          mTr(context, 'Slow service', 'שירות איטי'),
          mTr(context, 'Too expensive', 'יקר מדי'),
          mTr(context, 'Not clean enough', 'לא מספיק נקי'),
          mTr(context, 'Long wait', 'המתנה ארוכה'),
          mTr(context, 'Needs improvement', 'יש מה לשפר'),
        ];

  void _toggleTag(String tag) => setState(() => _tags.contains(tag) ? _tags.remove(tag) : _tags.add(tag));

  Future<void> _addPhoto() async {
    if (_photos.length >= ReviewComposer.maxPhotos || _saving) return;
    final p = await widget.onPickPhoto();
    if (p != null && mounted) setState(() => _photos.add(p));
  }

  Future<void> _post() async {
    if (_rating == 0 || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    // The chosen phrases open the review, in the order shown, then their
    // own words.
    final tags = _suggestions.where(_tags.contains).join(' · ');
    final body = [if (tags.isNotEmpty) tags, _text.text.trim()].where((p) => p.isNotEmpty).join('\n');
    final error = await widget.onSubmit(_rating, body, List.of(_photos));
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = error;
      _done = error == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _done ? _thanks(context) : _form(context, bottom),
      ),
    );
  }

  Widget _form(BuildContext context, double keyboard) {
    final words = _text.text.trim().isEmpty ? 0 : _text.text.trim().split(RegExp(r'\s+')).length;
    return Column(
      key: const ValueKey('form'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFDADADA), borderRadius: BorderRadius.circular(2))),
        // The place, and who is writing.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
          child: Row(
            children: [
              ClipOval(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: NetworkPhoto(url: widget.businessLogo, width: 40, height: 40, icon: IconsaxPlusLinear.shop),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.businessName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 17, fontWeight: FontWeight.w600, color: Colors.black),
                ),
              ),
              IconButton(
                tooltip: mTr(context, 'Close', 'סגירה'),
                onPressed: _saving ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Color(0xFF6D6D6D)),
              ),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + keyboard),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _Avatar(url: widget.userAvatar, name: widget.userName),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.userName, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, fontWeight: FontWeight.w600)),
                          Text(
                            mTr(context, 'Shown to everyone once approved', 'יוצג לכולם לאחר אישור'),
                            style: TextStyle(fontFamily: AppFonts.inter, fontSize: 12, color: const Color(0xFF6D6D6D)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                // The stars, large, with the word under them.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final n = i + 1;
                    final on = _rating >= n;
                    return GestureDetector(
                      onTap: _saving ? null : () => setState(() {
                        if ((n >= 4) != (_rating >= 4)) _tags.clear();
                        _rating = n;
                      }),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: AnimatedScale(
                          scale: on ? 1.08 : 1,
                          duration: const Duration(milliseconds: 150),
                          child: Icon(
                            on ? IconsaxPlusBold.star_1 : IconsaxPlusLinear.star_1,
                            size: 44,
                            color: on ? const Color(0xFFFFC107) : const Color(0xFFC9C9C9),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  _rating == 0 ? mTr(context, 'Tap a star to rate', 'הקישו על כוכב לדירוג') : _word(_rating),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.midBlue),
                ),
                if (_rating > 0) ...[
                  const SizedBox(height: 22),
                  Text(
                    _rating >= 4
                        ? mTr(context, 'What did you like?', 'מה אהבתם?')
                        : mTr(context, 'What could be better?', 'מה אפשר לשפר?'),
                    style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tag in _suggestions)
                        GestureDetector(
                          onTap: _saving ? null : () => _toggleTag(tag),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: _tags.contains(tag) ? const Color(0xFFE6EDF7) : Colors.white,
                              border: Border.all(color: _tags.contains(tag) ? AppColors.midBlue : const Color(0xFFE0E0E0)),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_tags.contains(tag)) ...[
                                  const Icon(Icons.check, size: 15, color: AppColors.midBlue),
                                  const SizedBox(width: 4),
                                ],
                                Text(tag, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 13, color: _tags.contains(tag) ? AppColors.midBlue : const Color(0xFF333333))),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _text,
                    minLines: 4,
                    maxLines: 8,
                    maxLength: 2000,
                    onChanged: (_) => setState(() {}),
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, height: 1.45),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: mTr(
                        context,
                        'Share the details of your experience — what stood out?',
                        'ספרו על החוויה שלכם — מה בלט במיוחד?',
                      ),
                      hintStyle: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: const Color(0xFF9E9E9E)),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FB),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE7E7E7))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE7E7E7))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.midBlue)),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // A nudge, not a rule: any length may be sent.
                  Text(
                    words < 10
                        ? mTr(context, 'A few more words help other residents decide', 'עוד כמה מילים יעזרו לתושבים אחרים להחליט')
                        : mTr(context, 'Great — that will really help others', 'מעולה — זה ממש יעזור לאחרים'),
                    style: TextStyle(fontFamily: AppFonts.inter, fontSize: 12, color: words < 10 ? const Color(0xFF8A8A8A) : const Color(0xFF1E9E4A)),
                  ),
                  const SizedBox(height: 18),
                  // Photos: a large tile while there are none, small ones after.
                  if (_photos.isEmpty)
                    GestureDetector(
                      onTap: _addPhoto,
                      child: Container(
                        height: 92,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F6FB),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFCFDCEC)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(IconsaxPlusLinear.gallery_add, size: 26, color: AppColors.midBlue),
                            const SizedBox(width: 10),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(mTr(context, 'Add photos', 'הוספת תמונות'), style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.midBlue)),
                                Text(
                                  mTr(context, 'Reviews with photos help the most', 'ביקורות עם תמונות עוזרות הכי הרבה'),
                                  style: TextStyle(fontFamily: AppFonts.inter, fontSize: 12, color: const Color(0xFF6D6D6D)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 76,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (var i = 0; i < _photos.length; i++)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(end: 8),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.memory(_photos[i].bytes, width: 76, height: 76, fit: BoxFit.cover),
                                  ),
                                  PositionedDirectional(
                                    top: 3,
                                    end: 3,
                                    child: GestureDetector(
                                      onTap: _saving ? null : () => setState(() => _photos.removeAt(i)),
                                      child: Container(
                                        width: 22,
                                        height: 22,
                                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (_photos.length < ReviewComposer.maxPhotos)
                            GestureDetector(
                              onTap: _addPhoto,
                              child: Container(
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF2F6FB),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFCFDCEC)),
                                ),
                                child: const Icon(IconsaxPlusLinear.add, color: AppColors.midBlue),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0x1AE74C3C), borderRadius: BorderRadius.circular(10)),
                    child: Text(_error!, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 13, color: const Color(0xFFC0392B))),
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _rating == 0 || _saving ? null : _post,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.midBlue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFB9C6D8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                    ),
                    child: _saving
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : Text(mTr(context, 'Post review', 'פרסום הביקורת'), style: TextStyle(fontFamily: AppFonts.inter, fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _thanks(BuildContext context) {
    return Padding(
      key: const ValueKey('thanks'),
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.6, end: 1),
            duration: const Duration(milliseconds: 400),
            curve: Curves.elasticOut,
            builder: (_, s, child) => Transform.scale(scale: s, child: child),
            child: Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(color: Color(0xFFE7F9E8), shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, size: 46, color: Color(0xFF1E9E4A)),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            mTr(context, 'Thank you for your review!', 'תודה על הביקורת!'),
            style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            mTr(
              context,
              'It will appear on the page once the team has approved it. Your words help residents find great places.',
              'היא תופיע בעמוד אחרי אישור הצוות. המילים שלכם עוזרות לתושבים למצוא מקומות טובים.',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, height: 1.5, color: const Color(0xFF555555)),
          ),
          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.midBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
              ),
              child: Text(mTr(context, 'Done', 'סיום'), style: TextStyle(fontFamily: AppFonts.inter, fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  final String name;
  const _Avatar({required this.url, required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim().characters.first;
    return ClipOval(
      child: SizedBox(
        width: 40,
        height: 40,
        child: (url ?? '').isNotEmpty
            ? NetworkPhoto(url: url, width: 40, height: 40, icon: IconsaxPlusBold.user)
            : ColoredBox(
                color: const Color(0xFFE6EDF7),
                child: Center(
                  child: Text(initial, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.midBlue)),
                ),
              ),
      ),
    );
  }
}
