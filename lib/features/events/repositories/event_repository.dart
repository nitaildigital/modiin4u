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
      query = query
          .or('title.ilike.%$search%,short_description.ilike.%$search%');
    }

    final data = await query.order('start_date', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> fetchById(String id) async {
    return await _client.from('events').select().eq('id', id).single();
  }
}
