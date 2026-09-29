import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../news/models/article_body.dart';
import '../providers/admin_articles_provider.dart';
import '../widgets/image_upload_field.dart';
import '../widgets/admin_load_error.dart';

class AdminArticlesScreen extends ConsumerStatefulWidget {
  const AdminArticlesScreen({super.key});

  @override
  ConsumerState<AdminArticlesScreen> createState() =>
      _AdminArticlesScreenState();
}

class _AdminArticlesScreenState extends ConsumerState<AdminArticlesScreen> {
  String _statusFilter = '';
  bool _loadingMore = false;
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
    final notifier = ref.watch(adminArticleListProvider.notifier);
    final isWide = MediaQuery.of(context).size.width > 900;

    return Column(
      children: [
        // ─── Toolbar (CRM-style) ───
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: AppColors.adminCardBorder, width: 1),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: isWide ? 320 : 200,
                height: 40,
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'חיפוש כתבה...',
                    hintStyle: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      color: AppColors.adminTextLight,
                    ),
                    prefixIcon: Icon(
                      IconsaxPlusLinear.search_normal,
                      size: 18,
                      color: AppColors.adminTextLight,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(
                        color: AppColors.adminSearchBorder,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(
                        color: AppColors.adminSearchBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: AppColors.midBlue),
                    ),
                  ),
                  onChanged: (v) => _debouncer.run(() {
                    ref
                        .read(adminArticleListProvider.notifier)
                        .setSearch(v.isEmpty ? null : v);
                  }),
                ),
              ),
              const SizedBox(width: 12),
              _FilterChip('הכל', _statusFilter.isEmpty, () {
                setState(() => _statusFilter = '');
                ref
                    .read(adminArticleListProvider.notifier)
                    .setStatusFilter(null);
              }),
              _FilterChip('פורסם', _statusFilter == 'published', () {
                setState(() => _statusFilter = 'published');
                ref
                    .read(adminArticleListProvider.notifier)
                    .setStatusFilter('published');
              }),
              _FilterChip('טיוטה', _statusFilter == 'draft', () {
                setState(() => _statusFilter = 'draft');
                ref
                    .read(adminArticleListProvider.notifier)
                    .setStatusFilter('draft');
              }),
              _FilterChip('ארכיון', _statusFilter == 'archived', () {
                setState(() => _statusFilter = 'archived');
                ref
                    .read(adminArticleListProvider.notifier)
                    .setStatusFilter('archived');
              }),
              const Spacer(),
              // `valueOrNull`, not `whenData(...).value`: the latter rethrows
              // on a failed load and greys the whole section instead of
              // letting the table below show the error and a retry.
              if (articlesAsync.valueOrNull case final list?)
                Text(
                  notifier.hasMore
                      ? '${list.length} מתוך ${notifier.totalCount} כתבות'
                      : '${notifier.totalCount} כתבות',
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 13,
                    color: AppColors.adminTextLight,
                  ),
                ),
              const SizedBox(width: 16),
              SizedBox(
                height: 40,
                child: FilledButton.icon(
                  onPressed: () => _showArticleEditor(context, ref),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(
                    'כתבה חדשה',
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.midBlue,
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ─── Table ───
        Expanded(
          child: articlesAsync.when(
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
                    'שגיאה בטעינת כתבות',
                    style: TextStyle(
                      fontFamily: AppFonts.rubik,
                      color: AppColors.error,
                    ),
                  ),
                  Text(
                    '$e',
                    style: TextStyle(
                      fontFamily: AppFonts.rubik,
                      fontSize: 12,
                      color: AppColors.grayText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () =>
                        ref.read(adminArticleListProvider.notifier).load(),
                    child: const Text('נסה שוב'),
                  ),
                ],
              ),
            ),
            data: (articles) {
              if (articles.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.article_outlined,
                        size: 48,
                        color: AppColors.grayLight.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'אין כתבות',
                        style: TextStyle(
                          fontFamily: AppFonts.rubik,
                          color: AppColors.grayText,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Column(
                children: [
                  Expanded(
                    child: _ArticleTable(
                      articles: articles,
                      isWide: isWide,
                      onTap: (a) =>
                          _showArticleEditor(context, ref, article: a),
                      onAction: _handleAction,
                    ),
                  ),

                  // Rows are fetched a page at a time, and there are more
                  // articles than one page. Without this the oldest ones
                  // could not be reached, let alone edited.
                  if (notifier.hasMore)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(
                            color: AppColors.adminCardBorder,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Center(
                        child: OutlinedButton.icon(
                          onPressed: _loadingMore ? null : _loadMore,
                          icon: _loadingMore
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.expand_more, size: 18),
                          label: Text(
                            'טען עוד (${notifier.totalCount - articles.length} נותרו)',
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      await ref.read(adminArticleListProvider.notifier).loadMore();
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _handleAction(String action, Map<String, dynamic> article) {
    final notifier = ref.read(adminArticleListProvider.notifier);
    final id = article['id'] as String;
    switch (action) {
      case 'edit':
        _showArticleEditor(context, ref, article: article);
      case 'publish':
        runAdminAction(context, () => notifier.updateStatus(id, 'published'));
      case 'draft':
        runAdminAction(context, () => notifier.updateStatus(id, 'draft'));
      case 'archive':
        runAdminAction(context, () => notifier.updateStatus(id, 'archived'));
    }
  }

  void _showArticleEditor(
    BuildContext context,
    WidgetRef ref, {
    Map<String, dynamic>? article,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ArticleEditorDialog(article: article),
    );
  }
}

// ─── Article Table ───

class _ArticleTable extends StatelessWidget {
  final List<Map<String, dynamic>> articles;
  final bool isWide;
  final void Function(Map<String, dynamic>) onTap;
  final void Function(String, Map<String, dynamic>) onAction;
  const _ArticleTable({
    required this.articles,
    required this.isWide,
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
              _Col('כותרת', flex: 4),
              if (isWide) _Col('קטגוריה', flex: 2),
              if (isWide) _Col('סטטוס', flex: 1),
              if (isWide) _Col('צפיות', flex: 1),
              _Col('SEO', flex: 1),
              if (isWide) _Col('תאריך', flex: 2),
              const SizedBox(width: 40),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: articles.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: AppColors.border.withValues(alpha: 0.3),
            ),
            itemBuilder: (_, i) {
              final a = articles[i];
              final status = a['status'] as String? ?? 'draft';
              final views = a['view_count'] as int? ?? 0;
              final hasMeta =
                  (a['meta_description'] as String?)?.isNotEmpty == true;
              final hasSlug = (a['slug'] as String?)?.isNotEmpty == true;
              final isFeatured = a['is_featured'] as bool? ?? false;
              final isBreaking = a['is_breaking'] as bool? ?? false;
              final publishedAt = a['published_at'] as String?;

              final coverUrl = a['cover_image_url'] as String?;
              // Absent when the lookup failed, empty when the article is
              // filed nowhere; only the second is "—".
              final categoryNames = a['category_names'] as List<String>?;

              return InkWell(
                onTap: () => onTap(a),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      // Cover image thumbnail
                      if (coverUrl != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            coverUrl,
                            width: 52,
                            height: 36,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 52,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.broken_image,
                                size: 16,
                                color: AppColors.grayLight,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (isBreaking)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 6),
                                    child: Icon(
                                      Icons.bolt,
                                      size: 14,
                                      color: AppColors.error,
                                    ),
                                  ),
                                if (isFeatured)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 6),
                                    child: Icon(
                                      Icons.star,
                                      size: 14,
                                      color: AppColors.gold,
                                    ),
                                  ),
                                Flexible(
                                  child: Text(
                                    a['title'] as String? ?? '',
                                    style: TextStyle(
                                      fontFamily: AppFonts.rubik,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.navy,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              a['slug'] as String? ?? '',
                              style: TextStyle(
                                fontFamily: AppFonts.rubik,
                                fontSize: 11,
                                color: AppColors.grayLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Category
                      if (isWide)
                        Expanded(
                          flex: 2,
                          child: categoryNames == null
                              ? const SizedBox.shrink()
                              : categoryNames.isEmpty
                              ? Text(
                                  '—',
                                  style: TextStyle(
                                    fontFamily: AppFonts.rubik,
                                    fontSize: 12,
                                    color: AppColors.grayLight,
                                  ),
                                )
                              : Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: [
                                    for (final name in categoryNames)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.midBlue.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          name,
                                          style: TextStyle(
                                            fontFamily: AppFonts.rubik,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.midBlue,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                  ],
                                ),
                        ),
                      if (isWide) Expanded(flex: 1, child: _StatusPill(status)),
                      if (isWide)
                        Expanded(
                          flex: 1,
                          child: Text(
                            '$views',
                            style: TextStyle(
                              fontFamily: AppFonts.rubik,
                              fontSize: 13,
                              color: AppColors.grayText,
                            ),
                          ),
                        ),
                      Expanded(
                        flex: 1,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              hasMeta ? Icons.check_circle : Icons.cancel,
                              size: 14,
                              color: hasMeta
                                  ? AppColors.success
                                  : AppColors.error.withValues(alpha: 0.4),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              hasSlug ? Icons.check_circle : Icons.cancel,
                              size: 14,
                              color: hasSlug
                                  ? AppColors.success
                                  : AppColors.error.withValues(alpha: 0.4),
                            ),
                          ],
                        ),
                      ),
                      if (isWide)
                        Expanded(
                          flex: 2,
                          child: Text(
                            publishedAt != null
                                ? _formatDate(publishedAt)
                                : 'לא פורסם',
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
                        onSelected: (v) => onAction(v, a),
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text(
                              'עריכה',
                              style: TextStyle(
                                fontFamily: AppFonts.rubik,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          if (status != 'published')
                            PopupMenuItem(
                              value: 'publish',
                              child: Text(
                                'פרסם',
                                style: TextStyle(
                                  fontFamily: AppFonts.rubik,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          if (status != 'draft')
                            PopupMenuItem(
                              value: 'draft',
                              child: Text(
                                'החזר לטיוטה',
                                style: TextStyle(
                                  fontFamily: AppFonts.rubik,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          if (status != 'archived')
                            PopupMenuItem(
                              value: 'archive',
                              child: Text(
                                'העבר לארכיון',
                                style: TextStyle(
                                  fontFamily: AppFonts.rubik,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          // An item reading "delete" stood here. It asked
                          // for confirmation and then archived the article —
                          // exactly what "העבר לארכיון" above it does. There
                          // is no permanent delete for an article: removing
                          // one would take its comments with it. Offering the
                          // word without the deed helped nobody.
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

  String _formatDate(String iso) {
    try {
      // Stored in UTC; an article published after 21:00 in Modiin belongs to
      // the next day in UTC, so the date is taken in the reader's zone.
      final d = DateTime.parse(iso).toLocal();
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
  ConsumerState<_ArticleEditorDialog> createState() =>
      _ArticleEditorDialogState();
}

class _ArticleEditorDialogState extends ConsumerState<_ArticleEditorDialog>
    with SingleTickerProviderStateMixin {
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

  /// The categories the article was filed under when the editor opened —
  /// null until they have loaded. Saving compares against this and moves only
  /// the links the person added or took away.
  Set<String>? _originalCategoryIds;
  Set<String> _categoryIds = {};
  bool _categoriesFailed = false;

  /// In the reader's zone; converted to UTC on the way out. Written only when
  /// [_publishedAtChanged] — the date is the article's, not the last save's.
  DateTime? _publishedAt;
  bool _publishedAtChanged = false;

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

  /// What the form held when it opened, in the shape [_collect] produces.
  ///
  /// A save sends only the fields that differ from this. Sending everything
  /// rewrote every column of the row on each save, so anything the form
  /// reads imperfectly — or a change someone else made in the meantime —
  /// was overwritten by a person who only fixed a typo in the title.
  late final Map<String, dynamic> _baseline;

  bool get _isEditing => widget.article != null;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    final a = widget.article;

    _title = TextEditingController(text: a?['title'] as String? ?? '');
    _subtitle = TextEditingController(text: a?['subtitle'] as String? ?? '');
    _slug = TextEditingController(text: a?['slug'] as String? ?? '');
    _body = TextEditingController(text: a?['body'] as String? ?? '');
    _excerpt = TextEditingController(text: a?['excerpt'] as String? ?? '');
    _coverImageUrl = TextEditingController(
      text: a?['cover_image_url'] as String? ?? '',
    );
    _source = TextEditingController(text: a?['source'] as String? ?? '');
    _credit = TextEditingController(text: a?['credit'] as String? ?? '');

    _seoTitle = TextEditingController(text: a?['seo_title'] as String? ?? '');
    _metaDesc = TextEditingController(
      text: a?['meta_description'] as String? ?? '',
    );
    _metaKeywords = TextEditingController(
      text: a?['meta_keywords'] as String? ?? '',
    );
    _focusKeyword = TextEditingController(
      text: a?['focus_keyword'] as String? ?? '',
    );
    _ogTitle = TextEditingController(text: a?['og_title'] as String? ?? '');
    _ogDesc = TextEditingController(
      text: a?['og_description'] as String? ?? '',
    );

    _status = a?['status'] as String? ?? 'draft';
    _isBreaking = a?['is_breaking'] as bool? ?? false;
    _isFeatured = a?['is_featured'] as bool? ?? false;
    _isPinned = a?['is_pinned'] as bool? ?? false;
    _isSponsored = a?['is_sponsored'] as bool? ?? false;
    _isMembersOnly = a?['is_members_only'] as bool? ?? false;
    _pushWorthy = a?['push_worthy'] as bool? ?? false;
    _noindex = a?['noindex'] as bool? ?? false;
    _nofollow = a?['nofollow'] as bool? ?? false;

    _publishedAt = DateTime.tryParse(
      a?['published_at'] as String? ?? '',
    )?.toLocal();

    _baseline = _collect();

    if (_isEditing) {
      _loadCategories();
    } else {
      _originalCategoryIds = {};
    }
  }

  /// Reads the article's category links from the table.
  ///
  /// The editor used to start with none selected whatever the article was
  /// filed under, and saving then removed them all.
  Future<void> _loadCategories() async {
    setState(() => _categoriesFailed = false);
    try {
      final ids = await ref
          .read(adminArticleListProvider.notifier)
          .categoryIdsOf(widget.article!['id'] as String);
      if (!mounted) return;
      setState(() {
        _originalCategoryIds = ids;
        _categoryIds = {...ids};
      });
    } catch (_) {
      if (mounted) setState(() => _categoriesFailed = true);
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    _title.dispose();
    _subtitle.dispose();
    _slug.dispose();
    _body.dispose();
    _excerpt.dispose();
    _coverImageUrl.dispose();
    _source.dispose();
    _credit.dispose();
    _seoTitle.dispose();
    _metaDesc.dispose();
    _metaKeywords.dispose();
    _focusKeyword.dispose();
    _ogTitle.dispose();
    _ogDesc.dispose();
    super.dispose();
  }

  /// Saving waits for the categories to load, so it cannot compare against a
  /// set it has not read yet. If they could not be read, it saves without
  /// touching them.
  bool get _canSave =>
      !_saving && (_originalCategoryIds != null || _categoriesFailed);

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
            child: Column(
              children: [
                // Header
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
                        _isEditing ? 'עריכת כתבה' : 'כתבה חדשה',
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

                // Tabs
                Container(
                  color: AppColors.surfaceLight,
                  child: TabBar(
                    controller: _tabs,
                    labelStyle: TextStyle(
                      fontFamily: AppFonts.rubik,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontFamily: AppFonts.rubik,
                      fontSize: 13,
                    ),
                    labelColor: AppColors.turquoise,
                    unselectedLabelColor: AppColors.grayText,
                    indicatorColor: AppColors.turquoise,
                    tabs: const [
                      Tab(text: 'תוכן'),
                      Tab(text: 'הגדרות'),
                      Tab(text: 'SEO'),
                      Tab(text: 'תצוגה מקדימה'),
                    ],
                  ),
                ),

                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _buildContentTab(),
                      _buildSettingsTab(),
                      _buildSeoTab(),
                      _buildPreviewTab(),
                    ],
                  ),
                ),

                // Footer
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
                      if (_isEditing) ...[
                        _StatusPill(_status),
                        const SizedBox(width: 8),
                      ],
                      if (_isEditing)
                        Text(
                          '${widget.article?['view_count'] ?? 0} צפיות',
                          style: TextStyle(
                            fontFamily: AppFonts.rubik,
                            fontSize: 12,
                            color: AppColors.grayText,
                          ),
                        ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'ביטול',
                          style: TextStyle(fontFamily: AppFonts.rubik),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_status == 'draft') ...[
                        OutlinedButton(
                          onPressed: _canSave
                              ? () => _save(asDraft: true)
                              : null,
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'שמור טיוטה',
                            style: TextStyle(
                              fontFamily: AppFonts.rubik,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      FilledButton(
                        onPressed: _canSave ? () => _save() : null,
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
                                _isEditing ? 'שמור' : 'צור כתבה',
                                style: TextStyle(
                                  fontFamily: AppFonts.rubik,
                                  fontSize: 13,
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

  Widget _buildContentTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _field(
          'כותרת *',
          _title,
          validator: (v) => v == null || v.isEmpty ? 'שדה חובה' : null,
        ),
        _field('כותרת משנה', _subtitle),
        _field(
          'Slug *',
          _slug,
          validator: (v) => v == null || v.isEmpty ? 'שדה חובה' : null,
        ),
        _buildCategoryPicker(),
        _field('תקציר', _excerpt, maxLines: 2),
        // Uploaded to storage, or an address pasted as before.
        ImageUploadField(
          label: 'תמונת כריכה',
          controller: _coverImageUrl,
          folder: 'articles/cover',
        ),
        const SizedBox(height: 16),
        // The body is kept exactly as it is stored. The imported stories are
        // WordPress HTML, and a rich editor would rewrite that markup on
        // every save; a text box leaves it alone, and the preview tab shows
        // what the site will make of it.
        _field(
          'תוכן *',
          _body,
          maxLines: 12,
          helper:
              'הטקסט נשמר בדיוק כפי שהוא, כולל תגיות HTML מהאתר הקודם. '
              'פסקה חדשה: שורה ריקה. לשונית "תצוגה מקדימה" מראה איך האתר יציג אותו.',
          validator: (v) => v == null || v.isEmpty ? 'שדה חובה' : null,
        ),
        Row(
          children: [
            Expanded(child: _field('מקור', _source)),
            const SizedBox(width: 12),
            // `credit` is the byline the site prints under the title.
            Expanded(child: _field('קרדיט / כותב', _credit)),
          ],
        ),
      ],
    );
  }

  /// Several categories, not one: 70 of the articles are filed under two or
  /// three, and a single-choice picker could only ever lose the others.
  Widget _buildCategoryPicker() {
    final label = Text(
      'קטגוריות',
      style: TextStyle(
        fontFamily: AppFonts.rubik,
        fontSize: 12,
        color: AppColors.adminTextMedium,
      ),
    );

    if (_categoriesFailed) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label,
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'לא ניתן לטעון את הקטגוריות של הכתבה. שמירה לא תשנה אותן.',
                    style: TextStyle(
                      fontFamily: AppFonts.rubik,
                      fontSize: 12,
                      color: AppColors.error,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _loadCategories,
                  child: Text(
                    'נסה שוב',
                    style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final categories = ref.watch(articleCategoriesProvider);
    if (_originalCategoryIds == null || categories.isLoading) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label,
            const SizedBox(height: 8),
            const LinearProgressIndicator(),
          ],
        ),
      );
    }

    final cats = categories.valueOrNull ?? const <Map<String, dynamic>>[];
    final known = {for (final c in cats) c['id'] as String};
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          label,
          const SizedBox(height: 6),
          if (categories.hasError)
            Text(
              'לא ניתן לטעון את רשימת הקטגוריות.',
              style: TextStyle(
                fontFamily: AppFonts.rubik,
                fontSize: 12,
                color: AppColors.error,
              ),
            ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final c in cats)
                if (c['is_active'] == true ||
                    _categoryIds.contains(c['id'] as String))
                  _toggle(
                    c['is_active'] == true
                        ? c['name'] as String
                        : '${c['name']} (לא פעילה)',
                    _categoryIds.contains(c['id'] as String),
                    (v) => setState(() {
                      final id = c['id'] as String;
                      v ? _categoryIds.add(id) : _categoryIds.remove(id);
                    }),
                  ),
              // A link to a category this list does not know — kept, and
              // shown, so that it is not removed without anyone seeing it.
              for (final id in _categoryIds.where((id) => !known.contains(id)))
                _toggle(
                  'קטגוריה לא מוכרת',
                  true,
                  (v) => setState(() => _categoryIds.remove(id)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'סטטוס',
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _status,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
          items: [
            for (final (value, label) in [
              ('draft', 'טיוטה'),
              ('published', 'פורסם'),
              ('archived', 'ארכיון'),
              // Only offered to an article already there; the trash screen
              // is where articles are sent to it.
              if (_baseline['status'] == 'trash') ('trash', 'פח'),
            ])
              DropdownMenuItem(
                value: value,
                child: Text(
                  label,
                  style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
                ),
              ),
          ],
          onChanged: (v) => setState(() => _status = v!),
        ),
        const SizedBox(height: 16),
        Text(
          'תאריך פרסום',
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InputDecorator(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  _publishedAt == null
                      ? 'ייקבע בפרסום הראשון'
                      : _formatDateTime(_publishedAt!),
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 13,
                    color: _publishedAt == null
                        ? AppColors.grayLight
                        : AppColors.navy,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _pickPublishedAt,
              icon: const Icon(Icons.edit_calendar_outlined, size: 16),
              label: Text(
                'שינוי',
                style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'התאריך נקבע בפרסום הראשון ונשאר קבוע, גם אחרי עריכה או פרסום מחדש. '
          'הוא משתנה רק אם משנים אותו כאן.',
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontSize: 11,
            color: AppColors.grayText,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'דגלים',
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _toggle(
              'חדשות בזק',
              _isBreaking,
              (v) => setState(() => _isBreaking = v),
            ),
            _toggle(
              'מומלץ',
              _isFeatured,
              (v) => setState(() => _isFeatured = v),
            ),
            _toggle('נעוץ', _isPinned, (v) => setState(() => _isPinned = v)),
            _toggle(
              'ממומן',
              _isSponsored,
              (v) => setState(() => _isSponsored = v),
            ),
            _toggle(
              'לחברים בלבד',
              _isMembersOnly,
              (v) => setState(() => _isMembersOnly = v),
            ),
            _toggle(
              'ראוי ל-Push',
              _pushWorthy,
              (v) => setState(() => _pushWorthy = v),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickPublishedAt() async {
    final now = DateTime.now();
    final initial = _publishedAt ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: DateTime(2000),
      // Nothing publishes an article at a future time, so a future date
      // would only put it at the top of the feed dated tomorrow.
      lastDate: now,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (!mounted) return;
    final t = time ?? TimeOfDay.fromDateTime(initial);
    setState(() {
      _publishedAt = DateTime(
        date.year,
        date.month,
        date.day,
        t.hour,
        t.minute,
      );
      _publishedAtChanged = true;
    });
  }

  static String _formatDateTime(DateTime d) =>
      '${d.day}/${d.month}/${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Widget _buildSeoTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _field('SEO Title', _seoTitle),
        _field('Meta Description', _metaDesc, maxLines: 3),
        _field('Meta Keywords', _metaKeywords),
        _field('Focus Keyword', _focusKeyword),
        const SizedBox(height: 16),
        Text(
          'Open Graph',
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 8),
        _field('OG Title', _ogTitle),
        _field('OG Description', _ogDesc, maxLines: 3),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _toggle('Noindex', _noindex, (v) => setState(() => _noindex = v)),
            _toggle(
              'Nofollow',
              _nofollow,
              (v) => setState(() => _nofollow = v),
            ),
          ],
        ),
      ],
    );
  }

  /// The body read the way the website reads it — the same parser — so a
  /// broken tag or a photo that will not load shows here before it shows on
  /// the site. Read-only; the text box on the first tab is what is saved.
  Widget _buildPreviewTab() {
    return ListenableBuilder(
      listenable: Listenable.merge([_title, _subtitle, _coverImageUrl, _body]),
      builder: (context, _) {
        final blocks = parseArticleBody(_body.text);
        final cover = _coverImageUrl.text.trim();
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'תצוגה מקדימה של התוכן כפי שהאתר קורא אותו. העיצוב המלא '
                'מופיע בעמוד הכתבה באתר.',
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  fontSize: 12,
                  color: AppColors.grayText,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _title.text,
              style: TextStyle(
                fontFamily: AppFonts.rubik,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
            if (_subtitle.text.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                _subtitle.text,
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  fontSize: 15,
                  color: AppColors.grayText,
                ),
              ),
            ],
            if (cover.isNotEmpty) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _previewImage(cover, height: 260),
              ),
            ],
            const SizedBox(height: 18),
            if (blocks.isEmpty)
              Text(
                'אין תוכן',
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  fontSize: 13,
                  color: AppColors.grayLight,
                ),
              ),
            for (final (i, block) in blocks.indexed) ...[
              if (i > 0)
                SizedBox(
                  height:
                      block.kind == ArticleBlockKind.listItem &&
                          blocks[i - 1].kind == ArticleBlockKind.listItem
                      ? 6
                      : 16,
                ),
              _previewBlock(block),
            ],
          ],
        );
      },
    );
  }

  Widget _previewBlock(ArticleBlock block) {
    final spans = TextSpan(
      children: [
        for (final s in block.spans)
          TextSpan(
            text: s.text,
            style: TextStyle(
              fontWeight: s.bold ? FontWeight.w600 : null,
              fontStyle: s.italic ? FontStyle.italic : null,
              color: s.href != null ? AppColors.midBlue : null,
              decoration: s.href != null ? TextDecoration.underline : null,
            ),
          ),
      ],
    );
    final base = TextStyle(
      fontFamily: AppFonts.rubik,
      fontSize: 15,
      height: 1.6,
      color: AppColors.adminTextDark,
    );
    return switch (block.kind) {
      ArticleBlockKind.heading => Text.rich(
        spans,
        style: base.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.navy,
        ),
      ),
      ArticleBlockKind.listItem => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•  ', style: base),
          Expanded(child: Text.rich(spans, style: base)),
        ],
      ),
      ArticleBlockKind.image => Align(
        alignment: AlignmentDirectional.centerStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 516),
          child: _previewImage(block.src ?? ''),
        ),
      ),
      ArticleBlockKind.paragraph => Text.rich(spans, style: base),
    };
  }

  /// Photos in the imported stories sit on the old WordPress site, which
  /// sends no CORS headers; letting the browser draw them is what the
  /// article page does too.
  Widget _previewImage(String url, {double? height}) {
    return Image.network(
      url,
      height: height,
      width: height == null ? null : double.infinity,
      fit: BoxFit.cover,
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      errorBuilder: (_, _, _) => Container(
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'התמונה לא נטענה: $url',
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontSize: 11,
            color: AppColors.grayLight,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    String? helper,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          helperMaxLines: 3,
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

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 12),
      ),
      selected: value,
      onSelected: onChanged,
      selectedColor: AppColors.turquoise.withValues(alpha: 0.15),
      checkmarkColor: AppColors.turquoise,
      side: BorderSide(color: value ? AppColors.turquoise : AppColors.border),
    );
  }

  /// Every column the form edits, as the form currently holds it.
  Map<String, dynamic> _collect({bool asDraft = false}) {
    String? text(TextEditingController c) => c.text.isEmpty ? null : c.text;
    return <String, dynamic>{
      'title': _title.text,
      'subtitle': text(_subtitle),
      'slug': _slug.text,
      'body': _body.text,
      'excerpt': text(_excerpt),
      'source': text(_source),
      'credit': text(_credit),
      'cover_image_url': text(_coverImageUrl),
      'status': asDraft ? 'draft' : _status,
      'is_breaking': _isBreaking,
      'is_featured': _isFeatured,
      'is_pinned': _isPinned,
      'is_sponsored': _isSponsored,
      'is_members_only': _isMembersOnly,
      'push_worthy': _pushWorthy,
      'seo_title': text(_seoTitle),
      'meta_description': text(_metaDesc),
      'meta_keywords': text(_metaKeywords),
      'focus_keyword': text(_focusKeyword),
      'og_title': text(_ogTitle),
      'og_description': text(_ogDesc),
      'noindex': _noindex,
      'nofollow': _nofollow,
    };
  }

  Future<void> _save({bool asDraft = false}) async {
    if (!_formKey.currentState!.validate()) return;

    final fields = _collect(asDraft: asDraft);
    if (_publishedAtChanged && _publishedAt != null) {
      fields['published_at'] = _publishedAt!.toUtc().toIso8601String();
    }

    // Null when the links could not be read: then they are not touched.
    final original = _originalCategoryIds;
    final added = original == null
        ? <String>{}
        : _categoryIds.difference(original);
    final removed = original == null
        ? <String>{}
        : original.difference(_categoryIds);

    final changed = _isEditing
        ? {
            for (final e in fields.entries)
              if (!_baseline.containsKey(e.key) || _baseline[e.key] != e.value)
                e.key: e.value,
          }
        : fields;

    if (_isEditing && changed.isEmpty && added.isEmpty && removed.isEmpty) {
      Navigator.pop(context);
      return;
    }

    setState(() => _saving = true);
    try {
      final notifier = ref.read(adminArticleListProvider.notifier);
      if (_isEditing) {
        await notifier.updateArticle(
          widget.article!['id'] as String,
          changed,
          addCategories: added,
          removeCategories: removed,
        );
      } else {
        await notifier.createArticle(fields, categoryIds: _categoryIds);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה: $e'),
            backgroundColor: AppColors.error,
          ),
        );
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
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
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
      padding: const EdgeInsets.only(left: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.adminActiveBg : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected
                  ? AppColors.midBlue.withValues(alpha: 0.3)
                  : AppColors.adminSearchBorder,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
              color: selected ? AppColors.midBlue : AppColors.adminTextMedium,
            ),
          ),
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
    _pending = Future.delayed(
      Duration(milliseconds: milliseconds),
    ).then((_) => action());
  }
}
