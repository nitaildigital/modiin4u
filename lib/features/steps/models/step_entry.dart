/// One day's step count.
class StepEntry {
  final DateTime date;
  final int steps;
  const StepEntry({required this.date, required this.steps});
}

/// A person's place in the ranking, as `steps_leaderboard_people` returns it.
class PersonRanking {
  final String profileId;
  final String name;
  final String? avatarUrl;
  final int totalSteps;
  final int rank;

  const PersonRanking({
    required this.profileId,
    required this.name,
    this.avatarUrl,
    required this.totalSteps,
    required this.rank,
  });

  factory PersonRanking.fromJson(Map<String, dynamic> json) => PersonRanking(
    profileId: json['profile_id'] as String,
    name: (json['full_name'] as String?) ?? '',
    avatarUrl: json['avatar_url'] as String?,
    totalSteps: (json['total_steps'] as num?)?.toInt() ?? 0,
    rank: (json['rank'] as num?)?.toInt() ?? 0,
  );
}

/// A neighbourhood's place, as `steps_leaderboard_neighborhoods` returns it.
class NeighborhoodRanking {
  final String neighborhoodId;
  final String name;
  final int totalSteps;
  final int memberCount;
  final int rank;

  const NeighborhoodRanking({
    required this.neighborhoodId,
    required this.name,
    required this.totalSteps,
    required this.memberCount,
    required this.rank,
  });

  factory NeighborhoodRanking.fromJson(Map<String, dynamic> json) =>
      NeighborhoodRanking(
        neighborhoodId: json['neighborhood_id'] as String,
        name: (json['name'] as String?) ?? '',
        totalSteps: (json['total_steps'] as num?)?.toInt() ?? 0,
        memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
        rank: (json['rank'] as num?)?.toInt() ?? 0,
      );
}
