import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/event.dart';
import '../repositories/event_repository.dart';

final eventRepositoryProvider =
    Provider<EventRepository>((ref) => EventRepository());

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

final eventByIdProvider =
    FutureProvider.family<Event, String>((ref, id) async {
  final row = await ref.watch(eventRepositoryProvider).fetchById(id);
  return Event.fromJson(row);
});
