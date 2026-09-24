import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_config.dart';

class EventRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<List<Map<String, dynamic>>> fetchAll({
    String? search,
    String status = 'published',
  }) async {
    var query = _client.from('events').select();

    if (status.isNotEmpty) {
      query = query.eq('status', status);
    }
    if (search != null && search.isNotEmpty) {
      query = query.or(
        'title.ilike.%$search%,short_description.ilike.%$search%',
      );
    }

    final data = await query.order('start_date', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> fetchById(String id) async {
    return await _client.from('events').select().eq('id', id).single();
  }

  // ── Attendance ──
  //
  // `event_attendees` has existed since migration 00006 and nothing touched
  // it: the "I'm going" button was a local `setState`. These are the reads
  // and writes it should always have had.

  /// Whether this person has said they are coming.
  ///
  /// The owner policy lets someone read only their own row, so this answers
  /// for the signed-in account and nobody else. Null when signed out.
  Future<bool> isAttending(String eventId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return false;

    final row = await _client
        .from('event_attendees')
        .select('status')
        .eq('event_id', eventId)
        .eq('profile_id', uid)
        .maybeSingle();

    return row != null && row['status'] != 'cancelled';
  }

  /// Says they are coming.
  ///
  /// Upserted on the table's own `(event_id, profile_id)` unique key, so
  /// coming back after cancelling reuses the row rather than failing on it.
  Future<void> attend(String eventId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('An RSVP can only be made by a signed-in account.');
    }

    await _client.from('event_attendees').upsert({
      'event_id': eventId,
      'profile_id': uid,
      'status': 'going',
    }, onConflict: 'event_id,profile_id');
  }

  /// Takes it back. The row is kept and marked rather than deleted, so the
  /// history of who had signed up is not lost.
  Future<void> cancelAttendance(String eventId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;

    await _client
        .from('event_attendees')
        .update({'status': 'cancelled'})
        .eq('event_id', eventId)
        .eq('profile_id', uid);
  }
}
