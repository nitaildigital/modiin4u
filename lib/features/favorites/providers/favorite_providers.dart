import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../repositories/favorite_repository.dart';

final favoriteRepositoryProvider = Provider((ref) => FavoriteRepository());

/// The saved items, as `type:id` keys.
///
/// Held as one set rather than a query per card: a list of twenty businesses
/// would otherwise be twenty round trips to colour twenty hearts.
final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>(
  (ref) {
    return FavoritesNotifier(ref);
  },
);

/// Whether one particular thing is saved.
final isFavoriteProvider =
    Provider.family<bool, ({FavoriteKind kind, String id})>(
      (ref, arg) =>
          ref.watch(favoritesProvider).contains('${arg.kind.value}:${arg.id}'),
    );

class FavoritesNotifier extends StateNotifier<Set<String>> {
  final Ref _ref;

  FavoritesNotifier(this._ref) : super(const {}) {
    // Reload whenever the person changes, and empty out on sign-out so one
    // account's saved items never show under another.
    _ref.listen(
      authProvider,
      (_, next) => _load(next?.id),
      fireImmediately: true,
    );
  }

  Future<void> _load(String? profileId) async {
    if (profileId == null) {
      if (mounted) state = const {};
      return;
    }
    try {
      final keys = await _ref
          .read(favoriteRepositoryProvider)
          .fetchKeys(profileId);
      if (mounted) state = keys;
    } catch (_) {
      // A failed read leaves the hearts empty rather than wrong.
      if (mounted) state = const {};
    }
  }

  /// Saves or unsaves, updating the heart before the write lands and putting
  /// it back if the write fails.
  ///
  /// Returns false when nobody is signed in, so the caller can say so.
  Future<bool> toggle(FavoriteKind kind, String id) async {
    final profileId = _ref.read(authProvider)?.id;
    if (profileId == null) return false;

    final key = '${kind.value}:$id';
    final wasSaved = state.contains(key);
    final next = Set<String>.from(state);
    wasSaved ? next.remove(key) : next.add(key);
    state = next;

    try {
      final repo = _ref.read(favoriteRepositoryProvider);
      await (wasSaved
          ? repo.remove(profileId, kind, id)
          : repo.add(profileId, kind, id));
    } catch (_) {
      final reverted = Set<String>.from(state);
      wasSaved ? reverted.add(key) : reverted.remove(key);
      if (mounted) state = reverted;
      rethrow;
    }
    return true;
  }

  /// The saved ids of one kind, for the Favourites screen.
  List<String> idsOf(FavoriteKind kind) {
    final prefix = '${kind.value}:';
    return [
      for (final key in state)
        if (key.startsWith(prefix)) key.substring(prefix.length),
    ];
  }
}

/// The saved items, read back out of their own tables.
///
/// Watches the key set, so saving or unsaving anywhere in the app refreshes
/// the Favourites screen without it having to be reopened.
final favoriteEntriesProvider = FutureProvider<List<FavoriteEntry>>((
  ref,
) async {
  final keys = ref.watch(favoritesProvider);
  if (keys.isEmpty) return const [];
  return ref.read(favoriteRepositoryProvider).resolve(keys);
});
