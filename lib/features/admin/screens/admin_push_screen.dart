import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/admin_push_provider.dart';
import '../providers/admin_realestate_provider.dart'
    show adminNeighborhoodOptionsProvider;
import '../widgets/admin_form_pickers.dart';

/// `push_status`, the database enum, in the panel's words.
const _statusLabels = {
  'draft': 'טיוטה',
  'scheduled': 'מתוזמן',
  'sending': 'בשליחה',
  'sent': 'נשלח',
  'failed': 'נכשל',
  'cancelled': 'בוטל',
};

/// The four topics a resident can opt in to — the `notify_*` switches on
/// their profile.
const _topics = {
  'news': 'חדשות',
  'deals': 'מבצעים',
  'neighborhood': 'השכונה שלי',
  'realestate': 'נדל״ן',
};

class AdminPushScreen extends ConsumerStatefulWidget {
  const AdminPushScreen({super.key});

  @override
  ConsumerState<AdminPushScreen> createState() => _AdminPushScreenState();
}

class _AdminPushScreenState extends ConsumerState<AdminPushScreen> {
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
    final pushAsync = ref.watch(adminPushListProvider);
    final loaded = pushAsync.valueOrNull;
    final isWide = MediaQuery.of(context).size.width > 900;

    return Column(
      children: [
        // Said before anything else: the screen looks like it sends, and
        // it does not.
        const _NotConnectedNote(),

        // ─── Stats Row ───
        if (loaded != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                _StatChip(
                  'טיוטות',
                  '${loaded.where((n) => n['status'] == 'draft').length}',
                  Icons.edit_note,
                  AppColors.gold,
                ),
                const SizedBox(width: 16),
                _StatChip(
                  'מתוזמנות',
                  '${loaded.where((n) => n['status'] == 'scheduled').length}',
                  Icons.schedule,
                  AppColors.midBlue,
                ),
                const SizedBox(width: 16),
                _StatChip(
                  'נשלחו',
                  '${loaded.where((n) => n['status'] == 'sent').length}',
                  Icons.send,
                  AppColors.turquoise,
                ),
              ],
            ),
          ),

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
                    hintText: 'חיפוש הודעה...',
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
                        .read(adminPushListProvider.notifier)
                        .setSearch(v.isEmpty ? null : v);
                  }),
                ),
              ),
              const SizedBox(width: 12),
              for (final e in const {
                '': 'הכל',
                'draft': 'טיוטה',
                'scheduled': 'מתוזמן',
                'sent': 'נשלח',
                'cancelled': 'בוטל',
              }.entries)
                _FilterChip(e.value, _statusFilter == e.key, () {
                  setState(() => _statusFilter = e.key);
                  ref
                      .read(adminPushListProvider.notifier)
                      .setStatusFilter(e.key.isEmpty ? null : e.key);
                }),
              const Spacer(),
              if (loaded != null)
                Text(
                  '${loaded.length} הודעות',
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 13,
                    color: AppColors.grayText,
                  ),
                ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: () => _showPushEditor(context),
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  'הודעה חדשה',
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
          child: pushAsync.when(
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
                    'שגיאה בטעינת הודעות: ${adminErrorText(e)}',
                    style: TextStyle(
                      fontFamily: AppFonts.rubik,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
            data: (notifications) {
              if (notifications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 48,
                        color: AppColors.grayLight.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'אין הודעות',
                        style: TextStyle(
                          fontFamily: AppFonts.rubik,
                          color: AppColors.grayText,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return _PushTable(
                notifications: notifications,
                isWide: isWide,
                neighborhoods: _neighborhoodNames(),
                onTap: (n) => _showPushEditor(context, notification: n),
                onAction: _handleAction,
              );
            },
          ),
        ),
      ],
    );
  }

  Map<String, String> _neighborhoodNames() => {
    for (final n
        in ref.watch(adminNeighborhoodOptionsProvider).valueOrNull ??
            const <Map<String, dynamic>>[])
      n['id'] as String: n['name'] as String? ?? '',
  };

  Future<void> _handleAction(
    String action,
    Map<String, dynamic> notification,
  ) async {
    final notifier = ref.read(adminPushListProvider.notifier);
    final id = notification['id'] as String;
    switch (action) {
      case 'edit':
        _showPushEditor(context, notification: notification);
      case 'restore':
        try {
          await notifier.restoreToDraft(id);
        } catch (e) {
          if (mounted) showAdminError(context, 'הפעולה נכשלה', e);
        }
      case 'cancel':
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: Text(
                'ביטול הודעה',
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: Text(
                'לבטל את "${notification['title']}"? ההודעה תישאר ברשימה '
                'תחת "בוטל", ו"החזר לטיוטה" בתפריט שלה מחזיר אותה.',
                style: TextStyle(fontFamily: AppFonts.rubik),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(
                    'חזרה',
                    style: TextStyle(fontFamily: AppFonts.rubik),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(
                    'בטל הודעה',
                    style: TextStyle(
                      fontFamily: AppFonts.rubik,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        if (ok != true) return;
        try {
          await notifier.cancelNotification(id);
        } catch (e) {
          if (mounted) showAdminError(context, 'הביטול נכשל', e);
        }
    }
  }

  void _showPushEditor(
    BuildContext context, {
    Map<String, dynamic>? notification,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PushEditorDialog(notification: notification),
    );
  }
}

/// Sending is not connected, said where the client will read it.
class _NotConnectedNote extends StatelessWidget {
  const _NotConnectedNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: AppColors.gold.withValues(alpha: 0.4)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.gold),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'שליחת התראות עדיין לא מחוברת. אפשר לכתוב הודעות ולשמור אותן '
              'כטיוטה או כמתוזמנות, אבל שום הודעה לא נשלחת לטלפונים — גם '
              'לא הודעה מתוזמנת כשמגיע מועדה. כדי לחבר את השליחה נדרשים '
              'מפתחות Firebase של האפליקציה (ולאייפון גם APNs של Apple).',
              style: TextStyle(
                fontFamily: AppFonts.rubik,
                fontSize: 12,
                height: 1.5,
                color: AppColors.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Chip ───

class _StatChip extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatChip(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  fontSize: 11,
                  color: AppColors.grayText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Push Table ───

/// Who a campaign is for, in words.
String _audienceLabel(Map<String, dynamic> n, Map<String, String> hoods) {
  final filter = n['audience_filter'] as Map?;
  return switch (n['audience_type'] as String? ?? 'all') {
    'neighborhood' => 'שכונה: ${hoods[filter?['neighborhood_id']] ?? '—'}',
    'topic' => 'נושא: ${_topics[filter?['topic']] ?? '—'}',
    _ => 'כולם',
  };
}

class _PushTable extends StatelessWidget {
  final List<Map<String, dynamic>> notifications;
  final bool isWide;
  final Map<String, String> neighborhoods;
  final void Function(Map<String, dynamic>) onTap;
  final void Function(String, Map<String, dynamic>) onAction;
  const _PushTable({
    required this.notifications,
    required this.isWide,
    required this.neighborhoods,
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
              _Col('כותרת', flex: 3),
              _Col('קהל יעד', flex: 2),
              _Col('סטטוס', flex: 1),
              if (isWide) _Col('נמסרו', flex: 1),
              if (isWide) _Col('נפתחו', flex: 1),
              if (isWide) _Col('תאריך', flex: 2),
              const SizedBox(width: 40),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: AppColors.border.withValues(alpha: 0.3),
            ),
            itemBuilder: (_, i) {
              final n = notifications[i];
              final status = n['status'] as String? ?? 'draft';
              final delivered = n['delivered_count'] as int? ?? 0;
              final opened = n['opened_count'] as int? ?? 0;
              final sentAt = n['sent_at'] as String?;
              final scheduledAt = n['scheduled_at'] as String?;

              return InkWell(
                onTap: () => onTap(n),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      if (n['image_url'] != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            n['image_url'] as String,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.broken_image,
                                size: 18,
                                color: AppColors.grayLight,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n['title'] as String? ?? '',
                              style: TextStyle(
                                fontFamily: AppFonts.rubik,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.navy,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              n['body'] as String? ?? '',
                              style: TextStyle(
                                fontFamily: AppFonts.rubik,
                                fontSize: 11,
                                color: AppColors.grayLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          _audienceLabel(n, neighborhoods),
                          style: TextStyle(
                            fontFamily: AppFonts.rubik,
                            fontSize: 12,
                            color: AppColors.grayText,
                          ),
                        ),
                      ),
                      Expanded(flex: 1, child: _StatusPill(status)),
                      if (isWide)
                        Expanded(
                          flex: 1,
                          child: Text(
                            status == 'sent' ? '$delivered' : '—',
                            style: TextStyle(
                              fontFamily: AppFonts.rubik,
                              fontSize: 13,
                              color: AppColors.grayText,
                            ),
                          ),
                        ),
                      if (isWide)
                        Expanded(
                          flex: 1,
                          child: Text(
                            delivered > 0
                                ? '${(opened / delivered * 100).toInt()}%'
                                : '—',
                            style: TextStyle(
                              fontFamily: AppFonts.rubik,
                              fontSize: 13,
                              color: AppColors.grayText,
                            ),
                          ),
                        ),
                      if (isWide)
                        Expanded(
                          flex: 2,
                          child: Text(
                            sentAt != null
                                ? _formatDate(sentAt)
                                : scheduledAt != null
                                ? 'מתוזמן: ${_formatDate(scheduledAt)}'
                                : '—',
                            style: TextStyle(
                              fontFamily: AppFonts.rubik,
                              fontSize: 12,
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
                        onSelected: (v) => onAction(v, n),
                        itemBuilder: (_) => [
                          _item('edit', 'עריכה'),
                          if (status == 'cancelled')
                            _item('restore', 'החזר לטיוטה')
                          else if (status == 'draft' || status == 'scheduled')
                            _item('cancel', 'בטל', color: AppColors.error),
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

  PopupMenuItem<String> _item(String value, String label, {Color? color}) =>
      PopupMenuItem(
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

String _formatDate(String iso) {
  final d = DateTime.tryParse(iso)?.toLocal();
  if (d == null) return iso;
  return '${d.day}/${d.month}/${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

// ─── Push Editor Dialog ───

class _PushEditorDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? notification;
  const _PushEditorDialog({this.notification});

  @override
  ConsumerState<_PushEditorDialog> createState() => _PushEditorDialogState();
}

class _PushEditorDialogState extends ConsumerState<_PushEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late final TextEditingController _title;
  late final TextEditingController _body;
  late final TextEditingController _imageUrl;
  late final TextEditingController _deepLink;

  /// What the form may set. Sent, sending and failed belong to the sender
  /// that does not exist yet; a campaign in one of those is shown, not
  /// edited back into a draft by accident.
  String _status = 'draft';
  String _audience = 'all';
  String? _neighborhoodId;
  String _topic = 'news';
  DateTime? _scheduledAt;
  bool _scheduleMissing = false;

  bool get _isEditing => widget.notification != null;
  String get _original => widget.notification?['status'] as String? ?? 'draft';
  bool get _editable =>
      !_isEditing || _original == 'draft' || _original == 'scheduled';

  @override
  void initState() {
    super.initState();
    final n = widget.notification;
    _title = TextEditingController(text: n?['title'] as String? ?? '');
    _body = TextEditingController(text: n?['body'] as String? ?? '');
    _imageUrl = TextEditingController(text: n?['image_url'] as String? ?? '');
    _deepLink = TextEditingController(text: n?['deep_link'] as String? ?? '');
    if (_original == 'scheduled') _status = 'scheduled';
    final audience = n?['audience_type'] as String?;
    if (audience == 'neighborhood' || audience == 'topic') {
      _audience = audience!;
    }
    final filter = n?['audience_filter'] as Map?;
    _neighborhoodId = filter?['neighborhood_id'] as String?;
    final topic = filter?['topic'] as String?;
    if (_topics.containsKey(topic)) _topic = topic!;
    _scheduledAt = DateTime.tryParse(
      n?['scheduled_at'] as String? ?? '',
    )?.toLocal();
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _imageUrl.dispose();
    _deepLink.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label, {String? hint, String? error}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: error,
        labelStyle: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      );

  Widget _dropdown<T>(
    String label,
    T? value,
    Map<T, String> items,
    ValueChanged<T?> onChanged,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: _decoration(label),
      items: [
        for (final e in items.entries)
          DropdownMenuItem(
            value: e.key,
            child: Text(
              e.value,
              style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
            ),
          ),
      ],
      onChanged: _editable ? (v) => setState(() => onChanged(v)) : null,
    ),
  );

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final start = _scheduledAt ?? now.add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: start.isBefore(now) ? now : start,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(start),
    );
    if (time == null) return;
    setState(() {
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _scheduleMissing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hoods = ref.watch(adminNeighborhoodOptionsProvider).valueOrNull;
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650, maxHeight: 680),
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
                        !_isEditing
                            ? 'הודעה חדשה'
                            : _editable
                            ? 'עריכת הודעה'
                            : 'הודעה',
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
                      if (!_editable)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'ההודעה במצב "${_statusLabels[_original] ?? _original}" '
                            'ולכן מוצגת לקריאה בלבד.'
                            '${_original == 'cancelled' ? ' "החזר לטיוטה" בתפריט שלה מאפשר לערוך אותה שוב.' : ''}',
                            style: TextStyle(
                              fontFamily: AppFonts.rubik,
                              fontSize: 12,
                              color: AppColors.grayText,
                            ),
                          ),
                        ),
                      _field(
                        'כותרת *',
                        _title,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'שדה חובה' : null,
                      ),
                      _field(
                        'תוכן ההודעה *',
                        _body,
                        maxLines: 4,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'שדה חובה' : null,
                      ),
                      _field(
                        'קישור תמונה',
                        _imageUrl,
                        hint: 'https://...',
                        onChanged: (_) => setState(() {}),
                      ),
                      if (_imageUrl.text.trim().isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _imageUrl.text.trim(),
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              height: 60,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'תמונה לא נמצאה',
                                style: TextStyle(
                                  fontFamily: AppFonts.rubik,
                                  fontSize: 12,
                                  color: AppColors.grayLight,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      _field(
                        'קישור בתוך האפליקציה',
                        _deepLink,
                        hint: '/event/…',
                      ),
                      const SizedBox(height: 4),
                      _dropdown<String>('קהל יעד', _audience, const {
                        'all': 'כולם',
                        'neighborhood': 'לפי שכונה',
                        'topic': 'מי שנרשם לנושא',
                      }, (v) => _audience = v ?? 'all'),
                      if (_audience == 'neighborhood')
                        hoods == null
                            ? const LinearProgressIndicator(minHeight: 2)
                            : _dropdown<String>('שכונה', _neighborhoodId, {
                                for (final h in hoods)
                                  h['id'] as String: h['name'] as String? ?? '',
                              }, (v) => _neighborhoodId = v),
                      if (_audience == 'topic')
                        _dropdown<String>(
                          'נושא',
                          _topic,
                          _topics,
                          (v) => _topic = v ?? 'news',
                        ),
                      if (_editable)
                        _dropdown<String>('מצב', _status, const {
                          'draft': 'טיוטה',
                          'scheduled': 'מתוזמן',
                        }, (v) => _status = v ?? 'draft'),
                      if (_status == 'scheduled' && _editable)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: _pickSchedule,
                            child: InputDecorator(
                              decoration:
                                  _decoration(
                                    'מועד מתוכנן *',
                                    error: _scheduleMissing
                                        ? 'יש לבחור מועד'
                                        : null,
                                  ).copyWith(
                                    suffixIcon: const Icon(
                                      Icons.schedule,
                                      size: 18,
                                    ),
                                  ),
                              child: Text(
                                _scheduledAt == null
                                    ? 'בחירת תאריך ושעה'
                                    : _formatDate(
                                        _scheduledAt!.toIso8601String(),
                                      ),
                                style: TextStyle(
                                  fontFamily: AppFonts.rubik,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
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
                      Expanded(
                        child: Text(
                          'נשמר בלבד — לא נשלח',
                          style: TextStyle(
                            fontFamily: AppFonts.rubik,
                            fontSize: 11,
                            color: AppColors.grayText,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          _editable ? 'ביטול' : 'סגירה',
                          style: TextStyle(fontFamily: AppFonts.rubik),
                        ),
                      ),
                      if (_editable) ...[
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
                                  _status == 'scheduled'
                                      ? 'שמור כמתוזמן'
                                      : 'שמור כטיוטה',
                                  style: TextStyle(
                                    fontFamily: AppFonts.rubik,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ],
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

  Widget _field(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    String? hint,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        onChanged: onChanged,
        readOnly: !_editable,
        style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
        decoration: _decoration(label, hint: hint),
      ),
    );
  }

  String? _text(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _save() async {
    final valid = _formKey.currentState!.validate();
    final needsTime = _status == 'scheduled' && _scheduledAt == null;
    setState(() => _scheduleMissing = needsTime);
    if (!valid || needsTime) return;
    if (_audience == 'neighborhood' && _neighborhoodId == null) {
      showAdminError(context, 'לא נשמר', 'יש לבחור שכונה');
      return;
    }
    setState(() => _saving = true);

    // Never `sent`, never `sent_at`: nothing sends yet.
    final fields = <String, dynamic>{
      'title': _title.text.trim(),
      'body': _body.text.trim(),
      'image_url': _text(_imageUrl),
      'deep_link': _text(_deepLink),
      'status': _status,
      'scheduled_at': _status == 'scheduled'
          ? _scheduledAt!.toUtc().toIso8601String()
          : null,
      'audience_type': _audience,
      'audience_filter': switch (_audience) {
        'neighborhood' => {'neighborhood_id': _neighborhoodId},
        'topic' => {'topic': _topic},
        _ => null,
      },
    };

    try {
      final notifier = ref.read(adminPushListProvider.notifier);
      if (_isEditing) {
        await notifier.updateNotification(
          widget.notification!['id'] as String,
          fields,
        );
      } else {
        await notifier.createNotification(fields);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showAdminError(context, 'השמירה נכשלה', e);
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
    final color = switch (status) {
      'sent' => AppColors.success,
      'scheduled' || 'sending' => AppColors.midBlue,
      'draft' => AppColors.gold,
      'failed' => AppColors.error,
      _ => AppColors.grayLight,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _statusLabels[status] ?? status,
        style: TextStyle(
          fontFamily: AppFonts.rubik,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
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

/// Waits for typing to pause before searching. The old version chained
/// futures it could not cancel, so every keystroke still ran a search.
class _Debouncer {
  final int milliseconds;
  _Debouncer({required this.milliseconds});
  Timer? _timer;
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}
