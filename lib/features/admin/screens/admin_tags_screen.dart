import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/admin_tags_provider.dart';
import '../widgets/admin_form_pickers.dart';
import '../admin_language.dart';

class AdminTagsScreen extends ConsumerStatefulWidget {
  const AdminTagsScreen({super.key});
  @override
  ConsumerState<AdminTagsScreen> createState() => _AdminTagsScreenState();
}

class _AdminTagsScreenState extends ConsumerState<AdminTagsScreen> {
  final _searchController = TextEditingController();

  /// Typing fired a search per keystroke, and the answers can arrive out of
  /// order — an early, broader one landing last showed rows that did not
  /// match. Waiting for a pause sends one.
  Timer? _searchDebounce;
  String _sortBy = 'name';

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(adminTagListProvider);
    final isWide = MediaQuery.of(context).size.width > 900;

    return Column(
      children: [
        // Tags look like they label things on the site; today they label
        // nothing, and the client should not have to find that out.
        const _NotShownNote(),

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
                width: isWide ? 280 : 180,
                height: 40,
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: tr('חיפוש תגית...', 'Search tags...'),
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
                  onChanged: (v) {
                    _searchDebounce?.cancel();
                    _searchDebounce = Timer(
                      const Duration(milliseconds: 400),
                      () => ref
                          .read(adminTagListProvider.notifier)
                          .setSearch(v.isEmpty ? null : v),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              _SortChip(tr('שם', 'Name'), _sortBy == 'name', () {
                setState(() => _sortBy = 'name');
                ref.read(adminTagListProvider.notifier).setSortBy('name');
              }),
              _SortChip(tr('שימוש', 'Usage'), _sortBy == 'usage', () {
                setState(() => _sortBy = 'usage');
                ref.read(adminTagListProvider.notifier).setSortBy('usage');
              }),
              const Spacer(),
              if (asyncData.valueOrNull case final l?)
                Text(
                  tr('${l.length} תגיות', '${l.length} tags'),
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 13,
                    color: AppColors.grayText,
                  ),
                ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showEditor(context, null),
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  tr('תגית חדשה', 'New tag'),
                  style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.turquoise,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ─── Tags Grid ───
        Expanded(
          child: asyncData.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                tr('שגיאה בטעינת התגיות: ${adminErrorText(e)}', 'Error loading the tags: ${adminErrorText(e)}'),
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
                        Icons.label_off,
                        size: 48,
                        color: AppColors.grayLight.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        tr('אין תגיות', 'No tags'),
                        style: TextStyle(
                          fontFamily: AppFonts.rubik,
                          color: AppColors.grayText,
                        ),
                      ),
                    ],
                  ),
                );
              }
              // Scrolls: 71 tags run past the bottom of the screen, and the
              // ones below the fold could not be reached.
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: list
                      .map(
                        (tag) => _TagChip(
                          tag: tag,
                          onEdit: () => _showEditor(context, tag),
                          onDelete: () => _confirmDelete(context, tag),
                        ),
                      )
                      .toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showEditor(BuildContext context, Map<String, dynamic>? existing) {
    showDialog(
      context: context,
      builder: (_) => _TagEditorDialog(existing: existing),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Map<String, dynamic> tag,
  ) async {
    final usage = tag['usage_count'] as int? ?? 0;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: adminDir,
        child: AlertDialog(
          title: Text(
            tr('מחיקת תגית', 'Delete tag'),
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
          content: Text(
            // Tags have no hidden state to fall back on, so this one is
            // permanent, and it says so.
            tr('למחוק את התגית "${tag['name']}" לצמיתות? '
            '${usage == 0 ? 'היא לא מוצמדת לשום פריט.' : 'היא תוסר גם מ-$usage פריטים שמוצמדת אליהם.'}', 'Delete the tag "${tag['name']}" permanently? ${usage == 0 ? 'It is not attached to any item.' : 'It will also be removed from the $usage items it is attached to.'}'),
            style: TextStyle(fontFamily: AppFonts.rubik),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                tr('ביטול', 'Cancel'),
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  color: AppColors.grayText,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(tr('מחק', 'Delete'), style: TextStyle(fontFamily: AppFonts.rubik)),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(adminTagListProvider.notifier)
          .deleteTag(tag['id'] as String);
    } catch (e) {
      if (context.mounted) showAdminError(context, tr('המחיקה נכשלה', 'Deleting failed'), e);
    }
  }
}

/// Says where tags show: nowhere yet.
class _NotShownNote extends StatelessWidget {
  const _NotShownNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.adminContentBg,
        border: Border.all(color: AppColors.adminCardBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: AppColors.adminTextLight),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tr('התגיות נשמרות כאן, אך עדיין אינן מוצגות באתר או באפליקציה, '
              'ואף עסק או כתבה אינם מתויגים בהן. הצגת תגיות למשתמשים היא '
              'פיתוח נפרד.', 'Tags are saved here, but they are not shown on the site or in the app yet, and no business or article is tagged with them. Showing tags to users is separate development.'),
              style: TextStyle(
                fontFamily: AppFonts.rubik,
                fontSize: 12,
                height: 1.5,
                color: AppColors.adminTextLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagEditorDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? existing;
  const _TagEditorDialog({this.existing});

  @override
  ConsumerState<_TagEditorDialog> createState() => _TagEditorDialogState();
}

class _TagEditorDialogState extends ConsumerState<_TagEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: widget.existing?['name'] as String? ?? '',
  );
  late final _slug = TextEditingController(
    text: widget.existing?['slug'] as String? ?? '',
  );
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _slug.dispose();
    super.dispose();
  }

  /// The imported slugs are the name with spaces as hyphens, Hebrew kept,
  /// so a new one is made the same way.
  String _slugFrom(String name) => name
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[\s_]+'), '-')
      .replaceAll(RegExp(r'[^\p{L}\p{N}-]', unicode: true), '')
      .replaceAll(RegExp(r'-+'), '-');

  InputDecoration _decoration(String label, {String? hint}) => InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: TextStyle(
      fontFamily: AppFonts.rubik,
      fontSize: 13,
      color: AppColors.grayText,
    ),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final name = _name.text.trim();
    final slug = _slug.text.trim().isEmpty
        ? _slugFrom(name)
        : _slugFrom(_slug.text);
    final notifier = ref.read(adminTagListProvider.notifier);
    try {
      final existing = widget.existing;
      if (existing != null) {
        await notifier.updateTag(existing['id'] as String, {
          'name': name,
          'slug': slug,
        });
      } else {
        await notifier.createTag({'name': name, 'slug': slug});
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      // `name` and `slug` are both unique, so a duplicate is the usual cause.
      if (mounted) showAdminError(context, tr('השמירה נכשלה', 'Saving failed'), e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;
    return Directionality(
      textDirection: adminDir,
      child: AlertDialog(
        title: Text(
          existing == null ? tr('תגית חדשה', 'New tag') : tr('עריכת תגית', 'Edit tag'),
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        content: SizedBox(
          width: 400,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14),
                  decoration: _decoration(tr('שם', 'Name')),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? tr('שדה חובה', 'Required field') : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _slug,
                  style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14),
                  decoration: _decoration('Slug', hint: tr('ריק — ייווצר מהשם', 'Empty — made from the name')),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              tr('ביטול', 'Cancel'),
              style: TextStyle(
                fontFamily: AppFonts.rubik,
                color: AppColors.grayText,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.turquoise,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              existing == null ? tr('צור', 'Create') : tr('שמור', 'Save'),
              style: TextStyle(fontFamily: AppFonts.rubik),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final Map<String, dynamic> tag;
  final VoidCallback onEdit, onDelete;
  const _TagChip({
    required this.tag,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final usage = tag['usage_count'] as int? ?? 0;
    return Material(
      borderRadius: BorderRadius.circular(10),
      color: AppColors.turquoise.withValues(alpha: 0.06),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.label, size: 16, color: AppColors.turquoise),
              const SizedBox(width: 8),
              Text(
                tag['name'] as String? ?? '',
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.navy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$usage',
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grayText,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: onDelete,
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: AppColors.grayLight.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SortChip(this.label, this.selected, this.onTap);
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
