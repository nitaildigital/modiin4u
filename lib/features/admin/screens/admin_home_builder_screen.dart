import 'dart:convert';

import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import '../../../core/theme/app_colors.dart';
import '../providers/admin_home_builder_provider.dart';
import '../admin_language.dart';
import '../ui/admin_kit.dart';

class AdminHomeBuilderScreen extends ConsumerStatefulWidget {
  const AdminHomeBuilderScreen({super.key});

  @override
  ConsumerState<AdminHomeBuilderScreen> createState() =>
      _AdminHomeBuilderScreenState();
}

class _AdminHomeBuilderScreenState
    extends ConsumerState<AdminHomeBuilderScreen> {
  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(adminHomeBuilderProvider);
    final isWide = MediaQuery.of(context).size.width > 900;

    return Column(
      children: [
        // ─── Stats bar ───
        if (asyncData.valueOrNull case final list?)
          Builder(
            builder: (_) {
              final active = list.where((b) => b['is_active'] == true).length;
              final published = list
                  .where((b) => b['published'] == true)
                  .length;
              final drafts = list.length - published;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
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
                    _StatChip(tr('סה״כ בלוקים', 'Total blocks'), '${list.length}', AppColors.navy),
                    const SizedBox(width: 16),
                    _StatChip(tr('פעילים', 'Active'), '$active', AppColors.success),
                    const SizedBox(width: 16),
                    _StatChip(tr('מפורסמים', 'Published'), '$published', AppColors.midBlue),
                    const SizedBox(width: 16),
                    _StatChip(tr('טיוטות', 'Drafts'), '$drafts', AppColors.gold),
                  ],
                ),
              );
            },
          ),

        // ─── Toolbar ───
        AdminListToolbar(
          search: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.dashboard_customize, size: 20, color: AppColors.navy),
              const SizedBox(width: 8),
              Text(
                tr('בונה מסך הבית', 'Home screen builder'),
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          actions: [
            AdminToolbarButton(
              primary: false,
              icon: Icons.publish,
              label: tr('פרסם הכל', 'Publish all'),
              onPressed: _publishAll,
            ),
            AdminToolbarButton(
              label: tr('בלוק חדש', 'New block'),
              onPressed: () => _showEditor(context, ref),
            ),
          ],
        ),

        // ─── Block List ───
        Expanded(
          child: asyncData.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                tr('שגיאה: $e', 'Error: $e'),
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  color: AppColors.error,
                ),
              ),
            ),
            data: (list) {
              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.dashboard_customize_outlined,
                        size: 48,
                        color: AppColors.grayLight.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        tr('אין בלוקים', 'No blocks'),
                        style: TextStyle(
                          fontFamily: AppFonts.rubik,
                          color: AppColors.grayText,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ReorderableListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: list.length,
                onReorder: (oldIndex, newIndex) {
                  if (newIndex > oldIndex) newIndex--;
                  final blockId = list[oldIndex]['id'] as String;
                  // The index in the list, as the notifier takes it; this
                  // used to add one, so every drag landed a row too low.
                  _run(
                    () => ref
                        .read(adminHomeBuilderProvider.notifier)
                        .reorder(blockId, newIndex),
                  );
                },
                itemBuilder: (_, i) {
                  final b = list[i];
                  final isActive = b['is_active'] as bool? ?? false;
                  final isPublished = b['published'] as bool? ?? false;
                  final blockType = b['block_type'] as String? ?? '';
                  final version = b['version'] as int? ?? 1;

                  return Container(
                    key: ValueKey(b['id']),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isActive
                            ? AppColors.midBlue.withValues(alpha: 0.3)
                            : AppColors.border.withValues(alpha: 0.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.drag_indicator,
                            size: 20,
                            color: AppColors.grayLight,
                          ),
                          Text(
                            '#${b['sort_order']}',
                            style: TextStyle(
                              fontFamily: AppFonts.rubik,
                              fontSize: 10,
                              color: AppColors.grayLight,
                            ),
                          ),
                        ],
                      ),
                      title: Row(
                        children: [
                          Icon(
                            _blockIcon(blockType),
                            size: 20,
                            color: isActive
                                ? AppColors.midBlue
                                : AppColors.grayLight,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _blockHeadline(b),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppFonts.rubik,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.navy,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.navy.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                homeBlockTypes[blockType] ?? blockType,
                                style: TextStyle(
                                  fontFamily: AppFonts.rubik,
                                  fontSize: 10,
                                  color: AppColors.navy,
                                ),
                              ),
                            ),
                            // Kept here, but no screen draws this kind yet.
                            if (!homeBlockTypesShown.contains(blockType)) ...[
                              const SizedBox(width: 6),
                              Text(
                                tr('לא מוצג באתר', 'Not shown on the site'),
                                style: TextStyle(
                                  fontFamily: AppFonts.rubik,
                                  fontSize: 10,
                                  color: AppColors.adminTextLight,
                                ),
                              ),
                            ],
                            const SizedBox(width: 8),
                            Text(
                              'v$version',
                              style: TextStyle(
                                fontFamily: AppFonts.rubik,
                                fontSize: 10,
                                color: AppColors.grayLight,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (isPublished)
                              AdminPill(tr('מפורסם', 'Published'), AdminKit.of(context).success)
                            else
                              AdminPill(tr('טיוטה', 'Draft'), AdminKit.of(context).inkSoft),
                            if (isWide && b['audience'] != null) ...[
                              const SizedBox(width: 12),
                              Text(
                                tr('קהל: ${b['audience']}', 'Audience: ${b['audience']}'),
                                style: TextStyle(
                                  fontFamily: AppFonts.rubik,
                                  fontSize: 10,
                                  color: AppColors.grayLight,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: isActive,
                            onChanged: (_) => _run(
                              () => ref
                                  .read(adminHomeBuilderProvider.notifier)
                                  .toggleActive(b['id'] as String),
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert,
                              size: 18,
                              color: AppColors.grayLight,
                            ),
                            onSelected: (v) => _handleAction(v, b),
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text(
                                  tr('עריכה', 'Edit'),
                                  style: TextStyle(
                                    fontFamily: AppFonts.rubik,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              if (isActive)
                                PopupMenuItem(
                                  value: 'deactivate',
                                  child: Text(
                                    tr('הסרה מהאתר (השבתה)', 'Take off the site (disable)'),
                                    style: TextStyle(
                                      fontFamily: AppFonts.rubik,
                                      fontSize: 13,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _blockIcon(String type) => switch (type) {
    'alert' => Icons.campaign_outlined,
    'hero' => Icons.view_carousel,
    'news_grid' => Icons.article,
    'event_carousel' => Icons.event,
    'business_carousel' => Icons.store,
    'restaurant_carousel' => Icons.restaurant,
    'banner' => Icons.ad_units,
    'offers' => Icons.local_offer,
    'game' => Icons.sports_esports,
    'ai_search' => Icons.auto_awesome,
    'map_preview' => Icons.map,
    'real_estate' => Icons.apartment,
    'steps_challenge' => Icons.directions_walk,
    'custom_promo' => Icons.star_outline,
    'weather' => Icons.wb_sunny_outlined,
    _ => Icons.widgets,
  };

  /// The row's title, and for a notice what it says, since that is what the
  /// site shows.
  String _blockHeadline(Map<String, dynamic> b) {
    final title = (b['title'] as String? ?? '').trim();
    if (b['block_type'] != 'alert') return title;
    final config = b['config'] is Map ? b['config'] as Map : const {};
    final message = (config['message_he'] as String? ?? '').trim();
    if (message.isEmpty) return title;
    return title.isEmpty ? message : '$title: $message';
  }

  Future<void> _handleAction(String action, Map<String, dynamic> b) async {
    final notifier = ref.read(adminHomeBuilderProvider.notifier);
    final id = b['id'] as String;
    switch (action) {
      case 'edit':
        _showEditor(context, ref, block: b);
      case 'deactivate':
        final done = await _run(() => notifier.deactivateBlock(id));
        if (done && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                tr('"${_blockHeadline(b)}" הוסר מהאתר ונשמר כאן כמושבת. '
                'המתג בשורה שלו מחזיר אותו.', '"${_blockHeadline(b)}" was taken off the site and kept here as disabled. The switch on its row brings it back.'),
                style: TextStyle(fontFamily: AppFonts.rubik),
              ),
              duration: const Duration(seconds: 6),
              action: SnackBarAction(
                label: tr('ביטול', 'Cancel'),
                onPressed: () => _run(() => notifier.toggleActive(id)),
              ),
            ),
          );
        }
    }
  }

  /// Publishing every block is not undoable one by one, so it asks first.
  Future<void> _publishAll() async {
    final ok = await _confirm(
      tr('לפרסם את כל הבלוקים?', 'Publish all blocks?'),
      tr('כל בלוק פעיל שעדיין לא פורסם יפורסם עכשיו — כולל טיוטות של הודעות, '
          'שיופיעו באתר. אפשר גם לפרסם בלוק אחד מתוך העריכה שלו.', 'Every active block not yet published will be published now — including notice drafts, which will appear on the site. You can also publish one block from its editor.'),
      tr('פרסום הכל', 'Publish all'),
    );
    if (ok) {
      await _run(
        () => ref.read(adminHomeBuilderProvider.notifier).publishAll(),
      );
    }
  }

  /// Runs a write and says so when it fails, rather than failing silently.
  /// True when it went through.
  Future<bool> _run(Future<void> Function() action) async {
    try {
      await action();
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr('הפעולה נכשלה: ${_why(e)}', 'The action failed: ${_why(e)}'),
            style: TextStyle(fontFamily: AppFonts.rubik),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return false;
    }
  }

  Future<bool> _confirm(String title, String body, String action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: adminDir,
        child: AlertDialog(
          title: Text(
            title,
            style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 16),
          ),
          content: Text(
            body,
            style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('חזרה', 'Back'), style: TextStyle(fontFamily: AppFonts.rubik)),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.midBlue,
              ),
              child: Text(action, style: TextStyle(fontFamily: AppFonts.rubik)),
            ),
          ],
        ),
      ),
    );
    return ok ?? false;
  }

  void _showEditor(
    BuildContext context,
    WidgetRef ref, {
    Map<String, dynamic>? block,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _BlockEditorDialog(block: block),
    );
  }
}

// ─── Editor Dialog ───

/// One home block. For the notice (`alert`) it edits every field the website
/// reads — the label and the sentence in Hebrew and English, where "View
/// details" leads and what it says, the dates, and whether it is published.
///
/// The form used to offer eight block types the `block_type` enum does not
/// have (a new block started as `hero_banner`, which the database refused),
/// left out `alert`, and sent `config` as `{}` — which the save then dropped,
/// so nothing a notice says could be written from here.
class _BlockEditorDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? block;
  const _BlockEditorDialog({this.block});

  @override
  ConsumerState<_BlockEditorDialog> createState() => _BlockEditorDialogState();
}

class _BlockEditorDialogState extends ConsumerState<_BlockEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  String? _error;

  late final TextEditingController _title;
  late final TextEditingController _sortOrder;
  late final TextEditingController _labelHe;
  late final TextEditingController _labelEn;
  late final TextEditingController _messageHe;
  late final TextEditingController _messageEn;
  late final TextEditingController _url;
  late final TextEditingController _linkLabelHe;
  late final TextEditingController _linkLabelEn;
  late final TextEditingController _configJson;
  String _blockType = 'alert';
  String _audience = 'all';
  bool _isActive = true;
  bool _published = false;
  DateTime? _startAt;
  DateTime? _endAt;

  /// The row's config as it was loaded. A notice's fields are written over
  /// it, so keys this form does not show are kept rather than wiped.
  late final Map<String, dynamic> _config;

  bool get _isEditing => widget.block != null;
  bool get _isAlert => _blockType == 'alert';

  @override
  void initState() {
    super.initState();
    final b = widget.block;
    _config = b?['config'] is Map
        ? Map<String, dynamic>.from(b!['config'] as Map)
        : <String, dynamic>{};
    String cfg(String key) => _config[key] is String ? _config[key] : '';

    _title = TextEditingController(text: b?['title'] as String? ?? '');
    _sortOrder = TextEditingController(
      text: (b?['sort_order'] as int?)?.toString() ?? '',
    );
    _labelHe = TextEditingController(text: cfg('title_he'));
    _labelEn = TextEditingController(text: cfg('title_en'));
    _messageHe = TextEditingController(text: cfg('message_he'));
    _messageEn = TextEditingController(text: cfg('message_en'));
    _url = TextEditingController(text: cfg('url'));
    _linkLabelHe = TextEditingController(text: cfg('link_label_he'));
    _linkLabelEn = TextEditingController(text: cfg('link_label_en'));
    _configJson = TextEditingController(
      text: const JsonEncoder.withIndent('  ').convert(_config),
    );
    // A new block starts as a notice: it is the one kind the site shows.
    _blockType = b?['block_type'] as String? ?? 'alert';
    _audience = b?['audience'] as String? ?? 'all';
    _isActive = b?['is_active'] as bool? ?? true;
    _published = b?['published'] as bool? ?? false;
    _startAt = DateTime.tryParse(b?['start_at'] as String? ?? '')?.toLocal();
    _endAt = DateTime.tryParse(b?['end_at'] as String? ?? '')?.toLocal();
    for (final c in [
      _labelHe,
      _messageHe,
      _linkLabelHe,
      _url,
      _title,
      _sortOrder,
    ]) {
      c.addListener(_refresh);
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final c in [
      _title,
      _sortOrder,
      _labelHe,
      _labelEn,
      _messageHe,
      _messageEn,
      _url,
      _linkLabelHe,
      _linkLabelEn,
      _configJson,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 860),
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
                        _isEditing ? tr('עריכת בלוק', 'Edit block') : tr('בלוק חדש', 'New block'),
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDropdown(
                          tr('סוג בלוק', 'Block type'),
                          _blockType,
                          {
                            ...homeBlockTypes,
                            if (!homeBlockTypes.containsKey(_blockType))
                              _blockType: _blockType,
                          },
                          (v) => setState(() => _blockType = v!),
                        ),
                        if (!homeBlockTypesShown.contains(_blockType)) ...[
                          const SizedBox(height: 6),
                          Text(
                            tr('האתר והאפליקציה עדיין לא מציגים בלוק מסוג זה; הוא נשמר כאן בלבד.',
                                'The site and the app do not show this kind of block yet; it is only kept here.'),
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 12,
                              color: AppColors.adminTextLight,
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        _buildField(
                          _isAlert ? tr('שם פנימי', 'Internal name') : tr('כותרת', 'Title'),
                          _title,
                          hint: _isAlert ? tr('עדכון תנועה', 'Traffic update') : tr('עסקים מומלצים', 'Recommended businesses'),
                          helper: _isAlert
                              ? tr('מופיע ברשימה כאן; באתר הוא משמש כתווית רק כשאין תווית למטה', 'Shown in the list here; on the site it is used as the label only when there is no label below')
                              : null,
                        ),
                        const SizedBox(height: 14),
                        if (_isAlert) ..._alertFields() else _configField(),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateField(
                                tr('מוצג מ-', 'Shown from'),
                                _startAt,
                                empty: tr('מיד', 'Immediately'),
                                onPick: (d) => setState(
                                  () => _startAt = DateTime(
                                    d.year,
                                    d.month,
                                    d.day,
                                  ),
                                ),
                                onClear: () => setState(() => _startAt = null),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDateField(
                                tr('מוצג עד (כולל היום הזה)', 'Shown until (including that day)'),
                                _endAt,
                                empty: tr('ללא סיום', 'No end'),
                                onPick: (d) => setState(
                                  () => _endAt = DateTime(
                                    d.year,
                                    d.month,
                                    d.day,
                                    23,
                                    59,
                                  ),
                                ),
                                onClear: () => setState(() => _endAt = null),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildField(
                                tr('סדר', 'Order'),
                                _sortOrder,
                                hint: '0',
                                helper: tr('מספר נמוך מופיע קודם', 'A lower number appears first'),
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  final t = (v ?? '').trim();
                                  if (t.isEmpty) return null;
                                  return int.tryParse(t) == null
                                      ? tr('מספר שלם', 'A whole number')
                                      : null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDropdown(
                                tr('קהל יעד', 'Target audience'),
                                _audience,
                                {
                                  'all': tr('כולם', 'Everyone'),
                                  'new': tr('משתמשים חדשים', 'New users'),
                                  'returning': tr('חוזרים', 'Returning'),
                                  if (!const {
                                    'all',
                                    'new',
                                    'returning',
                                  }.contains(_audience))
                                    _audience: _audience,
                                },
                                (v) => setState(() => _audience = v!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            tr('פעיל', 'Active'),
                            style: TextStyle(
                              fontFamily: AppFonts.rubik,
                              fontSize: 14,
                            ),
                          ),
                          value: _isActive,
                          onChanged: (v) => setState(() => _isActive = v),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            tr('מפורסם באתר', 'Published on the site'),
                            style: TextStyle(
                              fontFamily: AppFonts.rubik,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            tr('כבוי = טיוטה שרק כאן רואים', 'Off = a draft only seen here'),
                            style: TextStyle(
                              fontFamily: AppFonts.rubik,
                              fontSize: 11,
                              color: AppColors.grayText,
                            ),
                          ),
                          value: _published,
                          activeThumbColor: AppColors.success,
                          onChanged: (v) => setState(() => _published = v),
                        ),
                        if (_isAlert) ...[
                          const SizedBox(height: 8),
                          _NoticeHint(text: _siteHint()),
                        ] else ...[
                          const SizedBox(height: 8),
                          Text(
                            tr('האתר והאפליקציה עדיין לא קוראים בלוק מסוג זה — '
                            'הוא נשמר כאן לסידור בלבד. מה שמוצג באתר מתוך הבונה '
                            'הוא ההודעה ("הודעה באתר").', 'The site and the app do not read this kind of block yet — it is kept here for ordering only. What the site shows from the builder is the notice ("Site notice").'),
                            style: TextStyle(
                              fontFamily: AppFonts.rubik,
                              fontSize: 12,
                              color: AppColors.gold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          tr('סגירה', 'Close'),
                          style: TextStyle(
                            fontFamily: AppFonts.rubik,
                            fontSize: 13,
                            color: AppColors.grayText,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _error == null
                            ? const SizedBox.shrink()
                            : Text(
                                _error!,
                                style: TextStyle(
                                  fontFamily: AppFonts.rubik,
                                  fontSize: 12,
                                  color: AppColors.error,
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.midBlue,
                          minimumSize: const Size(120, 42),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isEditing ? tr('עדכון', 'Update') : tr('יצירה', 'Create'),
                                style: TextStyle(
                                  fontFamily: AppFonts.rubik,
                                  fontSize: 14,
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

  // ─── The notice ───

  List<Widget> _alertFields() {
    String? required(String? v) => (v ?? '').trim().isEmpty ? tr('שדה חובה', 'Required field') : null;
    return [
      _NoticePreview(
        label: _labelHe.text.trim().isNotEmpty
            ? _labelHe.text.trim()
            : _title.text.trim(),
        message: _messageHe.text.trim(),
        link: _url.text.trim().isEmpty
            ? null
            : (_linkLabelHe.text.trim().isEmpty
                  ? tr('לפרטים', 'Details')
                  : _linkLabelHe.text.trim()),
      ),
      const SizedBox(height: 14),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildField(
              tr('תווית מודגשת (עברית)', 'Highlighted label (Hebrew)'),
              _labelHe,
              hint: tr('עדכון תנועה', 'Traffic update'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildField(
              'Label (English)',
              _labelEn,
              hint: 'Traffic update',
              ltr: true,
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      _buildField(
        tr('ההודעה (עברית)', 'The message (Hebrew)'),
        _messageHe,
        hint: tr('עבודות בכביש ברחוב בגין — צפויים עיכובים באזור', 'Roadworks on Begin Street — delays expected in the area'),
        maxLines: 2,
        validator: required,
      ),
      const SizedBox(height: 14),
      _buildField(
        'Message (English)',
        _messageEn,
        hint: 'Road work on Begin St. - expect delays in the area',
        helper: tr('האתר מוצג גם באנגלית; זה הנוסח שם', 'The site is also shown in English; this is the wording there'),
        maxLines: 2,
        ltr: true,
        validator: required,
      ),
      const SizedBox(height: 14),
      _buildField(
        tr('קישור "לפרטים"', '"Details" link'),
        _url,
        hint: tr('/news  או  https://…', '/news  or  https://…'),
        helper: tr('עמוד באתר (מתחיל ב-/) או כתובת מלאה. ריק = בלי קישור "לפרטים"', 'A page on the site (starting with /) or a full address. Empty = no "Details" link'),
        ltr: true,
        validator: (v) {
          final t = (v ?? '').trim();
          if (t.isEmpty) return null;
          return _normalizeLink(t) == null
              ? tr('כתובת לא תקינה — /news או https://example.co.il', 'Invalid address — /news or https://example.co.il')
              : null;
        },
      ),
      const SizedBox(height: 14),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildField(
              tr('נוסח הקישור (עברית)', 'Link wording (Hebrew)'),
              _linkLabelHe,
              hint: tr('לפרטים', 'Details'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildField(
              'Link text (English)',
              _linkLabelEn,
              hint: 'View details',
              ltr: true,
            ),
          ),
        ],
      ),
    ];
  }

  /// Whether this notice will be the one on the home page. The site shows a
  /// single notice: the first published, active one, by order, whose dates
  /// hold today.
  String _siteHint() {
    final now = DateTime.now();
    final reasons = <String>[
      if (!_published) tr('לא מפורסם (טיוטה)', 'Not published (draft)'),
      if (!_isActive) tr('מושבת', 'Disabled'),
      if (_startAt != null && _startAt!.isAfter(now))
        tr('יתחיל ב-${_fmtDate(_startAt!)}', 'Starts on ${_fmtDate(_startAt!)}'),
      if (_endAt != null && !_endAt!.isAfter(now)) tr('תאריך הסיום עבר', 'The end date has passed'),
    ];
    if (reasons.isNotEmpty) {
      return tr('לא יוצג באתר עכשיו: ${reasons.join(' · ')}.', 'Not shown on the site now: ${reasons.join(' · ')}.');
    }

    final order = _orderToSave;
    final others = (ref.read(adminHomeBuilderProvider).valueOrNull ?? const [])
        .where(
          (b) =>
              b['id'] != widget.block?['id'] &&
              b['block_type'] == 'alert' &&
              b['is_active'] == true &&
              b['published'] == true &&
              _inWindow(b, now) &&
              ((b['sort_order'] as int?) ?? 0) <= order,
        )
        .toList();
    if (others.isNotEmpty) {
      return tr('לא יוצג: באתר מוצגת הודעה אחת בלבד, והודעה אחרת '
          '("${others.first['title'] ?? ''}") קודמת לה בסדר. '
          'השביתו אותה או תנו להודעה הזו מספר סדר נמוך יותר.', 'Not shown: the site shows only one notice, and another notice ("${others.first['title'] ?? ''}") comes before it in the order. Disable it or give this notice a lower order number.');
    }
    final until = _endAt == null ? '' : tr(' עד ${_fmtDate(_endAt!)}', ' to ${_fmtDate(_endAt!)}');
    return tr('תוצג בעמוד הבית של האתר$until.', 'Will be shown on the site\'s home page$until.');
  }

  /// The order as it will be saved: as typed, else the row's own, else the
  /// end of the list.
  int get _orderToSave =>
      int.tryParse(_sortOrder.text.trim()) ??
      (widget.block?['sort_order'] as int?) ??
      99;

  static bool _inWindow(Map<String, dynamic> b, DateTime now) {
    final start = DateTime.tryParse(b['start_at'] as String? ?? '');
    final end = DateTime.tryParse(b['end_at'] as String? ?? '');
    if (start != null && start.isAfter(now)) return false;
    if (end != null && !end.isAfter(now)) return false;
    return true;
  }

  /// A page on this site (`/…`) as it is, a full address as it is, and a bare
  /// "example.co.il" with its https://; null for anything else. The site
  /// opens `/…` inside itself and anything else in a new tab.
  static String? _normalizeLink(String text) {
    if (text.startsWith('/')) return text;
    final withScheme =
        RegExp(r'^https?://', caseSensitive: false).hasMatch(text)
        ? text
        : 'https://$text';
    final uri = Uri.tryParse(withScheme);
    if (uri == null || uri.host.isEmpty || !uri.host.contains('.')) {
      return null;
    }
    return withScheme;
  }

  // ─── Other kinds ───

  /// The block's settings as JSON, for the kinds that have no form of their
  /// own yet — `items_count`, `placement` and the like.
  Widget _configField() {
    return _buildField(
      tr('הגדרות (JSON)', 'Settings (JSON)'),
      _configJson,
      hint: '{"items_count": 4}',
      maxLines: 5,
      ltr: true,
      validator: (v) {
        final t = (v ?? '').trim();
        if (t.isEmpty) return null;
        try {
          return jsonDecode(t) is Map ? null : tr('צריך להיות אובייקט {…}', 'Must be an object {…}');
        } on FormatException {
          return tr('JSON לא תקין', 'Invalid JSON');
        }
      },
    );
  }

  // ─── Saving ───

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    if (_startAt != null && _endAt != null && !_endAt!.isAfter(_startAt!)) {
      setState(() => _error = tr('תאריך הסיום חייב להיות אחרי תאריך ההתחלה', 'The end date must be after the start date'));
      return;
    }

    final Map<String, dynamic> config;
    if (_isAlert) {
      // Each text under `<key>_he` / `<key>_en`, the names the site reads;
      // an emptied field is removed rather than stored empty.
      config = {..._config};
      void put(String key, TextEditingController c) {
        final t = c.text.trim();
        if (t.isEmpty) {
          config.remove(key);
        } else {
          config[key] = t;
        }
      }

      put('title_he', _labelHe);
      put('title_en', _labelEn);
      put('message_he', _messageHe);
      put('message_en', _messageEn);
      put('link_label_he', _linkLabelHe);
      put('link_label_en', _linkLabelEn);
      final link = _normalizeLink(_url.text.trim());
      if (link == null) {
        config.remove('url');
      } else {
        config['url'] = link;
      }
    } else {
      final t = _configJson.text.trim();
      config = t.isEmpty
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(jsonDecode(t) as Map);
    }

    setState(() => _saving = true);
    final notifier = ref.read(adminHomeBuilderProvider.notifier);
    final title = _title.text.trim();
    final wasPublished = widget.block?['published'] == true;
    final data = <String, dynamic>{
      'title': title.isEmpty ? null : title,
      'block_type': _blockType,
      'config': config,
      'sort_order': _orderToSave,
      'audience': _audience,
      'is_active': _isActive,
      'start_at': _startAt?.toUtc().toIso8601String(),
      'end_at': _endAt?.toUtc().toIso8601String(),
      'published': _published,
      // Stamped when a block goes live, not on every edit of a live one.
      if (_published && !wasPublished) ...{
        'published_at': DateTime.now().toUtc().toIso8601String(),
        'published_by': await notifier.currentAdminId(),
      },
    };
    try {
      if (_isEditing) {
        await notifier.updateBlock(widget.block!['id'] as String, data);
      } else {
        await notifier.createBlock(data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = tr('השמירה נכשלה: ${_why(e)}', 'Saving failed: ${_why(e)}');
        });
      }
    }
  }

  // ─── Fields ───

  InputDecoration _decoration({String? hint, String? helper}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: AppFonts.rubik,
          fontSize: 13,
          color: AppColors.grayLight,
        ),
        helperText: helper,
        helperMaxLines: 2,
        helperStyle: TextStyle(
          fontFamily: AppFonts.rubik,
          fontSize: 11,
          color: AppColors.grayText,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
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
          borderSide: const BorderSide(color: AppColors.midBlue),
        ),
      );

  Widget _labelled(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.grayText,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl, {
    String? hint,
    String? helper,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool ltr = false,
  }) {
    return _labelled(
      label,
      TextFormField(
        controller: ctrl,
        validator: validator,
        maxLines: maxLines,
        keyboardType: keyboardType,
        textDirection: ltr ? TextDirection.ltr : null,
        style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14),
        decoration: _decoration(hint: hint, helper: helper),
      ),
    );
  }

  Widget _buildDateField(
    String label,
    DateTime? value, {
    required String empty,
    required ValueChanged<DateTime> onPick,
    required VoidCallback onClear,
  }) {
    return _labelled(
      label,
      InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            locale: adminLocale,
            context: context,
            initialDate: value ?? now,
            firstDate: DateTime(now.year - 2),
            lastDate: DateTime(now.year + 5),
          );
          if (picked != null) onPick(picked);
        },
        child: InputDecorator(
          decoration: _decoration().copyWith(
            suffixIcon: value == null
                ? const Icon(Icons.calendar_today_outlined, size: 16)
                : IconButton(
                    tooltip: tr('ניקוי', 'Clear'),
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: onClear,
                  ),
          ),
          child: Text(
            value == null ? empty : _fmtDate(value),
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontSize: 14,
              color: value == null ? AppColors.grayLight : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    Map<String, String> items,
    ValueChanged<String?> onChanged,
  ) {
    return _labelled(
      label,
      DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        items: items.entries
            .map(
              (e) => DropdownMenuItem(
                value: e.key,
                child: Text(
                  e.value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14),
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
        decoration: _decoration(),
      ),
    );
  }
}

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// The notice as the home page draws it — the pale amber bar with the bell —
/// so the wording can be judged before it goes out.
class _NoticePreview extends StatelessWidget {
  final String label;
  final String message;
  final String? link;
  const _NoticePreview({
    required this.label,
    required this.message,
    required this.link,
  });

  @override
  Widget build(BuildContext context) {
    final text = TextStyle(
      fontFamily: AppFonts.rubik,
      fontSize: 12,
      color: Colors.black,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF5E1),
        border: Border.all(color: const Color(0xFFFFD89A)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_none,
            size: 20,
            color: Color(0xFFE8A33D),
          ),
          const SizedBox(width: 9),
          if (label.isNotEmpty) ...[
            Text(
              label.endsWith(':') ? label : '$label:',
              style: text.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Text(
              message.isEmpty ? '…' : message,
              style: text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (link != null) ...[
            const SizedBox(width: 12),
            Text(
              link!,
              style: text.copyWith(
                color: AppColors.midBlue,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Whether the notice will be on the home page, in one line.
class _NoticeHint extends StatelessWidget {
  final String text;
  const _NoticeHint({required this.text});

  @override
  Widget build(BuildContext context) {
    final live = text.startsWith(tr('תוצג', 'Will be shown'));
    final color = live ? AppColors.success : AppColors.gold;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            live ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: AppFonts.rubik,
                fontSize: 13,
                color: AppColors.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper Widgets ───

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontSize: 12,
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// What went wrong, in the database's own words rather than the exception's
/// wrapper — "value … is out of range", not "PostgrestException(message: …".
String _why(Object e) => e is PostgrestException ? e.message : '$e';
