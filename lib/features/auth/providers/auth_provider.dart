import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

final authProvider = StateNotifierProvider<AuthNotifier, UserModel?>((ref) {
  return AuthNotifier();
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authProvider) != null;
});

class AuthNotifier extends StateNotifier<UserModel?> {
  AuthNotifier() : super(null);

  void login({
    required String name,
    required String phone,
    String? neighborhood,
  }) {
    state = UserModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      phone: phone,
      neighborhood: neighborhood,
      points: 120,
      isVerifiedResident: true,
      createdAt: DateTime.now(),
    );
  }

  void logout() {
    state = null;
  }

  void updateProfile({
    String? name,
    String? phone,
    String? neighborhood,
    String? avatarUrl,
  }) {
    if (state == null) return;
    state = state!.copyWith(
      name: name,
      phone: phone,
      neighborhood: neighborhood,
      avatarUrl: avatarUrl,
    );
  }

  void toggleFavoriteBusiness(String businessId) {
    if (state == null) return;
    final current = List<String>.from(state!.favoriteBusinessIds);
    if (current.contains(businessId)) {
      current.remove(businessId);
    } else {
      current.add(businessId);
    }
    state = state!.copyWith(favoriteBusinessIds: current);
  }

  void toggleFavoriteListing(String listingId) {
    if (state == null) return;
    final current = List<String>.from(state!.favoriteListingIds);
    if (current.contains(listingId)) {
      current.remove(listingId);
    } else {
      current.add(listingId);
    }
    state = state!.copyWith(favoriteListingIds: current);
  }

  void addPoints(int amount) {
    if (state == null) return;
    state = state!.copyWith(points: state!.points + amount);
  }
}
