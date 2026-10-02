import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../admin_language.dart';

/// What a push notification opens: an article, event, business or deal
/// chosen from the database, or any address. Stored in
/// `push_campaigns.deep_link` as the app's own path (`/article/<id>`) or the
/// address itself; the app opens a path inside, the sender turns it into the
/// site's address for browsers.
class PushDestinationField extends StatefulWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  const PushDestinationField({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  State<PushDestinationField> createState() => _PushDestinationFieldState();
}

/// The kinds a notification can point at, with their table, the column
/// shown, and the app's path for them.
class _Kind {
  final String table;
  final String nameColumn;
  final String path;
  const _Kind(this.table, this.nameColumn, this.path);
}

const _kinds = {
  'article': _Kind('articles', 'title', '/article/'),
  'event': _Kind('events', 'title', '/event/'),
  'business': _Kind('businesses', 'name', '/business/'),
  'deal': _Kind('offers', 'name', '/deal/'),
};

Map<String, String> get _kindLabels => {
  'none': tr('ללא — פותח את האפליקציה', 'None — opens the app'),
  'article': tr('כתבה', 'Article'),
  'event': tr('אירוע', 'Event'),
  'business': tr('עסק', 'Business'),
  'deal': tr('מבצע', 'Deal'),
  'link': tr('קישור', 'Link'),
};

class _PushDestinationFieldState extends State<PushDestinationField> {
  late String _kind;
  String? _id;
  String? _name;
  late final TextEditingController _link;

  @override
  void initState() {
    super.initState();
    final v = widget.value;
    _kind = 'none';
    _link = TextEditingController();
    if (v == null || v.isEmpty) return;
    for (final e in _kinds.entries) {
      if (v.startsWith(e.value.path)) {
        _kind = e.key;
        _id = v.substring(e.value.path.length);
        _loadName();
        return;
      }
    }
    _kind = 'link';
    _link.text = v;
  }

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  Future<void> _loadName() async {
    final kind = _kinds[_kind];
    if (kind == null || _id == null) return;
    try {
      final row = await SupabaseConfig.client
          .from(kind.table)
          .select(kind.nameColumn)
          .eq('id', _id!)
          .maybeSingle();
      if (mounted) setState(() => _name = row?[kind.nameColumn] as String?);
    } catch (_) {
      // The id is still saved; only its name is missing from the field.
    }
  }

  void _setKind(String kind) {
    setState(() {
      _kind = kind;
      _id = null;
      _name = null;
    });
    widget.onChanged(kind == 'link' ? _text(_link) : null);
  }

  Future<void> _pick() async {
    final kind = _kinds[_kind]!;
    final picked = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _SearchDialog(kind: kind, title: _kindLabels[_kind]!),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _id = picked['id'] as String;
      _name = picked[kind.nameColumn] as String?;
    });
    widget.onChanged('${kind.path}$_id');
  }

  String? _text(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  InputDecoration _decoration(String label, {String? hint}) => InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DropdownButtonFormField<String>(
            initialValue: _kind,
            isExpanded: true,
            decoration: _decoration(tr('לחיצה על ההתראה פותחת', 'Tapping the notification opens')),
            items: [
              for (final e in _kindLabels.entries)
                DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value, style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13)),
                ),
            ],
            onChanged: widget.enabled ? (v) => _setKind(v ?? 'none') : null,
          ),
        ),
        if (_kind == 'link')
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextFormField(
              controller: _link,
              readOnly: !widget.enabled,
              style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
              decoration: _decoration(tr('כתובת', 'Address'), hint: 'https://…'),
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return tr('שדה חובה', 'Required field');
                final uri = Uri.tryParse(t);
                return uri == null || !uri.hasScheme
                    ? tr('כתובת מלאה, כולל https://', 'A full address, with https://')
                    : null;
              },
              onChanged: (_) => widget.onChanged(_text(_link)),
            ),
          ),
        if (_kinds.containsKey(_kind))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: widget.enabled ? _pick : null,
              child: InputDecorator(
                decoration: _decoration(_kindLabels[_kind]!).copyWith(
                  suffixIcon: const Icon(Icons.search, size: 18),
                ),
                child: Text(
                  _id == null
                      ? tr('בחירה…', 'Choose…')
                      : (_name ?? tr('טוען…', 'Loading…')),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 13,
                    color: _id == null ? AppColors.grayLight : null,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Searches one table by its name column, newest first.
class _SearchDialog extends StatefulWidget {
  final _Kind kind;
  final String title;
  const _SearchDialog({required this.kind, required this.title});

  @override
  State<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<_SearchDialog> {
  List<Map<String, dynamic>>? _rows;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _search(String q) async {
    final k = widget.kind;
    var query = SupabaseConfig.client.from(k.table).select('id, ${k.nameColumn}');
    if (q.trim().isNotEmpty) query = query.ilike(k.nameColumn, '%${q.trim()}%');
    try {
      final rows = await query.order('created_at', ascending: false).limit(30);
      if (mounted) setState(() => _rows = List<Map<String, dynamic>>.from(rows));
    } catch (_) {
      if (mounted) setState(() => _rows = const []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
        child: Directionality(
          textDirection: adminDir,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  autofocus: true,
                  style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: tr('חיפוש ${widget.title}', 'Search ${widget.title.toLowerCase()}'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (q) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 300), () => _search(q));
                  },
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: rows == null
                      ? const Center(child: CircularProgressIndicator())
                      : rows.isEmpty
                      ? Center(
                          child: Text(
                            tr('לא נמצא', 'Nothing found'),
                            style: TextStyle(fontFamily: AppFonts.rubik, color: AppColors.grayText),
                          ),
                        )
                      : ListView.builder(
                          itemCount: rows.length,
                          itemBuilder: (_, i) => ListTile(
                            dense: true,
                            title: Text(
                              rows[i][widget.kind.nameColumn] as String? ?? '',
                              style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
                            ),
                            onTap: () => Navigator.pop(context, rows[i]),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
