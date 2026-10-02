import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../steps/models/step_group.dart';
import '../../steps/repositories/step_groups_repository.dart';
import '../widgets/admin_load_error.dart';
import 'admin_challenges_screen.dart';
import '../admin_language.dart';

/// The panel's Step Counter section: the city's challenges, and the step
/// groups residents make in the app.
class AdminStepsSection extends StatelessWidget {
  const AdminStepsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelStyle: TextStyle(
                fontFamily: AppFonts.rubik,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: TextStyle(
                fontFamily: AppFonts.rubik,
                fontSize: 14,
              ),
              tabs: [Tab(text: tr('אתגרים', 'Challenges')), Tab(text: tr('קבוצות צעדים', 'Step groups'))],
            ),
          ),
          const Expanded(
            child: TabBarView(
              physics: NeverScrollableScrollPhysics(),
              children: [AdminChallengesScreen(), AdminStepGroupsScreen()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Every step group, newest first, with its creator and size.
final adminStepGroupsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final rows = await SupabaseConfig.client
          .from('step_groups')
          .select(
            'id, name, invite_code, is_hidden, created_at, '
            'creator:profiles!step_groups_created_by_fkey(full_name), '
            'step_group_members(count)',
          )
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(rows);
    });

/// Step groups (migration 00041).
///
/// Residents create and run their groups in the app; the panel's part is a
/// name that should not be there. Hiding takes a group out of its members'
/// lists and stops its invitation from working, and is undone with
/// Restore — the panel never deletes, as the client asked.
class AdminStepGroupsScreen extends ConsumerWidget {
  const AdminStepGroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminStepGroupsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AdminLoadError(
        message: tr('שגיאה בטעינת הקבוצות', 'Error loading the groups'),
        error: e,
        onRetry: () => ref.invalidate(adminStepGroupsProvider),
      ),
      data: (rows) {
        if (rows.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                tr('אין קבוצות עדיין. תושבים יוצרים קבוצות במד הצעדים באפליקציה '
                'ומזמינים אליהן בקישור.', 'No groups yet. Residents create groups in the app\'s Step Counter and invite others with a link.'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  fontSize: 13,
                  color: AppColors.grayText,
                ),
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: rows.length + 1,
          separatorBuilder: (_, _) =>
              Divider(height: 1, color: AppColors.border.withValues(alpha: 0.3)),
          itemBuilder: (context, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  tr('${rows.length} קבוצות', '${rows.length} groups'),
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 13,
                    color: AppColors.grayText,
                  ),
                ),
              );
            }
            return _row(context, ref, rows[i - 1]);
          },
        );
      },
    );
  }

  Widget _row(BuildContext context, WidgetRef ref, Map<String, dynamic> g) {
    final hidden = g['is_hidden'] as bool? ?? false;
    final members = ((g['step_group_members'] as List?)?.firstOrNull
            as Map?)?['count'] as int? ??
        0;
    final creator = (g['creator'] as Map?)?['full_name'] as String? ?? '—';
    final created = DateTime.tryParse(g['created_at'] as String? ?? '');
    final style = TextStyle(
      fontFamily: AppFonts.rubik,
      fontSize: 13,
      color: AppColors.grayText,
    );

    return InkWell(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => _MembersDialog(id: g['id'] as String, name: g['name'] as String),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                (g['name'] as String?) ?? '',
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: hidden ? AppColors.grayLight : AppColors.navy,
                  decoration: hidden ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            Expanded(flex: 2, child: Text(tr('נוצרה על ידי $creator', 'Created by $creator'), style: style)),
            Expanded(child: Text(tr('$members חברים', '$members members'), style: style)),
            Expanded(
              child: Text(
                created == null
                    ? ''
                    : '${created.day}/${created.month}/${created.year}',
                style: style,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (hidden ? AppColors.grayLight : AppColors.success)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                hidden ? tr('מוסתרת', 'Hidden') : tr('פעילה', 'Active'),
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  fontSize: 12,
                  color: hidden ? AppColors.grayText : AppColors.success,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () async {
                final ok = await runAdminAction(
                  context,
                  () => SupabaseConfig.client
                      .from('step_groups')
                      .update({'is_hidden': !hidden})
                      .eq('id', g['id'] as String),
                );
                if (ok) ref.invalidate(adminStepGroupsProvider);
              },
              child: Text(
                hidden ? tr('שחזור', 'Restore') : tr('הסתרה', 'Hide'),
                style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A group's members with their steps, read through `step_group_stats`,
/// which lets the panel in as it lets members in.
class _MembersDialog extends StatelessWidget {
  final String id;
  final String name;
  const _MembersDialog({required this.id, required this.name});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontFamily: AppFonts.rubik, fontSize: 13);
    return AlertDialog(
      title: Text(name, style: TextStyle(fontFamily: AppFonts.rubik, fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 460,
        child: FutureBuilder<List<GroupMember>>(
          future: StepGroupsRepository().stats(id),
          builder: (context, snap) {
            if (snap.hasError) {
              return Text(tr('שגיאה בטעינת החברים: ${snap.error}', 'Error loading the members: ${snap.error}'), style: style);
            }
            if (!snap.hasData) {
              return const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final members = snap.data!..sort((a, b) => b.week.compareTo(a.week));
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(flex: 3, child: Text(tr('חבר/ה', 'Member'), style: style.copyWith(color: AppColors.grayText))),
                    Expanded(child: Text(tr('היום', 'Today'), style: style.copyWith(color: AppColors.grayText))),
                    Expanded(child: Text(tr('השבוע', 'This week'), style: style.copyWith(color: AppColors.grayText))),
                    Expanded(child: Text(tr('החודש', 'This month'), style: style.copyWith(color: AppColors.grayText))),
                  ],
                ),
                const Divider(),
                for (final m in members)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(m.isOwner ? tr('${m.name} (מנהל/ת)', '${m.name} (owner)') : m.name, style: style),
                        ),
                        Expanded(child: Text('${m.today}', style: style)),
                        Expanded(child: Text('${m.week}', style: style)),
                        Expanded(child: Text('${m.month}', style: style)),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(tr('סגירה', 'Close'), style: style),
        ),
      ],
    );
  }
}
