import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../site_pages/widgets/site_page_body.dart';
import '../providers/admin_site_pages_provider.dart';
import '../widgets/admin_load_error.dart';
import '../admin_language.dart';
import '../ui/admin_kit.dart';

/// עמודי מידע — About Us and the Accessibility Statement.
///
/// The website's footer links to both, and the accessibility statement is
/// required by law, but the words are the client's: the pages were seeded
/// with their names and nothing else. Here he writes each in Hebrew and
/// English and publishes it; until then the site says the content will be
/// published soon.
///
/// The pages are fixed, so there is no "new page" and no delete. Taking one
/// down is switching it back to unpublished.
class AdminSitePagesScreen extends ConsumerWidget {
  const AdminSitePagesScreen({super.key});

  /// Where each page lives on the site, shown so the client can open it.
  static const _paths = {
    'about': '/about',
    'accessibility': '/accessibility',
    'terms': '/terms',
    'privacy': '/privacy',
    'delete-account': '/delete-account',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminSitePagesProvider);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
            ),
          ),
          child: Text(
            tr('העמודים שהקישורים בתחתית האתר מובילים אליהם. עמוד שלא פורסם '
            'מציג לגולשים "תוכן העמוד יפורסם בקרוב".', 'The pages the links at the bottom of the site lead to. An unpublished page shows visitors "The page content will be published soon".'),
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontSize: 13,
              color: AppColors.grayText,
            ),
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => AdminLoadError(
              message: tr('שגיאה בטעינת עמודי המידע', 'Error loading the info pages'),
              error: e,
              onRetry: () => ref.read(adminSitePagesProvider.notifier).load(),
            ),
            data: (pages) {
              if (pages.isEmpty) {
                // The two rows are seeded by migration 00037; none means it
                // has not run on this database.
                return Center(
                  child: Text(
                    tr('לא נמצאו עמודים — יש להריץ את מיגרציה 00037.', 'No pages found — migration 00037 must be run.'),
                    style: TextStyle(
                      fontFamily: AppFonts.rubik,
                      color: AppColors.grayText,
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: pages.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _PageCard(
                  page: pages[i],
                  path: _paths[pages[i]['slug']] ?? '/${pages[i]['slug']}',
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PageCard extends ConsumerWidget {
  final Map<String, dynamic> page;
  final String path;
  const _PageCard({required this.page, required this.path});

  String _text(String key) => (page[key] as String? ?? '').trim();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final published = page['is_published'] as bool? ?? false;
    final hasHe = _text('body_he').isNotEmpty;
    final hasEn = _text('body_en').isNotEmpty;
    final updated = DateTime.tryParse(
      page['updated_at'] as String? ?? '',
    )?.toLocal();
    final small = TextStyle(
      fontFamily: AppFonts.rubik,
      fontSize: 12,
      color: AppColors.grayText,
    );

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _openEditor(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: [
              const Icon(Icons.article_outlined, color: AppColors.midBlue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _text('title_he').isNotEmpty
                                ? _text('title_he')
                                : _text('title_en'),
                            style: TextStyle(
                              fontFamily: AppFonts.rubik,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.navy,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AdminPill(
                          published ? tr('מפורסם', 'Published') : tr('לא מפורסם', 'Not published'),
                          published ? AdminKit.of(context).success : AdminKit.of(context).muted,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        tr('עברית: ${hasHe ? 'נכתב' : 'ריק'}', 'Hebrew: ${hasHe ? 'written' : 'empty'}'),
                        tr('אנגלית: ${hasEn ? 'נכתב' : 'ריק'}', 'English: ${hasEn ? 'written' : 'empty'}'),
                        if (updated != null)
                          tr('עודכן ${updated.day}.${updated.month}.${updated.year}', 'Updated ${updated.day}.${updated.month}.${updated.year}'),
                      ].join('  ·  '),
                      style: small,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      path,
                      textDirection: TextDirection.ltr,
                      style: small.copyWith(color: AppColors.grayLight),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  size: 18,
                  color: AppColors.grayLight,
                ),
                onSelected: (v) => v == 'edit'
                    ? _openEditor(context)
                    : _setPublished(context, ref, !published),
                itemBuilder: (_) => [
                  _menuItem('edit', tr('עריכה', 'Edit')),
                  // Unpublishing is how a page comes down; the same menu
                  // puts it back.
                  _menuItem('toggle', published ? tr('הסרה מפרסום', 'Unpublish') : tr('פרסום', 'Publish')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, String label) => PopupMenuItem(
    value: value,
    child: Text(
      label,
      style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
    ),
  );

  Future<void> _setPublished(
    BuildContext context,
    WidgetRef ref,
    bool published,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(adminSitePagesProvider.notifier)
          .setPublished(page['id'] as String, published);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(tr('העדכון נכשל: $e', 'The update failed: $e'))));
    }
  }

  void _openEditor(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SitePageEditorDialog(page: page),
    );
  }
}

// ─── Editor Dialog ───

class _SitePageEditorDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> page;
  const _SitePageEditorDialog({required this.page});

  @override
  ConsumerState<_SitePageEditorDialog> createState() =>
      _SitePageEditorDialogState();
}

class _SitePageEditorDialogState extends ConsumerState<_SitePageEditorDialog> {
  late final TextEditingController _titleHe;
  late final TextEditingController _titleEn;
  late final TextEditingController _bodyHe;
  late final TextEditingController _bodyEn;
  late bool _published;
  bool _saving = false;
  String? _error;

  /// Which language the preview shows.
  bool _previewHebrew = true;

  /// On a narrow screen the preview takes the form's place rather than
  /// sitting beside it.
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    String text(String key) => widget.page[key] as String? ?? '';
    _titleHe = TextEditingController(text: text('title_he'));
    _titleEn = TextEditingController(text: text('title_en'));
    _bodyHe = TextEditingController(text: text('body_he'));
    _bodyEn = TextEditingController(text: text('body_en'));
    _published = widget.page['is_published'] as bool? ?? false;
    // The preview follows what is typed.
    for (final c in [_titleHe, _titleEn, _bodyHe, _bodyEn]) {
      c.addListener(_refresh);
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final c in [_titleHe, _titleEn, _bodyHe, _bodyEn]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 900;

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: wide ? 1200 : 640,
          maxHeight: 820,
        ),
        child: Directionality(
          textDirection: adminDir,
          child: Column(
            children: [
              _header(wide),
              Expanded(
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _form()),
                          VerticalDivider(width: 1, color: AppColors.border),
                          Expanded(child: _preview()),
                        ],
                      )
                    : (_showPreview ? _preview() : _form()),
              ),
              _footer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(bool wide) {
    final title = (widget.page['title_he'] as String? ?? '').trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: Row(
        children: [
          Text(
            tr('עריכת עמוד: $title', 'Edit page: $title'),
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          if (!wide)
            TextButton(
              onPressed: () => setState(() => _showPreview = !_showPreview),
              child: Text(
                _showPreview ? tr('חזרה לעריכה', 'Back to editing') : tr('תצוגה מקדימה', 'Preview'),
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _form() {
    final hint = TextStyle(
      fontFamily: AppFonts.rubik,
      fontSize: 12,
      color: AppColors.grayText,
      height: 1.5,
    );
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            tr('עיצוב פשוט: שורה שמתחילה ב-"# " או "## " היא כותרת, שורה '
            'שמתחילה ב-"- " היא סעיף ברשימה, ושורה ריקה פותחת פסקה חדשה. '
            'כתובות אתר ודוא״ל הופכות לקישורים.\n'
            'אם אחת השפות ריקה, האתר מציג לקוראיה את השפה השנייה.', 'Simple formatting: a line starting with "# " or "## " is a heading, a line starting with "- " is a list item, and an empty line starts a new paragraph. Web and email addresses become links.\nIf one language is empty, the site shows its readers the other language.'),
            style: hint,
          ),
        ),
        _field(tr('כותרת בעברית', 'Hebrew title'), _titleHe),
        _field(tr('תוכן בעברית', 'Hebrew content'), _bodyHe, maxLines: 12),
        const SizedBox(height: 8),
        _field(tr('כותרת באנגלית', 'English title'), _titleEn, ltr: true),
        _field(tr('תוכן באנגלית', 'English content'), _bodyEn, maxLines: 12, ltr: true),
        SwitchListTile(
          title: Text(
            tr('מפורסם באתר', 'Published on the site'),
            style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14),
          ),
          subtitle: Text(
            _published
                ? tr('הגולשים רואים את העמוד.', 'Visitors see the page.')
                : tr('הגולשים רואים "תוכן העמוד יפורסם בקרוב".', 'Visitors see "The page content will be published soon".'),
            style: hint,
          ),
          value: _published,
          onChanged: (v) => setState(() => _published = v),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _preview() {
    final hebrew = _previewHebrew;
    final title = (hebrew ? _titleHe : _titleEn).text.trim();
    final body = (hebrew ? _bodyHe : _bodyEn).text.trim();

    return Container(
      color: AppColors.surfaceLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Row(
              children: [
                Text(
                  tr('תצוגה מקדימה', 'Preview'),
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
                const Spacer(),
                _LangChip(tr('עברית', 'Hebrew'), hebrew, () {
                  setState(() => _previewHebrew = true);
                }),
                _LangChip('English', !hebrew, () {
                  setState(() => _previewHebrew = false);
                }),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: body.isEmpty
                      ? Text(
                          hebrew
                              ? tr('התוכן בעברית ריק — קוראי העברית יראו את '
                                    'האנגלית, ואם גם היא ריקה, את ההודעה '
                                    '"תוכן העמוד יפורסם בקרוב".', 'The Hebrew content is empty — Hebrew readers will see the English, and if that is empty too, the message "The page content will be published soon".')
                              : tr('התוכן באנגלית ריק — קוראי האנגלית יראו את '
                                    'העברית, ואם גם היא ריקה, את ההודעה '
                                    '"תוכן העמוד יפורסם בקרוב".', 'The English content is empty — English readers will see the Hebrew, and if that is empty too, the message "The page content will be published soon".'),
                          style: TextStyle(
                            fontFamily: AppFonts.rubik,
                            fontSize: 13,
                            color: AppColors.grayText,
                          ),
                        )
                      : Directionality(
                          textDirection: hebrew
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (title.isNotEmpty) ...[
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontFamily: AppFonts.nunito,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1C1C1E),
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                              SitePageBody(text: body, fontSize: 15),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (_error != null)
            Expanded(
              child: Text(
                _error!,
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  fontSize: 12,
                  color: AppColors.error,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            )
          else
            const Spacer(),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('ביטול', 'Cancel'), style: TextStyle(fontFamily: AppFonts.rubik)),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: AdminKit.of(context).accent,
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
                    tr('שמור', 'Save'),
                    style: TextStyle(
                      fontFamily: AppFonts.rubik,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    bool ltr = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        minLines: maxLines > 1 ? 6 : 1,
        maxLines: maxLines,
        textDirection: ltr ? TextDirection.ltr : TextDirection.rtl,
        keyboardType: maxLines > 1 ? TextInputType.multiline : null,
        style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: maxLines > 1,
          labelStyle: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      await ref
          .read(adminSitePagesProvider.notifier)
          .update(widget.page['id'] as String, {
            'title_he': _titleHe.text.trim(),
            'title_en': _titleEn.text.trim(),
            // Trimmed at the ends only: the line breaks inside are the
            // page's paragraphs.
            'body_he': _bodyHe.text.trim(),
            'body_en': _bodyEn.text.trim(),
            'is_published': _published,
          });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = switch (e) {
            PostgrestException(:final message) => tr('השמירה נכשלה: $message', 'Saving failed: $message'),
            _ => tr('השמירה נכשלה: $e', 'Saving failed: $e'),
          },
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ─── Small widgets ───

class _LangChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _LangChip(this.label, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.midBlue.withValues(alpha: 0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected ? AppColors.midBlue : AppColors.border,
              width: 0.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? AppColors.midBlue : AppColors.grayText,
            ),
          ),
        ),
      ),
    );
  }
}
