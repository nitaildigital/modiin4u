enum UserRole { admin, businessOwner, user }

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? neighborhood;
  final String? avatarUrl;
  final int points;
  final List<String> favoriteBusinessIds;
  final List<String> favoriteListingIds;
  final bool isVerifiedResident;
  final bool isBanned;
  final UserRole role;
  final String? ownedBusinessId;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const UserModel({
    required this.id,
    required this.name,
    this.email = '',
    required this.phone,
    this.neighborhood,
    this.avatarUrl,
    this.points = 0,
    this.favoriteBusinessIds = const [],
    this.favoriteListingIds = const [],
    this.isVerifiedResident = false,
    this.isBanned = false,
    this.role = UserRole.user,
    this.ownedBusinessId,
    required this.createdAt,
    this.lastLoginAt,
  });

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? neighborhood,
    String? avatarUrl,
    int? points,
    List<String>? favoriteBusinessIds,
    List<String>? favoriteListingIds,
    bool? isVerifiedResident,
    bool? isBanned,
    UserRole? role,
    String? ownedBusinessId,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      neighborhood: neighborhood ?? this.neighborhood,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      points: points ?? this.points,
      favoriteBusinessIds: favoriteBusinessIds ?? this.favoriteBusinessIds,
      favoriteListingIds: favoriteListingIds ?? this.favoriteListingIds,
      isVerifiedResident: isVerifiedResident ?? this.isVerifiedResident,
      isBanned: isBanned ?? this.isBanned,
      role: role ?? this.role,
      ownedBusinessId: ownedBusinessId ?? this.ownedBusinessId,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isBusinessOwner => role == UserRole.businessOwner;

  String get roleLabel => switch (role) {
    UserRole.admin => 'מנהל',
    UserRole.businessOwner => 'בעל עסק',
    UserRole.user => 'תושב',
  };

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return name.isNotEmpty ? name[0] : '?';
  }
}
