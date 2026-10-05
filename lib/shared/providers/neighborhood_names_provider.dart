import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_config.dart';

/// The city's neighbourhoods as the panel keeps them, in its order — for the
/// sign-up and profile forms.
///
/// The forms had a list of their own, in English ("Modiin Center",
/// "HaPrachim"), that matched none of the database's Hebrew names, so the
/// neighbourhood a person chose was looked up, not found, and never saved.
final neighborhoodNamesProvider = FutureProvider<List<String>>((ref) async {
  final rows = await SupabaseConfig.client
      .from('neighborhoods')
      .select('name')
      .order('sort_order')
      .order('name');
  return [
    for (final r in List<Map<String, dynamic>>.from(rows))
      if ((r['name'] as String?)?.trim().isNotEmpty ?? false) r['name'] as String,
  ];
});
