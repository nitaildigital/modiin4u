import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/event.dart';
import '../repositories/event_repository.dart';

final eventRepositoryProvider = Provider<EventRepository>(
  (ref) => EventRepository(),
);

/// Every published event, earliest first.
final eventsProvider = FutureProvider<List<Event>>((ref) async {
  final rows = await ref.watch(eventRepositoryProvider).fetchAll();
  return rows.map(Event.fromJson).toList();
});

/// Events still to come, earliest first — and only those.
///
/// This used to fall back to every event when all of them had passed, "so the
/// screen is never blank without reason". But the home page draws this under
/// the heading "Upcoming Events", so when the last event went by in early
/// September the page began presenting past events as upcoming ones. An
/// empty section says something true; a full one with the wrong heading
/// does not. The home page hides the section when this is empty, the way it
/// already does for deals and apartments.
final upcomingEventsProvider = FutureProvider<List<Event>>((ref) async {
  final events = await ref.watch(eventsProvider.future);
  return events.where((e) => !e.hasPassed).toList();
});

final eventByIdProvider = FutureProvider.family<Event, String>((ref, id) async {
  final row = await ref.watch(eventRepositoryProvider).fetchById(id);
  return Event.fromJson(row);
});

/// Whether the signed-in person has said they are coming to this event.
///
/// False when signed out, so the button can offer to sign in rather than
/// show a failure. The screen used to hold this in a local `bool` that reset
/// to false on every open, so someone who had already RSVP'd was told they
/// had not.
final isAttendingProvider = FutureProvider.family<bool, String>((
  ref,
  eventId,
) async {
  final user = ref.watch(authProvider);
  if (user == null) return false;
  return ref.watch(eventRepositoryProvider).isAttending(eventId);
});

/// What the events list is narrowed to. Empty means everything.
///
/// The search field on the events screen was a `Text`, so nothing could be
/// typed and the repository's `search` argument — which has always been
/// there — was never passed.
final eventSearchProvider = StateProvider<String>((ref) => '');

/// Upcoming events matching the search.
final filteredEventsProvider = FutureProvider<List<Event>>((ref) async {
  final query = ref.watch(eventSearchProvider).trim();
  final events = await ref.watch(upcomingEventsProvider.future);
  if (query.isEmpty) return events;

  // Filtered here rather than in a query: the set is small and already
  // loaded, so a round trip per keystroke would be worse.
  final q = query.toLowerCase();
  return events
      .where(
        (e) =>
            e.title.toLowerCase().contains(q) ||
            (e.venueName ?? '').toLowerCase().contains(q) ||
            e.address.toLowerCase().contains(q),
      )
      .toList();
});
