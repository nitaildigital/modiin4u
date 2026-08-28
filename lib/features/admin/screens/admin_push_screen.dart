import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/admin_push_provider.dart';

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
    final isWide = MediaQuery.of(context).size.width > 900;

    return Column(children: [
      // ─── Stats Row ───
      pushAsync.whenOrNull(data: (list) {
        final sent = list.where((n) => n['status'] == 'sent').toList();
        final totalDelivered = sent.fold<int>(0, (sum, n) => sum + (n['delivered_count'] as int? ?? 0));
        final totalRead = sent.fold<int>(0, (sum, n) => sum + (n['read_count'] as int? ?? 0));
        final totalClicked = sent.fold<int>(0, (sum, n) => sum + (n['click_count'] as int? ?? 0));
        final readRate = totalDelivered > 0 ? (totalRead / totalDelivered * 100).toInt() : 0;
        final clickRate = totalDelivered > 0 ? (totalClicked / totalDelivered * 100).toInt() : 0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(color: AppColors.surfaceLight, border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5)))),
          child: Row(children: [
            _StatChip('נשלחו', '${sent.length}', Icons.send, AppColors.turquoise),
            const SizedBox(width: 16),
            _StatChip('אחוז קריאה', '$readRate%', Icons.visibility, AppColors.success),
            const SizedBox(width: 16),
            _StatChip('אחוז הקלקה', '$clickRate%', Icons.touch_app, AppColors.midBlue),
            const SizedBox(width: 16),
            _StatChip('סה"כ נמסרו', _formatNumber(totalDelivered), Icons.check_circle, AppColors.gold),
          ]),
        );
      }) ?? const SizedBox.shrink(),

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
                hintText: 'חיפוש הודעה...',
                hintStyle: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayLight),
                prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.grayLight),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.turquoise)),
              ),
              onChanged: (v) => _debouncer.run(() {
                ref.read(adminPushListProvider.notifier).setSearch(v.isEmpty ? null : v);
              }),
            ),
          ),
          const SizedBox(width: 12),
          _FilterChip('הכל', _statusFilter.isEmpty, () {
            setState(() => _statusFilter = '');
            ref.read(adminPushListProvider.notifier).setStatusFilter(null);
          }),
          _FilterChip('נשלח', _statusFilter == 'sent', () {
            setState(() => _statusFilter = 'sent');
            ref.read(adminPushListProvider.notifier).setStatusFilter('sent');
          }),
          _FilterChip('מתוזמן', _statusFilter == 'scheduled', () {
            setState(() => _statusFilter = 'scheduled');
            ref.read(adminPushListProvider.notifier).setStatusFilter('scheduled');
          }),
          _FilterChip('טיוטה', _statusFilter == 'draft', () {
            setState(() => _statusFilter = 'draft');
            ref.read(adminPushListProvider.notifier).setStatusFilter('draft');
          }),
          const Spacer(),
          pushAsync.whenData((list) => Text('${list.length} הודעות', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText))).value ?? const SizedBox.shrink(),
          const SizedBox(width: 16),
          FilledButton.icon(
            onPressed: () => _showPushEditor(context, ref),
            icon: const Icon(Icons.add, size: 18),
            label: Text('הודעה חדשה', style: GoogleFonts.rubik(fontSize: 13)),
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
        child: pushAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text('שגיאה בטעינת הודעות', style: GoogleFonts.rubik(color: AppColors.error)),
          ])),
          data: (notifications) {
            if (notifications.isEmpty) {
              return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.notifications_none, size: 48, color: AppColors.grayLight.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text('אין הודעות', style: GoogleFonts.rubik(color: AppColors.grayText)),
              ]));
            }
            return _PushTable(notifications: notifications, isWide: isWide, onTap: (n) => _showPushEditor(context, ref, notification: n), onAction: _handleAction);
          },
        ),
      ),
    ]);
  }

  String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  void _handleAction(String action, Map<String, dynamic> notification) {
    final notifier = ref.read(adminPushListProvider.notifier);
    final id = notification['id'] as String;
    switch (action) {
      case 'edit':
        _showPushEditor(context, ref, notification: notification);
      case 'send':
        notifier.sendNotification(id);
      case 'delete':
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('מחיקת הודעה', style: GoogleFonts.rubik(fontWeight: FontWeight.w700)),
            content: Text('למחוק את "${notification['title']}"?', style: GoogleFonts.rubik()),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text('ביטול', style: GoogleFonts.rubik())),
              TextButton(onPressed: () { Navigator.pop(ctx); notifier.deleteNotification(id); }, child: Text('מחק', style: GoogleFonts.rubik(color: AppColors.error))),
            ],
          ),
        );
    }
  }

  void _showPushEditor(BuildContext context, WidgetRef ref, {Map<String, dynamic>? notification}) {
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => _PushEditorDialog(notification: notification));
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
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navy)),
          Text(label, style: GoogleFonts.rubik(fontSize: 11, color: AppColors.grayText)),
        ]),
      ]),
    );
  }
}

// ─── Push Table ───

class _PushTable extends StatelessWidget {
  final List<Map<String, dynamic>> notifications;
  final bool isWide;
  final void Function(Map<String, dynamic>) onTap;
  final void Function(String, Map<String, dynamic>) onAction;
  const _PushTable({required this.notifications, required this.isWide, required this.onTap, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(color: AppColors.surfaceLight, border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5)))),
        child: Row(children: [
          _Col('כותרת', flex: 3),
          _Col('סוג', flex: 1),
          _Col('קהל יעד', flex: 2),
          _Col('סטטוס', flex: 1),
          if (isWide) _Col('נמסרו', flex: 1),
          if (isWide) _Col('נקראו', flex: 1),
          if (isWide) _Col('תאריך', flex: 2),
          const SizedBox(width: 40),
        ]),
      ),
      Expanded(
        child: ListView.separated(
          itemCount: notifications.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.border.withValues(alpha: 0.3)),
          itemBuilder: (_, i) {
            final n = notifications[i];
            final status = n['status'] as String? ?? 'draft';
            final type = n['type'] as String? ?? 'general';
            final audience = n['target_audience'] as String? ?? 'all';
            final targetValue = n['target_value'] as String?;
            final delivered = n['delivered_count'] as int? ?? 0;
            final read = n['read_count'] as int? ?? 0;
            final sentAt = n['sent_at'] as String?;
            final scheduledAt = n['scheduled_at'] as String?;

            return InkWell(
              onTap: () => onTap(n),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(children: [
                  Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(n['title'] as String? ?? '', style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy), overflow: TextOverflow.ellipsis),
                    Text(n['body'] as String? ?? '', style: GoogleFonts.rubik(fontSize: 11, color: AppColors.grayLight), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ])),
                  Expanded(flex: 1, child: _TypeBadge(type)),
                  Expanded(flex: 2, child: Text(
                    audience == 'all' ? 'כולם' : audience == 'neighborhood' ? 'שכונה: ${targetValue ?? "—"}' : 'תפקיד: ${targetValue ?? "—"}',
                    style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayText),
                  )),
                  Expanded(flex: 1, child: _StatusPill(status)),
                  if (isWide) Expanded(flex: 1, child: Text('$delivered', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText))),
                  if (isWide) Expanded(flex: 1, child: Text(delivered > 0 ? '${(read / delivered * 100).toInt()}%' : '—', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText))),
                  if (isWide) Expanded(flex: 2, child: Text(
                    sentAt != null ? _formatDate(sentAt) : scheduledAt != null ? 'מתוזמן: ${_formatDate(scheduledAt)}' : '—',
                    style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayText),
                  )),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18, color: AppColors.grayLight),
                    onSelected: (v) => onAction(v, n),
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'edit', child: Text('עריכה', style: GoogleFonts.rubik(fontSize: 13))),
                      if (status == 'draft' || status == 'scheduled') PopupMenuItem(value: 'send', child: Text('שלח עכשיו', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.success))),
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

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
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
  late final TextEditingController _targetValue;
  late final TextEditingController _scheduledAt;

  String _type = 'general';
  String _status = 'draft';
  String _targetAudience = 'all';

  bool get _isEditing => widget.notification != null;

  @override
  void initState() {
    super.initState();
    final n = widget.notification;
    _title = TextEditingController(text: n?['title'] as String? ?? '');
    _body = TextEditingController(text: n?['body'] as String? ?? '');
    _targetValue = TextEditingController(text: n?['target_value'] as String? ?? '');
    _scheduledAt = TextEditingController(text: n?['scheduled_at'] as String? ?? '');

    _type = n?['type'] as String? ?? 'general';
    _status = n?['status'] as String? ?? 'draft';
    _targetAudience = n?['target_audience'] as String? ?? 'all';
  }

  @override
  void dispose() {
    _title.dispose(); _body.dispose(); _targetValue.dispose(); _scheduledAt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650, maxHeight: 600),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Form(
            key: _formKey,
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
                child: Row(children: [
                  Text(_isEditing ? 'עריכת הודעה' : 'הודעה חדשה', style: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
                ]),
              ),
              Expanded(
                child: ListView(padding: const EdgeInsets.all(20), children: [
                  _field('כותרת *', _title, validator: (v) => v == null || v.isEmpty ? 'שדה חובה' : null),
                  _field('תוכן ההודעה *', _body, maxLines: 4, validator: (v) => v == null || v.isEmpty ? 'שדה חובה' : null),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: DropdownButtonFormField<String>(
                      value: _type,
                      decoration: InputDecoration(labelText: 'סוג', labelStyle: GoogleFonts.rubik(fontSize: 13), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                      items: [
                        DropdownMenuItem(value: 'general', child: Text('כללי', style: GoogleFonts.rubik(fontSize: 13))),
                        DropdownMenuItem(value: 'breaking', child: Text('מבזק', style: GoogleFonts.rubik(fontSize: 13))),
                        DropdownMenuItem(value: 'event', child: Text('אירוע', style: GoogleFonts.rubik(fontSize: 13))),
                        DropdownMenuItem(value: 'deal', child: Text('מבצע', style: GoogleFonts.rubik(fontSize: 13))),
                        DropdownMenuItem(value: 'municipal', child: Text('עירוני', style: GoogleFonts.rubik(fontSize: 13))),
                      ],
                      onChanged: (v) => setState(() => _type = v!),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: DropdownButtonFormField<String>(
                      value: _status,
                      decoration: InputDecoration(labelText: 'סטטוס', labelStyle: GoogleFonts.rubik(fontSize: 13), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                      items: [
                        DropdownMenuItem(value: 'draft', child: Text('טיוטה', style: GoogleFonts.rubik(fontSize: 13))),
                        DropdownMenuItem(value: 'scheduled', child: Text('מתוזמן', style: GoogleFonts.rubik(fontSize: 13))),
                        DropdownMenuItem(value: 'sent', child: Text('נשלח', style: GoogleFonts.rubik(fontSize: 13))),
                      ],
                      onChanged: (v) => setState(() => _status = v!),
                    )),
                  ]),
                  const SizedBox(height: 16),
                  Text('קהל יעד', style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _targetAudience,
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                    items: [
                      DropdownMenuItem(value: 'all', child: Text('כולם', style: GoogleFonts.rubik(fontSize: 13))),
                      DropdownMenuItem(value: 'neighborhood', child: Text('לפי שכונה', style: GoogleFonts.rubik(fontSize: 13))),
                      DropdownMenuItem(value: 'role', child: Text('לפי תפקיד', style: GoogleFonts.rubik(fontSize: 13))),
                    ],
                    onChanged: (v) => setState(() => _targetAudience = v!),
                  ),
                  if (_targetAudience != 'all') ...[
                    const SizedBox(height: 8),
                    _field(_targetAudience == 'neighborhood' ? 'שכונה' : 'תפקיד', _targetValue, hint: _targetAudience == 'neighborhood' ? 'אבני חן' : 'הורים'),
                  ],
                  if (_status == 'scheduled') ...[
                    const SizedBox(height: 12),
                    _field('מתוזמן ל', _scheduledAt, hint: '2026-09-01T10:00:00Z'),
                  ],
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
                child: Row(children: [
                  const Spacer(),
                  TextButton(onPressed: () => Navigator.pop(context), child: Text('ביטול', style: GoogleFonts.rubik())),
                  const SizedBox(width: 8),
                  if (!_isEditing || _status == 'draft') ...[
                    OutlinedButton(
                      onPressed: _saving ? null : () => _save(sendNow: true),
                      style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), foregroundColor: AppColors.success),
                      child: Text('שלח עכשיו', style: GoogleFonts.rubik(fontSize: 13)),
                    ),
                    const SizedBox(width: 8),
                  ],
                  FilledButton(
                    onPressed: _saving ? null : () => _save(),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.turquoise, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_isEditing ? 'שמור' : 'צור הודעה', style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w600)),
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

  Future<void> _save({bool sendNow = false}) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final fields = <String, dynamic>{
      'title': _title.text,
      'body': _body.text,
      'type': _type,
      'status': sendNow ? 'sent' : _status,
      'target_audience': _targetAudience,
      'target_value': _targetAudience == 'all' ? null : _targetValue.text.isEmpty ? null : _targetValue.text,
      if (sendNow) 'sent_at': DateTime.now().toIso8601String(),
      if (_status == 'scheduled') 'scheduled_at': _scheduledAt.text.isEmpty ? null : _scheduledAt.text,
    };

    try {
      final notifier = ref.read(adminPushListProvider.notifier);
      if (_isEditing) {
        await notifier.updateNotification(widget.notification!['id'] as String, fields);
      } else {
        fields['read_count'] = sendNow ? 0 : 0;
        fields['delivered_count'] = sendNow ? 0 : 0;
        fields['click_count'] = 0;
        fields['total_recipients'] = _targetAudience == 'all' ? 5400 : 1200;
        await notifier.createNotification(fields);
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
      'sent' => ('נשלח', AppColors.success),
      'scheduled' => ('מתוזמן', AppColors.midBlue),
      'draft' => ('טיוטה', AppColors.gold),
      _ => (status, AppColors.grayLight),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: GoogleFonts.rubik(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge(this.type);

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (type) {
      'breaking' => ('מבזק', AppColors.error),
      'event' => ('אירוע', AppColors.turquoise),
      'deal' => ('מבצע', AppColors.gold),
      'municipal' => ('עירוני', AppColors.midBlue),
      'general' => ('כללי', AppColors.grayLight),
      _ => (type, AppColors.grayLight),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: GoogleFonts.rubik(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
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
