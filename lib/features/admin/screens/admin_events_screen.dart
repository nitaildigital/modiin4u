import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/admin_events_provider.dart';

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(adminEventListProvider);
    final isWide = MediaQuery.of(context).size.width > 900;

    return Column(children: [
      // ─── Toolbar ───
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
        ),
        child: Row(children: [
          SizedBox(
            width: isWide ? 320 : 200,
            height: 40,
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.rubik(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'חיפוש אירוע...',
                hintStyle: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayLight),
                prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.grayLight),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.turquoise)),
              ),
              onChanged: (v) => _debouncer.run(() {
                ref.read(adminEventListProvider.notifier).setSearch(v.isEmpty ? null : v);
              }),
            ),
          ),
          const SizedBox(width: 12),
          _FilterChip('הכל', _statusFilter.isEmpty, () {
            setState(() => _statusFilter = '');
            ref.read(adminEventListProvider.notifier).setStatusFilter(null);
          }),
          _FilterChip('פורסם', _statusFilter == 'published', () {
            setState(() => _statusFilter = 'published');
            ref.read(adminEventListProvider.notifier).setStatusFilter('published');
          }),
          _FilterChip('טיוטה', _statusFilter == 'draft', () {
            setState(() => _statusFilter = 'draft');
            ref.read(adminEventListProvider.notifier).setStatusFilter('draft');
          }),
          _FilterChip('בוטל', _statusFilter == 'cancelled', () {
            setState(() => _statusFilter = 'cancelled');
            ref.read(adminEventListProvider.notifier).setStatusFilter('cancelled');
          }),
          const Spacer(),
          eventsAsync.whenData((list) => Text('${list.length} אירועים', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText))).value ?? const SizedBox.shrink(),
          const SizedBox(width: 16),
          FilledButton.icon(
            onPressed: () => _showEventEditor(context, ref),
            icon: const Icon(Icons.add, size: 18),
            label: Text('אירוע חדש', style: GoogleFonts.rubik(fontSize: 13)),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.turquoise,
              minimumSize: const Size(0, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ]),
      ),

      // ─── Table ───
      Expanded(
        child: eventsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text('שגיאה בטעינת אירועים', style: GoogleFonts.rubik(color: AppColors.error)),
            Text('$e', style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayText)),
            const SizedBox(height: 12),
            TextButton(onPressed: () => ref.read(adminEventListProvider.notifier).load(), child: const Text('נסה שוב')),
          ])),
          data: (events) {
            if (events.isEmpty) {
              return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.event_outlined, size: 48, color: AppColors.grayLight.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text('אין אירועים', style: GoogleFonts.rubik(color: AppColors.grayText)),
              ]));
            }
            return _EventTable(events: events, isWide: isWide, onTap: (ev) => _showEventEditor(context, ref, event: ev), onAction: _handleAction);
          },
        ),
      ),
    ]);
  }

  void _handleAction(String action, Map<String, dynamic> event) {
    final notifier = ref.read(adminEventListProvider.notifier);
    final id = event['id'] as String;
    switch (action) {
      case 'edit':
        _showEventEditor(context, ref, event: event);
      case 'publish':
        notifier.updateStatus(id, 'published');
      case 'draft':
        notifier.updateStatus(id, 'draft');
      case 'cancel':
        notifier.updateStatus(id, 'cancelled');
      case 'delete':
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('מחיקת אירוע', style: GoogleFonts.rubik(fontWeight: FontWeight.w700)),
            content: Text('למחוק את "${event['title']}"?', style: GoogleFonts.rubik()),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text('ביטול', style: GoogleFonts.rubik())),
              TextButton(onPressed: () { Navigator.pop(ctx); notifier.deleteEvent(id); }, child: Text('מחק', style: GoogleFonts.rubik(color: AppColors.error))),
            ],
          ),
        );
    }
  }

  void _showEventEditor(BuildContext context, WidgetRef ref, {Map<String, dynamic>? event}) {
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => _EventEditorDialog(event: event));
  }
}

// ─── Event Table ───

class _EventTable extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  final bool isWide;
  final void Function(Map<String, dynamic>) onTap;
  final void Function(String, Map<String, dynamic>) onAction;
  const _EventTable({required this.events, required this.isWide, required this.onTap, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(color: AppColors.surfaceLight, border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5)))),
        child: Row(children: [
          _Col('שם אירוע', flex: 3),
          _Col('תאריך', flex: 2),
          if (isWide) _Col('מיקום', flex: 2),
          _Col('קטגוריה', flex: 1),
          _Col('סטטוס', flex: 1),
          if (isWide) _Col('נרשמים', flex: 1),
          const SizedBox(width: 40),
        ]),
      ),
      Expanded(
        child: ListView.separated(
          itemCount: events.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.border.withValues(alpha: 0.3)),
          itemBuilder: (_, i) {
            final ev = events[i];
            final status = ev['status'] as String? ?? 'draft';
            final registered = ev['registered_count'] as int? ?? 0;
            final capacity = ev['max_capacity'] as int? ?? 0;
            final isFeatured = ev['is_featured'] as bool? ?? false;
            final isFree = ev['is_free'] as bool? ?? false;

            return InkWell(
              onTap: () => onTap(ev),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(children: [
                  Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      if (isFeatured) Padding(padding: const EdgeInsets.only(left: 4), child: Icon(Icons.star, size: 14, color: AppColors.gold)),
                      if (isFree) Padding(padding: const EdgeInsets.only(left: 4), child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(3)),
                        child: Text('חינם', style: GoogleFonts.rubik(fontSize: 9, color: AppColors.success, fontWeight: FontWeight.w600)),
                      )),
                      Flexible(child: Text(ev['title'] as String? ?? '', style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy), overflow: TextOverflow.ellipsis)),
                    ]),
                    if (ev['price'] != null) Text(ev['price'] as String, style: GoogleFonts.rubik(fontSize: 11, color: AppColors.grayLight)),
                  ])),
                  Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(ev['date'] as String? ?? '', style: GoogleFonts.rubik(fontSize: 13)),
                    Text(ev['time'] as String? ?? '', style: GoogleFonts.rubik(fontSize: 11, color: AppColors.grayLight)),
                  ])),
                  if (isWide) Expanded(flex: 2, child: Text(ev['location'] as String? ?? '', style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayText), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Expanded(flex: 1, child: Text(ev['category'] as String? ?? '', style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayText))),
                  Expanded(flex: 1, child: _StatusPill(status)),
                  if (isWide) Expanded(flex: 1, child: Text(capacity > 0 ? '$registered/$capacity' : '$registered', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText))),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18, color: AppColors.grayLight),
                    onSelected: (v) => onAction(v, ev),
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'edit', child: Text('עריכה', style: GoogleFonts.rubik(fontSize: 13))),
                      if (status != 'published') PopupMenuItem(value: 'publish', child: Text('פרסם', style: GoogleFonts.rubik(fontSize: 13))),
                      if (status != 'draft') PopupMenuItem(value: 'draft', child: Text('החזר לטיוטה', style: GoogleFonts.rubik(fontSize: 13))),
                      if (status != 'cancelled') PopupMenuItem(value: 'cancel', child: Text('בטל אירוע', style: GoogleFonts.rubik(fontSize: 13))),
                      PopupMenuItem(value: 'delete', child: Text('מחק', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.error))),
                    ],
                  ),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }
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

  late final TextEditingController _title;
  late final TextEditingController _date;
  late final TextEditingController _time;
  late final TextEditingController _location;
  late final TextEditingController _description;
  late final TextEditingController _organizer;
  late final TextEditingController _price;
  late final TextEditingController _capacity;

  String _status = 'draft';
  String _category = 'עירייה וקהילה';
  bool _isFree = false;
  bool _isFeatured = false;

  bool get _isEditing => widget.event != null;

  static const _categories = ['מוזיקה', 'ילדים ומשפחה', 'ספורט', 'עירייה וקהילה', 'קולינריה', 'תרבות', 'חינוך'];

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _title = TextEditingController(text: e?['title'] as String? ?? '');
    _date = TextEditingController(text: e?['date'] as String? ?? '');
    _time = TextEditingController(text: e?['time'] as String? ?? '');
    _location = TextEditingController(text: e?['location'] as String? ?? '');
    _description = TextEditingController(text: e?['description'] as String? ?? '');
    _organizer = TextEditingController(text: e?['organizer'] as String? ?? '');
    _price = TextEditingController(text: e?['price'] as String? ?? '');
    _capacity = TextEditingController(text: (e?['max_capacity'] as int?)?.toString() ?? '');

    _status = e?['status'] as String? ?? 'draft';
    _category = e?['category'] as String? ?? 'עירייה וקהילה';
    _isFree = e?['is_free'] as bool? ?? false;
    _isFeatured = e?['is_featured'] as bool? ?? false;
  }

  @override
  void dispose() {
    _title.dispose(); _date.dispose(); _time.dispose(); _location.dispose();
    _description.dispose(); _organizer.dispose(); _price.dispose(); _capacity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 650),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Form(
            key: _formKey,
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
                child: Row(children: [
                  Text(_isEditing ? 'עריכת אירוע' : 'אירוע חדש', style: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
                ]),
              ),

              Expanded(
                child: ListView(padding: const EdgeInsets.all(20), children: [
                  _field('שם אירוע *', _title, validator: (v) => v == null || v.isEmpty ? 'שדה חובה' : null),
                  Row(children: [
                    Expanded(child: _field('תאריך *', _date, hint: '2026-09-15', validator: (v) => v == null || v.isEmpty ? 'שדה חובה' : null)),
                    const SizedBox(width: 12),
                    Expanded(child: _field('שעה *', _time, hint: '20:00', validator: (v) => v == null || v.isEmpty ? 'שדה חובה' : null)),
                  ]),
                  _field('מיקום *', _location, validator: (v) => v == null || v.isEmpty ? 'שדה חובה' : null),
                  _field('תיאור', _description, maxLines: 4),
                  Row(children: [
                    Expanded(child: _field('מארגן', _organizer)),
                    const SizedBox(width: 12),
                    Expanded(child: _field('מחיר', _price, hint: '₪50 / חינם')),
                  ]),
                  Row(children: [
                    Expanded(child: _field('קיבולת מקסימלית', _capacity, hint: '100')),
                    const SizedBox(width: 12),
                    Expanded(child: DropdownButtonFormField<String>(
                      value: _category,
                      decoration: InputDecoration(labelText: 'קטגוריה', labelStyle: GoogleFonts.rubik(fontSize: 13), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.rubik(fontSize: 13)))).toList(),
                      onChanged: (v) => setState(() => _category = v!),
                    )),
                  ]),
                  const SizedBox(height: 16),
                  Text('הגדרות', style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: InputDecoration(labelText: 'סטטוס', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                    items: [
                      DropdownMenuItem(value: 'draft', child: Text('טיוטה', style: GoogleFonts.rubik(fontSize: 13))),
                      DropdownMenuItem(value: 'published', child: Text('פורסם', style: GoogleFonts.rubik(fontSize: 13))),
                      DropdownMenuItem(value: 'cancelled', child: Text('בוטל', style: GoogleFonts.rubik(fontSize: 13))),
                    ],
                    onChanged: (v) => setState(() => _status = v!),
                  ),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 4, children: [
                    _toggle('חינם', _isFree, (v) => setState(() => _isFree = v)),
                    _toggle('מומלץ', _isFeatured, (v) => setState(() => _isFeatured = v)),
                  ]),
                ]),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
                child: Row(children: [
                  const Spacer(),
                  TextButton(onPressed: () => Navigator.pop(context), child: Text('ביטול', style: GoogleFonts.rubik())),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(backgroundColor: AppColors.turquoise, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_isEditing ? 'שמור' : 'צור אירוע', style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, {int maxLines = 1, String? hint, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller, maxLines: maxLines, validator: validator,
        style: GoogleFonts.rubik(fontSize: 13),
        decoration: InputDecoration(
          labelText: label, hintText: hint,
          labelStyle: GoogleFonts.rubik(fontSize: 13),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
    return FilterChip(
      label: Text(label, style: GoogleFonts.rubik(fontSize: 12)),
      selected: value, onSelected: onChanged,
      selectedColor: AppColors.turquoise.withValues(alpha: 0.15),
      checkmarkColor: AppColors.turquoise,
      side: BorderSide(color: value ? AppColors.turquoise : AppColors.border),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final fields = <String, dynamic>{
      'title': _title.text,
      'date': _date.text,
      'time': _time.text,
      'location': _location.text,
      'description': _description.text.isEmpty ? null : _description.text,
      'organizer': _organizer.text.isEmpty ? null : _organizer.text,
      'price': _price.text.isEmpty ? null : _price.text,
      'max_capacity': int.tryParse(_capacity.text) ?? 0,
      'category': _category,
      'status': _status,
      'is_free': _isFree,
      'is_featured': _isFeatured,
    };

    try {
      final notifier = ref.read(adminEventListProvider.notifier);
      if (_isEditing) {
        await notifier.updateEvent(widget.event!['id'] as String, fields);
      } else {
        fields['registered_count'] = 0;
        await notifier.createEvent(fields);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('שגיאה: $e'), backgroundColor: AppColors.error));
      }
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
      'cancelled' => ('בוטל', AppColors.error),
      _ => (status, AppColors.grayLight),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: GoogleFonts.rubik(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _Col extends StatelessWidget {
  final String label;
  final int flex;
  const _Col(this.label, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(flex: flex, child: Text(label, style: GoogleFonts.rubik(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.grayLight)));
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
        onTap: onTap, borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.turquoise.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: selected ? AppColors.turquoise : AppColors.border, width: 0.5),
          ),
          child: Text(label, style: GoogleFonts.rubik(fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? AppColors.turquoise : AppColors.grayText)),
        ),
      ),
    );
  }
}

class _Debouncer {
  final int milliseconds;
  _Debouncer({required this.milliseconds});
  Future<void>? _pending;
  void run(VoidCallback action) {
    _pending?.ignore();
    _pending = Future.delayed(Duration(milliseconds: milliseconds)).then((_) => action());
  }
}
