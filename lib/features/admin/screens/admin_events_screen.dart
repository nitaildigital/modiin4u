import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../events/models/event_labels.dart';
import '../providers/admin_events_provider.dart';
import '../widgets/admin_events_form_fields.dart';
import '../widgets/image_upload_field.dart';

class AdminEventsScreen extends ConsumerStatefulWidget {
  const AdminEventsScreen({super.key});

  @override
  ConsumerState<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends ConsumerState<AdminEventsScreen> {
  String _statusFilter = '';
  final _searchController = TextEditingController();
  final _debouncer = _Debouncer(milliseconds: 400);

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.cancel();
    super.dispose();
  }

  void _filter(String status) {
    setState(() => _statusFilter = status);
    ref
        .read(adminEventListProvider.notifier)
        .setStatusFilter(status.isEmpty ? null : status);
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(adminEventListProvider);
    final categories = ref.watch(adminEventCategoriesProvider).valueOrNull;
    final links = ref.watch(adminEventCategoryLinksProvider).valueOrNull;
    final isWide = MediaQuery.of(context).size.width > 900;

    final categoryNames = {
      for (final c in categories ?? const []) c.id: c.name,
    };

    return Column(
      children: [
        // ─── Toolbar ───
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: AppColors.border.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: isWide ? 320 : 200,
                height: 40,
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'חיפוש אירוע...',
                    hintStyle: TextStyle(
                      fontFamily: AppFonts.rubik,
                      fontSize: 13,
                      color: AppColors.grayLight,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 18,
                      color: AppColors.grayLight,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.turquoise),
                    ),
                  ),
                  onChanged: (v) => _debouncer.run(() {
                    ref
                        .read(adminEventListProvider.notifier)
                        .setSearch(v.isEmpty ? null : v);
                  }),
                ),
              ),
              const SizedBox(width: 12),
              _FilterChip('הכל', _statusFilter.isEmpty, () => _filter('')),
              _FilterChip(
                'פורסם',
                _statusFilter == 'published',
                () => _filter('published'),
              ),
              _FilterChip(
                'טיוטה',
                _statusFilter == 'draft',
                () => _filter('draft'),
              ),
              _FilterChip(
                'ממתין',
                _statusFilter == 'pending',
                () => _filter('pending'),
              ),
              _FilterChip(
                'בוטל',
                _statusFilter == 'cancelled',
                () => _filter('cancelled'),
              ),
              const Spacer(),
              eventsAsync
                      .whenData(
                        (list) => Text(
                          '${list.length} אירועים',
                          style: TextStyle(
                            fontFamily: AppFonts.rubik,
                            fontSize: 13,
                            color: AppColors.grayText,
                          ),
                        ),
                      )
                      .value ??
                  const SizedBox.shrink(),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: () => _showEventEditor(context),
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  'אירוע חדש',
                  style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.turquoise,
                  minimumSize: const Size(0, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ─── Table ───
        Expanded(
          child: eventsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'שגיאה בטעינת אירועים',
                    style: TextStyle(
                      fontFamily: AppFonts.rubik,
                      color: AppColors.error,
                    ),
                  ),
                  Text(
                    '$e',
                    style: TextStyle(
                      fontFamily: AppFonts.rubik,
                      fontSize: 12,
                      color: AppColors.grayText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () =>
                        ref.read(adminEventListProvider.notifier).load(),
                    child: const Text('נסה שוב'),
                  ),
                ],
              ),
            ),
            data: (events) {
              if (events.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.event_outlined,
                        size: 48,
                        color: AppColors.grayLight.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'אין אירועים',
                        style: TextStyle(
                          fontFamily: AppFonts.rubik,
                          color: AppColors.grayText,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return _EventTable(
                events: events,
                isWide: isWide,
                categoriesOf: (id) => [
                  for (final c in links?[id] ?? const <String>[])
                    if (categoryNames[c] != null) categoryNames[c]!,
                ],
                onTap: (ev) => _showEventEditor(context, event: ev),
                onAction: _handleAction,
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('שגיאה: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  void _handleAction(String action, Map<String, dynamic> event) {
    final notifier = ref.read(adminEventListProvider.notifier);
    final id = event['id'] as String;
    switch (action) {
      case 'edit':
        _showEventEditor(context, event: event);
      case 'publish':
        _run(() => notifier.publish(id, publishedAt: event['published_at']));
      case 'draft':
        _run(() => notifier.updateStatus(id, 'draft'));
      case 'cancel':
        _run(() => notifier.updateStatus(id, 'cancelled'));
      case 'delete':
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(
              'מחיקת אירוע',
              style: TextStyle(
                fontFamily: AppFonts.rubik,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              'לבטל את "${event['title']}"? האירוע ירד מהאפליקציה '
              'וניתן יהיה להחזירו על ידי שינוי הסטטוס.',
              style: TextStyle(fontFamily: AppFonts.rubik),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'ביטול',
                  style: TextStyle(fontFamily: AppFonts.rubik),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _run(() => notifier.deleteEvent(id));
                },
                child: Text(
                  'מחק',
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }

  void _showEventEditor(BuildContext context, {Map<String, dynamic>? event}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _EventEditorDialog(event: event),
    );
  }
}

// ─── Event Table ───

/// A numeric column's value, whether it arrived as a number or as text.
num? _num(Object? v) => v is num ? v : num.tryParse('${v ?? ''}');

/// "2026-09-15" → "15.09.2026".
String _displayDate(Object? value) {
  final d = value is String ? DateTime.tryParse(value) : null;
  if (d == null) return '';
  return '${d.day.toString().padLeft(2, '0')}.'
      '${d.month.toString().padLeft(2, '0')}.${d.year}';
}

class _EventTable extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  final bool isWide;
  final List<String> Function(String id) categoriesOf;
  final void Function(Map<String, dynamic>) onTap;
  final void Function(String, Map<String, dynamic>) onAction;
  const _EventTable({
    required this.events,
    required this.isWide,
    required this.categoriesOf,
    required this.onTap,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            border: Border(
              bottom: BorderSide(
                color: AppColors.border.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Row(
            children: [
              _Col('שם אירוע', flex: 3),
              _Col('תאריך', flex: 2),
              if (isWide) _Col('מיקום', flex: 2),
              _Col('קטגוריה', flex: 2),
              _Col('סטטוס', flex: 1),
              if (isWide) _Col('מתעניינים', flex: 1),
              const SizedBox(width: 40),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: events.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: AppColors.border.withValues(alpha: 0.3),
            ),
            itemBuilder: (_, i) {
              final ev = events[i];
              final id = ev['id'] as String;
              final status = ev['status'] as String? ?? 'draft';
              final rsvps = (ev['rsvp_count'] as num?)?.toInt() ?? 0;
              final capacity = (ev['max_attendees'] as num?)?.toInt();
              final isFeatured = ev['is_featured'] as bool? ?? false;
              final isFree = ev['is_free'] as bool? ?? false;
              // `price` is numeric(10,2): it arrives as a number, not text.
              final price = _num(ev['price']);
              final isAllDay = ev['is_all_day'] as bool? ?? false;
              final start = adminTimeFromDb(ev['start_time']);
              final end = adminTimeFromDb(ev['end_time']);
              final endDate = _displayDate(ev['end_date']);
              final startDate = _displayDate(ev['start_date']);
              final venue =
                  [
                    ev['venue_name'] as String?,
                    ev['address'] as String?,
                  ].firstWhere(
                    (v) => (v ?? '').trim().isNotEmpty,
                    orElse: () => '',
                  );
              final cats = categoriesOf(id);

              return InkWell(
                onTap: () => onTap(ev),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (isFeatured)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: Icon(
                                      Icons.star,
                                      size: 14,
                                      color: AppColors.gold,
                                    ),
                                  ),
                                if (isFree)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.success.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        'חינם',
                                        style: TextStyle(
                                          fontFamily: AppFonts.rubik,
                                          fontSize: 9,
                                          color: AppColors.success,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                Flexible(
                                  child: Text(
                                    ev['title'] as String? ?? '',
                                    style: TextStyle(
                                      fontFamily: AppFonts.rubik,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.navy,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (!isFree && price != null)
                              Text(
                                '₪${price == price.truncate() ? price.toInt() : price}',
                                style: TextStyle(
                                  fontFamily: AppFonts.rubik,
                                  fontSize: 11,
                                  color: AppColors.grayLight,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              endDate.isNotEmpty && endDate != startDate
                                  ? '$startDate – $endDate'
                                  : startDate,
                              style: TextStyle(
                                fontFamily: AppFonts.rubik,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              isAllDay
                                  ? 'כל היום'
                                  : end.isNotEmpty
                                  ? '$start–$end'
                                  : start,
                              style: TextStyle(
                                fontFamily: AppFonts.rubik,
                                fontSize: 11,
                                color: AppColors.grayLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isWide)
                        Expanded(
                          flex: 2,
                          child: Text(
                            (ev['is_online'] as bool? ?? false)
                                ? 'אונליין'
                                : venue ?? '',
                            style: TextStyle(
                              fontFamily: AppFonts.rubik,
                              fontSize: 12,
                              color: AppColors.grayText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          cats.isEmpty ? '—' : cats.join(', '),
                          style: TextStyle(
                            fontFamily: AppFonts.rubik,
                            fontSize: 12,
                            color: cats.isEmpty
                                ? AppColors.grayLight
                                : AppColors.grayText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(flex: 1, child: _StatusPill(status)),
                      if (isWide)
                        Expanded(
                          flex: 1,
                          child: Text(
                            capacity != null && capacity > 0
                                ? '$rsvps/$capacity'
                                : '$rsvps',
                            style: TextStyle(
                              fontFamily: AppFonts.rubik,
                              fontSize: 13,
                              color: AppColors.grayText,
                            ),
                          ),
                        ),
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert,
                          size: 18,
                          color: AppColors.grayLight,
                        ),
                        onSelected: (v) => onAction(v, ev),
                        itemBuilder: (_) => [
                          _menuItem('edit', 'עריכה'),
                          if (status != 'published')
                            _menuItem('publish', 'פרסם'),
                          if (status != 'draft')
                            _menuItem('draft', 'החזר לטיוטה'),
                          if (status != 'cancelled')
                            _menuItem('cancel', 'בטל אירוע'),
                          _menuItem(
                            'delete',
                            // The row is not removed; it becomes status = 'cancelled'.
                            'בטל',
                            color: AppColors.error,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(String value, String label, {Color? color}) {
    return PopupMenuItem(
      value: value,
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppFonts.rubik,
          fontSize: 13,
          color: color,
        ),
      ),
    );
  }
}

// ─── "What's included" ───
//
// `events` has no column for it. The website reads it out of the full
// description: a paragraph whose first line is "מה כלול:" and whose other
// lines each start with "•" (see [EventDescription]). The editor keeps it in a
// field of its own and writes it back in that form, so nobody has to know the
// convention to fill it in.

final _leadingBullet = RegExp(r'^[•·\-\*–]\s*');

/// The items as typed, one per line, without any bullet the editor typed.
List<String> _includedItems(String text) => text
    .split('\n')
    .map((l) => l.trim().replaceFirst(_leadingBullet, '').trim())
    .where((l) => l.isNotEmpty)
    .toList();

/// The body and the list, as one `full_description`. Null when both are
/// empty.
String? _composeFullDescription(String body, String included) {
  final b = body.trim();
  final items = _includedItems(included);
  final parts = [
    if (b.isNotEmpty) b,
    if (items.isNotEmpty) 'מה כלול:\n${items.map((i) => '• $i').join('\n')}',
  ];
  return parts.isEmpty ? null : parts.join('\n\n');
}

// ─── Event Editor Dialog ───

class _EventEditorDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? event;
  const _EventEditorDialog({this.event});

  @override
  ConsumerState<_EventEditorDialog> createState() => _EventEditorDialogState();
}

class _EventEditorDialogState extends ConsumerState<_EventEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  /// Set once a new event has been inserted, so that a retry after a failed
  /// category step updates it rather than inserting a second copy.
  String? _savedId;

  late final TextEditingController _title;
  late final TextEditingController _shortDescription;
  late final TextEditingController _body;
  late final TextEditingController _included;
  late final TextEditingController _image;
  late final TextEditingController _startDate;
  late final TextEditingController _startTime;
  late final TextEditingController _endDate;
  late final TextEditingController _endTime;
  late final TextEditingController _venue;
  late final TextEditingController _address;
  late final TextEditingController _latitude;
  late final TextEditingController _longitude;
  late final TextEditingController _waze;
  late final TextEditingController _onlineUrl;
  late final TextEditingController _price;
  late final TextEditingController _ticketUrl;
  late final TextEditingController _maxAttendees;

  /// The description as it was opened, split the way it is shown — to tell
  /// whether it was edited. An untouched one is saved exactly as it was
  /// rather than re-assembled.
  late final String _initialBody;
  late final String _initialIncluded;

  String _status = 'draft';
  bool _isAllDay = false;
  bool _isOnline = false;
  bool _isFree = false;
  bool _isSoldOut = false;
  bool _isFeatured = false;
  String? _businessId;

  /// The categories in the order picked; the first is the primary. Null until
  /// the event's current links have loaded.
  List<String>? _categoryIds;
  List<String>? _initialCategoryIds;

  bool get _isEditing => widget.event != null || _savedId != null;
  String? get _id => widget.event?['id'] as String? ?? _savedId;

  static const _statuses = {
    'draft': 'טיוטה',
    'pending': 'ממתין לאישור',
    'published': 'פורסם',
    'cancelled': 'בוטל',
    'past': 'הסתיים',
  };

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    String text(String key) => (e?[key] as String?) ?? '';
    String number(String key) {
      final v = _num(e?[key]);
      if (v == null) return '';
      return v == v.truncate() ? '${v.toInt()}' : '$v';
    }

    final described = EventDescription.parse(e?['full_description'] as String?);
    _initialBody = described.paragraphs.join('\n\n');
    _initialIncluded = described.included.join('\n');

    _title = TextEditingController(text: text('title'));
    _shortDescription = TextEditingController(text: text('short_description'));
    _body = TextEditingController(text: _initialBody);
    _included = TextEditingController(text: _initialIncluded);
    _image = TextEditingController(text: text('image_url'));
    _startDate = TextEditingController(text: text('start_date'));
    _startTime = TextEditingController(text: adminTimeFromDb(e?['start_time']));
    _endDate = TextEditingController(text: text('end_date'));
    _endTime = TextEditingController(text: adminTimeFromDb(e?['end_time']));
    _venue = TextEditingController(text: text('venue_name'));
    _address = TextEditingController(text: text('address'));
    _latitude = TextEditingController(text: number('latitude'));
    _latitudeBefore = _latitude.text;
    _longitude = TextEditingController(text: number('longitude'));
    _waze = TextEditingController(text: text('waze_url'));
    _onlineUrl = TextEditingController(text: text('online_url'));
    _price = TextEditingController(text: number('price'));
    _ticketUrl = TextEditingController(text: text('ticket_url'));
    _maxAttendees = TextEditingController(text: number('max_attendees'));

    _status = e?['status'] as String? ?? 'draft';
    if (!_statuses.containsKey(_status)) _status = 'draft';
    _isAllDay = e?['is_all_day'] as bool? ?? false;
    _isOnline = e?['is_online'] as bool? ?? false;
    // A new event is not assumed free: the column defaults to true, and an
    // event saved without anyone deciding would read "חינם" on the site.
    _isFree = e?['is_free'] as bool? ?? false;
    _isSoldOut = e?['is_sold_out'] as bool? ?? false;
    _isFeatured = e?['is_featured'] as bool? ?? false;
    _businessId = e?['business_id'] as String?;

    if (e == null) {
      _categoryIds = [];
      _initialCategoryIds = [];
    }
  }

  @override
  void dispose() {
    for (final c in [
      _title,
      _shortDescription,
      _body,
      _included,
      _image,
      _startDate,
      _startTime,
      _endDate,
      _endTime,
      _venue,
      _address,
      _latitude,
      _longitude,
      _waze,
      _onlineUrl,
      _price,
      _ticketUrl,
      _maxAttendees,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Takes the event's current categories once they have loaded.
  void _adoptLinks(Map<String, List<String>>? links) {
    if (_categoryIds != null || links == null) return;
    final current = List<String>.from(links[_id] ?? const <String>[]);
    _categoryIds = current;
    _initialCategoryIds = List.of(current);
  }

  InputDecoration _decoration(String label, {String? hint, String? helper}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      helperMaxLines: 2,
      labelStyle: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
      helperStyle: TextStyle(
        fontFamily: AppFonts.rubik,
        fontSize: 11,
        color: AppColors.grayLight,
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  @override
  Widget build(BuildContext context) {
    final links = ref.watch(adminEventCategoryLinksProvider);
    _adoptLinks(links.valueOrNull);

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 860),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _isEditing ? 'עריכת אירוע' : 'אירוע חדש',
                        style: TextStyle(
                          fontFamily: AppFonts.rubik,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // ── What ──
                      _section('פרטי האירוע'),
                      _field(
                        _title,
                        _decoration('שם אירוע *'),
                        validator: (v) =>
                            (v ?? '').trim().isEmpty ? 'שדה חובה' : null,
                      ),
                      _field(
                        _shortDescription,
                        _decoration(
                          'תיאור קצר',
                          helper: 'משפט או שניים. מוצג באתר כשאין תיאור מלא.',
                        ),
                        maxLines: 2,
                      ),
                      _field(
                        _body,
                        _decoration(
                          'תיאור מלא',
                          helper:
                              'מוצג תחת "אודות האירוע". שורה ריקה מפרידה בין פסקאות.',
                        ),
                        maxLines: 6,
                      ),
                      _field(
                        _included,
                        _decoration(
                          'מה כלול',
                          hint: 'הופעה חיה\nכיבוד קל\nחניה חופשית',
                          helper:
                              'פריט אחד בכל שורה. מוצג באתר כרשימת סימונים תחת '
                              '"מה כלול"; ריק — החלק לא יוצג.',
                        ),
                        maxLines: 5,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ImageUploadField(
                          label: 'תמונה',
                          controller: _image,
                          folder: 'events',
                        ),
                      ),
                      _categoriesField(links),

                      // ── When ──
                      _section('מועד'),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _padded(
                              AdminDateField(
                                controller: _startDate,
                                decoration: _decoration('תאריך התחלה *'),
                                required: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _padded(
                              AdminTimeField(
                                controller: _startTime,
                                decoration: _decoration('שעת התחלה'),
                                enabled: !_isAllDay,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _padded(
                              AdminDateField(
                                controller: _endDate,
                                decoration: _decoration(
                                  'תאריך סיום',
                                  helper: 'רק לאירוע של יותר מיום אחד',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _padded(
                              AdminTimeField(
                                controller: _endTime,
                                decoration: _decoration('שעת סיום'),
                                enabled: !_isAllDay,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _toggle(
                            'כל היום',
                            _isAllDay,
                            (v) => setState(() => _isAllDay = v),
                          ),
                        ],
                      ),

                      // ── Where ──
                      _section('מיקום'),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _field(
                              _venue,
                              _decoration('שם המקום', hint: 'היכל התרבות'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: TextButton.icon(
                              onPressed: _fillFromBusiness,
                              icon: const Icon(
                                Icons.storefront_outlined,
                                size: 16,
                              ),
                              label: Text(
                                'מילוי מעסק',
                                style: TextStyle(
                                  fontFamily: AppFonts.rubik,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      _field(_address, _decoration('כתובת')),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _field(
                              _latitude,
                              _decoration(
                                'קו רוחב',
                                hint: '31.8969',
                                helper:
                                    'אפשר להדביק כאן "31.89, 35.01" מגוגל מפות',
                              ),
                              ltr: true,
                              onChanged: _splitPastedCoordinates,
                              validator: (v) => _coordinate(v, 90),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              _longitude,
                              _decoration(
                                'קו אורך',
                                hint: '35.0095',
                                helper: 'בלי נקודה — אין מפה ואין ניווט באתר',
                              ),
                              ltr: true,
                              validator: (v) => _coordinate(v, 180),
                            ),
                          ),
                        ],
                      ),
                      _field(
                        _waze,
                        _decoration(
                          'קישור Waze',
                          hint: 'https://waze.com/ul?...',
                          helper: 'אם ריק, כפתור הניווט באתר ישתמש בנקודה',
                        ),
                        ltr: true,
                        validator: _url,
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _toggle(
                            'אירוע אונליין',
                            _isOnline,
                            (v) => setState(() => _isOnline = v),
                          ),
                        ],
                      ),
                      if (_isOnline) ...[
                        const SizedBox(height: 8),
                        _field(
                          _onlineUrl,
                          _decoration('קישור לשידור', hint: 'https://'),
                          ltr: true,
                          validator: _url,
                        ),
                      ],

                      // ── Tickets ──
                      _section('כרטיסים'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _toggle(
                            'כניסה חופשית',
                            _isFree,
                            (v) => setState(() => _isFree = v),
                          ),
                          _toggle(
                            'אזלו הכרטיסים',
                            _isSoldOut,
                            (v) => setState(() => _isSoldOut = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _field(
                              _price,
                              _decoration(
                                'מחיר (₪)',
                                hint: '50',
                                helper: _isFree ? 'האירוע מסומן חינם' : null,
                              ),
                              ltr: true,
                              enabled: !_isFree,
                              validator: _priceValidator,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              _maxAttendees,
                              _decoration('מספר משתתפים מרבי', hint: '100'),
                              ltr: true,
                              validator: _positiveInt,
                            ),
                          ),
                        ],
                      ),
                      _field(
                        _ticketUrl,
                        _decoration('קישור לרכישת כרטיסים', hint: 'https://'),
                        ltr: true,
                        validator: _url,
                      ),

                      // ── Who ──
                      _section('מארגן'),
                      _padded(
                        AdminBusinessPickerField(
                          label: 'העסק המארגן',
                          businessId: _businessId,
                          onChanged: (b) => setState(() => _businessId = b?.id),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12, right: 4),
                        child: Text(
                          'מוצג בעמוד האירוע בכרטיס "מאורגן על ידי". ריק — הכרטיס לא יוצג.',
                          style: TextStyle(
                            fontFamily: AppFonts.rubik,
                            fontSize: 11,
                            color: AppColors.grayLight,
                          ),
                        ),
                      ),

                      // ── Status ──
                      _section('פרסום'),
                      DropdownButtonFormField<String>(
                        initialValue: _status,
                        decoration: _decoration('סטטוס'),
                        items: [
                          for (final s in _statuses.entries)
                            DropdownMenuItem(
                              value: s.key,
                              child: Text(
                                s.value,
                                style: TextStyle(
                                  fontFamily: AppFonts.rubik,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                        ],
                        onChanged: (v) => setState(() => _status = v!),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 6, right: 4),
                        child: Text(
                          _publishedNote(),
                          style: TextStyle(
                            fontFamily: AppFonts.rubik,
                            fontSize: 11,
                            color: AppColors.grayLight,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _toggle(
                            'מומלץ',
                            _isFeatured,
                            (v) => setState(() => _isFeatured = v),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'ביטול',
                          style: TextStyle(fontFamily: AppFonts.rubik),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.turquoise,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isEditing ? 'שמור' : 'צור אירוע',
                                style: TextStyle(
                                  fontFamily: AppFonts.rubik,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _publishedNote() {
    final at = DateTime.tryParse(
      widget.event?['published_at'] as String? ?? '',
    );
    if (at != null) {
      final l = at.toLocal();
      return 'פורסם לראשונה ${_displayDate(formatAdminDate(l))} '
          '${formatAdminTime(l.hour, l.minute)} — המיון "החדשים" באתר לפיו.';
    }
    return 'תאריך הפרסום יירשם בשמירה הראשונה בסטטוס "פורסם".';
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: AppFonts.rubik,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.navy,
        ),
      ),
    );
  }

  Widget _padded(Widget child) =>
      Padding(padding: const EdgeInsets.only(bottom: 12), child: child);

  Widget _field(
    TextEditingController controller,
    InputDecoration decoration, {
    int maxLines = 1,
    bool ltr = false,
    bool enabled = true,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        enabled: enabled,
        validator: enabled ? validator : null,
        onChanged: onChanged,
        textDirection: ltr ? TextDirection.ltr : null,
        style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
        decoration: decoration,
      ),
    );
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 12),
      ),
      selected: value,
      onSelected: onChanged,
      selectedColor: AppColors.turquoise.withValues(alpha: 0.15),
      checkmarkColor: AppColors.turquoise,
      side: BorderSide(color: value ? AppColors.turquoise : AppColors.border),
    );
  }

  Widget _categoriesField(AsyncValue<Map<String, List<String>>> links) {
    final categories = ref.watch(adminEventCategoriesProvider);
    final selected = _categoryIds;

    Widget body;
    if (links.hasError || categories.hasError) {
      body = Text(
        'לא ניתן לטעון את הקטגוריות: ${links.error ?? categories.error}',
        style: TextStyle(
          fontFamily: AppFonts.rubik,
          fontSize: 12,
          color: AppColors.error,
        ),
      );
    } else if (selected == null || !categories.hasValue) {
      body = const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else {
      final all = categories.value!;
      body = Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final c in all)
            if (c.isActive || selected.contains(c.id))
              FilterChip(
                label: Text(
                  [
                    c.name,
                    if (selected.isNotEmpty && selected.first == c.id)
                      '(ראשית)',
                    if (!c.isActive) '(לא פעילה)',
                  ].join(' '),
                  style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 12),
                ),
                selected: selected.contains(c.id),
                onSelected: (on) => setState(() {
                  if (on) {
                    selected.add(c.id);
                  } else {
                    selected.remove(c.id);
                  }
                }),
                selectedColor: AppColors.turquoise.withValues(alpha: 0.15),
                checkmarkColor: AppColors.turquoise,
                side: BorderSide(
                  color: selected.contains(c.id)
                      ? AppColors.turquoise
                      : AppColors.border,
                ),
              ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'קטגוריות',
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontSize: 12,
              color: AppColors.adminTextMedium,
            ),
          ),
          const SizedBox(height: 6),
          body,
          const SizedBox(height: 4),
          Text(
            'הקטגוריה הראשונה שנבחרה היא הראשית — היא מוצגת על כרטיס האירוע.',
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontSize: 11,
              color: AppColors.grayLight,
            ),
          ),
        ],
      ),
    );
  }

  /// Copies a business's name, address and map point into the venue.
  Future<void> _fillFromBusiness() async {
    final b = await showAdminBusinessPicker(context);
    if (b == null || !mounted) return;
    setState(() {
      _venue.text = b.name;
      if ((b.address ?? '').trim().isNotEmpty) _address.text = b.address!;
      if (b.latitude != null && b.longitude != null) {
        _latitude.text = '${b.latitude}';
        _longitude.text = '${b.longitude}';
        _latitudeBefore = _latitude.text;
      }
    });
  }

  /// "31.8969, 35.0095" → both numbers, or null when it is not such a pair.
  static ({double lat, double lng})? _coordinatePair(String text) {
    final parts = text.split(',');
    if (parts.length != 2) return null;
    final lat = double.tryParse(parts[0].trim());
    final lng = double.tryParse(parts[1].trim());
    if (lat == null || lng == null || lat.abs() > 90 || lng.abs() > 180) {
      return null;
    }
    return (lat: lat, lng: lng);
  }

  String _latitudeBefore = '';

  /// Google Maps copies a point as "31.8969, 35.0095"; pasted into the first
  /// box, it is split across the two.
  ///
  /// Only on a paste — text arriving several characters at once. Split on
  /// every keystroke, someone typing the pair by hand would be cut off at
  /// "31.8969, 3" and the rest would land in the wrong box. A typed pair is
  /// split on save instead.
  void _splitPastedCoordinates(String v) {
    final pasted = v.length - _latitudeBefore.length > 1;
    _latitudeBefore = v;
    if (!pasted) return;
    final pair = _coordinatePair(v);
    if (pair == null) return;
    _latitude.text = '${pair.lat}';
    _longitude.text = '${pair.lng}';
    _latitudeBefore = _latitude.text;
  }

  String? _coordinate(String? v, double limit) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return null;
    if (limit == 90 && _coordinatePair(t) != null) return null;
    final n = double.tryParse(t);
    if (n == null || n.abs() > limit) return 'מספר לא תקין';
    return null;
  }

  String? _url(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return null;
    return t.startsWith('http://') || t.startsWith('https://')
        ? null
        : 'קישור מלא, מתחיל ב-https://';
  }

  String? _priceValidator(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return null;
    final n = num.tryParse(t.replaceAll('₪', '').trim());
    return n == null || n < 0 ? 'מספר בלבד, למשל 50' : null;
  }

  String? _positiveInt(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return null;
    final n = int.tryParse(t);
    return n == null || n <= 0 ? 'מספר שלם חיובי' : null;
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    String? nullIfEmpty(TextEditingController c) {
      final t = c.text.trim();
      return t.isEmpty ? null : t;
    }

    final start = parseAdminDate(_startDate.text)!;
    final end = parseAdminDate(_endDate.text);
    if (end != null && end.isBefore(start)) {
      _toast('תאריך הסיום לפני תאריך ההתחלה');
      return;
    }
    final pair = _coordinatePair(_latitude.text);
    final lat = pair?.lat ?? double.tryParse(_latitude.text.trim());
    final lng = pair?.lng ?? double.tryParse(_longitude.text.trim());
    if ((lat == null) != (lng == null)) {
      _toast('יש למלא גם קו רוחב וגם קו אורך, או להשאיר את שניהם ריקים');
      return;
    }

    // Only re-assembled when edited: an untouched description is written back
    // exactly as it was, whatever spacing or heading it used.
    final descriptionEdited =
        _body.text != _initialBody || _included.text != _initialIncluded;
    final fullDescription = descriptionEdited
        ? _composeFullDescription(_body.text, _included.text)
        : widget.event?['full_description'] as String?;

    final publishedAt = widget.event?['published_at'];
    final fields = <String, dynamic>{
      'title': _title.text.trim(),
      'short_description': nullIfEmpty(_shortDescription),
      'full_description': fullDescription,
      'image_url': nullIfEmpty(_image),
      'start_date': formatAdminDate(start),
      'start_time': _isAllDay ? null : nullIfEmpty(_startTime),
      'end_date': end == null ? null : formatAdminDate(end),
      'end_time': _isAllDay ? null : nullIfEmpty(_endTime),
      'is_all_day': _isAllDay,
      'venue_name': nullIfEmpty(_venue),
      'address': nullIfEmpty(_address),
      'latitude': lat,
      'longitude': lng,
      'waze_url': nullIfEmpty(_waze),
      'is_online': _isOnline,
      'online_url': _isOnline ? nullIfEmpty(_onlineUrl) : null,
      'is_free': _isFree,
      'price': _isFree
          ? null
          : num.tryParse(_price.text.replaceAll('₪', '').trim()),
      'ticket_url': nullIfEmpty(_ticketUrl),
      'is_sold_out': _isSoldOut,
      'max_attendees': int.tryParse(_maxAttendees.text.trim()),
      'business_id': _businessId,
      'status': _status,
      'is_featured': _isFeatured,
      // Stamped the first time it goes out, and never moved after: the site's
      // "Newest" sort reads it.
      if (_status == 'published' && publishedAt == null)
        'published_at': DateTime.now().toUtc().toIso8601String(),
    };

    final cats = _categoryIds;
    final catsChanged =
        cats != null &&
        (_initialCategoryIds == null ||
            cats.length != _initialCategoryIds!.length ||
            [
              for (var i = 0; i < cats.length; i++)
                cats[i] == _initialCategoryIds![i],
            ].contains(false));

    setState(() => _saving = true);
    final notifier = ref.read(adminEventListProvider.notifier);
    try {
      await notifier.saveEvent(
        id: _id,
        fields: fields,
        // A new event always writes its (possibly empty) set; an edit only
        // when it changed.
        categoryIds: _id == null || catsChanged ? cats : null,
        onCreated: (id) => _savedId = id,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) _toast('שגיאה: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ─── Shared Widgets ───

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill(this.status);

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'published' => ('פורסם', AppColors.success),
      'draft' => ('טיוטה', AppColors.gold),
      'pending' => ('ממתין', AppColors.turquoise),
      'cancelled' => ('בוטל', AppColors.error),
      'past' => ('הסתיים', AppColors.grayText),
      _ => (status, AppColors.grayLight),
    };
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _Col extends StatelessWidget {
  final String label;
  final int flex;
  const _Col(this.label, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppFonts.rubik,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.grayLight,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(this.label, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.turquoise.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected ? AppColors.turquoise : AppColors.border,
              width: 0.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? AppColors.turquoise : AppColors.grayText,
            ),
          ),
        ),
      ),
    );
  }
}

/// Runs the search once typing pauses. The previous one fired a query for
/// every keystroke, each 400ms late, and the answers could land out of order.
class _Debouncer {
  final int milliseconds;
  _Debouncer({required this.milliseconds});
  Timer? _timer;
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void cancel() => _timer?.cancel();
}
