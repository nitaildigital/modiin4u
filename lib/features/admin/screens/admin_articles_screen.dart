import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/admin_articles_provider.dart';

class AdminArticlesScreen extends ConsumerStatefulWidget {
  const AdminArticlesScreen({super.key});

  @override
  ConsumerState<AdminArticlesScreen> createState() => _AdminArticlesScreenState();
}

class _AdminArticlesScreenState extends ConsumerState<AdminArticlesScreen> {
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
    final articlesAsync = ref.watch(adminArticleListProvider);
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
                hintText: 'חיפוש כתבה...',
                hintStyle: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayLight),
                prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.grayLight),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.turquoise)),
              ),
              onChanged: (v) => _debouncer.run(() {
                ref.read(adminArticleListProvider.notifier).setSearch(v.isEmpty ? null : v);
              }),
            ),
          ),
          const SizedBox(width: 12),
          _FilterChip('הכל', _statusFilter.isEmpty, () {
            setState(() => _statusFilter = '');
            ref.read(adminArticleListProvider.notifier).setStatusFilter(null);
          }),
          _FilterChip('פורסם', _statusFilter == 'published', () {
            setState(() => _statusFilter = 'published');
            ref.read(adminArticleListProvider.notifier).setStatusFilter('published');
          }),
          _FilterChip('טיוטה', _statusFilter == 'draft', () {
            setState(() => _statusFilter = 'draft');
            ref.read(adminArticleListProvider.notifier).setStatusFilter('draft');
          }),
          _FilterChip('ארכיון', _statusFilter == 'archived', () {
            setState(() => _statusFilter = 'archived');
            ref.read(adminArticleListProvider.notifier).setStatusFilter('archived');
          }),
          const Spacer(),
          articlesAsync.whenData((list) => Text('${list.length} כתבות', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText))).value ?? const SizedBox.shrink(),
          const SizedBox(width: 16),
          FilledButton.icon(
            onPressed: () => _showArticleEditor(context, ref),
            icon: const Icon(Icons.add, size: 18),
            label: Text('כתבה חדשה', style: GoogleFonts.rubik(fontSize: 13)),
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
        child: articlesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text('שגיאה בטעינת כתבות', style: GoogleFonts.rubik(color: AppColors.error)),
            Text('$e', style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayText)),
            const SizedBox(height: 12),
            TextButton(onPressed: () => ref.read(adminArticleListProvider.notifier).load(), child: const Text('נסה שוב')),
          ])),
          data: (articles) {
            if (articles.isEmpty) {
              return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.article_outlined, size: 48, color: AppColors.grayLight.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text('אין כתבות', style: GoogleFonts.rubik(color: AppColors.grayText)),
              ]));
            }
            return _ArticleTable(articles: articles, isWide: isWide, onTap: (a) => _showArticleEditor(context, ref, article: a), onAction: _handleAction);
          },
        ),
      ),
    ]);
  }

  void _handleAction(String action, Map<String, dynamic> article) {
    final notifier = ref.read(adminArticleListProvider.notifier);
    final id = article['id'] as String;
    switch (action) {
      case 'edit':
        _showArticleEditor(context, ref, article: article);
      case 'publish':
        notifier.updateStatus(id, 'published');
      case 'draft':
        notifier.updateStatus(id, 'draft');
      case 'archive':
        notifier.updateStatus(id, 'archived');
      case 'delete':
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('מחיקת כתבה', style: GoogleFonts.rubik(fontWeight: FontWeight.w700)),
            content: Text('למחוק את "${article['title']}"?', style: GoogleFonts.rubik()),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text('ביטול', style: GoogleFonts.rubik())),
              TextButton(onPressed: () { Navigator.pop(ctx); notifier.deleteArticle(id); }, child: Text('מחק', style: GoogleFonts.rubik(color: AppColors.error))),
            ],
          ),
        );
    }
  }

  void _showArticleEditor(BuildContext context, WidgetRef ref, {Map<String, dynamic>? article}) {
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => _ArticleEditorDialog(article: article));
  }
}

// ─── Article Table ───

class _ArticleTable extends StatelessWidget {
  final List<Map<String, dynamic>> articles;
  final bool isWide;
  final void Function(Map<String, dynamic>) onTap;
  final void Function(String, Map<String, dynamic>) onAction;
  const _ArticleTable({required this.articles, required this.isWide, required this.onTap, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(color: AppColors.surfaceLight, border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5)))),
        child: Row(children: [
          _Col('כותרת', flex: 4),
          if (isWide) _Col('קטגוריה', flex: 2),
          if (isWide) _Col('סטטוס', flex: 1),
          if (isWide) _Col('צפיות', flex: 1),
          _Col('SEO', flex: 1),
          if (isWide) _Col('תאריך', flex: 2),
          const SizedBox(width: 40),
        ]),
      ),
      Expanded(
        child: ListView.separated(
          itemCount: articles.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.border.withValues(alpha: 0.3)),
          itemBuilder: (_, i) {
            final a = articles[i];
            final status = a['status'] as String? ?? 'draft';
            final views = a['view_count'] as int? ?? 0;
            final hasMeta = (a['meta_description'] as String?)?.isNotEmpty == true;
            final hasSlug = (a['slug'] as String?)?.isNotEmpty == true;
            final isFeatured = a['is_featured'] as bool? ?? false;
            final isBreaking = a['is_breaking'] as bool? ?? false;
            final publishedAt = a['published_at'] as String?;

            final coverUrl = a['cover_image_url'] as String?;
            final categoryName = a['category_name'] as String?;

            return InkWell(
              onTap: () => onTap(a),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(children: [
                  // Cover image thumbnail
                  if (coverUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(coverUrl, width: 52, height: 36, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(width: 52, height: 36, decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.broken_image, size: 16, color: AppColors.grayLight))),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(flex: 4, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      if (isBreaking) Padding(padding: const EdgeInsets.only(left: 6), child: Icon(Icons.bolt, size: 14, color: AppColors.error)),
                      if (isFeatured) Padding(padding: const EdgeInsets.only(left: 6), child: Icon(Icons.star, size: 14, color: AppColors.gold)),
                      Flexible(child: Text(a['title'] as String? ?? '', style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy), overflow: TextOverflow.ellipsis)),
                    ]),
                    Text(a['slug'] as String? ?? '', style: GoogleFonts.rubik(fontSize: 11, color: AppColors.grayLight)),
                  ])),
                  // Category
                  if (isWide) Expanded(flex: 2, child: categoryName != null
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.midBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(categoryName, style: GoogleFonts.rubik(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.midBlue), overflow: TextOverflow.ellipsis),
                      )
                    : Text('—', style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayLight))),
                  if (isWide) Expanded(flex: 1, child: _StatusPill(status)),
                  if (isWide) Expanded(flex: 1, child: Text('$views', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText))),
                  Expanded(flex: 1, child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(hasMeta ? Icons.check_circle : Icons.cancel, size: 14, color: hasMeta ? AppColors.success : AppColors.error.withValues(alpha: 0.4)),
                    const SizedBox(width: 4),
                    Icon(hasSlug ? Icons.check_circle : Icons.cancel, size: 14, color: hasSlug ? AppColors.success : AppColors.error.withValues(alpha: 0.4)),
                  ])),
                  if (isWide) Expanded(flex: 2, child: Text(
                    publishedAt != null ? _formatDate(publishedAt) : 'לא פורסם',
                    style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayText),
                  )),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18, color: AppColors.grayLight),
                    onSelected: (v) => onAction(v, a),
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'edit', child: Text('עריכה', style: GoogleFonts.rubik(fontSize: 13))),
                      if (status != 'published') PopupMenuItem(value: 'publish', child: Text('פרסם', style: GoogleFonts.rubik(fontSize: 13))),
                      if (status != 'draft') PopupMenuItem(value: 'draft', child: Text('החזר לטיוטה', style: GoogleFonts.rubik(fontSize: 13))),
                      if (status != 'archived') PopupMenuItem(value: 'archive', child: Text('העבר לארכיון', style: GoogleFonts.rubik(fontSize: 13))),
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
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return iso;
    }
  }
}

// ─── Article Editor Dialog ───

class _ArticleEditorDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? article;
  const _ArticleEditorDialog({this.article});

  @override
  ConsumerState<_ArticleEditorDialog> createState() => _ArticleEditorDialogState();
}

class _ArticleEditorDialogState extends ConsumerState<_ArticleEditorDialog> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late final TextEditingController _title;
  late final TextEditingController _subtitle;
  late final TextEditingController _slug;
  late final TextEditingController _body;
  late final TextEditingController _excerpt;
  late final TextEditingController _coverImageUrl;
  late final TextEditingController _source;
  late final TextEditingController _credit;
  String? _categoryId;

  // SEO
  late final TextEditingController _seoTitle;
  late final TextEditingController _metaDesc;
  late final TextEditingController _metaKeywords;
  late final TextEditingController _focusKeyword;
  late final TextEditingController _ogTitle;
  late final TextEditingController _ogDesc;

  String _status = 'draft';
  bool _isBreaking = false;
  bool _isFeatured = false;
  bool _isPinned = false;
  bool _isSponsored = false;
  bool _isMembersOnly = false;
  bool _pushWorthy = false;
  bool _noindex = false;
  bool _nofollow = false;

  bool get _isEditing => widget.article != null;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    final a = widget.article;

    _title = TextEditingController(text: a?['title'] as String? ?? '');
    _subtitle = TextEditingController(text: a?['subtitle'] as String? ?? '');
    _slug = TextEditingController(text: a?['slug'] as String? ?? '');
    _body = TextEditingController(text: a?['body'] as String? ?? '');
    _excerpt = TextEditingController(text: a?['excerpt'] as String? ?? '');
    _coverImageUrl = TextEditingController(text: a?['cover_image_url'] as String? ?? '');
    _source = TextEditingController(text: a?['source'] as String? ?? '');
    _credit = TextEditingController(text: a?['credit'] as String? ?? '');
    _categoryId = a?['category_id'] as String?;

    _seoTitle = TextEditingController(text: a?['seo_title'] as String? ?? '');
    _metaDesc = TextEditingController(text: a?['meta_description'] as String? ?? '');
    _metaKeywords = TextEditingController(text: a?['meta_keywords'] as String? ?? '');
    _focusKeyword = TextEditingController(text: a?['focus_keyword'] as String? ?? '');
    _ogTitle = TextEditingController(text: a?['og_title'] as String? ?? '');
    _ogDesc = TextEditingController(text: a?['og_description'] as String? ?? '');

    _status = a?['status'] as String? ?? 'draft';
    _isBreaking = a?['is_breaking'] as bool? ?? false;
    _isFeatured = a?['is_featured'] as bool? ?? false;
    _isPinned = a?['is_pinned'] as bool? ?? false;
    _isSponsored = a?['is_sponsored'] as bool? ?? false;
    _isMembersOnly = a?['is_members_only'] as bool? ?? false;
    _pushWorthy = a?['push_worthy'] as bool? ?? false;
    _noindex = a?['noindex'] as bool? ?? false;
    _nofollow = a?['nofollow'] as bool? ?? false;
  }

  @override
  void dispose() {
    _tabs.dispose();
    _title.dispose(); _subtitle.dispose(); _slug.dispose(); _body.dispose(); _excerpt.dispose();
    _coverImageUrl.dispose(); _source.dispose(); _credit.dispose();
    _seoTitle.dispose(); _metaDesc.dispose(); _metaKeywords.dispose(); _focusKeyword.dispose();
    _ogTitle.dispose(); _ogDesc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 850, maxHeight: 750),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Form(
            key: _formKey,
            child: Column(children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
                child: Row(children: [
                  Text(_isEditing ? 'עריכת כתבה' : 'כתבה חדשה', style: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
                ]),
              ),

              // Tabs
              Container(
                color: AppColors.surfaceLight,
                child: TabBar(
                  controller: _tabs,
                  labelStyle: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: GoogleFonts.rubik(fontSize: 13),
                  labelColor: AppColors.turquoise,
                  unselectedLabelColor: AppColors.grayText,
                  indicatorColor: AppColors.turquoise,
                  tabs: const [Tab(text: 'תוכן'), Tab(text: 'הגדרות'), Tab(text: 'SEO')],
                ),
              ),

              Expanded(
                child: TabBarView(controller: _tabs, children: [
                  _buildContentTab(),
                  _buildSettingsTab(),
                  _buildSeoTab(),
                ]),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
                child: Row(children: [
                  if (_isEditing) ...[_StatusPill(_status), const SizedBox(width: 8)],
                  if (_isEditing) Text('${widget.article?['view_count'] ?? 0} צפיות', style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayText)),
                  const Spacer(),
                  TextButton(onPressed: () => Navigator.pop(context), child: Text('ביטול', style: GoogleFonts.rubik())),
                  const SizedBox(width: 8),
                  if (_status == 'draft') ...[
                    OutlinedButton(
                      onPressed: _saving ? null : () => _save(asDraft: true),
                      style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      child: Text('שמור טיוטה', style: GoogleFonts.rubik(fontSize: 13)),
                    ),
                    const SizedBox(width: 8),
                  ],
                  FilledButton(
                    onPressed: _saving ? null : () => _save(),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.turquoise, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_isEditing ? 'שמור' : 'צור כתבה', style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildContentTab() {
    final categories = ref.watch(articleCategoriesProvider);
    return ListView(padding: const EdgeInsets.all(20), children: [
      _field('כותרת *', _title, validator: (v) => v == null || v.isEmpty ? 'שדה חובה' : null),
      _field('כותרת משנה', _subtitle),
      _field('Slug *', _slug, validator: (v) => v == null || v.isEmpty ? 'שדה חובה' : null),
      // Category dropdown
      categories.when(
        loading: () => const LinearProgressIndicator(),
        error: (_, __) => const SizedBox.shrink(),
        data: (cats) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DropdownButtonFormField<String?>(
            value: _categoryId,
            decoration: InputDecoration(labelText: 'קטגוריה', labelStyle: GoogleFonts.rubik(fontSize: 13), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
            items: [
              DropdownMenuItem<String?>(value: null, child: Text('ללא קטגוריה', style: GoogleFonts.rubik(fontSize: 13))),
              ...cats.map((c) => DropdownMenuItem(value: c['id'] as String, child: Text(c['name'] as String, style: GoogleFonts.rubik(fontSize: 13)))),
            ],
            onChanged: (v) => setState(() => _categoryId = v),
          ),
        ),
      ),
      _field('תקציר', _excerpt, maxLines: 2),
      // Cover image
      _field('קישור תמונת כריכה', _coverImageUrl, hint: 'https://...'),
      if (_coverImageUrl.text.isNotEmpty) ...[
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(_coverImageUrl.text, height: 140, width: double.infinity, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(height: 60, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(8)), child: Text('תמונה לא נמצאה', style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayLight)))),
        ),
        const SizedBox(height: 12),
      ],
      _field('תוכן *', _body, maxLines: 12, validator: (v) => v == null || v.isEmpty ? 'שדה חובה' : null),
      Row(children: [
        Expanded(child: _field('מקור', _source)),
        const SizedBox(width: 12),
        Expanded(child: _field('קרדיט', _credit)),
      ]),
    ]);
  }

  Widget _buildSettingsTab() {
    return ListView(padding: const EdgeInsets.all(20), children: [
      Text('סטטוס', style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: _status,
        decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
        items: [
          DropdownMenuItem(value: 'draft', child: Text('טיוטה', style: GoogleFonts.rubik(fontSize: 13))),
          DropdownMenuItem(value: 'published', child: Text('פורסם', style: GoogleFonts.rubik(fontSize: 13))),
          DropdownMenuItem(value: 'archived', child: Text('ארכיון', style: GoogleFonts.rubik(fontSize: 13))),
        ],
        onChanged: (v) => setState(() => _status = v!),
      ),
      const SizedBox(height: 16),
      Text('דגלים', style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 4, children: [
        _toggle('חדשות בזק', _isBreaking, (v) => setState(() => _isBreaking = v)),
        _toggle('מומלץ', _isFeatured, (v) => setState(() => _isFeatured = v)),
        _toggle('נעוץ', _isPinned, (v) => setState(() => _isPinned = v)),
        _toggle('ממומן', _isSponsored, (v) => setState(() => _isSponsored = v)),
        _toggle('לחברים בלבד', _isMembersOnly, (v) => setState(() => _isMembersOnly = v)),
        _toggle('ראוי ל-Push', _pushWorthy, (v) => setState(() => _pushWorthy = v)),
      ]),
    ]);
  }

  Widget _buildSeoTab() {
    return ListView(padding: const EdgeInsets.all(20), children: [
      _field('SEO Title', _seoTitle),
      _field('Meta Description', _metaDesc, maxLines: 3),
      _field('Meta Keywords', _metaKeywords),
      _field('Focus Keyword', _focusKeyword),
      const SizedBox(height: 16),
      Text('Open Graph', style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy)),
      const SizedBox(height: 8),
      _field('OG Title', _ogTitle),
      _field('OG Description', _ogDesc, maxLines: 3),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 4, children: [
        _toggle('Noindex', _noindex, (v) => setState(() => _noindex = v)),
        _toggle('Nofollow', _nofollow, (v) => setState(() => _nofollow = v)),
      ]),
    ]);
  }

  Widget _field(String label, TextEditingController controller, {int maxLines = 1, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        style: GoogleFonts.rubik(fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
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
      selected: value,
      onSelected: onChanged,
      selectedColor: AppColors.turquoise.withValues(alpha: 0.15),
      checkmarkColor: AppColors.turquoise,
      side: BorderSide(color: value ? AppColors.turquoise : AppColors.border),
    );
  }

  Future<void> _save({bool asDraft = false}) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final fields = <String, dynamic>{
      'title': _title.text,
      'subtitle': _subtitle.text.isEmpty ? null : _subtitle.text,
      'slug': _slug.text,
      'body': _body.text,
      'excerpt': _excerpt.text.isEmpty ? null : _excerpt.text,
      'source': _source.text.isEmpty ? null : _source.text,
      'credit': _credit.text.isEmpty ? null : _credit.text,
      'cover_image_url': _coverImageUrl.text.isEmpty ? null : _coverImageUrl.text,
      'category_id': _categoryId,
      'status': asDraft ? 'draft' : _status,
      'is_breaking': _isBreaking,
      'is_featured': _isFeatured,
      'is_pinned': _isPinned,
      'is_sponsored': _isSponsored,
      'is_members_only': _isMembersOnly,
      'push_worthy': _pushWorthy,
      'seo_title': _seoTitle.text.isEmpty ? null : _seoTitle.text,
      'meta_description': _metaDesc.text.isEmpty ? null : _metaDesc.text,
      'meta_keywords': _metaKeywords.text.isEmpty ? null : _metaKeywords.text,
      'focus_keyword': _focusKeyword.text.isEmpty ? null : _focusKeyword.text,
      'og_title': _ogTitle.text.isEmpty ? null : _ogTitle.text,
      'og_description': _ogDesc.text.isEmpty ? null : _ogDesc.text,
      'noindex': _noindex,
      'nofollow': _nofollow,
    };

    if (!_isEditing && _status == 'published' && !asDraft) {
      fields['published_at'] = DateTime.now().toIso8601String();
    }

    try {
      final notifier = ref.read(adminArticleListProvider.notifier);
      if (_isEditing) {
        await notifier.updateArticle(widget.article!['id'] as String, fields);
      } else {
        await notifier.createArticle(fields);
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
      'archived' => ('ארכיון', AppColors.grayLight),
      'trash' => ('פח', AppColors.error),
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
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
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
