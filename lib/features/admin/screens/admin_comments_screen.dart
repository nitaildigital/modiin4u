import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/admin_comments_provider.dart';

class AdminCommentsScreen extends ConsumerStatefulWidget {
  const AdminCommentsScreen({super.key});
  @override
  ConsumerState<AdminCommentsScreen> createState() =>
      _AdminCommentsScreenState();
}

class _AdminCommentsScreenState extends ConsumerState<AdminCommentsScreen> {
  final _searchController = TextEditingController();
  String _statusFilter = '';
  String _entityFilter = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setStatus(String status) {
    setState(() => _statusFilter = status);
    ref
        .read(adminCommentsProvider.notifier)
        .setStatusFilter(status.isEmpty ? null : status);
  }

  void _toggleEntity(String type) {
    setState(() => _entityFilter = _entityFilter == type ? '' : type);
    ref
        .read(adminCommentsProvider.notifier)
        .setEntityTypeFilter(_entityFilter.isEmpty ? null : _entityFilter);
  }

  /// Runs a moderation action and says what happened — the actions used to
  /// be fired and forgotten, so a refused update looked like a success.
  Future<void> _run(Future<void> Function() action, String done) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(
        SnackBar(
          content: Text(done, style: TextStyle(fontFamily: AppFonts.rubik)),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'הפעולה נכשלה: $e',
            style: TextStyle(fontFamily: AppFonts.rubik),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(adminCommentsProvider);
    final list = asyncData.valueOrNull;
    final notifier = ref.read(adminCommentsProvider.notifier);
    final isWide = MediaQuery.of(context).size.width > 900;

    return Column(
      children: [
        // ─── Stats ───
        if (list != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                _StatChip(
                  'ממתינות',
                  '${list.where((c) => c['status'] == 'pending').length}',
                  AppColors.gold,
                ),
                const SizedBox(width: 12),
                _StatChip(
                  'מאושרות',
                  '${list.where((c) => c['status'] == 'approved').length}',
                  AppColors.success,
                ),
                const SizedBox(width: 12),
                // `report_count` is how many residents reported the comment.
                _StatChip(
                  'דווחו',
                  '${list.where((c) => ((c['report_count'] as num?) ?? 0) > 0).length}',
                  AppColors.error,
                ),
                const SizedBox(width: 12),
                _StatChip('סה״כ', '${list.length}', AppColors.turquoise),
              ],
            ),
          ),

        // Nothing creates comments yet; an empty list should not read as
        // "all caught up".
        const _NothingWritesThisNote(),

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
                    hintText: 'חיפוש תגובה...',
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
                  onChanged: (v) => notifier.setSearch(v.isEmpty ? null : v),
                ),
              ),
              const SizedBox(width: 12),
              _FilterChip('הכל', _statusFilter.isEmpty, () => _setStatus('')),
              _FilterChip(
                'ממתין',
                _statusFilter == 'pending',
                () => _setStatus('pending'),
              ),
              _FilterChip(
                'מאושר',
                _statusFilter == 'approved',
                () => _setStatus('approved'),
              ),
              _FilterChip(
                'נדחה',
                _statusFilter == 'rejected',
                () => _setStatus('rejected'),
              ),
              _FilterChip(
                'מוסתר',
                _statusFilter == 'hidden',
                () => _setStatus('hidden'),
              ),
              if (isWide) ...[
                const SizedBox(width: 12),
                // Residents' replies to reviews, from the business pages.
                _FilterChip(
                  'ביקורות',
                  _entityFilter == 'review',
                  () => _toggleEntity('review'),
                ),
                _FilterChip(
                  'עסקים',
                  _entityFilter == 'business',
                  () => _toggleEntity('business'),
                ),
                _FilterChip(
                  'כתבות',
                  _entityFilter == 'article',
                  () => _toggleEntity('article'),
                ),
                _FilterChip(
                  'אירועים',
                  _entityFilter == 'event',
                  () => _toggleEntity('event'),
                ),
              ],
              const Spacer(),
              if (list != null)
                Text(
                  '${list.length} תגובות',
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 13,
                    color: AppColors.grayText,
                  ),
                ),
            ],
          ),
        ),

        // ─── List ───
        Expanded(
          child: asyncData.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                'שגיאה: $e',
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
                        Icons.forum_outlined,
                        size: 48,
                        color: AppColors.grayLight.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'אין תגובות',
                        style: TextStyle(
                          fontFamily: AppFonts.rubik,
                          color: AppColors.grayText,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: list.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  color: AppColors.border.withValues(alpha: 0.3),
                ),
                itemBuilder: (_, i) {
                  final c = list[i];
                  final id = c['id'] as String;
                  final status = c['status'] as String? ?? 'pending';
                  final reports = (c['report_count'] as num?)?.toInt() ?? 0;
                  final author = c['profiles'] is Map
                      ? ((c['profiles'] as Map)['full_name'] as String? ?? '')
                            .trim()
                      : '';

                  return Container(
                    color: reports > 0
                        ? AppColors.error.withValues(alpha: 0.04)
                        : (status == 'pending'
                              ? AppColors.gold.withValues(alpha: 0.04)
                              : null),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.turquoise.withValues(
                            alpha: 0.1,
                          ),
                          child: Text(
                            author.isEmpty ? '?' : author.characters.first,
                            style: TextStyle(
                              fontFamily: AppFonts.rubik,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.turquoise,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    author.isEmpty ? 'ללא שם' : author,
                                    style: TextStyle(
                                      fontFamily: AppFonts.rubik,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.navy,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _entityLabel(
                                      c['entity_type'] as String? ?? '',
                                    ),
                                    style: TextStyle(
                                      fontFamily: AppFonts.rubik,
                                      fontSize: 11,
                                      color: AppColors.grayLight,
                                    ),
                                  ),
                                  const Spacer(),
                                  _StatusPill(status),
                                  if (reports > 0) ...[
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.flag,
                                      size: 14,
                                      color: AppColors.error,
                                    ),
                                    Text(
                                      '$reports',
                                      style: TextStyle(
                                        fontFamily: AppFonts.rubik,
                                        fontSize: 11,
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                c['body'] as String? ?? '',
                                style: TextStyle(
                                  fontFamily: AppFonts.rubik,
                                  fontSize: 13,
                                  color: AppColors.navy,
                                  height: 1.4,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    _shortDate(
                                      c['created_at'] as String? ?? '',
                                    ),
                                    style: TextStyle(
                                      fontFamily: AppFonts.rubik,
                                      fontSize: 11,
                                      color: AppColors.grayLight,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (status != 'approved')
                                    _ActionButton(
                                      'אשר',
                                      Icons.check,
                                      AppColors.success,
                                      () => _run(
                                        () => notifier.approve(id),
                                        'התגובה אושרה',
                                      ),
                                    ),
                                  if (status == 'pending')
                                    _ActionButton(
                                      'דחה',
                                      Icons.close,
                                      AppColors.error,
                                      () => _run(
                                        () => notifier.reject(id),
                                        'התגובה נדחתה — אפשר להחזיר אותה מסל המחזור',
                                      ),
                                    ),
                                  if (status == 'approved')
                                    _ActionButton(
                                      'הסתר',
                                      Icons.visibility_off,
                                      AppColors.turquoise,
                                      () => _run(
                                        () => notifier.hide(id),
                                        'התגובה הוסתרה — אפשר להחזיר אותה מסל המחזור',
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
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

  String _entityLabel(String t) => switch (t) {
    'review' => 'תגובה לביקורת',
    'business' => 'על עסק',
    'article' => 'על כתבה',
    'event' => 'על אירוע',
    _ => t,
  };
  String _shortDate(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return iso;
    }
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  const _ActionButton(this.label, this.icon, this.color, this.onPressed);
  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: 14),
    label: Text(
      label,
      style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 12),
    ),
    style: TextButton.styleFrom(
      foregroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    ),
  );
}

/// Why this list is empty, said rather than left to be guessed.
class _NothingWritesThisNote extends StatelessWidget {
  const _NothingWritesThisNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
              'עדיין אין באתר או באפליקציה מקום לכתוב תגובה, ולכן הרשימה '
              'תתמלא רק כשיתווסף אחד.',
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

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill(this.status);
  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'approved' => ('מאושר', AppColors.success),
      'pending' => ('ממתין', AppColors.gold),
      'rejected' => ('נדחה', AppColors.error),
      'hidden' => ('מוסתר', AppColors.grayText),
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
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatChip(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontSize: 16,
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
            color: AppColors.grayText,
          ),
        ),
      ],
    ),
  );
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(this.label, this.selected, this.onTap);
  @override
  Widget build(BuildContext context) => Padding(
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
