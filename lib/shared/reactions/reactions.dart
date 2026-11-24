import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_config.dart';
import '../../features/auth/providers/auth_provider.dart';

/// What can be liked (00089). The ♥ is still saving to Favourites; a like is
/// the 👍 beside it.
enum ReactionTarget {
  article('article'),
  business('business'),
  comment('comment'),
  review('review');

  const ReactionTarget(this.value);
  final String value;
}

/// A like, or — on a review — "helpful".
enum ReactionKind {
  like('like'),
  helpful('helpful');

  const ReactionKind(this.value);
  final String value;
}

/// One item's counts, and whether this person has reacted.
class ReactionInfo {
  final int likes;
  final int helpful;
  final bool liked;
  final bool markedHelpful;

  const ReactionInfo({
    this.likes = 0,
    this.helpful = 0,
    this.liked = false,
    this.markedHelpful = false,
  });

  int count(ReactionKind k) => k == ReactionKind.like ? likes : helpful;
  bool mine(ReactionKind k) => k == ReactionKind.like ? liked : markedHelpful;

  ReactionInfo toggled(ReactionKind k) {
    final on = !mine(k);
    final step = on ? 1 : -1;
    return k == ReactionKind.like
        ? ReactionInfo(
            likes: (likes + step).clamp(0, 1 << 30),
            helpful: helpful,
            liked: on,
            markedHelpful: markedHelpful,
          )
        : ReactionInfo(
            likes: likes,
            helpful: (helpful + step).clamp(0, 1 << 30),
            liked: liked,
            markedHelpful: on,
          );
  }
}

/// The counts for one kind of item, keyed by id, filled as screens ask.
///
/// Buttons ask for their own item; the asks made while a frame is built are
/// sent as one request (the counts) plus, signed in, one more (which of them
/// this person reacted to) — a page of reviews costs two requests, not two
/// per review. Kept for the session; read again for the new person when the
/// account changes, and for a page when it is pulled to refresh.
class ReactionsNotifier extends StateNotifier<Map<String, ReactionInfo>> {
  ReactionsNotifier(this._ref, this.target) : super(const {}) {
    _ref.listen(authProvider.select((u) => u?.id), (previous, next) {
      if (previous == next) return;
      // Whose likes they are changed: everything is read again.
      final ids = {...state.keys, ..._pending};
      _known.clear();
      state = const {};
      for (final id in ids) {
        ensure(id);
      }
    });
  }

  final Ref _ref;
  final ReactionTarget target;
  final Set<String> _known = {};
  final Set<String> _pending = {};
  Timer? _flush;

  /// Taps still on their way to the server, by id and kind: a second tap
  /// before the first is saved is ignored, so a like and an unlike cannot
  /// arrive out of order.
  final Set<String> _busy = {};

  /// Reads [id]'s counts if they have not been read, together with the
  /// other ids asked for in the same moment.
  void ensure(String id) {
    if (id.isEmpty || _known.contains(id)) return;
    _known.add(id);
    _pending.add(id);
    _flush ??= Timer(Duration.zero, _load);
  }

  /// Reads these ids again (pull to refresh).
  void refresh(Iterable<String> ids) {
    for (final id in ids) {
      _known.remove(id);
      ensure(id);
    }
  }

  Future<void> _load() async {
    _flush = null;
    final ids = _pending.toList();
    _pending.clear();
    if (ids.isEmpty) return;
    final me = _ref.read(authProvider)?.id;
    try {
      final client = SupabaseConfig.client;
      final (counts, mine) = await (
        client.rpc('reaction_counts', params: {'p_entity_type': target.value, 'p_ids': ids}),
        me == null
            ? Future.value(const <dynamic>[])
            : client
                .from('reactions')
                .select('entity_id, kind')
                .eq('entity_type', target.value)
                .eq('profile_id', me)
                .inFilter('entity_id', ids),
      ).wait;
      if (!mounted || _ref.read(authProvider)?.id != me) return;
      final byId = {
        for (final r in List<Map<String, dynamic>>.from(counts as List))
          r['entity_id'] as String: r,
      };
      final myKinds = <String, Set<String>>{};
      for (final r in List<Map<String, dynamic>>.from(mine)) {
        myKinds.putIfAbsent(r['entity_id'] as String, () => {}).add(r['kind'] as String);
      }
      state = {
        ...state,
        for (final id in ids)
          id: ReactionInfo(
            likes: (byId[id]?['likes'] as num?)?.toInt() ?? 0,
            helpful: (byId[id]?['helpful'] as num?)?.toInt() ?? 0,
            liked: myKinds[id]?.contains('like') ?? false,
            markedHelpful: myKinds[id]?.contains('helpful') ?? false,
          ),
      };
    } catch (_) {
      // Offline or refused: asked again the next time a button shows.
      _known.removeAll(ids);
    }
  }

  /// Likes or unlikes (or marks helpful). Shown at once and put back if the
  /// server refuses. False when nobody is signed in — the caller offers to
  /// sign in.
  Future<bool> toggle(String id, ReactionKind kind) async {
    final me = _ref.read(authProvider)?.id;
    if (me == null) return false;
    final key = '$id:${kind.value}';
    if (!_busy.add(key)) return true;
    final before = state[id] ?? const ReactionInfo();
    final after = before.toggled(kind);
    state = {...state, id: after};
    try {
      final table = SupabaseConfig.client.from('reactions');
      if (after.mine(kind)) {
        await table.insert({
          'entity_type': target.value,
          'entity_id': id,
          'kind': kind.value,
          'profile_id': me,
        });
      } else {
        await table
            .delete()
            .eq('entity_type', target.value)
            .eq('entity_id', id)
            .eq('kind', kind.value)
            .eq('profile_id', me);
      }
      return true;
    } catch (e) {
      if (mounted) state = {...state, id: before};
      rethrow;
    } finally {
      _busy.remove(key);
    }
  }

  @override
  void dispose() {
    _flush?.cancel();
    super.dispose();
  }
}

final reactionsProvider = StateNotifierProvider.family<
    ReactionsNotifier, Map<String, ReactionInfo>, ReactionTarget>(
  ReactionsNotifier.new,
);
