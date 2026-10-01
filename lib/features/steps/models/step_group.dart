/// A group in the caller's list, as `my_step_groups` (00041) returns it.
class StepGroupSummary {
  final String id;
  final String name;
  final bool isOwner;
  final int memberCount;
  final int todayTotal;

  /// The caller's place in the group today, 1 for the most steps.
  final int? myRank;

  const StepGroupSummary({
    required this.id,
    required this.name,
    required this.isOwner,
    required this.memberCount,
    required this.todayTotal,
    this.myRank,
  });

  factory StepGroupSummary.fromJson(Map<String, dynamic> json) =>
      StepGroupSummary(
        id: json['id'] as String,
        name: (json['name'] as String?) ?? '',
        isOwner: json['role'] == 'owner',
        memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
        todayTotal: (json['today_total'] as num?)?.toInt() ?? 0,
        myRank: (json['my_rank'] as num?)?.toInt(),
      );
}

/// The group itself, read from `step_groups` (members only, by its policy).
class StepGroup {
  final String id;
  final String name;
  final String inviteCode;

  const StepGroup({
    required this.id,
    required this.name,
    required this.inviteCode,
  });

  factory StepGroup.fromJson(Map<String, dynamic> json) => StepGroup(
    id: json['id'] as String,
    name: (json['name'] as String?) ?? '',
    inviteCode: (json['invite_code'] as String?) ?? '',
  );
}

/// One member with their steps, as `step_group_stats` returns them.
class GroupMember {
  final String profileId;
  final String name;
  final String? avatarUrl;
  final bool isOwner;
  final bool isMe;
  final int today;

  /// Since Sunday, Israel's first day of the week.
  final int week;

  /// Since the first of the month.
  final int month;

  /// Each of the last seven days, `yyyy-mm-dd` → steps; days without a
  /// record are missing.
  final Map<String, int> last7;

  const GroupMember({
    required this.profileId,
    required this.name,
    this.avatarUrl,
    required this.isOwner,
    required this.isMe,
    required this.today,
    required this.week,
    required this.month,
    required this.last7,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) => GroupMember(
    profileId: json['profile_id'] as String,
    name: (json['full_name'] as String?) ?? '',
    avatarUrl: json['avatar_url'] as String?,
    isOwner: json['role'] == 'owner',
    isMe: json['is_me'] == true,
    today: (json['today'] as num?)?.toInt() ?? 0,
    week: (json['week'] as num?)?.toInt() ?? 0,
    month: (json['month'] as num?)?.toInt() ?? 0,
    last7: {
      for (final e in ((json['last7'] as Map?) ?? const {}).entries)
        e.key as String: (e.value as num).toInt(),
    },
  );

  int stepsFor(GroupPeriod period) => switch (period) {
    GroupPeriod.today => today,
    GroupPeriod.week => week,
    GroupPeriod.month => month,
  };
}

enum GroupPeriod { today, week, month }

/// What an invitation shows before someone decides, from
/// `step_group_preview`.
class GroupPreview {
  final String id;
  final String name;
  final int memberCount;
  final bool isMember;

  const GroupPreview({
    required this.id,
    required this.name,
    required this.memberCount,
    required this.isMember,
  });

  factory GroupPreview.fromJson(Map<String, dynamic> json) => GroupPreview(
    id: json['id'] as String,
    name: (json['name'] as String?) ?? '',
    memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
    isMember: json['is_member'] == true,
  );
}
