import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/router/app_router.dart' show AppNavigation;
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/m_kit.dart';
import '../../../shared/widgets/m_step_form.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../auth/widgets/m_account_widgets.dart';
import '../../deals/models/offer.dart';
import '../data/owner_data.dart';

/// Create Deal (`business_side/Create Deal.png`), and the same form over an
/// existing deal when [dealId] is given. A deal the owner publishes is live
/// at once (00051); there is no approval step.
class CreateDealScreen extends ConsumerStatefulWidget {
  final String? dealId;
  const CreateDealScreen({super.key, this.dealId});

  @override
  ConsumerState<CreateDealScreen> createState() => _CreateDealScreenState();
}

/// The bucket refuses anything larger.
const _maxBytes = 10 * 1024 * 1024;

/// The colours of the design's image box: a light blue fill and a dashed
/// blue edge.
const _boxFill = Color(0xFFEFF5FD);
const _boxEdge = Color(0xFF7DA6DA);

class _CreateDealScreenState extends ConsumerState<CreateDealScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _value = TextEditingController();
  final _terms = TextEditingController();
  String? _type;
  DateTime? _start;
  DateTime? _end;

  /// The picture already on the deal, and one newly picked (uploaded on
  /// save, so a form abandoned half-way leaves nothing in storage).
  String? _imageUrl;
  ({String name, Uint8List bytes})? _picked;

  Offer? _existing;
  bool _loading = false;
  String? _loadError;
  bool _saving = false;

  bool get _editing => widget.dealId != null;

  @override
  void initState() {
    super.initState();
    if (_editing) _load();
  }

  @override
  void dispose() {
    for (final c in [_title, _description, _value, _terms]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final d = await ref.read(ownerRepositoryProvider).fetchDeal(widget.dealId!);
      if (!mounted) return;
      if (d == null) {
        setState(() {
          _loading = false;
          _loadError = mTr(context, 'This deal no longer exists', 'המבצע הזה כבר לא קיים');
        });
        return;
      }
      setState(() {
        _existing = d;
        _title.text = d.name;
        _description.text = d.description ?? '';
        _terms.text = d.terms ?? '';
        _type = d.dealType;
        final v = d.dealValue;
        _value.text = v == null ? '' : (v == v.roundToDouble() ? v.toInt().toString() : v.toString());
        _start = d.startAt?.toLocal();
        _end = d.endAt?.toLocal();
        _imageUrl = d.imageUrl;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = mTr(context, 'Could not load the deal', 'לא ניתן לטעון את המבצע');
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? file;
    try {
      file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 2000, imageQuality: 85);
    } catch (_) {
      if (mounted) mToast(context, mTr(context, 'Could not open your photos', 'לא ניתן לפתוח את התמונות'), error: true);
      return;
    }
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    if (bytes.lengthInBytes > _maxBytes) {
      mToast(context, mTr(context, 'That photo is over 10 MB', 'התמונה גדולה מ-10MB'), error: true);
      return;
    }
    setState(() => _picked = (name: file!.name, bytes: bytes));
  }

  Future<void> _pickDate({required bool start}) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final current = start ? _start : _end;
    // A deal being edited may have started before today; the picker must
    // still be able to show its date.
    var first = start ? today : (_start ?? today);
    if (current != null && current.isBefore(first)) first = DateUtils.dateOnly(current);
    final initial = current ?? first;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : initial,
      firstDate: first,
      lastDate: today.add(const Duration(days: 3 * 365)),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _start = picked;
        // An end before the new start is no longer an end.
        if (_end != null && _end!.isBefore(picked)) _end = null;
      } else {
        _end = picked;
      }
    });
  }

  bool get _hasValue => _type == 'percentage' || _type == 'fixed';

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      mToast(context, mTr(context, 'Enter a title for the deal', 'נא להזין כותרת למבצע'), error: true);
      return;
    }
    double? value;
    if (_hasValue) {
      final raw = _value.text.trim().replaceAll(',', '.');
      value = double.tryParse(raw);
      if (value == null || value <= 0 || (_type == 'percentage' && value > 100)) {
        mToast(
          context,
          _type == 'percentage'
              ? mTr(context, 'Enter a percentage between 1 and 100', 'נא להזין אחוז בין 1 ל-100')
              : mTr(context, 'Enter the amount in shekels', 'נא להזין את הסכום בשקלים'),
          error: true,
        );
        return;
      }
    }
    if (_start != null && _end != null && DateUtils.dateOnly(_end!).isBefore(DateUtils.dateOnly(_start!))) {
      mToast(context, mTr(context, 'The end date is before the start date', 'תאריך הסיום לפני תאריך ההתחלה'), error: true);
      return;
    }
    final businessId = _existing?.businessId ?? ref.read(myBusinessIdProvider);
    if (businessId == null) {
      mToast(context, mTr(context, 'No business on this account', 'אין עסק בחשבון הזה'), error: true);
      return;
    }

    String? orNull(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    setState(() => _saving = true);
    final repo = ref.read(ownerRepositoryProvider);
    try {
      var imageUrl = _imageUrl;
      if (_picked != null) {
        imageUrl = await repo.upload(
          folder: 'offers',
          businessId: businessId,
          fileName: _picked!.name,
          bytes: _picked!.bytes,
        );
      }
      final start = _start;
      final end = _end;
      final saved = await repo.saveDeal(
        id: widget.dealId,
        row: {
          'business_id': businessId,
          'name': title,
          'description': orNull(_description),
          'terms': orNull(_terms),
          'image_url': imageUrl,
          'deal_type': _type,
          'deal_value': value,
          'start_at': start == null ? null : DateTime(start.year, start.month, start.day).toUtc().toIso8601String(),
          // Valid through the whole of its last day.
          'end_at': end == null
              ? null
              : DateTime(end.year, end.month, end.day, 23, 59, 59).toUtc().toIso8601String(),
          // A new deal is live at once. An edit leaves the status as it is,
          // so correcting a closed deal does not quietly reopen it.
          if (!_editing) 'status': 'active',
        },
      );
      ref.invalidate(myDealsProvider);
      if (!mounted) return;
      if (_editing) {
        mToast(context, mTr(context, 'Deal saved', 'המבצע נשמר'));
        context.back('/business-deals');
      } else {
        context.pushReplacement('/business-deals/${saved.id}/published');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        mToast(context, mTr(context, 'Could not save the deal. Try again.', 'שמירת המבצע נכשלה. נסו שוב.'), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MPage(
      title: _editing ? mTr(context, 'Edit Deal', 'עריכת מבצע') : mTr(context, 'Create Deal', 'יצירת מבצע'),
      bottom: _loading || _loadError != null
          ? null
          : MButton(
              label: _editing ? mTr(context, 'Save', 'שמירה') : mTr(context, 'Publish Deal', 'פרסום המבצע'),
              loading: _saving,
              onTap: _save,
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? MEmpty(icon: IconsaxPlusLinear.ticket_discount, title: _loadError!)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _sectionLabel(mTr(context, 'Deal Image', 'תמונת המבצע')),
                const SizedBox(height: 8),
                _imageBox(),
                const SizedBox(height: 20),
                MFormCard(
                  label: mTr(context, 'Deal Title', 'כותרת המבצע'),
                  child: MInputRow(
                    placeholder: mTr(context, 'e.g. 20% Off Your Dinner Bill', 'לדוגמה: 20% הנחה על הארוחה'),
                    controller: _title,
                  ),
                ),
                const SizedBox(height: 16),
                _multiLine(
                  mTr(context, 'Description', 'תיאור'),
                  _description,
                  mTr(context, 'Describe the offer for customers...', 'תארו את המבצע ללקוחות...'),
                ),
                const SizedBox(height: 20),
                _sectionLabel(mTr(context, 'Deal Type', 'סוג המבצע')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: MFormCard(
                        label: mTr(context, 'Type', 'סוג'),
                        child: MDropdownRow<String>(
                          placeholder: mTr(context, 'Select', 'בחירה'),
                          value: _type,
                          items: [
                            for (final t in const ['percentage', 'fixed', 'bogo', 'other'])
                              DropdownMenuItem(value: t, child: Text(_typeLabel(t))),
                          ],
                          onChanged: (v) => setState(() => _type = v),
                        ),
                      ),
                    ),
                    if (_hasValue) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: MFormCard(
                          label: mTr(context, 'Value', 'ערך'),
                          child: MInputRow(
                            placeholder: _type == 'percentage' ? '20' : '50',
                            controller: _value,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            suffix: _type == 'percentage' ? '%' : '₪',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                _sectionLabel(mTr(context, 'Validity', 'תוקף')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _dateCard(mTr(context, 'Start Date', 'תאריך התחלה'), _start, start: true)),
                    const SizedBox(width: 12),
                    // The design labels both "Start Date"; the second is the end.
                    Expanded(child: _dateCard(mTr(context, 'End Date', 'תאריך סיום'), _end, start: false)),
                  ],
                ),
                const SizedBox(height: 20),
                _multiLine(
                  mTr(context, 'Restrictions', 'הגבלות'),
                  _terms,
                  mTr(context, 'Add restrictions or terms, if any...', 'הוסיפו הגבלות או תנאים, אם יש...'),
                ),
              ],
            ),
    );
  }

  String _typeLabel(String t) => switch (t) {
    'percentage' => mTr(context, 'Percentage', 'אחוז הנחה'),
    'fixed' => mTr(context, 'Fixed amount ₪', 'סכום קבוע ₪'),
    'bogo' => mTr(context, 'Buy 1 get 1', '1+1'),
    _ => mTr(context, 'Other', 'אחר'),
  };

  Widget _sectionLabel(String text) => Text(text, style: mText(14, weight: FontWeight.w500));

  Widget _imageBox() {
    final hasImage = _picked != null || (_imageUrl ?? '').isNotEmpty;
    return GestureDetector(
      onTap: _pickImage,
      child: SizedBox(
        height: 150,
        child: hasImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _picked != null
                        ? Image.memory(_picked!.bytes, fit: BoxFit.cover)
                        : NetworkPhoto(url: _imageUrl!, height: 150, icon: IconsaxPlusBold.image),
                    PositionedDirectional(
                      end: 8,
                      bottom: 8,
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
                            Text(mTr(context, 'Change Image', 'החלפת תמונה'), style: mText(12.5, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : CustomPaint(
                foregroundPainter: _DashedBox(),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: _boxFill, borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(IconsaxPlusLinear.gallery, size: 34, color: mStepMid),
                      const SizedBox(height: 10),
                      Text(mTr(context, 'Add Image', 'הוספת תמונה'), style: mText(14, weight: FontWeight.w500, color: mStepMid)),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _dateCard(String label, DateTime? date, {required bool start}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _pickDate(start: start),
      child: MFormCard(
        label: label,
        child: SizedBox(
          height: 20,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  date == null ? mTr(context, 'Select date', 'בחירת תאריך') : mDate(context, date),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: mText(14, color: date == null ? mStepGrey : mStepInk),
                ),
              ),
              const Icon(IconsaxPlusLinear.calendar_1, size: 18, color: mStepGrey),
            ],
          ),
        ),
      ),
    );
  }

  /// The tall bordered box of the design's Description and Restrictions.
  Widget _multiLine(String label, TextEditingController controller, String hint) {
    return Container(
      height: 135,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: mStepHairline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: mText(13, weight: FontWeight.w500)),
          const SizedBox(height: 13),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: mStepInk, height: 1.4),
              decoration: InputDecoration(
                hintText: hint,
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
    );
  }
}

/// The dashed blue edge of the empty image box. [MDashedBorderPainter] draws
/// in grey only; the design's box is blue.
class _DashedBox extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _boxEdge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    const dash = 4.0;
    const gap = 3.0;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)));
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, (d + dash).clamp(0, metric.length)), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
