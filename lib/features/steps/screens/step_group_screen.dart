import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../auth/widgets/m_account_widgets.dart' show MBackArrow;
import '../models/step_group.dart';
import '../providers/step_groups_providers.dart';
import '../services/health_steps.dart' show dateKey;
import '../widgets/step_groups_tab.dart';

const _border = Color(0xFFE7E7E7);
const _muted = Color(0xFF6D6D6D);
const _ink = Color(0xFF1F1F1F);
const _blue = Color(0xFF216AD0);

/// One step group: everyone's steps side by side, for today, this week and
/// this month, the group's own totals, and its last seven days.
///
/// The figures come from `step_group_stats` (00041), which answers members
/// only. The owner can invite, rename, renew the invitation, remove members
/// and delete the group; anyone can invite and leave.
class StepGroupScreen extends ConsumerStatefulWidget {
  final String groupId;

  /// Straight after creating it: open the share sheet, since a group of one
  /// is the reason the person is here.
  final bool inviteNow;

  const StepGroupScreen({
    super.key,
    required this.groupId,
    this.inviteNow = false,
  });

  @override
  ConsumerState<StepGroupScreen> createState() => _StepGroupScreenState();
}

class _StepGroupScreenState extends ConsumerState<StepGroupScreen> {
  GroupPeriod _period = GroupPeriod.today;
  bool _invited = false;

  String get _id => widget.groupId;

  void _back() => context.canPop() ? context.pop() : context.go('/steps?tab=groups');

  Future<void> _refresh() async {
    ref.invalidate(stepGroupProvider(_id));
    ref.invalidate(stepGroupStatsProvider(_id));
    ref.invalidate(myStepGroupsProvider);
    await ref.read(stepGroupStatsProvider(_id).future);
  }

  Future<void> _invite(StepGroup group) async {
    final l = L.of(context);
    final site = await ref.read(siteUrlProvider.future);
    final link = '$site/join/${group.inviteCode}';
    await Share.share(
      l.sgInviteMessage(group.name, link, group.inviteCode),
      subject: group.name,
    );
  }

  Future<void> _rename(StepGroup group) async {
    final l = L.of(context);
    final name = await askText(
      context,
      title: l.sgRename,
      hint: l.sgGroupName,
      action: l.sgSave,
      initial: group.name,
    );
    if (name == null || name.trim().isEmpty || name.trim() == group.name) return;
    await _run(() => ref.read(stepGroupsRepositoryProvider).rename(_id, name));
  }

  Future<void> _newInvite() async {
    final l = L.of(context);
    final ok = await confirmGroupAction(
      context,
      title: l.sgNewInvite,
      body: l.sgNewInviteBody,
      action: l.sgContinue,
    );
    if (!ok) return;
    await _run(() async {
      final code = await ref.read(stepGroupsRepositoryProvider).resetCode(_id);
      if (mounted) showGroupError(context, l.sgNewInviteDone(code));
    });
  }

  Future<void> _delete() async {
    final l = L.of(context);
    final ok = await confirmGroupAction(
      context,
      title: l.sgDeleteGroup,
      body: l.sgDeleteGroupBody,
      action: l.delete,
      destructive: true,
    );
    if (!ok) return;
    await _run(() async {
      await ref.read(stepGroupsRepositoryProvider).delete(_id);
      if (mounted) _back();
    }, refresh: false);
  }

  Future<void> _leave(bool owner) async {
    final l = L.of(context);
    final ok = await confirmGroupAction(
      context,
      title: l.sgLeaveGroup,
      body: owner ? l.sgLeaveGroupOwnerBody : l.sgLeaveGroupBody,
      action: l.sgLeave,
      destructive: true,
    );
    if (!ok) return;
    await _run(() async {
      await ref.read(stepGroupsRepositoryProvider).leave(_id);
      if (mounted) _back();
    }, refresh: false);
  }

  Future<void> _remove(GroupMember m) async {
    final l = L.of(context);
    final ok = await confirmGroupAction(
      context,
      title: l.sgRemoveMemberConfirm(m.name),
      action: l.sgRemove,
      destructive: true,
    );
    if (!ok) return;
    await _run(
      () => ref.read(stepGroupsRepositoryProvider).removeMember(_id, m.profileId),
    );
  }

  Future<void> _run(Future<void> Function() action, {bool refresh = true}) async {
    final l = L.of(context);
    try {
      await action();
      ref.invalidate(myStepGroupsProvider);
      if (refresh) await _refresh();
    } catch (e) {
      if (mounted) showGroupError(context, groupErrorText(l, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final groupAsync = ref.watch(stepGroupProvider(_id));
    final statsAsync = ref.watch(stepGroupStatsProvider(_id));
    final group = groupAsync.valueOrNull;
    final members = statsAsync.valueOrNull ?? const <GroupMember>[];
    final me = members.where((m) => m.isMe).firstOrNull;
    final isOwner = me?.isOwner ?? false;

    if (widget.inviteNow && !_invited && group != null) {
      _invited = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _invite(group));
    }

    final gone =
        (groupAsync.hasValue && group == null) || statsAsync.hasError;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 10, 6, 0),
                  child: Row(
                    children: [
                      MBackArrow(
                        color: const Color(0xFF3D3D3D),
                        onTap: _back,
                      ),
                      Expanded(
                        child: Text(
                          group?.name ?? '',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      if (group != null && me != null)
                        _Menu(
                          isOwner: isOwner,
                          onRename: () => _rename(group),
                          onNewInvite: _newInvite,
                          onDelete: _delete,
                          onLeave: () => _leave(isOwner),
                        )
                      else
                        const SizedBox(width: 40),
                    ],
                  ),
                ),
                Expanded(
                  child: gone
                      ? _Centered(text: l.sgGroupGone)
                      : group == null || statsAsync.isLoading && members.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: _refresh,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                            children: [
                              _InviteCard(
                                group: group,
                                memberCount: members.length,
                                onInvite: () => _invite(group),
                              ),
                              const SizedBox(height: 16),
                              _PeriodSwitch(
                                value: _period,
                                onChanged: (p) => setState(() => _period = p),
                              ),
                              const SizedBox(height: 16),
                              _GroupStats(members: members, period: _period),
                              const SizedBox(height: 16),
                              _CompareTable(
                                members: members,
                                period: _period,
                                canRemove: isOwner,
                                onRemove: _remove,
                              ),
                              const SizedBox(height: 16),
                              _GroupWeekChart(members: members),
                            ],
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

class _Menu extends StatelessWidget {
  final bool isOwner;
  final VoidCallback onRename;
  final VoidCallback onNewInvite;
  final VoidCallback onDelete;
  final VoidCallback onLeave;
  const _Menu({
    required this.isOwner,
    required this.onRename,
    required this.onNewInvite,
    required this.onDelete,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    PopupMenuItem<VoidCallback> item(IconData icon, String label, VoidCallback f,
            {Color color = _ink}) =>
        PopupMenuItem(
          value: f,
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: color),
              ),
            ],
          ),
        );
    return PopupMenuButton<VoidCallback>(
      icon: const Icon(IconsaxPlusLinear.more, color: Color(0xFF3D3D3D)),
      color: Colors.white,
      surfaceTintColor: Colors.white,
      onSelected: (f) => f(),
      itemBuilder: (_) => [
        if (isOwner) ...[
          item(IconsaxPlusLinear.edit_2, l.sgRename, onRename),
          item(IconsaxPlusLinear.refresh, l.sgNewInvite, onNewInvite),
        ],
        item(IconsaxPlusLinear.logout, l.sgLeaveGroup, onLeave, color: AppColors.error),
        if (isOwner)
          item(IconsaxPlusLinear.trash, l.sgDeleteGroup, onDelete, color: AppColors.error),
      ],
    );
  }
}

class _InviteCard extends StatelessWidget {
  final StepGroup group;
  final int memberCount;
  final VoidCallback onInvite;
  const _InviteCard({
    required this.group,
    required this.memberCount,
    required this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF123A72), Color(0xFF216AD0)],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.name,
            style: TextStyle(
              fontFamily: AppFonts.nunito,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l.sgMembers(memberCount),
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: onInvite,
                    child: SizedBox(
                      height: 42,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(IconsaxPlusLinear.share, size: 18, color: AppColors.midBlue),
                          const SizedBox(width: 8),
                          Text(
                            l.sgInvite,
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.midBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // The code on its own, for reading out or typing in; a tap
              // copies it.
              Material(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: group.inviteCode));
                    showGroupError(context, '${l.sgInviteCode}: ${group.inviteCode}');
                  },
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    child: Row(
                      children: [
                        Text(
                          group.inviteCode,
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(IconsaxPlusLinear.copy, size: 16, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PeriodSwitch extends StatelessWidget {
  final GroupPeriod value;
  final ValueChanged<GroupPeriod> onChanged;
  const _PeriodSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final labels = {
      GroupPeriod.today: l.sgToday,
      GroupPeriod.week: l.thisWeek,
      GroupPeriod.month: l.sgThisMonth,
    };
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final p in GroupPeriod.values)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: p == value ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: p == value
                        ? const [BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1))]
                        : null,
                  ),
                  child: Text(
                    labels[p]!,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 13,
                      fontWeight: p == value ? FontWeight.w600 : FontWeight.w500,
                      color: p == value ? AppColors.midBlue : _muted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The group's own figures for the chosen period: everyone's steps added
/// up, the average per member, and who leads.
class _GroupStats extends StatelessWidget {
  final List<GroupMember> members;
  final GroupPeriod period;
  const _GroupStats({required this.members, required this.period});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final total = members.fold<int>(0, (s, m) => s + m.stepsFor(period));
    final average = members.isEmpty ? 0 : (total / members.length).round();
    final sorted = [...members]..sort((a, b) => b.stepsFor(period).compareTo(a.stepsFor(period)));
    final leader = sorted.isEmpty || sorted.first.stepsFor(period) == 0 ? null : sorted.first;

    Widget tile(String label, String value, {String? sub}) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 12, color: _muted),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
            if (sub != null) ...[
              const SizedBox(height: 2),
              Text(
                sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: AppFonts.inter, fontSize: 11, color: _muted),
              ),
            ],
          ],
        ),
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        tile(l.sgGroupTotal, formatSteps(total), sub: l.stepsUnit),
        const SizedBox(width: 8),
        tile(l.sgAverage, formatSteps(average), sub: l.stepsUnit),
        const SizedBox(width: 8),
        tile(
          l.sgTopWalker,
          leader == null ? '—' : (leader.isMe ? l.you : leader.name),
          sub: leader == null ? null : formatSteps(leader.stepsFor(period)),
        ),
      ],
    );
  }
}

/// Every member side by side — today, this week, this month — ranked by
/// the chosen period, which is the column drawn darker. The client's own
/// example of what the group should show.
class _CompareTable extends StatelessWidget {
  final List<GroupMember> members;
  final GroupPeriod period;
  final bool canRemove;
  final ValueChanged<GroupMember> onRemove;
  const _CompareTable({
    required this.members,
    required this.period,
    required this.canRemove,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final sorted = [...members]
      ..sort((a, b) {
        final c = b.stepsFor(period).compareTo(a.stepsFor(period));
        return c != 0 ? c : a.name.compareTo(b.name);
      });

    TextStyle head(GroupPeriod? p) => TextStyle(
      fontFamily: AppFonts.inter,
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: p == period ? AppColors.midBlue : _muted,
    );
    TextStyle cell(GroupPeriod p) => TextStyle(
      fontFamily: AppFonts.inter,
      fontSize: 13,
      fontWeight: p == period ? FontWeight.w700 : FontWeight.w400,
      color: p == period ? _ink : const Color(0xFF5D5D5D),
    );
    const numW = 62.0;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Text(
              l.sgCompareTitle,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              children: [
                Expanded(child: Text(l.sgColMember, style: head(null))),
                SizedBox(width: numW, child: Text(l.sgToday, textAlign: TextAlign.end, style: head(GroupPeriod.today))),
                SizedBox(width: numW, child: Text(l.thisWeek, textAlign: TextAlign.end, style: head(GroupPeriod.week))),
                SizedBox(width: numW, child: Text(l.sgThisMonth, textAlign: TextAlign.end, style: head(GroupPeriod.month))),
              ],
            ),
          ),
          for (var i = 0; i < sorted.length; i++)
            InkWell(
              onLongPress: canRemove && !sorted[i].isMe ? () => onRemove(sorted[i]) : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: sorted[i].isMe ? const Color(0xFFF1F6FD) : null,
                  border: const Border(top: BorderSide(color: _border)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: i == 0 && sorted[i].stepsFor(period) > 0
                              ? const Color(0xFFFB7901)
                              : _muted,
                        ),
                      ),
                    ),
                    _Avatar(member: sorted[i]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sorted[i].name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _ink,
                            ),
                          ),
                          // On a line of their own, so a long name is
                          // not cut short of them.
                          if (sorted[i].isMe || sorted[i].isOwner) ...[
                            const SizedBox(height: 3),
                            Wrap(
                              spacing: 4,
                              runSpacing: 2,
                              children: [
                                if (sorted[i].isMe)
                                  OwnerTag(label: l.you, me: true),
                                if (sorted[i].isOwner)
                                  OwnerTag(label: l.sgOwner),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    for (final p in GroupPeriod.values)
                      SizedBox(
                        width: numW,
                        child: Text(
                          formatSteps(sorted[i].stepsFor(p)),
                          textAlign: TextAlign.end,
                          style: cell(p),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (canRemove && sorted.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Text(
                l.sgRemoveHint,
                style: TextStyle(fontFamily: AppFonts.inter, fontSize: 11, color: _muted),
              ),
            )
          else
            const SizedBox(height: 6),
        ],
      ),
    );
  }

}

class _Avatar extends StatelessWidget {
  final GroupMember member;
  const _Avatar({required this.member});

  @override
  Widget build(BuildContext context) {
    final url = member.avatarUrl;
    if (url != null && url.isNotEmpty) {
      return NetworkPhoto(
        url: url,
        width: 28,
        height: 28,
        radius: BorderRadius.circular(14),
      );
    }
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFD9D9D9)),
      alignment: Alignment.center,
      child: Text(
        member.name.isEmpty ? '?' : member.name.characters.first,
        style: TextStyle(
          fontFamily: AppFonts.inter,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// The group's steps on each of the last seven days, everyone added up.
class _GroupWeekChart extends StatelessWidget {
  final List<GroupMember> members;
  const _GroupWeekChart({required this.members});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final now = DateTime.now();
    final days = [
      for (var i = 6; i >= 0; i--) DateTime(now.year, now.month, now.day).subtract(Duration(days: i)),
    ];
    final totals = [
      for (final d in days) members.fold<int>(0, (s, m) => s + (m.last7[dateKey(d)] ?? 0)),
    ];
    final best = totals.fold<int>(0, (a, b) => a > b ? a : b);
    const barMaxH = 120.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.sgGroupLast7,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _ink,
            ),
          ),
          const SizedBox(height: 14),
          if (best == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  l.sgNoStepsShared,
                  style: TextStyle(fontFamily: AppFonts.inter, fontSize: 13, color: _muted),
                ),
              ),
            )
          else
            SizedBox(
              height: barMaxH + 44,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < days.length; i++)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            totals[i] >= 1000
                                ? '${(totals[i] / 1000).toStringAsFixed(1)}K'
                                : '${totals[i]}',
                            style: TextStyle(fontFamily: AppFonts.inter, fontSize: 11, color: _ink),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 16,
                            height: best == 0 ? 0 : (totals[i] / best) * barMaxH,
                            decoration: BoxDecoration(
                              color: i == days.length - 1 ? AppColors.midBlue : _blue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            weekdayShort(l, days[i]),
                            style: TextStyle(fontFamily: AppFonts.inter, fontSize: 11, color: _muted),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 1 = Monday, as DateTime.weekday numbers them.
String weekdayShort(L l, DateTime d) => switch (d.weekday) {
  DateTime.monday => l.weekdayMon,
  DateTime.tuesday => l.weekdayTue,
  DateTime.wednesday => l.weekdayWed,
  DateTime.thursday => l.weekdayThu,
  DateTime.friday => l.weekdayFri,
  DateTime.saturday => l.weekdaySat,
  _ => l.weekdaySun,
};

class _Centered extends StatelessWidget {
  final String text;
  const _Centered({required this.text});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: _muted),
      ),
    ),
  );
}
