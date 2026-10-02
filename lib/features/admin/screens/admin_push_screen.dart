import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/admin_push_provider.dart';
import '../providers/admin_realestate_provider.dart'
    show adminNeighborhoodOptionsProvider;
import '../widgets/admin_form_pickers.dart';
import '../widgets/image_upload_field.dart';
import '../widgets/push_destination_field.dart';
import '../admin_language.dart';

/// `push_status`, the database enum, in the panel's words.
Map<String, String> get _statusLabels => {
  'draft': tr('טיוטה', 'Draft'),
  'scheduled': tr('מתוזמן', 'Scheduled'),
  'sending': tr('בשליחה', 'Sending'),
  'sent': tr('נשלח', 'Sent'),
  'failed': tr('נכשל', 'Failed'),
  'cancelled': tr('בוטל', 'Cancelled'),
};

/// The topics a device can opt in to in the app's Settings — the
/// `notify_*` switches on `push_devices` (migration 00045). News, events and
/// businesses are also what the automatic notifications go to.
Map<String, String> get _topics => {
  'news': tr('חדשות', 'News'),
  'events': tr('אירועים', 'Events'),
  'businesses': tr('עסקים חדשים', 'New businesses'),
  'deals': tr('מבצעים', 'Deals'),
  'realestate': tr('נדל״ן', 'Real estate'),
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
        const _HowItWorksNote(),

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
                  tr('טיוטות', 'Drafts'),
                  '${loaded.where((n) => n['status'] == 'draft').length}',
                  Icons.edit_note,
                  AppColors.gold,
                ),
                const SizedBox(width: 16),
                _StatChip(
                  tr('מתוזמנות', 'Scheduled'),
                  '${loaded.where((n) => n['status'] == 'scheduled').length}',
                  Icons.schedule,
                  AppColors.midBlue,
                ),
                const SizedBox(width: 16),
                _StatChip(
                  tr('נשלחו', 'Sent'),
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
                    hintText: tr('חיפוש הודעה...', 'Search notifications...'),
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
              for (final e in {
                '': tr('הכל', 'All'),
                'draft': tr('טיוטה', 'Draft'),
                'scheduled': tr('מתוזמן', 'Scheduled'),
                'sent': tr('נשלח', 'Sent'),
                'cancelled': tr('בוטל', 'Cancelled'),
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
                  tr('${loaded.length} הודעות', '${loaded.length} notifications'),
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
                  tr('הודעה חדשה', 'New notification'),
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
                    tr('שגיאה בטעינת הודעות: ${adminErrorText(e)}', 'Error loading notifications: ${adminErrorText(e)}'),
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
                        tr('אין הודעות', 'No notifications'),
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
          if (mounted) showAdminError(context, tr('הפעולה נכשלה', 'The action failed'), e);
        }
      case 'cancel':
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => Directionality(
            textDirection: adminDir,
            child: AlertDialog(
              title: Text(
                tr('ביטול הודעה', 'Cancel notification'),
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: Text(
                tr('לבטל את "${notification['title']}"? ההודעה תישאר ברשימה '
                'תחת "בוטל", ו"החזר לטיוטה" בתפריט שלה מחזיר אותה.', 'Cancel "${notification['title']}"? The notification stays in the list under "Cancelled", and "Back to draft" in its menu brings it back.'),
                style: TextStyle(fontFamily: AppFonts.rubik),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(
                    tr('חזרה', 'Back'),
                    style: TextStyle(fontFamily: AppFonts.rubik),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(
                    tr('בטל הודעה', 'Cancel notification'),
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
          if (mounted) showAdminError(context, tr('הביטול נכשל', 'Cancelling failed'), e);
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

/// When things go out, said where the client will read it — above all that
/// new articles, events and businesses send themselves.
class _HowItWorksNote extends StatelessWidget {
  const _HowItWorksNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.turquoise.withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(color: AppColors.turquoise.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.turquoise),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tr('הודעה נשלחת עד דקה אחרי המועד שלה. כתבה, אירוע או עסק חדש '
              'שמתפרסמים נשלחים אוטומטית חמש דקות אחרי הפרסום למי שבחר בנושא, '
              'אלא אם הורדתם את הסימון "לשלוח התראה" בטופס שלהם — ועד שהיא '
              'יוצאת, אפשר לבטל אותה כאן. "נפתחו" סופר כל מכשיר פעם אחת.',
              'A notification goes out within a minute of its time. A new article, event or business is sent automatically five minutes after it is published to everyone who chose that topic, unless you cleared "Send a notification" in its form — and until it goes out, you can cancel it here. "Opened" counts each device once.'),
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
    'neighborhood' => tr('שכונה: ${hoods[filter?['neighborhood_id']] ?? '—'}', 'Neighbourhood: ${hoods[filter?['neighborhood_id']] ?? '—'}'),
    'topic' => tr('נושא: ${_topics[filter?['topic']] ?? '—'}', 'Topic: ${_topics[filter?['topic']] ?? '—'}'),
    'device' => tr('מכשיר בדיקה', 'Test device'),
    _ => tr('כולם', 'Everyone'),
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
              _Col(tr('כותרת', 'Title'), flex: 3),
              _Col(tr('קהל יעד', 'Target audience'), flex: 2),
              _Col(tr('סטטוס', 'Status'), flex: 1),
              if (isWide) _Col(tr('נשלחו אל', 'Sent to'), flex: 1),
              if (isWide) _Col(tr('נפתחו', 'Opened'), flex: 1),
              if (isWide) _Col(tr('תאריך', 'Date'), flex: 2),
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
              // Devices Firebase accepted it for — "about", as the client was
              // told: an accepted message is not proof it was seen.
              final delivered = n['sent_count'] as int? ?? 0;
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
                            if (n['source_type'] != null)
                              Text(
                                tr('אוטומטית', 'Automatic'),
                                style: TextStyle(
                                  fontFamily: AppFonts.rubik,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.turquoise,
                                ),
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
                                ? '$opened (${(opened / delivered * 100).round()}%)'
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
                                ? tr('מתוזמן: ${_formatDate(scheduledAt)}', 'Scheduled: ${_formatDate(scheduledAt)}')
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
                          _item('edit', tr('עריכה', 'Edit')),
                          if (status == 'cancelled')
                            _item('restore', tr('החזר לטיוטה', 'Back to draft'))
                          else if (status == 'draft' || status == 'scheduled')
                            _item('cancel', tr('בטל', 'Cancel'), color: AppColors.error),
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
  late final TextEditingController _titleEn;
  late final TextEditingController _bodyEn;
  late final TextEditingController _imageUrl;
  String? _deepLink;

  /// What the form may set: a draft, now, or a time. "Now" is saved as
  /// scheduled for this moment, which the sender picks up within a minute.
  /// Sent, sending and failed belong to the sender; a campaign in one of
  /// those is shown, not edited back into a draft by accident.
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
    _titleEn = TextEditingController(text: n?['title_en'] as String? ?? '');
    _bodyEn = TextEditingController(text: n?['body_en'] as String? ?? '');
    _imageUrl = TextEditingController(text: n?['image_url'] as String? ?? '');
    _deepLink = n?['deep_link'] as String?;
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
    _titleEn.dispose();
    _bodyEn.dispose();
    _imageUrl.dispose();
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
      locale: adminLocale,
      context: context,
      initialDate: start.isBefore(now) ? now : start,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      builder: (ctx, child) => Localizations.override(
        context: ctx,
        locale: adminLocale,
        child: child,
      ),
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
          textDirection: adminDir,
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
                            ? tr('הודעה חדשה', 'New notification')
                            : _editable
                            ? tr('עריכת הודעה', 'Edit notification')
                            : tr('הודעה', 'Notification'),
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
                            tr('ההודעה במצב "${_statusLabels[_original] ?? _original}" '
                            'ולכן מוצגת לקריאה בלבד.'
                            '${_original == 'cancelled' ? ' "החזר לטיוטה" בתפריט שלה מאפשר לערוך אותה שוב.' : ''}', 'The notification is "${_statusLabels[_original] ?? _original}", so it is read-only.${_original == 'cancelled' ? ' "Back to draft" in its menu lets you edit it again.' : ''}'),
                            style: TextStyle(
                              fontFamily: AppFonts.rubik,
                              fontSize: 12,
                              color: AppColors.grayText,
                            ),
                          ),
                        ),
                      _field(
                        tr('כותרת *', 'Title *'),
                        _title,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? tr('שדה חובה', 'Required field') : null,
                      ),
                      _field(
                        tr('תוכן ההודעה *', 'Notification text *'),
                        _body,
                        maxLines: 4,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? tr('שדה חובה', 'Required field') : null,
                      ),
                      // English is optional: a device set to English gets
                      // it, and the Hebrew when it is left empty.
                      _sectionLabel(tr('באנגלית (לא חובה)', 'In English (optional)')),
                      _field(tr('כותרת באנגלית', 'Title in English'), _titleEn),
                      _field(
                        tr('תוכן באנגלית', 'Text in English'),
                        _bodyEn,
                        maxLines: 3,
                      ),
                      if (_editable)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ImageUploadField(
                            label: tr('תמונה (לא חובה)', 'Image (optional)'),
                            controller: _imageUrl,
                            folder: 'push',
                          ),
                        )
                      else if (_imageUrl.text.trim().isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _imageUrl.text.trim(),
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const SizedBox.shrink(),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      PushDestinationField(
                        value: _deepLink,
                        enabled: _editable,
                        onChanged: (v) => _deepLink = v,
                      ),
                      const SizedBox(height: 4),
                      _dropdown<String>(tr('קהל יעד', 'Target audience'), _audience, {
                        'all': tr('כולם', 'Everyone'),
                        'neighborhood': tr('לפי שכונה', 'By neighbourhood'),
                        'topic': tr('מי שנרשם לנושא', 'Subscribers to the topic'),
                      }, (v) => _audience = v ?? 'all'),
                      if (_audience == 'neighborhood')
                        hoods == null
                            ? const LinearProgressIndicator(minHeight: 2)
                            : _dropdown<String>(tr('שכונה', 'Neighbourhood'), _neighborhoodId, {
                                for (final h in hoods)
                                  h['id'] as String: h['name'] as String? ?? '',
                              }, (v) => _neighborhoodId = v),
                      if (_audience == 'topic')
                        _dropdown<String>(
                          tr('נושא', 'Topic'),
                          _topic,
                          _topics,
                          (v) => _topic = v ?? 'news',
                        ),
                      if (_editable) _AudienceEstimate(type: _audience, filter: _audienceFilter),
                      if (_editable)
                        _dropdown<String>(tr('שליחה', 'Sending'), _status, {
                          'draft': tr('טיוטה — לא לשלוח עדיין', 'Draft — do not send yet'),
                          'now': tr('לשלוח עכשיו', 'Send now'),
                          'scheduled': tr('לתזמן', 'Schedule'),
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
                                    tr('מועד מתוכנן *', 'Scheduled time *'),
                                    error: _scheduleMissing
                                        ? tr('יש לבחור מועד', 'A time must be chosen')
                                        : null,
                                  ).copyWith(
                                    suffixIcon: const Icon(
                                      Icons.schedule,
                                      size: 18,
                                    ),
                                  ),
                              child: Text(
                                _scheduledAt == null
                                    ? tr('בחירת תאריך ושעה', 'Choose date and time')
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
                          !_editable
                              ? ''
                              : switch (_status) {
                                  'now' => tr('יוצאת תוך דקה', 'Goes out within a minute'),
                                  'scheduled' => tr('יוצאת במועד שנקבע', 'Goes out at the time set'),
                                  _ => tr('נשמרת בלבד — לא נשלחת', 'Saved only — not sent'),
                                },
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
                          _editable ? tr('ביטול', 'Cancel') : tr('סגירה', 'Close'),
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
                                  switch (_status) {
                                    'now' => tr('שלח עכשיו', 'Send now'),
                                    'scheduled' => tr('שמור כמתוזמן', 'Save as scheduled'),
                                    _ => tr('שמור כטיוטה', 'Save as draft'),
                                  },
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

  Map<String, dynamic>? get _audienceFilter => switch (_audience) {
    'neighborhood' => {'neighborhood_id': _neighborhoodId},
    'topic' => {'topic': _topic},
    _ => null,
  };

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 8),
    child: Text(
      text,
      style: TextStyle(
        fontFamily: AppFonts.rubik,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.grayText,
      ),
    ),
  );

  /// "Send now" cannot be taken back after the minute is up, so it asks
  /// first, with how many devices it is about to reach.
  Future<bool> _confirmSendNow() async {
    int? reach;
    try {
      reach = await SupabaseConfig.client.rpc(
        'push_audience_size',
        params: {'p_audience_type': _audience, 'p_audience_filter': _audienceFilter},
      ) as int?;
    } catch (_) {}
    if (!mounted) return false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: adminDir,
        child: AlertDialog(
          title: Text(tr('לשלוח עכשיו?', 'Send now?'), style: TextStyle(fontFamily: AppFonts.rubik)),
          content: Text(
            reach == null
                ? tr('ההודעה תצא תוך דקה.', 'The notification goes out within a minute.')
                : tr('ההודעה תצא תוך דקה לכ-$reach מכשירים.',
                    'The notification goes out within a minute to about $reach devices.'),
            style: TextStyle(fontFamily: AppFonts.rubik),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('חזרה', 'Back'))),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('שלח', 'Send'))),
          ],
        ),
      ),
    );
    return ok == true;
  }

  Future<void> _save() async {
    final valid = _formKey.currentState!.validate();
    final needsTime = _status == 'scheduled' && _scheduledAt == null;
    setState(() => _scheduleMissing = needsTime);
    if (!valid || needsTime) return;
    if (_audience == 'neighborhood' && _neighborhoodId == null) {
      showAdminError(context, tr('לא נשמר', 'Not saved'), tr('יש לבחור שכונה', 'A neighbourhood must be chosen'));
      return;
    }
    if (_status == 'now' && !await _confirmSendNow()) return;
    setState(() => _saving = true);

    // Never `sent` or `sent_at`: those are the sender's to write once it has
    // sent (supabase/functions/push-dispatch).
    final fields = <String, dynamic>{
      'title': _title.text.trim(),
      'body': _body.text.trim(),
      'title_en': _text(_titleEn),
      'body_en': _text(_bodyEn),
      'image_url': _text(_imageUrl),
      'deep_link': _deepLink,
      'status': _status == 'draft' ? 'draft' : 'scheduled',
      'scheduled_at': switch (_status) {
        'now' => DateTime.now().toUtc().toIso8601String(),
        'scheduled' => _scheduledAt!.toUtc().toIso8601String(),
        _ => null,
      },
      'audience_type': _audience,
      'audience_filter': _audienceFilter,
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
      if (mounted) showAdminError(context, tr('השמירה נכשלה', 'Saving failed'), e);
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
      padding: const EdgeInsetsDirectional.only(end: 6),
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


/// About how many devices the audience reaches right now — devices that
/// allowed notifications, kept them on and chose this topic or neighbourhood.
class _AudienceEstimate extends StatefulWidget {
  final String type;
  final Map<String, dynamic>? filter;
  const _AudienceEstimate({required this.type, required this.filter});

  @override
  State<_AudienceEstimate> createState() => _AudienceEstimateState();
}

class _AudienceEstimateState extends State<_AudienceEstimate> {
  Future<int?>? _count;
  String _key = '';

  @override
  Widget build(BuildContext context) {
    final key = '${widget.type}|${widget.filter}';
    if (key != _key) {
      _key = key;
      _count = SupabaseConfig.client
          .rpc('push_audience_size', params: {
            'p_audience_type': widget.type,
            'p_audience_filter': widget.filter,
          })
          .then((v) => v as int?)
          .catchError((_) => null);
    }
    return FutureBuilder<int?>(
      future: _count,
      builder: (context, snap) {
        final n = snap.data;
        if (n == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            tr('מגיעה כרגע לכ-$n מכשירים', 'Reaches about $n devices right now'),
            style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 12, color: AppColors.grayText),
          ),
        );
      },
    );
  }
}
