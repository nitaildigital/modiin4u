import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../auth/providers/auth_provider.dart';
import '../../businesses/providers/business_providers.dart';
import '../models/event.dart';
import '../models/event_category.dart';
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

// ── Categories ──
//
// Read here rather than through `EventRepository`: they are two plain
// selects, and the repository is shared with the phone screens, which do not
// use them.

/// The event categories, in the editor's order.
final eventCategoriesProvider = FutureProvider<List<EventCategory>>((ref) async {
  final rows = await SupabaseConfig.client
      .from('categories')
      // `*` so the English name comes too, once 00062 has added it.
      .select('*')
      .eq('scope', 'event')
      .eq('is_active', true)
      .order('sort_order', ascending: true);
  return List<Map<String, dynamic>>.from(rows)
      .map(EventCategory.fromJson)
      .toList();
});

/// Each event's categories, keyed by event id, the primary one first.
///
/// Empty for an event nobody has filed. The card then shows no pill, rather
/// than a category chosen for it.
final eventCategoriesByEventProvider =
    FutureProvider<Map<String, List<EventCategory>>>((ref) async {
      final categories = await ref.watch(eventCategoriesProvider.future);
      final byId = {for (final c in categories) c.id: c};

      final rows = await SupabaseConfig.client
          .from('entity_categories')
          .select('entity_id, category_id, is_primary')
          .eq('entity_type', 'event');

      final links = List<Map<String, dynamic>>.from(rows)
        ..sort((a, b) {
          final pa = a['is_primary'] == true ? 0 : 1;
          final pb = b['is_primary'] == true ? 0 : 1;
          return pa.compareTo(pb);
        });

      final result = <String, List<EventCategory>>{};
      for (final link in links) {
        final category = byId[link['category_id']];
        if (category == null) continue;
        result.putIfAbsent(link['entity_id'] as String, () => []).add(category);
      }
      return result;
    });

// ── Organizer ──

/// Who is putting the event on, for the "Organized by" card.
///
/// The business named by `business_id`, with the category it is filed under
/// as the line beneath its name — the design's "Community & Municipal
/// Events". Null when the event names no business.
final eventOrganizerProvider =
    FutureProvider.family<EventOrganizer?, String?>((ref, businessId) async {
      if (businessId == null || businessId.isEmpty) return null;
      final business = await ref.watch(businessByIdProvider(businessId).future);
      final kinds = await ref.watch(businessPrimaryCategoryProvider.future);
      final kind = kinds[businessId]?.category.name;
      final about = business.description?.trim();
      return EventOrganizer(
        id: business.id,
        name: business.name,
        logoUrl: business.logoUrl ?? business.imageUrl,
        subtitle: (kind != null && kind.isNotEmpty)
            ? kind
            : (about != null && about.isNotEmpty ? about : null),
      );
    });

class EventOrganizer {
  final String id;
  final String name;
  final String? logoUrl;
  final String? subtitle;
  const EventOrganizer({
    required this.id,
    required this.name,
    this.logoUrl,
    this.subtitle,
  });
}
