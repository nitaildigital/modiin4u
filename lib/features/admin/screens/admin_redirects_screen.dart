import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../admin_language.dart';
import '../providers/admin_redirects_provider.dart';
import '../ui/admin_kit.dart';
import '../widgets/admin_form_pickers.dart';

/// Redirects for the website — what Yoast's redirect manager did on
/// WordPress. When a page's address changes or a page goes, a redirect
/// sends visitors and Google from the old address to the new one, and a
/// permanent one (301) carries the old address's place in Google with it.
class AdminRedirectsScreen extends ConsumerStatefulWidget {
  const AdminRedirectsScreen({super.key});

  @override
  ConsumerState<AdminRedirectsScreen> createState() => _AdminRedirectsScreenState();
}

class _AdminRedirectsScreenState extends ConsumerState<AdminRedirectsScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  /// null: all; true: on; false: off.
  bool? _active;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _filter(bool? active) {
    setState(() => _active = active);
    ref.read(adminRedirectListProvider.notifier).setColumnFilter('is_active', active);
  }

  @override
  Widget build(BuildContext context) {
    final k = AdminKit.of(context);
    final rows = ref.watch(adminRedirectListProvider);
    final isWide = MediaQuery.of(context).size.width > 900;

    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: k.accentSoft,
            borderRadius: BorderRadius.circular(k.radius),
          ),
          child: Text(
            tr(
              'כשכתובת של עמוד משתנה או שעמוד יורד, הפניה שולחת מבקרים וגוגל מהכתובת הישנה לחדשה. '
                  'קבועה (301) מעבירה לכתובת החדשה את מקומה של הישנה בגוגל; זמנית (302) לא. '
                  'הפניה שכובתה נשארת ברשימה ואפשר להפעיל אותה שוב. שינוי מגיע לאתר תוך כ-5 דקות.',
              'When a page\'s address changes or a page goes, a redirect sends visitors and Google from the old address to the new one. '
                  'Permanent (301) passes the old address\'s place in Google to the new one; temporary (302) does not. '
                  'A redirect turned off stays in the list and can be turned on again. A change reaches the site within about 5 minutes.',
            ),
            style: k.body.copyWith(fontSize: 13),
          ),
        ),
        AdminListToolbar(
          search: AdminSearchField(
            controller: _searchController,
            width: isWide ? 280 : 180,
            hint: tr('חיפוש כתובת...', 'Search addresses...'),
            onChanged: (v) {
              _searchDebounce?.cancel();
              _searchDebounce = Timer(
                const Duration(milliseconds: 400),
                () => ref.read(adminRedirectListProvider.notifier).setSearch(v.isEmpty ? null : v),
              );
            },
          ),
          filters: [
            AdminFilterChip(tr('הכל', 'All'), _active == null, () => _filter(null)),
            AdminFilterChip(tr('פעילות', 'On'), _active == true, () => _filter(true)),
            AdminFilterChip(tr('כבויות', 'Off'), _active == false, () => _filter(false)),
          ],
          count: switch (rows.valueOrNull) {
            final l? => tr('${l.length} הפניות', '${l.length} redirects'),
            null => null,
          },
          actions: [
            AdminToolbarButton(
              label: tr('הפניה חדשה', 'New redirect'),
              onPressed: () => _edit(null),
            ),
          ],
        ),
        Expanded(
          child: rows.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                tr('שגיאה בטעינת ההפניות: ${adminErrorText(e)}', 'Error loading the redirects: ${adminErrorText(e)}'),
                style: k.body.copyWith(color: k.danger),
              ),
            ),
            data: (list) => list.isEmpty
                ? Center(child: Text(tr('אין הפניות', 'No redirects'), style: k.hint))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _RedirectRow(
                      row: list[i],
                      onEdit: () => _edit(list[i]),
                      onToggle: (on) => _toggle(list[i], on),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  void _edit(Map<String, dynamic>? row) {
    showDialog(
      context: context,
      builder: (_) => _RedirectEditor(existing: row),
    );
  }

  Future<void> _toggle(Map<String, dynamic> row, bool on) async {
    // Turning one on again is checked like a new one: meanwhile another
    // redirect may have made it a loop.
    if (on) {
      final problem = redirectProblem(
        ref.read(adminRedirectListProvider).valueOrNull ?? const [],
        id: row['id'] as String,
        from: row['old_path'] as String,
        to: row['new_path'] as String,
      );
      if (problem != null) {
        showAdminError(context, tr('לא ניתן להפעיל', 'Cannot turn it on'), problem);
        return;
      }
    }
    try {
      await ref.read(adminRedirectListProvider.notifier).update(row['id'] as String, {'is_active': on});
    } catch (e) {
      if (mounted) showAdminError(context, tr('השמירה נכשלה', 'Saving failed'), e);
    }
  }
}

/// Why a redirect from [from] to [to] cannot be on, among [rows] (its own
/// row, [id], aside); null when it can.
String? redirectProblem(
  List<Map<String, dynamic>> rows, {
  String? id,
  required String from,
  required String to,
}) {
  if (from == '/') {
    return tr('אי אפשר להפנות את דף הבית.', 'The home page cannot be redirected.');
  }
  if (from.startsWith('/_next/') || from.startsWith('/api/')) {
    return tr('זו כתובת פנימית של האתר.', 'That is one of the site\'s internal addresses.');
  }
  final toPath = to.split('?').first;
  if (toPath == from) {
    return tr('הכתובת הישנה והחדשה זהות.', 'The old and new addresses are the same.');
  }
  final others = rows.where((r) => r['id'] != id && r['is_active'] == true);
  for (final r in others) {
    if (r['old_path'] == from) {
      return tr('כבר יש הפניה פעילה מהכתובת הזאת.', 'There is already an active redirect from this address.');
    }
  }
  // A chain: the new address is itself sent on. Followed until it ends, so
  // a loop of any length (A → B → A, or longer) is caught.
  final byFrom = {for (final r in others) r['old_path'] as String: r['new_path'] as String};
  var next = toPath;
  final seen = <String>{from};
  while (byFrom.containsKey(next)) {
    if (!seen.add(next)) break;
    next = byFrom[next]!.split('?').first;
    if (next == from) {
      return tr('זה יוצר לולאה: הכתובת החדשה מפנה בחזרה לישנה.', 'This makes a loop: the new address redirects back to the old one.');
    }
  }
  if (byFrom.containsKey(toPath)) {
    return tr('הכתובת החדשה כבר מפנה הלאה (ל-${byFrom[toPath]}). עדיף להפנות ישר לשם.',
        'The new address already redirects on (to ${byFrom[toPath]}). Redirect straight there instead.');
  }
  return null;
}

class _RedirectRow extends StatelessWidget {
  final Map<String, dynamic> row;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggle;
  const _RedirectRow({required this.row, required this.onEdit, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final k = AdminKit.of(context);
    final on = row['is_active'] as bool? ?? false;
    final code = row['status_code'] as int? ?? 301;
    // Addresses read left to right whatever the panel's language.
    final path = k.body.copyWith(fontSize: 13, color: on ? k.ink : k.muted);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: k.surface,
        border: Border.all(color: k.border),
        borderRadius: BorderRadius.circular(k.radius),
      ),
      child: Row(
        children: [
          AdminPill(code == 302 ? tr('302 זמנית', '302 temporary') : tr('301 קבועה', '301 permanent'),
              code == 302 ? k.warning : k.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  SelectableText(row['old_path'] as String? ?? '', style: path),
                  Icon(Icons.arrow_forward, size: 16, color: k.muted),
                  SelectableText(row['new_path'] as String? ?? '', style: path),
                ],
              ),
            ),
          ),
          Switch(value: on, onChanged: onToggle),
          IconButton(
            tooltip: tr('עריכה', 'Edit'),
            icon: Icon(Icons.edit_outlined, size: 18, color: k.inkSoft),
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}

class _RedirectEditor extends ConsumerStatefulWidget {
  final Map<String, dynamic>? existing;
  const _RedirectEditor({this.existing});

  @override
  ConsumerState<_RedirectEditor> createState() => _RedirectEditorState();
}

class _RedirectEditorState extends ConsumerState<_RedirectEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _from;
  late final TextEditingController _to;
  late int _code;
  late bool _active;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final r = widget.existing;
    _from = TextEditingController(text: r?['old_path'] as String? ?? '');
    _to = TextEditingController(text: r?['new_path'] as String? ?? '');
    _code = r?['status_code'] as int? ?? 301;
    _active = r?['is_active'] as bool? ?? true;
  }

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    final from = siteAddress(_from.text)!;
    final to = redirectTarget(_to.text)!;
    if (_active) {
      final problem = redirectProblem(
        ref.read(adminRedirectListProvider).valueOrNull ?? const [],
        id: widget.existing?['id'] as String?,
        from: from,
        to: to,
      );
      if (problem != null) {
        setState(() => _error = problem);
        return;
      }
    }
    setState(() => _saving = true);
    final fields = {'old_path': from, 'new_path': to, 'status_code': _code, 'is_active': _active};
    final notifier = ref.read(adminRedirectListProvider.notifier);
    try {
      if (widget.existing == null) {
        await notifier.create(fields);
      } else {
        await notifier.update(widget.existing!['id'] as String, fields);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e is PostgrestException && e.code == '23505'
            ? tr('כבר יש הפניה מהכתובת הזאת (אולי כבויה) — ערכו אותה.', 'There is already a redirect from this address (perhaps turned off) — edit that one.')
            : tr('השמירה נכשלה: ${adminErrorText(e)}', 'Saving failed: ${adminErrorText(e)}'));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final k = AdminKit.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Directionality(
          textDirection: adminDir,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.existing == null ? tr('הפניה חדשה', 'New redirect') : tr('עריכת הפניה', 'Edit redirect'), style: k.title.copyWith(fontSize: 18)),
                  const SizedBox(height: 18),
                  AdminField(
                    label: tr('מהכתובת *', 'From address *'),
                    controller: _from,
                    hint: '/business/old-name/',
                    helper: tr('הכתובת באתר בלבד, או קישור מלא לאתר.', 'The address on the site only, or a full link to the site.'),
                    textDirection: TextDirection.ltr,
                    validator: (v) => siteAddress(v ?? '') == null
                        ? tr('כתובת באתר, מתחילה ב-/', 'An address on the site, starting with /')
                        : null,
                  ),
                  AdminField(
                    label: tr('לכתובת *', 'To address *'),
                    controller: _to,
                    hint: '/business/new-name/',
                    helper: tr('כתובת באתר, או קישור מלא לאתר אחר.', 'An address on the site, or a full link to another site.'),
                    textDirection: TextDirection.ltr,
                    validator: (v) => redirectTarget(v ?? '') == null
                        ? tr('כתובת באתר (מתחילה ב-/) או קישור מלא', 'An address on the site (starting with /) or a full link')
                        : null,
                  ),
                  Text(tr('סוג', 'Type'), style: k.label),
                  const SizedBox(height: 6),
                  SegmentedButton<int>(
                    segments: [
                      ButtonSegment(value: 301, label: Text(tr('301 קבועה', '301 permanent'))),
                      ButtonSegment(value: 302, label: Text(tr('302 זמנית', '302 temporary'))),
                    ],
                    selected: {_code},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) => setState(() => _code = s.first),
                  ),
                  const SizedBox(height: 12),
                  AdminSwitchRow(
                    label: tr('פעילה', 'On'),
                    value: _active,
                    onChanged: (v) => setState(() => _active = v),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: k.body.copyWith(color: k.danger, fontSize: 13)),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AdminButton(label: tr('ביטול', 'Cancel'), primary: false, onPressed: () => Navigator.pop(context)),
                      const SizedBox(width: 8),
                      AdminButton(
                        label: tr('שמירה', 'Save'),
                        icon: Icons.check,
                        busy: _saving,
                        onPressed: _saving ? null : _save,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
