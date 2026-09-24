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

/// Events still to come, earliest first. Falls back to everything when the
/// whole set is in the past, so the screen is never blank without reason.
final upcomingEventsProvider = FutureProvider<List<Event>>((ref) async {
  final events = await ref.watch(eventsProvider.future);
  final upcoming = events.where((e) => !e.hasPassed).toList();
  return upcoming.isEmpty ? events : upcoming;
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
