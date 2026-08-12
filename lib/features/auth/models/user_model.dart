class UserModel {
  final String id;
  final String name;
  final String phone;
  final String? neighborhood;
  final String? avatarUrl;
  final int points;
  final List<String> favoriteBusinessIds;
  final List<String> favoriteListingIds;
  final bool isVerifiedResident;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    this.neighborhood,
    this.avatarUrl,
    this.points = 0,
    this.favoriteBusinessIds = const [],
    this.favoriteListingIds = const [],
    this.isVerifiedResident = false,
    required this.createdAt,
  });

  UserModel copyWith({
    String? name,
    String? phone,
    String? neighborhood,
    String? avatarUrl,
    int? points,
    List<String>? favoriteBusinessIds,
    List<String>? favoriteListingIds,
    bool? isVerifiedResident,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      neighborhood: neighborhood ?? this.neighborhood,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      points: points ?? this.points,
      favoriteBusinessIds: favoriteBusinessIds ?? this.favoriteBusinessIds,
      favoriteListingIds: favoriteListingIds ?? this.favoriteListingIds,
      isVerifiedResident: isVerifiedResident ?? this.isVerifiedResident,
      createdAt: createdAt,
    );
  }

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return name.isNotEmpty ? name[0] : '?';
  }
}
