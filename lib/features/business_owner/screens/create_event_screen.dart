import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/router/app_router.dart' show AppNavigation;
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/m_kit.dart';
import '../../../shared/widgets/m_step_form.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../auth/widgets/m_account_widgets.dart';
import '../data/owner_data.dart';

/// Create Event — a business publishes its own event (the client, TestFlight
/// 11 Oct: "no new design — the existing design language and what an event
/// needs"). The form is Create Deal's: the image box, the labelled cards, the
/// date cards, the button at the foot. With [eventId], the same form over an
/// existing event. Either way the event waits for the panel (00081).
class CreateEventScreen extends ConsumerStatefulWidget {
  final String? eventId;
  const CreateEventScreen({super.key, this.eventId});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

const _maxBytes = 10 * 1024 * 1024;
const _boxFill = Color(0xFFEFF5FD);
const _boxEdge = Color(0xFF7DA6DA);

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _title = TextEditingController();
  final _summary = TextEditingController();
  final _description = TextEditingController();
  final _venue = TextEditingController();
  final _address = TextEditingController();
  final _price = TextEditingController();
  final _ticket = TextEditingController();
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  bool _free = true;

  String? _imageUrl;
  ({String name, Uint8List bytes})? _picked;

  bool _loading = false;
  String? _loadError;
  bool _saving = false;
  bool _filledFromBusiness = false;

  bool get _editing => widget.eventId != null;

  @override
  void initState() {
    super.initState();
    if (_editing) _load();
  }

  @override
  void dispose() {
    for (final c in [_title, _summary, _description, _venue, _address, _price, _ticket]) {
      c.dispose();
    }
    super.dispose();
  }

  TimeOfDay? _time(String? hhmm) {
    final parts = (hhmm ?? '').split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    return h == null || m == null ? null : TimeOfDay(hour: h, minute: m);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final e = await ref.read(ownerRepositoryProvider).fetchEvent(widget.eventId!);
      if (!mounted) return;
      if (e == null) {
        setState(() {
          _loading = false;
          _loadError = mTr(context, 'This event no longer exists', 'האירוע הזה כבר לא קיים');
        });
        return;
      }
      final ev = e.event;
      setState(() {
        _filledFromBusiness = true;
        _title.text = ev.title;
        _summary.text = ev.shortDescription ?? '';
        _description.text = ev.fullDescription ?? '';
        _venue.text = ev.venueName ?? '';
        _address.text = ev.address;
        _free = ev.isFree;
        _price.text = ev.price ?? '';
        _ticket.text = ev.ticketUrl ?? '';
        _startDate = ev.startDate?.toLocal();
        _startTime = _time(ev.startTime);
        _endDate = ev.endDate?.toLocal();
        _endTime = _time(ev.endTime);
        _imageUrl = ev.imageUrl;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = mTr(context, 'Could not load the event', 'לא ניתן לטעון את האירוע');
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
    final current = start ? _startDate : _endDate;
    var first = start ? today : (_startDate ?? today);
    if (current != null && current.isBefore(first)) first = DateUtils.dateOnly(current);
    final initial = current ?? first;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : initial,
      firstDate: first,
      lastDate: today.add(const Duration(days: 2 * 365)),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) _endDate = null;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _pickTime({required bool start}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (start ? _startTime : _endTime) ?? const TimeOfDay(hour: 19, minute: 0),
    );
    if (picked == null) return;
    setState(() => start ? _startTime = picked : _endTime = picked);
  }

  String _dateIso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String _timeIso(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';
  String _timeLabel(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      mToast(context, mTr(context, 'Enter a name for the event', 'נא להזין שם לאירוע'), error: true);
      return;
    }
    if (_startDate == null) {
      mToast(context, mTr(context, 'Choose the date of the event', 'נא לבחור את תאריך האירוע'), error: true);
      return;
    }
    double? price;
    if (!_free) {
      price = double.tryParse(_price.text.trim().replaceAll(',', '.'));
      if (price == null || price <= 0) {
        mToast(context, mTr(context, 'Enter the price in shekels', 'נא להזין את המחיר בשקלים'), error: true);
        return;
      }
    }
    final ticket = _ticket.text.trim();
    if (ticket.isNotEmpty && !ticket.startsWith('http')) {
      mToast(context, mTr(context, 'The ticket link should start with https://', 'קישור הכרטיסים צריך להתחיל ב-https://'), error: true);
      return;
    }
    final business = ref.read(myBusinessProvider).valueOrNull;
    final businessId = ref.read(myBusinessIdProvider);
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
        // Under the business's own folder, where its owner may upload.
        imageUrl = await repo.upload(
          folder: 'businesses',
          businessId: businessId,
          fileName: _picked!.name,
          bytes: _picked!.bytes,
        );
      }
      final hasPlace = business != null && (business.latitude != 0 || business.longitude != 0);
      await repo.saveEvent(
        id: widget.eventId,
        row: {
          'business_id': businessId,
          'title': title,
          'short_description': orNull(_summary),
          'full_description': orNull(_description),
          'image_url': imageUrl,
          'start_date': _dateIso(_startDate!),
          'start_time': _startTime == null ? null : _timeIso(_startTime!),
          'end_date': _endDate == null ? null : _dateIso(_endDate!),
          'end_time': _endTime == null ? null : _timeIso(_endTime!),
          'is_all_day': _startTime == null,
          'venue_name': orNull(_venue),
          'address': orNull(_address),
          // On the map where the business is, unless the panel moves it.
          if (!_editing && hasPlace) 'latitude': business.latitude,
          if (!_editing && hasPlace) 'longitude': business.longitude,
          'is_free': _free,
          'price': _free ? null : price,
          'ticket_url': ticket.isEmpty ? null : ticket,
        },
      );
      ref.invalidate(myEventsProvider);
      if (!mounted) return;
      mToast(
        context,
        mTr(context, 'Sent for approval — it will appear once the team approves it.', 'נשלח לאישור — האירוע יופיע לאחר אישור הצוות.'),
      );
      context.back('/business-events');
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        mToast(context, mTr(context, 'Could not save the event. Try again.', 'שמירת האירוע נכשלה. נסו שוב.'), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // A new event starts at the business's own name and address.
    final business = ref.watch(myBusinessProvider).valueOrNull;
    if (!_editing && !_filledFromBusiness && business != null) {
      _filledFromBusiness = true;
      _venue.text = business.name;
      _address.text = business.address;
    }

    return MPage(
      title: _editing ? mTr(context, 'Edit Event', 'עריכת אירוע') : mTr(context, 'Create Event', 'יצירת אירוע'),
      bottom: _loading || _loadError != null
          ? null
          : MButton(
              label: mTr(context, 'Send for Approval', 'שליחה לאישור'),
              loading: _saving,
              onTap: _save,
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? MEmpty(icon: IconsaxPlusLinear.calendar, title: _loadError!)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _sectionLabel(mTr(context, 'Event Image', 'תמונת האירוע')),
                const SizedBox(height: 8),
                _imageBox(),
                const SizedBox(height: 20),
                MFormCard(
                  label: mTr(context, 'Event Name', 'שם האירוע'),
                  child: MInputRow(
                    placeholder: mTr(context, 'e.g. Live Jazz Evening', 'לדוגמה: ערב ג׳אז חי'),
                    controller: _title,
                  ),
                ),
                const SizedBox(height: 16),
                MFormCard(
                  label: mTr(context, 'In one line', 'במשפט אחד'),
                  child: MInputRow(
                    placeholder: mTr(context, 'What is it, and for whom?', 'מה זה, ולמי זה מתאים?'),
                    controller: _summary,
                  ),
                ),
                const SizedBox(height: 16),
                _multiLine(
                  mTr(context, 'Description', 'תיאור'),
                  _description,
                  mTr(context, 'Tell residents about the event...', 'ספרו לתושבים על האירוע...'),
                ),
                const SizedBox(height: 20),
                _sectionLabel(mTr(context, 'When', 'מתי')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _pickCard(mTr(context, 'Date', 'תאריך'), _startDate == null ? null : mDate(context, _startDate!), IconsaxPlusLinear.calendar_1, () => _pickDate(start: true))),
                    const SizedBox(width: 12),
                    Expanded(child: _pickCard(mTr(context, 'Start Time', 'שעת התחלה'), _startTime == null ? null : _timeLabel(_startTime!), IconsaxPlusLinear.clock, () => _pickTime(start: true))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _pickCard(mTr(context, 'End Date (optional)', 'תאריך סיום (לא חובה)'), _endDate == null ? null : mDate(context, _endDate!), IconsaxPlusLinear.calendar_1, () => _pickDate(start: false))),
                    const SizedBox(width: 12),
                    Expanded(child: _pickCard(mTr(context, 'End Time (optional)', 'שעת סיום (לא חובה)'), _endTime == null ? null : _timeLabel(_endTime!), IconsaxPlusLinear.clock, () => _pickTime(start: false))),
                  ],
                ),
                const SizedBox(height: 20),
                _sectionLabel(mTr(context, 'Where', 'איפה')),
                const SizedBox(height: 8),
                MFormCard(
                  label: mTr(context, 'Place', 'מקום'),
                  child: MInputRow(placeholder: mTr(context, 'Name of the place', 'שם המקום'), controller: _venue),
                ),
                const SizedBox(height: 12),
                MFormCard(
                  label: mTr(context, 'Address', 'כתובת'),
                  child: MInputRow(placeholder: mTr(context, 'Street and number', 'רחוב ומספר'), controller: _address),
                ),
                const SizedBox(height: 20),
                _sectionLabel(mTr(context, 'Entry', 'כניסה')),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsetsDirectional.fromSTEB(14, 6, 8, 6),
                  decoration: BoxDecoration(border: Border.all(color: mStepHairline), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Expanded(child: Text(mTr(context, 'Free entry', 'כניסה חופשית'), style: mText(14))),
                      MSwitch(value: _free, onChanged: (v) => setState(() => _free = v)),
                    ],
                  ),
                ),
                if (!_free) ...[
                  const SizedBox(height: 12),
                  MFormCard(
                    label: mTr(context, 'Price', 'מחיר'),
                    child: MInputRow(
                      placeholder: '50',
                      controller: _price,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      suffix: '₪',
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                MFormCard(
                  label: mTr(context, 'Tickets / registration link (optional)', 'קישור לכרטיסים / הרשמה (לא חובה)'),
                  child: MInputRow(placeholder: 'https://', controller: _ticket, keyboardType: TextInputType.url),
                ),
                const SizedBox(height: 16),
                Text(
                  mTr(
                    context,
                    'The team checks each event before it appears in the app; changes to a published event are checked again.',
                    'הצוות בודק כל אירוע לפני שהוא מופיע באפליקציה; שינוי באירוע שפורסם נבדק שוב.',
                  ),
                  style: mText(12.5, color: mStepGrey, height: 1.45),
                ),
              ],
            ),
    );
  }

  Widget _sectionLabel(String text) => Text(text, style: mText(14, weight: FontWeight.w500));

  Widget _pickCard(String label, String? value, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: MFormCard(
        label: label,
        child: SizedBox(
          height: 20,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value ?? mTr(context, 'Select', 'בחירה'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: mText(14, color: value == null ? mStepGrey : mStepInk),
                ),
              ),
              Icon(icon, size: 18, color: mStepGrey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageBox() {
    final hasImage = _picked != null || (_imageUrl ?? '').isNotEmpty;
    return GestureDetector(
      onTap: _pickImage,
      child: SizedBox(
        height: 160,
        child: hasImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _picked != null
                        ? Image.memory(_picked!.bytes, fit: BoxFit.cover)
                        : NetworkPhoto(url: _imageUrl!, height: 160, icon: IconsaxPlusBold.image),
                    PositionedDirectional(
                      end: 8,
                      bottom: 8,
                      child: Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(color: const Color(0x99000000), borderRadius: BorderRadius.circular(50)),
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

class _DashedBox extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _boxEdge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    const dash = 4.0;
    const gap = 3.0;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)));
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
